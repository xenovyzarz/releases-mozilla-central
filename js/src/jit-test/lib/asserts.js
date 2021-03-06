/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


if (typeof assertThrowsInstanceOf === 'undefined') {
    var assertThrowsInstanceOf = function assertThrowsInstanceOf(f, ctor, msg) {
        var fullmsg;
        try {
            f();
        } catch (exc) {
            if (exc instanceof ctor)
                return;
            fullmsg = "Assertion failed: expected exception " + ctor.name + ", got " + exc;
        }
        if (fullmsg === undefined)
            fullmsg = "Assertion failed: expected exception " + ctor.name + ", no exception thrown";
        if (msg !== undefined)
            fullmsg += " - " + msg;
        throw new Error(fullmsg);
    };
}

if (typeof assertThrowsValue === 'undefined') {
    var assertThrowsValue = function assertThrowsValue(f, val, msg) {
        var fullmsg;
        try {
            f();
        } catch (exc) {
            if ((exc === val) === (val === val) && (val !== 0 || 1 / exc === 1 / val))
                return;
            fullmsg = "Assertion failed: expected exception " + val + ", got " + exc;
        }
        if (fullmsg === undefined)
            fullmsg = "Assertion failed: expected exception " + val + ", no exception thrown";
        if (msg !== undefined)
            fullmsg += " - " + msg;
        throw new Error(fullmsg);
    };
}

if (typeof assertWarning === 'undefined') {
    var assertWarning = function assertWarning(f, errorClass, msg) {
        var hadWerror = options().split(",").indexOf("werror") !== -1;

        // Ensure the "werror" option is disabled.
        if (hadWerror)
            options("werror");

        try {
            f();
        } catch (exc) {
            if (hadWerror)
                options("werror");

            // print() rather than throw a different exception value, in case
            // the caller wants exc.stack.
            if (msg)
                print("assertWarning: " + msg);
            print("assertWarning: Unexpected exception calling " + f +
                  " with warnings-as-errors disabled");
            throw exc;
        }

        // Enable the "werror" option.
        options("werror");

        try {
            assertThrowsInstanceOf(f, errorClass, msg);
        } catch (exc) {
            if (msg)
                print("assertWarning: " + msg);
            throw exc;
        } finally {
            if (!hadWerror)
                options("werror");
        }
    };
}

if (typeof assertNoWarning === 'undefined') {
    var assertNoWarning = function assertWarning(f, msg) {
        // Ensure the "werror" option is enabled.
        var hadWerror = options().split(",").indexOf("werror") !== -1;
        if (!hadWerror)
            options("werror");

        try {
            f();
        } catch (exc) {
            if (msg)
                print("assertNoWarning: " + msg);
            print("assertNoWarning: Unexpected exception calling " + f +
                  "with warnings-as-errors enabled");
            throw exc;
        } finally {
            if (!hadWerror)
                options("werror");
        }
    };
}
