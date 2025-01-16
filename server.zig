const std = @import("std");
const net = std.net;
const mem = std.mem;
const types = @import("types.zig");

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
    fn read_stream(self: *Self, connection: net.Server.Connection) ![]u8 {
        const page_size = 1024;
        var page: usize = 1;

        var buffer = try self.allocator.alloc(u8, page_size);
        defer self.allocator.free(buffer);

        while (true) {
            const start = (page - 1) * page_size;
            const end = page * page_size;

            if (buffer.len < end) {
                buffer = try self.allocator.realloc(buffer, end);
            }

            const slice = buffer[start..end];
            const read = try connection.stream.read(slice);

            if (read == 0) {
                break; // End of stream
            } else {
                std.debug.print("Read {d} bytes\n", .{read});
                page += 1;
            }
        }
        return buffer;
    }

    fn parse_message_buffer(buffer: []u8) types.ClientErrors!types.Message {
        var message_parts = mem.splitScalar(u8, buffer, " ");
        const command = message_parts.first();
        const value = message_parts.next() orelse return types.ClientErrors.BadRequest;

        var message = types.Message{};

        if (std.mem.eql(u8, command, "connect")) {
            message.command = types.Commands.CONNECT;
        } else if (std.mem.eql(u8, command, "disconnect")) {
            message.command = types.Commands.DISCONNECT;
        } else {
            return types.ClientErrors.UnknownCommand;
        }

        message.value = value;

        return message;
    }

    fn handle_command(message: types.Message) !void {
        switch (message.command) {
            types.Commands.CONNECT => {},
            types.Commands.DISCONNECT => {},
            types.Commands.SEND => {},
        }
    }

    fn mainloop(self: *Self) !void {
        std.debug.print("Server started\n", .{});

        while (true) {
            const connection = try self.server.accept();
            const buffer = try self.read_stream(connection);
            const message = parse_message_buffer(buffer) catch |err| {
                switch (err) {
                    types.ClientErrors.BadRequest => {
                        connection.stream.writeAll("ERR: Bad request -> {COMMAND} {VALUE}");
                    },
                    types.ClientErrors.UnknownCommand => {
                        connection.stream.writeAll("ERR: Unknown Command -> please send 'HELP' for command list");
                    },
                }
            };

            handle_command(message);
        }
    }
    pub fn run(self: *Self) !void {
        const listen_config = net.Address.ListenOptions{ .reuse_address = true, .reuse_port = true };
        const server = try self.addr.listen(listen_config);
        self.server = server;
        try self.mainloop();
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
