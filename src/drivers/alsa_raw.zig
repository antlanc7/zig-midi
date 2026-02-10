const std = @import("std");
const common = @import("common");
const ar = @import("alsa_raw");

pub const DeviceHandle = *ar.c.snd_rawmidi_t;

pub const MidiDevice = struct {
    user_cb_data: *const common.MidiEventCallbackData,
    handle: DeviceHandle,
};

fn midiThread(device: MidiDevice) void {
    var buf: [3]u8 = undefined;

    while (true) {
        const read = ar.snd_rawmidi_read(device.handle, @ptrCast(&buf[0])) catch continue;
        if (read == 1) {
            if (buf[0] < 0xF0) {
                const read_2 = ar.snd_rawmidi_read(device.handle, buf[1..]) catch continue;
                if (read_2 == 2) {
                    device.user_cb_data.cb(.{
                        .timestamp = 0,
                        .status = buf[0],
                        .data1 = buf[1],
                        .data2 = buf[2],
                    }, device.user_cb_data.data);
                }
            }
        }
    }
}

pub fn midiInOpen(device_id: common.MidiDeviceId, user_cb_data: *const common.MidiEventCallbackData) !MidiDevice {
    var device: MidiDevice = undefined;
    device.user_cb_data = user_cb_data;

    var nameBuf: [32]u8 = undefined;
    const name = try std.fmt.bufPrintZ(&nameBuf, "hw:{},0,0", .{device_id});

    try ar.snd_rawmidi_open(&device.handle, null, name, 0);

    const thread = try std.Thread.spawn(.{}, midiThread, .{device});
    thread.detach();

    return device;
}

pub fn midiInClose(device: MidiDevice) !void {
    try ar.snd_rawmidi_close(device.handle);
}

pub fn getMidiInDeviceCount() usize {
    return std.math.maxInt(i32);
}

pub fn forEachMidiDevice(cb: *const fn (deviceId: common.MidiDeviceId, deviceName: [*:0]const u8, user_data: ?*anyopaque) void, user_data: ?*anyopaque) void {
    var card: c_int = -1;
    while (true) {
        ar.snd_card_next(&card) catch break;
        var card_name_buf: [32]u8 = undefined;
        const card_name = std.fmt.bufPrintZ(&card_name_buf, "hw:{}", .{card}) catch unreachable;
        const ctl = ar.snd_ctl_open(card_name, 0) catch continue;
        defer ar.snd_ctl_close(ctl) catch {};

        var dev: c_int = -1;
        while (true) {
            ar.snd_ctl_rawmidi_next_device(ctl, &dev) catch break;
            const info = ar.snd_rawmidi_info_malloc() catch break;
            defer ar.snd_rawmidi_info_free(info);

            ar.snd_rawmidi_info_set_device(info, @intCast(dev));
            ar.snd_rawmidi_info_set_subdevice(info, 0);
            ar.snd_rawmidi_info_set_stream(info, .input);

            ar.snd_ctl_rawmidi_info(ctl, info) catch break;
            const device_name = ar.snd_rawmidi_info_get_name(info);
            const subdevice_name = ar.snd_rawmidi_info_get_subdevice_name(info);

            var name_buf: [64]u8 = undefined;
            const name = std.fmt.bufPrintZ(&name_buf, "{} {} {s}:{s}", .{ card, dev, device_name, subdevice_name }) catch unreachable;
            cb(@intCast(dev), name, user_data);
        }
    }
}
