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

const root = @import("root");

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
const PATH_MAX = c_decl.getValue("PATH_MAX");
const E = c_decl.getValue("E");
const O = c_decl.getValue("O");
const AT = c_decl.getValue("AT");

fn errno(rc: anytype) E {
    return if (rc == -1) @enumFromInt(_errno().*) else .SUCCESS;
}

fn toPosixPath(file_path: []const u8) error{NameTooLong}![PATH_MAX - 1:0]u8 {
    if (std.debug.runtime_safety) assert(mem.findScalar(u8, file_path, 0) == null);
    var path_with_null: [PATH_MAX - 1:0]u8 = undefined;
    // >= rather than > to make room for the null byte
    if (file_path.len >= PATH_MAX) return error.NameTooLong;
    @memcpy(path_with_null[0..file_path.len], file_path);
    path_with_null[file_path.len] = 0;
    return path_with_null;
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

fn write(fd: fd_t, bytes: []const u8) File.Writer.Error!usize {
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
            .AGAIN => return error.WouldBlock,
            .BADF => return error.NotOpenForWriting, // Can be a race condition.
            .DESTADDRREQ => return error.Unexpected, // `connect` was never called.
            .DQUOT => return error.DiskQuota,
            .FBIG => return error.FileTooBig,
            .IO => return error.InputOutput,
            .NOSPC => return error.NoSpaceLeft,
            .PERM => return error.PermissionDenied,
            .PIPE => return error.BrokenPipe,
            .CONNRESET => return error.Unexpected, // Not a socket handle.
            .BUSY => return error.DeviceBusy,
            else => return error.Unexpected,
        }
    }
}

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
    _: Dir,
    _: []const u8,
    _: File.CreateFlags,
) File.OpenError!File {
    @panic("dirCreateFile unimplemented");
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
    _ = flags;

    if (dir.handle == AT.FDCWD) {
        const fd = try open(sub_path, .{}, 0);
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

fn dirDeleteFile(_: ?*anyopaque, _: Dir, _: []const u8) Dir.DeleteFileError!void {
    @panic("dirDeleteFile unimplemented");
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
        close(file.handle);
}

fn fileWriteStreaming(
    _: ?*anyopaque,
    file: File,
    header: []const u8,
    data: []const []const u8,
    splat: usize,
) File.Writer.Error!usize {
    if (header.len != 0) {
        return try write(file.handle, header);
    }

    for (data[0 .. data.len - 1]) |buf| {
        if (buf.len == 0) continue;
        return try write(file.handle, buf);
    }

    const pattern = data[data.len - 1];
    if (pattern.len == 0 or splat == 0) return 0;
    return try write(file.handle, pattern);
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
    @panic("fileWriteFilePositional unimplemented");
}

fn fileReadStreaming(_: ?*anyopaque, _: File, _: []const []u8) File.Reader.Error!usize {
    @panic("fileReadStreaming unimplemented");
}

fn fileReadPositional(_: ?*anyopaque, _: File, _: []const []u8, _: u64) File.ReadPositionalError!usize {
    @panic("fileReadPositional unimplemented");
}

fn fileSeekBy(_: ?*anyopaque, _: File, _: i64) File.SeekError!void {
    @panic("fileSeekBy unimplemented");
}

fn fileSeekTo(_: ?*anyopaque, _: File, _: u64) File.SeekError!void {
    @panic("fileSeekTo unimplemented");
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
    _: IpAddress,
    _: IpAddress.ListenOptions,
) IpAddress.ListenError!net.Server {
    @panic("netListenIp unimplemented");
}

fn netListenUnix(
    _: ?*anyopaque,
    _: *const net.UnixAddress,
    _: net.UnixAddress.ListenOptions,
) net.UnixAddress.ListenError!net.Socket.Handle {
    @panic("netListenUnix unimplemented");
}

fn netAccept(_: ?*anyopaque, _: net.Socket.Handle) net.Server.AcceptError!net.Stream {
    @panic("netAccept unimplemented");
}

fn netBindIp(
    _: ?*anyopaque,
    _: *const IpAddress,
    _: IpAddress.BindOptions,
) IpAddress.BindError!net.Socket {
    @panic("netBindIp unimplemented");
}

fn netConnectIp(
    _: ?*anyopaque,
    _: *const IpAddress,
    _: IpAddress.ConnectOptions,
) IpAddress.ConnectError!net.Stream {
    @panic("netConnectIp unimplemented");
}

fn netConnectUnix(
    _: ?*anyopaque,
    _: *const net.UnixAddress,
) net.UnixAddress.ConnectError!net.Socket.Handle {
    @panic("netConnectUnix unimplemented");
}

fn netClose(_: ?*anyopaque, _: []const net.Socket.Handle) void {
    @panic("netClose unimplemented");
}

fn netShutdown(_: ?*anyopaque, _: net.Socket.Handle, _: net.ShutdownHow) net.ShutdownError!void {
    @panic("netShutdown unimplemented");
}

fn netRead(_: ?*anyopaque, _: net.Socket.Handle, _: [][]u8) net.Stream.Reader.Error!usize {
    @panic("netRead unimplemented");
}

fn netWrite(
    _: ?*anyopaque,
    _: net.Socket.Handle,
    _: []const u8,
    _: []const []const u8,
    _: usize,
) net.Stream.Writer.Error!usize {
    @panic("netWrite unimplemented");
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

const private = struct {
    extern "c" fn open(path: [*:0]const u8, oflag: O, ...) c_int;
    extern "c" fn close(fd: fd_t) c_int;
    extern "c" fn write(fd: fd_t, buf: [*]const u8, nbyte: usize) isize;
};
