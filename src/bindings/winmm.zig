const std = @import("std");
pub const c = @cImport({
    @cInclude("windows.h");
    @cInclude("mmsystem.h");
});

pub const MimMessageType = enum(c.UINT) {
    MIM_CLOSE = c.MIM_CLOSE,
    MIM_DATA = c.MIM_DATA,
    MIM_ERROR = c.MIM_ERROR,
    MIM_LONGDATA = c.MIM_LONGDATA,
    MIM_LONGERROR = c.MIM_LONGERROR,
    MIM_MOREDATA = c.MIM_MOREDATA,
    MIM_OPEN = c.MIM_OPEN,
    _,
};

const MmResultEnum = enum(c.MMRESULT) {
    MMSYSERR_NOERROR = c.MMSYSERR_NOERROR,
    MMSYSERR_ERROR = c.MMSYSERR_ERROR,
    MMSYSERR_BADDEVICEID = c.MMSYSERR_BADDEVICEID,
    MMSYSERR_NOTENABLED = c.MMSYSERR_NOTENABLED,
    MMSYSERR_ALLOCATED = c.MMSYSERR_ALLOCATED,
    MMSYSERR_INVALHANDLE = c.MMSYSERR_INVALHANDLE,
    MMSYSERR_NODRIVER = c.MMSYSERR_NODRIVER,
    MMSYSERR_NOMEM = c.MMSYSERR_NOMEM,
    MMSYSERR_NOTSUPPORTED = c.MMSYSERR_NOTSUPPORTED,
    MMSYSERR_BADERRNUM = c.MMSYSERR_BADERRNUM,
    MMSYSERR_INVALFLAG = c.MMSYSERR_INVALFLAG,
    MMSYSERR_INVALPARAM = c.MMSYSERR_INVALPARAM,
    MMSYSERR_HANDLEBUSY = c.MMSYSERR_HANDLEBUSY,
    MMSYSERR_INVALIDALIAS = c.MMSYSERR_INVALIDALIAS,
    MMSYSERR_BADDB = c.MMSYSERR_BADDB,
    MMSYSERR_KEYNOTFOUND = c.MMSYSERR_KEYNOTFOUND,
    MMSYSERR_READERROR = c.MMSYSERR_READERROR,
    MMSYSERR_WRITEERROR = c.MMSYSERR_WRITEERROR,
    MMSYSERR_DELETEERROR = c.MMSYSERR_DELETEERROR,
    MMSYSERR_VALNOTFOUND = c.MMSYSERR_VALNOTFOUND,
    MMSYSERR_NODRIVERCB = c.MMSYSERR_NODRIVERCB,
    MMSYSERR_MOREDATA = c.MMSYSERR_MOREDATA,
    _,
};

pub const MmResultError = error{
    MMSYSERR_ERROR,
    MMSYSERR_BADDEVICEID,
    MMSYSERR_NOTENABLED,
    MMSYSERR_ALLOCATED,
    MMSYSERR_INVALHANDLE,
    MMSYSERR_NODRIVER,
    MMSYSERR_NOMEM,
    MMSYSERR_NOTSUPPORTED,
    MMSYSERR_BADERRNUM,
    MMSYSERR_INVALFLAG,
    MMSYSERR_INVALPARAM,
    MMSYSERR_HANDLEBUSY,
    MMSYSERR_INVALIDALIAS,
    MMSYSERR_BADDB,
    MMSYSERR_KEYNOTFOUND,
    MMSYSERR_READERROR,
    MMSYSERR_WRITEERROR,
    MMSYSERR_DELETEERROR,
    MMSYSERR_VALNOTFOUND,
    MMSYSERR_NODRIVERCB,
    MMSYSERR_MOREDATA,
    MMSYSERR_UNKNOWNERROR,
};

fn midiMmResultCheck(res: c.MMRESULT) MmResultError!void {
    const res_code: MmResultEnum = @enumFromInt(res);
    switch (res_code) {
        .MMSYSERR_NOERROR => return,
        .MMSYSERR_ERROR => return error.MMSYSERR_ERROR,
        .MMSYSERR_BADDEVICEID => return error.MMSYSERR_BADDEVICEID,
        .MMSYSERR_NOTENABLED => return error.MMSYSERR_NOTENABLED,
        .MMSYSERR_ALLOCATED => return error.MMSYSERR_ALLOCATED,
        .MMSYSERR_INVALHANDLE => return error.MMSYSERR_INVALHANDLE,
        .MMSYSERR_NODRIVER => return error.MMSYSERR_NODRIVER,
        .MMSYSERR_NOMEM => return error.MMSYSERR_NOMEM,
        .MMSYSERR_NOTSUPPORTED => return error.MMSYSERR_NOTSUPPORTED,
        .MMSYSERR_BADERRNUM => return error.MMSYSERR_BADERRNUM,
        .MMSYSERR_INVALFLAG => return error.MMSYSERR_INVALFLAG,
        .MMSYSERR_INVALPARAM => return error.MMSYSERR_INVALPARAM,
        .MMSYSERR_HANDLEBUSY => return error.MMSYSERR_HANDLEBUSY,
        .MMSYSERR_INVALIDALIAS => return error.MMSYSERR_INVALIDALIAS,
        .MMSYSERR_BADDB => return error.MMSYSERR_BADDB,
        .MMSYSERR_KEYNOTFOUND => return error.MMSYSERR_KEYNOTFOUND,
        .MMSYSERR_READERROR => return error.MMSYSERR_READERROR,
        .MMSYSERR_WRITEERROR => return error.MMSYSERR_WRITEERROR,
        .MMSYSERR_DELETEERROR => return error.MMSYSERR_DELETEERROR,
        .MMSYSERR_VALNOTFOUND => return error.MMSYSERR_VALNOTFOUND,
        .MMSYSERR_NODRIVERCB => return error.MMSYSERR_NODRIVERCB,
        .MMSYSERR_MOREDATA => return error.MMSYSERR_MOREDATA,
        else => return error.MMSYSERR_UNKNOWNERROR,
    }
}

pub fn midiInGetNumDevs() usize {
    return c.midiInGetNumDevs();
}

pub fn midiInGetDevCaps(deviceId: c.UINT) MmResultError!c.MIDIINCAPS {
    var midiInCaps: c.MIDIINCAPS = undefined;
    const res = c.midiInGetDevCapsA(deviceId, &midiInCaps, @sizeOf(c.MIDIINCAPS));
    try midiMmResultCheck(res);
    return midiInCaps;
}

pub const MidiInProc = *const fn (hMidiIn: c.HMIDIIN, wMsg: c.UINT, dwInstance: c.DWORD_PTR, dwParam1: c.DWORD_PTR, dwParam2: c.DWORD_PTR) callconv(.winapi) void;

pub fn midiInOpen(deviceId: c.UINT, cb: MidiInProc, data: ?*anyopaque) MmResultError!c.HMIDIIN {
    var midiIn: c.HMIDIIN = undefined;
    const res = c.midiInOpen(&midiIn, deviceId, @intFromPtr(cb), @intFromPtr(data), c.CALLBACK_FUNCTION);
    try midiMmResultCheck(res);
    return midiIn;
}

pub fn midiInStart(midiDevice: c.HMIDIIN) MmResultError!void {
    return midiMmResultCheck(c.midiInStart(midiDevice));
}

pub fn midiInStop(midiDevice: c.HMIDIIN) MmResultError!void {
    return midiMmResultCheck(c.midiInStop(midiDevice));
}

pub fn midiInClose(midiDevice: c.HMIDIIN) MmResultError!void {
    return midiMmResultCheck(c.midiInClose(midiDevice));
}

pub fn midiInGetID(midiDevice: c.HMIDIIN) MmResultError!c.UINT {
    var midiInDeviceId: c.UINT = undefined;
    const res = c.midiInGetID(midiDevice, &midiInDeviceId);
    try midiMmResultCheck(res);
    return midiInDeviceId;
}
