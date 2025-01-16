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
