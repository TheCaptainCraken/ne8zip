const std = @import("std");
const raylib = @import("raylib");

pub const Ne8zipVM = struct {
    const RegisterNumber = u4;
    const Value = u24;
    const NUMBER_OF_REGISTERS = 16;
    const MAX_RAM_SIZE = std.math.pow(comptime_int, 2, 24); // ~16 MB (Max addressable with 24 bits)
    const TIMER_CLOCK_SPEED = 60;
    const MAX_STACK_SIZE = 1024;

    const Instruction = packed struct(u24) {
        const InstructionPayload = packed union {
            const RType = packed struct(u20) {
                rd: Ne8zipVM.RegisterNumber,
                rs1: Ne8zipVM.RegisterNumber,
                rs2: Ne8zipVM.RegisterNumber,
                func: u8,
            };
            const IType = packed struct(u20) {
                rd: Ne8zipVM.RegisterNumber,
                rs1: Ne8zipVM.RegisterNumber,
                imm: u12,
            };
            const JType = packed struct(u20) { addr: u20 };
            const SType = packed struct(u20) { syscall: u20 };

            r_type: Ne8zipVM.Instruction.InstructionPayload.RType,
            i_type: Ne8zipVM.Instruction.InstructionPayload.IType,
            j_type: Ne8zipVM.Instruction.InstructionPayload.JType,
            s_type: Ne8zipVM.Instruction.InstructionPayload.SType,
        };

        opcode: u4,
        payload: Ne8zipVM.InstructionPayload,
    };

    const Display = struct {
        const DISPLAY_WIDTH = 800;
        const DISPLAY_HEIGHT = 450;
        const Pixel = packed struct(u32) { red: u8, green: u8, blue: u8, alpha: u8 = 255 };

        pixels: [DISPLAY_HEIGHT * DISPLAY_WIDTH]Pixel,
    };

    registers: [NUMBER_OF_REGISTERS]Value = [_]Value{0} ** NUMBER_OF_REGISTERS,
    ip: *Value,

    ram: std.ArrayList(u8),

    stack: std.ArrayList(Ne8zipVM.Value),

    program: std.ArrayList(Ne8zipVM.Value),

    pub fn init(allocator: std.mem.Allocator) !Ne8zipVM {
        raylib.initWindow(Ne8zipVM.Display.DISPLAY_WIDTH, Ne8zipVM.Display.DISPLAY_HEIGHT, "Ne8Zip");
        raylib.setTargetFPS(TIMER_CLOCK_SPEED);

        var vm = Ne8zipVM{
            .registers = [_]Value{0} ** NUMBER_OF_REGISTERS,
            .ip = undefined, // You'll need to set this to point to a valid register
            .ram = try std.ArrayList(u8).initCapacity(allocator, 10),
            .stack = try std.ArrayList(Ne8zipVM.Value).initCapacity(allocator, 10),
            .program = try std.ArrayList(Ne8zipVM.Value).initCapacity(allocator, 10),
        };

        // Initialize ip to point to register 0 (or wherever you want)
        vm.ip = &vm.registers[0];

        return vm;
    }

    pub fn run(self: *@This()) !u8 {
        self.ip = &self.registers[0];

        while (!raylib.windowShouldClose()) {
            raylib.beginDrawing();
            defer raylib.endDrawing();

            raylib.clearBackground(.ray_white);
            raylib.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
        }

        return 0;
    }

    pub fn deinit(self: *Ne8zipVM, allocator: std.mem.Allocator) void {
        self.ram.deinit(allocator);
        self.stack.deinit(allocator);
        self.program.deinit(allocator);
        raylib.closeWindow();
    }
};
