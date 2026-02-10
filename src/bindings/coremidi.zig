const std = @import("std");
const c = @cImport({
    @cInclude("CoreFoundation/CoreFoundation.h");
    @cInclude("CoreMIDI/CoreMIDI.h");
});

pub const MIDIClientRef = c.MIDIClientRef;
pub const MIDIPortRef = c.MIDIPortRef;
pub const CFStringRefNotNull = *const c.struct___CFString;
pub const MIDIPacketList = c.MIDIPacketList;

pub extern const kMIDIPropertyName: c.CFStringRef;
pub extern const kMIDIPropertyManufacturer: c.CFStringRef;
pub extern const kMIDIPropertyModel: c.CFStringRef;
pub extern const kMIDIPropertyUniqueID: c.CFStringRef;
pub extern const kMIDIPropertyDeviceID: c.CFStringRef;
pub extern const kMIDIPropertyReceiveChannels: c.CFStringRef;
pub extern const kMIDIPropertyTransmitChannels: c.CFStringRef;
pub extern const kMIDIPropertyMaxSysExSpeed: c.CFStringRef;
pub extern const kMIDIPropertyAdvanceScheduleTimeMuSec: c.CFStringRef;
pub extern const kMIDIPropertyIsEmbeddedEntity: c.CFStringRef;
pub extern const kMIDIPropertyIsBroadcast: c.CFStringRef;
pub extern const kMIDIPropertySingleRealtimeEntity: c.CFStringRef;
pub extern const kMIDIPropertyConnectionUniqueID: c.CFStringRef;
pub extern const kMIDIPropertyOffline: c.CFStringRef;
pub extern const kMIDIPropertyPrivate: c.CFStringRef;
pub extern const kMIDIPropertyDriverOwner: c.CFStringRef;
pub extern const kMIDIPropertyFactoryPatchNameFile: c.CFStringRef;
pub extern const kMIDIPropertyUserPatchNameFile: c.CFStringRef;
pub extern const kMIDIPropertyNameConfiguration: c.CFStringRef;
pub extern const kMIDIPropertyNameConfigurationDictionary: c.CFStringRef;
pub extern const kMIDIPropertyImage: c.CFStringRef;
pub extern const kMIDIPropertyDriverVersion: c.CFStringRef;
pub extern const kMIDIPropertySupportsGeneralMIDI: c.CFStringRef;
pub extern const kMIDIPropertySupportsMMC: c.CFStringRef;
pub extern const kMIDIPropertyCanRoute: c.CFStringRef;
pub extern const kMIDIPropertyReceivesClock: c.CFStringRef;
pub extern const kMIDIPropertyReceivesMTC: c.CFStringRef;
pub extern const kMIDIPropertyReceivesNotes: c.CFStringRef;
pub extern const kMIDIPropertyReceivesProgramChanges: c.CFStringRef;
pub extern const kMIDIPropertyReceivesBankSelectMSB: c.CFStringRef;
pub extern const kMIDIPropertyReceivesBankSelectLSB: c.CFStringRef;
pub extern const kMIDIPropertyTransmitsClock: c.CFStringRef;
pub extern const kMIDIPropertyTransmitsMTC: c.CFStringRef;
pub extern const kMIDIPropertyTransmitsNotes: c.CFStringRef;
pub extern const kMIDIPropertyTransmitsProgramChanges: c.CFStringRef;
pub extern const kMIDIPropertyTransmitsBankSelectMSB: c.CFStringRef;
pub extern const kMIDIPropertyTransmitsBankSelectLSB: c.CFStringRef;
pub extern const kMIDIPropertyPanDisruptsStereo: c.CFStringRef;
pub extern const kMIDIPropertyIsSampler: c.CFStringRef;
pub extern const kMIDIPropertyIsDrumMachine: c.CFStringRef;
pub extern const kMIDIPropertyIsMixer: c.CFStringRef;
pub extern const kMIDIPropertyIsEffectUnit: c.CFStringRef;
pub extern const kMIDIPropertyMaxReceiveChannels: c.CFStringRef;
pub extern const kMIDIPropertyMaxTransmitChannels: c.CFStringRef;
pub extern const kMIDIPropertyDriverDeviceEditorApp: c.CFStringRef;
pub extern const kMIDIPropertySupportsShowControl: c.CFStringRef;
pub extern const kMIDIPropertyDisplayName: c.CFStringRef;
pub extern const kMIDIPropertyProtocolID: c.CFStringRef;
pub extern const kMIDIPropertyUMPActiveGroupBitmap: c.CFStringRef;
pub extern const kMIDIPropertyUMPCanTransmitGroupless: c.CFStringRef;
pub extern const kMIDIPropertyAssociatedEndpoint: c.CFStringRef;

pub const kCFStringEncodingMacRoman = c.kCFStringEncodingMacRoman;
pub const kCFStringEncodingWindowsLatin1 = c.kCFStringEncodingWindowsLatin1;
pub const kCFStringEncodingISOLatin1 = c.kCFStringEncodingISOLatin1;
pub const kCFStringEncodingNextStepLatin = c.kCFStringEncodingNextStepLatin;
pub const kCFStringEncodingASCII = c.kCFStringEncodingASCII;
pub const kCFStringEncodingUnicode = c.kCFStringEncodingUnicode;
pub const kCFStringEncodingUTF8 = c.kCFStringEncodingUTF8;
pub const kCFStringEncodingNonLossyASCII = c.kCFStringEncodingNonLossyASCII;
pub const kCFStringEncodingUTF16 = c.kCFStringEncodingUTF16;
pub const kCFStringEncodingUTF16BE = c.kCFStringEncodingUTF16BE;
pub const kCFStringEncodingUTF16LE = c.kCFStringEncodingUTF16LE;
pub const kCFStringEncodingUTF32 = c.kCFStringEncodingUTF32;
pub const kCFStringEncodingUTF32BE = c.kCFStringEncodingUTF32BE;
pub const kCFStringEncodingUTF32LE = c.kCFStringEncodingUTF32LE;

const CoreMidiError = error.CoreMidiError;

fn OSStatusCheck(status: c.OSStatus) !void {
    if (status != 0) {
        return CoreMidiError;
    }
}

pub const CFSTR = c.__CFStringMakeConstantString;

pub const MIDIGetNumberOfSources = c.MIDIGetNumberOfSources;
pub const MIDIGetSource = c.MIDIGetSource;

pub fn MIDIPortDisconnectSource(port: MIDIPortRef, source: c.MIDIPortRef) !void {
    return OSStatusCheck(c.MIDIPortDisconnectSource(port, source));
}

pub fn MIDIPortDispose(port: MIDIPortRef) !void {
    return OSStatusCheck(c.MIDIPortDispose(port));
}

pub fn MIDIClientDispose(client: MIDIClientRef) !void {
    return OSStatusCheck(c.MIDIClientDispose(client));
}

pub fn MIDIObjectGetStringProperty(source: c.MIDIObjectRef, propertyID: c.CFStringRef) !CFStringRefNotNull {
    var cfStringNullable: c.CFStringRef = undefined;
    const result = c.MIDIObjectGetStringProperty(source, propertyID, &cfStringNullable);
    try OSStatusCheck(result);
    return cfStringNullable orelse CoreMidiError;
}

pub fn CFStringGetCStringPtr(cfString: c.CFStringRef, encoding: c.CFStringEncoding) ?[*:0]const u8 {
    return c.CFStringGetCStringPtr(cfString, encoding);
}

pub fn CFStringGetCString(cfString: c.CFStringRef, buffer: []u8, encoding: c.CFStringEncoding) ![*:0]u8 {
    const res = c.CFStringGetCString(cfString, buffer.ptr, @intCast(buffer.len), encoding);
    if (res == 0) return CoreMidiError;
    const out: [*:0]u8 = @ptrCast(buffer.ptr);
    return out;
}

pub const CFRelease = c.CFRelease;

pub fn MIDIClientCreate(name: [*:0]const u8, notifyProc: c.MIDINotifyProc, notifyRefCon: ?*anyopaque) !MIDIClientRef {
    var client: MIDIClientRef = undefined;
    const result = c.MIDIClientCreate(CFSTR(name), notifyProc, notifyRefCon, &client);
    try OSStatusCheck(result);
    return client;
}

pub fn MIDIInputPortCreate(client: MIDIClientRef, name: [*:0]const u8, readProc: c.MIDIReadProc, refCon: ?*anyopaque) !MIDIPortRef {
    var port: MIDIPortRef = undefined;
    const result = c.MIDIInputPortCreate(client, CFSTR(name), readProc, refCon, &port);
    try OSStatusCheck(result);
    return port;
}

// pub fn MIDIInputPortCreateWithProtocol_(client: MIDIClientRef, name: [*:0]const u8, protocol: c.MIDIProtocolID, receiveBlock: MIDIReceiveBlock) !MIDIPortRef {
//     var port: MIDIPortRef = undefined;
//     const result = c.MIDIInputPortCreateWithProtocol(client, CFSTR(name), protocol, &port, receiveBlock);
//     try OSStatusCheck(result);
//     return port;
// }

pub fn MIDIPortConnectSource(port: MIDIPortRef, source: c.MIDIPortRef, connRefCon: ?*anyopaque) !void {
    return OSStatusCheck(c.MIDIPortConnectSource(port, source, connRefCon));
}

pub fn MIDIPacketListGetPacket(packetList: *const c.MIDIPacketList) *align(4) const c.MIDIPacket {
    const packetListAddress: usize = @intFromPtr(packetList);
    const packetAddress = packetListAddress + 4;
    return @ptrFromInt(packetAddress);
}

pub fn MIDIPacketNext(pkt: *align(4) const c.MIDIPacket) *align(4) const c.MIDIPacket {
    return @ptrFromInt((@as(usize, @intCast(@intFromPtr(&pkt.*.data[pkt.*.length]))) +% @as(usize, @bitCast(@as(c_long, @as(c_int, 3))))) & @as(usize, @bitCast(@as(c_long, ~@as(c_int, 3)))));
}
