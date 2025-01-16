const std = @import("std");
const net = std.net;
const mem = std.mem;

const Server = struct {
    const Self = @This();

    port: u16,
    server: net.Server,
    allocator: mem.Allocator,
    addr: net.Address,
    public: bool,

    fn init_ip(public: bool, port: u16) net.Address {
        if (public) {
            return net.Address.initIp4(.{ 0, 0, 0, 0 }, port);
        } else {
            return net.Address.initIp4(.{ 127, 0, 0, 1 }, port);
        }
    }

    pub fn init(allocator: mem.Allocator, port: u16, public: ?bool) !*Server {
        var self = try allocator.create(Self);
        self.allocator = allocator;
        self.port = port;
        self.public = public orelse false;
        self.addr = init_ip(self.public, self.port);

        return self;
    }
    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }
    fn read_stream(self: *Self) !void {
        const page_size = 1024;
        var page = 0;
        const buffer = try self.allocator.alloc(u8, page_size);
        while (true) {
            const read = try self.server.stream.read(buffer[(page-1) * page_size..page_size * page.. ]);
            if (read == 0) {
                break;
            } else {}
        }
    }
    fn mainloop(self: *Self) void {
        std.debug.print("Server started\n", .{});

        while (true) {
            self.read_stream();
        }
    }
    pub fn run(self: *Self) !void {
        const listen_config = net.Address.ListenOptions{ .reuse_address = true, .reuse_port = true };
        const server = try self.addr.listen(listen_config);
        self.server = server;
        mainloop();
    }
};
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const port: u16 = 4000;
    var server = try Server.init(allocator, port, false);
    defer server.deinit();
    try server.run();
}
