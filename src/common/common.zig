pub const MidiDeviceId = u32;
pub const MidiEventCallback = *const fn (msg: MidiData, user_data: ?*anyopaque) void;
pub const MidiEventCallbackData = struct {
    cb: MidiEventCallback,
    data: ?*anyopaque,
};
pub const MidiData = struct {
    timestamp: u64,
    status: u8,
    data1: u8,
    data2: u8,
};
