/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-
 * vim: set ts=4 sw=4 et tw=99:
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#if !defined(jsion_baseline_helpers_arm_h__) && defined(JS_ION)
#define jsion_baseline_helpers_arm_h__

#include "ion/IonMacroAssembler.h"
#include "ion/BaselineRegisters.h"
#include "ion/BaselineIC.h"

namespace js {
namespace ion {

inline void
EmitRestoreTailCallReg(MacroAssembler &masm)
{
    // No-op on ARM because link register is always holding the return address.
}

inline void
EmitCallIC(CodeOffsetLabel *patchOffset, MacroAssembler &masm)
{

    // Move ICEntry offset into BaselineStubReg
    CodeOffsetLabel offset = masm.movWithPatch(ImmWord(-1), BaselineStubReg);
    *patchOffset = offset;

    // Load stub pointer into BaselineStubReg
    masm.loadPtr(Address(BaselineStubReg, ICEntry::offsetOfFirstStub()), BaselineStubReg);

    // Load stubcode pointer from BaselineStubEntry.
    // R2 won't be active when we call ICs, so we can use r0.
    JS_ASSERT(R2 == ValueOperand(r1, r0));
    masm.loadPtr(Address(BaselineStubReg, ICStub::offsetOfStubCode()), r0);

    // Call the stubcode via a direct branch-and-link
    masm.ma_blx(r0);
}

inline void
EmitReturnFromIC(MacroAssembler &masm)
{
    masm.ma_mov(lr, pc);
}

inline void
EmitTailCall(IonCode *target, MacroAssembler &masm, uint32_t argSize)
{
    // We assume during this that R0 and R1 have been pushed, and that R2 is
    // unused.
    JS_ASSERT(R2 == ValueOperand(r1, r0));

    // Compute frame size.
    masm.movePtr(BaselineFrameReg, r0);
    masm.ma_add(Imm32(BaselineFrame::FramePointerOffset), r0);
    masm.ma_sub(BaselineStackReg, r0);

    // Store frame size without VMFunction arguments for GC marking.
    masm.ma_sub(r0, Imm32(argSize), r1);
    masm.storePtr(r1, Address(BaselineFrameReg, BaselineFrame::reverseOffsetOfFrameSize()));

    // Push frame descriptor and perform the tail call.
    // BaselineTailCallReg (lr) already contains the return address (as we keep it there through
    // the stub calls), but the VMWrapper code being called expects the return address to also
    // be pushed on the stack.
    JS_ASSERT(BaselineTailCallReg == lr);
    masm.makeFrameDescriptor(r0, IonFrame_BaselineJS);
    masm.push(r0);
    masm.push(lr);
    masm.branch(target);
}

inline void
EmitStubGuardFailure(MacroAssembler &masm)
{
    JS_ASSERT(R2 == ValueOperand(r1, r0));

    // NOTE: This routine assumes that the stub guard code left the stack in the
    // same state it was in when it was entered.

    // BaselineStubEntry points to the current stub.

    // Load next stub into BaselineStubReg
    masm.loadPtr(Address(BaselineStubReg, ICStub::offsetOfNext()), BaselineStubReg);

    // Load stubcode pointer from BaselineStubEntry into scratch register.
    masm.loadPtr(Address(BaselineStubReg, ICStub::offsetOfStubCode()), r0);

    // Return address is already loaded, just jump to the next stubcode.
    JS_ASSERT(BaselineTailCallReg == lr);
    masm.branch(r0);
}


} // namespace ion
} // namespace js

#endif

