const std = @import("std");
const common = @import("common");
const cm = @import("coremidi");

pub const DeviceHandle = struct {
    client: cm.MIDIClientRef,
    input_port: cm.MIDIPortRef,
};

pub const MidiDevice = struct {
    user_cb_data: *const common.MidiEventCallbackData,
    handle: DeviceHandle,
};

fn driver_cb(
    packetListC: [*c]const cm.MIDIPacketList,
    readProcRefCon: ?*anyopaque,
    srcConnRefCon: ?*anyopaque,
) callconv(.c) void {
    _ = srcConnRefCon;
    const user_cb: *const common.MidiEventCallbackData = @ptrCast(@alignCast(readProcRefCon));
    const packetList: *const cm.MIDIPacketList = packetListC;
    var packet = cm.MIDIPacketListGetPacket(packetList);
    for (0..packetList.numPackets) |_| {
        const midiData: common.MidiData = .{
            .timestamp = packet.timeStamp,
            .status = packet.data[0],
            .data1 = if (packet.length >= 2) packet.data[1] else 0,
            .data2 = if (packet.length >= 3) packet.data[2] else 0,
        };
        user_cb.cb(midiData, user_cb.data);
        packet = cm.MIDIPacketNext(packet);
    }
}

pub fn midiInOpen(device_id: common.MidiDeviceId, user_cb_data: *const common.MidiEventCallbackData) !MidiDevice {
    var device: MidiDevice = undefined;
    device.user_cb_data = user_cb_data;
    device.handle.client = try cm.MIDIClientCreate("MidiInClient", null, null);
    device.handle.input_port = try cm.MIDIInputPortCreate(device.handle.client, "MidiInPort", driver_cb, @constCast(user_cb_data));
    try cm.MIDIPortConnectSource(device.handle.input_port, cm.MIDIGetSource(device_id), null);
    return device;
}

pub fn midiInClose(device: MidiDevice) !void {
    try cm.MIDIPortDisconnectSource(device.handle.input_port, cm.MIDIGetSource(0));
    try cm.MIDIPortDispose(device.handle.input_port);
    try cm.MIDIClientDispose(device.handle.client);
}

pub fn getMidiInDeviceCount() usize {
    return cm.MIDIGetNumberOfSources();
}

pub fn forEachMidiDevice(cb: *const fn (deviceId: common.MidiDeviceId, deviceName: [*:0]const u8, user_data: ?*anyopaque) void, user_data: ?*anyopaque) void {
    const nDevices = getMidiInDeviceCount();
    for (0..nDevices) |i| {
        const id: common.MidiDeviceId = @truncate(i);
        const source = cm.MIDIGetSource(i);
        const cfName = cm.MIDIObjectGetStringProperty(source, cm.kMIDIPropertyName) catch continue;
        defer cm.CFRelease(cfName);
        if (cm.CFStringGetCStringPtr(cfName, cm.kCFStringEncodingUTF8)) |name| {
            cb(id, name, user_data);
        } else {
            var buf: [256]u8 = undefined;
            const name = cm.CFStringGetCString(cfName, &buf, cm.kCFStringEncodingUTF8) catch continue;
            cb(id, name, user_data);
        }
    }
}
