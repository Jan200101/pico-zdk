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

fn write(fd: fd_t, bytes: []const u8) File.Writer.Error!usize {
    const max_count = switch (native_os) {
        .linux => 0x7ffff000,
        .macos, .ios, .watchos, .tvos, .visionos => maxInt(i32),
        else => maxInt(isize),
    };
    while (true) {
        const rc = c.write(fd, bytes.ptr, @min(bytes.len, max_count));
        switch (c.errno(rc)) {
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
    @panic("unimplemented");
}

fn concurrent(
    _: ?*anyopaque,
    _: usize,
    _: Alignment,
    _: []const u8,
    _: Alignment,
    _: *const fn (_: *const anyopaque, _: *anyopaque) void,
) Io.ConcurrentError!*Io.AnyFuture {
    @panic("unimplemented");
}

fn await(
    _: ?*anyopaque,
    _: *Io.AnyFuture,
    _: []u8,
    _: Alignment,
) void {
    @panic("unimplemented");
}

fn cancel(
    _: ?*anyopaque,
    _: *Io.AnyFuture,
    _: []u8,
    _: Alignment,
) void {
    @panic("unimplemented");
}

fn select(_: ?*anyopaque, _: []const *Io.AnyFuture) Io.Cancelable!usize {
    @panic("unimplemented");
}

fn groupAsync(
    _: ?*anyopaque,
    _: *Io.Group,
    _: []const u8,
    _: Alignment,
    _: *const fn (_: *const anyopaque) Io.Cancelable!void,
) void {
    @panic("unimplemented");
}

fn groupConcurrent(
    _: ?*anyopaque,
    _: *Io.Group,
    _: []const u8,
    _: Alignment,
    _: *const fn (_: *const anyopaque) Io.Cancelable!void,
) Io.ConcurrentError!void {
    @panic("unimplemented");
}

fn groupAwait(_: ?*anyopaque, _: *Io.Group, _: *anyopaque) Io.Cancelable!void {
    @panic("unimplemented");
}

fn groupCancel(_: ?*anyopaque, _: *Io.Group, _: *anyopaque) void {
    @panic("unimplemented");
}

fn recancel(_: ?*anyopaque) void {
    @panic("unimplemented");
}

fn swapCancelProtection(_: ?*anyopaque, _: Io.CancelProtection) Io.CancelProtection {
    return .unblocked;
}

fn checkCancel(_: ?*anyopaque) Io.Cancelable!void {
    @panic("unimplemented");
}

fn futexWait(_: ?*anyopaque, _: *const u32, _: u32, _: Io.Timeout) Io.Cancelable!void {
    @panic("unimplemented");
}

fn futexWaitUncancelable(_: ?*anyopaque, _: *const u32, _: u32) void {
    @panic("unimplemented");
}

fn futexWake(_: ?*anyopaque, _: *const u32, _: u32) void {
    @panic("unimplemented");
}

fn dirCreateDir(_: ?*anyopaque, _: Dir, _: []const u8, _: Dir.Permissions) Dir.CreateDirError!void {
    @panic("unimplemented");
}

fn dirCreateDirPath(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.Permissions,
) Dir.CreateDirPathError!Dir.CreatePathStatus {
    @panic("unimplemented");
}

fn dirCreateDirPathOpen(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.Permissions,
    _: Dir.OpenOptions,
) Dir.CreateDirPathOpenError!Dir {
    @panic("unimplemented");
}

fn dirStat(_: ?*anyopaque, _: Dir) Dir.StatError!Dir.Stat {
    @panic("unimplemented");
}

fn dirStatFile(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.StatFileOptions,
) Dir.StatFileError!File.Stat {
    @panic("unimplemented");
}

fn dirAccess(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.AccessOptions,
) Dir.AccessError!void {
    @panic("unimplemented");
}

fn dirCreateFile(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: File.CreateFlags,
) File.OpenError!File {
    @panic("unimplemented");
}

fn dirCreateFileAtomic(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.CreateFileAtomicOptions,
) Dir.CreateFileAtomicError!File.Atomic {
    @panic("unimplemented");
}

fn dirOpenFile(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: File.OpenFlags,
) File.OpenError!File {
    @panic("unimplemented");
}

fn dirOpenDir(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.OpenOptions,
) Dir.OpenError!Dir {
    @panic("unimplemented");
}

fn dirClose(_: ?*anyopaque, _: []const Dir) void {}

fn dirRead(_: ?*anyopaque, _: *Dir.Reader, _: []Dir.Entry) Dir.Reader.Error!usize {
    @panic("unimplemented");
}

fn dirRealPath(_: ?*anyopaque, _: Dir, _: []u8) Dir.RealPathError!usize {
    @panic("unimplemented");
}

fn dirRealPathFile(_: ?*anyopaque, _: Dir, _: []const u8, _: []u8) Dir.RealPathFileError!usize {
    @panic("unimplemented");
}

fn dirDeleteFile(_: ?*anyopaque, _: Dir, _: []const u8) Dir.DeleteFileError!void {
    @panic("unimplemented");
}

fn dirDeleteDir(_: ?*anyopaque, _: Dir, _: []const u8) Dir.DeleteDirError!void {
    @panic("unimplemented");
}

fn dirRename(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir,
    _: []const u8,
) Dir.RenameError!void {
    @panic("unimplemented");
}

fn dirRenamePreserve(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir,
    _: []const u8,
) Dir.RenamePreserveError!void {
    @panic("unimplemented");
}

fn dirSymLink(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: []const u8,
    _: Dir.SymLinkFlags,
) Dir.SymLinkError!void {
    @panic("unimplemented");
}

fn dirReadLink(_: ?*anyopaque, _: Dir, _: []const u8, _: []u8) Dir.ReadLinkError!usize {
    @panic("unimplemented");
}

fn dirSetOwner(_: ?*anyopaque, _: Dir, _: ?File.Uid, _: ?File.Gid) Dir.SetOwnerError!void {
    @panic("unimplemented");
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
    @panic("unimplemented");
}

fn dirSetTimestamps(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir.SetTimestampsOptions,
) Dir.SetTimestampsError!void {
    @panic("unimplemented");
}

fn dirHardLink(
    _: ?*anyopaque,
    _: Dir,
    _: []const u8,
    _: Dir,
    _: []const u8,
    _: Dir.HardLinkOptions,
) Dir.HardLinkError!void {
    @panic("unimplemented");
}

fn fileStat(_: ?*anyopaque, _: File) File.StatError!File.Stat {
    @panic("unimplemented");
}

fn fileLength(_: ?*anyopaque, _: File) File.LengthError!u64 {
    @panic("unimplemented");
}

fn fileClose(_: ?*anyopaque, _: []const File) void {}

fn fileWriteStreaming(
    _: ?*anyopaque,
    file: File,
    header: []const u8,
    data: []const []const u8,
    splat: usize,
) File.Writer.Error!usize {
    var written: usize = 0;

    if (header.len != 0)
        written += try write(file.handle, header);

    for (data[0 .. data.len - 1]) |bytes| {
        if (bytes.len != 0) {
            written += try write(file.handle, bytes);
        }
    }

    const pattern = data[data.len - 1];
    for (0..splat) |_| {
        written += try write(file.handle, pattern);
    }

    return written;
}

fn fileWritePositional(
    _: ?*anyopaque,
    _: File,
    _: []const u8,
    _: []const []const u8,
    _: usize,
    _: u64,
) File.WritePositionalError!usize {
    @panic("unimplemented");
}

fn fileWriteFileStreaming(
    _: ?*anyopaque,
    _: File,
    _: []const u8,
    _: *File.Reader,
    _: Io.Limit,
) File.Writer.WriteFileError!usize {
    @panic("unimplemented");
}

fn fileWriteFilePositional(
    _: ?*anyopaque,
    _: File,
    _: []const u8,
    _: *File.Reader,
    _: Io.Limit,
    _: u64,
) File.WriteFilePositionalError!usize {
    @panic("unimplemented");
}

fn fileReadStreaming(_: ?*anyopaque, _: File, _: []const []u8) File.Reader.Error!usize {
    @panic("unimplemented");
}

fn fileReadPositional(_: ?*anyopaque, _: File, _: []const []u8, _: u64) File.ReadPositionalError!usize {
    @panic("unimplemented");
}

fn fileSeekBy(_: ?*anyopaque, _: File, _: i64) File.SeekError!void {
    @panic("unimplemented");
}

fn fileSeekTo(_: ?*anyopaque, _: File, _: u64) File.SeekError!void {
    @panic("unimplemented");
}

fn fileSync(_: ?*anyopaque, _: File) File.SyncError!void {
    @panic("unimplemented");
}

fn fileIsTty(_: ?*anyopaque, _: File) Io.Cancelable!bool {
    @panic("unimplemented");
}

fn fileEnableAnsiEscapeCodes(_: ?*anyopaque, _: File) File.EnableAnsiEscapeCodesError!void {
    @panic("unimplemented");
}

fn fileSupportsAnsiEscapeCodes(_: ?*anyopaque, _: File) Io.Cancelable!bool {
    @panic("unimplemented");
}

fn fileSetLength(_: ?*anyopaque, _: File, _: u64) File.SetLengthError!void {
    @panic("unimplemented");
}

fn fileSetOwner(_: ?*anyopaque, _: File, _: ?File.Uid, _: ?File.Gid) File.SetOwnerError!void {
    @panic("unimplemented");
}

fn fileSetPermissions(_: ?*anyopaque, _: File, _: File.Permissions) File.SetPermissionsError!void {
    @panic("unimplemented");
}

fn fileSetTimestamps(
    _: ?*anyopaque,
    _: File,
    _: File.SetTimestampsOptions,
) File.SetTimestampsError!void {
    @panic("unimplemented");
}

fn fileLock(_: ?*anyopaque, _: File, _: File.Lock) File.LockError!void {
    @panic("unimplemented");
}

fn fileTryLock(_: ?*anyopaque, _: File, _: File.Lock) File.LockError!bool {
    @panic("unimplemented");
}

fn fileUnlock(_: ?*anyopaque, _: File) void {
    @panic("unimplemented");
}

fn fileDowngradeLock(_: ?*anyopaque, _: File) File.DowngradeLockError!void {
    @panic("unimplemented");
}

fn fileRealPath(_: ?*anyopaque, _: File, _: []u8) File.RealPathError!usize {
    @panic("unimplemented");
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
    @panic("unimplemented");
}

fn processExecutablePath(_: ?*anyopaque, _: []u8) process.ExecutablePathError!usize {
    @panic("unimplemented");
}

fn lockStderr(_: ?*anyopaque, _: ?Io.Terminal.Mode) Io.Cancelable!Io.LockedStderr {
    @panic("unimplemented");
}

fn tryLockStderr(_: ?*anyopaque, _: ?Io.Terminal.Mode) Io.Cancelable!?Io.LockedStderr {
    @panic("unimplemented");
}

fn unlockStderr(_: ?*anyopaque) void {
    @panic("unimplemented");
}

fn processSetCurrentDir(_: ?*anyopaque, _: Dir) process.SetCurrentDirError!void {
    @panic("unimplemented");
}

fn processReplace(_: ?*anyopaque, _: process.ReplaceOptions) process.ReplaceError {
    @panic("unimplemented");
}

fn processReplacePath(_: ?*anyopaque, _: Dir, _: process.ReplaceOptions) process.ReplaceError {
    @panic("unimplemented");
}

fn processSpawn(_: ?*anyopaque, _: process.SpawnOptions) process.SpawnError!process.Child {
    @panic("unimplemented");
}

fn processSpawnPath(_: ?*anyopaque, _: Dir, _: process.SpawnOptions) process.SpawnError!process.Child {
    @panic("unimplemented");
}

fn childWait(_: ?*anyopaque, _: *process.Child) process.Child.WaitError!process.Child.Term {
    @panic("unimplemented");
}

fn childKill(_: ?*anyopaque, _: *process.Child) void {
    @panic("unimplemented");
}

fn progressParentFile(_: ?*anyopaque) std.Progress.ParentFileError!File {
    @panic("unimplemented");
}

fn now(_: ?*anyopaque, _: Io.Clock) Io.Clock.Error!Io.Timestamp {
    @panic("unimplemented");
}

fn sleep(_: ?*anyopaque, _: Io.Timeout) Io.SleepError!void {
    @panic("unimplemented");
}

fn random(_: ?*anyopaque, _: []u8) void {
    @panic("unimplemented");
}

fn randomSecure(_: ?*anyopaque, _: []u8) Io.RandomSecureError!void {
    @panic("unimplemented");
}

fn netListenIp(
    _: ?*anyopaque,
    _: IpAddress,
    _: IpAddress.ListenOptions,
) IpAddress.ListenError!net.Server {
    @panic("unimplemented");
}

fn netListenUnix(
    _: ?*anyopaque,
    _: *const net.UnixAddress,
    _: net.UnixAddress.ListenOptions,
) net.UnixAddress.ListenError!net.Socket.Handle {
    @panic("unimplemented");
}

fn netAccept(_: ?*anyopaque, _: net.Socket.Handle) net.Server.AcceptError!net.Stream {
    @panic("unimplemented");
}

fn netBindIp(
    _: ?*anyopaque,
    _: *const IpAddress,
    _: IpAddress.BindOptions,
) IpAddress.BindError!net.Socket {
    @panic("unimplemented");
}

fn netConnectIp(
    _: ?*anyopaque,
    _: *const IpAddress,
    _: IpAddress.ConnectOptions,
) IpAddress.ConnectError!net.Stream {
    @panic("unimplemented");
}

fn netConnectUnix(
    _: ?*anyopaque,
    _: *const net.UnixAddress,
) net.UnixAddress.ConnectError!net.Socket.Handle {
    @panic("unimplemented");
}

fn netClose(_: ?*anyopaque, _: []const net.Socket.Handle) void {
    @panic("unimplemented");
}

fn netShutdown(_: ?*anyopaque, _: net.Socket.Handle, _: net.ShutdownHow) net.ShutdownError!void {
    @panic("unimplemented");
}

fn netRead(_: ?*anyopaque, _: net.Socket.Handle, _: [][]u8) net.Stream.Reader.Error!usize {
    @panic("unimplemented");
}

fn netWrite(
    _: ?*anyopaque,
    _: net.Socket.Handle,
    _: []const u8,
    _: []const []const u8,
    _: usize,
) net.Stream.Writer.Error!usize {
    @panic("unimplemented");
}

fn netWriteFile(
    _: ?*anyopaque,
    _: net.Socket.Handle,
    _: []const u8,
    _: *File.Reader,
    _: Io.Limit,
) net.Stream.Writer.WriteFileError!usize {
    @panic("unimplemented");
}

fn netSend(
    _: ?*anyopaque,
    _: net.Socket.Handle,
    _: []net.OutgoingMessage,
    _: net.SendFlags,
) struct { ?net.Socket.SendError, usize } {
    @panic("unimplemented");
}

fn netReceive(
    _: ?*anyopaque,
    _: net.Socket.Handle,
    _: []net.IncomingMessage,
    _: []u8,
    _: net.ReceiveFlags,
    _: Io.Timeout,
) struct { ?net.Socket.ReceiveTimeoutError, usize } {
    @panic("unimplemented");
}

fn netInterfaceNameResolve(
    _: ?*anyopaque,
    _: *const net.Interface.Name,
) net.Interface.Name.ResolveError!net.Interface {
    @panic("unimplemented");
}

fn netInterfaceName(_: ?*anyopaque, _: net.Interface) net.Interface.NameError!net.Interface.Name {
    @panic("unimplemented");
}

fn netLookup(
    _: ?*anyopaque,
    _: HostName,
    _: *Io.Queue(HostName.LookupResult),
    _: HostName.LookupOptions,
) net.HostName.LookupError!void {
    @panic("unimplemented");
}
