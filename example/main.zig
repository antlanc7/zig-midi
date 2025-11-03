const std = @import("std");
const midi = @import("zig_midi");

fn cb(msg: midi.MidiData, user_data: ?*anyopaque) void {
    const device_id_ptr: *const midi.MidiDeviceId = @ptrCast(@alignCast(user_data));
    const device_id = device_id_ptr.*;
    if (msg.status != 0xf8 and msg.status != 0xfe) {
        std.log.info("MIDI event input ID {s}: [{}] data: {} {} {}", .{ device_id, msg.timestamp, msg.status, msg.data1, msg.data2 });
    }
}

pub fn main() !void {
    const nDevices = midi.getMidiInDeviceCount();
    std.debug.print("Found {} devices\n", .{nDevices});
    if (nDevices == 0) {
        std.debug.print("No MIDI devices found\n", .{});
        return;
    }
    const for_each_device = struct {
        fn cb(device_id: midi.MidiDeviceId, device_name: [:0]const u8, user_data: ?*anyopaque) void {
            _ = user_data;
            std.debug.print("Device [{s}]: {s}\n", .{ device_id, device_name });
        }
    };
    midi.forEachMidiDevice(for_each_device.cb, null);
    std.debug.print("Select MIDI device: \n", .{});
    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;
    const device_id_line = stdin.takeDelimiterInclusive('\n') catch return;
    const device_id = std.mem.trim(u8, device_id_line, &std.ascii.whitespace);
    const user_cb_data: midi.MidiEventCallbackData = .{
        .cb = cb,
        .data = @ptrCast(@constCast(&device_id)),
    };
    const midiIn = try midi.midiInOpen(device_id, &user_cb_data);
    std.log.info("MIDI input device {s} opened", .{device_id});
    main_loop: while (true) {
        const line = stdin.takeDelimiterInclusive('\n') catch return;
        const cmd = std.mem.trim(u8, line, &std.ascii.whitespace);
        const exit_cmds: [3][]const u8 = .{ "exit", "q", "quit" };
        for (exit_cmds) |exit_cmd| {
            if (std.mem.eql(u8, cmd, exit_cmd)) {
                break :main_loop;
            }
        }
        std.Thread.sleep(100);
    }
    try midi.midiInClose(midiIn);
    std.log.info("MIDI input closed, exiting...", .{});
}
