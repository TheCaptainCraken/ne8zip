const std = @import("std");
const ne8zip = @import("ne8zip");

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var vm = try ne8zip.Ne8zipVM.init(allocator);
    defer vm.deinit(allocator);

    const res = vm.run();

    return res;
}
