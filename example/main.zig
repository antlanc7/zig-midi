const std = @import("std");
const midi = @import("zig_midi");

fn cb(msg: midi.MidiData, user_data: ?*anyopaque) void {
    const device_id_ptr: *const midi.MidiDeviceId = @ptrCast(@alignCast(user_data));
    const device_id = device_id_ptr.*;
    if (msg.status != 0xf8 and msg.status != 0xfe) {
        std.log.info("MIDI event input ID {}: [{}] data: {} {} {}", .{ device_id, msg.timestamp, msg.status, msg.data1, msg.data2 });
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
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
    var stdin_reader = std.Io.File.stdin().reader(io, &stdin_buffer);
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
        .data = @constCast(&deviceIndex),
    };
    const midiIn = try midi.midiInOpen(deviceIndex, &user_cb_data);
    std.log.info("MIDI input device with id {} opened", .{deviceIndex});
    main_loop: while (true) {
        const line = stdin.takeDelimiterInclusive('\n') catch @panic("stdin fail");
        const cmd = std.mem.trim(u8, line, &std.ascii.whitespace);
        const exit_cmds = [_][]const u8{ "exit", "q", "quit" };
        for (exit_cmds) |exit_cmd| {
            if (std.mem.eql(u8, cmd, exit_cmd)) {
                break :main_loop;
            }
        }
        try io.sleep(.fromMilliseconds(100), .boot);
    }
    try midi.midiInClose(midiIn);
    std.log.info("MIDI input closed, exiting...", .{});
}
