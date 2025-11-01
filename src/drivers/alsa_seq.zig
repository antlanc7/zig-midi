const std = @import("std");
const common = @import("common");
const alsa = @import("alsa_seq");

pub const DeviceHandle = struct {
    handle: *alsa.c.snd_seq_t,
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
        const ev_data = alsa.snd_midi_event_decode(decoder, &ev_buffer, ev) catch continue;
        device.user_cb_data.cb(.{
            .timestamp = ev.time.tick,
            .status = if (ev_data.len > 0) ev_data[0] else 0,
            .data1 = if (ev_data.len > 1) ev_data[1] else 0,
            .data2 = if (ev_data.len > 2) ev_data[2] else 0,
        }, device.user_cb_data.data);
    }
}

pub fn midiInOpen(device_id: common.MidiDeviceId, user_cb_data: *const common.MidiEventCallbackData) !MidiDevice {
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

    _ = alsa.c.snd_seq_connect_from(device.handle.handle, device.handle.port, @intCast(device_id), 0);

    const thread = try std.Thread.spawn(.{}, midiThread, .{device});
    thread.detach();

    return device;
}

pub fn midiInClose(device: MidiDevice) !void {
    try alsa.snd_seq_close(device.handle.handle);
}

pub fn getMidiInDeviceCount() usize {
    return std.math.maxInt(i32);
}

pub fn forEachMidiDevice(cb: *const fn (deviceId: common.MidiDeviceId, deviceName: [:0]const u8, user_data: ?*anyopaque) void, user_data: ?*anyopaque) void {
    // const nDevices = getMidiInDeviceCount();
    // for (0..nDevices) |i| {}
    _ = cb;
    _ = user_data;
}
