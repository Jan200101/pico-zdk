const std = @import("std");
const builtin = @import("builtin");

const Io = std.Io;
const net = std.Io.net;
const File = std.Io.File;
const Dir = std.Io.Dir;
const HostName = std.Io.net.HostName;
const IpAddress = std.Io.net.IpAddress;
const process = std.process;
const Allocator = std.mem.Allocator;
const Alignment = std.mem.Alignment;
const c = std.c;
const fd_t = std.Io.File.Handle;
const native_os = builtin.os.tag;
const maxInt = std.math.maxInt;
const posix = std.posix;
const assert = std.debug.assert;
const mem = std.mem;
const socket_t = posix.socket_t;

const root = @import("root");

const has_networking = if (@hasDecl(root, "options") and @hasDecl(root.options, "networking"))
    root.options.networking
else
    true;

var stderr_writer: File.Writer = .{
    .io = io(),
    .interface = Io.File.Writer.initInterface(&.{}),
    .file = .stderr(),
    .mode = .streaming,
};

const c_decl = struct {
    pub fn getType(comptime decl: []const u8) type {
        return @TypeOf(
            if (@hasDecl(root, "c") and @hasDecl(root.c, decl))
                @field(root.c, decl)
            else
                @field(c, decl),
        );
    }

    pub fn getValue(comptime decl: []const u8) getType(decl) {
        return if (@hasDecl(root, "c") and @hasDecl(root.c, decl))
            @field(root.c, decl)
        else
            @field(c, decl);
    }
};

const _errno = c_decl.getValue("_errno");
const mode_t = c_decl.getValue("mode_t");
const off_t = c_decl.getValue("off_t");
const PATH_MAX = c_decl.getValue("PATH_MAX");
const E = c_decl.getValue("E");
const O = c_decl.getValue("O");
const AT = c_decl.getValue("AT");
const SEEK = c_decl.getValue("SEEK");
const sockaddr = c_decl.getValue("sockaddr");
const sa_family_t = c_decl.getValue("sa_family_t");
const AF = c_decl.getValue("AF");
const SOCK = c_decl.getValue("SOCK");
const socklen_t = c_decl.getValue("socklen_t");
const SOL = c_decl.getValue("SOL");
const SO = c_decl.getValue("SO");

pub fn cwd() Dir {
    return .{
        .handle = AT.FDCWD,
    };
}

pub fn io() Io {
    return .{
        .userdata = null,
        .vtable = &.{
            .async = async,
            .concurrent = concurrent,
            .await = await,
            .cancel = cancel,
            .select = select,

            .groupAsync = groupAsync,
            .groupConcurrent = groupConcurrent,
            .groupAwait = groupAwait,
            .groupCancel = groupCancel,

            .recancel = recancel,
            .swapCancelProtection = swapCancelProtection,
            .checkCancel = checkCancel,

            .futexWait = futexWait,
            .futexWaitUncancelable = futexWaitUncancelable,
            .futexWake = futexWake,

            .dirCreateDir = dirCreateDir,
            .dirCreateDirPath = dirCreateDirPath,
            .dirCreateDirPathOpen = dirCreateDirPathOpen,
            .dirStat = dirStat,
            .dirStatFile = dirStatFile,
            .dirAccess = dirAccess,
            .dirCreateFile = dirCreateFile,
            .dirCreateFileAtomic = dirCreateFileAtomic,
            .dirOpenFile = dirOpenFile,
            .dirOpenDir = dirOpenDir,
            .dirClose = dirClose,
            .dirRead = dirRead,
            .dirRealPath = dirRealPath,
            .dirRealPathFile = dirRealPathFile,
            .dirDeleteFile = dirDeleteFile,
            .dirDeleteDir = dirDeleteDir,
            .dirRename = dirRename,
            .dirRenamePreserve = dirRenamePreserve,
            .dirSymLink = dirSymLink,
            .dirReadLink = dirReadLink,
            .dirSetOwner = dirSetOwner,
            .dirSetFileOwner = dirSetFileOwner,
            .dirSetPermissions = dirSetPermissions,
            .dirSetFilePermissions = dirSetFilePermissions,
            .dirSetTimestamps = dirSetTimestamps,
            .dirHardLink = dirHardLink,

            .fileStat = fileStat,
            .fileLength = fileLength,
            .fileClose = fileClose,
            .fileWriteStreaming = fileWriteStreaming,
            .fileWritePositional = fileWritePositional,
            .fileWriteFileStreaming = fileWriteFileStreaming,
            .fileWriteFilePositional = fileWriteFilePositional,
            .fileReadStreaming = fileReadStreaming,
            .fileReadPositional = fileReadPositional,
            .fileSeekBy = fileSeekBy,
            .fileSeekTo = fileSeekTo,
            .fileSync = fileSync,
            .fileIsTty = fileIsTty,
            .fileEnableAnsiEscapeCodes = fileEnableAnsiEscapeCodes,
            .fileSupportsAnsiEscapeCodes = fileSupportsAnsiEscapeCodes,
            .fileSetLength = fileSetLength,
            .fileSetOwner = fileSetOwner,
            .fileSetPermissions = fileSetPermissions,
            .fileSetTimestamps = fileSetTimestamps,
            .fileLock = fileLock,
            .fileTryLock = fileTryLock,
            .fileUnlock = fileUnlock,
            .fileDowngradeLock = fileDowngradeLock,
            .fileRealPath = fileRealPath,
            .fileHardLink = fileHardLink,

            .processExecutableOpen = processExecutableOpen,
            .processExecutablePath = processExecutablePath,
            .lockStderr = lockStderr,
            .tryLockStderr = tryLockStderr,
            .unlockStderr = unlockStderr,
            .processSetCurrentDir = processSetCurrentDir,
            .processReplace = processReplace,
            .processReplacePath = processReplacePath,
            .processSpawn = processSpawn,
            .processSpawnPath = processSpawnPath,
            .childWait = childWait,
            .childKill = childKill,

            .progressParentFile = progressParentFile,

            .now = now,
            .sleep = sleep,

            .random = random,
            .randomSecure = randomSecure,

            .netListenIp = netListenIp,
            .netListenUnix = netListenUnix,
            .netAccept = netAccept,
            .netBindIp = netBindIp,
            .netConnectIp = netConnectIp,
            .netConnectUnix = netConnectUnix,
            .netClose = netClose,
            .netShutdown = netShutdown,
            .netRead = netRead,
            .netWrite = netWrite,
            .netWriteFile = netWriteFile,
            .netSend = netSend,
            .netReceive = netReceive,
            .netInterfaceNameResolve = netInterfaceNameResolve,
            .netInterfaceName = netInterfaceName,
            .netLookup = netLookup,
        },
    };
}

fn async(
    _: ?*anyopaque,
    _: []u8,
    _: Alignment,
    _: []const u8,
    _: Alignment,
    _: *const fn (_: *const anyopaque, _: *anyopaque) void,
) ?*Io.AnyFuture {
    @panic("async unimplemented");
}

fn concurrent(
    _: ?*anyopaque,
    _: usize,
    _: Alignment,
    _: []const u8,
    _: Alignment,
    _: *const fn (_: *const anyopaque, _: *anyopaque) void,
) Io.ConcurrentError!*Io.AnyFuture {
    @panic("concurrent unimplemented");
}

fn await(
    _: ?*anyopaque,
    _: *Io.AnyFuture,
    _: []u8,
    _: Alignment,
) void {
    @panic("await unimplemented");
}

fn cancel(
    _: ?*anyopaque,
    _: *Io.AnyFuture,
    _: []u8,
    _: Alignment,
) void {
    @panic("cancel unimplemented");
}

fn select(_: ?*anyopaque, _: []const *Io.AnyFuture) Io.Cancelable!usize {
    @panic("select unimplemented");
}

fn groupAsync(
    _: ?*anyopaque,
    _: *Io.Group,
    _: []const u8,
    _: Alignment,
    _: *const fn (_: *const anyopaque) Io.Cancelable!void,
) void {
    @panic("groupAsync unimplemented");
}

fn groupConcurrent(
    _: ?*anyopaque,
    _: *Io.Group,
    _: []const u8,
    _: Alignment,
    _: *const fn (_: *const anyopaque) Io.Cancelable!void,
) Io.ConcurrentError!void {
    @panic("groupConcurrent unimplemented");
}

fn groupAwait(_: ?*anyopaque, _: *Io.Group, _: *anyopaque) Io.Cancelable!void {
    @panic("groupAwait unimplemented");
}

fn groupCancel(_: ?*anyopaque, _: *Io.Group, _: *anyopaque) void {
    @panic("groupCancel unimplemented");
}

fn recancel(_: ?*anyopaque) void {
    @panic("recancel unimplemented");
}

fn swapCancelProtection(_: ?*anyopaque, _: Io.CancelProtection) Io.CancelProtection {
    return .unblocked;
}

fn checkCancel(_: ?*anyopaque) Io.Cancelable!void {
    @panic("checkCancel unimplemented");
}

fn futexWait(_: ?*anyopaque, _: *const u32, _: u32, _: Io.Timeout) Io.Cancelable!void {
    @panic("futexWait unimplemented");
}

fn futexWaitUncancelable(_: ?*anyopaque, _: *const u32, _: u32) void {
    @panic("futexWaitUncancelable unimplemented");
}

fn futexWake(_: ?*anyopaque, _: *const u32, _: u32) void {
    @panic("futexWake unimplemented");
}

fn dirCreateDir(_: ?*anyopaque, _: Dir, _: []const u8, _: Dir.Permissions) Dir.CreateDirError!void {
    @panic("dirCreateDir unimplemented");
}

fn dirCreateDirPath(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.Permissions,
) Dir.CreateDirPathError!Dir.CreatePathStatus {
    @panic("dirCreateDirPath unimplemented");
}

fn dirCreateDirPathOpen(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.Permissions,
    _: Dir.OpenOptions,
) Dir.CreateDirPathOpenError!Dir {
    @panic("dirCreateDirPathOpen unimplemented");
}

fn dirStat(_: ?*anyopaque, _: Dir) Dir.StatError!Dir.Stat {
    @panic("dirStat unimplemented");
}

fn dirStatFile(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.StatFileOptions,
) Dir.StatFileError!File.Stat {
    @panic("dirStatFile unimplemented");
}

fn dirAccess(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.AccessOptions,
) Dir.AccessError!void {
    @panic("dirAccess unimplemented");
}

fn dirCreateFile(
    _: ?*anyopaque,
    dir: Dir,
    sub_path: []const u8,
    flags: File.CreateFlags,
) File.OpenError!File {
    const f: O = .{
        .ACCMODE = if (flags.read) .RDWR else .WRONLY,
        .CREAT = true,
        .TRUNC = flags.truncate,
        .EXCL = flags.exclusive,
    };

    if (dir.handle == AT.FDCWD) {
        const fd = try system.open(sub_path, f, 0);
        return .{ .handle = fd };
    }

    return error.NoDevice;
}

fn dirCreateFileAtomic(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.CreateFileAtomicOptions,
) Dir.CreateFileAtomicError!File.Atomic {
    @panic("dirCreateFileAtomic unimplemented");
}

fn dirOpenFile(
    _: ?*anyopaque,
    dir: Dir,
    sub_path: []const u8,
    flags: File.OpenFlags,
) File.OpenError!File {
    const f: O = .{
        .ACCMODE = switch (flags.mode) {
            .read_only => .RDONLY,
            .write_only => .WRONLY,
            .read_write => .RDWR,
        },
    };

    if (dir.handle == AT.FDCWD) {
        const fd = try system.open(sub_path, f, 0);
        return .{ .handle = fd };
    }

    return error.NoDevice;
}

fn dirOpenDir(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.OpenOptions,
) Dir.OpenError!Dir {
    @panic("dirOpenDir unimplemented");
}

fn dirClose(_: ?*anyopaque, _: []const Dir) void {
    @panic("dirClose unimplemented");
}

fn dirRead(_: ?*anyopaque, _: *Dir.Reader, _: []Dir.Entry) Dir.Reader.Error!usize {
    @panic("dirRead unimplemented");
}

fn dirRealPath(_: ?*anyopaque, _: Dir, _: []u8) Dir.RealPathError!usize {
    @panic("dirRealPath unimplemented");
}

fn dirRealPathFile(_: ?*anyopaque, _: Dir, _: []const u8, _: []u8) Dir.RealPathFileError!usize {
    @panic("dirRealPathFile unimplemented");
}

fn dirDeleteFile(_: ?*anyopaque, dir: Dir, sub_path: []const u8) Dir.DeleteFileError!void {
    if (dir.handle == AT.FDCWD) {
        try system.unlink(sub_path);
        return;
    }

    return error.FileNotFound;
}

fn dirDeleteDir(_: ?*anyopaque, _: Dir, _: []const u8) Dir.DeleteDirError!void {
    @panic("dirDeleteDir unimplemented");
}

fn dirRename(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir,
    _: []const u8,
) Dir.RenameError!void {
    @panic("dirRename unimplemented");
}

fn dirRenamePreserve(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir,
    _: []const u8,
) Dir.RenamePreserveError!void {
    @panic("dirRenamePreserve unimplemented");
}

fn dirSymLink(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: []const u8,
    _: Dir.SymLinkFlags,
) Dir.SymLinkError!void {
    @panic("dirSymLink unimplemented");
}

fn dirReadLink(_: ?*anyopaque, _: Dir, _: []const u8, _: []u8) Dir.ReadLinkError!usize {
    @panic("dirReadLink unimplemented");
}

fn dirSetOwner(_: ?*anyopaque, _: Dir, _: ?File.Uid, _: ?File.Gid) Dir.SetOwnerError!void {
    @panic("dirSetOwner unimplemented");
}

fn dirSetFileOwner(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: ?File.Uid,
    _: ?File.Gid,
    _: Dir.SetFileOwnerOptions,
) Dir.SetFileOwnerError!void {
    @panic("unimplemented");
}

fn dirSetPermissions(_: ?*anyopaque, _: Dir, _: Dir.Permissions) Dir.SetPermissionsError!void {
    @panic("unimplemented");
}

fn dirSetFilePermissions(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.Permissions,
    _: Dir.SetFilePermissionsOptions,
) Dir.SetFilePermissionsError!void {
    @panic("dirSetFilePermissions unimplemented");
}

fn dirSetTimestamps(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.SetTimestampsOptions,
) Dir.SetTimestampsError!void {
    @panic("dirSetTimestamps unimplemented");
}

fn dirHardLink(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir,
    _: []const u8,
    _: Dir.HardLinkOptions,
) Dir.HardLinkError!void {
    @panic("dirHardLink unimplemented");
}

fn fileStat(_: ?*anyopaque, _: File) File.StatError!File.Stat {
    @panic("fileStat unimplemented");
}

fn fileLength(_: ?*anyopaque, _: File) File.LengthError!u64 {
    @panic("fileLength unimplemented");
}

fn fileClose(_: ?*anyopaque, files: []const File) void {
    for (files) |file|
        system.close(file.handle);
}

fn fileWriteStreaming(
    _: ?*anyopaque,
    file: File,
    header: []const u8,
    data: []const []const u8,
    splat: usize,
) File.Writer.Error!usize {
    if (header.len != 0) {
        return try system.write(file.handle, header);
    }

    for (data[0 .. data.len - 1]) |buf| {
        if (buf.len == 0) continue;
        return try system.write(file.handle, buf);
    }

    const pattern = data[data.len - 1];
    if (pattern.len == 0 or splat == 0) return 0;
    return try system.write(file.handle, pattern);
}

fn fileWritePositional(
    _: ?*anyopaque,
    _: File,
    _: []const u8,
    _: []const []const u8,
    _: usize,
    _: u64,
) File.WritePositionalError!usize {
    // a basic libc implementation does not have pwrite
    return error.Unseekable;
}

fn fileWriteFileStreaming(
    _: ?*anyopaque,
    _: File,
    _: []const u8,
    _: *File.Reader,
    _: Io.Limit,
) File.Writer.WriteFileError!usize {
    @panic("fileWriteFileStreaming unimplemented");
}

fn fileWriteFilePositional(
    _: ?*anyopaque,
    _: File,
    _: []const u8,
    _: *File.Reader,
    _: Io.Limit,
    _: u64,
) File.WriteFilePositionalError!usize {
    // a basic libc implementation does not have pwrite
    return error.Unseekable;
}

fn fileReadStreaming(_: ?*anyopaque, file: File, data: []const []u8) File.Reader.Error!usize {
    for (data) |buf| {
        if (buf.len == 0) continue;
        return try system.read(file.handle, buf);
    }

    return 0;
}

fn fileReadPositional(_: ?*anyopaque, _: File, _: []const []u8, _: u64) File.ReadPositionalError!usize {
    // a basic libc implementation does not have pread
    return error.Unseekable;
}

fn fileSeekBy(_: ?*anyopaque, file: File, offset: i64) File.SeekError!void {
    try system.lseek(file.handle, @intCast(offset), SEEK.CUR);
}

fn fileSeekTo(_: ?*anyopaque, file: File, pos: u64) File.SeekError!void {
    try system.lseek(file.handle, @intCast(pos), SEEK.SET);
}

fn fileSync(_: ?*anyopaque, _: File) File.SyncError!void {
    @panic("fileSync unimplemented");
}

fn fileIsTty(_: ?*anyopaque, _: File) Io.Cancelable!bool {
    @panic("fileIsTty unimplemented");
}

fn fileEnableAnsiEscapeCodes(_: ?*anyopaque, _: File) File.EnableAnsiEscapeCodesError!void {
    @panic("fileEnableAnsiEscapeCodes unimplemented");
}

fn fileSupportsAnsiEscapeCodes(_: ?*anyopaque, _: File) Io.Cancelable!bool {
    @panic("fileSupportsAnsiEscapeCodes unimplemented");
}

fn fileSetLength(_: ?*anyopaque, _: File, _: u64) File.SetLengthError!void {
    @panic("fileSetLength unimplemented");
}

fn fileSetOwner(_: ?*anyopaque, _: File, _: ?File.Uid, _: ?File.Gid) File.SetOwnerError!void {
    @panic("fileSetOwner unimplemented");
}

fn fileSetPermissions(_: ?*anyopaque, _: File, _: File.Permissions) File.SetPermissionsError!void {
    @panic("fileSetPermissions unimplemented");
}

fn fileSetTimestamps(
    _: ?*anyopaque,
    _: File,
    _: File.SetTimestampsOptions,
) File.SetTimestampsError!void {
    @panic("fileSetTimestampsunimplemented");
}

fn fileLock(_: ?*anyopaque, _: File, _: File.Lock) File.LockError!void {
    @panic("fileLock unimplemented");
}

fn fileTryLock(_: ?*anyopaque, _: File, _: File.Lock) File.LockError!bool {
    @panic("fileTryLock unimplemented");
}

fn fileUnlock(_: ?*anyopaque, _: File) void {
    @panic("fileUnlock unimplemented");
}

fn fileDowngradeLock(_: ?*anyopaque, _: File) File.DowngradeLockError!void {
    @panic("fileDowngradeLock unimplemented");
}

fn fileRealPath(_: ?*anyopaque, _: File, _: []u8) File.RealPathError!usize {
    @panic("fileRealPath unimplemented");
}

fn fileHardLink(
    _: ?*anyopaque,
    _: File,
    _: Dir,
    _: []const u8,
    _: File.HardLinkOptions,
) File.HardLinkError!void {
    @panic("unimplemented");
}

fn processExecutableOpen(_: ?*anyopaque, _: File.OpenFlags) process.OpenExecutableError!File {
    return error.NoDevice;
}

fn processExecutablePath(_: ?*anyopaque, _: []u8) process.ExecutablePathError!usize {
    return error.NoDevice;
}

fn lockStderr(_: ?*anyopaque, _: ?Io.Terminal.Mode) Io.Cancelable!Io.LockedStderr {
    return .{
        .file_writer = &stderr_writer,
        .terminal_mode = .no_color,
    };
}

fn tryLockStderr(userdata: ?*anyopaque, terminal_mode: ?Io.Terminal.Mode) Io.Cancelable!?Io.LockedStderr {
    return try lockStderr(userdata, terminal_mode);
}

fn unlockStderr(_: ?*anyopaque) void {
    stderr_writer.interface.flush() catch {};
    stderr_writer.interface.end = 0;
    stderr_writer.interface.buffer = &.{};
}

fn processSetCurrentDir(_: ?*anyopaque, _: Dir) process.SetCurrentDirError!void {
    @panic("processSetCurrentDir unimplemented");
}

fn processReplace(_: ?*anyopaque, _: process.ReplaceOptions) process.ReplaceError {
    @panic("processReplace unimplemented");
}

fn processReplacePath(_: ?*anyopaque, _: Dir, _: process.ReplaceOptions) process.ReplaceError {
    @panic("processReplacePath unimplemented");
}

fn processSpawn(_: ?*anyopaque, _: process.SpawnOptions) process.SpawnError!process.Child {
    @panic("processSpawn unimplemented");
}

fn processSpawnPath(_: ?*anyopaque, _: Dir, _: process.SpawnOptions) process.SpawnError!process.Child {
    @panic("processSpawnPath unimplemented");
}

fn childWait(_: ?*anyopaque, _: *process.Child) process.Child.WaitError!process.Child.Term {
    @panic("childWait unimplemented");
}

fn childKill(_: ?*anyopaque, _: *process.Child) void {
    @panic("childKill unimplemented");
}

fn progressParentFile(_: ?*anyopaque) std.Progress.ParentFileError!File {
    @panic("progressParentFile unimplemented");
}

fn now(_: ?*anyopaque, _: Io.Clock) Io.Clock.Error!Io.Timestamp {
    @panic("now unimplemented");
}

fn sleep(_: ?*anyopaque, _: Io.Timeout) Io.SleepError!void {
    @panic("sleep unimplemented");
}

fn random(_: ?*anyopaque, _: []u8) void {
    @panic("random unimplemented");
}

fn randomSecure(_: ?*anyopaque, _: []u8) Io.RandomSecureError!void {
    @panic("randomSecure unimplemented");
}

fn netListenIp(
    _: ?*anyopaque,
    address: IpAddress,
    options: IpAddress.ListenOptions,
) IpAddress.ListenError!net.Server {
    if (!has_networking)
        return error.NetworkDown;

    const family = posixAddressFamily(&address);
    const mode = posixSocketMode(options.mode);
    const protocol = posixProtocol(options.protocol);

    const flags: u32 = mode;
    const socket_fd = try system.socket(family, flags, protocol);
    errdefer system.close(socket_fd);

    if (options.reuse_address) {
        try system.setsockopt(socket_fd, SOL.SOCKET, SO.REUSEADDR, 1);
        if (@hasDecl(SO, "REUSEPORT"))
            try system.setsockopt(socket_fd, SOL.SOCKET, SO.REUSEPORT, 1);
    }

    var storage: PosixAddress = undefined;
    const addr_len = addressToPosix(&address, &storage);
    try system.bind(socket_fd, &storage.any, addr_len);

    try system.listen(socket_fd, 128);

    return .{
        .socket = .{
            .handle = socket_fd,
            .address = addressFromPosix(&storage),
        },
    };
}

fn netListenUnix(
    _: ?*anyopaque,
    _: *const net.UnixAddress,
    _: net.UnixAddress.ListenOptions,
) net.UnixAddress.ListenError!net.Socket.Handle {
    return error.NetworkDown;
}

fn netAccept(_: ?*anyopaque, listen_fd: net.Socket.Handle) net.Server.AcceptError!net.Stream {
    if (!has_networking)
        return error.NetworkDown;

    var storage: PosixAddress = undefined;
    var addr_len: posix.socklen_t = @sizeOf(PosixAddress);

    const req_fd = try system.accept(listen_fd, &storage.any, &addr_len);

    return .{
        .socket = .{
            .handle = req_fd,
            .address = addressFromPosix(&storage),
        },
    };
}

fn netBindIp(
    _: ?*anyopaque,
    address: *const IpAddress,
    options: IpAddress.BindOptions,
) IpAddress.BindError!net.Socket {
    if (!has_networking)
        return error.NetworkDown;

    const family = posixAddressFamily(address);
    const mode = posixSocketMode(options.mode);
    const protocol = posixProtocol(options.protocol);

    const flags: u32 = mode;
    const socket_fd = try system.socket(family, flags, protocol);
    errdefer system.close(socket_fd);

    var storage: PosixAddress = undefined;
    const addr_len = addressToPosix(address, &storage);
    try system.bind(socket_fd, &storage.any, addr_len);

    return .{
        .handle = socket_fd,
        .address = addressFromPosix(&storage),
    };
}

fn netConnectIp(
    _: ?*anyopaque,
    address: *const IpAddress,
    options: IpAddress.ConnectOptions,
) IpAddress.ConnectError!net.Stream {
    if (!has_networking)
        return error.NetworkDown;

    const family = posixAddressFamily(address);
    const mode = posixSocketMode(options.mode);
    const protocol = posixProtocol(options.protocol);

    const flags: u32 = mode;
    const socket_fd = try system.socket(family, flags, protocol);
    errdefer system.close(socket_fd);

    var storage: PosixAddress = undefined;
    const addr_len = addressToPosix(address, &storage);
    try system.connect(socket_fd, &storage.any, addr_len);

    return .{
        .socket = .{
            .handle = socket_fd,
            .address = addressFromPosix(&storage),
        },
    };
}

fn netConnectUnix(
    _: ?*anyopaque,
    _: *const net.UnixAddress,
) net.UnixAddress.ConnectError!net.Socket.Handle {
    return error.NetworkDown;
}

fn netClose(_: ?*anyopaque, handles: []const net.Socket.Handle) void {
    if (!has_networking)
        return;

    for (handles) |handle| system.close(handle);
}

fn netShutdown(_: ?*anyopaque, _: net.Socket.Handle, _: net.ShutdownHow) net.ShutdownError!void {
    @panic("netShutdown unimplemented");
}

fn netRead(_: ?*anyopaque, handle: net.Socket.Handle, data: [][]u8) net.Stream.Reader.Error!usize {
    if (!has_networking)
        return error.NetworkDown;

    for (data) |buf| {
        if (buf.len == 0) continue;
        return try system.read(handle, buf);
    }

    return 0;
}

fn netWrite(
    _: ?*anyopaque,
    handle: net.Socket.Handle,
    header: []const u8,
    data: []const []const u8,
    splat: usize,
) net.Stream.Writer.Error!usize {
    if (!has_networking)
        return error.NetworkDown;

    if (header.len != 0) {
        return try system.write(handle, header);
    }

    for (data[0 .. data.len - 1]) |buf| {
        if (buf.len == 0) continue;
        return try system.write(handle, buf);
    }

    const pattern = data[data.len - 1];
    if (pattern.len == 0 or splat == 0) return 0;
    return try system.write(handle, pattern);
}

fn netWriteFile(
    _: ?*anyopaque,
    _: net.Socket.Handle,
    _: []const u8,
    _: *File.Reader,
    _: Io.Limit,
) net.Stream.Writer.WriteFileError!usize {
    @panic("netWriteFile unimplemented");
}

fn netSend(
    _: ?*anyopaque,
    _: net.Socket.Handle,
    _: []net.OutgoingMessage,
    _: net.SendFlags,
) struct { ?net.Socket.SendError, usize } {
    @panic("netSend unimplemented");
}

fn netReceive(
    _: ?*anyopaque,
    _: net.Socket.Handle,
    _: []net.IncomingMessage,
    _: []u8,
    _: net.ReceiveFlags,
    _: Io.Timeout,
) struct { ?net.Socket.ReceiveTimeoutError, usize } {
    @panic("netReceive unimplemented");
}

fn netInterfaceNameResolve(
    _: ?*anyopaque,
    _: *const net.Interface.Name,
) net.Interface.Name.ResolveError!net.Interface {
    @panic("netInterfaceNameResolve unimplemented");
}

fn netInterfaceName(_: ?*anyopaque, _: net.Interface) net.Interface.NameError!net.Interface.Name {
    @panic("netInterfaceName unimplemented");
}

fn netLookup(
    _: ?*anyopaque,
    _: HostName,
    _: *Io.Queue(HostName.LookupResult),
    _: HostName.LookupOptions,
) net.HostName.LookupError!void {
    @panic("netLookup unimplemented");
}

const PosixAddress = extern union {
    any: sockaddr,
    in: sockaddr.in,
    in6: sockaddr.in6,
};

fn posixAddressFamily(a: *const IpAddress) sa_family_t {
    return switch (a.*) {
        .ip4 => AF.INET,
        .ip6 => AF.INET6,
    };
}

fn posixSocketMode(mode: net.Socket.Mode) u32 {
    return switch (mode) {
        .stream => SOCK.STREAM,
        .dgram => SOCK.DGRAM,
        .seqpacket => unreachable,
        .raw => SOCK.RAW,
        .rdm => unreachable,
    };
}

fn posixProtocol(protocol: ?net.Protocol) u32 {
    return @intFromEnum(protocol orelse return 0);
}

fn addressFromPosix(posix_address: *const PosixAddress) IpAddress {
    return switch (posix_address.any.family) {
        AF.INET => .{ .ip4 = address4FromPosix(&posix_address.in) },
        AF.INET6 => .{ .ip6 = address6FromPosix(&posix_address.in6) },
        else => .{ .ip4 = .loopback(0) },
    };
}

fn address4FromPosix(in: *const sockaddr.in) net.Ip4Address {
    return .{
        .port = std.mem.bigToNative(u16, in.port),
        .bytes = @bitCast(in.addr),
    };
}

fn address6FromPosix(in6: *const sockaddr.in6) net.Ip6Address {
    return .{
        .port = std.mem.bigToNative(u16, in6.port),
        .bytes = in6.addr,
        .flow = in6.flowinfo,
        .interface = .{ .index = in6.scope_id },
    };
}

fn addressToPosix(a: *const IpAddress, storage: *PosixAddress) socklen_t {
    return switch (a.*) {
        .ip4 => |ip4| {
            storage.in = address4ToPosix(ip4);
            return @sizeOf(sockaddr.in);
        },
        .ip6 => |*ip6| {
            storage.in6 = address6ToPosix(ip6);
            return @sizeOf(sockaddr.in6);
        },
    };
}

fn address4ToPosix(a: net.Ip4Address) sockaddr.in {
    return .{
        .port = std.mem.nativeToBig(u16, a.port),
        .addr = @bitCast(a.bytes),
    };
}

fn address6ToPosix(a: *const net.Ip6Address) sockaddr.in6 {
    return .{
        .port = std.mem.nativeToBig(u16, a.port),
        .flowinfo = a.flow,
        .addr = a.bytes,
        .scope_id = a.interface.index,
    };
}

const system = struct {
    fn toPosixPath(file_path: []const u8) error{NameTooLong}![PATH_MAX - 1:0]u8 {
        if (std.debug.runtime_safety) assert(mem.findScalar(u8, file_path, 0) == null);
        var path_with_null: [PATH_MAX - 1:0]u8 = undefined;
        // >= rather than > to make room for the null byte
        if (file_path.len >= PATH_MAX) return error.NameTooLong;
        @memcpy(path_with_null[0..file_path.len], file_path);
        path_with_null[file_path.len] = 0;
        return path_with_null;
    }

    fn errno(rc: anytype) E {
        return if (rc == -1) @enumFromInt(_errno().*) else .SUCCESS;
    }

    pub fn open(file_path: []const u8, flags: O, perm: mode_t) File.OpenError!fd_t {
        const file_path_c = try toPosixPath(file_path);

        while (true) {
            const rc = private.open(&file_path_c, flags, perm);
            switch (errno(rc)) {
                .SUCCESS => return @intCast(rc),
                .INTR => continue,

                .FAULT => unreachable,
                .INVAL => return error.BadPathName,
                .ACCES => return error.AccessDenied,
                .FBIG => return error.FileTooBig,
                .OVERFLOW => return error.FileTooBig,
                .ISDIR => return error.IsDir,
                .LOOP => return error.SymLinkLoop,
                .MFILE => return error.ProcessFdQuotaExceeded,
                .NAMETOOLONG => return error.NameTooLong,
                .NFILE => return error.SystemFdQuotaExceeded,
                .NODEV => return error.NoDevice,
                .NOENT => return error.FileNotFound,
                .NOMEM => return error.SystemResources,
                .NOSPC => return error.NoSpaceLeft,
                .NOTDIR => return error.NotDir,
                .PERM => return error.PermissionDenied,
                .EXIST => return error.PathAlreadyExists,
                .BUSY => return error.DeviceBusy,
                else => return error.Unexpected,
            }
        }
    }

    pub fn close(fd: fd_t) void {
        const rc = private.close(fd);
        switch (errno(rc)) {
            .BADF => unreachable,
            .INTR => return,
            else => return,
        }
    }

    pub fn read(fd: fd_t, buf: []u8) !usize {
        const max_count = switch (native_os) {
            .linux => 0x7ffff000,
            .macos, .ios, .watchos, .tvos, .visionos => maxInt(i32),
            else => maxInt(isize),
        };
        while (true) {
            const rc = private.read(fd, buf.ptr, @min(buf.len, max_count));
            switch (errno(rc)) {
                .SUCCESS => return @intCast(rc),
                .INTR => continue,
                .INVAL => unreachable,
                .FAULT => unreachable,
                //.AGAIN => return error.WouldBlock,
                .CANCELED => return error.Canceled,
                //.BADF => return error.NotOpenForReading, // Can be a race condition.
                //.IO => return error.InputOutput,
                //.ISDIR => return error.IsDir,
                .NOBUFS => return error.SystemResources,
                .NOMEM => return error.SystemResources,
                .CONNRESET => return error.ConnectionResetByPeer,
                else => return error.Unexpected,
            }
        }
    }

    pub fn write(fd: fd_t, bytes: []const u8) !usize {
        const max_count = switch (native_os) {
            .linux => 0x7ffff000,
            .macos, .ios, .watchos, .tvos, .visionos => maxInt(i32),
            else => maxInt(isize),
        };
        while (true) {
            const rc = private.write(fd, bytes.ptr, @min(bytes.len, max_count));
            switch (errno(rc)) {
                .SUCCESS => return @intCast(rc),
                .INTR => continue,
                .INVAL => return error.Unexpected,
                .FAULT => return error.Unexpected,
                //.AGAIN => return error.WouldBlock,
                //.BADF => return error.NotOpenForWriting, // Can be a race condition.
                .DESTADDRREQ => return error.Unexpected, // `connect` was never called.
                //.DQUOT => return error.DiskQuota,
                //.FBIG => return error.FileTooBig,
                //.IO => return error.InputOutput,
                //.NOSPC => return error.NoSpaceLeft,
                //.PERM => return error.PermissionDenied,
                //.PIPE => return error.BrokenPipe,
                .CONNRESET => return error.Unexpected, // Not a socket handle.
                //.BUSY => return error.DeviceBusy,
                else => return error.Unexpected,
            }
        }
    }

    pub fn unlink(file_path: []const u8) Dir.DeleteFileError!void {
        const file_path_c = try toPosixPath(file_path);

        const rc = private.unlink(&file_path_c);
        switch (errno(rc)) {
            .SUCCESS => return,
            .ACCES => return error.AccessDenied,
            .PERM => return error.PermissionDenied,
            .BUSY => return error.FileBusy,
            .FAULT => unreachable,
            .INVAL => unreachable,
            .IO => return error.FileSystem,
            .ISDIR => return error.IsDir,
            .LOOP => return error.SymLinkLoop,
            .NAMETOOLONG => return error.NameTooLong,
            .NOENT => return error.FileNotFound,
            .NOTDIR => return error.NotDir,
            .NOMEM => return error.SystemResources,
            .ROFS => return error.ReadOnlyFileSystem,
            else => return error.Unexpected,
        }
    }

    pub fn lseek(fd: fd_t, offset: off_t, whence: c_int) File.SeekError!void {
        const rc = private.lseek(fd, @bitCast(offset), whence);
        switch (errno(rc)) {
            .SUCCESS => return,
            .BADF => unreachable, // always a race condition
            .INVAL => return error.Unseekable,
            .OVERFLOW => return error.Unseekable,
            .SPIPE => return error.Unseekable,
            .NXIO => return error.Unseekable,
            else => return error.Unexpected,
        }
    }

    pub fn socket(domain: u32, socket_type: u32, protocol: u32) !socket_t {
        const rc = private.socket(domain, socket_type, protocol);
        switch (errno(rc)) {
            .SUCCESS => return @intCast(rc),
            //.ACCES => return error.AccessDenied,
            .AFNOSUPPORT => return error.AddressFamilyUnsupported,
            .INVAL => return error.ProtocolUnsupportedByAddressFamily,
            .MFILE => return error.ProcessFdQuotaExceeded,
            .NFILE => return error.SystemFdQuotaExceeded,
            .NOBUFS => return error.SystemResources,
            .NOMEM => return error.SystemResources,
            .PROTONOSUPPORT => return error.ProtocolUnsupportedBySystem,
            .PROTOTYPE => return error.SocketModeUnsupported,
            else => return error.Unexpected,
        }
    }

    pub fn bind(sock: socket_t, addr: *const sockaddr, addr_len: posix.socklen_t) IpAddress.BindError!void {
        while (true) {
            const rc = private.bind(sock, addr, addr_len);
            switch (errno(rc)) {
                .SUCCESS => return,
                .INTR => continue,
                //.ACCES => return error.AccessDenied,
                .ADDRINUSE => return error.AddressInUse,
                .AFNOSUPPORT => return error.AddressFamilyUnsupported,
                .ADDRNOTAVAIL => return error.AddressUnavailable,
                .NOMEM => return error.SystemResources,

                //.LOOP => return error.SymLinkLoop,
                //.NOENT => return error.FileNotFound,
                //.NOTDIR => return error.NotDir,
                //.ROFS => return error.ReadOnlyFileSystem,
                //.PERM => return error.PermissionDenied,

                else => return error.Unexpected,
            }
        }
    }

    pub fn listen(sock: socket_t, backlog: u31) !void {
        while (true) {
            const rc = private.listen(sock, backlog);
            switch (errno(rc)) {
                .SUCCESS => return,
                .INTR => continue,
                .ADDRINUSE => return error.AddressInUse,
                .BADF => unreachable,
                //.NOTSOCK => return error.FileDescriptorNotASocket,
                //.OPNOTSUPP => return error.OperationNotSupported,
                else => return error.Unexpected,
            }
        }
    }

    pub fn accept(sock: socket_t, addr: ?*sockaddr, addr_size: ?*socklen_t) !socket_t {
        while (true) {
            const rc = private.accept(sock, addr, addr_size);
            switch (errno(rc)) {
                .SUCCESS => return @intCast(rc),
                .INTR => continue,
                .CONNABORTED => return error.ConnectionAborted,
                .INVAL => return error.SocketNotListening,
                .MFILE => return error.ProcessFdQuotaExceeded,
                .NFILE => return error.SystemFdQuotaExceeded,
                .NOBUFS => return error.SystemResources,
                .NOMEM => return error.SystemResources,
                .PROTO => return error.ProtocolFailure,
                .PERM => return error.BlockedByFirewall,
                else => return error.Unexpected,
            }
        }
    }

    pub fn connect(sock: socket_t, addr: *sockaddr, addr_size: socklen_t) !void {
        while (true) {
            const rc = private.connect(sock, addr, addr_size);
            switch (errno(rc)) {
                .SUCCESS => return,
                .INTR => continue,
                .ADDRNOTAVAIL => return error.AddressUnavailable,
                .AFNOSUPPORT => return error.AddressFamilyUnsupported,
                .AGAIN, .INPROGRESS => return error.WouldBlock,
                .ALREADY => return error.ConnectionPending,
                .CONNREFUSED => return error.ConnectionRefused,
                .CONNRESET => return error.ConnectionResetByPeer,
                .HOSTUNREACH => return error.HostUnreachable,
                .NETUNREACH => return error.NetworkUnreachable,
                .TIMEDOUT => return error.Timeout,
                .ACCES => return error.AccessDenied,
                .NETDOWN => return error.NetworkDown,
                else => return error.Unexpected,
            }
        }
    }

    fn setsockopt(sock: socket_t, level: i32, opt_name: u32, option: u32) !void {
        const o: []const u8 = @ptrCast(&option);
        while (true) {
            const rc = private.setsockopt(sock, level, opt_name, o.ptr, @intCast(o.len));
            switch (errno(rc)) {
                .SUCCESS => return,
                .INTR => continue,
                else => return error.Unexpected,
            }
        }
    }

    const private = struct {
        extern "c" fn open(path: [*:0]const u8, oflag: O, ...) c_int;
        extern "c" fn close(fd: fd_t) c_int;
        extern "c" fn read(fd: fd_t, buf: [*]u8, nbyte: usize) isize;
        extern "c" fn write(fd: fd_t, buf: [*]const u8, nbyte: usize) isize;
        extern "c" fn unlink(path: [*:0]const u8) c_int;
        extern "c" fn lseek(fd: fd_t, offset: off_t, whence: c_int) off_t;
        extern "c" fn socket(domain: c_uint, sock_type: c_uint, protocol: c_uint) c_int;
        extern "c" fn bind(socket: fd_t, address: ?*const sockaddr, address_len: socklen_t) c_int;
        extern "c" fn listen(sockfd: fd_t, backlog: c_uint) c_int;
        extern "c" fn accept(sockfd: fd_t, noalias addr: ?*sockaddr, noalias addrlen: ?*socklen_t) c_int;
        extern "c" fn connect(sockfd: fd_t, sock_addr: *const sockaddr, addrlen: socklen_t) c_int;
        extern "c" fn setsockopt(sockfd: fd_t, level: i32, optname: u32, optval: ?*const anyopaque, optlen: socklen_t) c_int;
    };
};
