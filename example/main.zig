const std = @import("std");
const midi = @import("zig_midi");

fn cb(device_id: midi.MidiDeviceId, msg: midi.MidiData, user_data: ?*anyopaque) void {
    _ = user_data;
    std.log.info("MIDI event input ID {}: [{}] data: {} {} {}", .{ device_id, msg.timestamp, msg.status, msg.data1, msg.data2 });
}

pub fn main() !void {
    const nDevices = midi.getMidiInDeviceCount();
    std.log.info("Found {} devices", .{nDevices});
    if (nDevices == 0) {
        return error.NoMidiDevicesFound;
    }
    const for_each_device = struct {
        fn cb(device_id: midi.MidiDeviceId, device_name: [:0]const u8, user_data: ?*anyopaque) void {
            _ = user_data;
            std.log.info("Device {}: {s}", .{ device_id, device_name });
        }
    };
    midi.forEachMidiDevice(for_each_device.cb, null);
    std.log.info("Select MIDI device (0-{}): ", .{nDevices - 1});
    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;
    const deviceIndexStr = stdin.takeDelimiterInclusive('\n') catch return;
    const deviceIndex = std.fmt.parseInt(u32, std.mem.trim(u8, deviceIndexStr, &std.ascii.whitespace), 10) catch {
        return error.InvalidDeviceIndex;
    };
    if (deviceIndex > nDevices - 1) {
        return error.InvalidDeviceIndex;
    }
    const user_cb_data: midi.MidiEventCallbackData = .{
        .cb = cb,
        .data = null,
    };
    const midiIn = try midi.midiInOpen(deviceIndex, &user_cb_data);
    std.log.info("MIDI input device with id {} opened", .{deviceIndex});
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
