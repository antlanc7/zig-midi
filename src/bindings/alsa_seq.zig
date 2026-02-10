const std = @import("std");
pub const c = @cImport({
    @cInclude("alsa/asoundlib.h");
});

fn snd_error_check(r: c_int) !void {
    if (r < 0) return error.snd_error;
}

pub const snd_seq_open_streams_t = enum(c_int) {
    SND_SEQ_OPEN_OUTPUT = c.SND_SEQ_OPEN_OUTPUT,
    SND_SEQ_OPEN_INPUT = c.SND_SEQ_OPEN_INPUT,
    SND_SEQ_OPEN_DUPLEX = c.SND_SEQ_OPEN_DUPLEX,
};

pub const snd_seq_open_mode_t = enum(c_int) {
    SND_SEQ_BLOCK = 0,
    SND_SEQ_NONBLOCK = c.SND_SEQ_NONBLOCK,
};

pub const snd_seq_port_caps_t = packed struct(c_uint) {
    SND_SEQ_PORT_CAP_READ: bool = false,
    SND_SEQ_PORT_CAP_WRITE: bool = false,
    SND_SEQ_PORT_CAP_SYNC_READ: bool = false,
    SND_SEQ_PORT_CAP_SYNC_WRITE: bool = false,
    SND_SEQ_PORT_CAP_DUPLEX: bool = false,
    SND_SEQ_PORT_CAP_SUBS_READ: bool = false,
    SND_SEQ_PORT_CAP_SUBS_WRITE: bool = false,
    SND_SEQ_PORT_CAP_NO_EXPORT: bool = false,
    SND_SEQ_PORT_CAP_INACTIVE: bool = false,
    SND_SEQ_PORT_CAP_UMP_ENDPOINT: bool = false,
    _: u22 = 0,
};

pub const snd_seq_port_type_t = packed struct(c_uint) {
    SND_SEQ_PORT_TYPE_SPECIFIC: bool = false,
    SND_SEQ_PORT_TYPE_MIDI_GENERIC: bool = false,
    SND_SEQ_PORT_TYPE_MIDI_GM: bool = false,
    SND_SEQ_PORT_TYPE_MIDI_GS: bool = false,
    SND_SEQ_PORT_TYPE_MIDI_XG: bool = false,
    SND_SEQ_PORT_TYPE_MIDI_MT32: bool = false,
    SND_SEQ_PORT_TYPE_MIDI_GM2: bool = false,
    SND_SEQ_PORT_TYPE_MIDI_UMP: bool = false,
    SND_SEQ_PORT_TYPE_SYNTH: bool = false,
    SND_SEQ_PORT_TYPE_DIRECT_SAMPLE: bool = false,
    SND_SEQ_PORT_TYPE_SAMPLE: bool = false,
    SND_SEQ_PORT_TYPE_HARDWARE: bool = false,
    SND_SEQ_PORT_TYPE_SOFTWARE: bool = false,
    SND_SEQ_PORT_TYPE_SYNTHESIZER: bool = false,
    SND_SEQ_PORT_TYPE_PORT: bool = false,
    SND_SEQ_PORT_TYPE_APPLICATION: bool = false,
    _: u16 = 0,
};

pub fn snd_seq_open(name: [*:0]const u8, streams: snd_seq_open_streams_t, mode: snd_seq_open_mode_t) !*c.snd_seq_t {
    var handle: ?*c.snd_seq_t = undefined;
    const r = c.snd_seq_open(&handle, name, @intFromEnum(streams), @intFromEnum(mode));
    try snd_error_check(r);
    return handle.?;
}

pub fn snd_seq_close(handle: *c.snd_seq_t) !void {
    const r = c.snd_seq_close(handle);
    try snd_error_check(r);
}

pub fn snd_seq_create_simple_port(
    handle: *c.snd_seq_t,
    name: [*:0]const u8,
    caps: snd_seq_port_caps_t,
    @"type": snd_seq_port_type_t,
) !c_int {
    const r = c.snd_seq_create_simple_port(handle, name, @bitCast(caps), @bitCast(@"type"));
    try snd_error_check(r);
    return r;
}

pub fn snd_seq_event_input(handle: *c.snd_seq_t) !*c.snd_seq_event_t {
    var ev: ?*c.snd_seq_event_t = undefined;
    const r = c.snd_seq_event_input(handle, &ev);
    try snd_error_check(r);
    return ev.?;
}

pub fn snd_seq_free_event(ev: *c.snd_seq_event_t) !void {
    return snd_error_check(c.snd_seq_free_event(ev));
}

pub fn snd_midi_event_decode(dev: *c.snd_midi_event_t, buf: []u8, event: *const c.snd_seq_event_t) ![]u8 {
    const count = c.snd_midi_event_decode(dev, buf.ptr, @intCast(buf.len), event);
    try snd_error_check(@intCast(count));
    return buf[0..@intCast(count)];
}

pub fn snd_midi_event_new(buf_size: usize) !*c.snd_midi_event_t {
    var dev: ?*c.snd_midi_event_t = undefined;
    const r = c.snd_midi_event_new(buf_size, &dev);
    try snd_error_check(r);
    return dev.?;
}

pub fn snd_midi_event_init(dev: *c.snd_midi_event_t) void {
    c.snd_midi_event_init(dev);
}

pub fn snd_midi_event_no_status(dev: *c.snd_midi_event_t, on: bool) void {
    c.snd_midi_event_no_status(dev, @intFromBool(on));
}

pub fn snd_midi_event_free(dev: *c.snd_midi_event_t) void {
    c.snd_midi_event_free(dev);
}
