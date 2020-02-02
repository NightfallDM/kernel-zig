// https://wiki.osdev.org/IDT
// usingnamespace @import("kernel");
// usingnamespace @import("x86");
usingnamespace @import("index.zig");

// Types of gates.
pub const INTERRUPT_GATE = 0x8E;
pub const SYSCALL_GATE = 0xEE;

// Interrupt Descriptor Table.
var idt_table: [256]IDTEntry = undefined;

// IDT descriptor register pointing at the IDT.
const idtr = IDTRegister{
    .limit = @as(u16, @sizeOf(@TypeOf(idt_table))),
    .base = &idt_table,
};

// Structure representing an entry in the IDT.
const IDTEntry = packed struct {
    offset_low: u16,
    selector: u16,
    zero: u8,
    flags: u8,
    offset_high: u16,
};

// IDT descriptor register.
const IDTRegister = packed struct {
    limit: u16,
    base: *[256]IDTEntry,
};

// Setup an IDT entry.
//
// Arguments:
//     n: Index of the gate.
//     flags: Type and attributes.
//     offset: Address of the ISR.
//
pub fn setGate(n: u8, flags: u8, offset: extern fn () void) void {
    const intOffset = @ptrToInt(offset);

    idt_table[n].offset_low = @truncate(u16, intOffset);
    idt_table[n].offset_high = @truncate(u16, intOffset >> 16);
    idt_table[n].flags = flags;
    idt_table[n].zero = 0;
    idt_table[n].selector = gdt.KERNEL_CODE;
}

// Initialize the Interrupt Descriptor Table.
pub fn initialize() void {
    // configure PIC
    interrupt.remapPIC();
    interrupt.configPIT();
    // install ISRs
    isr.install_exceptions();
    isr.install_irqs();
    isr.install_syscalls();
    interrupt.registerIRQ(0, kernel.time.increment);
    interrupt.registerIRQ(1, kernel.ps2.keyboard_handler);
    interrupt.register(1, debug_trap);
    interrupt.register(13, general_protection_fault);
    interrupt.register(14, page_fault);

    // load IDT
    lidt(@ptrToInt(&idtr));
}

fn general_protection_fault() void {
    kernel.println("general protection fault", .{});
    hang();
}

fn debug_trap() void {
    kernel.println("debug fault/trap", .{});
    kernel.println("dr7: 0b{b}", .{dr7()});
}

fn page_fault() void {
    const vaddr = cr2();
    kernel.println("cr2: 0x{x}", .{vaddr});
    kernel.println("phy: 0x{x}", .{paging.translate(vaddr)});
    kernel.println("pde: 0x{x} ({})", .{ paging.pde(vaddr), vaddr >> 22 });
    kernel.println("pte: 0x{x} ({})", .{ paging.pte(vaddr), vaddr >> 12 });
    // paging.format();
    hang();
}
