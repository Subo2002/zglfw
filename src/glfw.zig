pub const std = @import("std");
const builtin = @import("builtin");

pub const ErrorCode = enum(c_int) {
    NotInitialized = 0x00010001,
    NoCurrentContext = 0x00010002,
    InvalidEnum = 0x00010003,
    InvalidValue = 0x00010004,
    OutOfMemory = 0x00010005,
    APIUnavailable = 0x00010006,
    VersionUnavailable = 0x00010007,
    PlatformError = 0x00010008,
    FormatUnavailable = 0x00010009,
    NoWindowContext = 0x0001000A,
    NoError = 0,
};

pub const GLFWError = error{
    NotInitialized,
    NoCurrentContext,
    InvalidEnum,
    InvalidValue,
    OutOfMemory,
    APIUnavailable,
    VersionUnavailable,
    PlatformError,
    FormatUnavailable,
    NoWindowContext,
    NoError,
};

pub const GLFW = struct {
    extern fn glfwInit() c_int;
    pub fn init() !GLFW {
        if (glfwInit() != 1) {
            return GLFWError.PlatformError;
        }
        return .{};
    }

    extern fn glfwTerminate() void;
    pub fn terminate(glfw: *GLFW) void {
        _ = glfw;
        glfwTerminate();
        errorCheck2();
    }

    extern fn glfwMakeContextCurrent(window: ?*Window.Internal) void;
    pub fn makeContextCurrent(window: ?*Window) void {
        glfwMakeContextCurrent(Window.unwrapNull(window));
        errorCheck2();
    }

    pub const GLproc = *const anyopaque; //fn () callconv(.c) void;
    extern fn glfwGetProcAddress(procname: [*:0]const u8) callconv(.c) ?GLproc;
    pub fn getProcAddress(procname: [*:0]const u8) callconv(.c) ?GLproc {
        const res = glfwGetProcAddress(procname);
        errorCheck2();
        return res;
    }

    extern fn glfwPollEvents() void;
    pub fn pollEvents(glfw: *GLFW) void {
        _ = glfw;
        glfwPollEvents();
        errorCheck2();
    }
};

extern fn glfwGetError(description: ?[*:0]const u8) c_int;

fn errorCheck() !void {
    const code: ErrorCode = @enumFromInt(glfwGetError(null));
    const err = switch (code) {
        .NotInitialized => GLFWError.NotInitialized,
        .NoCurrentContext => GLFWError.NoCurrentContext,
        .InvalidEnum => GLFWError.InvalidEnum,
        .InvalidValue => GLFWError.InvalidValue,
        .OutOfMemory => GLFWError.OutOfMemory,
        .APIUnavailable => GLFWError.APIUnavailable,
        .VersionUnavailable => GLFWError.VersionUnavailable,
        .PlatformError => GLFWError.PlatformError,
        .FormatUnavailable => GLFWError.FormatUnavailable,
        .NoWindowContext => GLFWError.NoWindowContext,
        .NoError => GLFWError.NoError,
    };
    return err;
}

fn errorCheck2() void {
    errorCheck() catch |err| {
        if (err != GLFWError.NoError) {
            std.log.scoped(.zGLFW).err("{s}", .{@errorName(err)});
        }
    };
}

pub const Monitor = struct {
    pub const Internal = c_long;
    id: Internal,

    pub fn wrap(monitor: *Internal) *Monitor {
        return @ptrCast(monitor);
    }

    pub fn wrapNull(monitor: ?*Internal) ?*Monitor {
        return if (monitor) |m| .wrap(m) else null;
    }

    pub fn unwrap(monitor: *Monitor) *Internal {
        return @ptrCast(monitor);
    }

    pub fn unwrapNull(monitor: ?*Monitor) ?*Internal {
        return if (monitor) |m| unwrap(m) else null;
    }
};

pub const Window = struct {
    pub const Internal = c_long;
    id: Internal,

    pub fn wrap(window: *Internal) *Window {
        return @ptrCast(window);
    }

    pub fn wrapNull(window: ?*Internal) ?*Window {
        return if (window) |w| .wrap(w) else null;
    }

    pub fn unwrap(window: *Window) *Internal {
        return @ptrCast(window);
    }

    pub fn unwrapNull(window: ?*Window) ?*Internal {
        return if (window) |w| unwrap(w) else null;
    }

    extern fn glfwCreateWindow(width: c_int, height: c_int, title: [*:0]const u8, monitor: ?*Monitor.Internal, share: ?*Internal) ?*Internal;
    pub fn create(width: u32, height: u32, title: [*:0]const u8, monitor: ?*Monitor, share: ?*Window) !*Window {
        const res = glfwCreateWindow(@intCast(width), @intCast(height), title, Monitor.unwrapNull(monitor), unwrapNull(share));
        errorCheck2();
        return if (res) |r| wrap(r) else GLFWError.PlatformError;
    }

    extern fn glfwDestroyWindow(window: ?*Internal) void;
    pub fn destroy(window: ?*Window) void {
        glfwDestroyWindow(unwrapNull(window));
        errorCheck2();
    }

    extern fn glfwWindowShouldClose(window: ?*Internal) c_int;
    pub fn shouldClose(window: ?*Window) bool {
        const res = glfwWindowShouldClose(unwrapNull(window));
        errorCheck2();
        return res != 0;
    }
};
