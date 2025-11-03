const std = @import("std");
const common = @import("common");
const alsa = @import("alsa_seq");

pub const DeviceHandle = struct {
    handle: *alsa.snd_seq_t,
    port: c_int,
};

pub const MidiDevice = struct {
    user_cb_data: *const common.MidiEventCallbackData,
    handle: DeviceHandle,
};

// fn driver_cb() callconv(.c) void {
//     const midiData: common.MidiData = .{
//         .timestamp = packet.timeStamp,
//         .status = packet.data[0],
//         .data1 = if (packet.length >= 2) packet.data[1] else 0,
//         .data2 = if (packet.length >= 3) packet.data[2] else 0,
//     };
//     user_cb.cb(midiData, user_cb.data);
// }

fn midiThread(device: MidiDevice) void {
    const decoder = alsa.snd_midi_event_new(0) catch return;
    defer alsa.snd_midi_event_free(decoder);
    alsa.snd_midi_event_init(decoder);
    alsa.snd_midi_event_no_status(decoder, true);
    while (true) {
        const ev = alsa.snd_seq_event_input(device.handle.handle) catch continue;
        var ev_buffer: [12]u8 = undefined;
        const data = alsa.snd_midi_event_decode(decoder, &ev_buffer, ev) catch continue;
        if (data.len == 0) continue;
        const opcode = data[0];
        const status = opcode & 0xf0;
        const channel: u4 = @truncate(opcode);
        const is_sys_msg = status == 0xf0;
        device.user_cb_data.cb(.{
            .timestamp = ev.time.tick,
            .status = if (is_sys_msg) opcode else status,
            .channel = if (is_sys_msg) 0 else channel,
            .data1 = if (data.len > 1) data[1] else 0,
            .data2 = if (data.len > 2) data[2] else 0,
        }, device.user_cb_data.data);
    }
}

pub fn midiInOpen(device_id: common.MidiDeviceId, user_cb_data: *const common.MidiEventCallbackData) !MidiDevice {
    var tokenizer = std.mem.tokenizeScalar(u8, device_id, ',');
    const client_id_str = tokenizer.next() orelse return error.InvalidDeviceId;
    const client_id = std.fmt.parseInt(c_int, client_id_str, 10) catch return error.InvalidDeviceId;
    const port_id_str = tokenizer.next() orelse return error.InvalidDeviceId;
    const port_id = std.fmt.parseInt(c_int, port_id_str, 10) catch return error.InvalidDeviceId;

    var device: MidiDevice = undefined;
    device.user_cb_data = user_cb_data;

    device.handle.handle = try alsa.snd_seq_open("default", .SND_SEQ_OPEN_INPUT, .SND_SEQ_BLOCK);
    device.handle.port = try alsa.snd_seq_create_simple_port(
        device.handle.handle,
        "in",
        .{
            .SND_SEQ_PORT_CAP_WRITE = true,
            .SND_SEQ_PORT_CAP_SUBS_WRITE = true,
        },
        .{ .SND_SEQ_PORT_TYPE_APPLICATION = true },
    );

    try alsa.snd_seq_connect_from(device.handle.handle, device.handle.port, client_id, port_id);

    const thread = try std.Thread.spawn(.{}, midiThread, .{device});
    thread.detach();

    return device;
}

pub fn midiInClose(device: MidiDevice) !void {
    try alsa.snd_seq_close(device.handle.handle);
}

pub fn getMidiInDeviceCount() usize {
    var count: usize = 0;
    const cb = struct {
        pub fn cb(_: common.MidiDeviceId, _: [:0]const u8, user_data: ?*anyopaque) void {
            const count_ptr: *usize = @ptrCast(@alignCast(user_data));
            count_ptr.* += 1;
        }
    };
    forEachMidiDevice(cb.cb, &count);
    return count;
}

pub fn forEachMidiDevice(cb: *const fn (deviceId: common.MidiDeviceId, deviceName: [:0]const u8, user_data: ?*anyopaque) void, user_data: ?*anyopaque) void {
    // const nDevices = getMidiInDeviceCount();
    // for (0..nDevices) |i| {}
    _ = cb;
    _ = user_data;
}
