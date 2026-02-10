const std = @import("std");
pub const c = @cImport({
    @cInclude("alsa/asoundlib.h");
});

fn snd_error_check(r: c_int) !void {
    if (r < 0) return error.snd_error;
}

fn snd_isize_check(r: isize) !usize {
    if (r < 0) return error.snd_error;
    return @intCast(r);
}

pub fn snd_rawmidi_open(inputp: ?**c.snd_rawmidi_t, outputp: ?**c.snd_rawmidi_t, name: [:0]const u8, mode: c_int) !void {
    var input: ?*c.snd_rawmidi_t = undefined;
    var output: ?*c.snd_rawmidi_t = undefined;
    try snd_error_check(c.snd_rawmidi_open(if (inputp != null) &input else null, if (outputp != null) &output else null, name, mode));
    if (inputp) |p| p.* = input.?;
    if (outputp) |p| p.* = output.?;
}

pub fn snd_rawmidi_close(handle: *c.snd_rawmidi_t) !void {
    return snd_error_check(c.snd_rawmidi_close(handle));
}

pub fn snd_rawmidi_read(handle: *c.snd_rawmidi_t, buf: []u8) !usize {
    return snd_isize_check(c.snd_rawmidi_read(handle, buf.ptr, buf.len));
}

pub fn snd_card_next(card: *c_int) !void {
    try snd_error_check(c.snd_card_next(card));
    try snd_error_check(card.*);
}

pub fn snd_ctl_open(name: [:0]const u8, mode: c_int) !*c.snd_ctl_t {
    var ctl: ?*c.snd_ctl_t = undefined;
    try snd_error_check(c.snd_ctl_open(&ctl, name, mode));
    return ctl.?;
}

pub fn snd_ctl_close(ctl: *c.snd_ctl_t) !void {
    return snd_error_check(c.snd_ctl_close(ctl));
}

pub fn snd_ctl_rawmidi_next_device(ctl: *c.snd_ctl_t, dev_iter: *c_int) !void {
    try snd_error_check(c.snd_ctl_rawmidi_next_device(ctl, dev_iter));
    try snd_error_check(dev_iter.*);
}

pub fn snd_rawmidi_info_malloc() !*c.snd_rawmidi_info_t {
    var info_opt: ?*c.snd_rawmidi_info_t = undefined;
    try snd_error_check(c.snd_rawmidi_info_malloc(&info_opt));
    return info_opt.?;
}

pub fn snd_rawmidi_info_free(info: *c.snd_rawmidi_info_t) void {
    c.snd_rawmidi_info_free(info);
}

pub fn snd_rawmidi_info_set_device(info: *c.snd_rawmidi_info_t, device: c_uint) void {
    c.snd_rawmidi_info_set_device(info, device);
}

pub fn snd_rawmidi_info_set_subdevice(info: *c.snd_rawmidi_info_t, subdevice: c_uint) void {
    c.snd_rawmidi_info_set_subdevice(info, subdevice);
}

pub const snd_rawmidi_stream_t = enum(c.snd_rawmidi_stream_t) {
    input = c.SND_RAWMIDI_STREAM_INPUT,
    output = c.SND_RAWMIDI_STREAM_OUTPUT,
};

pub fn snd_rawmidi_info_set_stream(info: *c.snd_rawmidi_info_t, stream: snd_rawmidi_stream_t) void {
    c.snd_rawmidi_info_set_stream(info, @intFromEnum(stream));
}

pub fn snd_ctl_rawmidi_info(ctl: *c.snd_ctl_t, info: *c.snd_rawmidi_info_t) !void {
    try snd_error_check(c.snd_ctl_rawmidi_info(ctl, info));
}

pub fn snd_rawmidi_info_get_name(info: *c.snd_rawmidi_info_t) [:0]const u8 {
    return std.mem.span(c.snd_rawmidi_info_get_name(info));
}

pub fn snd_rawmidi_info_get_subdevice_name(info: *c.snd_rawmidi_info_t) [:0]const u8 {
    return std.mem.span(c.snd_rawmidi_info_get_subdevice_name(info));
}
