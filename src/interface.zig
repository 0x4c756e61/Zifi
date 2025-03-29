const std = @import("std");

const c = @cImport({
    @cInclude("sys/socket.h");
    @cInclude("netinet/if_ether.h");
    @cInclude("sys/ioctl.h");
    @cInclude("arpa/inet.h");
    @cInclude("linux/if_packet.h");
    @cInclude("string.h");
    @cInclude("linux/wireless.h");
    @cInclude("stdio.h");
});

const csocket = c_int;
pub const InterfacePower = enum(c_short) { Up = c.IFF_UP, Down = ~c.IFF_UP };
pub const InterfaceMode = enum(c_uint) { Monitor = c.IW_MODE_MONITOR, Managed = c.IW_MODE_AUTO };
const InterfaceError = error{
    UninitiatedInterface,
    UnableToQueryInterfaceFlags,
    UnableToSetInterfaceFlags,
    UnableToCreateSocket,
    UnableToSwitchInterfaceMode,
    UnableToSendPacket,
    UnableToSwitchChanel,
};

pub const Interface = struct {
    _socket: ?csocket = null,
    _ifreq: c.ifreq = std.mem.zeroes(c.ifreq),
    _iwreq: c.iwreq = std.mem.zeroes(c.iwreq),

    pub fn init(self: *@This(), interface_name: []const u8) InterfaceError!void {
        self._socket = c.socket(c.AF_PACKET, c.SOCK_RAW, 0);

        if (self._socket.? == -1) {
            c.perror("init.rawsock");
            self._socket = null;
            return error.UnableToCreateSocket;
        }
        _ = c.strcpy(&self._ifreq.ifr_ifrn.ifrn_name, @ptrCast(interface_name));
        _ = c.strcpy(&self._iwreq.ifr_ifrn.ifrn_name, @ptrCast(interface_name));

        if (c.ioctl(self._socket.?, c.SIOCGIFINDEX, &self._ifreq) == -1) {
            std.debug.print("Could not get interface index: ", .{});
            c.perror("ioctl");
            return;
        }
    }

    pub fn switchPower(self: *@This(), power: InterfacePower) InterfaceError!void {
        if (self._socket == null) {
            return error.UninitiatedInterface;
        }

        if (c.ioctl(self._socket.?, c.SIOCGIFFLAGS, &self._ifreq) == -1) {
            c.perror("switchpower.flags");
            return error.UnableToQueryInterfaceFlags;
        }

        self._ifreq.ifr_ifru.ifru_flags &= @intFromEnum(power);

        if (c.ioctl(self._socket.?, c.SIOCSIFFLAGS, &self._ifreq) == -1) {
            c.perror("switchpower.setflags");
            return error.UnableToSetInterfaceFlags;
        }
    }

    pub fn switchMode(self: *@This(), mode: InterfaceMode) InterfaceError!void {
        if (self._socket == null) {
            return error.UninitiatedInterface;
        }

        self._iwreq.u.mode = @intFromEnum(mode);
        if (c.ioctl(self._socket.?, c.SIOCSIWMODE, &self._iwreq) == -1) {
            c.perror("switchmode.setmode");
            return error.UnableToSwitchInterfaceMode;
        }
    }

    pub fn switchChanel(self: *@This(), chanel: u8) InterfaceError!void {
        if (self._socket == null) {
            return error.UninitiatedInterface;
        }

        self._iwreq.u.freq.m = chanel;
        self._iwreq.u.freq.e = 0;

        if (c.ioctl(self._socket.?, c.SIOCSIWFREQ, &self._iwreq) == -1) {
            c.perror("switchanel");
            return error.UnableToSwitchChanel;
        }
    }

    pub fn sendPacket(self: *@This(), packet: []u8) InterfaceError!void {
        if (self._socket == null) {
            return error.UninitiatedInterface;
        }

        // could be move to the init function and inside the struct but oh well
        const sockaddr = c.sockaddr_ll{
            .sll_family = c.AF_PACKET,
            .sll_protocol = std.mem.nativeToBig(u16, c.ETH_P_ALL),
            .sll_ifindex = self._ifreq.ifr_ifru.ifru_ivalue,
            .sll_halen = 6,
            .sll_addr = [_]u8{ 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0, 0 },
        };

        if (c.sendto(self._socket.?, packet.ptr, packet.len, 0, @ptrCast(&sockaddr), @sizeOf(c.sockaddr_ll)) == -1) {
            c.perror("sendPacket");
            return error.UnableToSendPacket;
        }
    }
};
