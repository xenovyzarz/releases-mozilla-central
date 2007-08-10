#
# Build step. Calls tinderbox to produce en-US Firefox build.
#
package Bootstrap::Step::Build;

use Bootstrap::Step;

@ISA = ("Bootstrap::Step");

sub Execute {
    my $this = shift;

    my $config = new Bootstrap::Config();
    my $buildDir = $config->Get(sysvar => 'buildDir');
    my $productTag = $config->Get(var => 'productTag');
    my $rc = $config->Get(var => 'rc');
    my $buildPlatform = $config->Get(sysvar => 'buildPlatform');
    my $logDir = $config->Get(sysvar => 'logDir');
    my $rcTag = $productTag . '_RC' . $rc;

    my $lastBuilt = catfile($buildDir, $buildPlatform, 'last-built');
    if (! unlink($lastBuilt)) {
        $this->Log(msg => "Cannot unlink last-built file $lastBuilt: $!");
    } else {
        $this->Log(msg => "Unlinked $lastBuilt");
    }

    my $buildLog = catfile($logDir, 'build_' . $rcTag . '-build.log');
 
    $this->Shell(
      cmd => './build-seamonkey.pl',
      cmdArgs => ['--once', '--mozconfig', 'mozconfig', '--depend', 
                  '--config-cvsup-dir', 
                  catfile($buildDir, 'tinderbox-configs')],
      dir => $buildDir,
      logFile => $buildLog,
      timeout => 36000
    );

}

sub Verify {
    my $this = shift;

    my $config = new Bootstrap::Config();
    my $buildDir = $config->Get(sysvar => 'buildDir');
    my $productTag = $config->Get(var => 'productTag');
    my $rc = $config->Get(var => 'rc');
    my $rcTag = $productTag.'_RC'.$rc;
    my $logDir = $config->Get(sysvar => 'logDir');

    my $buildLog = catfile($logDir, 'build_' . $rcTag . '-build.log');

    $this->CheckLog(
        log => $buildLog,
        notAllowed => 'tinderbox: status: failed',
    );

    my $logParser = new MozBuild::TinderLogParse(
        logFile => $buildLog,
    );

    if (! defined($logParser->GetBuildID())) {
        die("No buildID found in $buildLog");
    }
    if (! defined($logParser->GetPushDir())) {
        die("No pushDir found in $buildLog");
    }
}

sub Push {
    my $this = shift;

    my $config = new Bootstrap::Config();
    my $productTag = $config->Get(var => 'productTag');
    my $rc = $config->Get(var => 'rc');
    my $logDir = $config->Get(sysvar => 'logDir');
    my $sshUser = $config->Get(var => 'sshUser');
    my $sshServer = $config->Get(var => 'sshServer');

    my $rcTag = $productTag . '_RC' . $rc;
    my $buildLog = catfile($logDir, 'build_' . $rcTag . '-build.log');
    my $pushLog  = catfile($logDir, 'build_' . $rcTag . '-push.log');

    my $logParser = new MozBuild::TinderLogParse(
        logFile => $buildLog,
    );
    my $pushDir = $logParser->GetPushDir();
    if (! defined($pushDir)) {
        die("No pushDir found in $buildLog");
    }
    $pushDir =~ s!^http://ftp.mozilla.org/pub/mozilla.org!/home/ftp/pub!;

    my $candidateDir = $config->GetFtpCandidateDir(bitsUnsigned => 1);

    my $osFileMatch = $config->SystemInfo(var => 'osname');    
    if ($osFileMatch eq 'win32')  {
      $osFileMatch = 'win';
    } elsif ($osFileMatch eq 'macosx') {
      $osFileMatch = 'mac';
    }    

    $this->Shell(
      cmd => 'ssh',
      cmdArgs => ['-2', '-l', $sshUser, $sshServer,
                  'mkdir -p ' . $candidateDir],
      logFile => $pushLog,
    );

    $this->Shell(
      cmd => 'ssh',
      cmdArgs => ['-2', '-l', $sshUser, $sshServer,
                  'rsync', '-av', 
                  '--include=*' . $osFileMatch . '*',
                  '--exclude=*', 
                  $pushDir, 
                  $candidateDir],
      logFile => $pushLog,
    );
}

sub Announce {
    my $this = shift;

    my $config = new Bootstrap::Config();
    my $product = $config->Get(var => 'product');
    my $productTag = $config->Get(var => 'productTag');
    my $version = $config->Get(var => 'version');
    my $rc = $config->Get(var => 'rc');
    my $logDir = $config->Get(sysvar => 'logDir');

    my $rcTag = $productTag . '_RC' . $rc;
    my $buildLog = catfile($logDir, 'build_' . $rcTag . '-build.log');

    my $logParser = new MozBuild::TinderLogParse(
        logFile => $buildLog,
    );
    my $buildID = $logParser->GetBuildID();
    my $pushDir = $logParser->GetPushDir();

    if (! defined($buildID)) {
        die("No buildID found in $buildLog");
    } 
    if (! defined($pushDir)) {
        die("No pushDir found in $buildLog");
    } 

    $this->SendAnnouncement(
      subject => "$product $version build step finished",
      message => "$product $version en-US build was copied to the candidates dir.\nBuild ID is $buildID\nPush Dir was $pushDir",
    );
}

1;

