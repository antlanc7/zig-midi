const std = @import("std");
const common = @import("common");
const builtin = @import("builtin");
const driver = @import("driver");

pub const MidiDevice = driver.MidiDevice;

pub const getMidiInDeviceCount = driver.getMidiInDeviceCount;
pub const midiInOpen = driver.midiInOpen;
pub const midiInClose = driver.midiInClose;
pub const forEachMidiDevice = driver.forEachMidiDevice;

pub const MidiDeviceId = common.MidiDeviceId;
pub const MidiEventCallback = common.MidiEventCallback;
pub const MidiEventCallbackData = common.MidiEventCallbackData;
pub const MidiData = common.MidiData;
