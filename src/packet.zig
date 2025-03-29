const std = @import("std");
const ArrayList = std.ArrayList;

const ether_addr = packed struct {
    b1: u8,
    b2: u8,
    b3: u8,
    b4: u8,
    b5: u8,
    b6: u8,
};
const default_beacon_interval = 0x64;

const ether_addr_null = ether_addr{ .b1 = 0, .b2 = 0, .b3 = 0, .b4 = 0, .b5 = 0, .b6 = 0 };
const ether_addr_broadcast = ether_addr{ .b1 = 0xFF, .b2 = 0xFF, .b3 = 0xFF, .b4 = 0xFF, .b5 = 0xFF, .b6 = 0xFF };

const default_11b_rates = "\x01\x04\x82\x84\x8b\x96";
const wpa_aes_tag = "\xDD\x18\x00\x50\xF2\x01\x01\x00\x00\x50\xF2\x04\x01\x00\x00\x50\xF2\x04\x01\x00\x00\x50\xF2\x02\x00\x00";

const header_type = enum(u8) { beacon = 0x80 };

pub const beacon_pkt = packed struct {
    type: header_type = header_type.beacon,
    flags: u8 = 0x00,
    duration: u16 = 0,
    addr1: ether_addr = ether_addr_broadcast,
    addr2: ether_addr = ether_addr_null,
    addr3: ether_addr = ether_addr_null,
    fragment_sequence: u16 = 0,
    timestamp: u64 = std.mem.nativeToLittle(u64, 0x400 * default_beacon_interval),
    interval: u16 = std.mem.nativeToLittle(u64, default_beacon_interval),
    capabilities: u16 = 0x0001,
    ssid_param: u8 = 0x00,
    ssid_len: u8 = undefined,
};

pub fn createBeaconFrame(alloc: *ArrayList(u8), bssid: ether_addr, ssid: []const u8, channel: u8) ![]u8 {
    alloc.clearAndFree();
    var pkt = beacon_pkt{};

    pkt.addr1 = ether_addr_broadcast;
    pkt.addr2 = bssid;
    pkt.addr3 = bssid;

    // say we support encryption
    pkt.capabilities |= 0x0010;
    pkt.ssid_len = @truncate(ssid.len); // hello world

    // transform our pkt into bytes
    const pkt_bytes = std.mem.asBytes(&pkt);
    try alloc.appendSlice(pkt_bytes);
    try alloc.appendSlice(ssid);
    try alloc.appendSlice(default_11b_rates);

    try alloc.append(0x03);
    try alloc.append(0x01);
    try alloc.append(channel);

    try alloc.appendSlice(wpa_aes_tag);

    return alloc.items;
}
