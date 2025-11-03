const std = @import("std");
const wm = @import("winmm");
const common = @import("common");

pub const DeviceHandle = wm.c.HMIDIIN;

pub const MidiDevice = struct {
    user_cb_data: *const common.MidiEventCallbackData,
    handle: DeviceHandle,
};

fn driver_cb(hMidiIn: wm.c.HMIDIIN, wMsg: wm.c.UINT, dwInstance: wm.c.DWORD_PTR, dwParam1: wm.c.DWORD_PTR, dwParam2: wm.c.DWORD_PTR) callconv(.winapi) void {
    _ = hMidiIn;
    const user_cb: *const common.MidiEventCallbackData = @ptrFromInt(dwInstance);
    const msgType: wm.MimMessageType = @enumFromInt(wMsg);
    if (msgType == .MIM_DATA) {
        const data = std.mem.toBytes(dwParam1);
        const opcode = data[0];
        const status = opcode & 0xf0;
        const channel: u4 = @truncate(opcode);
        const is_sys_msg = status == 0xf0;
        const midiData: common.MidiData = .{
            .status = if (is_sys_msg) opcode else status,
            .channel = if (is_sys_msg) 0 else channel,
            .data1 = data[1],
            .data2 = data[2],
            .timestamp = dwParam2,
        };
        user_cb.cb(midiData, user_cb.data);
    }
}

pub fn midiInOpen(device_id: common.MidiDeviceId, user_cb_data: *const common.MidiEventCallbackData) !MidiDevice {
    const device_id_int = std.fmt.parseInt(c_uint, device_id, 10) catch return error.InvalidDeviceId;
    const dev = try wm.midiInOpen(device_id_int, driver_cb, @constCast(user_cb_data));
    try wm.midiInStart(dev);
    return .{
        .user_cb_data = user_cb_data,
        .handle = dev,
    };
}

pub fn midiInClose(device: MidiDevice) !void {
    try wm.midiInStop(device.handle);
    try wm.midiInClose(device.handle);
}

pub fn getMidiInDeviceCount() usize {
    return wm.midiInGetNumDevs();
}

pub fn forEachMidiDevice(cb: *const fn (deviceId: common.MidiDeviceId, deviceName: [:0]const u8, user_data: ?*anyopaque) void, user_data: ?*anyopaque) void {
    const nDevices = wm.midiInGetNumDevs();
    for (0..nDevices) |i| {
        const id: c_uint = @intCast(i);
        const caps = wm.midiInGetDevCaps(id) catch continue;
        var id_str_buf: [16]u8 = undefined;
        const id_str = std.fmt.bufPrintZ(&id_str_buf, "{d}", .{id}) catch unreachable;
        const name: [*c]const u8 = @ptrCast(&caps.szPname);
        const name_slice = std.mem.span(name);
        cb(id_str, name_slice, user_data);
    }
}
