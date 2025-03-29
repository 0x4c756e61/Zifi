const std = @import("std");
const ArrayList = std.ArrayList;

const packet = @import("packet");
const interface = @import("interface");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    if (std.os.linux.getuid() != 0) {
        std.debug.print("This program must be ran as root !", .{});
        return;
    }

    const rnd = std.crypto.random;

    var iiface = interface.Interface{};
    try iiface.init("wlan0");

    try iiface.switchPower(.Down);
    try iiface.switchMode(.Monitor);
    try iiface.switchPower(.Up);

    const ssid = "hello world";
    var pkt = ArrayList(u8).init(debug_allocator.allocator());
    defer pkt.deinit();

    for (0..100000) |_| {
        const chan = rnd.uintLessThan(u8, 14) + 1;
        const finalized_pkt = try packet.createBeaconFrame(&pkt, .{
            .b1 = rnd.uintLessThan(u8, 255),
            .b2 = rnd.uintLessThan(u8, 255),
            .b3 = rnd.uintLessThan(u8, 255),
            .b4 = rnd.uintLessThan(u8, 255),
            .b5 = rnd.uintLessThan(u8, 255),
            .b6 = rnd.uintLessThan(u8, 255),
        }, ssid, chan);
        //try iiface.switchChanel(chan);
        try iiface.sendPacket(finalized_pkt);
        std.Thread.sleep(100 * std.time.ns_per_ms);
    }

    try iiface.switchPower(.Down);
    try iiface.switchMode(.Managed);
    try iiface.switchPower(.Up);
}
