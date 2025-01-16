const Connection = @import("std").net.Server.Connection;
pub const Commands = enum {
    CONNECT, // connect
    DISCONNECT,
    SEND,
};
pub const ClientErrors = error{ BadRequest, UnknownCommand };
pub const Message = struct {
    command: Commands,
    value: []const u8, //
};

pub const User = struct {
    connected: bool,
    username: []const u8, // max 64 chars
    connection: Connection,
};
