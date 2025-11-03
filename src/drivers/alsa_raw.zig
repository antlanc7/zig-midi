const std = @import("std");
const common = @import("common");
const ar = @import("alsa_raw");

pub const DeviceHandle = *ar.snd_rawmidi_t;

pub const MidiDevice = struct {
    user_cb_data: *const common.MidiEventCallbackData,
    handle: DeviceHandle,
};

fn midiThread(device: MidiDevice) void {
    var timer = std.time.Timer.start() catch unreachable;
    while (true) {
        var buf: [3]u8 = undefined;
        const status_buf = buf[0..1];
        const read = ar.snd_rawmidi_read(device.handle, status_buf) catch continue;
        if (read == 1 and (buf[0] & 0x80) != 0) {
            const opcode = buf[0];
            const status = opcode & 0xf0;
            const channel: u4 = @truncate(opcode);
            const status_u3: u3 = @truncate(status >> 4);
            const is_sys_msg = status_u3 == 7;
            const bytes_to_read: usize = switch (status_u3) {
                0...3, 6 => 2,
                4, 5 => 1,
                7 => switch (channel) {
                    1 => 1,
                    2 => 2,
                    3 => 1,
                    else => 0,
                },
            };
            const buf_to_read = buf[0..bytes_to_read];
            const read_2 = ar.snd_rawmidi_read(device.handle, buf_to_read) catch continue;
            if (read_2 == bytes_to_read) {
                device.user_cb_data.cb(.{
                    .timestamp = timer.read() / std.time.ns_per_ms,
                    .status = if (is_sys_msg) opcode else status,
                    .channel = if (is_sys_msg) 0 else channel,
                    .data1 = if (bytes_to_read >= 1) buf_to_read[0] else 0,
                    .data2 = if (bytes_to_read >= 2) buf_to_read[1] else 0,
                }, device.user_cb_data.data);
            }
        }
    }
}

pub fn midiInOpen(device_id: common.MidiDeviceId, user_cb_data: *const common.MidiEventCallbackData) !MidiDevice {
    var device: MidiDevice = undefined;
    device.user_cb_data = user_cb_data;

    var nameBuf: [32]u8 = undefined;
    const name = try std.fmt.bufPrintZ(&nameBuf, "hw:{s},0", .{device_id});

    ar.snd_rawmidi_open(&device.handle, null, name, 0) catch return error.InvalidDeviceId;

    const thread = try std.Thread.spawn(.{}, midiThread, .{device});
    thread.detach();

    return device;
}

pub fn midiInClose(device: MidiDevice) !void {
    try ar.snd_rawmidi_close(device.handle);
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

            var device_id_buf: [32]u8 = undefined;
            const device_id = std.fmt.bufPrint(&device_id_buf, "{},{}", .{ card, dev }) catch unreachable;

            var name_buf: [64]u8 = undefined;
            const name = std.fmt.bufPrintZ(&name_buf, "{s}:{s}", .{ device_name, subdevice_name }) catch unreachable;
            cb(device_id, name, user_data);
        }
    }
}
