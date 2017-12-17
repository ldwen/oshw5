
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 f6 31 00 00       	call   f0103253 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 c9 04 00 00       	call   f010052b <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 37 10 f0       	push   $0xf0103700
f010006f:	e8 1b 27 00 00       	call   f010278f <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 ab 0f 00 00       	call   f0101024 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 70 07 00 00       	call   f01007f6 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 1b 37 10 f0       	push   $0xf010371b
f01000b5:	e8 d5 26 00 00       	call   f010278f <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 a5 26 00 00       	call   f0102769 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 14 46 10 f0 	movl   $0xf0104614,(%esp)
f01000cb:	e8 bf 26 00 00       	call   f010278f <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 19 07 00 00       	call   f01007f6 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 33 37 10 f0       	push   $0xf0103733
f01000f7:	e8 93 26 00 00       	call   f010278f <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 61 26 00 00       	call   f0102769 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 14 46 10 f0 	movl   $0xf0104614,(%esp)
f010010f:	e8 7b 26 00 00       	call   f010278f <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100159:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 a0 38 10 f0 	movzbl -0xfefc760(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 a0 38 10 f0 	movzbl -0xfefc760(%edx),%eax
f0100211:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f0100217:	0f b6 8a a0 37 10 f0 	movzbl -0xfefc860(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 80 37 10 f0 	mov    -0xfefc880(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 4d 37 10 f0       	push   $0xf010374d
f010026d:	e8 1d 25 00 00       	call   f010278f <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)
cga_putc(int c)
{
	
	// if no attribute given, then use black on white
	
	if (!(c & ~0xFF)) {
f010031a:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100320:	75 3d                	jne    f010035f <cons_putc+0xc8>
    char ch = c & 0xFF;
    if (ch > 47 && ch < 58) {
f0100322:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100326:	83 e8 30             	sub    $0x30,%eax
f0100329:	3c 09                	cmp    $0x9,%al
f010032b:	77 08                	ja     f0100335 <cons_putc+0x9e>
        c |= 0x0700;
f010032d:	81 cf 00 07 00 00    	or     $0x700,%edi
f0100333:	eb 2a                	jmp    f010035f <cons_putc+0xc8>
    } else if (ch > 64 && ch < 91) {
f0100335:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100339:	83 e8 41             	sub    $0x41,%eax
f010033c:	3c 19                	cmp    $0x19,%al
f010033e:	77 08                	ja     f0100348 <cons_putc+0xb1>
        c |= 0x0200;
f0100340:	81 cf 00 02 00 00    	or     $0x200,%edi
f0100346:	eb 17                	jmp    f010035f <cons_putc+0xc8>
    } else if (ch > 96 && ch < 123) {
f0100348:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010034c:	83 e8 61             	sub    $0x61,%eax
        c |= 0x0300;
f010034f:	89 fa                	mov    %edi,%edx
f0100351:	80 ce 03             	or     $0x3,%dh
f0100354:	81 cf 00 04 00 00    	or     $0x400,%edi
f010035a:	3c 19                	cmp    $0x19,%al
f010035c:	0f 46 fa             	cmovbe %edx,%edi
    } else {
        c |= 0x0400;
    }
}

	switch (c & 0xff) {
f010035f:	89 f8                	mov    %edi,%eax
f0100361:	0f b6 c0             	movzbl %al,%eax
f0100364:	83 f8 09             	cmp    $0x9,%eax
f0100367:	74 74                	je     f01003dd <cons_putc+0x146>
f0100369:	83 f8 09             	cmp    $0x9,%eax
f010036c:	7f 0a                	jg     f0100378 <cons_putc+0xe1>
f010036e:	83 f8 08             	cmp    $0x8,%eax
f0100371:	74 14                	je     f0100387 <cons_putc+0xf0>
f0100373:	e9 99 00 00 00       	jmp    f0100411 <cons_putc+0x17a>
f0100378:	83 f8 0a             	cmp    $0xa,%eax
f010037b:	74 3a                	je     f01003b7 <cons_putc+0x120>
f010037d:	83 f8 0d             	cmp    $0xd,%eax
f0100380:	74 3d                	je     f01003bf <cons_putc+0x128>
f0100382:	e9 8a 00 00 00       	jmp    f0100411 <cons_putc+0x17a>
	case '\b':
		if (crt_pos > 0) {
f0100387:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010038e:	66 85 c0             	test   %ax,%ax
f0100391:	0f 84 e6 00 00 00    	je     f010047d <cons_putc+0x1e6>
			crt_pos--;
f0100397:	83 e8 01             	sub    $0x1,%eax
f010039a:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003a0:	0f b7 c0             	movzwl %ax,%eax
f01003a3:	66 81 e7 00 ff       	and    $0xff00,%di
f01003a8:	83 cf 20             	or     $0x20,%edi
f01003ab:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003b1:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003b5:	eb 78                	jmp    f010042f <cons_putc+0x198>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003b7:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f01003be:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003bf:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003c6:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003cc:	c1 e8 16             	shr    $0x16,%eax
f01003cf:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003d2:	c1 e0 04             	shl    $0x4,%eax
f01003d5:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003db:	eb 52                	jmp    f010042f <cons_putc+0x198>
		break;
	case '\t':
		cons_putc(' ');
f01003dd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e2:	e8 b0 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003e7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ec:	e8 a6 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003f1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f6:	e8 9c fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003fb:	b8 20 00 00 00       	mov    $0x20,%eax
f0100400:	e8 92 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f0100405:	b8 20 00 00 00       	mov    $0x20,%eax
f010040a:	e8 88 fe ff ff       	call   f0100297 <cons_putc>
f010040f:	eb 1e                	jmp    f010042f <cons_putc+0x198>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100411:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100418:	8d 50 01             	lea    0x1(%eax),%edx
f010041b:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f0100422:	0f b7 c0             	movzwl %ax,%eax
f0100425:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f010042b:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010042f:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f0100436:	cf 07 
f0100438:	76 43                	jbe    f010047d <cons_putc+0x1e6>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010043a:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f010043f:	83 ec 04             	sub    $0x4,%esp
f0100442:	68 00 0f 00 00       	push   $0xf00
f0100447:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010044d:	52                   	push   %edx
f010044e:	50                   	push   %eax
f010044f:	e8 4c 2e 00 00       	call   f01032a0 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100454:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f010045a:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100460:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100466:	83 c4 10             	add    $0x10,%esp
f0100469:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010046e:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100471:	39 d0                	cmp    %edx,%eax
f0100473:	75 f4                	jne    f0100469 <cons_putc+0x1d2>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100475:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f010047c:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010047d:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100483:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100488:	89 ca                	mov    %ecx,%edx
f010048a:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010048b:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f0100492:	8d 71 01             	lea    0x1(%ecx),%esi
f0100495:	89 d8                	mov    %ebx,%eax
f0100497:	66 c1 e8 08          	shr    $0x8,%ax
f010049b:	89 f2                	mov    %esi,%edx
f010049d:	ee                   	out    %al,(%dx)
f010049e:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004a3:	89 ca                	mov    %ecx,%edx
f01004a5:	ee                   	out    %al,(%dx)
f01004a6:	89 d8                	mov    %ebx,%eax
f01004a8:	89 f2                	mov    %esi,%edx
f01004aa:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004ae:	5b                   	pop    %ebx
f01004af:	5e                   	pop    %esi
f01004b0:	5f                   	pop    %edi
f01004b1:	5d                   	pop    %ebp
f01004b2:	c3                   	ret    

f01004b3 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004b3:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f01004ba:	74 11                	je     f01004cd <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004bc:	55                   	push   %ebp
f01004bd:	89 e5                	mov    %esp,%ebp
f01004bf:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004c2:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f01004c7:	e8 6f fc ff ff       	call   f010013b <cons_intr>
}
f01004cc:	c9                   	leave  
f01004cd:	f3 c3                	repz ret 

f01004cf <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004cf:	55                   	push   %ebp
f01004d0:	89 e5                	mov    %esp,%ebp
f01004d2:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004d5:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004da:	e8 5c fc ff ff       	call   f010013b <cons_intr>
}
f01004df:	c9                   	leave  
f01004e0:	c3                   	ret    

f01004e1 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004e1:	55                   	push   %ebp
f01004e2:	89 e5                	mov    %esp,%ebp
f01004e4:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004e7:	e8 c7 ff ff ff       	call   f01004b3 <serial_intr>
	kbd_intr();
f01004ec:	e8 de ff ff ff       	call   f01004cf <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004f1:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004f6:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004fc:	74 26                	je     f0100524 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004fe:	8d 50 01             	lea    0x1(%eax),%edx
f0100501:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f0100507:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010050e:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100510:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100516:	75 11                	jne    f0100529 <cons_getc+0x48>
			cons.rpos = 0;
f0100518:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f010051f:	00 00 00 
f0100522:	eb 05                	jmp    f0100529 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100524:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100529:	c9                   	leave  
f010052a:	c3                   	ret    

f010052b <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010052b:	55                   	push   %ebp
f010052c:	89 e5                	mov    %esp,%ebp
f010052e:	57                   	push   %edi
f010052f:	56                   	push   %esi
f0100530:	53                   	push   %ebx
f0100531:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100534:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010053b:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100542:	5a a5 
	if (*cp != 0xA55A) {
f0100544:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010054b:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010054f:	74 11                	je     f0100562 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100551:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f0100558:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010055b:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100560:	eb 16                	jmp    f0100578 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100562:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100569:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f0100570:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100573:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100578:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
f010057e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100583:	89 fa                	mov    %edi,%edx
f0100585:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100586:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100589:	89 da                	mov    %ebx,%edx
f010058b:	ec                   	in     (%dx),%al
f010058c:	0f b6 c8             	movzbl %al,%ecx
f010058f:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100592:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100597:	89 fa                	mov    %edi,%edx
f0100599:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010059a:	89 da                	mov    %ebx,%edx
f010059c:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010059d:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c
	crt_pos = pos;
f01005a3:	0f b6 c0             	movzbl %al,%eax
f01005a6:	09 c8                	or     %ecx,%eax
f01005a8:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ae:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b8:	89 f2                	mov    %esi,%edx
f01005ba:	ee                   	out    %al,(%dx)
f01005bb:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005c0:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005c5:	ee                   	out    %al,(%dx)
f01005c6:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005cb:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005d0:	89 da                	mov    %ebx,%edx
f01005d2:	ee                   	out    %al,(%dx)
f01005d3:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005dd:	ee                   	out    %al,(%dx)
f01005de:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005e3:	b8 03 00 00 00       	mov    $0x3,%eax
f01005e8:	ee                   	out    %al,(%dx)
f01005e9:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f3:	ee                   	out    %al,(%dx)
f01005f4:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005f9:	b8 01 00 00 00       	mov    $0x1,%eax
f01005fe:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ff:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100604:	ec                   	in     (%dx),%al
f0100605:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100607:	3c ff                	cmp    $0xff,%al
f0100609:	0f 95 05 34 75 11 f0 	setne  0xf0117534
f0100610:	89 f2                	mov    %esi,%edx
f0100612:	ec                   	in     (%dx),%al
f0100613:	89 da                	mov    %ebx,%edx
f0100615:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100616:	80 f9 ff             	cmp    $0xff,%cl
f0100619:	75 10                	jne    f010062b <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f010061b:	83 ec 0c             	sub    $0xc,%esp
f010061e:	68 59 37 10 f0       	push   $0xf0103759
f0100623:	e8 67 21 00 00       	call   f010278f <cprintf>
f0100628:	83 c4 10             	add    $0x10,%esp
}
f010062b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010062e:	5b                   	pop    %ebx
f010062f:	5e                   	pop    %esi
f0100630:	5f                   	pop    %edi
f0100631:	5d                   	pop    %ebp
f0100632:	c3                   	ret    

f0100633 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100633:	55                   	push   %ebp
f0100634:	89 e5                	mov    %esp,%ebp
f0100636:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100639:	8b 45 08             	mov    0x8(%ebp),%eax
f010063c:	e8 56 fc ff ff       	call   f0100297 <cons_putc>
}
f0100641:	c9                   	leave  
f0100642:	c3                   	ret    

f0100643 <getchar>:

int
getchar(void)
{
f0100643:	55                   	push   %ebp
f0100644:	89 e5                	mov    %esp,%ebp
f0100646:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100649:	e8 93 fe ff ff       	call   f01004e1 <cons_getc>
f010064e:	85 c0                	test   %eax,%eax
f0100650:	74 f7                	je     f0100649 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100652:	c9                   	leave  
f0100653:	c3                   	ret    

f0100654 <iscons>:

int
iscons(int fdnum)
{
f0100654:	55                   	push   %ebp
f0100655:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100657:	b8 01 00 00 00       	mov    $0x1,%eax
f010065c:	5d                   	pop    %ebp
f010065d:	c3                   	ret    

f010065e <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010065e:	55                   	push   %ebp
f010065f:	89 e5                	mov    %esp,%ebp
f0100661:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100664:	68 a0 39 10 f0       	push   $0xf01039a0
f0100669:	68 be 39 10 f0       	push   $0xf01039be
f010066e:	68 c3 39 10 f0       	push   $0xf01039c3
f0100673:	e8 17 21 00 00       	call   f010278f <cprintf>
f0100678:	83 c4 0c             	add    $0xc,%esp
f010067b:	68 54 3a 10 f0       	push   $0xf0103a54
f0100680:	68 cc 39 10 f0       	push   $0xf01039cc
f0100685:	68 c3 39 10 f0       	push   $0xf01039c3
f010068a:	e8 00 21 00 00       	call   f010278f <cprintf>
	return 0;
}
f010068f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100694:	c9                   	leave  
f0100695:	c3                   	ret    

f0100696 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100696:	55                   	push   %ebp
f0100697:	89 e5                	mov    %esp,%ebp
f0100699:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010069c:	68 d5 39 10 f0       	push   $0xf01039d5
f01006a1:	e8 e9 20 00 00       	call   f010278f <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a6:	83 c4 08             	add    $0x8,%esp
f01006a9:	68 0c 00 10 00       	push   $0x10000c
f01006ae:	68 7c 3a 10 f0       	push   $0xf0103a7c
f01006b3:	e8 d7 20 00 00       	call   f010278f <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b8:	83 c4 0c             	add    $0xc,%esp
f01006bb:	68 0c 00 10 00       	push   $0x10000c
f01006c0:	68 0c 00 10 f0       	push   $0xf010000c
f01006c5:	68 a4 3a 10 f0       	push   $0xf0103aa4
f01006ca:	e8 c0 20 00 00       	call   f010278f <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006cf:	83 c4 0c             	add    $0xc,%esp
f01006d2:	68 e1 36 10 00       	push   $0x1036e1
f01006d7:	68 e1 36 10 f0       	push   $0xf01036e1
f01006dc:	68 c8 3a 10 f0       	push   $0xf0103ac8
f01006e1:	e8 a9 20 00 00       	call   f010278f <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006e6:	83 c4 0c             	add    $0xc,%esp
f01006e9:	68 00 73 11 00       	push   $0x117300
f01006ee:	68 00 73 11 f0       	push   $0xf0117300
f01006f3:	68 ec 3a 10 f0       	push   $0xf0103aec
f01006f8:	e8 92 20 00 00       	call   f010278f <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006fd:	83 c4 0c             	add    $0xc,%esp
f0100700:	68 70 79 11 00       	push   $0x117970
f0100705:	68 70 79 11 f0       	push   $0xf0117970
f010070a:	68 10 3b 10 f0       	push   $0xf0103b10
f010070f:	e8 7b 20 00 00       	call   f010278f <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100714:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f0100719:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010071e:	83 c4 08             	add    $0x8,%esp
f0100721:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100726:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010072c:	85 c0                	test   %eax,%eax
f010072e:	0f 48 c2             	cmovs  %edx,%eax
f0100731:	c1 f8 0a             	sar    $0xa,%eax
f0100734:	50                   	push   %eax
f0100735:	68 34 3b 10 f0       	push   $0xf0103b34
f010073a:	e8 50 20 00 00       	call   f010278f <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010073f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100744:	c9                   	leave  
f0100745:	c3                   	ret    

f0100746 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100746:	55                   	push   %ebp
f0100747:	89 e5                	mov    %esp,%ebp
f0100749:	57                   	push   %edi
f010074a:	56                   	push   %esi
f010074b:	53                   	push   %ebx
f010074c:	83 ec 48             	sub    $0x48,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010074f:	89 e8                	mov    %ebp,%eax
	// Your code here.
	uint32_t *ebp,*eip;
	uint32_t arg0,arg1,arg2,arg3,arg4;
ebp=(uint32_t*)read_ebp();
f0100751:	89 c3                	mov    %eax,%ebx
eip=(uint32_t*)ebp[1];
f0100753:	8b 78 04             	mov    0x4(%eax),%edi
arg0=ebp[2];
f0100756:	8b 50 08             	mov    0x8(%eax),%edx
f0100759:	89 55 c0             	mov    %edx,-0x40(%ebp)
arg1=ebp[3];
f010075c:	8b 48 0c             	mov    0xc(%eax),%ecx
f010075f:	89 4d bc             	mov    %ecx,-0x44(%ebp)
arg2=ebp[4];
f0100762:	8b 70 10             	mov    0x10(%eax),%esi
f0100765:	89 75 b8             	mov    %esi,-0x48(%ebp)
arg3=ebp[5];
f0100768:	8b 70 14             	mov    0x14(%eax),%esi
f010076b:	89 75 c4             	mov    %esi,-0x3c(%ebp)
arg4=ebp[6];
f010076e:	8b 70 18             	mov    0x18(%eax),%esi

cprintf("Stack_backtrace:\n");
f0100771:	68 ee 39 10 f0       	push   $0xf01039ee
f0100776:	e8 14 20 00 00       	call   f010278f <cprintf>
while(ebp!=0){
f010077b:	83 c4 10             	add    $0x10,%esp
f010077e:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0100781:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0100784:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0100787:	eb 5c                	jmp    f01007e5 <mon_backtrace+0x9f>
cprintf("  ebp %08x eip %08x  args %08x %08x %08x %08x %08x\n",ebp,eip,arg0,arg1,arg2,arg3,arg4);
f0100789:	56                   	push   %esi
f010078a:	ff 75 c4             	pushl  -0x3c(%ebp)
f010078d:	51                   	push   %ecx
f010078e:	52                   	push   %edx
f010078f:	50                   	push   %eax
f0100790:	57                   	push   %edi
f0100791:	53                   	push   %ebx
f0100792:	68 60 3b 10 f0       	push   $0xf0103b60
f0100797:	e8 f3 1f 00 00       	call   f010278f <cprintf>

struct Eipdebuginfo info;
debuginfo_eip(ebp[1], &info);
f010079c:	83 c4 18             	add    $0x18,%esp
f010079f:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007a2:	50                   	push   %eax
f01007a3:	ff 73 04             	pushl  0x4(%ebx)
f01007a6:	e8 ee 20 00 00       	call   f0102899 <debuginfo_eip>
    cprintf("\n     %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1] - info.eip_fn_addr);
f01007ab:	83 c4 08             	add    $0x8,%esp
f01007ae:	8b 43 04             	mov    0x4(%ebx),%eax
f01007b1:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01007b4:	50                   	push   %eax
f01007b5:	ff 75 d8             	pushl  -0x28(%ebp)
f01007b8:	ff 75 dc             	pushl  -0x24(%ebp)
f01007bb:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007be:	ff 75 d0             	pushl  -0x30(%ebp)
f01007c1:	68 00 3a 10 f0       	push   $0xf0103a00
f01007c6:	e8 c4 1f 00 00       	call   f010278f <cprintf>
    ebp = (uint32_t*)ebp[0];
f01007cb:	8b 1b                	mov    (%ebx),%ebx
eip=(uint32_t*)ebp[1];
f01007cd:	8b 7b 04             	mov    0x4(%ebx),%edi
arg0=ebp[2];
f01007d0:	8b 43 08             	mov    0x8(%ebx),%eax
arg1=ebp[3];
f01007d3:	8b 53 0c             	mov    0xc(%ebx),%edx
arg2=ebp[4];
f01007d6:	8b 4b 10             	mov    0x10(%ebx),%ecx
arg3=ebp[5];
f01007d9:	8b 73 14             	mov    0x14(%ebx),%esi
f01007dc:	89 75 c4             	mov    %esi,-0x3c(%ebp)
arg4=ebp[6];
f01007df:	8b 73 18             	mov    0x18(%ebx),%esi
f01007e2:	83 c4 20             	add    $0x20,%esp
arg2=ebp[4];
arg3=ebp[5];
arg4=ebp[6];

cprintf("Stack_backtrace:\n");
while(ebp!=0){
f01007e5:	85 db                	test   %ebx,%ebx
f01007e7:	75 a0                	jne    f0100789 <mon_backtrace+0x43>
arg2=ebp[4];
arg3=ebp[5];
arg4=ebp[6];
}
	return 0;
}
f01007e9:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ee:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007f1:	5b                   	pop    %ebx
f01007f2:	5e                   	pop    %esi
f01007f3:	5f                   	pop    %edi
f01007f4:	5d                   	pop    %ebp
f01007f5:	c3                   	ret    

f01007f6 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007f6:	55                   	push   %ebp
f01007f7:	89 e5                	mov    %esp,%ebp
f01007f9:	57                   	push   %edi
f01007fa:	56                   	push   %esi
f01007fb:	53                   	push   %ebx
f01007fc:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007ff:	68 94 3b 10 f0       	push   $0xf0103b94
f0100804:	e8 86 1f 00 00       	call   f010278f <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100809:	c7 04 24 b8 3b 10 f0 	movl   $0xf0103bb8,(%esp)
f0100810:	e8 7a 1f 00 00       	call   f010278f <cprintf>
f0100815:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100818:	83 ec 0c             	sub    $0xc,%esp
f010081b:	68 16 3a 10 f0       	push   $0xf0103a16
f0100820:	e8 d7 27 00 00       	call   f0102ffc <readline>
f0100825:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100827:	83 c4 10             	add    $0x10,%esp
f010082a:	85 c0                	test   %eax,%eax
f010082c:	74 ea                	je     f0100818 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010082e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100835:	be 00 00 00 00       	mov    $0x0,%esi
f010083a:	eb 0a                	jmp    f0100846 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010083c:	c6 03 00             	movb   $0x0,(%ebx)
f010083f:	89 f7                	mov    %esi,%edi
f0100841:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100844:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100846:	0f b6 03             	movzbl (%ebx),%eax
f0100849:	84 c0                	test   %al,%al
f010084b:	74 63                	je     f01008b0 <monitor+0xba>
f010084d:	83 ec 08             	sub    $0x8,%esp
f0100850:	0f be c0             	movsbl %al,%eax
f0100853:	50                   	push   %eax
f0100854:	68 1a 3a 10 f0       	push   $0xf0103a1a
f0100859:	e8 b8 29 00 00       	call   f0103216 <strchr>
f010085e:	83 c4 10             	add    $0x10,%esp
f0100861:	85 c0                	test   %eax,%eax
f0100863:	75 d7                	jne    f010083c <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100865:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100868:	74 46                	je     f01008b0 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010086a:	83 fe 0f             	cmp    $0xf,%esi
f010086d:	75 14                	jne    f0100883 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010086f:	83 ec 08             	sub    $0x8,%esp
f0100872:	6a 10                	push   $0x10
f0100874:	68 1f 3a 10 f0       	push   $0xf0103a1f
f0100879:	e8 11 1f 00 00       	call   f010278f <cprintf>
f010087e:	83 c4 10             	add    $0x10,%esp
f0100881:	eb 95                	jmp    f0100818 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100883:	8d 7e 01             	lea    0x1(%esi),%edi
f0100886:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010088a:	eb 03                	jmp    f010088f <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010088c:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010088f:	0f b6 03             	movzbl (%ebx),%eax
f0100892:	84 c0                	test   %al,%al
f0100894:	74 ae                	je     f0100844 <monitor+0x4e>
f0100896:	83 ec 08             	sub    $0x8,%esp
f0100899:	0f be c0             	movsbl %al,%eax
f010089c:	50                   	push   %eax
f010089d:	68 1a 3a 10 f0       	push   $0xf0103a1a
f01008a2:	e8 6f 29 00 00       	call   f0103216 <strchr>
f01008a7:	83 c4 10             	add    $0x10,%esp
f01008aa:	85 c0                	test   %eax,%eax
f01008ac:	74 de                	je     f010088c <monitor+0x96>
f01008ae:	eb 94                	jmp    f0100844 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008b0:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008b7:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008b8:	85 f6                	test   %esi,%esi
f01008ba:	0f 84 58 ff ff ff    	je     f0100818 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008c0:	83 ec 08             	sub    $0x8,%esp
f01008c3:	68 be 39 10 f0       	push   $0xf01039be
f01008c8:	ff 75 a8             	pushl  -0x58(%ebp)
f01008cb:	e8 e8 28 00 00       	call   f01031b8 <strcmp>
f01008d0:	83 c4 10             	add    $0x10,%esp
f01008d3:	85 c0                	test   %eax,%eax
f01008d5:	74 1e                	je     f01008f5 <monitor+0xff>
f01008d7:	83 ec 08             	sub    $0x8,%esp
f01008da:	68 cc 39 10 f0       	push   $0xf01039cc
f01008df:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e2:	e8 d1 28 00 00       	call   f01031b8 <strcmp>
f01008e7:	83 c4 10             	add    $0x10,%esp
f01008ea:	85 c0                	test   %eax,%eax
f01008ec:	75 2f                	jne    f010091d <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008ee:	b8 01 00 00 00       	mov    $0x1,%eax
f01008f3:	eb 05                	jmp    f01008fa <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008f5:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008fa:	83 ec 04             	sub    $0x4,%esp
f01008fd:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100900:	01 d0                	add    %edx,%eax
f0100902:	ff 75 08             	pushl  0x8(%ebp)
f0100905:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100908:	51                   	push   %ecx
f0100909:	56                   	push   %esi
f010090a:	ff 14 85 e8 3b 10 f0 	call   *-0xfefc418(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100911:	83 c4 10             	add    $0x10,%esp
f0100914:	85 c0                	test   %eax,%eax
f0100916:	78 1d                	js     f0100935 <monitor+0x13f>
f0100918:	e9 fb fe ff ff       	jmp    f0100818 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010091d:	83 ec 08             	sub    $0x8,%esp
f0100920:	ff 75 a8             	pushl  -0x58(%ebp)
f0100923:	68 3c 3a 10 f0       	push   $0xf0103a3c
f0100928:	e8 62 1e 00 00       	call   f010278f <cprintf>
f010092d:	83 c4 10             	add    $0x10,%esp
f0100930:	e9 e3 fe ff ff       	jmp    f0100818 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100935:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100938:	5b                   	pop    %ebx
f0100939:	5e                   	pop    %esi
f010093a:	5f                   	pop    %edi
f010093b:	5d                   	pop    %ebp
f010093c:	c3                   	ret    

f010093d <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f010093d:	55                   	push   %ebp
f010093e:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100940:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100947:	75 11                	jne    f010095a <boot_alloc+0x1d>
		 extern char end[];
		
        	nextfree = ROUNDUP((char *) end, PGSIZE);  
f0100949:	ba 6f 89 11 f0       	mov    $0xf011896f,%edx
f010094e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100954:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
        if(n==0)  
f010095a:	85 c0                	test   %eax,%eax
f010095c:	75 07                	jne    f0100965 <boot_alloc+0x28>
        	return nextfree;  
f010095e:	a1 38 75 11 f0       	mov    0xf0117538,%eax
f0100963:	eb 19                	jmp    f010097e <boot_alloc+0x41>
    	result = nextfree;  
f0100965:	8b 15 38 75 11 f0    	mov    0xf0117538,%edx
    	nextfree += n;  
    	nextfree = ROUNDUP( (char*)nextfree, PGSIZE);  
f010096b:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100972:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100977:	a3 38 75 11 f0       	mov    %eax,0xf0117538
	return result;
f010097c:	89 d0                	mov    %edx,%eax
}
f010097e:	5d                   	pop    %ebp
f010097f:	c3                   	ret    

f0100980 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100980:	89 d1                	mov    %edx,%ecx
f0100982:	c1 e9 16             	shr    $0x16,%ecx
f0100985:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100988:	a8 01                	test   $0x1,%al
f010098a:	74 52                	je     f01009de <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010098c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100991:	89 c1                	mov    %eax,%ecx
f0100993:	c1 e9 0c             	shr    $0xc,%ecx
f0100996:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f010099c:	72 1b                	jb     f01009b9 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010099e:	55                   	push   %ebp
f010099f:	89 e5                	mov    %esp,%ebp
f01009a1:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009a4:	50                   	push   %eax
f01009a5:	68 f8 3b 10 f0       	push   $0xf0103bf8
f01009aa:	68 ec 02 00 00       	push   $0x2ec
f01009af:	68 4c 43 10 f0       	push   $0xf010434c
f01009b4:	e8 d2 f6 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009b9:	c1 ea 0c             	shr    $0xc,%edx
f01009bc:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009c2:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009c9:	89 c2                	mov    %eax,%edx
f01009cb:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009ce:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009d3:	85 d2                	test   %edx,%edx
f01009d5:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009da:	0f 44 c2             	cmove  %edx,%eax
f01009dd:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009e3:	c3                   	ret    

f01009e4 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009e4:	55                   	push   %ebp
f01009e5:	89 e5                	mov    %esp,%ebp
f01009e7:	57                   	push   %edi
f01009e8:	56                   	push   %esi
f01009e9:	53                   	push   %ebx
f01009ea:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009ed:	84 c0                	test   %al,%al
f01009ef:	0f 85 72 02 00 00    	jne    f0100c67 <check_page_free_list+0x283>
f01009f5:	e9 7f 02 00 00       	jmp    f0100c79 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009fa:	83 ec 04             	sub    $0x4,%esp
f01009fd:	68 1c 3c 10 f0       	push   $0xf0103c1c
f0100a02:	68 2f 02 00 00       	push   $0x22f
f0100a07:	68 4c 43 10 f0       	push   $0xf010434c
f0100a0c:	e8 7a f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a11:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a14:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a17:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a1a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a1d:	89 c2                	mov    %eax,%edx
f0100a1f:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0100a25:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a2b:	0f 95 c2             	setne  %dl
f0100a2e:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a31:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a35:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a37:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a3b:	8b 00                	mov    (%eax),%eax
f0100a3d:	85 c0                	test   %eax,%eax
f0100a3f:	75 dc                	jne    f0100a1d <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a41:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a44:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a4a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a4d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a50:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a52:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a55:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a5a:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a5f:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100a65:	eb 53                	jmp    f0100aba <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a67:	89 d8                	mov    %ebx,%eax
f0100a69:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100a6f:	c1 f8 03             	sar    $0x3,%eax
f0100a72:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a75:	89 c2                	mov    %eax,%edx
f0100a77:	c1 ea 16             	shr    $0x16,%edx
f0100a7a:	39 f2                	cmp    %esi,%edx
f0100a7c:	73 3a                	jae    f0100ab8 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a7e:	89 c2                	mov    %eax,%edx
f0100a80:	c1 ea 0c             	shr    $0xc,%edx
f0100a83:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100a89:	72 12                	jb     f0100a9d <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a8b:	50                   	push   %eax
f0100a8c:	68 f8 3b 10 f0       	push   $0xf0103bf8
f0100a91:	6a 52                	push   $0x52
f0100a93:	68 58 43 10 f0       	push   $0xf0104358
f0100a98:	e8 ee f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a9d:	83 ec 04             	sub    $0x4,%esp
f0100aa0:	68 80 00 00 00       	push   $0x80
f0100aa5:	68 97 00 00 00       	push   $0x97
f0100aaa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100aaf:	50                   	push   %eax
f0100ab0:	e8 9e 27 00 00       	call   f0103253 <memset>
f0100ab5:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ab8:	8b 1b                	mov    (%ebx),%ebx
f0100aba:	85 db                	test   %ebx,%ebx
f0100abc:	75 a9                	jne    f0100a67 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100abe:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ac3:	e8 75 fe ff ff       	call   f010093d <boot_alloc>
f0100ac8:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100acb:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ad1:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100ad7:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100adc:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100adf:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ae2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ae5:	be 00 00 00 00       	mov    $0x0,%esi
f0100aea:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aed:	e9 30 01 00 00       	jmp    f0100c22 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100af2:	39 ca                	cmp    %ecx,%edx
f0100af4:	73 19                	jae    f0100b0f <check_page_free_list+0x12b>
f0100af6:	68 66 43 10 f0       	push   $0xf0104366
f0100afb:	68 72 43 10 f0       	push   $0xf0104372
f0100b00:	68 49 02 00 00       	push   $0x249
f0100b05:	68 4c 43 10 f0       	push   $0xf010434c
f0100b0a:	e8 7c f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b0f:	39 fa                	cmp    %edi,%edx
f0100b11:	72 19                	jb     f0100b2c <check_page_free_list+0x148>
f0100b13:	68 87 43 10 f0       	push   $0xf0104387
f0100b18:	68 72 43 10 f0       	push   $0xf0104372
f0100b1d:	68 4a 02 00 00       	push   $0x24a
f0100b22:	68 4c 43 10 f0       	push   $0xf010434c
f0100b27:	e8 5f f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b2c:	89 d0                	mov    %edx,%eax
f0100b2e:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b31:	a8 07                	test   $0x7,%al
f0100b33:	74 19                	je     f0100b4e <check_page_free_list+0x16a>
f0100b35:	68 40 3c 10 f0       	push   $0xf0103c40
f0100b3a:	68 72 43 10 f0       	push   $0xf0104372
f0100b3f:	68 4b 02 00 00       	push   $0x24b
f0100b44:	68 4c 43 10 f0       	push   $0xf010434c
f0100b49:	e8 3d f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b4e:	c1 f8 03             	sar    $0x3,%eax
f0100b51:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b54:	85 c0                	test   %eax,%eax
f0100b56:	75 19                	jne    f0100b71 <check_page_free_list+0x18d>
f0100b58:	68 9b 43 10 f0       	push   $0xf010439b
f0100b5d:	68 72 43 10 f0       	push   $0xf0104372
f0100b62:	68 4e 02 00 00       	push   $0x24e
f0100b67:	68 4c 43 10 f0       	push   $0xf010434c
f0100b6c:	e8 1a f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b71:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b76:	75 19                	jne    f0100b91 <check_page_free_list+0x1ad>
f0100b78:	68 ac 43 10 f0       	push   $0xf01043ac
f0100b7d:	68 72 43 10 f0       	push   $0xf0104372
f0100b82:	68 4f 02 00 00       	push   $0x24f
f0100b87:	68 4c 43 10 f0       	push   $0xf010434c
f0100b8c:	e8 fa f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b91:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b96:	75 19                	jne    f0100bb1 <check_page_free_list+0x1cd>
f0100b98:	68 74 3c 10 f0       	push   $0xf0103c74
f0100b9d:	68 72 43 10 f0       	push   $0xf0104372
f0100ba2:	68 50 02 00 00       	push   $0x250
f0100ba7:	68 4c 43 10 f0       	push   $0xf010434c
f0100bac:	e8 da f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bb1:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bb6:	75 19                	jne    f0100bd1 <check_page_free_list+0x1ed>
f0100bb8:	68 c5 43 10 f0       	push   $0xf01043c5
f0100bbd:	68 72 43 10 f0       	push   $0xf0104372
f0100bc2:	68 51 02 00 00       	push   $0x251
f0100bc7:	68 4c 43 10 f0       	push   $0xf010434c
f0100bcc:	e8 ba f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bd1:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bd6:	76 3f                	jbe    f0100c17 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bd8:	89 c3                	mov    %eax,%ebx
f0100bda:	c1 eb 0c             	shr    $0xc,%ebx
f0100bdd:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100be0:	77 12                	ja     f0100bf4 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100be2:	50                   	push   %eax
f0100be3:	68 f8 3b 10 f0       	push   $0xf0103bf8
f0100be8:	6a 52                	push   $0x52
f0100bea:	68 58 43 10 f0       	push   $0xf0104358
f0100bef:	e8 97 f4 ff ff       	call   f010008b <_panic>
f0100bf4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bf9:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bfc:	76 1e                	jbe    f0100c1c <check_page_free_list+0x238>
f0100bfe:	68 98 3c 10 f0       	push   $0xf0103c98
f0100c03:	68 72 43 10 f0       	push   $0xf0104372
f0100c08:	68 52 02 00 00       	push   $0x252
f0100c0d:	68 4c 43 10 f0       	push   $0xf010434c
f0100c12:	e8 74 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c17:	83 c6 01             	add    $0x1,%esi
f0100c1a:	eb 04                	jmp    f0100c20 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c1c:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c20:	8b 12                	mov    (%edx),%edx
f0100c22:	85 d2                	test   %edx,%edx
f0100c24:	0f 85 c8 fe ff ff    	jne    f0100af2 <check_page_free_list+0x10e>
f0100c2a:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c2d:	85 f6                	test   %esi,%esi
f0100c2f:	7f 19                	jg     f0100c4a <check_page_free_list+0x266>
f0100c31:	68 df 43 10 f0       	push   $0xf01043df
f0100c36:	68 72 43 10 f0       	push   $0xf0104372
f0100c3b:	68 5a 02 00 00       	push   $0x25a
f0100c40:	68 4c 43 10 f0       	push   $0xf010434c
f0100c45:	e8 41 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c4a:	85 db                	test   %ebx,%ebx
f0100c4c:	7f 42                	jg     f0100c90 <check_page_free_list+0x2ac>
f0100c4e:	68 f1 43 10 f0       	push   $0xf01043f1
f0100c53:	68 72 43 10 f0       	push   $0xf0104372
f0100c58:	68 5b 02 00 00       	push   $0x25b
f0100c5d:	68 4c 43 10 f0       	push   $0xf010434c
f0100c62:	e8 24 f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c67:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100c6c:	85 c0                	test   %eax,%eax
f0100c6e:	0f 85 9d fd ff ff    	jne    f0100a11 <check_page_free_list+0x2d>
f0100c74:	e9 81 fd ff ff       	jmp    f01009fa <check_page_free_list+0x16>
f0100c79:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100c80:	0f 84 74 fd ff ff    	je     f01009fa <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c86:	be 00 04 00 00       	mov    $0x400,%esi
f0100c8b:	e9 cf fd ff ff       	jmp    f0100a5f <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c90:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c93:	5b                   	pop    %ebx
f0100c94:	5e                   	pop    %esi
f0100c95:	5f                   	pop    %edi
f0100c96:	5d                   	pop    %ebp
f0100c97:	c3                   	ret    

f0100c98 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c98:	55                   	push   %ebp
f0100c99:	89 e5                	mov    %esp,%ebp
f0100c9b:	56                   	push   %esi
f0100c9c:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100c9d:	be 00 00 00 00       	mov    $0x0,%esi
f0100ca2:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100ca7:	e9 c5 00 00 00       	jmp    f0100d71 <page_init+0xd9>
		//pages[i].pp_ref = 0;
		//pages[i].pp_link = page_free_list;
		//page_free_list = &pages[i];
		if(i == 0)  
f0100cac:	85 db                	test   %ebx,%ebx
f0100cae:	75 16                	jne    f0100cc6 <page_init+0x2e>
            	{   
			pages[i].pp_ref = 1;  
f0100cb0:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100cb5:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
                	pages[i].pp_link = NULL;  
f0100cbb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100cc1:	e9 a5 00 00 00       	jmp    f0100d6b <page_init+0xd3>
            	}  
        	else if(i>=1 && i<npages_basemem)  
f0100cc6:	3b 1d 40 75 11 f0    	cmp    0xf0117540,%ebx
f0100ccc:	73 25                	jae    f0100cf3 <page_init+0x5b>
        	{  
            		pages[i].pp_ref = 0;  
f0100cce:	89 f0                	mov    %esi,%eax
f0100cd0:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100cd6:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
            		pages[i].pp_link = page_free_list;   
f0100cdc:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100ce2:	89 10                	mov    %edx,(%eax)
            		page_free_list = &pages[i];  
f0100ce4:	89 f0                	mov    %esi,%eax
f0100ce6:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100cec:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
f0100cf1:	eb 78                	jmp    f0100d6b <page_init+0xd3>
        	}  
        	else if(i>=IOPHYSMEM/PGSIZE && i< EXTPHYSMEM/PGSIZE )  
f0100cf3:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100cf9:	83 f8 5f             	cmp    $0x5f,%eax
f0100cfc:	77 16                	ja     f0100d14 <page_init+0x7c>
        	{  
            		pages[i].pp_ref = 1;  
f0100cfe:	89 f0                	mov    %esi,%eax
f0100d00:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100d06:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
            		pages[i].pp_link = NULL;  
f0100d0c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100d12:	eb 57                	jmp    f0100d6b <page_init+0xd3>
        	}  
      
        	else if( i >= EXTPHYSMEM / PGSIZE &&   i < ( (int)(boot_alloc(0)) - KERNBASE)/PGSIZE)  
f0100d14:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100d1a:	76 2c                	jbe    f0100d48 <page_init+0xb0>
f0100d1c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d21:	e8 17 fc ff ff       	call   f010093d <boot_alloc>
f0100d26:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d2b:	c1 e8 0c             	shr    $0xc,%eax
f0100d2e:	39 c3                	cmp    %eax,%ebx
f0100d30:	73 16                	jae    f0100d48 <page_init+0xb0>
        	{  
            		pages[i].pp_ref = 1;  
f0100d32:	89 f0                	mov    %esi,%eax
f0100d34:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100d3a:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
            		pages[i].pp_link =NULL;  
f0100d40:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100d46:	eb 23                	jmp    f0100d6b <page_init+0xd3>
        	}  
        	else  
        	{  
            		pages[i].pp_ref = 0;  
f0100d48:	89 f0                	mov    %esi,%eax
f0100d4a:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100d50:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
            		pages[i].pp_link = page_free_list;  
f0100d56:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100d5c:	89 10                	mov    %edx,(%eax)
            		page_free_list = &pages[i];  
f0100d5e:	89 f0                	mov    %esi,%eax
f0100d60:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100d66:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100d6b:	83 c3 01             	add    $0x1,%ebx
f0100d6e:	83 c6 08             	add    $0x8,%esi
f0100d71:	3b 1d 64 79 11 f0    	cmp    0xf0117964,%ebx
f0100d77:	0f 82 2f ff ff ff    	jb     f0100cac <page_init+0x14>
            		pages[i].pp_ref = 0;  
            		pages[i].pp_link = page_free_list;  
            		page_free_list = &pages[i];  
        	}  
	}
}
f0100d7d:	5b                   	pop    %ebx
f0100d7e:	5e                   	pop    %esi
f0100d7f:	5d                   	pop    %ebp
f0100d80:	c3                   	ret    

f0100d81 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d81:	55                   	push   %ebp
f0100d82:	89 e5                	mov    %esp,%ebp
f0100d84:	53                   	push   %ebx
f0100d85:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
   	if(page_free_list == NULL)  
f0100d88:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100d8e:	85 db                	test   %ebx,%ebx
f0100d90:	74 58                	je     f0100dea <page_alloc+0x69>
        	return NULL;  
  
    	struct PageInfo* page = page_free_list;  
    	page_free_list = page->pp_link;  
f0100d92:	8b 03                	mov    (%ebx),%eax
f0100d94:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
    	page->pp_link = 0;  
f0100d99:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
    	if(alloc_flags & ALLOC_ZERO)  
f0100d9f:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100da3:	74 45                	je     f0100dea <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100da5:	89 d8                	mov    %ebx,%eax
f0100da7:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100dad:	c1 f8 03             	sar    $0x3,%eax
f0100db0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100db3:	89 c2                	mov    %eax,%edx
f0100db5:	c1 ea 0c             	shr    $0xc,%edx
f0100db8:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100dbe:	72 12                	jb     f0100dd2 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dc0:	50                   	push   %eax
f0100dc1:	68 f8 3b 10 f0       	push   $0xf0103bf8
f0100dc6:	6a 52                	push   $0x52
f0100dc8:	68 58 43 10 f0       	push   $0xf0104358
f0100dcd:	e8 b9 f2 ff ff       	call   f010008b <_panic>
        	memset(page2kva(page), 0, PGSIZE);  
f0100dd2:	83 ec 04             	sub    $0x4,%esp
f0100dd5:	68 00 10 00 00       	push   $0x1000
f0100dda:	6a 00                	push   $0x0
f0100ddc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100de1:	50                   	push   %eax
f0100de2:	e8 6c 24 00 00       	call   f0103253 <memset>
f0100de7:	83 c4 10             	add    $0x10,%esp
    	return page;  
}
f0100dea:	89 d8                	mov    %ebx,%eax
f0100dec:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100def:	c9                   	leave  
f0100df0:	c3                   	ret    

f0100df1 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100df1:	55                   	push   %ebp
f0100df2:	89 e5                	mov    %esp,%ebp
f0100df4:	83 ec 08             	sub    $0x8,%esp
f0100df7:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_link != 0  || pp->pp_ref != 0)  
f0100dfa:	83 38 00             	cmpl   $0x0,(%eax)
f0100dfd:	75 07                	jne    f0100e06 <page_free+0x15>
f0100dff:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e04:	74 17                	je     f0100e1d <page_free+0x2c>
        	panic("page_free is not right");  
f0100e06:	83 ec 04             	sub    $0x4,%esp
f0100e09:	68 02 44 10 f0       	push   $0xf0104402
f0100e0e:	68 55 01 00 00       	push   $0x155
f0100e13:	68 4c 43 10 f0       	push   $0xf010434c
f0100e18:	e8 6e f2 ff ff       	call   f010008b <_panic>
    	pp->pp_link = page_free_list;  
f0100e1d:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100e23:	89 10                	mov    %edx,(%eax)
    	page_free_list = pp;  
f0100e25:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
    	return;   
}
f0100e2a:	c9                   	leave  
f0100e2b:	c3                   	ret    

f0100e2c <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e2c:	55                   	push   %ebp
f0100e2d:	89 e5                	mov    %esp,%ebp
f0100e2f:	83 ec 08             	sub    $0x8,%esp
f0100e32:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e35:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e39:	83 e8 01             	sub    $0x1,%eax
f0100e3c:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e40:	66 85 c0             	test   %ax,%ax
f0100e43:	75 0c                	jne    f0100e51 <page_decref+0x25>
		page_free(pp);
f0100e45:	83 ec 0c             	sub    $0xc,%esp
f0100e48:	52                   	push   %edx
f0100e49:	e8 a3 ff ff ff       	call   f0100df1 <page_free>
f0100e4e:	83 c4 10             	add    $0x10,%esp
}
f0100e51:	c9                   	leave  
f0100e52:	c3                   	ret    

f0100e53 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e53:	55                   	push   %ebp
f0100e54:	89 e5                	mov    %esp,%ebp
f0100e56:	56                   	push   %esi
f0100e57:	53                   	push   %ebx
f0100e58:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in 
    	int pdeIndex = (unsigned int)va >>22;  
    	if(pgdir[pdeIndex] == 0 && create == 0)  
f0100e5b:	89 f3                	mov    %esi,%ebx
f0100e5d:	c1 eb 16             	shr    $0x16,%ebx
f0100e60:	c1 e3 02             	shl    $0x2,%ebx
f0100e63:	03 5d 08             	add    0x8(%ebp),%ebx
f0100e66:	8b 03                	mov    (%ebx),%eax
f0100e68:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e6c:	75 04                	jne    f0100e72 <pgdir_walk+0x1f>
f0100e6e:	85 c0                	test   %eax,%eax
f0100e70:	74 68                	je     f0100eda <pgdir_walk+0x87>
        	return NULL;  
    	if(pgdir[pdeIndex] == 0){  
f0100e72:	85 c0                	test   %eax,%eax
f0100e74:	75 27                	jne    f0100e9d <pgdir_walk+0x4a>
        	struct PageInfo* page = page_alloc(1);  
f0100e76:	83 ec 0c             	sub    $0xc,%esp
f0100e79:	6a 01                	push   $0x1
f0100e7b:	e8 01 ff ff ff       	call   f0100d81 <page_alloc>
        	if(page == NULL)  
f0100e80:	83 c4 10             	add    $0x10,%esp
f0100e83:	85 c0                	test   %eax,%eax
f0100e85:	74 5a                	je     f0100ee1 <pgdir_walk+0x8e>
            	return NULL;  
        	page->pp_ref++;  
f0100e87:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
        	pte_t pgAddress = page2pa(page);  
        	pgAddress |= PTE_U;  
        	pgAddress |= PTE_P;  
        	pgAddress |= PTE_W;  
        	pgdir[pdeIndex] = pgAddress;  
f0100e8c:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100e92:	c1 f8 03             	sar    $0x3,%eax
f0100e95:	c1 e0 0c             	shl    $0xc,%eax
f0100e98:	83 c8 07             	or     $0x7,%eax
f0100e9b:	89 03                	mov    %eax,(%ebx)
    	}  
    	pte_t pgAdd = pgdir[pdeIndex];  
f0100e9d:	8b 13                	mov    (%ebx),%edx
    	pgAdd = pgAdd>>12<<12;  
    	int pteIndex =(pte_t)va >>12 & 0x3ff;  
    	pte_t * pte =(pte_t*) pgAdd + pteIndex;  
f0100e9f:	c1 ee 0a             	shr    $0xa,%esi
f0100ea2:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100ea8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100eae:	8d 04 16             	lea    (%esi,%edx,1),%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eb1:	89 c2                	mov    %eax,%edx
f0100eb3:	c1 ea 0c             	shr    $0xc,%edx
f0100eb6:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100ebc:	72 15                	jb     f0100ed3 <pgdir_walk+0x80>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ebe:	50                   	push   %eax
f0100ebf:	68 f8 3b 10 f0       	push   $0xf0103bf8
f0100ec4:	68 92 01 00 00       	push   $0x192
f0100ec9:	68 4c 43 10 f0       	push   $0xf010434c
f0100ece:	e8 b8 f1 ff ff       	call   f010008b <_panic>
    	return KADDR( (pte_t) pte );  
f0100ed3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ed8:	eb 0c                	jmp    f0100ee6 <pgdir_walk+0x93>
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
	// Fill this function in 
    	int pdeIndex = (unsigned int)va >>22;  
    	if(pgdir[pdeIndex] == 0 && create == 0)  
        	return NULL;  
f0100eda:	b8 00 00 00 00       	mov    $0x0,%eax
f0100edf:	eb 05                	jmp    f0100ee6 <pgdir_walk+0x93>
    	if(pgdir[pdeIndex] == 0){  
        	struct PageInfo* page = page_alloc(1);  
        	if(page == NULL)  
            	return NULL;  
f0100ee1:	b8 00 00 00 00       	mov    $0x0,%eax
    	pte_t pgAdd = pgdir[pdeIndex];  
    	pgAdd = pgAdd>>12<<12;  
    	int pteIndex =(pte_t)va >>12 & 0x3ff;  
    	pte_t * pte =(pte_t*) pgAdd + pteIndex;  
    	return KADDR( (pte_t) pte );  
}
f0100ee6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ee9:	5b                   	pop    %ebx
f0100eea:	5e                   	pop    %esi
f0100eeb:	5d                   	pop    %ebp
f0100eec:	c3                   	ret    

f0100eed <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100eed:	55                   	push   %ebp
f0100eee:	89 e5                	mov    %esp,%ebp
f0100ef0:	53                   	push   %ebx
f0100ef1:	83 ec 08             	sub    $0x8,%esp
f0100ef4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t* pte = pgdir_walk(pgdir, va, 0);  
f0100ef7:	6a 00                	push   $0x0
f0100ef9:	ff 75 0c             	pushl  0xc(%ebp)
f0100efc:	ff 75 08             	pushl  0x8(%ebp)
f0100eff:	e8 4f ff ff ff       	call   f0100e53 <pgdir_walk>
    	if(pte == NULL)  
f0100f04:	83 c4 10             	add    $0x10,%esp
f0100f07:	85 c0                	test   %eax,%eax
f0100f09:	74 3a                	je     f0100f45 <page_lookup+0x58>
        	return NULL;  
    	pte_t pa =  *pte>>12<<12;  
f0100f0b:	8b 10                	mov    (%eax),%edx
f0100f0d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
    	if(pte_store != 0)  
f0100f13:	85 db                	test   %ebx,%ebx
f0100f15:	74 02                	je     f0100f19 <page_lookup+0x2c>
        	*pte_store = pte ;  
f0100f17:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f19:	89 d0                	mov    %edx,%eax
f0100f1b:	c1 e8 0c             	shr    $0xc,%eax
f0100f1e:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100f24:	72 14                	jb     f0100f3a <page_lookup+0x4d>
		panic("pa2page called with invalid pa");
f0100f26:	83 ec 04             	sub    $0x4,%esp
f0100f29:	68 e0 3c 10 f0       	push   $0xf0103ce0
f0100f2e:	6a 4b                	push   $0x4b
f0100f30:	68 58 43 10 f0       	push   $0xf0104358
f0100f35:	e8 51 f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100f3a:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0100f40:	8d 04 c2             	lea    (%edx,%eax,8),%eax
    	return pa2page(pa);
f0100f43:	eb 05                	jmp    f0100f4a <page_lookup+0x5d>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t* pte = pgdir_walk(pgdir, va, 0);  
    	if(pte == NULL)  
        	return NULL;  
f0100f45:	b8 00 00 00 00       	mov    $0x0,%eax
    	pte_t pa =  *pte>>12<<12;  
    	if(pte_store != 0)  
        	*pte_store = pte ;  
    	return pa2page(pa);
}
f0100f4a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f4d:	c9                   	leave  
f0100f4e:	c3                   	ret    

f0100f4f <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f4f:	55                   	push   %ebp
f0100f50:	89 e5                	mov    %esp,%ebp
f0100f52:	53                   	push   %ebx
f0100f53:	83 ec 18             	sub    $0x18,%esp
f0100f56:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t* pte;  
    	struct PageInfo* page = page_lookup(pgdir, va, &pte);  
f0100f59:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f5c:	50                   	push   %eax
f0100f5d:	53                   	push   %ebx
f0100f5e:	ff 75 08             	pushl  0x8(%ebp)
f0100f61:	e8 87 ff ff ff       	call   f0100eed <page_lookup>
    	if(page == 0)  
f0100f66:	83 c4 10             	add    $0x10,%esp
f0100f69:	85 c0                	test   %eax,%eax
f0100f6b:	74 28                	je     f0100f95 <page_remove+0x46>
        	return;  
    	*pte = 0;  
f0100f6d:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100f70:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
    	page->pp_ref--;  
f0100f76:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100f7a:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100f7d:	66 89 50 04          	mov    %dx,0x4(%eax)
    	if(page->pp_ref ==0)  
f0100f81:	66 85 d2             	test   %dx,%dx
f0100f84:	75 0c                	jne    f0100f92 <page_remove+0x43>
        	page_free(page);  
f0100f86:	83 ec 0c             	sub    $0xc,%esp
f0100f89:	50                   	push   %eax
f0100f8a:	e8 62 fe ff ff       	call   f0100df1 <page_free>
f0100f8f:	83 c4 10             	add    $0x10,%esp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f92:	0f 01 3b             	invlpg (%ebx)
    	tlb_invalidate(pgdir, va);  
}
f0100f95:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f98:	c9                   	leave  
f0100f99:	c3                   	ret    

f0100f9a <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f9a:	55                   	push   %ebp
f0100f9b:	89 e5                	mov    %esp,%ebp
f0100f9d:	57                   	push   %edi
f0100f9e:	56                   	push   %esi
f0100f9f:	53                   	push   %ebx
f0100fa0:	83 ec 10             	sub    $0x10,%esp
f0100fa3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fa6:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in

	pte_t* pte = pgdir_walk(pgdir, va, 1);  
f0100fa9:	6a 01                	push   $0x1
f0100fab:	57                   	push   %edi
f0100fac:	ff 75 08             	pushl  0x8(%ebp)
f0100faf:	e8 9f fe ff ff       	call   f0100e53 <pgdir_walk>
    	if(pte == NULL)  
f0100fb4:	83 c4 10             	add    $0x10,%esp
f0100fb7:	85 c0                	test   %eax,%eax
f0100fb9:	74 5c                	je     f0101017 <page_insert+0x7d>
f0100fbb:	89 c6                	mov    %eax,%esi
      	  	return -E_NO_MEM;  
   	if( (pte[0] &  ~0xfff) == page2pa(pp))  
f0100fbd:	8b 10                	mov    (%eax),%edx
f0100fbf:	89 d1                	mov    %edx,%ecx
f0100fc1:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100fc7:	89 d8                	mov    %ebx,%eax
f0100fc9:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100fcf:	c1 f8 03             	sar    $0x3,%eax
f0100fd2:	c1 e0 0c             	shl    $0xc,%eax
f0100fd5:	39 c1                	cmp    %eax,%ecx
f0100fd7:	75 07                	jne    f0100fe0 <page_insert+0x46>
     	   	pp->pp_ref--;  
f0100fd9:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f0100fde:	eb 13                	jmp    f0100ff3 <page_insert+0x59>
    	else if(*pte != 0)  
f0100fe0:	85 d2                	test   %edx,%edx
f0100fe2:	74 0f                	je     f0100ff3 <page_insert+0x59>
        	page_remove(pgdir, va);  
f0100fe4:	83 ec 08             	sub    $0x8,%esp
f0100fe7:	57                   	push   %edi
f0100fe8:	ff 75 08             	pushl  0x8(%ebp)
f0100feb:	e8 5f ff ff ff       	call   f0100f4f <page_remove>
f0100ff0:	83 c4 10             	add    $0x10,%esp
  
    	*pte = (page2pa(pp) & ~0xfff) | perm | PTE_P;  
f0100ff3:	89 d8                	mov    %ebx,%eax
f0100ff5:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100ffb:	c1 f8 03             	sar    $0x3,%eax
f0100ffe:	c1 e0 0c             	shl    $0xc,%eax
f0101001:	8b 55 14             	mov    0x14(%ebp),%edx
f0101004:	83 ca 01             	or     $0x1,%edx
f0101007:	09 d0                	or     %edx,%eax
f0101009:	89 06                	mov    %eax,(%esi)
    	pp->pp_ref++;  	
f010100b:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	return 0; 
f0101010:	b8 00 00 00 00       	mov    $0x0,%eax
f0101015:	eb 05                	jmp    f010101c <page_insert+0x82>
{
	// Fill this function in

	pte_t* pte = pgdir_walk(pgdir, va, 1);  
    	if(pte == NULL)  
      	  	return -E_NO_MEM;  
f0101017:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
        	page_remove(pgdir, va);  
  
    	*pte = (page2pa(pp) & ~0xfff) | perm | PTE_P;  
    	pp->pp_ref++;  	
	return 0; 
}
f010101c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010101f:	5b                   	pop    %ebx
f0101020:	5e                   	pop    %esi
f0101021:	5f                   	pop    %edi
f0101022:	5d                   	pop    %ebp
f0101023:	c3                   	ret    

f0101024 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101024:	55                   	push   %ebp
f0101025:	89 e5                	mov    %esp,%ebp
f0101027:	57                   	push   %edi
f0101028:	56                   	push   %esi
f0101029:	53                   	push   %ebx
f010102a:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010102d:	6a 15                	push   $0x15
f010102f:	e8 f4 16 00 00       	call   f0102728 <mc146818_read>
f0101034:	89 c3                	mov    %eax,%ebx
f0101036:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010103d:	e8 e6 16 00 00       	call   f0102728 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101042:	c1 e0 08             	shl    $0x8,%eax
f0101045:	09 d8                	or     %ebx,%eax
f0101047:	c1 e0 0a             	shl    $0xa,%eax
f010104a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101050:	85 c0                	test   %eax,%eax
f0101052:	0f 48 c2             	cmovs  %edx,%eax
f0101055:	c1 f8 0c             	sar    $0xc,%eax
f0101058:	a3 40 75 11 f0       	mov    %eax,0xf0117540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010105d:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101064:	e8 bf 16 00 00       	call   f0102728 <mc146818_read>
f0101069:	89 c3                	mov    %eax,%ebx
f010106b:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101072:	e8 b1 16 00 00       	call   f0102728 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101077:	c1 e0 08             	shl    $0x8,%eax
f010107a:	09 d8                	or     %ebx,%eax
f010107c:	c1 e0 0a             	shl    $0xa,%eax
f010107f:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101085:	83 c4 10             	add    $0x10,%esp
f0101088:	85 c0                	test   %eax,%eax
f010108a:	0f 48 c2             	cmovs  %edx,%eax
f010108d:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101090:	85 c0                	test   %eax,%eax
f0101092:	74 0e                	je     f01010a2 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101094:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010109a:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
f01010a0:	eb 0c                	jmp    f01010ae <mem_init+0x8a>
	else
		npages = npages_basemem;
f01010a2:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f01010a8:	89 15 64 79 11 f0    	mov    %edx,0xf0117964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010ae:	c1 e0 0c             	shl    $0xc,%eax
f01010b1:	c1 e8 0a             	shr    $0xa,%eax
f01010b4:	50                   	push   %eax
f01010b5:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f01010ba:	c1 e0 0c             	shl    $0xc,%eax
f01010bd:	c1 e8 0a             	shr    $0xa,%eax
f01010c0:	50                   	push   %eax
f01010c1:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01010c6:	c1 e0 0c             	shl    $0xc,%eax
f01010c9:	c1 e8 0a             	shr    $0xa,%eax
f01010cc:	50                   	push   %eax
f01010cd:	68 00 3d 10 f0       	push   $0xf0103d00
f01010d2:	e8 b8 16 00 00       	call   f010278f <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010d7:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010dc:	e8 5c f8 ff ff       	call   f010093d <boot_alloc>
f01010e1:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f01010e6:	83 c4 0c             	add    $0xc,%esp
f01010e9:	68 00 10 00 00       	push   $0x1000
f01010ee:	6a 00                	push   $0x0
f01010f0:	50                   	push   %eax
f01010f1:	e8 5d 21 00 00       	call   f0103253 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010f6:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010fb:	83 c4 10             	add    $0x10,%esp
f01010fe:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101103:	77 15                	ja     f010111a <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101105:	50                   	push   %eax
f0101106:	68 3c 3d 10 f0       	push   $0xf0103d3c
f010110b:	68 8d 00 00 00       	push   $0x8d
f0101110:	68 4c 43 10 f0       	push   $0xf010434c
f0101115:	e8 71 ef ff ff       	call   f010008b <_panic>
f010111a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101120:	83 ca 05             	or     $0x5,%edx
f0101123:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	

    	pages = boot_alloc(npages * sizeof (struct PageInfo));  
f0101129:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010112e:	c1 e0 03             	shl    $0x3,%eax
f0101131:	e8 07 f8 ff ff       	call   f010093d <boot_alloc>
f0101136:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
    	memset(pages, 0, npages*sizeof(struct PageInfo)); 
f010113b:	83 ec 04             	sub    $0x4,%esp
f010113e:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101144:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010114b:	52                   	push   %edx
f010114c:	6a 00                	push   $0x0
f010114e:	50                   	push   %eax
f010114f:	e8 ff 20 00 00       	call   f0103253 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101154:	e8 3f fb ff ff       	call   f0100c98 <page_init>

	check_page_free_list(1);
f0101159:	b8 01 00 00 00       	mov    $0x1,%eax
f010115e:	e8 81 f8 ff ff       	call   f01009e4 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101163:	83 c4 10             	add    $0x10,%esp
f0101166:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f010116d:	75 17                	jne    f0101186 <mem_init+0x162>
		panic("'pages' is a null pointer!");
f010116f:	83 ec 04             	sub    $0x4,%esp
f0101172:	68 19 44 10 f0       	push   $0xf0104419
f0101177:	68 6c 02 00 00       	push   $0x26c
f010117c:	68 4c 43 10 f0       	push   $0xf010434c
f0101181:	e8 05 ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101186:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010118b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101190:	eb 05                	jmp    f0101197 <mem_init+0x173>
		++nfree;
f0101192:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101195:	8b 00                	mov    (%eax),%eax
f0101197:	85 c0                	test   %eax,%eax
f0101199:	75 f7                	jne    f0101192 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010119b:	83 ec 0c             	sub    $0xc,%esp
f010119e:	6a 00                	push   $0x0
f01011a0:	e8 dc fb ff ff       	call   f0100d81 <page_alloc>
f01011a5:	89 c7                	mov    %eax,%edi
f01011a7:	83 c4 10             	add    $0x10,%esp
f01011aa:	85 c0                	test   %eax,%eax
f01011ac:	75 19                	jne    f01011c7 <mem_init+0x1a3>
f01011ae:	68 34 44 10 f0       	push   $0xf0104434
f01011b3:	68 72 43 10 f0       	push   $0xf0104372
f01011b8:	68 74 02 00 00       	push   $0x274
f01011bd:	68 4c 43 10 f0       	push   $0xf010434c
f01011c2:	e8 c4 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01011c7:	83 ec 0c             	sub    $0xc,%esp
f01011ca:	6a 00                	push   $0x0
f01011cc:	e8 b0 fb ff ff       	call   f0100d81 <page_alloc>
f01011d1:	89 c6                	mov    %eax,%esi
f01011d3:	83 c4 10             	add    $0x10,%esp
f01011d6:	85 c0                	test   %eax,%eax
f01011d8:	75 19                	jne    f01011f3 <mem_init+0x1cf>
f01011da:	68 4a 44 10 f0       	push   $0xf010444a
f01011df:	68 72 43 10 f0       	push   $0xf0104372
f01011e4:	68 75 02 00 00       	push   $0x275
f01011e9:	68 4c 43 10 f0       	push   $0xf010434c
f01011ee:	e8 98 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01011f3:	83 ec 0c             	sub    $0xc,%esp
f01011f6:	6a 00                	push   $0x0
f01011f8:	e8 84 fb ff ff       	call   f0100d81 <page_alloc>
f01011fd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101200:	83 c4 10             	add    $0x10,%esp
f0101203:	85 c0                	test   %eax,%eax
f0101205:	75 19                	jne    f0101220 <mem_init+0x1fc>
f0101207:	68 60 44 10 f0       	push   $0xf0104460
f010120c:	68 72 43 10 f0       	push   $0xf0104372
f0101211:	68 76 02 00 00       	push   $0x276
f0101216:	68 4c 43 10 f0       	push   $0xf010434c
f010121b:	e8 6b ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101220:	39 f7                	cmp    %esi,%edi
f0101222:	75 19                	jne    f010123d <mem_init+0x219>
f0101224:	68 76 44 10 f0       	push   $0xf0104476
f0101229:	68 72 43 10 f0       	push   $0xf0104372
f010122e:	68 79 02 00 00       	push   $0x279
f0101233:	68 4c 43 10 f0       	push   $0xf010434c
f0101238:	e8 4e ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010123d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101240:	39 c6                	cmp    %eax,%esi
f0101242:	74 04                	je     f0101248 <mem_init+0x224>
f0101244:	39 c7                	cmp    %eax,%edi
f0101246:	75 19                	jne    f0101261 <mem_init+0x23d>
f0101248:	68 60 3d 10 f0       	push   $0xf0103d60
f010124d:	68 72 43 10 f0       	push   $0xf0104372
f0101252:	68 7a 02 00 00       	push   $0x27a
f0101257:	68 4c 43 10 f0       	push   $0xf010434c
f010125c:	e8 2a ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101261:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101267:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f010126d:	c1 e2 0c             	shl    $0xc,%edx
f0101270:	89 f8                	mov    %edi,%eax
f0101272:	29 c8                	sub    %ecx,%eax
f0101274:	c1 f8 03             	sar    $0x3,%eax
f0101277:	c1 e0 0c             	shl    $0xc,%eax
f010127a:	39 d0                	cmp    %edx,%eax
f010127c:	72 19                	jb     f0101297 <mem_init+0x273>
f010127e:	68 88 44 10 f0       	push   $0xf0104488
f0101283:	68 72 43 10 f0       	push   $0xf0104372
f0101288:	68 7b 02 00 00       	push   $0x27b
f010128d:	68 4c 43 10 f0       	push   $0xf010434c
f0101292:	e8 f4 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101297:	89 f0                	mov    %esi,%eax
f0101299:	29 c8                	sub    %ecx,%eax
f010129b:	c1 f8 03             	sar    $0x3,%eax
f010129e:	c1 e0 0c             	shl    $0xc,%eax
f01012a1:	39 c2                	cmp    %eax,%edx
f01012a3:	77 19                	ja     f01012be <mem_init+0x29a>
f01012a5:	68 a5 44 10 f0       	push   $0xf01044a5
f01012aa:	68 72 43 10 f0       	push   $0xf0104372
f01012af:	68 7c 02 00 00       	push   $0x27c
f01012b4:	68 4c 43 10 f0       	push   $0xf010434c
f01012b9:	e8 cd ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012be:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012c1:	29 c8                	sub    %ecx,%eax
f01012c3:	c1 f8 03             	sar    $0x3,%eax
f01012c6:	c1 e0 0c             	shl    $0xc,%eax
f01012c9:	39 c2                	cmp    %eax,%edx
f01012cb:	77 19                	ja     f01012e6 <mem_init+0x2c2>
f01012cd:	68 c2 44 10 f0       	push   $0xf01044c2
f01012d2:	68 72 43 10 f0       	push   $0xf0104372
f01012d7:	68 7d 02 00 00       	push   $0x27d
f01012dc:	68 4c 43 10 f0       	push   $0xf010434c
f01012e1:	e8 a5 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012e6:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01012eb:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01012ee:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01012f5:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012f8:	83 ec 0c             	sub    $0xc,%esp
f01012fb:	6a 00                	push   $0x0
f01012fd:	e8 7f fa ff ff       	call   f0100d81 <page_alloc>
f0101302:	83 c4 10             	add    $0x10,%esp
f0101305:	85 c0                	test   %eax,%eax
f0101307:	74 19                	je     f0101322 <mem_init+0x2fe>
f0101309:	68 df 44 10 f0       	push   $0xf01044df
f010130e:	68 72 43 10 f0       	push   $0xf0104372
f0101313:	68 84 02 00 00       	push   $0x284
f0101318:	68 4c 43 10 f0       	push   $0xf010434c
f010131d:	e8 69 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101322:	83 ec 0c             	sub    $0xc,%esp
f0101325:	57                   	push   %edi
f0101326:	e8 c6 fa ff ff       	call   f0100df1 <page_free>
	page_free(pp1);
f010132b:	89 34 24             	mov    %esi,(%esp)
f010132e:	e8 be fa ff ff       	call   f0100df1 <page_free>
	page_free(pp2);
f0101333:	83 c4 04             	add    $0x4,%esp
f0101336:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101339:	e8 b3 fa ff ff       	call   f0100df1 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010133e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101345:	e8 37 fa ff ff       	call   f0100d81 <page_alloc>
f010134a:	89 c6                	mov    %eax,%esi
f010134c:	83 c4 10             	add    $0x10,%esp
f010134f:	85 c0                	test   %eax,%eax
f0101351:	75 19                	jne    f010136c <mem_init+0x348>
f0101353:	68 34 44 10 f0       	push   $0xf0104434
f0101358:	68 72 43 10 f0       	push   $0xf0104372
f010135d:	68 8b 02 00 00       	push   $0x28b
f0101362:	68 4c 43 10 f0       	push   $0xf010434c
f0101367:	e8 1f ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010136c:	83 ec 0c             	sub    $0xc,%esp
f010136f:	6a 00                	push   $0x0
f0101371:	e8 0b fa ff ff       	call   f0100d81 <page_alloc>
f0101376:	89 c7                	mov    %eax,%edi
f0101378:	83 c4 10             	add    $0x10,%esp
f010137b:	85 c0                	test   %eax,%eax
f010137d:	75 19                	jne    f0101398 <mem_init+0x374>
f010137f:	68 4a 44 10 f0       	push   $0xf010444a
f0101384:	68 72 43 10 f0       	push   $0xf0104372
f0101389:	68 8c 02 00 00       	push   $0x28c
f010138e:	68 4c 43 10 f0       	push   $0xf010434c
f0101393:	e8 f3 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101398:	83 ec 0c             	sub    $0xc,%esp
f010139b:	6a 00                	push   $0x0
f010139d:	e8 df f9 ff ff       	call   f0100d81 <page_alloc>
f01013a2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013a5:	83 c4 10             	add    $0x10,%esp
f01013a8:	85 c0                	test   %eax,%eax
f01013aa:	75 19                	jne    f01013c5 <mem_init+0x3a1>
f01013ac:	68 60 44 10 f0       	push   $0xf0104460
f01013b1:	68 72 43 10 f0       	push   $0xf0104372
f01013b6:	68 8d 02 00 00       	push   $0x28d
f01013bb:	68 4c 43 10 f0       	push   $0xf010434c
f01013c0:	e8 c6 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013c5:	39 fe                	cmp    %edi,%esi
f01013c7:	75 19                	jne    f01013e2 <mem_init+0x3be>
f01013c9:	68 76 44 10 f0       	push   $0xf0104476
f01013ce:	68 72 43 10 f0       	push   $0xf0104372
f01013d3:	68 8f 02 00 00       	push   $0x28f
f01013d8:	68 4c 43 10 f0       	push   $0xf010434c
f01013dd:	e8 a9 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013e2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013e5:	39 c7                	cmp    %eax,%edi
f01013e7:	74 04                	je     f01013ed <mem_init+0x3c9>
f01013e9:	39 c6                	cmp    %eax,%esi
f01013eb:	75 19                	jne    f0101406 <mem_init+0x3e2>
f01013ed:	68 60 3d 10 f0       	push   $0xf0103d60
f01013f2:	68 72 43 10 f0       	push   $0xf0104372
f01013f7:	68 90 02 00 00       	push   $0x290
f01013fc:	68 4c 43 10 f0       	push   $0xf010434c
f0101401:	e8 85 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101406:	83 ec 0c             	sub    $0xc,%esp
f0101409:	6a 00                	push   $0x0
f010140b:	e8 71 f9 ff ff       	call   f0100d81 <page_alloc>
f0101410:	83 c4 10             	add    $0x10,%esp
f0101413:	85 c0                	test   %eax,%eax
f0101415:	74 19                	je     f0101430 <mem_init+0x40c>
f0101417:	68 df 44 10 f0       	push   $0xf01044df
f010141c:	68 72 43 10 f0       	push   $0xf0104372
f0101421:	68 91 02 00 00       	push   $0x291
f0101426:	68 4c 43 10 f0       	push   $0xf010434c
f010142b:	e8 5b ec ff ff       	call   f010008b <_panic>
f0101430:	89 f0                	mov    %esi,%eax
f0101432:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101438:	c1 f8 03             	sar    $0x3,%eax
f010143b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010143e:	89 c2                	mov    %eax,%edx
f0101440:	c1 ea 0c             	shr    $0xc,%edx
f0101443:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101449:	72 12                	jb     f010145d <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010144b:	50                   	push   %eax
f010144c:	68 f8 3b 10 f0       	push   $0xf0103bf8
f0101451:	6a 52                	push   $0x52
f0101453:	68 58 43 10 f0       	push   $0xf0104358
f0101458:	e8 2e ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010145d:	83 ec 04             	sub    $0x4,%esp
f0101460:	68 00 10 00 00       	push   $0x1000
f0101465:	6a 01                	push   $0x1
f0101467:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010146c:	50                   	push   %eax
f010146d:	e8 e1 1d 00 00       	call   f0103253 <memset>
	page_free(pp0);
f0101472:	89 34 24             	mov    %esi,(%esp)
f0101475:	e8 77 f9 ff ff       	call   f0100df1 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010147a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101481:	e8 fb f8 ff ff       	call   f0100d81 <page_alloc>
f0101486:	83 c4 10             	add    $0x10,%esp
f0101489:	85 c0                	test   %eax,%eax
f010148b:	75 19                	jne    f01014a6 <mem_init+0x482>
f010148d:	68 ee 44 10 f0       	push   $0xf01044ee
f0101492:	68 72 43 10 f0       	push   $0xf0104372
f0101497:	68 96 02 00 00       	push   $0x296
f010149c:	68 4c 43 10 f0       	push   $0xf010434c
f01014a1:	e8 e5 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01014a6:	39 c6                	cmp    %eax,%esi
f01014a8:	74 19                	je     f01014c3 <mem_init+0x49f>
f01014aa:	68 0c 45 10 f0       	push   $0xf010450c
f01014af:	68 72 43 10 f0       	push   $0xf0104372
f01014b4:	68 97 02 00 00       	push   $0x297
f01014b9:	68 4c 43 10 f0       	push   $0xf010434c
f01014be:	e8 c8 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014c3:	89 f0                	mov    %esi,%eax
f01014c5:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01014cb:	c1 f8 03             	sar    $0x3,%eax
f01014ce:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014d1:	89 c2                	mov    %eax,%edx
f01014d3:	c1 ea 0c             	shr    $0xc,%edx
f01014d6:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01014dc:	72 12                	jb     f01014f0 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014de:	50                   	push   %eax
f01014df:	68 f8 3b 10 f0       	push   $0xf0103bf8
f01014e4:	6a 52                	push   $0x52
f01014e6:	68 58 43 10 f0       	push   $0xf0104358
f01014eb:	e8 9b eb ff ff       	call   f010008b <_panic>
f01014f0:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01014f6:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014fc:	80 38 00             	cmpb   $0x0,(%eax)
f01014ff:	74 19                	je     f010151a <mem_init+0x4f6>
f0101501:	68 1c 45 10 f0       	push   $0xf010451c
f0101506:	68 72 43 10 f0       	push   $0xf0104372
f010150b:	68 9a 02 00 00       	push   $0x29a
f0101510:	68 4c 43 10 f0       	push   $0xf010434c
f0101515:	e8 71 eb ff ff       	call   f010008b <_panic>
f010151a:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010151d:	39 d0                	cmp    %edx,%eax
f010151f:	75 db                	jne    f01014fc <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101521:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101524:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101529:	83 ec 0c             	sub    $0xc,%esp
f010152c:	56                   	push   %esi
f010152d:	e8 bf f8 ff ff       	call   f0100df1 <page_free>
	page_free(pp1);
f0101532:	89 3c 24             	mov    %edi,(%esp)
f0101535:	e8 b7 f8 ff ff       	call   f0100df1 <page_free>
	page_free(pp2);
f010153a:	83 c4 04             	add    $0x4,%esp
f010153d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101540:	e8 ac f8 ff ff       	call   f0100df1 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101545:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010154a:	83 c4 10             	add    $0x10,%esp
f010154d:	eb 05                	jmp    f0101554 <mem_init+0x530>
		--nfree;
f010154f:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101552:	8b 00                	mov    (%eax),%eax
f0101554:	85 c0                	test   %eax,%eax
f0101556:	75 f7                	jne    f010154f <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f0101558:	85 db                	test   %ebx,%ebx
f010155a:	74 19                	je     f0101575 <mem_init+0x551>
f010155c:	68 26 45 10 f0       	push   $0xf0104526
f0101561:	68 72 43 10 f0       	push   $0xf0104372
f0101566:	68 a7 02 00 00       	push   $0x2a7
f010156b:	68 4c 43 10 f0       	push   $0xf010434c
f0101570:	e8 16 eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101575:	83 ec 0c             	sub    $0xc,%esp
f0101578:	68 80 3d 10 f0       	push   $0xf0103d80
f010157d:	e8 0d 12 00 00       	call   f010278f <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101582:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101589:	e8 f3 f7 ff ff       	call   f0100d81 <page_alloc>
f010158e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101591:	83 c4 10             	add    $0x10,%esp
f0101594:	85 c0                	test   %eax,%eax
f0101596:	75 19                	jne    f01015b1 <mem_init+0x58d>
f0101598:	68 34 44 10 f0       	push   $0xf0104434
f010159d:	68 72 43 10 f0       	push   $0xf0104372
f01015a2:	68 00 03 00 00       	push   $0x300
f01015a7:	68 4c 43 10 f0       	push   $0xf010434c
f01015ac:	e8 da ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01015b1:	83 ec 0c             	sub    $0xc,%esp
f01015b4:	6a 00                	push   $0x0
f01015b6:	e8 c6 f7 ff ff       	call   f0100d81 <page_alloc>
f01015bb:	89 c3                	mov    %eax,%ebx
f01015bd:	83 c4 10             	add    $0x10,%esp
f01015c0:	85 c0                	test   %eax,%eax
f01015c2:	75 19                	jne    f01015dd <mem_init+0x5b9>
f01015c4:	68 4a 44 10 f0       	push   $0xf010444a
f01015c9:	68 72 43 10 f0       	push   $0xf0104372
f01015ce:	68 01 03 00 00       	push   $0x301
f01015d3:	68 4c 43 10 f0       	push   $0xf010434c
f01015d8:	e8 ae ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01015dd:	83 ec 0c             	sub    $0xc,%esp
f01015e0:	6a 00                	push   $0x0
f01015e2:	e8 9a f7 ff ff       	call   f0100d81 <page_alloc>
f01015e7:	89 c6                	mov    %eax,%esi
f01015e9:	83 c4 10             	add    $0x10,%esp
f01015ec:	85 c0                	test   %eax,%eax
f01015ee:	75 19                	jne    f0101609 <mem_init+0x5e5>
f01015f0:	68 60 44 10 f0       	push   $0xf0104460
f01015f5:	68 72 43 10 f0       	push   $0xf0104372
f01015fa:	68 02 03 00 00       	push   $0x302
f01015ff:	68 4c 43 10 f0       	push   $0xf010434c
f0101604:	e8 82 ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101609:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010160c:	75 19                	jne    f0101627 <mem_init+0x603>
f010160e:	68 76 44 10 f0       	push   $0xf0104476
f0101613:	68 72 43 10 f0       	push   $0xf0104372
f0101618:	68 05 03 00 00       	push   $0x305
f010161d:	68 4c 43 10 f0       	push   $0xf010434c
f0101622:	e8 64 ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101627:	39 c3                	cmp    %eax,%ebx
f0101629:	74 05                	je     f0101630 <mem_init+0x60c>
f010162b:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010162e:	75 19                	jne    f0101649 <mem_init+0x625>
f0101630:	68 60 3d 10 f0       	push   $0xf0103d60
f0101635:	68 72 43 10 f0       	push   $0xf0104372
f010163a:	68 06 03 00 00       	push   $0x306
f010163f:	68 4c 43 10 f0       	push   $0xf010434c
f0101644:	e8 42 ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101649:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010164e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101651:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101658:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010165b:	83 ec 0c             	sub    $0xc,%esp
f010165e:	6a 00                	push   $0x0
f0101660:	e8 1c f7 ff ff       	call   f0100d81 <page_alloc>
f0101665:	83 c4 10             	add    $0x10,%esp
f0101668:	85 c0                	test   %eax,%eax
f010166a:	74 19                	je     f0101685 <mem_init+0x661>
f010166c:	68 df 44 10 f0       	push   $0xf01044df
f0101671:	68 72 43 10 f0       	push   $0xf0104372
f0101676:	68 0d 03 00 00       	push   $0x30d
f010167b:	68 4c 43 10 f0       	push   $0xf010434c
f0101680:	e8 06 ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101685:	83 ec 04             	sub    $0x4,%esp
f0101688:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010168b:	50                   	push   %eax
f010168c:	6a 00                	push   $0x0
f010168e:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101694:	e8 54 f8 ff ff       	call   f0100eed <page_lookup>
f0101699:	83 c4 10             	add    $0x10,%esp
f010169c:	85 c0                	test   %eax,%eax
f010169e:	74 19                	je     f01016b9 <mem_init+0x695>
f01016a0:	68 a0 3d 10 f0       	push   $0xf0103da0
f01016a5:	68 72 43 10 f0       	push   $0xf0104372
f01016aa:	68 10 03 00 00       	push   $0x310
f01016af:	68 4c 43 10 f0       	push   $0xf010434c
f01016b4:	e8 d2 e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016b9:	6a 02                	push   $0x2
f01016bb:	6a 00                	push   $0x0
f01016bd:	53                   	push   %ebx
f01016be:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01016c4:	e8 d1 f8 ff ff       	call   f0100f9a <page_insert>
f01016c9:	83 c4 10             	add    $0x10,%esp
f01016cc:	85 c0                	test   %eax,%eax
f01016ce:	78 19                	js     f01016e9 <mem_init+0x6c5>
f01016d0:	68 d8 3d 10 f0       	push   $0xf0103dd8
f01016d5:	68 72 43 10 f0       	push   $0xf0104372
f01016da:	68 13 03 00 00       	push   $0x313
f01016df:	68 4c 43 10 f0       	push   $0xf010434c
f01016e4:	e8 a2 e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016e9:	83 ec 0c             	sub    $0xc,%esp
f01016ec:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016ef:	e8 fd f6 ff ff       	call   f0100df1 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01016f4:	6a 02                	push   $0x2
f01016f6:	6a 00                	push   $0x0
f01016f8:	53                   	push   %ebx
f01016f9:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01016ff:	e8 96 f8 ff ff       	call   f0100f9a <page_insert>
f0101704:	83 c4 20             	add    $0x20,%esp
f0101707:	85 c0                	test   %eax,%eax
f0101709:	74 19                	je     f0101724 <mem_init+0x700>
f010170b:	68 08 3e 10 f0       	push   $0xf0103e08
f0101710:	68 72 43 10 f0       	push   $0xf0104372
f0101715:	68 17 03 00 00       	push   $0x317
f010171a:	68 4c 43 10 f0       	push   $0xf010434c
f010171f:	e8 67 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101724:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010172a:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f010172f:	89 c1                	mov    %eax,%ecx
f0101731:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101734:	8b 17                	mov    (%edi),%edx
f0101736:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010173c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010173f:	29 c8                	sub    %ecx,%eax
f0101741:	c1 f8 03             	sar    $0x3,%eax
f0101744:	c1 e0 0c             	shl    $0xc,%eax
f0101747:	39 c2                	cmp    %eax,%edx
f0101749:	74 19                	je     f0101764 <mem_init+0x740>
f010174b:	68 38 3e 10 f0       	push   $0xf0103e38
f0101750:	68 72 43 10 f0       	push   $0xf0104372
f0101755:	68 18 03 00 00       	push   $0x318
f010175a:	68 4c 43 10 f0       	push   $0xf010434c
f010175f:	e8 27 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101764:	ba 00 00 00 00       	mov    $0x0,%edx
f0101769:	89 f8                	mov    %edi,%eax
f010176b:	e8 10 f2 ff ff       	call   f0100980 <check_va2pa>
f0101770:	89 da                	mov    %ebx,%edx
f0101772:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101775:	c1 fa 03             	sar    $0x3,%edx
f0101778:	c1 e2 0c             	shl    $0xc,%edx
f010177b:	39 d0                	cmp    %edx,%eax
f010177d:	74 19                	je     f0101798 <mem_init+0x774>
f010177f:	68 60 3e 10 f0       	push   $0xf0103e60
f0101784:	68 72 43 10 f0       	push   $0xf0104372
f0101789:	68 19 03 00 00       	push   $0x319
f010178e:	68 4c 43 10 f0       	push   $0xf010434c
f0101793:	e8 f3 e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101798:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010179d:	74 19                	je     f01017b8 <mem_init+0x794>
f010179f:	68 31 45 10 f0       	push   $0xf0104531
f01017a4:	68 72 43 10 f0       	push   $0xf0104372
f01017a9:	68 1a 03 00 00       	push   $0x31a
f01017ae:	68 4c 43 10 f0       	push   $0xf010434c
f01017b3:	e8 d3 e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01017b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017bb:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017c0:	74 19                	je     f01017db <mem_init+0x7b7>
f01017c2:	68 42 45 10 f0       	push   $0xf0104542
f01017c7:	68 72 43 10 f0       	push   $0xf0104372
f01017cc:	68 1b 03 00 00       	push   $0x31b
f01017d1:	68 4c 43 10 f0       	push   $0xf010434c
f01017d6:	e8 b0 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017db:	6a 02                	push   $0x2
f01017dd:	68 00 10 00 00       	push   $0x1000
f01017e2:	56                   	push   %esi
f01017e3:	57                   	push   %edi
f01017e4:	e8 b1 f7 ff ff       	call   f0100f9a <page_insert>
f01017e9:	83 c4 10             	add    $0x10,%esp
f01017ec:	85 c0                	test   %eax,%eax
f01017ee:	74 19                	je     f0101809 <mem_init+0x7e5>
f01017f0:	68 90 3e 10 f0       	push   $0xf0103e90
f01017f5:	68 72 43 10 f0       	push   $0xf0104372
f01017fa:	68 1e 03 00 00       	push   $0x31e
f01017ff:	68 4c 43 10 f0       	push   $0xf010434c
f0101804:	e8 82 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101809:	ba 00 10 00 00       	mov    $0x1000,%edx
f010180e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101813:	e8 68 f1 ff ff       	call   f0100980 <check_va2pa>
f0101818:	89 f2                	mov    %esi,%edx
f010181a:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101820:	c1 fa 03             	sar    $0x3,%edx
f0101823:	c1 e2 0c             	shl    $0xc,%edx
f0101826:	39 d0                	cmp    %edx,%eax
f0101828:	74 19                	je     f0101843 <mem_init+0x81f>
f010182a:	68 cc 3e 10 f0       	push   $0xf0103ecc
f010182f:	68 72 43 10 f0       	push   $0xf0104372
f0101834:	68 1f 03 00 00       	push   $0x31f
f0101839:	68 4c 43 10 f0       	push   $0xf010434c
f010183e:	e8 48 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101843:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101848:	74 19                	je     f0101863 <mem_init+0x83f>
f010184a:	68 53 45 10 f0       	push   $0xf0104553
f010184f:	68 72 43 10 f0       	push   $0xf0104372
f0101854:	68 20 03 00 00       	push   $0x320
f0101859:	68 4c 43 10 f0       	push   $0xf010434c
f010185e:	e8 28 e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101863:	83 ec 0c             	sub    $0xc,%esp
f0101866:	6a 00                	push   $0x0
f0101868:	e8 14 f5 ff ff       	call   f0100d81 <page_alloc>
f010186d:	83 c4 10             	add    $0x10,%esp
f0101870:	85 c0                	test   %eax,%eax
f0101872:	74 19                	je     f010188d <mem_init+0x869>
f0101874:	68 df 44 10 f0       	push   $0xf01044df
f0101879:	68 72 43 10 f0       	push   $0xf0104372
f010187e:	68 23 03 00 00       	push   $0x323
f0101883:	68 4c 43 10 f0       	push   $0xf010434c
f0101888:	e8 fe e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010188d:	6a 02                	push   $0x2
f010188f:	68 00 10 00 00       	push   $0x1000
f0101894:	56                   	push   %esi
f0101895:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010189b:	e8 fa f6 ff ff       	call   f0100f9a <page_insert>
f01018a0:	83 c4 10             	add    $0x10,%esp
f01018a3:	85 c0                	test   %eax,%eax
f01018a5:	74 19                	je     f01018c0 <mem_init+0x89c>
f01018a7:	68 90 3e 10 f0       	push   $0xf0103e90
f01018ac:	68 72 43 10 f0       	push   $0xf0104372
f01018b1:	68 26 03 00 00       	push   $0x326
f01018b6:	68 4c 43 10 f0       	push   $0xf010434c
f01018bb:	e8 cb e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018c0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018c5:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01018ca:	e8 b1 f0 ff ff       	call   f0100980 <check_va2pa>
f01018cf:	89 f2                	mov    %esi,%edx
f01018d1:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01018d7:	c1 fa 03             	sar    $0x3,%edx
f01018da:	c1 e2 0c             	shl    $0xc,%edx
f01018dd:	39 d0                	cmp    %edx,%eax
f01018df:	74 19                	je     f01018fa <mem_init+0x8d6>
f01018e1:	68 cc 3e 10 f0       	push   $0xf0103ecc
f01018e6:	68 72 43 10 f0       	push   $0xf0104372
f01018eb:	68 27 03 00 00       	push   $0x327
f01018f0:	68 4c 43 10 f0       	push   $0xf010434c
f01018f5:	e8 91 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018fa:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018ff:	74 19                	je     f010191a <mem_init+0x8f6>
f0101901:	68 53 45 10 f0       	push   $0xf0104553
f0101906:	68 72 43 10 f0       	push   $0xf0104372
f010190b:	68 28 03 00 00       	push   $0x328
f0101910:	68 4c 43 10 f0       	push   $0xf010434c
f0101915:	e8 71 e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010191a:	83 ec 0c             	sub    $0xc,%esp
f010191d:	6a 00                	push   $0x0
f010191f:	e8 5d f4 ff ff       	call   f0100d81 <page_alloc>
f0101924:	83 c4 10             	add    $0x10,%esp
f0101927:	85 c0                	test   %eax,%eax
f0101929:	74 19                	je     f0101944 <mem_init+0x920>
f010192b:	68 df 44 10 f0       	push   $0xf01044df
f0101930:	68 72 43 10 f0       	push   $0xf0104372
f0101935:	68 2c 03 00 00       	push   $0x32c
f010193a:	68 4c 43 10 f0       	push   $0xf010434c
f010193f:	e8 47 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101944:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f010194a:	8b 02                	mov    (%edx),%eax
f010194c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101951:	89 c1                	mov    %eax,%ecx
f0101953:	c1 e9 0c             	shr    $0xc,%ecx
f0101956:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f010195c:	72 15                	jb     f0101973 <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010195e:	50                   	push   %eax
f010195f:	68 f8 3b 10 f0       	push   $0xf0103bf8
f0101964:	68 2f 03 00 00       	push   $0x32f
f0101969:	68 4c 43 10 f0       	push   $0xf010434c
f010196e:	e8 18 e7 ff ff       	call   f010008b <_panic>
f0101973:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101978:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010197b:	83 ec 04             	sub    $0x4,%esp
f010197e:	6a 00                	push   $0x0
f0101980:	68 00 10 00 00       	push   $0x1000
f0101985:	52                   	push   %edx
f0101986:	e8 c8 f4 ff ff       	call   f0100e53 <pgdir_walk>
f010198b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010198e:	8d 57 04             	lea    0x4(%edi),%edx
f0101991:	83 c4 10             	add    $0x10,%esp
f0101994:	39 d0                	cmp    %edx,%eax
f0101996:	74 19                	je     f01019b1 <mem_init+0x98d>
f0101998:	68 fc 3e 10 f0       	push   $0xf0103efc
f010199d:	68 72 43 10 f0       	push   $0xf0104372
f01019a2:	68 30 03 00 00       	push   $0x330
f01019a7:	68 4c 43 10 f0       	push   $0xf010434c
f01019ac:	e8 da e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019b1:	6a 06                	push   $0x6
f01019b3:	68 00 10 00 00       	push   $0x1000
f01019b8:	56                   	push   %esi
f01019b9:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01019bf:	e8 d6 f5 ff ff       	call   f0100f9a <page_insert>
f01019c4:	83 c4 10             	add    $0x10,%esp
f01019c7:	85 c0                	test   %eax,%eax
f01019c9:	74 19                	je     f01019e4 <mem_init+0x9c0>
f01019cb:	68 3c 3f 10 f0       	push   $0xf0103f3c
f01019d0:	68 72 43 10 f0       	push   $0xf0104372
f01019d5:	68 33 03 00 00       	push   $0x333
f01019da:	68 4c 43 10 f0       	push   $0xf010434c
f01019df:	e8 a7 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019e4:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f01019ea:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019ef:	89 f8                	mov    %edi,%eax
f01019f1:	e8 8a ef ff ff       	call   f0100980 <check_va2pa>
f01019f6:	89 f2                	mov    %esi,%edx
f01019f8:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01019fe:	c1 fa 03             	sar    $0x3,%edx
f0101a01:	c1 e2 0c             	shl    $0xc,%edx
f0101a04:	39 d0                	cmp    %edx,%eax
f0101a06:	74 19                	je     f0101a21 <mem_init+0x9fd>
f0101a08:	68 cc 3e 10 f0       	push   $0xf0103ecc
f0101a0d:	68 72 43 10 f0       	push   $0xf0104372
f0101a12:	68 34 03 00 00       	push   $0x334
f0101a17:	68 4c 43 10 f0       	push   $0xf010434c
f0101a1c:	e8 6a e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a21:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a26:	74 19                	je     f0101a41 <mem_init+0xa1d>
f0101a28:	68 53 45 10 f0       	push   $0xf0104553
f0101a2d:	68 72 43 10 f0       	push   $0xf0104372
f0101a32:	68 35 03 00 00       	push   $0x335
f0101a37:	68 4c 43 10 f0       	push   $0xf010434c
f0101a3c:	e8 4a e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a41:	83 ec 04             	sub    $0x4,%esp
f0101a44:	6a 00                	push   $0x0
f0101a46:	68 00 10 00 00       	push   $0x1000
f0101a4b:	57                   	push   %edi
f0101a4c:	e8 02 f4 ff ff       	call   f0100e53 <pgdir_walk>
f0101a51:	83 c4 10             	add    $0x10,%esp
f0101a54:	f6 00 04             	testb  $0x4,(%eax)
f0101a57:	75 19                	jne    f0101a72 <mem_init+0xa4e>
f0101a59:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0101a5e:	68 72 43 10 f0       	push   $0xf0104372
f0101a63:	68 36 03 00 00       	push   $0x336
f0101a68:	68 4c 43 10 f0       	push   $0xf010434c
f0101a6d:	e8 19 e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a72:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101a77:	f6 00 04             	testb  $0x4,(%eax)
f0101a7a:	75 19                	jne    f0101a95 <mem_init+0xa71>
f0101a7c:	68 64 45 10 f0       	push   $0xf0104564
f0101a81:	68 72 43 10 f0       	push   $0xf0104372
f0101a86:	68 37 03 00 00       	push   $0x337
f0101a8b:	68 4c 43 10 f0       	push   $0xf010434c
f0101a90:	e8 f6 e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a95:	6a 02                	push   $0x2
f0101a97:	68 00 10 00 00       	push   $0x1000
f0101a9c:	56                   	push   %esi
f0101a9d:	50                   	push   %eax
f0101a9e:	e8 f7 f4 ff ff       	call   f0100f9a <page_insert>
f0101aa3:	83 c4 10             	add    $0x10,%esp
f0101aa6:	85 c0                	test   %eax,%eax
f0101aa8:	74 19                	je     f0101ac3 <mem_init+0xa9f>
f0101aaa:	68 90 3e 10 f0       	push   $0xf0103e90
f0101aaf:	68 72 43 10 f0       	push   $0xf0104372
f0101ab4:	68 3a 03 00 00       	push   $0x33a
f0101ab9:	68 4c 43 10 f0       	push   $0xf010434c
f0101abe:	e8 c8 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ac3:	83 ec 04             	sub    $0x4,%esp
f0101ac6:	6a 00                	push   $0x0
f0101ac8:	68 00 10 00 00       	push   $0x1000
f0101acd:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101ad3:	e8 7b f3 ff ff       	call   f0100e53 <pgdir_walk>
f0101ad8:	83 c4 10             	add    $0x10,%esp
f0101adb:	f6 00 02             	testb  $0x2,(%eax)
f0101ade:	75 19                	jne    f0101af9 <mem_init+0xad5>
f0101ae0:	68 b0 3f 10 f0       	push   $0xf0103fb0
f0101ae5:	68 72 43 10 f0       	push   $0xf0104372
f0101aea:	68 3b 03 00 00       	push   $0x33b
f0101aef:	68 4c 43 10 f0       	push   $0xf010434c
f0101af4:	e8 92 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101af9:	83 ec 04             	sub    $0x4,%esp
f0101afc:	6a 00                	push   $0x0
f0101afe:	68 00 10 00 00       	push   $0x1000
f0101b03:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b09:	e8 45 f3 ff ff       	call   f0100e53 <pgdir_walk>
f0101b0e:	83 c4 10             	add    $0x10,%esp
f0101b11:	f6 00 04             	testb  $0x4,(%eax)
f0101b14:	74 19                	je     f0101b2f <mem_init+0xb0b>
f0101b16:	68 e4 3f 10 f0       	push   $0xf0103fe4
f0101b1b:	68 72 43 10 f0       	push   $0xf0104372
f0101b20:	68 3c 03 00 00       	push   $0x33c
f0101b25:	68 4c 43 10 f0       	push   $0xf010434c
f0101b2a:	e8 5c e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b2f:	6a 02                	push   $0x2
f0101b31:	68 00 00 40 00       	push   $0x400000
f0101b36:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b39:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b3f:	e8 56 f4 ff ff       	call   f0100f9a <page_insert>
f0101b44:	83 c4 10             	add    $0x10,%esp
f0101b47:	85 c0                	test   %eax,%eax
f0101b49:	78 19                	js     f0101b64 <mem_init+0xb40>
f0101b4b:	68 1c 40 10 f0       	push   $0xf010401c
f0101b50:	68 72 43 10 f0       	push   $0xf0104372
f0101b55:	68 3f 03 00 00       	push   $0x33f
f0101b5a:	68 4c 43 10 f0       	push   $0xf010434c
f0101b5f:	e8 27 e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b64:	6a 02                	push   $0x2
f0101b66:	68 00 10 00 00       	push   $0x1000
f0101b6b:	53                   	push   %ebx
f0101b6c:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b72:	e8 23 f4 ff ff       	call   f0100f9a <page_insert>
f0101b77:	83 c4 10             	add    $0x10,%esp
f0101b7a:	85 c0                	test   %eax,%eax
f0101b7c:	74 19                	je     f0101b97 <mem_init+0xb73>
f0101b7e:	68 54 40 10 f0       	push   $0xf0104054
f0101b83:	68 72 43 10 f0       	push   $0xf0104372
f0101b88:	68 42 03 00 00       	push   $0x342
f0101b8d:	68 4c 43 10 f0       	push   $0xf010434c
f0101b92:	e8 f4 e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b97:	83 ec 04             	sub    $0x4,%esp
f0101b9a:	6a 00                	push   $0x0
f0101b9c:	68 00 10 00 00       	push   $0x1000
f0101ba1:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101ba7:	e8 a7 f2 ff ff       	call   f0100e53 <pgdir_walk>
f0101bac:	83 c4 10             	add    $0x10,%esp
f0101baf:	f6 00 04             	testb  $0x4,(%eax)
f0101bb2:	74 19                	je     f0101bcd <mem_init+0xba9>
f0101bb4:	68 e4 3f 10 f0       	push   $0xf0103fe4
f0101bb9:	68 72 43 10 f0       	push   $0xf0104372
f0101bbe:	68 43 03 00 00       	push   $0x343
f0101bc3:	68 4c 43 10 f0       	push   $0xf010434c
f0101bc8:	e8 be e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101bcd:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101bd3:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bd8:	89 f8                	mov    %edi,%eax
f0101bda:	e8 a1 ed ff ff       	call   f0100980 <check_va2pa>
f0101bdf:	89 c1                	mov    %eax,%ecx
f0101be1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101be4:	89 d8                	mov    %ebx,%eax
f0101be6:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101bec:	c1 f8 03             	sar    $0x3,%eax
f0101bef:	c1 e0 0c             	shl    $0xc,%eax
f0101bf2:	39 c1                	cmp    %eax,%ecx
f0101bf4:	74 19                	je     f0101c0f <mem_init+0xbeb>
f0101bf6:	68 90 40 10 f0       	push   $0xf0104090
f0101bfb:	68 72 43 10 f0       	push   $0xf0104372
f0101c00:	68 46 03 00 00       	push   $0x346
f0101c05:	68 4c 43 10 f0       	push   $0xf010434c
f0101c0a:	e8 7c e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c0f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c14:	89 f8                	mov    %edi,%eax
f0101c16:	e8 65 ed ff ff       	call   f0100980 <check_va2pa>
f0101c1b:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c1e:	74 19                	je     f0101c39 <mem_init+0xc15>
f0101c20:	68 bc 40 10 f0       	push   $0xf01040bc
f0101c25:	68 72 43 10 f0       	push   $0xf0104372
f0101c2a:	68 47 03 00 00       	push   $0x347
f0101c2f:	68 4c 43 10 f0       	push   $0xf010434c
f0101c34:	e8 52 e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c39:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c3e:	74 19                	je     f0101c59 <mem_init+0xc35>
f0101c40:	68 7a 45 10 f0       	push   $0xf010457a
f0101c45:	68 72 43 10 f0       	push   $0xf0104372
f0101c4a:	68 49 03 00 00       	push   $0x349
f0101c4f:	68 4c 43 10 f0       	push   $0xf010434c
f0101c54:	e8 32 e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c59:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c5e:	74 19                	je     f0101c79 <mem_init+0xc55>
f0101c60:	68 8b 45 10 f0       	push   $0xf010458b
f0101c65:	68 72 43 10 f0       	push   $0xf0104372
f0101c6a:	68 4a 03 00 00       	push   $0x34a
f0101c6f:	68 4c 43 10 f0       	push   $0xf010434c
f0101c74:	e8 12 e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c79:	83 ec 0c             	sub    $0xc,%esp
f0101c7c:	6a 00                	push   $0x0
f0101c7e:	e8 fe f0 ff ff       	call   f0100d81 <page_alloc>
f0101c83:	83 c4 10             	add    $0x10,%esp
f0101c86:	39 c6                	cmp    %eax,%esi
f0101c88:	75 04                	jne    f0101c8e <mem_init+0xc6a>
f0101c8a:	85 c0                	test   %eax,%eax
f0101c8c:	75 19                	jne    f0101ca7 <mem_init+0xc83>
f0101c8e:	68 ec 40 10 f0       	push   $0xf01040ec
f0101c93:	68 72 43 10 f0       	push   $0xf0104372
f0101c98:	68 4d 03 00 00       	push   $0x34d
f0101c9d:	68 4c 43 10 f0       	push   $0xf010434c
f0101ca2:	e8 e4 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ca7:	83 ec 08             	sub    $0x8,%esp
f0101caa:	6a 00                	push   $0x0
f0101cac:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101cb2:	e8 98 f2 ff ff       	call   f0100f4f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cb7:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101cbd:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cc2:	89 f8                	mov    %edi,%eax
f0101cc4:	e8 b7 ec ff ff       	call   f0100980 <check_va2pa>
f0101cc9:	83 c4 10             	add    $0x10,%esp
f0101ccc:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ccf:	74 19                	je     f0101cea <mem_init+0xcc6>
f0101cd1:	68 10 41 10 f0       	push   $0xf0104110
f0101cd6:	68 72 43 10 f0       	push   $0xf0104372
f0101cdb:	68 51 03 00 00       	push   $0x351
f0101ce0:	68 4c 43 10 f0       	push   $0xf010434c
f0101ce5:	e8 a1 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cea:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cef:	89 f8                	mov    %edi,%eax
f0101cf1:	e8 8a ec ff ff       	call   f0100980 <check_va2pa>
f0101cf6:	89 da                	mov    %ebx,%edx
f0101cf8:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101cfe:	c1 fa 03             	sar    $0x3,%edx
f0101d01:	c1 e2 0c             	shl    $0xc,%edx
f0101d04:	39 d0                	cmp    %edx,%eax
f0101d06:	74 19                	je     f0101d21 <mem_init+0xcfd>
f0101d08:	68 bc 40 10 f0       	push   $0xf01040bc
f0101d0d:	68 72 43 10 f0       	push   $0xf0104372
f0101d12:	68 52 03 00 00       	push   $0x352
f0101d17:	68 4c 43 10 f0       	push   $0xf010434c
f0101d1c:	e8 6a e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d21:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d26:	74 19                	je     f0101d41 <mem_init+0xd1d>
f0101d28:	68 31 45 10 f0       	push   $0xf0104531
f0101d2d:	68 72 43 10 f0       	push   $0xf0104372
f0101d32:	68 53 03 00 00       	push   $0x353
f0101d37:	68 4c 43 10 f0       	push   $0xf010434c
f0101d3c:	e8 4a e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d41:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d46:	74 19                	je     f0101d61 <mem_init+0xd3d>
f0101d48:	68 8b 45 10 f0       	push   $0xf010458b
f0101d4d:	68 72 43 10 f0       	push   $0xf0104372
f0101d52:	68 54 03 00 00       	push   $0x354
f0101d57:	68 4c 43 10 f0       	push   $0xf010434c
f0101d5c:	e8 2a e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d61:	6a 00                	push   $0x0
f0101d63:	68 00 10 00 00       	push   $0x1000
f0101d68:	53                   	push   %ebx
f0101d69:	57                   	push   %edi
f0101d6a:	e8 2b f2 ff ff       	call   f0100f9a <page_insert>
f0101d6f:	83 c4 10             	add    $0x10,%esp
f0101d72:	85 c0                	test   %eax,%eax
f0101d74:	74 19                	je     f0101d8f <mem_init+0xd6b>
f0101d76:	68 34 41 10 f0       	push   $0xf0104134
f0101d7b:	68 72 43 10 f0       	push   $0xf0104372
f0101d80:	68 57 03 00 00       	push   $0x357
f0101d85:	68 4c 43 10 f0       	push   $0xf010434c
f0101d8a:	e8 fc e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101d8f:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d94:	75 19                	jne    f0101daf <mem_init+0xd8b>
f0101d96:	68 9c 45 10 f0       	push   $0xf010459c
f0101d9b:	68 72 43 10 f0       	push   $0xf0104372
f0101da0:	68 58 03 00 00       	push   $0x358
f0101da5:	68 4c 43 10 f0       	push   $0xf010434c
f0101daa:	e8 dc e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101daf:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101db2:	74 19                	je     f0101dcd <mem_init+0xda9>
f0101db4:	68 a8 45 10 f0       	push   $0xf01045a8
f0101db9:	68 72 43 10 f0       	push   $0xf0104372
f0101dbe:	68 59 03 00 00       	push   $0x359
f0101dc3:	68 4c 43 10 f0       	push   $0xf010434c
f0101dc8:	e8 be e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101dcd:	83 ec 08             	sub    $0x8,%esp
f0101dd0:	68 00 10 00 00       	push   $0x1000
f0101dd5:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101ddb:	e8 6f f1 ff ff       	call   f0100f4f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101de0:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101de6:	ba 00 00 00 00       	mov    $0x0,%edx
f0101deb:	89 f8                	mov    %edi,%eax
f0101ded:	e8 8e eb ff ff       	call   f0100980 <check_va2pa>
f0101df2:	83 c4 10             	add    $0x10,%esp
f0101df5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101df8:	74 19                	je     f0101e13 <mem_init+0xdef>
f0101dfa:	68 10 41 10 f0       	push   $0xf0104110
f0101dff:	68 72 43 10 f0       	push   $0xf0104372
f0101e04:	68 5d 03 00 00       	push   $0x35d
f0101e09:	68 4c 43 10 f0       	push   $0xf010434c
f0101e0e:	e8 78 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e13:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e18:	89 f8                	mov    %edi,%eax
f0101e1a:	e8 61 eb ff ff       	call   f0100980 <check_va2pa>
f0101e1f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e22:	74 19                	je     f0101e3d <mem_init+0xe19>
f0101e24:	68 6c 41 10 f0       	push   $0xf010416c
f0101e29:	68 72 43 10 f0       	push   $0xf0104372
f0101e2e:	68 5e 03 00 00       	push   $0x35e
f0101e33:	68 4c 43 10 f0       	push   $0xf010434c
f0101e38:	e8 4e e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e3d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e42:	74 19                	je     f0101e5d <mem_init+0xe39>
f0101e44:	68 bd 45 10 f0       	push   $0xf01045bd
f0101e49:	68 72 43 10 f0       	push   $0xf0104372
f0101e4e:	68 5f 03 00 00       	push   $0x35f
f0101e53:	68 4c 43 10 f0       	push   $0xf010434c
f0101e58:	e8 2e e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e5d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e62:	74 19                	je     f0101e7d <mem_init+0xe59>
f0101e64:	68 8b 45 10 f0       	push   $0xf010458b
f0101e69:	68 72 43 10 f0       	push   $0xf0104372
f0101e6e:	68 60 03 00 00       	push   $0x360
f0101e73:	68 4c 43 10 f0       	push   $0xf010434c
f0101e78:	e8 0e e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e7d:	83 ec 0c             	sub    $0xc,%esp
f0101e80:	6a 00                	push   $0x0
f0101e82:	e8 fa ee ff ff       	call   f0100d81 <page_alloc>
f0101e87:	83 c4 10             	add    $0x10,%esp
f0101e8a:	85 c0                	test   %eax,%eax
f0101e8c:	74 04                	je     f0101e92 <mem_init+0xe6e>
f0101e8e:	39 c3                	cmp    %eax,%ebx
f0101e90:	74 19                	je     f0101eab <mem_init+0xe87>
f0101e92:	68 94 41 10 f0       	push   $0xf0104194
f0101e97:	68 72 43 10 f0       	push   $0xf0104372
f0101e9c:	68 63 03 00 00       	push   $0x363
f0101ea1:	68 4c 43 10 f0       	push   $0xf010434c
f0101ea6:	e8 e0 e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101eab:	83 ec 0c             	sub    $0xc,%esp
f0101eae:	6a 00                	push   $0x0
f0101eb0:	e8 cc ee ff ff       	call   f0100d81 <page_alloc>
f0101eb5:	83 c4 10             	add    $0x10,%esp
f0101eb8:	85 c0                	test   %eax,%eax
f0101eba:	74 19                	je     f0101ed5 <mem_init+0xeb1>
f0101ebc:	68 df 44 10 f0       	push   $0xf01044df
f0101ec1:	68 72 43 10 f0       	push   $0xf0104372
f0101ec6:	68 66 03 00 00       	push   $0x366
f0101ecb:	68 4c 43 10 f0       	push   $0xf010434c
f0101ed0:	e8 b6 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ed5:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0101edb:	8b 11                	mov    (%ecx),%edx
f0101edd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ee3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ee6:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101eec:	c1 f8 03             	sar    $0x3,%eax
f0101eef:	c1 e0 0c             	shl    $0xc,%eax
f0101ef2:	39 c2                	cmp    %eax,%edx
f0101ef4:	74 19                	je     f0101f0f <mem_init+0xeeb>
f0101ef6:	68 38 3e 10 f0       	push   $0xf0103e38
f0101efb:	68 72 43 10 f0       	push   $0xf0104372
f0101f00:	68 69 03 00 00       	push   $0x369
f0101f05:	68 4c 43 10 f0       	push   $0xf010434c
f0101f0a:	e8 7c e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f0f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f15:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f18:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f1d:	74 19                	je     f0101f38 <mem_init+0xf14>
f0101f1f:	68 42 45 10 f0       	push   $0xf0104542
f0101f24:	68 72 43 10 f0       	push   $0xf0104372
f0101f29:	68 6b 03 00 00       	push   $0x36b
f0101f2e:	68 4c 43 10 f0       	push   $0xf010434c
f0101f33:	e8 53 e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f38:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f3b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f41:	83 ec 0c             	sub    $0xc,%esp
f0101f44:	50                   	push   %eax
f0101f45:	e8 a7 ee ff ff       	call   f0100df1 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f4a:	83 c4 0c             	add    $0xc,%esp
f0101f4d:	6a 01                	push   $0x1
f0101f4f:	68 00 10 40 00       	push   $0x401000
f0101f54:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101f5a:	e8 f4 ee ff ff       	call   f0100e53 <pgdir_walk>
f0101f5f:	89 c7                	mov    %eax,%edi
f0101f61:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f64:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f69:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f6c:	8b 40 04             	mov    0x4(%eax),%eax
f0101f6f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f74:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101f7a:	89 c2                	mov    %eax,%edx
f0101f7c:	c1 ea 0c             	shr    $0xc,%edx
f0101f7f:	83 c4 10             	add    $0x10,%esp
f0101f82:	39 ca                	cmp    %ecx,%edx
f0101f84:	72 15                	jb     f0101f9b <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f86:	50                   	push   %eax
f0101f87:	68 f8 3b 10 f0       	push   $0xf0103bf8
f0101f8c:	68 72 03 00 00       	push   $0x372
f0101f91:	68 4c 43 10 f0       	push   $0xf010434c
f0101f96:	e8 f0 e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f9b:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fa0:	39 c7                	cmp    %eax,%edi
f0101fa2:	74 19                	je     f0101fbd <mem_init+0xf99>
f0101fa4:	68 ce 45 10 f0       	push   $0xf01045ce
f0101fa9:	68 72 43 10 f0       	push   $0xf0104372
f0101fae:	68 73 03 00 00       	push   $0x373
f0101fb3:	68 4c 43 10 f0       	push   $0xf010434c
f0101fb8:	e8 ce e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101fbd:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fc0:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101fc7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fca:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fd0:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101fd6:	c1 f8 03             	sar    $0x3,%eax
f0101fd9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fdc:	89 c2                	mov    %eax,%edx
f0101fde:	c1 ea 0c             	shr    $0xc,%edx
f0101fe1:	39 d1                	cmp    %edx,%ecx
f0101fe3:	77 12                	ja     f0101ff7 <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fe5:	50                   	push   %eax
f0101fe6:	68 f8 3b 10 f0       	push   $0xf0103bf8
f0101feb:	6a 52                	push   $0x52
f0101fed:	68 58 43 10 f0       	push   $0xf0104358
f0101ff2:	e8 94 e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101ff7:	83 ec 04             	sub    $0x4,%esp
f0101ffa:	68 00 10 00 00       	push   $0x1000
f0101fff:	68 ff 00 00 00       	push   $0xff
f0102004:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102009:	50                   	push   %eax
f010200a:	e8 44 12 00 00       	call   f0103253 <memset>
	page_free(pp0);
f010200f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102012:	89 3c 24             	mov    %edi,(%esp)
f0102015:	e8 d7 ed ff ff       	call   f0100df1 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010201a:	83 c4 0c             	add    $0xc,%esp
f010201d:	6a 01                	push   $0x1
f010201f:	6a 00                	push   $0x0
f0102021:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102027:	e8 27 ee ff ff       	call   f0100e53 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010202c:	89 fa                	mov    %edi,%edx
f010202e:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102034:	c1 fa 03             	sar    $0x3,%edx
f0102037:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010203a:	89 d0                	mov    %edx,%eax
f010203c:	c1 e8 0c             	shr    $0xc,%eax
f010203f:	83 c4 10             	add    $0x10,%esp
f0102042:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0102048:	72 12                	jb     f010205c <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010204a:	52                   	push   %edx
f010204b:	68 f8 3b 10 f0       	push   $0xf0103bf8
f0102050:	6a 52                	push   $0x52
f0102052:	68 58 43 10 f0       	push   $0xf0104358
f0102057:	e8 2f e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f010205c:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102062:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102065:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010206b:	f6 00 01             	testb  $0x1,(%eax)
f010206e:	74 19                	je     f0102089 <mem_init+0x1065>
f0102070:	68 e6 45 10 f0       	push   $0xf01045e6
f0102075:	68 72 43 10 f0       	push   $0xf0104372
f010207a:	68 7d 03 00 00       	push   $0x37d
f010207f:	68 4c 43 10 f0       	push   $0xf010434c
f0102084:	e8 02 e0 ff ff       	call   f010008b <_panic>
f0102089:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010208c:	39 c2                	cmp    %eax,%edx
f010208e:	75 db                	jne    f010206b <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102090:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102095:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010209b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010209e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020a4:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01020a7:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f01020ad:	83 ec 0c             	sub    $0xc,%esp
f01020b0:	50                   	push   %eax
f01020b1:	e8 3b ed ff ff       	call   f0100df1 <page_free>
	page_free(pp1);
f01020b6:	89 1c 24             	mov    %ebx,(%esp)
f01020b9:	e8 33 ed ff ff       	call   f0100df1 <page_free>
	page_free(pp2);
f01020be:	89 34 24             	mov    %esi,(%esp)
f01020c1:	e8 2b ed ff ff       	call   f0100df1 <page_free>

	cprintf("check_page() succeeded!\n");
f01020c6:	c7 04 24 fd 45 10 f0 	movl   $0xf01045fd,(%esp)
f01020cd:	e8 bd 06 00 00       	call   f010278f <cprintf>
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	int perm = PTE_U | PTE_P;  
    	int i=0;  
    	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);  
f01020d2:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01020d7:	8d 34 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%esi
f01020de:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    	for(i=0; i<n; i= i+PGSIZE)  
f01020e4:	83 c4 10             	add    $0x10,%esp
f01020e7:	bb 00 00 00 00       	mov    $0x0,%ebx
f01020ec:	eb 6a                	jmp    f0102158 <mem_init+0x1134>
f01020ee:	8d 8b 00 00 00 ef    	lea    -0x11000000(%ebx),%ecx
        	page_insert(kern_pgdir, pa2page(PADDR(pages) + i), (void *) (UPAGES +i), perm); 
f01020f4:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020fa:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102100:	77 15                	ja     f0102117 <mem_init+0x10f3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102102:	52                   	push   %edx
f0102103:	68 3c 3d 10 f0       	push   $0xf0103d3c
f0102108:	68 b5 00 00 00       	push   $0xb5
f010210d:	68 4c 43 10 f0       	push   $0xf010434c
f0102112:	e8 74 df ff ff       	call   f010008b <_panic>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102117:	8d 84 02 00 00 00 10 	lea    0x10000000(%edx,%eax,1),%eax
f010211e:	c1 e8 0c             	shr    $0xc,%eax
f0102121:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0102127:	72 14                	jb     f010213d <mem_init+0x1119>
		panic("pa2page called with invalid pa");
f0102129:	83 ec 04             	sub    $0x4,%esp
f010212c:	68 e0 3c 10 f0       	push   $0xf0103ce0
f0102131:	6a 4b                	push   $0x4b
f0102133:	68 58 43 10 f0       	push   $0xf0104358
f0102138:	e8 4e df ff ff       	call   f010008b <_panic>
f010213d:	6a 05                	push   $0x5
f010213f:	51                   	push   %ecx
f0102140:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102143:	50                   	push   %eax
f0102144:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010214a:	e8 4b ee ff ff       	call   f0100f9a <page_insert>
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	int perm = PTE_U | PTE_P;  
    	int i=0;  
    	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);  
    	for(i=0; i<n; i= i+PGSIZE)  
f010214f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102155:	83 c4 10             	add    $0x10,%esp
f0102158:	89 d8                	mov    %ebx,%eax
f010215a:	39 de                	cmp    %ebx,%esi
f010215c:	77 90                	ja     f01020ee <mem_init+0x10ca>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010215e:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f0102163:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102168:	77 15                	ja     f010217f <mem_init+0x115b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010216a:	50                   	push   %eax
f010216b:	68 3c 3d 10 f0       	push   $0xf0103d3c
f0102170:	68 c3 00 00 00       	push   $0xc3
f0102175:	68 4c 43 10 f0       	push   $0xf010434c
f010217a:	e8 0c df ff ff       	call   f010008b <_panic>
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	perm =0;  
    	perm = PTE_P |PTE_W;  
    	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, ROUNDUP(KSTKSIZE, PGSIZE), PADDR(bootstack), perm); 
f010217f:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0102185:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
f010218a:	8d b3 00 50 11 10    	lea    0x10115000(%ebx),%esi
{
	// Fill this function in
	 
	while(size)  
    	{  
     	   pte_t* pte = pgdir_walk(pgdir, (void* )va, 1);  
f0102190:	83 ec 04             	sub    $0x4,%esp
f0102193:	6a 01                	push   $0x1
f0102195:	53                   	push   %ebx
f0102196:	57                   	push   %edi
f0102197:	e8 b7 ec ff ff       	call   f0100e53 <pgdir_walk>
      	  if(pte == NULL)  
f010219c:	83 c4 10             	add    $0x10,%esp
f010219f:	85 c0                	test   %eax,%eax
f01021a1:	74 13                	je     f01021b6 <mem_init+0x1192>
      	      return;  
      	  *pte= pa |perm|PTE_P;      
f01021a3:	83 ce 03             	or     $0x3,%esi
f01021a6:	89 30                	mov    %esi,(%eax)
      	  size -= PGSIZE;  
      	  pa  += PGSIZE;  
      	  va  += PGSIZE;  
f01021a8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	 
	while(size)  
f01021ae:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01021b4:	75 d4                	jne    f010218a <mem_init+0x1166>
	int size = ~0;  
    	size = size - KERNBASE +1;  
    	size = ROUNDUP(size, PGSIZE);  
    	perm = 0;  
    	perm = PTE_P | PTE_W;  
    	boot_map_region(kern_pgdir, KERNBASE, size, 0, perm );  
f01021b6:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f01021bc:	bb 00 00 00 f0       	mov    $0xf0000000,%ebx
f01021c1:	8d b3 00 00 00 10    	lea    0x10000000(%ebx),%esi
{
	// Fill this function in
	 
	while(size)  
    	{  
     	   pte_t* pte = pgdir_walk(pgdir, (void* )va, 1);  
f01021c7:	83 ec 04             	sub    $0x4,%esp
f01021ca:	6a 01                	push   $0x1
f01021cc:	53                   	push   %ebx
f01021cd:	57                   	push   %edi
f01021ce:	e8 80 ec ff ff       	call   f0100e53 <pgdir_walk>
      	  if(pte == NULL)  
f01021d3:	83 c4 10             	add    $0x10,%esp
f01021d6:	85 c0                	test   %eax,%eax
f01021d8:	74 0d                	je     f01021e7 <mem_init+0x11c3>
      	      return;  
      	  *pte= pa |perm|PTE_P;      
f01021da:	83 ce 03             	or     $0x3,%esi
f01021dd:	89 30                	mov    %esi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	 
	while(size)  
f01021df:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01021e5:	75 da                	jne    f01021c1 <mem_init+0x119d>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021e7:	8b 35 68 79 11 f0    	mov    0xf0117968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021ed:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01021f2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021f5:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021fc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102201:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102204:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010220a:	89 7d d0             	mov    %edi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010220d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102212:	eb 55                	jmp    f0102269 <mem_init+0x1245>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102214:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010221a:	89 f0                	mov    %esi,%eax
f010221c:	e8 5f e7 ff ff       	call   f0100980 <check_va2pa>
f0102221:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102228:	77 15                	ja     f010223f <mem_init+0x121b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010222a:	57                   	push   %edi
f010222b:	68 3c 3d 10 f0       	push   $0xf0103d3c
f0102230:	68 bf 02 00 00       	push   $0x2bf
f0102235:	68 4c 43 10 f0       	push   $0xf010434c
f010223a:	e8 4c de ff ff       	call   f010008b <_panic>
f010223f:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f0102246:	39 c2                	cmp    %eax,%edx
f0102248:	74 19                	je     f0102263 <mem_init+0x123f>
f010224a:	68 b8 41 10 f0       	push   $0xf01041b8
f010224f:	68 72 43 10 f0       	push   $0xf0104372
f0102254:	68 bf 02 00 00       	push   $0x2bf
f0102259:	68 4c 43 10 f0       	push   $0xf010434c
f010225e:	e8 28 de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102263:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102269:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010226c:	77 a6                	ja     f0102214 <mem_init+0x11f0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010226e:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102271:	c1 e7 0c             	shl    $0xc,%edi
f0102274:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102279:	eb 30                	jmp    f01022ab <mem_init+0x1287>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010227b:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102281:	89 f0                	mov    %esi,%eax
f0102283:	e8 f8 e6 ff ff       	call   f0100980 <check_va2pa>
f0102288:	39 c3                	cmp    %eax,%ebx
f010228a:	74 19                	je     f01022a5 <mem_init+0x1281>
f010228c:	68 ec 41 10 f0       	push   $0xf01041ec
f0102291:	68 72 43 10 f0       	push   $0xf0104372
f0102296:	68 c4 02 00 00       	push   $0x2c4
f010229b:	68 4c 43 10 f0       	push   $0xf010434c
f01022a0:	e8 e6 dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022a5:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01022ab:	39 fb                	cmp    %edi,%ebx
f01022ad:	72 cc                	jb     f010227b <mem_init+0x1257>
f01022af:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01022b4:	89 da                	mov    %ebx,%edx
f01022b6:	89 f0                	mov    %esi,%eax
f01022b8:	e8 c3 e6 ff ff       	call   f0100980 <check_va2pa>
f01022bd:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f01022c3:	39 c2                	cmp    %eax,%edx
f01022c5:	74 19                	je     f01022e0 <mem_init+0x12bc>
f01022c7:	68 14 42 10 f0       	push   $0xf0104214
f01022cc:	68 72 43 10 f0       	push   $0xf0104372
f01022d1:	68 c8 02 00 00       	push   $0x2c8
f01022d6:	68 4c 43 10 f0       	push   $0xf010434c
f01022db:	e8 ab dd ff ff       	call   f010008b <_panic>
f01022e0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022e6:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01022ec:	75 c6                	jne    f01022b4 <mem_init+0x1290>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022ee:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01022f3:	89 f0                	mov    %esi,%eax
f01022f5:	e8 86 e6 ff ff       	call   f0100980 <check_va2pa>
f01022fa:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022fd:	74 51                	je     f0102350 <mem_init+0x132c>
f01022ff:	68 5c 42 10 f0       	push   $0xf010425c
f0102304:	68 72 43 10 f0       	push   $0xf0104372
f0102309:	68 c9 02 00 00       	push   $0x2c9
f010230e:	68 4c 43 10 f0       	push   $0xf010434c
f0102313:	e8 73 dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102318:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f010231d:	72 36                	jb     f0102355 <mem_init+0x1331>
f010231f:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102324:	76 07                	jbe    f010232d <mem_init+0x1309>
f0102326:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010232b:	75 28                	jne    f0102355 <mem_init+0x1331>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f010232d:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102331:	0f 85 83 00 00 00    	jne    f01023ba <mem_init+0x1396>
f0102337:	68 16 46 10 f0       	push   $0xf0104616
f010233c:	68 72 43 10 f0       	push   $0xf0104372
f0102341:	68 d1 02 00 00       	push   $0x2d1
f0102346:	68 4c 43 10 f0       	push   $0xf010434c
f010234b:	e8 3b dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102350:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102355:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010235a:	76 3f                	jbe    f010239b <mem_init+0x1377>
				assert(pgdir[i] & PTE_P);
f010235c:	8b 14 86             	mov    (%esi,%eax,4),%edx
f010235f:	f6 c2 01             	test   $0x1,%dl
f0102362:	75 19                	jne    f010237d <mem_init+0x1359>
f0102364:	68 16 46 10 f0       	push   $0xf0104616
f0102369:	68 72 43 10 f0       	push   $0xf0104372
f010236e:	68 d5 02 00 00       	push   $0x2d5
f0102373:	68 4c 43 10 f0       	push   $0xf010434c
f0102378:	e8 0e dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f010237d:	f6 c2 02             	test   $0x2,%dl
f0102380:	75 38                	jne    f01023ba <mem_init+0x1396>
f0102382:	68 27 46 10 f0       	push   $0xf0104627
f0102387:	68 72 43 10 f0       	push   $0xf0104372
f010238c:	68 d6 02 00 00       	push   $0x2d6
f0102391:	68 4c 43 10 f0       	push   $0xf010434c
f0102396:	e8 f0 dc ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f010239b:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010239f:	74 19                	je     f01023ba <mem_init+0x1396>
f01023a1:	68 38 46 10 f0       	push   $0xf0104638
f01023a6:	68 72 43 10 f0       	push   $0xf0104372
f01023ab:	68 d8 02 00 00       	push   $0x2d8
f01023b0:	68 4c 43 10 f0       	push   $0xf010434c
f01023b5:	e8 d1 dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01023ba:	83 c0 01             	add    $0x1,%eax
f01023bd:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01023c2:	0f 86 50 ff ff ff    	jbe    f0102318 <mem_init+0x12f4>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01023c8:	83 ec 0c             	sub    $0xc,%esp
f01023cb:	68 8c 42 10 f0       	push   $0xf010428c
f01023d0:	e8 ba 03 00 00       	call   f010278f <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023d5:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023da:	83 c4 10             	add    $0x10,%esp
f01023dd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023e2:	77 15                	ja     f01023f9 <mem_init+0x13d5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023e4:	50                   	push   %eax
f01023e5:	68 3c 3d 10 f0       	push   $0xf0103d3c
f01023ea:	68 dc 00 00 00       	push   $0xdc
f01023ef:	68 4c 43 10 f0       	push   $0xf010434c
f01023f4:	e8 92 dc ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01023f9:	05 00 00 00 10       	add    $0x10000000,%eax
f01023fe:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102401:	b8 00 00 00 00       	mov    $0x0,%eax
f0102406:	e8 d9 e5 ff ff       	call   f01009e4 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f010240b:	0f 20 c0             	mov    %cr0,%eax
f010240e:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102411:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102416:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102419:	83 ec 0c             	sub    $0xc,%esp
f010241c:	6a 00                	push   $0x0
f010241e:	e8 5e e9 ff ff       	call   f0100d81 <page_alloc>
f0102423:	89 c3                	mov    %eax,%ebx
f0102425:	83 c4 10             	add    $0x10,%esp
f0102428:	85 c0                	test   %eax,%eax
f010242a:	75 19                	jne    f0102445 <mem_init+0x1421>
f010242c:	68 34 44 10 f0       	push   $0xf0104434
f0102431:	68 72 43 10 f0       	push   $0xf0104372
f0102436:	68 98 03 00 00       	push   $0x398
f010243b:	68 4c 43 10 f0       	push   $0xf010434c
f0102440:	e8 46 dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0102445:	83 ec 0c             	sub    $0xc,%esp
f0102448:	6a 00                	push   $0x0
f010244a:	e8 32 e9 ff ff       	call   f0100d81 <page_alloc>
f010244f:	89 c7                	mov    %eax,%edi
f0102451:	83 c4 10             	add    $0x10,%esp
f0102454:	85 c0                	test   %eax,%eax
f0102456:	75 19                	jne    f0102471 <mem_init+0x144d>
f0102458:	68 4a 44 10 f0       	push   $0xf010444a
f010245d:	68 72 43 10 f0       	push   $0xf0104372
f0102462:	68 99 03 00 00       	push   $0x399
f0102467:	68 4c 43 10 f0       	push   $0xf010434c
f010246c:	e8 1a dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102471:	83 ec 0c             	sub    $0xc,%esp
f0102474:	6a 00                	push   $0x0
f0102476:	e8 06 e9 ff ff       	call   f0100d81 <page_alloc>
f010247b:	89 c6                	mov    %eax,%esi
f010247d:	83 c4 10             	add    $0x10,%esp
f0102480:	85 c0                	test   %eax,%eax
f0102482:	75 19                	jne    f010249d <mem_init+0x1479>
f0102484:	68 60 44 10 f0       	push   $0xf0104460
f0102489:	68 72 43 10 f0       	push   $0xf0104372
f010248e:	68 9a 03 00 00       	push   $0x39a
f0102493:	68 4c 43 10 f0       	push   $0xf010434c
f0102498:	e8 ee db ff ff       	call   f010008b <_panic>
	page_free(pp0);
f010249d:	83 ec 0c             	sub    $0xc,%esp
f01024a0:	53                   	push   %ebx
f01024a1:	e8 4b e9 ff ff       	call   f0100df1 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024a6:	89 f8                	mov    %edi,%eax
f01024a8:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01024ae:	c1 f8 03             	sar    $0x3,%eax
f01024b1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024b4:	89 c2                	mov    %eax,%edx
f01024b6:	c1 ea 0c             	shr    $0xc,%edx
f01024b9:	83 c4 10             	add    $0x10,%esp
f01024bc:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01024c2:	72 12                	jb     f01024d6 <mem_init+0x14b2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024c4:	50                   	push   %eax
f01024c5:	68 f8 3b 10 f0       	push   $0xf0103bf8
f01024ca:	6a 52                	push   $0x52
f01024cc:	68 58 43 10 f0       	push   $0xf0104358
f01024d1:	e8 b5 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024d6:	83 ec 04             	sub    $0x4,%esp
f01024d9:	68 00 10 00 00       	push   $0x1000
f01024de:	6a 01                	push   $0x1
f01024e0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024e5:	50                   	push   %eax
f01024e6:	e8 68 0d 00 00       	call   f0103253 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024eb:	89 f0                	mov    %esi,%eax
f01024ed:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01024f3:	c1 f8 03             	sar    $0x3,%eax
f01024f6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024f9:	89 c2                	mov    %eax,%edx
f01024fb:	c1 ea 0c             	shr    $0xc,%edx
f01024fe:	83 c4 10             	add    $0x10,%esp
f0102501:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102507:	72 12                	jb     f010251b <mem_init+0x14f7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102509:	50                   	push   %eax
f010250a:	68 f8 3b 10 f0       	push   $0xf0103bf8
f010250f:	6a 52                	push   $0x52
f0102511:	68 58 43 10 f0       	push   $0xf0104358
f0102516:	e8 70 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f010251b:	83 ec 04             	sub    $0x4,%esp
f010251e:	68 00 10 00 00       	push   $0x1000
f0102523:	6a 02                	push   $0x2
f0102525:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010252a:	50                   	push   %eax
f010252b:	e8 23 0d 00 00       	call   f0103253 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102530:	6a 02                	push   $0x2
f0102532:	68 00 10 00 00       	push   $0x1000
f0102537:	57                   	push   %edi
f0102538:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010253e:	e8 57 ea ff ff       	call   f0100f9a <page_insert>
	assert(pp1->pp_ref == 1);
f0102543:	83 c4 20             	add    $0x20,%esp
f0102546:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010254b:	74 19                	je     f0102566 <mem_init+0x1542>
f010254d:	68 31 45 10 f0       	push   $0xf0104531
f0102552:	68 72 43 10 f0       	push   $0xf0104372
f0102557:	68 9f 03 00 00       	push   $0x39f
f010255c:	68 4c 43 10 f0       	push   $0xf010434c
f0102561:	e8 25 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102566:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010256d:	01 01 01 
f0102570:	74 19                	je     f010258b <mem_init+0x1567>
f0102572:	68 ac 42 10 f0       	push   $0xf01042ac
f0102577:	68 72 43 10 f0       	push   $0xf0104372
f010257c:	68 a0 03 00 00       	push   $0x3a0
f0102581:	68 4c 43 10 f0       	push   $0xf010434c
f0102586:	e8 00 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010258b:	6a 02                	push   $0x2
f010258d:	68 00 10 00 00       	push   $0x1000
f0102592:	56                   	push   %esi
f0102593:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102599:	e8 fc e9 ff ff       	call   f0100f9a <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010259e:	83 c4 10             	add    $0x10,%esp
f01025a1:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01025a8:	02 02 02 
f01025ab:	74 19                	je     f01025c6 <mem_init+0x15a2>
f01025ad:	68 d0 42 10 f0       	push   $0xf01042d0
f01025b2:	68 72 43 10 f0       	push   $0xf0104372
f01025b7:	68 a2 03 00 00       	push   $0x3a2
f01025bc:	68 4c 43 10 f0       	push   $0xf010434c
f01025c1:	e8 c5 da ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01025c6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01025cb:	74 19                	je     f01025e6 <mem_init+0x15c2>
f01025cd:	68 53 45 10 f0       	push   $0xf0104553
f01025d2:	68 72 43 10 f0       	push   $0xf0104372
f01025d7:	68 a3 03 00 00       	push   $0x3a3
f01025dc:	68 4c 43 10 f0       	push   $0xf010434c
f01025e1:	e8 a5 da ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01025e6:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025eb:	74 19                	je     f0102606 <mem_init+0x15e2>
f01025ed:	68 bd 45 10 f0       	push   $0xf01045bd
f01025f2:	68 72 43 10 f0       	push   $0xf0104372
f01025f7:	68 a4 03 00 00       	push   $0x3a4
f01025fc:	68 4c 43 10 f0       	push   $0xf010434c
f0102601:	e8 85 da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102606:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010260d:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102610:	89 f0                	mov    %esi,%eax
f0102612:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102618:	c1 f8 03             	sar    $0x3,%eax
f010261b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010261e:	89 c2                	mov    %eax,%edx
f0102620:	c1 ea 0c             	shr    $0xc,%edx
f0102623:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102629:	72 12                	jb     f010263d <mem_init+0x1619>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010262b:	50                   	push   %eax
f010262c:	68 f8 3b 10 f0       	push   $0xf0103bf8
f0102631:	6a 52                	push   $0x52
f0102633:	68 58 43 10 f0       	push   $0xf0104358
f0102638:	e8 4e da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010263d:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102644:	03 03 03 
f0102647:	74 19                	je     f0102662 <mem_init+0x163e>
f0102649:	68 f4 42 10 f0       	push   $0xf01042f4
f010264e:	68 72 43 10 f0       	push   $0xf0104372
f0102653:	68 a6 03 00 00       	push   $0x3a6
f0102658:	68 4c 43 10 f0       	push   $0xf010434c
f010265d:	e8 29 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102662:	83 ec 08             	sub    $0x8,%esp
f0102665:	68 00 10 00 00       	push   $0x1000
f010266a:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102670:	e8 da e8 ff ff       	call   f0100f4f <page_remove>
	assert(pp2->pp_ref == 0);
f0102675:	83 c4 10             	add    $0x10,%esp
f0102678:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010267d:	74 19                	je     f0102698 <mem_init+0x1674>
f010267f:	68 8b 45 10 f0       	push   $0xf010458b
f0102684:	68 72 43 10 f0       	push   $0xf0104372
f0102689:	68 a8 03 00 00       	push   $0x3a8
f010268e:	68 4c 43 10 f0       	push   $0xf010434c
f0102693:	e8 f3 d9 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102698:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f010269e:	8b 11                	mov    (%ecx),%edx
f01026a0:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01026a6:	89 d8                	mov    %ebx,%eax
f01026a8:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01026ae:	c1 f8 03             	sar    $0x3,%eax
f01026b1:	c1 e0 0c             	shl    $0xc,%eax
f01026b4:	39 c2                	cmp    %eax,%edx
f01026b6:	74 19                	je     f01026d1 <mem_init+0x16ad>
f01026b8:	68 38 3e 10 f0       	push   $0xf0103e38
f01026bd:	68 72 43 10 f0       	push   $0xf0104372
f01026c2:	68 ab 03 00 00       	push   $0x3ab
f01026c7:	68 4c 43 10 f0       	push   $0xf010434c
f01026cc:	e8 ba d9 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01026d1:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026d7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026dc:	74 19                	je     f01026f7 <mem_init+0x16d3>
f01026de:	68 42 45 10 f0       	push   $0xf0104542
f01026e3:	68 72 43 10 f0       	push   $0xf0104372
f01026e8:	68 ad 03 00 00       	push   $0x3ad
f01026ed:	68 4c 43 10 f0       	push   $0xf010434c
f01026f2:	e8 94 d9 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01026f7:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01026fd:	83 ec 0c             	sub    $0xc,%esp
f0102700:	53                   	push   %ebx
f0102701:	e8 eb e6 ff ff       	call   f0100df1 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102706:	c7 04 24 20 43 10 f0 	movl   $0xf0104320,(%esp)
f010270d:	e8 7d 00 00 00       	call   f010278f <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102712:	83 c4 10             	add    $0x10,%esp
f0102715:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102718:	5b                   	pop    %ebx
f0102719:	5e                   	pop    %esi
f010271a:	5f                   	pop    %edi
f010271b:	5d                   	pop    %ebp
f010271c:	c3                   	ret    

f010271d <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010271d:	55                   	push   %ebp
f010271e:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102720:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102723:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102726:	5d                   	pop    %ebp
f0102727:	c3                   	ret    

f0102728 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102728:	55                   	push   %ebp
f0102729:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010272b:	ba 70 00 00 00       	mov    $0x70,%edx
f0102730:	8b 45 08             	mov    0x8(%ebp),%eax
f0102733:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102734:	ba 71 00 00 00       	mov    $0x71,%edx
f0102739:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010273a:	0f b6 c0             	movzbl %al,%eax
}
f010273d:	5d                   	pop    %ebp
f010273e:	c3                   	ret    

f010273f <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010273f:	55                   	push   %ebp
f0102740:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102742:	ba 70 00 00 00       	mov    $0x70,%edx
f0102747:	8b 45 08             	mov    0x8(%ebp),%eax
f010274a:	ee                   	out    %al,(%dx)
f010274b:	ba 71 00 00 00       	mov    $0x71,%edx
f0102750:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102753:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102754:	5d                   	pop    %ebp
f0102755:	c3                   	ret    

f0102756 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102756:	55                   	push   %ebp
f0102757:	89 e5                	mov    %esp,%ebp
f0102759:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010275c:	ff 75 08             	pushl  0x8(%ebp)
f010275f:	e8 cf de ff ff       	call   f0100633 <cputchar>
	*cnt++;
}
f0102764:	83 c4 10             	add    $0x10,%esp
f0102767:	c9                   	leave  
f0102768:	c3                   	ret    

f0102769 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102769:	55                   	push   %ebp
f010276a:	89 e5                	mov    %esp,%ebp
f010276c:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010276f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102776:	ff 75 0c             	pushl  0xc(%ebp)
f0102779:	ff 75 08             	pushl  0x8(%ebp)
f010277c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010277f:	50                   	push   %eax
f0102780:	68 56 27 10 f0       	push   $0xf0102756
f0102785:	e8 5d 04 00 00       	call   f0102be7 <vprintfmt>
	return cnt;
}
f010278a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010278d:	c9                   	leave  
f010278e:	c3                   	ret    

f010278f <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010278f:	55                   	push   %ebp
f0102790:	89 e5                	mov    %esp,%ebp
f0102792:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102795:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102798:	50                   	push   %eax
f0102799:	ff 75 08             	pushl  0x8(%ebp)
f010279c:	e8 c8 ff ff ff       	call   f0102769 <vcprintf>
	va_end(ap);

	return cnt;
}
f01027a1:	c9                   	leave  
f01027a2:	c3                   	ret    

f01027a3 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01027a3:	55                   	push   %ebp
f01027a4:	89 e5                	mov    %esp,%ebp
f01027a6:	57                   	push   %edi
f01027a7:	56                   	push   %esi
f01027a8:	53                   	push   %ebx
f01027a9:	83 ec 14             	sub    $0x14,%esp
f01027ac:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01027af:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01027b2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01027b5:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01027b8:	8b 1a                	mov    (%edx),%ebx
f01027ba:	8b 01                	mov    (%ecx),%eax
f01027bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027bf:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01027c6:	eb 7f                	jmp    f0102847 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01027c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01027cb:	01 d8                	add    %ebx,%eax
f01027cd:	89 c6                	mov    %eax,%esi
f01027cf:	c1 ee 1f             	shr    $0x1f,%esi
f01027d2:	01 c6                	add    %eax,%esi
f01027d4:	d1 fe                	sar    %esi
f01027d6:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01027d9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027dc:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01027df:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027e1:	eb 03                	jmp    f01027e6 <stab_binsearch+0x43>
			m--;
f01027e3:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027e6:	39 c3                	cmp    %eax,%ebx
f01027e8:	7f 0d                	jg     f01027f7 <stab_binsearch+0x54>
f01027ea:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01027ee:	83 ea 0c             	sub    $0xc,%edx
f01027f1:	39 f9                	cmp    %edi,%ecx
f01027f3:	75 ee                	jne    f01027e3 <stab_binsearch+0x40>
f01027f5:	eb 05                	jmp    f01027fc <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01027f7:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01027fa:	eb 4b                	jmp    f0102847 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01027fc:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027ff:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102802:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102806:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102809:	76 11                	jbe    f010281c <stab_binsearch+0x79>
			*region_left = m;
f010280b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010280e:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102810:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102813:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010281a:	eb 2b                	jmp    f0102847 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010281c:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010281f:	73 14                	jae    f0102835 <stab_binsearch+0x92>
			*region_right = m - 1;
f0102821:	83 e8 01             	sub    $0x1,%eax
f0102824:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102827:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010282a:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010282c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102833:	eb 12                	jmp    f0102847 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102835:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102838:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010283a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010283e:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102840:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102847:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010284a:	0f 8e 78 ff ff ff    	jle    f01027c8 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102850:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102854:	75 0f                	jne    f0102865 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102856:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102859:	8b 00                	mov    (%eax),%eax
f010285b:	83 e8 01             	sub    $0x1,%eax
f010285e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102861:	89 06                	mov    %eax,(%esi)
f0102863:	eb 2c                	jmp    f0102891 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102865:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102868:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010286a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010286d:	8b 0e                	mov    (%esi),%ecx
f010286f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102872:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102875:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102878:	eb 03                	jmp    f010287d <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010287a:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010287d:	39 c8                	cmp    %ecx,%eax
f010287f:	7e 0b                	jle    f010288c <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102881:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102885:	83 ea 0c             	sub    $0xc,%edx
f0102888:	39 df                	cmp    %ebx,%edi
f010288a:	75 ee                	jne    f010287a <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010288c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010288f:	89 06                	mov    %eax,(%esi)
	}
}
f0102891:	83 c4 14             	add    $0x14,%esp
f0102894:	5b                   	pop    %ebx
f0102895:	5e                   	pop    %esi
f0102896:	5f                   	pop    %edi
f0102897:	5d                   	pop    %ebp
f0102898:	c3                   	ret    

f0102899 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102899:	55                   	push   %ebp
f010289a:	89 e5                	mov    %esp,%ebp
f010289c:	57                   	push   %edi
f010289d:	56                   	push   %esi
f010289e:	53                   	push   %ebx
f010289f:	83 ec 3c             	sub    $0x3c,%esp
f01028a2:	8b 75 08             	mov    0x8(%ebp),%esi
f01028a5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01028a8:	c7 03 46 46 10 f0    	movl   $0xf0104646,(%ebx)
	info->eip_line = 0;
f01028ae:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01028b5:	c7 43 08 46 46 10 f0 	movl   $0xf0104646,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01028bc:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01028c3:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01028c6:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01028cd:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01028d3:	76 11                	jbe    f01028e6 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028d5:	b8 01 c0 10 f0       	mov    $0xf010c001,%eax
f01028da:	3d 7d a2 10 f0       	cmp    $0xf010a27d,%eax
f01028df:	77 19                	ja     f01028fa <debuginfo_eip+0x61>
f01028e1:	e9 b5 01 00 00       	jmp    f0102a9b <debuginfo_eip+0x202>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01028e6:	83 ec 04             	sub    $0x4,%esp
f01028e9:	68 50 46 10 f0       	push   $0xf0104650
f01028ee:	6a 7f                	push   $0x7f
f01028f0:	68 5d 46 10 f0       	push   $0xf010465d
f01028f5:	e8 91 d7 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028fa:	80 3d 00 c0 10 f0 00 	cmpb   $0x0,0xf010c000
f0102901:	0f 85 9b 01 00 00    	jne    f0102aa2 <debuginfo_eip+0x209>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102907:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010290e:	b8 7c a2 10 f0       	mov    $0xf010a27c,%eax
f0102913:	2d 7c 48 10 f0       	sub    $0xf010487c,%eax
f0102918:	c1 f8 02             	sar    $0x2,%eax
f010291b:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102921:	83 e8 01             	sub    $0x1,%eax
f0102924:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102927:	83 ec 08             	sub    $0x8,%esp
f010292a:	56                   	push   %esi
f010292b:	6a 64                	push   $0x64
f010292d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102930:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102933:	b8 7c 48 10 f0       	mov    $0xf010487c,%eax
f0102938:	e8 66 fe ff ff       	call   f01027a3 <stab_binsearch>
	if (lfile == 0)
f010293d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102940:	83 c4 10             	add    $0x10,%esp
f0102943:	85 c0                	test   %eax,%eax
f0102945:	0f 84 5e 01 00 00    	je     f0102aa9 <debuginfo_eip+0x210>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010294b:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010294e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102951:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102954:	83 ec 08             	sub    $0x8,%esp
f0102957:	56                   	push   %esi
f0102958:	6a 24                	push   $0x24
f010295a:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010295d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102960:	b8 7c 48 10 f0       	mov    $0xf010487c,%eax
f0102965:	e8 39 fe ff ff       	call   f01027a3 <stab_binsearch>

	if (lfun <= rfun) {
f010296a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010296d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102970:	83 c4 10             	add    $0x10,%esp
f0102973:	39 d0                	cmp    %edx,%eax
f0102975:	7f 40                	jg     f01029b7 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102977:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f010297a:	c1 e1 02             	shl    $0x2,%ecx
f010297d:	8d b9 7c 48 10 f0    	lea    -0xfefb784(%ecx),%edi
f0102983:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102986:	8b b9 7c 48 10 f0    	mov    -0xfefb784(%ecx),%edi
f010298c:	b9 01 c0 10 f0       	mov    $0xf010c001,%ecx
f0102991:	81 e9 7d a2 10 f0    	sub    $0xf010a27d,%ecx
f0102997:	39 cf                	cmp    %ecx,%edi
f0102999:	73 09                	jae    f01029a4 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010299b:	81 c7 7d a2 10 f0    	add    $0xf010a27d,%edi
f01029a1:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01029a4:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01029a7:	8b 4f 08             	mov    0x8(%edi),%ecx
f01029aa:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01029ad:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01029af:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01029b2:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01029b5:	eb 0f                	jmp    f01029c6 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01029b7:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01029ba:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01029bd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01029c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01029c3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01029c6:	83 ec 08             	sub    $0x8,%esp
f01029c9:	6a 3a                	push   $0x3a
f01029cb:	ff 73 08             	pushl  0x8(%ebx)
f01029ce:	e8 64 08 00 00       	call   f0103237 <strfind>
f01029d3:	2b 43 08             	sub    0x8(%ebx),%eax
f01029d6:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01029d9:	83 c4 08             	add    $0x8,%esp
f01029dc:	56                   	push   %esi
f01029dd:	6a 44                	push   $0x44
f01029df:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01029e2:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01029e5:	b8 7c 48 10 f0       	mov    $0xf010487c,%eax
f01029ea:	e8 b4 fd ff ff       	call   f01027a3 <stab_binsearch>
if (lline > rline) {
f01029ef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029f2:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01029f5:	83 c4 10             	add    $0x10,%esp
f01029f8:	39 d0                	cmp    %edx,%eax
f01029fa:	0f 8f b0 00 00 00    	jg     f0102ab0 <debuginfo_eip+0x217>
    return -1;
} else {
    info->eip_line = stabs[rline].n_desc;
f0102a00:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102a03:	0f b7 14 95 82 48 10 	movzwl -0xfefb77e(,%edx,4),%edx
f0102a0a:	f0 
f0102a0b:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102a0e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102a11:	89 c2                	mov    %eax,%edx
f0102a13:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102a16:	8d 04 85 7c 48 10 f0 	lea    -0xfefb784(,%eax,4),%eax
f0102a1d:	eb 06                	jmp    f0102a25 <debuginfo_eip+0x18c>
f0102a1f:	83 ea 01             	sub    $0x1,%edx
f0102a22:	83 e8 0c             	sub    $0xc,%eax
f0102a25:	39 d7                	cmp    %edx,%edi
f0102a27:	7f 34                	jg     f0102a5d <debuginfo_eip+0x1c4>
	       && stabs[lline].n_type != N_SOL
f0102a29:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102a2d:	80 f9 84             	cmp    $0x84,%cl
f0102a30:	74 0b                	je     f0102a3d <debuginfo_eip+0x1a4>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102a32:	80 f9 64             	cmp    $0x64,%cl
f0102a35:	75 e8                	jne    f0102a1f <debuginfo_eip+0x186>
f0102a37:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102a3b:	74 e2                	je     f0102a1f <debuginfo_eip+0x186>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102a3d:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102a40:	8b 14 85 7c 48 10 f0 	mov    -0xfefb784(,%eax,4),%edx
f0102a47:	b8 01 c0 10 f0       	mov    $0xf010c001,%eax
f0102a4c:	2d 7d a2 10 f0       	sub    $0xf010a27d,%eax
f0102a51:	39 c2                	cmp    %eax,%edx
f0102a53:	73 08                	jae    f0102a5d <debuginfo_eip+0x1c4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102a55:	81 c2 7d a2 10 f0    	add    $0xf010a27d,%edx
f0102a5b:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a5d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102a60:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a63:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a68:	39 f2                	cmp    %esi,%edx
f0102a6a:	7d 50                	jge    f0102abc <debuginfo_eip+0x223>
		for (lline = lfun + 1;
f0102a6c:	83 c2 01             	add    $0x1,%edx
f0102a6f:	89 d0                	mov    %edx,%eax
f0102a71:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102a74:	8d 14 95 7c 48 10 f0 	lea    -0xfefb784(,%edx,4),%edx
f0102a7b:	eb 04                	jmp    f0102a81 <debuginfo_eip+0x1e8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102a7d:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102a81:	39 c6                	cmp    %eax,%esi
f0102a83:	7e 32                	jle    f0102ab7 <debuginfo_eip+0x21e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a85:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102a89:	83 c0 01             	add    $0x1,%eax
f0102a8c:	83 c2 0c             	add    $0xc,%edx
f0102a8f:	80 f9 a0             	cmp    $0xa0,%cl
f0102a92:	74 e9                	je     f0102a7d <debuginfo_eip+0x1e4>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a94:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a99:	eb 21                	jmp    f0102abc <debuginfo_eip+0x223>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102aa0:	eb 1a                	jmp    f0102abc <debuginfo_eip+0x223>
f0102aa2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102aa7:	eb 13                	jmp    f0102abc <debuginfo_eip+0x223>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102aa9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102aae:	eb 0c                	jmp    f0102abc <debuginfo_eip+0x223>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
if (lline > rline) {
    return -1;
f0102ab0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102ab5:	eb 05                	jmp    f0102abc <debuginfo_eip+0x223>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102ab7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102abc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102abf:	5b                   	pop    %ebx
f0102ac0:	5e                   	pop    %esi
f0102ac1:	5f                   	pop    %edi
f0102ac2:	5d                   	pop    %ebp
f0102ac3:	c3                   	ret    

f0102ac4 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102ac4:	55                   	push   %ebp
f0102ac5:	89 e5                	mov    %esp,%ebp
f0102ac7:	57                   	push   %edi
f0102ac8:	56                   	push   %esi
f0102ac9:	53                   	push   %ebx
f0102aca:	83 ec 1c             	sub    $0x1c,%esp
f0102acd:	89 c7                	mov    %eax,%edi
f0102acf:	89 d6                	mov    %edx,%esi
f0102ad1:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ad4:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102ad7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ada:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102add:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102ae0:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102ae5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102ae8:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102aeb:	39 d3                	cmp    %edx,%ebx
f0102aed:	72 05                	jb     f0102af4 <printnum+0x30>
f0102aef:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102af2:	77 45                	ja     f0102b39 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102af4:	83 ec 0c             	sub    $0xc,%esp
f0102af7:	ff 75 18             	pushl  0x18(%ebp)
f0102afa:	8b 45 14             	mov    0x14(%ebp),%eax
f0102afd:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102b00:	53                   	push   %ebx
f0102b01:	ff 75 10             	pushl  0x10(%ebp)
f0102b04:	83 ec 08             	sub    $0x8,%esp
f0102b07:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b0a:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b0d:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b10:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b13:	e8 48 09 00 00       	call   f0103460 <__udivdi3>
f0102b18:	83 c4 18             	add    $0x18,%esp
f0102b1b:	52                   	push   %edx
f0102b1c:	50                   	push   %eax
f0102b1d:	89 f2                	mov    %esi,%edx
f0102b1f:	89 f8                	mov    %edi,%eax
f0102b21:	e8 9e ff ff ff       	call   f0102ac4 <printnum>
f0102b26:	83 c4 20             	add    $0x20,%esp
f0102b29:	eb 18                	jmp    f0102b43 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102b2b:	83 ec 08             	sub    $0x8,%esp
f0102b2e:	56                   	push   %esi
f0102b2f:	ff 75 18             	pushl  0x18(%ebp)
f0102b32:	ff d7                	call   *%edi
f0102b34:	83 c4 10             	add    $0x10,%esp
f0102b37:	eb 03                	jmp    f0102b3c <printnum+0x78>
f0102b39:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102b3c:	83 eb 01             	sub    $0x1,%ebx
f0102b3f:	85 db                	test   %ebx,%ebx
f0102b41:	7f e8                	jg     f0102b2b <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102b43:	83 ec 08             	sub    $0x8,%esp
f0102b46:	56                   	push   %esi
f0102b47:	83 ec 04             	sub    $0x4,%esp
f0102b4a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b4d:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b50:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b53:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b56:	e8 35 0a 00 00       	call   f0103590 <__umoddi3>
f0102b5b:	83 c4 14             	add    $0x14,%esp
f0102b5e:	0f be 80 6b 46 10 f0 	movsbl -0xfefb995(%eax),%eax
f0102b65:	50                   	push   %eax
f0102b66:	ff d7                	call   *%edi
}
f0102b68:	83 c4 10             	add    $0x10,%esp
f0102b6b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b6e:	5b                   	pop    %ebx
f0102b6f:	5e                   	pop    %esi
f0102b70:	5f                   	pop    %edi
f0102b71:	5d                   	pop    %ebp
f0102b72:	c3                   	ret    

f0102b73 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102b73:	55                   	push   %ebp
f0102b74:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102b76:	83 fa 01             	cmp    $0x1,%edx
f0102b79:	7e 0e                	jle    f0102b89 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102b7b:	8b 10                	mov    (%eax),%edx
f0102b7d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102b80:	89 08                	mov    %ecx,(%eax)
f0102b82:	8b 02                	mov    (%edx),%eax
f0102b84:	8b 52 04             	mov    0x4(%edx),%edx
f0102b87:	eb 22                	jmp    f0102bab <getuint+0x38>
	else if (lflag)
f0102b89:	85 d2                	test   %edx,%edx
f0102b8b:	74 10                	je     f0102b9d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102b8d:	8b 10                	mov    (%eax),%edx
f0102b8f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b92:	89 08                	mov    %ecx,(%eax)
f0102b94:	8b 02                	mov    (%edx),%eax
f0102b96:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b9b:	eb 0e                	jmp    f0102bab <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102b9d:	8b 10                	mov    (%eax),%edx
f0102b9f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102ba2:	89 08                	mov    %ecx,(%eax)
f0102ba4:	8b 02                	mov    (%edx),%eax
f0102ba6:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102bab:	5d                   	pop    %ebp
f0102bac:	c3                   	ret    

f0102bad <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102bad:	55                   	push   %ebp
f0102bae:	89 e5                	mov    %esp,%ebp
f0102bb0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102bb3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102bb7:	8b 10                	mov    (%eax),%edx
f0102bb9:	3b 50 04             	cmp    0x4(%eax),%edx
f0102bbc:	73 0a                	jae    f0102bc8 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102bbe:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102bc1:	89 08                	mov    %ecx,(%eax)
f0102bc3:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bc6:	88 02                	mov    %al,(%edx)
}
f0102bc8:	5d                   	pop    %ebp
f0102bc9:	c3                   	ret    

f0102bca <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102bca:	55                   	push   %ebp
f0102bcb:	89 e5                	mov    %esp,%ebp
f0102bcd:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102bd0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102bd3:	50                   	push   %eax
f0102bd4:	ff 75 10             	pushl  0x10(%ebp)
f0102bd7:	ff 75 0c             	pushl  0xc(%ebp)
f0102bda:	ff 75 08             	pushl  0x8(%ebp)
f0102bdd:	e8 05 00 00 00       	call   f0102be7 <vprintfmt>
	va_end(ap);
}
f0102be2:	83 c4 10             	add    $0x10,%esp
f0102be5:	c9                   	leave  
f0102be6:	c3                   	ret    

f0102be7 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102be7:	55                   	push   %ebp
f0102be8:	89 e5                	mov    %esp,%ebp
f0102bea:	57                   	push   %edi
f0102beb:	56                   	push   %esi
f0102bec:	53                   	push   %ebx
f0102bed:	83 ec 2c             	sub    $0x2c,%esp
f0102bf0:	8b 75 08             	mov    0x8(%ebp),%esi
f0102bf3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102bf6:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102bf9:	eb 12                	jmp    f0102c0d <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102bfb:	85 c0                	test   %eax,%eax
f0102bfd:	0f 84 89 03 00 00    	je     f0102f8c <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102c03:	83 ec 08             	sub    $0x8,%esp
f0102c06:	53                   	push   %ebx
f0102c07:	50                   	push   %eax
f0102c08:	ff d6                	call   *%esi
f0102c0a:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102c0d:	83 c7 01             	add    $0x1,%edi
f0102c10:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102c14:	83 f8 25             	cmp    $0x25,%eax
f0102c17:	75 e2                	jne    f0102bfb <vprintfmt+0x14>
f0102c19:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102c1d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102c24:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c2b:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102c32:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c37:	eb 07                	jmp    f0102c40 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c39:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102c3c:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c40:	8d 47 01             	lea    0x1(%edi),%eax
f0102c43:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102c46:	0f b6 07             	movzbl (%edi),%eax
f0102c49:	0f b6 c8             	movzbl %al,%ecx
f0102c4c:	83 e8 23             	sub    $0x23,%eax
f0102c4f:	3c 55                	cmp    $0x55,%al
f0102c51:	0f 87 1a 03 00 00    	ja     f0102f71 <vprintfmt+0x38a>
f0102c57:	0f b6 c0             	movzbl %al,%eax
f0102c5a:	ff 24 85 f8 46 10 f0 	jmp    *-0xfefb908(,%eax,4)
f0102c61:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102c64:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102c68:	eb d6                	jmp    f0102c40 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c6a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c6d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c72:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102c75:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102c78:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102c7c:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102c7f:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102c82:	83 fa 09             	cmp    $0x9,%edx
f0102c85:	77 39                	ja     f0102cc0 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102c87:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102c8a:	eb e9                	jmp    f0102c75 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102c8c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c8f:	8d 48 04             	lea    0x4(%eax),%ecx
f0102c92:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102c95:	8b 00                	mov    (%eax),%eax
f0102c97:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c9a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c9d:	eb 27                	jmp    f0102cc6 <vprintfmt+0xdf>
f0102c9f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ca2:	85 c0                	test   %eax,%eax
f0102ca4:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102ca9:	0f 49 c8             	cmovns %eax,%ecx
f0102cac:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102caf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cb2:	eb 8c                	jmp    f0102c40 <vprintfmt+0x59>
f0102cb4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102cb7:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102cbe:	eb 80                	jmp    f0102c40 <vprintfmt+0x59>
f0102cc0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102cc3:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102cc6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102cca:	0f 89 70 ff ff ff    	jns    f0102c40 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102cd0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102cd3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102cd6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102cdd:	e9 5e ff ff ff       	jmp    f0102c40 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102ce2:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ce5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102ce8:	e9 53 ff ff ff       	jmp    f0102c40 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102ced:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cf0:	8d 50 04             	lea    0x4(%eax),%edx
f0102cf3:	89 55 14             	mov    %edx,0x14(%ebp)
f0102cf6:	83 ec 08             	sub    $0x8,%esp
f0102cf9:	53                   	push   %ebx
f0102cfa:	ff 30                	pushl  (%eax)
f0102cfc:	ff d6                	call   *%esi
			break;
f0102cfe:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d01:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102d04:	e9 04 ff ff ff       	jmp    f0102c0d <vprintfmt+0x26>

		

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102d09:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d0c:	8d 50 04             	lea    0x4(%eax),%edx
f0102d0f:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d12:	8b 00                	mov    (%eax),%eax
f0102d14:	99                   	cltd   
f0102d15:	31 d0                	xor    %edx,%eax
f0102d17:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102d19:	83 f8 06             	cmp    $0x6,%eax
f0102d1c:	7f 0b                	jg     f0102d29 <vprintfmt+0x142>
f0102d1e:	8b 14 85 50 48 10 f0 	mov    -0xfefb7b0(,%eax,4),%edx
f0102d25:	85 d2                	test   %edx,%edx
f0102d27:	75 18                	jne    f0102d41 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102d29:	50                   	push   %eax
f0102d2a:	68 83 46 10 f0       	push   $0xf0104683
f0102d2f:	53                   	push   %ebx
f0102d30:	56                   	push   %esi
f0102d31:	e8 94 fe ff ff       	call   f0102bca <printfmt>
f0102d36:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d39:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102d3c:	e9 cc fe ff ff       	jmp    f0102c0d <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102d41:	52                   	push   %edx
f0102d42:	68 84 43 10 f0       	push   $0xf0104384
f0102d47:	53                   	push   %ebx
f0102d48:	56                   	push   %esi
f0102d49:	e8 7c fe ff ff       	call   f0102bca <printfmt>
f0102d4e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d51:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d54:	e9 b4 fe ff ff       	jmp    f0102c0d <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102d59:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d5c:	8d 50 04             	lea    0x4(%eax),%edx
f0102d5f:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d62:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102d64:	85 ff                	test   %edi,%edi
f0102d66:	b8 7c 46 10 f0       	mov    $0xf010467c,%eax
f0102d6b:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102d6e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d72:	0f 8e 94 00 00 00    	jle    f0102e0c <vprintfmt+0x225>
f0102d78:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102d7c:	0f 84 98 00 00 00    	je     f0102e1a <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d82:	83 ec 08             	sub    $0x8,%esp
f0102d85:	ff 75 d0             	pushl  -0x30(%ebp)
f0102d88:	57                   	push   %edi
f0102d89:	e8 5f 03 00 00       	call   f01030ed <strnlen>
f0102d8e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d91:	29 c1                	sub    %eax,%ecx
f0102d93:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102d96:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d99:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d9d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102da0:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102da3:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102da5:	eb 0f                	jmp    f0102db6 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102da7:	83 ec 08             	sub    $0x8,%esp
f0102daa:	53                   	push   %ebx
f0102dab:	ff 75 e0             	pushl  -0x20(%ebp)
f0102dae:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102db0:	83 ef 01             	sub    $0x1,%edi
f0102db3:	83 c4 10             	add    $0x10,%esp
f0102db6:	85 ff                	test   %edi,%edi
f0102db8:	7f ed                	jg     f0102da7 <vprintfmt+0x1c0>
f0102dba:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102dbd:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102dc0:	85 c9                	test   %ecx,%ecx
f0102dc2:	b8 00 00 00 00       	mov    $0x0,%eax
f0102dc7:	0f 49 c1             	cmovns %ecx,%eax
f0102dca:	29 c1                	sub    %eax,%ecx
f0102dcc:	89 75 08             	mov    %esi,0x8(%ebp)
f0102dcf:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102dd2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102dd5:	89 cb                	mov    %ecx,%ebx
f0102dd7:	eb 4d                	jmp    f0102e26 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102dd9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102ddd:	74 1b                	je     f0102dfa <vprintfmt+0x213>
f0102ddf:	0f be c0             	movsbl %al,%eax
f0102de2:	83 e8 20             	sub    $0x20,%eax
f0102de5:	83 f8 5e             	cmp    $0x5e,%eax
f0102de8:	76 10                	jbe    f0102dfa <vprintfmt+0x213>
					putch('?', putdat);
f0102dea:	83 ec 08             	sub    $0x8,%esp
f0102ded:	ff 75 0c             	pushl  0xc(%ebp)
f0102df0:	6a 3f                	push   $0x3f
f0102df2:	ff 55 08             	call   *0x8(%ebp)
f0102df5:	83 c4 10             	add    $0x10,%esp
f0102df8:	eb 0d                	jmp    f0102e07 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102dfa:	83 ec 08             	sub    $0x8,%esp
f0102dfd:	ff 75 0c             	pushl  0xc(%ebp)
f0102e00:	52                   	push   %edx
f0102e01:	ff 55 08             	call   *0x8(%ebp)
f0102e04:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102e07:	83 eb 01             	sub    $0x1,%ebx
f0102e0a:	eb 1a                	jmp    f0102e26 <vprintfmt+0x23f>
f0102e0c:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e0f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e12:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e15:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102e18:	eb 0c                	jmp    f0102e26 <vprintfmt+0x23f>
f0102e1a:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e1d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e20:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e23:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102e26:	83 c7 01             	add    $0x1,%edi
f0102e29:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102e2d:	0f be d0             	movsbl %al,%edx
f0102e30:	85 d2                	test   %edx,%edx
f0102e32:	74 23                	je     f0102e57 <vprintfmt+0x270>
f0102e34:	85 f6                	test   %esi,%esi
f0102e36:	78 a1                	js     f0102dd9 <vprintfmt+0x1f2>
f0102e38:	83 ee 01             	sub    $0x1,%esi
f0102e3b:	79 9c                	jns    f0102dd9 <vprintfmt+0x1f2>
f0102e3d:	89 df                	mov    %ebx,%edi
f0102e3f:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e42:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e45:	eb 18                	jmp    f0102e5f <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102e47:	83 ec 08             	sub    $0x8,%esp
f0102e4a:	53                   	push   %ebx
f0102e4b:	6a 20                	push   $0x20
f0102e4d:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102e4f:	83 ef 01             	sub    $0x1,%edi
f0102e52:	83 c4 10             	add    $0x10,%esp
f0102e55:	eb 08                	jmp    f0102e5f <vprintfmt+0x278>
f0102e57:	89 df                	mov    %ebx,%edi
f0102e59:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e5c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e5f:	85 ff                	test   %edi,%edi
f0102e61:	7f e4                	jg     f0102e47 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e63:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e66:	e9 a2 fd ff ff       	jmp    f0102c0d <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e6b:	83 fa 01             	cmp    $0x1,%edx
f0102e6e:	7e 16                	jle    f0102e86 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102e70:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e73:	8d 50 08             	lea    0x8(%eax),%edx
f0102e76:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e79:	8b 50 04             	mov    0x4(%eax),%edx
f0102e7c:	8b 00                	mov    (%eax),%eax
f0102e7e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e81:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102e84:	eb 32                	jmp    f0102eb8 <vprintfmt+0x2d1>
	else if (lflag)
f0102e86:	85 d2                	test   %edx,%edx
f0102e88:	74 18                	je     f0102ea2 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102e8a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e8d:	8d 50 04             	lea    0x4(%eax),%edx
f0102e90:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e93:	8b 00                	mov    (%eax),%eax
f0102e95:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e98:	89 c1                	mov    %eax,%ecx
f0102e9a:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e9d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102ea0:	eb 16                	jmp    f0102eb8 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102ea2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ea5:	8d 50 04             	lea    0x4(%eax),%edx
f0102ea8:	89 55 14             	mov    %edx,0x14(%ebp)
f0102eab:	8b 00                	mov    (%eax),%eax
f0102ead:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102eb0:	89 c1                	mov    %eax,%ecx
f0102eb2:	c1 f9 1f             	sar    $0x1f,%ecx
f0102eb5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102eb8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102ebb:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102ebe:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102ec3:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102ec7:	79 74                	jns    f0102f3d <vprintfmt+0x356>
				putch('-', putdat);
f0102ec9:	83 ec 08             	sub    $0x8,%esp
f0102ecc:	53                   	push   %ebx
f0102ecd:	6a 2d                	push   $0x2d
f0102ecf:	ff d6                	call   *%esi
				num = -(long long) num;
f0102ed1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102ed4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102ed7:	f7 d8                	neg    %eax
f0102ed9:	83 d2 00             	adc    $0x0,%edx
f0102edc:	f7 da                	neg    %edx
f0102ede:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102ee1:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102ee6:	eb 55                	jmp    f0102f3d <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102ee8:	8d 45 14             	lea    0x14(%ebp),%eax
f0102eeb:	e8 83 fc ff ff       	call   f0102b73 <getuint>
			base = 10;
f0102ef0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102ef5:	eb 46                	jmp    f0102f3d <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap,lflag);
f0102ef7:	8d 45 14             	lea    0x14(%ebp),%eax
f0102efa:	e8 74 fc ff ff       	call   f0102b73 <getuint>
			base =8;
f0102eff:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102f04:	eb 37                	jmp    f0102f3d <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102f06:	83 ec 08             	sub    $0x8,%esp
f0102f09:	53                   	push   %ebx
f0102f0a:	6a 30                	push   $0x30
f0102f0c:	ff d6                	call   *%esi
			putch('x', putdat);
f0102f0e:	83 c4 08             	add    $0x8,%esp
f0102f11:	53                   	push   %ebx
f0102f12:	6a 78                	push   $0x78
f0102f14:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102f16:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f19:	8d 50 04             	lea    0x4(%eax),%edx
f0102f1c:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102f1f:	8b 00                	mov    (%eax),%eax
f0102f21:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102f26:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102f29:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102f2e:	eb 0d                	jmp    f0102f3d <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102f30:	8d 45 14             	lea    0x14(%ebp),%eax
f0102f33:	e8 3b fc ff ff       	call   f0102b73 <getuint>
			base = 16;
f0102f38:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102f3d:	83 ec 0c             	sub    $0xc,%esp
f0102f40:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102f44:	57                   	push   %edi
f0102f45:	ff 75 e0             	pushl  -0x20(%ebp)
f0102f48:	51                   	push   %ecx
f0102f49:	52                   	push   %edx
f0102f4a:	50                   	push   %eax
f0102f4b:	89 da                	mov    %ebx,%edx
f0102f4d:	89 f0                	mov    %esi,%eax
f0102f4f:	e8 70 fb ff ff       	call   f0102ac4 <printnum>
			break;
f0102f54:	83 c4 20             	add    $0x20,%esp
f0102f57:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f5a:	e9 ae fc ff ff       	jmp    f0102c0d <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102f5f:	83 ec 08             	sub    $0x8,%esp
f0102f62:	53                   	push   %ebx
f0102f63:	51                   	push   %ecx
f0102f64:	ff d6                	call   *%esi
			break;
f0102f66:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f69:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102f6c:	e9 9c fc ff ff       	jmp    f0102c0d <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102f71:	83 ec 08             	sub    $0x8,%esp
f0102f74:	53                   	push   %ebx
f0102f75:	6a 25                	push   $0x25
f0102f77:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102f79:	83 c4 10             	add    $0x10,%esp
f0102f7c:	eb 03                	jmp    f0102f81 <vprintfmt+0x39a>
f0102f7e:	83 ef 01             	sub    $0x1,%edi
f0102f81:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102f85:	75 f7                	jne    f0102f7e <vprintfmt+0x397>
f0102f87:	e9 81 fc ff ff       	jmp    f0102c0d <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102f8c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f8f:	5b                   	pop    %ebx
f0102f90:	5e                   	pop    %esi
f0102f91:	5f                   	pop    %edi
f0102f92:	5d                   	pop    %ebp
f0102f93:	c3                   	ret    

f0102f94 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f94:	55                   	push   %ebp
f0102f95:	89 e5                	mov    %esp,%ebp
f0102f97:	83 ec 18             	sub    $0x18,%esp
f0102f9a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f9d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102fa0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102fa3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102fa7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102faa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102fb1:	85 c0                	test   %eax,%eax
f0102fb3:	74 26                	je     f0102fdb <vsnprintf+0x47>
f0102fb5:	85 d2                	test   %edx,%edx
f0102fb7:	7e 22                	jle    f0102fdb <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102fb9:	ff 75 14             	pushl  0x14(%ebp)
f0102fbc:	ff 75 10             	pushl  0x10(%ebp)
f0102fbf:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102fc2:	50                   	push   %eax
f0102fc3:	68 ad 2b 10 f0       	push   $0xf0102bad
f0102fc8:	e8 1a fc ff ff       	call   f0102be7 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102fcd:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102fd0:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102fd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fd6:	83 c4 10             	add    $0x10,%esp
f0102fd9:	eb 05                	jmp    f0102fe0 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102fdb:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102fe0:	c9                   	leave  
f0102fe1:	c3                   	ret    

f0102fe2 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102fe2:	55                   	push   %ebp
f0102fe3:	89 e5                	mov    %esp,%ebp
f0102fe5:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102fe8:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102feb:	50                   	push   %eax
f0102fec:	ff 75 10             	pushl  0x10(%ebp)
f0102fef:	ff 75 0c             	pushl  0xc(%ebp)
f0102ff2:	ff 75 08             	pushl  0x8(%ebp)
f0102ff5:	e8 9a ff ff ff       	call   f0102f94 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102ffa:	c9                   	leave  
f0102ffb:	c3                   	ret    

f0102ffc <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102ffc:	55                   	push   %ebp
f0102ffd:	89 e5                	mov    %esp,%ebp
f0102fff:	57                   	push   %edi
f0103000:	56                   	push   %esi
f0103001:	53                   	push   %ebx
f0103002:	83 ec 0c             	sub    $0xc,%esp
f0103005:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103008:	85 c0                	test   %eax,%eax
f010300a:	74 11                	je     f010301d <readline+0x21>
		cprintf("%s", prompt);
f010300c:	83 ec 08             	sub    $0x8,%esp
f010300f:	50                   	push   %eax
f0103010:	68 84 43 10 f0       	push   $0xf0104384
f0103015:	e8 75 f7 ff ff       	call   f010278f <cprintf>
f010301a:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010301d:	83 ec 0c             	sub    $0xc,%esp
f0103020:	6a 00                	push   $0x0
f0103022:	e8 2d d6 ff ff       	call   f0100654 <iscons>
f0103027:	89 c7                	mov    %eax,%edi
f0103029:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010302c:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103031:	e8 0d d6 ff ff       	call   f0100643 <getchar>
f0103036:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103038:	85 c0                	test   %eax,%eax
f010303a:	79 18                	jns    f0103054 <readline+0x58>
			cprintf("read error: %e\n", c);
f010303c:	83 ec 08             	sub    $0x8,%esp
f010303f:	50                   	push   %eax
f0103040:	68 6c 48 10 f0       	push   $0xf010486c
f0103045:	e8 45 f7 ff ff       	call   f010278f <cprintf>
			return NULL;
f010304a:	83 c4 10             	add    $0x10,%esp
f010304d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103052:	eb 79                	jmp    f01030cd <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103054:	83 f8 08             	cmp    $0x8,%eax
f0103057:	0f 94 c2             	sete   %dl
f010305a:	83 f8 7f             	cmp    $0x7f,%eax
f010305d:	0f 94 c0             	sete   %al
f0103060:	08 c2                	or     %al,%dl
f0103062:	74 1a                	je     f010307e <readline+0x82>
f0103064:	85 f6                	test   %esi,%esi
f0103066:	7e 16                	jle    f010307e <readline+0x82>
			if (echoing)
f0103068:	85 ff                	test   %edi,%edi
f010306a:	74 0d                	je     f0103079 <readline+0x7d>
				cputchar('\b');
f010306c:	83 ec 0c             	sub    $0xc,%esp
f010306f:	6a 08                	push   $0x8
f0103071:	e8 bd d5 ff ff       	call   f0100633 <cputchar>
f0103076:	83 c4 10             	add    $0x10,%esp
			i--;
f0103079:	83 ee 01             	sub    $0x1,%esi
f010307c:	eb b3                	jmp    f0103031 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010307e:	83 fb 1f             	cmp    $0x1f,%ebx
f0103081:	7e 23                	jle    f01030a6 <readline+0xaa>
f0103083:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103089:	7f 1b                	jg     f01030a6 <readline+0xaa>
			if (echoing)
f010308b:	85 ff                	test   %edi,%edi
f010308d:	74 0c                	je     f010309b <readline+0x9f>
				cputchar(c);
f010308f:	83 ec 0c             	sub    $0xc,%esp
f0103092:	53                   	push   %ebx
f0103093:	e8 9b d5 ff ff       	call   f0100633 <cputchar>
f0103098:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010309b:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f01030a1:	8d 76 01             	lea    0x1(%esi),%esi
f01030a4:	eb 8b                	jmp    f0103031 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01030a6:	83 fb 0a             	cmp    $0xa,%ebx
f01030a9:	74 05                	je     f01030b0 <readline+0xb4>
f01030ab:	83 fb 0d             	cmp    $0xd,%ebx
f01030ae:	75 81                	jne    f0103031 <readline+0x35>
			if (echoing)
f01030b0:	85 ff                	test   %edi,%edi
f01030b2:	74 0d                	je     f01030c1 <readline+0xc5>
				cputchar('\n');
f01030b4:	83 ec 0c             	sub    $0xc,%esp
f01030b7:	6a 0a                	push   $0xa
f01030b9:	e8 75 d5 ff ff       	call   f0100633 <cputchar>
f01030be:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01030c1:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f01030c8:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f01030cd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030d0:	5b                   	pop    %ebx
f01030d1:	5e                   	pop    %esi
f01030d2:	5f                   	pop    %edi
f01030d3:	5d                   	pop    %ebp
f01030d4:	c3                   	ret    

f01030d5 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01030d5:	55                   	push   %ebp
f01030d6:	89 e5                	mov    %esp,%ebp
f01030d8:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01030db:	b8 00 00 00 00       	mov    $0x0,%eax
f01030e0:	eb 03                	jmp    f01030e5 <strlen+0x10>
		n++;
f01030e2:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01030e5:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01030e9:	75 f7                	jne    f01030e2 <strlen+0xd>
		n++;
	return n;
}
f01030eb:	5d                   	pop    %ebp
f01030ec:	c3                   	ret    

f01030ed <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01030ed:	55                   	push   %ebp
f01030ee:	89 e5                	mov    %esp,%ebp
f01030f0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030f3:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030f6:	ba 00 00 00 00       	mov    $0x0,%edx
f01030fb:	eb 03                	jmp    f0103100 <strnlen+0x13>
		n++;
f01030fd:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103100:	39 c2                	cmp    %eax,%edx
f0103102:	74 08                	je     f010310c <strnlen+0x1f>
f0103104:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103108:	75 f3                	jne    f01030fd <strnlen+0x10>
f010310a:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010310c:	5d                   	pop    %ebp
f010310d:	c3                   	ret    

f010310e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010310e:	55                   	push   %ebp
f010310f:	89 e5                	mov    %esp,%ebp
f0103111:	53                   	push   %ebx
f0103112:	8b 45 08             	mov    0x8(%ebp),%eax
f0103115:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103118:	89 c2                	mov    %eax,%edx
f010311a:	83 c2 01             	add    $0x1,%edx
f010311d:	83 c1 01             	add    $0x1,%ecx
f0103120:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103124:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103127:	84 db                	test   %bl,%bl
f0103129:	75 ef                	jne    f010311a <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010312b:	5b                   	pop    %ebx
f010312c:	5d                   	pop    %ebp
f010312d:	c3                   	ret    

f010312e <strcat>:

char *
strcat(char *dst, const char *src)
{
f010312e:	55                   	push   %ebp
f010312f:	89 e5                	mov    %esp,%ebp
f0103131:	53                   	push   %ebx
f0103132:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103135:	53                   	push   %ebx
f0103136:	e8 9a ff ff ff       	call   f01030d5 <strlen>
f010313b:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010313e:	ff 75 0c             	pushl  0xc(%ebp)
f0103141:	01 d8                	add    %ebx,%eax
f0103143:	50                   	push   %eax
f0103144:	e8 c5 ff ff ff       	call   f010310e <strcpy>
	return dst;
}
f0103149:	89 d8                	mov    %ebx,%eax
f010314b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010314e:	c9                   	leave  
f010314f:	c3                   	ret    

f0103150 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103150:	55                   	push   %ebp
f0103151:	89 e5                	mov    %esp,%ebp
f0103153:	56                   	push   %esi
f0103154:	53                   	push   %ebx
f0103155:	8b 75 08             	mov    0x8(%ebp),%esi
f0103158:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010315b:	89 f3                	mov    %esi,%ebx
f010315d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103160:	89 f2                	mov    %esi,%edx
f0103162:	eb 0f                	jmp    f0103173 <strncpy+0x23>
		*dst++ = *src;
f0103164:	83 c2 01             	add    $0x1,%edx
f0103167:	0f b6 01             	movzbl (%ecx),%eax
f010316a:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010316d:	80 39 01             	cmpb   $0x1,(%ecx)
f0103170:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103173:	39 da                	cmp    %ebx,%edx
f0103175:	75 ed                	jne    f0103164 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103177:	89 f0                	mov    %esi,%eax
f0103179:	5b                   	pop    %ebx
f010317a:	5e                   	pop    %esi
f010317b:	5d                   	pop    %ebp
f010317c:	c3                   	ret    

f010317d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010317d:	55                   	push   %ebp
f010317e:	89 e5                	mov    %esp,%ebp
f0103180:	56                   	push   %esi
f0103181:	53                   	push   %ebx
f0103182:	8b 75 08             	mov    0x8(%ebp),%esi
f0103185:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103188:	8b 55 10             	mov    0x10(%ebp),%edx
f010318b:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010318d:	85 d2                	test   %edx,%edx
f010318f:	74 21                	je     f01031b2 <strlcpy+0x35>
f0103191:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103195:	89 f2                	mov    %esi,%edx
f0103197:	eb 09                	jmp    f01031a2 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103199:	83 c2 01             	add    $0x1,%edx
f010319c:	83 c1 01             	add    $0x1,%ecx
f010319f:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01031a2:	39 c2                	cmp    %eax,%edx
f01031a4:	74 09                	je     f01031af <strlcpy+0x32>
f01031a6:	0f b6 19             	movzbl (%ecx),%ebx
f01031a9:	84 db                	test   %bl,%bl
f01031ab:	75 ec                	jne    f0103199 <strlcpy+0x1c>
f01031ad:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01031af:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01031b2:	29 f0                	sub    %esi,%eax
}
f01031b4:	5b                   	pop    %ebx
f01031b5:	5e                   	pop    %esi
f01031b6:	5d                   	pop    %ebp
f01031b7:	c3                   	ret    

f01031b8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01031b8:	55                   	push   %ebp
f01031b9:	89 e5                	mov    %esp,%ebp
f01031bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031be:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01031c1:	eb 06                	jmp    f01031c9 <strcmp+0x11>
		p++, q++;
f01031c3:	83 c1 01             	add    $0x1,%ecx
f01031c6:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01031c9:	0f b6 01             	movzbl (%ecx),%eax
f01031cc:	84 c0                	test   %al,%al
f01031ce:	74 04                	je     f01031d4 <strcmp+0x1c>
f01031d0:	3a 02                	cmp    (%edx),%al
f01031d2:	74 ef                	je     f01031c3 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01031d4:	0f b6 c0             	movzbl %al,%eax
f01031d7:	0f b6 12             	movzbl (%edx),%edx
f01031da:	29 d0                	sub    %edx,%eax
}
f01031dc:	5d                   	pop    %ebp
f01031dd:	c3                   	ret    

f01031de <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01031de:	55                   	push   %ebp
f01031df:	89 e5                	mov    %esp,%ebp
f01031e1:	53                   	push   %ebx
f01031e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01031e5:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031e8:	89 c3                	mov    %eax,%ebx
f01031ea:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01031ed:	eb 06                	jmp    f01031f5 <strncmp+0x17>
		n--, p++, q++;
f01031ef:	83 c0 01             	add    $0x1,%eax
f01031f2:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01031f5:	39 d8                	cmp    %ebx,%eax
f01031f7:	74 15                	je     f010320e <strncmp+0x30>
f01031f9:	0f b6 08             	movzbl (%eax),%ecx
f01031fc:	84 c9                	test   %cl,%cl
f01031fe:	74 04                	je     f0103204 <strncmp+0x26>
f0103200:	3a 0a                	cmp    (%edx),%cl
f0103202:	74 eb                	je     f01031ef <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103204:	0f b6 00             	movzbl (%eax),%eax
f0103207:	0f b6 12             	movzbl (%edx),%edx
f010320a:	29 d0                	sub    %edx,%eax
f010320c:	eb 05                	jmp    f0103213 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010320e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103213:	5b                   	pop    %ebx
f0103214:	5d                   	pop    %ebp
f0103215:	c3                   	ret    

f0103216 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103216:	55                   	push   %ebp
f0103217:	89 e5                	mov    %esp,%ebp
f0103219:	8b 45 08             	mov    0x8(%ebp),%eax
f010321c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103220:	eb 07                	jmp    f0103229 <strchr+0x13>
		if (*s == c)
f0103222:	38 ca                	cmp    %cl,%dl
f0103224:	74 0f                	je     f0103235 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103226:	83 c0 01             	add    $0x1,%eax
f0103229:	0f b6 10             	movzbl (%eax),%edx
f010322c:	84 d2                	test   %dl,%dl
f010322e:	75 f2                	jne    f0103222 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103230:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103235:	5d                   	pop    %ebp
f0103236:	c3                   	ret    

f0103237 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103237:	55                   	push   %ebp
f0103238:	89 e5                	mov    %esp,%ebp
f010323a:	8b 45 08             	mov    0x8(%ebp),%eax
f010323d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103241:	eb 03                	jmp    f0103246 <strfind+0xf>
f0103243:	83 c0 01             	add    $0x1,%eax
f0103246:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103249:	38 ca                	cmp    %cl,%dl
f010324b:	74 04                	je     f0103251 <strfind+0x1a>
f010324d:	84 d2                	test   %dl,%dl
f010324f:	75 f2                	jne    f0103243 <strfind+0xc>
			break;
	return (char *) s;
}
f0103251:	5d                   	pop    %ebp
f0103252:	c3                   	ret    

f0103253 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103253:	55                   	push   %ebp
f0103254:	89 e5                	mov    %esp,%ebp
f0103256:	57                   	push   %edi
f0103257:	56                   	push   %esi
f0103258:	53                   	push   %ebx
f0103259:	8b 7d 08             	mov    0x8(%ebp),%edi
f010325c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010325f:	85 c9                	test   %ecx,%ecx
f0103261:	74 36                	je     f0103299 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103263:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103269:	75 28                	jne    f0103293 <memset+0x40>
f010326b:	f6 c1 03             	test   $0x3,%cl
f010326e:	75 23                	jne    f0103293 <memset+0x40>
		c &= 0xFF;
f0103270:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103274:	89 d3                	mov    %edx,%ebx
f0103276:	c1 e3 08             	shl    $0x8,%ebx
f0103279:	89 d6                	mov    %edx,%esi
f010327b:	c1 e6 18             	shl    $0x18,%esi
f010327e:	89 d0                	mov    %edx,%eax
f0103280:	c1 e0 10             	shl    $0x10,%eax
f0103283:	09 f0                	or     %esi,%eax
f0103285:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103287:	89 d8                	mov    %ebx,%eax
f0103289:	09 d0                	or     %edx,%eax
f010328b:	c1 e9 02             	shr    $0x2,%ecx
f010328e:	fc                   	cld    
f010328f:	f3 ab                	rep stos %eax,%es:(%edi)
f0103291:	eb 06                	jmp    f0103299 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103293:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103296:	fc                   	cld    
f0103297:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103299:	89 f8                	mov    %edi,%eax
f010329b:	5b                   	pop    %ebx
f010329c:	5e                   	pop    %esi
f010329d:	5f                   	pop    %edi
f010329e:	5d                   	pop    %ebp
f010329f:	c3                   	ret    

f01032a0 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01032a0:	55                   	push   %ebp
f01032a1:	89 e5                	mov    %esp,%ebp
f01032a3:	57                   	push   %edi
f01032a4:	56                   	push   %esi
f01032a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01032a8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01032ab:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01032ae:	39 c6                	cmp    %eax,%esi
f01032b0:	73 35                	jae    f01032e7 <memmove+0x47>
f01032b2:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01032b5:	39 d0                	cmp    %edx,%eax
f01032b7:	73 2e                	jae    f01032e7 <memmove+0x47>
		s += n;
		d += n;
f01032b9:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032bc:	89 d6                	mov    %edx,%esi
f01032be:	09 fe                	or     %edi,%esi
f01032c0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01032c6:	75 13                	jne    f01032db <memmove+0x3b>
f01032c8:	f6 c1 03             	test   $0x3,%cl
f01032cb:	75 0e                	jne    f01032db <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01032cd:	83 ef 04             	sub    $0x4,%edi
f01032d0:	8d 72 fc             	lea    -0x4(%edx),%esi
f01032d3:	c1 e9 02             	shr    $0x2,%ecx
f01032d6:	fd                   	std    
f01032d7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032d9:	eb 09                	jmp    f01032e4 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01032db:	83 ef 01             	sub    $0x1,%edi
f01032de:	8d 72 ff             	lea    -0x1(%edx),%esi
f01032e1:	fd                   	std    
f01032e2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01032e4:	fc                   	cld    
f01032e5:	eb 1d                	jmp    f0103304 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032e7:	89 f2                	mov    %esi,%edx
f01032e9:	09 c2                	or     %eax,%edx
f01032eb:	f6 c2 03             	test   $0x3,%dl
f01032ee:	75 0f                	jne    f01032ff <memmove+0x5f>
f01032f0:	f6 c1 03             	test   $0x3,%cl
f01032f3:	75 0a                	jne    f01032ff <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01032f5:	c1 e9 02             	shr    $0x2,%ecx
f01032f8:	89 c7                	mov    %eax,%edi
f01032fa:	fc                   	cld    
f01032fb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032fd:	eb 05                	jmp    f0103304 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01032ff:	89 c7                	mov    %eax,%edi
f0103301:	fc                   	cld    
f0103302:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103304:	5e                   	pop    %esi
f0103305:	5f                   	pop    %edi
f0103306:	5d                   	pop    %ebp
f0103307:	c3                   	ret    

f0103308 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103308:	55                   	push   %ebp
f0103309:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010330b:	ff 75 10             	pushl  0x10(%ebp)
f010330e:	ff 75 0c             	pushl  0xc(%ebp)
f0103311:	ff 75 08             	pushl  0x8(%ebp)
f0103314:	e8 87 ff ff ff       	call   f01032a0 <memmove>
}
f0103319:	c9                   	leave  
f010331a:	c3                   	ret    

f010331b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010331b:	55                   	push   %ebp
f010331c:	89 e5                	mov    %esp,%ebp
f010331e:	56                   	push   %esi
f010331f:	53                   	push   %ebx
f0103320:	8b 45 08             	mov    0x8(%ebp),%eax
f0103323:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103326:	89 c6                	mov    %eax,%esi
f0103328:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010332b:	eb 1a                	jmp    f0103347 <memcmp+0x2c>
		if (*s1 != *s2)
f010332d:	0f b6 08             	movzbl (%eax),%ecx
f0103330:	0f b6 1a             	movzbl (%edx),%ebx
f0103333:	38 d9                	cmp    %bl,%cl
f0103335:	74 0a                	je     f0103341 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103337:	0f b6 c1             	movzbl %cl,%eax
f010333a:	0f b6 db             	movzbl %bl,%ebx
f010333d:	29 d8                	sub    %ebx,%eax
f010333f:	eb 0f                	jmp    f0103350 <memcmp+0x35>
		s1++, s2++;
f0103341:	83 c0 01             	add    $0x1,%eax
f0103344:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103347:	39 f0                	cmp    %esi,%eax
f0103349:	75 e2                	jne    f010332d <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010334b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103350:	5b                   	pop    %ebx
f0103351:	5e                   	pop    %esi
f0103352:	5d                   	pop    %ebp
f0103353:	c3                   	ret    

f0103354 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103354:	55                   	push   %ebp
f0103355:	89 e5                	mov    %esp,%ebp
f0103357:	53                   	push   %ebx
f0103358:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010335b:	89 c1                	mov    %eax,%ecx
f010335d:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103360:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103364:	eb 0a                	jmp    f0103370 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103366:	0f b6 10             	movzbl (%eax),%edx
f0103369:	39 da                	cmp    %ebx,%edx
f010336b:	74 07                	je     f0103374 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010336d:	83 c0 01             	add    $0x1,%eax
f0103370:	39 c8                	cmp    %ecx,%eax
f0103372:	72 f2                	jb     f0103366 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103374:	5b                   	pop    %ebx
f0103375:	5d                   	pop    %ebp
f0103376:	c3                   	ret    

f0103377 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103377:	55                   	push   %ebp
f0103378:	89 e5                	mov    %esp,%ebp
f010337a:	57                   	push   %edi
f010337b:	56                   	push   %esi
f010337c:	53                   	push   %ebx
f010337d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103380:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103383:	eb 03                	jmp    f0103388 <strtol+0x11>
		s++;
f0103385:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103388:	0f b6 01             	movzbl (%ecx),%eax
f010338b:	3c 20                	cmp    $0x20,%al
f010338d:	74 f6                	je     f0103385 <strtol+0xe>
f010338f:	3c 09                	cmp    $0x9,%al
f0103391:	74 f2                	je     f0103385 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103393:	3c 2b                	cmp    $0x2b,%al
f0103395:	75 0a                	jne    f01033a1 <strtol+0x2a>
		s++;
f0103397:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010339a:	bf 00 00 00 00       	mov    $0x0,%edi
f010339f:	eb 11                	jmp    f01033b2 <strtol+0x3b>
f01033a1:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01033a6:	3c 2d                	cmp    $0x2d,%al
f01033a8:	75 08                	jne    f01033b2 <strtol+0x3b>
		s++, neg = 1;
f01033aa:	83 c1 01             	add    $0x1,%ecx
f01033ad:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01033b2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01033b8:	75 15                	jne    f01033cf <strtol+0x58>
f01033ba:	80 39 30             	cmpb   $0x30,(%ecx)
f01033bd:	75 10                	jne    f01033cf <strtol+0x58>
f01033bf:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01033c3:	75 7c                	jne    f0103441 <strtol+0xca>
		s += 2, base = 16;
f01033c5:	83 c1 02             	add    $0x2,%ecx
f01033c8:	bb 10 00 00 00       	mov    $0x10,%ebx
f01033cd:	eb 16                	jmp    f01033e5 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01033cf:	85 db                	test   %ebx,%ebx
f01033d1:	75 12                	jne    f01033e5 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01033d3:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033d8:	80 39 30             	cmpb   $0x30,(%ecx)
f01033db:	75 08                	jne    f01033e5 <strtol+0x6e>
		s++, base = 8;
f01033dd:	83 c1 01             	add    $0x1,%ecx
f01033e0:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01033e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01033ea:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01033ed:	0f b6 11             	movzbl (%ecx),%edx
f01033f0:	8d 72 d0             	lea    -0x30(%edx),%esi
f01033f3:	89 f3                	mov    %esi,%ebx
f01033f5:	80 fb 09             	cmp    $0x9,%bl
f01033f8:	77 08                	ja     f0103402 <strtol+0x8b>
			dig = *s - '0';
f01033fa:	0f be d2             	movsbl %dl,%edx
f01033fd:	83 ea 30             	sub    $0x30,%edx
f0103400:	eb 22                	jmp    f0103424 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103402:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103405:	89 f3                	mov    %esi,%ebx
f0103407:	80 fb 19             	cmp    $0x19,%bl
f010340a:	77 08                	ja     f0103414 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010340c:	0f be d2             	movsbl %dl,%edx
f010340f:	83 ea 57             	sub    $0x57,%edx
f0103412:	eb 10                	jmp    f0103424 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103414:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103417:	89 f3                	mov    %esi,%ebx
f0103419:	80 fb 19             	cmp    $0x19,%bl
f010341c:	77 16                	ja     f0103434 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010341e:	0f be d2             	movsbl %dl,%edx
f0103421:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103424:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103427:	7d 0b                	jge    f0103434 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103429:	83 c1 01             	add    $0x1,%ecx
f010342c:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103430:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103432:	eb b9                	jmp    f01033ed <strtol+0x76>

	if (endptr)
f0103434:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103438:	74 0d                	je     f0103447 <strtol+0xd0>
		*endptr = (char *) s;
f010343a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010343d:	89 0e                	mov    %ecx,(%esi)
f010343f:	eb 06                	jmp    f0103447 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103441:	85 db                	test   %ebx,%ebx
f0103443:	74 98                	je     f01033dd <strtol+0x66>
f0103445:	eb 9e                	jmp    f01033e5 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103447:	89 c2                	mov    %eax,%edx
f0103449:	f7 da                	neg    %edx
f010344b:	85 ff                	test   %edi,%edi
f010344d:	0f 45 c2             	cmovne %edx,%eax
}
f0103450:	5b                   	pop    %ebx
f0103451:	5e                   	pop    %esi
f0103452:	5f                   	pop    %edi
f0103453:	5d                   	pop    %ebp
f0103454:	c3                   	ret    
f0103455:	66 90                	xchg   %ax,%ax
f0103457:	66 90                	xchg   %ax,%ax
f0103459:	66 90                	xchg   %ax,%ax
f010345b:	66 90                	xchg   %ax,%ax
f010345d:	66 90                	xchg   %ax,%ax
f010345f:	90                   	nop

f0103460 <__udivdi3>:
f0103460:	55                   	push   %ebp
f0103461:	57                   	push   %edi
f0103462:	56                   	push   %esi
f0103463:	53                   	push   %ebx
f0103464:	83 ec 1c             	sub    $0x1c,%esp
f0103467:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010346b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010346f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103473:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103477:	85 f6                	test   %esi,%esi
f0103479:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010347d:	89 ca                	mov    %ecx,%edx
f010347f:	89 f8                	mov    %edi,%eax
f0103481:	75 3d                	jne    f01034c0 <__udivdi3+0x60>
f0103483:	39 cf                	cmp    %ecx,%edi
f0103485:	0f 87 c5 00 00 00    	ja     f0103550 <__udivdi3+0xf0>
f010348b:	85 ff                	test   %edi,%edi
f010348d:	89 fd                	mov    %edi,%ebp
f010348f:	75 0b                	jne    f010349c <__udivdi3+0x3c>
f0103491:	b8 01 00 00 00       	mov    $0x1,%eax
f0103496:	31 d2                	xor    %edx,%edx
f0103498:	f7 f7                	div    %edi
f010349a:	89 c5                	mov    %eax,%ebp
f010349c:	89 c8                	mov    %ecx,%eax
f010349e:	31 d2                	xor    %edx,%edx
f01034a0:	f7 f5                	div    %ebp
f01034a2:	89 c1                	mov    %eax,%ecx
f01034a4:	89 d8                	mov    %ebx,%eax
f01034a6:	89 cf                	mov    %ecx,%edi
f01034a8:	f7 f5                	div    %ebp
f01034aa:	89 c3                	mov    %eax,%ebx
f01034ac:	89 d8                	mov    %ebx,%eax
f01034ae:	89 fa                	mov    %edi,%edx
f01034b0:	83 c4 1c             	add    $0x1c,%esp
f01034b3:	5b                   	pop    %ebx
f01034b4:	5e                   	pop    %esi
f01034b5:	5f                   	pop    %edi
f01034b6:	5d                   	pop    %ebp
f01034b7:	c3                   	ret    
f01034b8:	90                   	nop
f01034b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034c0:	39 ce                	cmp    %ecx,%esi
f01034c2:	77 74                	ja     f0103538 <__udivdi3+0xd8>
f01034c4:	0f bd fe             	bsr    %esi,%edi
f01034c7:	83 f7 1f             	xor    $0x1f,%edi
f01034ca:	0f 84 98 00 00 00    	je     f0103568 <__udivdi3+0x108>
f01034d0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01034d5:	89 f9                	mov    %edi,%ecx
f01034d7:	89 c5                	mov    %eax,%ebp
f01034d9:	29 fb                	sub    %edi,%ebx
f01034db:	d3 e6                	shl    %cl,%esi
f01034dd:	89 d9                	mov    %ebx,%ecx
f01034df:	d3 ed                	shr    %cl,%ebp
f01034e1:	89 f9                	mov    %edi,%ecx
f01034e3:	d3 e0                	shl    %cl,%eax
f01034e5:	09 ee                	or     %ebp,%esi
f01034e7:	89 d9                	mov    %ebx,%ecx
f01034e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034ed:	89 d5                	mov    %edx,%ebp
f01034ef:	8b 44 24 08          	mov    0x8(%esp),%eax
f01034f3:	d3 ed                	shr    %cl,%ebp
f01034f5:	89 f9                	mov    %edi,%ecx
f01034f7:	d3 e2                	shl    %cl,%edx
f01034f9:	89 d9                	mov    %ebx,%ecx
f01034fb:	d3 e8                	shr    %cl,%eax
f01034fd:	09 c2                	or     %eax,%edx
f01034ff:	89 d0                	mov    %edx,%eax
f0103501:	89 ea                	mov    %ebp,%edx
f0103503:	f7 f6                	div    %esi
f0103505:	89 d5                	mov    %edx,%ebp
f0103507:	89 c3                	mov    %eax,%ebx
f0103509:	f7 64 24 0c          	mull   0xc(%esp)
f010350d:	39 d5                	cmp    %edx,%ebp
f010350f:	72 10                	jb     f0103521 <__udivdi3+0xc1>
f0103511:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103515:	89 f9                	mov    %edi,%ecx
f0103517:	d3 e6                	shl    %cl,%esi
f0103519:	39 c6                	cmp    %eax,%esi
f010351b:	73 07                	jae    f0103524 <__udivdi3+0xc4>
f010351d:	39 d5                	cmp    %edx,%ebp
f010351f:	75 03                	jne    f0103524 <__udivdi3+0xc4>
f0103521:	83 eb 01             	sub    $0x1,%ebx
f0103524:	31 ff                	xor    %edi,%edi
f0103526:	89 d8                	mov    %ebx,%eax
f0103528:	89 fa                	mov    %edi,%edx
f010352a:	83 c4 1c             	add    $0x1c,%esp
f010352d:	5b                   	pop    %ebx
f010352e:	5e                   	pop    %esi
f010352f:	5f                   	pop    %edi
f0103530:	5d                   	pop    %ebp
f0103531:	c3                   	ret    
f0103532:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103538:	31 ff                	xor    %edi,%edi
f010353a:	31 db                	xor    %ebx,%ebx
f010353c:	89 d8                	mov    %ebx,%eax
f010353e:	89 fa                	mov    %edi,%edx
f0103540:	83 c4 1c             	add    $0x1c,%esp
f0103543:	5b                   	pop    %ebx
f0103544:	5e                   	pop    %esi
f0103545:	5f                   	pop    %edi
f0103546:	5d                   	pop    %ebp
f0103547:	c3                   	ret    
f0103548:	90                   	nop
f0103549:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103550:	89 d8                	mov    %ebx,%eax
f0103552:	f7 f7                	div    %edi
f0103554:	31 ff                	xor    %edi,%edi
f0103556:	89 c3                	mov    %eax,%ebx
f0103558:	89 d8                	mov    %ebx,%eax
f010355a:	89 fa                	mov    %edi,%edx
f010355c:	83 c4 1c             	add    $0x1c,%esp
f010355f:	5b                   	pop    %ebx
f0103560:	5e                   	pop    %esi
f0103561:	5f                   	pop    %edi
f0103562:	5d                   	pop    %ebp
f0103563:	c3                   	ret    
f0103564:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103568:	39 ce                	cmp    %ecx,%esi
f010356a:	72 0c                	jb     f0103578 <__udivdi3+0x118>
f010356c:	31 db                	xor    %ebx,%ebx
f010356e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103572:	0f 87 34 ff ff ff    	ja     f01034ac <__udivdi3+0x4c>
f0103578:	bb 01 00 00 00       	mov    $0x1,%ebx
f010357d:	e9 2a ff ff ff       	jmp    f01034ac <__udivdi3+0x4c>
f0103582:	66 90                	xchg   %ax,%ax
f0103584:	66 90                	xchg   %ax,%ax
f0103586:	66 90                	xchg   %ax,%ax
f0103588:	66 90                	xchg   %ax,%ax
f010358a:	66 90                	xchg   %ax,%ax
f010358c:	66 90                	xchg   %ax,%ax
f010358e:	66 90                	xchg   %ax,%ax

f0103590 <__umoddi3>:
f0103590:	55                   	push   %ebp
f0103591:	57                   	push   %edi
f0103592:	56                   	push   %esi
f0103593:	53                   	push   %ebx
f0103594:	83 ec 1c             	sub    $0x1c,%esp
f0103597:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010359b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010359f:	8b 74 24 34          	mov    0x34(%esp),%esi
f01035a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01035a7:	85 d2                	test   %edx,%edx
f01035a9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01035ad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035b1:	89 f3                	mov    %esi,%ebx
f01035b3:	89 3c 24             	mov    %edi,(%esp)
f01035b6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035ba:	75 1c                	jne    f01035d8 <__umoddi3+0x48>
f01035bc:	39 f7                	cmp    %esi,%edi
f01035be:	76 50                	jbe    f0103610 <__umoddi3+0x80>
f01035c0:	89 c8                	mov    %ecx,%eax
f01035c2:	89 f2                	mov    %esi,%edx
f01035c4:	f7 f7                	div    %edi
f01035c6:	89 d0                	mov    %edx,%eax
f01035c8:	31 d2                	xor    %edx,%edx
f01035ca:	83 c4 1c             	add    $0x1c,%esp
f01035cd:	5b                   	pop    %ebx
f01035ce:	5e                   	pop    %esi
f01035cf:	5f                   	pop    %edi
f01035d0:	5d                   	pop    %ebp
f01035d1:	c3                   	ret    
f01035d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01035d8:	39 f2                	cmp    %esi,%edx
f01035da:	89 d0                	mov    %edx,%eax
f01035dc:	77 52                	ja     f0103630 <__umoddi3+0xa0>
f01035de:	0f bd ea             	bsr    %edx,%ebp
f01035e1:	83 f5 1f             	xor    $0x1f,%ebp
f01035e4:	75 5a                	jne    f0103640 <__umoddi3+0xb0>
f01035e6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01035ea:	0f 82 e0 00 00 00    	jb     f01036d0 <__umoddi3+0x140>
f01035f0:	39 0c 24             	cmp    %ecx,(%esp)
f01035f3:	0f 86 d7 00 00 00    	jbe    f01036d0 <__umoddi3+0x140>
f01035f9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01035fd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103601:	83 c4 1c             	add    $0x1c,%esp
f0103604:	5b                   	pop    %ebx
f0103605:	5e                   	pop    %esi
f0103606:	5f                   	pop    %edi
f0103607:	5d                   	pop    %ebp
f0103608:	c3                   	ret    
f0103609:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103610:	85 ff                	test   %edi,%edi
f0103612:	89 fd                	mov    %edi,%ebp
f0103614:	75 0b                	jne    f0103621 <__umoddi3+0x91>
f0103616:	b8 01 00 00 00       	mov    $0x1,%eax
f010361b:	31 d2                	xor    %edx,%edx
f010361d:	f7 f7                	div    %edi
f010361f:	89 c5                	mov    %eax,%ebp
f0103621:	89 f0                	mov    %esi,%eax
f0103623:	31 d2                	xor    %edx,%edx
f0103625:	f7 f5                	div    %ebp
f0103627:	89 c8                	mov    %ecx,%eax
f0103629:	f7 f5                	div    %ebp
f010362b:	89 d0                	mov    %edx,%eax
f010362d:	eb 99                	jmp    f01035c8 <__umoddi3+0x38>
f010362f:	90                   	nop
f0103630:	89 c8                	mov    %ecx,%eax
f0103632:	89 f2                	mov    %esi,%edx
f0103634:	83 c4 1c             	add    $0x1c,%esp
f0103637:	5b                   	pop    %ebx
f0103638:	5e                   	pop    %esi
f0103639:	5f                   	pop    %edi
f010363a:	5d                   	pop    %ebp
f010363b:	c3                   	ret    
f010363c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103640:	8b 34 24             	mov    (%esp),%esi
f0103643:	bf 20 00 00 00       	mov    $0x20,%edi
f0103648:	89 e9                	mov    %ebp,%ecx
f010364a:	29 ef                	sub    %ebp,%edi
f010364c:	d3 e0                	shl    %cl,%eax
f010364e:	89 f9                	mov    %edi,%ecx
f0103650:	89 f2                	mov    %esi,%edx
f0103652:	d3 ea                	shr    %cl,%edx
f0103654:	89 e9                	mov    %ebp,%ecx
f0103656:	09 c2                	or     %eax,%edx
f0103658:	89 d8                	mov    %ebx,%eax
f010365a:	89 14 24             	mov    %edx,(%esp)
f010365d:	89 f2                	mov    %esi,%edx
f010365f:	d3 e2                	shl    %cl,%edx
f0103661:	89 f9                	mov    %edi,%ecx
f0103663:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103667:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010366b:	d3 e8                	shr    %cl,%eax
f010366d:	89 e9                	mov    %ebp,%ecx
f010366f:	89 c6                	mov    %eax,%esi
f0103671:	d3 e3                	shl    %cl,%ebx
f0103673:	89 f9                	mov    %edi,%ecx
f0103675:	89 d0                	mov    %edx,%eax
f0103677:	d3 e8                	shr    %cl,%eax
f0103679:	89 e9                	mov    %ebp,%ecx
f010367b:	09 d8                	or     %ebx,%eax
f010367d:	89 d3                	mov    %edx,%ebx
f010367f:	89 f2                	mov    %esi,%edx
f0103681:	f7 34 24             	divl   (%esp)
f0103684:	89 d6                	mov    %edx,%esi
f0103686:	d3 e3                	shl    %cl,%ebx
f0103688:	f7 64 24 04          	mull   0x4(%esp)
f010368c:	39 d6                	cmp    %edx,%esi
f010368e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103692:	89 d1                	mov    %edx,%ecx
f0103694:	89 c3                	mov    %eax,%ebx
f0103696:	72 08                	jb     f01036a0 <__umoddi3+0x110>
f0103698:	75 11                	jne    f01036ab <__umoddi3+0x11b>
f010369a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010369e:	73 0b                	jae    f01036ab <__umoddi3+0x11b>
f01036a0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01036a4:	1b 14 24             	sbb    (%esp),%edx
f01036a7:	89 d1                	mov    %edx,%ecx
f01036a9:	89 c3                	mov    %eax,%ebx
f01036ab:	8b 54 24 08          	mov    0x8(%esp),%edx
f01036af:	29 da                	sub    %ebx,%edx
f01036b1:	19 ce                	sbb    %ecx,%esi
f01036b3:	89 f9                	mov    %edi,%ecx
f01036b5:	89 f0                	mov    %esi,%eax
f01036b7:	d3 e0                	shl    %cl,%eax
f01036b9:	89 e9                	mov    %ebp,%ecx
f01036bb:	d3 ea                	shr    %cl,%edx
f01036bd:	89 e9                	mov    %ebp,%ecx
f01036bf:	d3 ee                	shr    %cl,%esi
f01036c1:	09 d0                	or     %edx,%eax
f01036c3:	89 f2                	mov    %esi,%edx
f01036c5:	83 c4 1c             	add    $0x1c,%esp
f01036c8:	5b                   	pop    %ebx
f01036c9:	5e                   	pop    %esi
f01036ca:	5f                   	pop    %edi
f01036cb:	5d                   	pop    %ebp
f01036cc:	c3                   	ret    
f01036cd:	8d 76 00             	lea    0x0(%esi),%esi
f01036d0:	29 f9                	sub    %edi,%ecx
f01036d2:	19 d6                	sbb    %edx,%esi
f01036d4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036d8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01036dc:	e9 18 ff ff ff       	jmp    f01035f9 <__umoddi3+0x69>
