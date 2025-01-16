const std = @import("std");
const types = @import("types.zig");

const net = std.net;
const mem = std.mem;
const Client = struct {
    const Self = @This();
    allocator: mem.Allocator,
    target_addr: net.Address,
    username: []const u8,
    pub fn connect(self: *Self) !net.Stream {
        const stream = net.tcpConnectToAddress(self.target_addr) catch |err| {
            std.debug.print("Error happened while connecting to address {any}\n", .{err});
            std.process.exit(1);
        };
        return stream;
    }
    pub fn init(allocator: mem.Allocator, username: []const u8, server_ip: [4]u8, server_port: u16) !*Client {
        var self = try allocator.create(Self);
        self.allocator = allocator;
        self.username = username;
        self.target_addr = net.Address.initIp4(server_ip, server_port);

        return self;
    }
    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const username = "bos vergec";
    const server_ip = .{ 127, 0, 0, 1 };
    const server_port: u16 = 4000;
    const client = try Client.init(allocator, username, server_ip, server_port);
    defer client.deinit();
    const stream = try client.connect();

    const command_buffer = try std.fmt.allocPrint(allocator, "{any} {s}", .{ types.Commands.CONNECT, client.username });
    defer allocator.free(command_buffer);
    const written = try stream.write(command_buffer);

    std.debug.print("{d} bytes written\n", .{written});
}
