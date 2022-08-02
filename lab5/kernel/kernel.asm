
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	c8478793          	addi	a5,a5,-892 # 80005ce0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	3c8080e7          	jalr	968(ra) # 800024ee <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	858080e7          	jalr	-1960(ra) # 80001a26 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	058080e7          	jalr	88(ra) # 80002236 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	27e080e7          	jalr	638(ra) # 80002498 <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	248080e7          	jalr	584(ra) # 80002544 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	f6c080e7          	jalr	-148(ra) # 800023bc <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	52e78793          	addi	a5,a5,1326 # 800219b0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	b06080e7          	jalr	-1274(ra) # 800023bc <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	8e6080e7          	jalr	-1818(ra) # 80002236 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00025517          	auipc	a0,0x25
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80026000 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	e60080e7          	jalr	-416(ra) # 80001a0a <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	e2e080e7          	jalr	-466(ra) # 80001a0a <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	e22080e7          	jalr	-478(ra) # 80001a0a <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	e0a080e7          	jalr	-502(ra) # 80001a0a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	dca080e7          	jalr	-566(ra) # 80001a0a <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	41c50513          	addi	a0,a0,1052 # 80008070 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	d9e080e7          	jalr	-610(ra) # 80001a0a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3d450513          	addi	a0,a0,980 # 80008078 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3dc50513          	addi	a0,a0,988 # 80008090 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	39c50513          	addi	a0,a0,924 # 80008098 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	b34080e7          	jalr	-1228(ra) # 800019fa <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	b18080e7          	jalr	-1256(ra) # 800019fa <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0d8080e7          	jalr	216(ra) # 80000fd4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00001097          	auipc	ra,0x1
    80000f08:	780080e7          	jalr	1920(ra) # 80002684 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	e14080e7          	jalr	-492(ra) # 80005d20 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	042080e7          	jalr	66(ra) # 80001f56 <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    printfinit();
    80000f24:	00000097          	auipc	ra,0x0
    80000f28:	854080e7          	jalr	-1964(ra) # 80000778 <printfinit>
    printf("\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	19c50513          	addi	a0,a0,412 # 800080c8 <digits+0x88>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	65e080e7          	jalr	1630(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	16450513          	addi	a0,a0,356 # 800080a0 <digits+0x60>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	64e080e7          	jalr	1614(ra) # 80000592 <printf>
    printf("\n");
    80000f4c:	00007517          	auipc	a0,0x7
    80000f50:	17c50513          	addi	a0,a0,380 # 800080c8 <digits+0x88>
    80000f54:	fffff097          	auipc	ra,0xfffff
    80000f58:	63e080e7          	jalr	1598(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	b88080e7          	jalr	-1144(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	322080e7          	jalr	802(ra) # 80001286 <kvminit>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	068080e7          	jalr	104(ra) # 80000fd4 <kvminithart>
    procinit();      // process table
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	9b6080e7          	jalr	-1610(ra) # 8000192a <procinit>
    trapinit();      // trap vectors
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	6e0080e7          	jalr	1760(ra) # 8000265c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	700080e7          	jalr	1792(ra) # 80002684 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	d7e080e7          	jalr	-642(ra) # 80005d0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	d8c080e7          	jalr	-628(ra) # 80005d20 <plicinithart>
    binit();         // buffer cache
    80000f9c:	00002097          	auipc	ra,0x2
    80000fa0:	f20080e7          	jalr	-224(ra) # 80002ebc <binit>
    iinit();         // inode cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	5b0080e7          	jalr	1456(ra) # 80003554 <iinit>
    fileinit();      // file table
    80000fac:	00003097          	auipc	ra,0x3
    80000fb0:	54e080e7          	jalr	1358(ra) # 800044fa <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	e74080e7          	jalr	-396(ra) # 80005e28 <virtio_disk_init>
    userinit();      // first user process
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	d34080e7          	jalr	-716(ra) # 80001cf0 <userinit>
    __sync_synchronize();
    80000fc4:	0ff0000f          	fence
    started = 1;
    80000fc8:	4785                	li	a5,1
    80000fca:	00008717          	auipc	a4,0x8
    80000fce:	04f72123          	sw	a5,66(a4) # 8000900c <started>
    80000fd2:	b789                	j	80000f14 <main+0x56>

0000000080000fd4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fd4:	1141                	addi	sp,sp,-16
    80000fd6:	e422                	sd	s0,8(sp)
    80000fd8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fda:	00008797          	auipc	a5,0x8
    80000fde:	0367b783          	ld	a5,54(a5) # 80009010 <kernel_pagetable>
    80000fe2:	83b1                	srli	a5,a5,0xc
    80000fe4:	577d                	li	a4,-1
    80000fe6:	177e                	slli	a4,a4,0x3f
    80000fe8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fea:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fee:	12000073          	sfence.vma
  sfence_vma();
}
    80000ff2:	6422                	ld	s0,8(sp)
    80000ff4:	0141                	addi	sp,sp,16
    80000ff6:	8082                	ret

0000000080000ff8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000ff8:	7139                	addi	sp,sp,-64
    80000ffa:	fc06                	sd	ra,56(sp)
    80000ffc:	f822                	sd	s0,48(sp)
    80000ffe:	f426                	sd	s1,40(sp)
    80001000:	f04a                	sd	s2,32(sp)
    80001002:	ec4e                	sd	s3,24(sp)
    80001004:	e852                	sd	s4,16(sp)
    80001006:	e456                	sd	s5,8(sp)
    80001008:	e05a                	sd	s6,0(sp)
    8000100a:	0080                	addi	s0,sp,64
    8000100c:	84aa                	mv	s1,a0
    8000100e:	89ae                	mv	s3,a1
    80001010:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001012:	57fd                	li	a5,-1
    80001014:	83e9                	srli	a5,a5,0x1a
    80001016:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001018:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000101a:	04b7f263          	bgeu	a5,a1,8000105e <walk+0x66>
    panic("walk");
    8000101e:	00007517          	auipc	a0,0x7
    80001022:	0b250513          	addi	a0,a0,178 # 800080d0 <digits+0x90>
    80001026:	fffff097          	auipc	ra,0xfffff
    8000102a:	522080e7          	jalr	1314(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000102e:	060a8663          	beqz	s5,8000109a <walk+0xa2>
    80001032:	00000097          	auipc	ra,0x0
    80001036:	aee080e7          	jalr	-1298(ra) # 80000b20 <kalloc>
    8000103a:	84aa                	mv	s1,a0
    8000103c:	c529                	beqz	a0,80001086 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000103e:	6605                	lui	a2,0x1
    80001040:	4581                	li	a1,0
    80001042:	00000097          	auipc	ra,0x0
    80001046:	cca080e7          	jalr	-822(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000104a:	00c4d793          	srli	a5,s1,0xc
    8000104e:	07aa                	slli	a5,a5,0xa
    80001050:	0017e793          	ori	a5,a5,1
    80001054:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001058:	3a5d                	addiw	s4,s4,-9
    8000105a:	036a0063          	beq	s4,s6,8000107a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000105e:	0149d933          	srl	s2,s3,s4
    80001062:	1ff97913          	andi	s2,s2,511
    80001066:	090e                	slli	s2,s2,0x3
    80001068:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000106a:	00093483          	ld	s1,0(s2)
    8000106e:	0014f793          	andi	a5,s1,1
    80001072:	dfd5                	beqz	a5,8000102e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001074:	80a9                	srli	s1,s1,0xa
    80001076:	04b2                	slli	s1,s1,0xc
    80001078:	b7c5                	j	80001058 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000107a:	00c9d513          	srli	a0,s3,0xc
    8000107e:	1ff57513          	andi	a0,a0,511
    80001082:	050e                	slli	a0,a0,0x3
    80001084:	9526                	add	a0,a0,s1
}
    80001086:	70e2                	ld	ra,56(sp)
    80001088:	7442                	ld	s0,48(sp)
    8000108a:	74a2                	ld	s1,40(sp)
    8000108c:	7902                	ld	s2,32(sp)
    8000108e:	69e2                	ld	s3,24(sp)
    80001090:	6a42                	ld	s4,16(sp)
    80001092:	6aa2                	ld	s5,8(sp)
    80001094:	6b02                	ld	s6,0(sp)
    80001096:	6121                	addi	sp,sp,64
    80001098:	8082                	ret
        return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7ed                	j	80001086 <walk+0x8e>

000000008000109e <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000109e:	1101                	addi	sp,sp,-32
    800010a0:	ec06                	sd	ra,24(sp)
    800010a2:	e822                	sd	s0,16(sp)
    800010a4:	e426                	sd	s1,8(sp)
    800010a6:	1000                	addi	s0,sp,32
    800010a8:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010aa:	1552                	slli	a0,a0,0x34
    800010ac:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010b0:	4601                	li	a2,0
    800010b2:	00008517          	auipc	a0,0x8
    800010b6:	f5e53503          	ld	a0,-162(a0) # 80009010 <kernel_pagetable>
    800010ba:	00000097          	auipc	ra,0x0
    800010be:	f3e080e7          	jalr	-194(ra) # 80000ff8 <walk>
  if(pte == 0)
    800010c2:	cd09                	beqz	a0,800010dc <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010c4:	6108                	ld	a0,0(a0)
    800010c6:	00157793          	andi	a5,a0,1
    800010ca:	c38d                	beqz	a5,800010ec <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800010cc:	8129                	srli	a0,a0,0xa
    800010ce:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800010d0:	9526                	add	a0,a0,s1
    800010d2:	60e2                	ld	ra,24(sp)
    800010d4:	6442                	ld	s0,16(sp)
    800010d6:	64a2                	ld	s1,8(sp)
    800010d8:	6105                	addi	sp,sp,32
    800010da:	8082                	ret
    panic("kvmpa");
    800010dc:	00007517          	auipc	a0,0x7
    800010e0:	ffc50513          	addi	a0,a0,-4 # 800080d8 <digits+0x98>
    800010e4:	fffff097          	auipc	ra,0xfffff
    800010e8:	464080e7          	jalr	1124(ra) # 80000548 <panic>
    panic("kvmpa");
    800010ec:	00007517          	auipc	a0,0x7
    800010f0:	fec50513          	addi	a0,a0,-20 # 800080d8 <digits+0x98>
    800010f4:	fffff097          	auipc	ra,0xfffff
    800010f8:	454080e7          	jalr	1108(ra) # 80000548 <panic>

00000000800010fc <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010fc:	715d                	addi	sp,sp,-80
    800010fe:	e486                	sd	ra,72(sp)
    80001100:	e0a2                	sd	s0,64(sp)
    80001102:	fc26                	sd	s1,56(sp)
    80001104:	f84a                	sd	s2,48(sp)
    80001106:	f44e                	sd	s3,40(sp)
    80001108:	f052                	sd	s4,32(sp)
    8000110a:	ec56                	sd	s5,24(sp)
    8000110c:	e85a                	sd	s6,16(sp)
    8000110e:	e45e                	sd	s7,8(sp)
    80001110:	0880                	addi	s0,sp,80
    80001112:	8aaa                	mv	s5,a0
    80001114:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001116:	777d                	lui	a4,0xfffff
    80001118:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000111c:	167d                	addi	a2,a2,-1
    8000111e:	00b609b3          	add	s3,a2,a1
    80001122:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001126:	893e                	mv	s2,a5
    80001128:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000112c:	6b85                	lui	s7,0x1
    8000112e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001132:	4605                	li	a2,1
    80001134:	85ca                	mv	a1,s2
    80001136:	8556                	mv	a0,s5
    80001138:	00000097          	auipc	ra,0x0
    8000113c:	ec0080e7          	jalr	-320(ra) # 80000ff8 <walk>
    80001140:	c51d                	beqz	a0,8000116e <mappages+0x72>
    if(*pte & PTE_V)
    80001142:	611c                	ld	a5,0(a0)
    80001144:	8b85                	andi	a5,a5,1
    80001146:	ef81                	bnez	a5,8000115e <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001148:	80b1                	srli	s1,s1,0xc
    8000114a:	04aa                	slli	s1,s1,0xa
    8000114c:	0164e4b3          	or	s1,s1,s6
    80001150:	0014e493          	ori	s1,s1,1
    80001154:	e104                	sd	s1,0(a0)
    if(a == last)
    80001156:	03390863          	beq	s2,s3,80001186 <mappages+0x8a>
    a += PGSIZE;
    8000115a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000115c:	bfc9                	j	8000112e <mappages+0x32>
      panic("remap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f8250513          	addi	a0,a0,-126 # 800080e0 <digits+0xa0>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3e2080e7          	jalr	994(ra) # 80000548 <panic>
      return -1;
    8000116e:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001170:	60a6                	ld	ra,72(sp)
    80001172:	6406                	ld	s0,64(sp)
    80001174:	74e2                	ld	s1,56(sp)
    80001176:	7942                	ld	s2,48(sp)
    80001178:	79a2                	ld	s3,40(sp)
    8000117a:	7a02                	ld	s4,32(sp)
    8000117c:	6ae2                	ld	s5,24(sp)
    8000117e:	6b42                	ld	s6,16(sp)
    80001180:	6ba2                	ld	s7,8(sp)
    80001182:	6161                	addi	sp,sp,80
    80001184:	8082                	ret
  return 0;
    80001186:	4501                	li	a0,0
    80001188:	b7e5                	j	80001170 <mappages+0x74>

000000008000118a <walkaddr>:
{
    8000118a:	7179                	addi	sp,sp,-48
    8000118c:	f406                	sd	ra,40(sp)
    8000118e:	f022                	sd	s0,32(sp)
    80001190:	ec26                	sd	s1,24(sp)
    80001192:	e84a                	sd	s2,16(sp)
    80001194:	e44e                	sd	s3,8(sp)
    80001196:	e052                	sd	s4,0(sp)
    80001198:	1800                	addi	s0,sp,48
    8000119a:	892a                	mv	s2,a0
    8000119c:	84ae                	mv	s1,a1
  struct proc *p=myproc();  // new code
    8000119e:	00001097          	auipc	ra,0x1
    800011a2:	888080e7          	jalr	-1912(ra) # 80001a26 <myproc>
  if(va >= MAXVA)
    800011a6:	57fd                	li	a5,-1
    800011a8:	83e9                	srli	a5,a5,0x1a
    800011aa:	0097fb63          	bgeu	a5,s1,800011c0 <walkaddr+0x36>
    return 0;
    800011ae:	4501                	li	a0,0
}
    800011b0:	70a2                	ld	ra,40(sp)
    800011b2:	7402                	ld	s0,32(sp)
    800011b4:	64e2                	ld	s1,24(sp)
    800011b6:	6942                	ld	s2,16(sp)
    800011b8:	69a2                	ld	s3,8(sp)
    800011ba:	6a02                	ld	s4,0(sp)
    800011bc:	6145                	addi	sp,sp,48
    800011be:	8082                	ret
    800011c0:	89aa                	mv	s3,a0
  pte = walk(pagetable, va, 0);
    800011c2:	4601                	li	a2,0
    800011c4:	85a6                	mv	a1,s1
    800011c6:	854a                	mv	a0,s2
    800011c8:	00000097          	auipc	ra,0x0
    800011cc:	e30080e7          	jalr	-464(ra) # 80000ff8 <walk>
    800011d0:	892a                	mv	s2,a0
  if(pte == 0 || (*pte & PTE_V) == 0) {
    800011d2:	c501                	beqz	a0,800011da <walkaddr+0x50>
    800011d4:	611c                	ld	a5,0(a0)
    800011d6:	8b85                	andi	a5,a5,1
    800011d8:	ebb9                	bnez	a5,8000122e <walkaddr+0xa4>
    if(va >= PGROUNDUP(p->trapframe->sp) && va < p->sz){
    800011da:	0589b783          	ld	a5,88(s3) # 1058 <_entry-0x7fffefa8>
    800011de:	7b9c                	ld	a5,48(a5)
    800011e0:	6705                	lui	a4,0x1
    800011e2:	177d                	addi	a4,a4,-1
    800011e4:	97ba                	add	a5,a5,a4
    800011e6:	777d                	lui	a4,0xfffff
    800011e8:	8ff9                	and	a5,a5,a4
        return 0;
    800011ea:	4501                	li	a0,0
    if(va >= PGROUNDUP(p->trapframe->sp) && va < p->sz){
    800011ec:	fcf4e2e3          	bltu	s1,a5,800011b0 <walkaddr+0x26>
    800011f0:	0489b783          	ld	a5,72(s3)
    800011f4:	faf4fee3          	bgeu	s1,a5,800011b0 <walkaddr+0x26>
        if ((pa = kalloc()) == 0) {
    800011f8:	00000097          	auipc	ra,0x0
    800011fc:	928080e7          	jalr	-1752(ra) # 80000b20 <kalloc>
    80001200:	8a2a                	mv	s4,a0
            return 0;
    80001202:	4501                	li	a0,0
        if ((pa = kalloc()) == 0) {
    80001204:	fa0a06e3          	beqz	s4,800011b0 <walkaddr+0x26>
        memset(pa, 0, PGSIZE);
    80001208:	6605                	lui	a2,0x1
    8000120a:	4581                	li	a1,0
    8000120c:	8552                	mv	a0,s4
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	afe080e7          	jalr	-1282(ra) # 80000d0c <memset>
        if (mappages(p->pagetable, PGROUNDDOWN(va), PGSIZE,
    80001216:	4759                	li	a4,22
    80001218:	86d2                	mv	a3,s4
    8000121a:	6605                	lui	a2,0x1
    8000121c:	75fd                	lui	a1,0xfffff
    8000121e:	8de5                	and	a1,a1,s1
    80001220:	0509b503          	ld	a0,80(s3)
    80001224:	00000097          	auipc	ra,0x0
    80001228:	ed8080e7          	jalr	-296(ra) # 800010fc <mappages>
    8000122c:	e911                	bnez	a0,80001240 <walkaddr+0xb6>
  if((*pte & PTE_U) == 0)
    8000122e:	00093783          	ld	a5,0(s2)
    80001232:	0107f513          	andi	a0,a5,16
    80001236:	dd2d                	beqz	a0,800011b0 <walkaddr+0x26>
  pa = PTE2PA(*pte);
    80001238:	00a7d513          	srli	a0,a5,0xa
    8000123c:	0532                	slli	a0,a0,0xc
  return pa;
    8000123e:	bf8d                	j	800011b0 <walkaddr+0x26>
            kfree(pa);
    80001240:	8552                	mv	a0,s4
    80001242:	fffff097          	auipc	ra,0xfffff
    80001246:	7e2080e7          	jalr	2018(ra) # 80000a24 <kfree>
            return 0;
    8000124a:	4501                	li	a0,0
    8000124c:	b795                	j	800011b0 <walkaddr+0x26>

000000008000124e <kvmmap>:
{
    8000124e:	1141                	addi	sp,sp,-16
    80001250:	e406                	sd	ra,8(sp)
    80001252:	e022                	sd	s0,0(sp)
    80001254:	0800                	addi	s0,sp,16
    80001256:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001258:	86ae                	mv	a3,a1
    8000125a:	85aa                	mv	a1,a0
    8000125c:	00008517          	auipc	a0,0x8
    80001260:	db453503          	ld	a0,-588(a0) # 80009010 <kernel_pagetable>
    80001264:	00000097          	auipc	ra,0x0
    80001268:	e98080e7          	jalr	-360(ra) # 800010fc <mappages>
    8000126c:	e509                	bnez	a0,80001276 <kvmmap+0x28>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret
    panic("kvmmap");
    80001276:	00007517          	auipc	a0,0x7
    8000127a:	e7250513          	addi	a0,a0,-398 # 800080e8 <digits+0xa8>
    8000127e:	fffff097          	auipc	ra,0xfffff
    80001282:	2ca080e7          	jalr	714(ra) # 80000548 <panic>

0000000080001286 <kvminit>:
{
    80001286:	1101                	addi	sp,sp,-32
    80001288:	ec06                	sd	ra,24(sp)
    8000128a:	e822                	sd	s0,16(sp)
    8000128c:	e426                	sd	s1,8(sp)
    8000128e:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001290:	00000097          	auipc	ra,0x0
    80001294:	890080e7          	jalr	-1904(ra) # 80000b20 <kalloc>
    80001298:	00008797          	auipc	a5,0x8
    8000129c:	d6a7bc23          	sd	a0,-648(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800012a0:	6605                	lui	a2,0x1
    800012a2:	4581                	li	a1,0
    800012a4:	00000097          	auipc	ra,0x0
    800012a8:	a68080e7          	jalr	-1432(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012ac:	4699                	li	a3,6
    800012ae:	6605                	lui	a2,0x1
    800012b0:	100005b7          	lui	a1,0x10000
    800012b4:	10000537          	lui	a0,0x10000
    800012b8:	00000097          	auipc	ra,0x0
    800012bc:	f96080e7          	jalr	-106(ra) # 8000124e <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012c0:	4699                	li	a3,6
    800012c2:	6605                	lui	a2,0x1
    800012c4:	100015b7          	lui	a1,0x10001
    800012c8:	10001537          	lui	a0,0x10001
    800012cc:	00000097          	auipc	ra,0x0
    800012d0:	f82080e7          	jalr	-126(ra) # 8000124e <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012d4:	4699                	li	a3,6
    800012d6:	6641                	lui	a2,0x10
    800012d8:	020005b7          	lui	a1,0x2000
    800012dc:	02000537          	lui	a0,0x2000
    800012e0:	00000097          	auipc	ra,0x0
    800012e4:	f6e080e7          	jalr	-146(ra) # 8000124e <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012e8:	4699                	li	a3,6
    800012ea:	00400637          	lui	a2,0x400
    800012ee:	0c0005b7          	lui	a1,0xc000
    800012f2:	0c000537          	lui	a0,0xc000
    800012f6:	00000097          	auipc	ra,0x0
    800012fa:	f58080e7          	jalr	-168(ra) # 8000124e <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012fe:	00007497          	auipc	s1,0x7
    80001302:	d0248493          	addi	s1,s1,-766 # 80008000 <etext>
    80001306:	46a9                	li	a3,10
    80001308:	80007617          	auipc	a2,0x80007
    8000130c:	cf860613          	addi	a2,a2,-776 # 8000 <_entry-0x7fff8000>
    80001310:	4585                	li	a1,1
    80001312:	05fe                	slli	a1,a1,0x1f
    80001314:	852e                	mv	a0,a1
    80001316:	00000097          	auipc	ra,0x0
    8000131a:	f38080e7          	jalr	-200(ra) # 8000124e <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000131e:	4699                	li	a3,6
    80001320:	4645                	li	a2,17
    80001322:	066e                	slli	a2,a2,0x1b
    80001324:	8e05                	sub	a2,a2,s1
    80001326:	85a6                	mv	a1,s1
    80001328:	8526                	mv	a0,s1
    8000132a:	00000097          	auipc	ra,0x0
    8000132e:	f24080e7          	jalr	-220(ra) # 8000124e <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001332:	46a9                	li	a3,10
    80001334:	6605                	lui	a2,0x1
    80001336:	00006597          	auipc	a1,0x6
    8000133a:	cca58593          	addi	a1,a1,-822 # 80007000 <_trampoline>
    8000133e:	04000537          	lui	a0,0x4000
    80001342:	157d                	addi	a0,a0,-1
    80001344:	0532                	slli	a0,a0,0xc
    80001346:	00000097          	auipc	ra,0x0
    8000134a:	f08080e7          	jalr	-248(ra) # 8000124e <kvmmap>
}
    8000134e:	60e2                	ld	ra,24(sp)
    80001350:	6442                	ld	s0,16(sp)
    80001352:	64a2                	ld	s1,8(sp)
    80001354:	6105                	addi	sp,sp,32
    80001356:	8082                	ret

0000000080001358 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001358:	715d                	addi	sp,sp,-80
    8000135a:	e486                	sd	ra,72(sp)
    8000135c:	e0a2                	sd	s0,64(sp)
    8000135e:	fc26                	sd	s1,56(sp)
    80001360:	f84a                	sd	s2,48(sp)
    80001362:	f44e                	sd	s3,40(sp)
    80001364:	f052                	sd	s4,32(sp)
    80001366:	ec56                	sd	s5,24(sp)
    80001368:	e85a                	sd	s6,16(sp)
    8000136a:	e45e                	sd	s7,8(sp)
    8000136c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000136e:	03459793          	slli	a5,a1,0x34
    80001372:	e795                	bnez	a5,8000139e <uvmunmap+0x46>
    80001374:	8a2a                	mv	s4,a0
    80001376:	892e                	mv	s2,a1
    80001378:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000137a:	0632                	slli	a2,a2,0xc
    8000137c:	00b609b3          	add	s3,a2,a1
    }
    if((*pte & PTE_V) == 0) {
      continue;     // lab5-2
//      panic("uvmunmap: not mapped");  
    }
    if(PTE_FLAGS(*pte) == PTE_V)
    80001380:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001382:	6a85                	lui	s5,0x1
    80001384:	0535e963          	bltu	a1,s3,800013d6 <uvmunmap+0x7e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001388:	60a6                	ld	ra,72(sp)
    8000138a:	6406                	ld	s0,64(sp)
    8000138c:	74e2                	ld	s1,56(sp)
    8000138e:	7942                	ld	s2,48(sp)
    80001390:	79a2                	ld	s3,40(sp)
    80001392:	7a02                	ld	s4,32(sp)
    80001394:	6ae2                	ld	s5,24(sp)
    80001396:	6b42                	ld	s6,16(sp)
    80001398:	6ba2                	ld	s7,8(sp)
    8000139a:	6161                	addi	sp,sp,80
    8000139c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000139e:	00007517          	auipc	a0,0x7
    800013a2:	d5250513          	addi	a0,a0,-686 # 800080f0 <digits+0xb0>
    800013a6:	fffff097          	auipc	ra,0xfffff
    800013aa:	1a2080e7          	jalr	418(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	d5a50513          	addi	a0,a0,-678 # 80008108 <digits+0xc8>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	192080e7          	jalr	402(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800013be:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800013c0:	00c79513          	slli	a0,a5,0xc
    800013c4:	fffff097          	auipc	ra,0xfffff
    800013c8:	660080e7          	jalr	1632(ra) # 80000a24 <kfree>
    *pte = 0;
    800013cc:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013d0:	9956                	add	s2,s2,s5
    800013d2:	fb397be3          	bgeu	s2,s3,80001388 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0) {
    800013d6:	4601                	li	a2,0
    800013d8:	85ca                	mv	a1,s2
    800013da:	8552                	mv	a0,s4
    800013dc:	00000097          	auipc	ra,0x0
    800013e0:	c1c080e7          	jalr	-996(ra) # 80000ff8 <walk>
    800013e4:	84aa                	mv	s1,a0
    800013e6:	d56d                	beqz	a0,800013d0 <uvmunmap+0x78>
    if((*pte & PTE_V) == 0) {
    800013e8:	611c                	ld	a5,0(a0)
    800013ea:	0017f713          	andi	a4,a5,1
    800013ee:	d36d                	beqz	a4,800013d0 <uvmunmap+0x78>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013f0:	3ff7f713          	andi	a4,a5,1023
    800013f4:	fb770de3          	beq	a4,s7,800013ae <uvmunmap+0x56>
    if(do_free){
    800013f8:	fc0b0ae3          	beqz	s6,800013cc <uvmunmap+0x74>
    800013fc:	b7c9                	j	800013be <uvmunmap+0x66>

00000000800013fe <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013fe:	1101                	addi	sp,sp,-32
    80001400:	ec06                	sd	ra,24(sp)
    80001402:	e822                	sd	s0,16(sp)
    80001404:	e426                	sd	s1,8(sp)
    80001406:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001408:	fffff097          	auipc	ra,0xfffff
    8000140c:	718080e7          	jalr	1816(ra) # 80000b20 <kalloc>
    80001410:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001412:	c519                	beqz	a0,80001420 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001414:	6605                	lui	a2,0x1
    80001416:	4581                	li	a1,0
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	8f4080e7          	jalr	-1804(ra) # 80000d0c <memset>
  return pagetable;
}
    80001420:	8526                	mv	a0,s1
    80001422:	60e2                	ld	ra,24(sp)
    80001424:	6442                	ld	s0,16(sp)
    80001426:	64a2                	ld	s1,8(sp)
    80001428:	6105                	addi	sp,sp,32
    8000142a:	8082                	ret

000000008000142c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000142c:	7179                	addi	sp,sp,-48
    8000142e:	f406                	sd	ra,40(sp)
    80001430:	f022                	sd	s0,32(sp)
    80001432:	ec26                	sd	s1,24(sp)
    80001434:	e84a                	sd	s2,16(sp)
    80001436:	e44e                	sd	s3,8(sp)
    80001438:	e052                	sd	s4,0(sp)
    8000143a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000143c:	6785                	lui	a5,0x1
    8000143e:	04f67863          	bgeu	a2,a5,8000148e <uvminit+0x62>
    80001442:	8a2a                	mv	s4,a0
    80001444:	89ae                	mv	s3,a1
    80001446:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001448:	fffff097          	auipc	ra,0xfffff
    8000144c:	6d8080e7          	jalr	1752(ra) # 80000b20 <kalloc>
    80001450:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001452:	6605                	lui	a2,0x1
    80001454:	4581                	li	a1,0
    80001456:	00000097          	auipc	ra,0x0
    8000145a:	8b6080e7          	jalr	-1866(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000145e:	4779                	li	a4,30
    80001460:	86ca                	mv	a3,s2
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	8552                	mv	a0,s4
    80001468:	00000097          	auipc	ra,0x0
    8000146c:	c94080e7          	jalr	-876(ra) # 800010fc <mappages>
  memmove(mem, src, sz);
    80001470:	8626                	mv	a2,s1
    80001472:	85ce                	mv	a1,s3
    80001474:	854a                	mv	a0,s2
    80001476:	00000097          	auipc	ra,0x0
    8000147a:	8f6080e7          	jalr	-1802(ra) # 80000d6c <memmove>
}
    8000147e:	70a2                	ld	ra,40(sp)
    80001480:	7402                	ld	s0,32(sp)
    80001482:	64e2                	ld	s1,24(sp)
    80001484:	6942                	ld	s2,16(sp)
    80001486:	69a2                	ld	s3,8(sp)
    80001488:	6a02                	ld	s4,0(sp)
    8000148a:	6145                	addi	sp,sp,48
    8000148c:	8082                	ret
    panic("inituvm: more than a page");
    8000148e:	00007517          	auipc	a0,0x7
    80001492:	c9250513          	addi	a0,a0,-878 # 80008120 <digits+0xe0>
    80001496:	fffff097          	auipc	ra,0xfffff
    8000149a:	0b2080e7          	jalr	178(ra) # 80000548 <panic>

000000008000149e <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000149e:	1101                	addi	sp,sp,-32
    800014a0:	ec06                	sd	ra,24(sp)
    800014a2:	e822                	sd	s0,16(sp)
    800014a4:	e426                	sd	s1,8(sp)
    800014a6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014a8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014aa:	00b67d63          	bgeu	a2,a1,800014c4 <uvmdealloc+0x26>
    800014ae:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014b0:	6785                	lui	a5,0x1
    800014b2:	17fd                	addi	a5,a5,-1
    800014b4:	00f60733          	add	a4,a2,a5
    800014b8:	767d                	lui	a2,0xfffff
    800014ba:	8f71                	and	a4,a4,a2
    800014bc:	97ae                	add	a5,a5,a1
    800014be:	8ff1                	and	a5,a5,a2
    800014c0:	00f76863          	bltu	a4,a5,800014d0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014c4:	8526                	mv	a0,s1
    800014c6:	60e2                	ld	ra,24(sp)
    800014c8:	6442                	ld	s0,16(sp)
    800014ca:	64a2                	ld	s1,8(sp)
    800014cc:	6105                	addi	sp,sp,32
    800014ce:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014d0:	8f99                	sub	a5,a5,a4
    800014d2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014d4:	4685                	li	a3,1
    800014d6:	0007861b          	sext.w	a2,a5
    800014da:	85ba                	mv	a1,a4
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	e7c080e7          	jalr	-388(ra) # 80001358 <uvmunmap>
    800014e4:	b7c5                	j	800014c4 <uvmdealloc+0x26>

00000000800014e6 <uvmalloc>:
  if(newsz < oldsz)
    800014e6:	0ab66163          	bltu	a2,a1,80001588 <uvmalloc+0xa2>
{
    800014ea:	7139                	addi	sp,sp,-64
    800014ec:	fc06                	sd	ra,56(sp)
    800014ee:	f822                	sd	s0,48(sp)
    800014f0:	f426                	sd	s1,40(sp)
    800014f2:	f04a                	sd	s2,32(sp)
    800014f4:	ec4e                	sd	s3,24(sp)
    800014f6:	e852                	sd	s4,16(sp)
    800014f8:	e456                	sd	s5,8(sp)
    800014fa:	0080                	addi	s0,sp,64
    800014fc:	8aaa                	mv	s5,a0
    800014fe:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001500:	6985                	lui	s3,0x1
    80001502:	19fd                	addi	s3,s3,-1
    80001504:	95ce                	add	a1,a1,s3
    80001506:	79fd                	lui	s3,0xfffff
    80001508:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000150c:	08c9f063          	bgeu	s3,a2,8000158c <uvmalloc+0xa6>
    80001510:	894e                	mv	s2,s3
    mem = kalloc();
    80001512:	fffff097          	auipc	ra,0xfffff
    80001516:	60e080e7          	jalr	1550(ra) # 80000b20 <kalloc>
    8000151a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000151c:	c51d                	beqz	a0,8000154a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000151e:	6605                	lui	a2,0x1
    80001520:	4581                	li	a1,0
    80001522:	fffff097          	auipc	ra,0xfffff
    80001526:	7ea080e7          	jalr	2026(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000152a:	4779                	li	a4,30
    8000152c:	86a6                	mv	a3,s1
    8000152e:	6605                	lui	a2,0x1
    80001530:	85ca                	mv	a1,s2
    80001532:	8556                	mv	a0,s5
    80001534:	00000097          	auipc	ra,0x0
    80001538:	bc8080e7          	jalr	-1080(ra) # 800010fc <mappages>
    8000153c:	e905                	bnez	a0,8000156c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000153e:	6785                	lui	a5,0x1
    80001540:	993e                	add	s2,s2,a5
    80001542:	fd4968e3          	bltu	s2,s4,80001512 <uvmalloc+0x2c>
  return newsz;
    80001546:	8552                	mv	a0,s4
    80001548:	a809                	j	8000155a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000154a:	864e                	mv	a2,s3
    8000154c:	85ca                	mv	a1,s2
    8000154e:	8556                	mv	a0,s5
    80001550:	00000097          	auipc	ra,0x0
    80001554:	f4e080e7          	jalr	-178(ra) # 8000149e <uvmdealloc>
      return 0;
    80001558:	4501                	li	a0,0
}
    8000155a:	70e2                	ld	ra,56(sp)
    8000155c:	7442                	ld	s0,48(sp)
    8000155e:	74a2                	ld	s1,40(sp)
    80001560:	7902                	ld	s2,32(sp)
    80001562:	69e2                	ld	s3,24(sp)
    80001564:	6a42                	ld	s4,16(sp)
    80001566:	6aa2                	ld	s5,8(sp)
    80001568:	6121                	addi	sp,sp,64
    8000156a:	8082                	ret
      kfree(mem);
    8000156c:	8526                	mv	a0,s1
    8000156e:	fffff097          	auipc	ra,0xfffff
    80001572:	4b6080e7          	jalr	1206(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001576:	864e                	mv	a2,s3
    80001578:	85ca                	mv	a1,s2
    8000157a:	8556                	mv	a0,s5
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	f22080e7          	jalr	-222(ra) # 8000149e <uvmdealloc>
      return 0;
    80001584:	4501                	li	a0,0
    80001586:	bfd1                	j	8000155a <uvmalloc+0x74>
    return oldsz;
    80001588:	852e                	mv	a0,a1
}
    8000158a:	8082                	ret
  return newsz;
    8000158c:	8532                	mv	a0,a2
    8000158e:	b7f1                	j	8000155a <uvmalloc+0x74>

0000000080001590 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001590:	7179                	addi	sp,sp,-48
    80001592:	f406                	sd	ra,40(sp)
    80001594:	f022                	sd	s0,32(sp)
    80001596:	ec26                	sd	s1,24(sp)
    80001598:	e84a                	sd	s2,16(sp)
    8000159a:	e44e                	sd	s3,8(sp)
    8000159c:	e052                	sd	s4,0(sp)
    8000159e:	1800                	addi	s0,sp,48
    800015a0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015a2:	84aa                	mv	s1,a0
    800015a4:	6905                	lui	s2,0x1
    800015a6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015a8:	4985                	li	s3,1
    800015aa:	a821                	j	800015c2 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015ac:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015ae:	0532                	slli	a0,a0,0xc
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	fe0080e7          	jalr	-32(ra) # 80001590 <freewalk>
      pagetable[i] = 0;
    800015b8:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015bc:	04a1                	addi	s1,s1,8
    800015be:	03248163          	beq	s1,s2,800015e0 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015c2:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015c4:	00f57793          	andi	a5,a0,15
    800015c8:	ff3782e3          	beq	a5,s3,800015ac <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015cc:	8905                	andi	a0,a0,1
    800015ce:	d57d                	beqz	a0,800015bc <freewalk+0x2c>
      panic("freewalk: leaf");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	b7050513          	addi	a0,a0,-1168 # 80008140 <digits+0x100>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	f70080e7          	jalr	-144(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015e0:	8552                	mv	a0,s4
    800015e2:	fffff097          	auipc	ra,0xfffff
    800015e6:	442080e7          	jalr	1090(ra) # 80000a24 <kfree>
}
    800015ea:	70a2                	ld	ra,40(sp)
    800015ec:	7402                	ld	s0,32(sp)
    800015ee:	64e2                	ld	s1,24(sp)
    800015f0:	6942                	ld	s2,16(sp)
    800015f2:	69a2                	ld	s3,8(sp)
    800015f4:	6a02                	ld	s4,0(sp)
    800015f6:	6145                	addi	sp,sp,48
    800015f8:	8082                	ret

00000000800015fa <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015fa:	1101                	addi	sp,sp,-32
    800015fc:	ec06                	sd	ra,24(sp)
    800015fe:	e822                	sd	s0,16(sp)
    80001600:	e426                	sd	s1,8(sp)
    80001602:	1000                	addi	s0,sp,32
    80001604:	84aa                	mv	s1,a0
  if(sz > 0)
    80001606:	e999                	bnez	a1,8000161c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001608:	8526                	mv	a0,s1
    8000160a:	00000097          	auipc	ra,0x0
    8000160e:	f86080e7          	jalr	-122(ra) # 80001590 <freewalk>
}
    80001612:	60e2                	ld	ra,24(sp)
    80001614:	6442                	ld	s0,16(sp)
    80001616:	64a2                	ld	s1,8(sp)
    80001618:	6105                	addi	sp,sp,32
    8000161a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000161c:	6605                	lui	a2,0x1
    8000161e:	167d                	addi	a2,a2,-1
    80001620:	962e                	add	a2,a2,a1
    80001622:	4685                	li	a3,1
    80001624:	8231                	srli	a2,a2,0xc
    80001626:	4581                	li	a1,0
    80001628:	00000097          	auipc	ra,0x0
    8000162c:	d30080e7          	jalr	-720(ra) # 80001358 <uvmunmap>
    80001630:	bfe1                	j	80001608 <uvmfree+0xe>

0000000080001632 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001632:	ca4d                	beqz	a2,800016e4 <uvmcopy+0xb2>
{
    80001634:	715d                	addi	sp,sp,-80
    80001636:	e486                	sd	ra,72(sp)
    80001638:	e0a2                	sd	s0,64(sp)
    8000163a:	fc26                	sd	s1,56(sp)
    8000163c:	f84a                	sd	s2,48(sp)
    8000163e:	f44e                	sd	s3,40(sp)
    80001640:	f052                	sd	s4,32(sp)
    80001642:	ec56                	sd	s5,24(sp)
    80001644:	e85a                	sd	s6,16(sp)
    80001646:	e45e                	sd	s7,8(sp)
    80001648:	0880                	addi	s0,sp,80
    8000164a:	8aaa                	mv	s5,a0
    8000164c:	8b2e                	mv	s6,a1
    8000164e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001650:	4481                	li	s1,0
    80001652:	a029                	j	8000165c <uvmcopy+0x2a>
    80001654:	6785                	lui	a5,0x1
    80001656:	94be                	add	s1,s1,a5
    80001658:	0744fa63          	bgeu	s1,s4,800016cc <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) == 0) {
    8000165c:	4601                	li	a2,0
    8000165e:	85a6                	mv	a1,s1
    80001660:	8556                	mv	a0,s5
    80001662:	00000097          	auipc	ra,0x0
    80001666:	996080e7          	jalr	-1642(ra) # 80000ff8 <walk>
    8000166a:	d56d                	beqz	a0,80001654 <uvmcopy+0x22>
      continue;     // lab5-3
//      panic("uvmcopy: pte should exist"); // lab5-3
    }
    if((*pte & PTE_V) == 0) {
    8000166c:	6118                	ld	a4,0(a0)
    8000166e:	00177793          	andi	a5,a4,1
    80001672:	d3ed                	beqz	a5,80001654 <uvmcopy+0x22>
      // lab5-3
      continue;
//        panic("uvmcopy: page not present");
    }
    pa = PTE2PA(*pte);
    80001674:	00a75593          	srli	a1,a4,0xa
    80001678:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000167c:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    80001680:	fffff097          	auipc	ra,0xfffff
    80001684:	4a0080e7          	jalr	1184(ra) # 80000b20 <kalloc>
    80001688:	89aa                	mv	s3,a0
    8000168a:	c515                	beqz	a0,800016b6 <uvmcopy+0x84>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000168c:	6605                	lui	a2,0x1
    8000168e:	85de                	mv	a1,s7
    80001690:	fffff097          	auipc	ra,0xfffff
    80001694:	6dc080e7          	jalr	1756(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001698:	874a                	mv	a4,s2
    8000169a:	86ce                	mv	a3,s3
    8000169c:	6605                	lui	a2,0x1
    8000169e:	85a6                	mv	a1,s1
    800016a0:	855a                	mv	a0,s6
    800016a2:	00000097          	auipc	ra,0x0
    800016a6:	a5a080e7          	jalr	-1446(ra) # 800010fc <mappages>
    800016aa:	d54d                	beqz	a0,80001654 <uvmcopy+0x22>
      kfree(mem);
    800016ac:	854e                	mv	a0,s3
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	376080e7          	jalr	886(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016b6:	4685                	li	a3,1
    800016b8:	00c4d613          	srli	a2,s1,0xc
    800016bc:	4581                	li	a1,0
    800016be:	855a                	mv	a0,s6
    800016c0:	00000097          	auipc	ra,0x0
    800016c4:	c98080e7          	jalr	-872(ra) # 80001358 <uvmunmap>
  return -1;
    800016c8:	557d                	li	a0,-1
    800016ca:	a011                	j	800016ce <uvmcopy+0x9c>
  return 0;
    800016cc:	4501                	li	a0,0
}
    800016ce:	60a6                	ld	ra,72(sp)
    800016d0:	6406                	ld	s0,64(sp)
    800016d2:	74e2                	ld	s1,56(sp)
    800016d4:	7942                	ld	s2,48(sp)
    800016d6:	79a2                	ld	s3,40(sp)
    800016d8:	7a02                	ld	s4,32(sp)
    800016da:	6ae2                	ld	s5,24(sp)
    800016dc:	6b42                	ld	s6,16(sp)
    800016de:	6ba2                	ld	s7,8(sp)
    800016e0:	6161                	addi	sp,sp,80
    800016e2:	8082                	ret
  return 0;
    800016e4:	4501                	li	a0,0
}
    800016e6:	8082                	ret

00000000800016e8 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016e8:	1141                	addi	sp,sp,-16
    800016ea:	e406                	sd	ra,8(sp)
    800016ec:	e022                	sd	s0,0(sp)
    800016ee:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016f0:	4601                	li	a2,0
    800016f2:	00000097          	auipc	ra,0x0
    800016f6:	906080e7          	jalr	-1786(ra) # 80000ff8 <walk>
  if(pte == 0)
    800016fa:	c901                	beqz	a0,8000170a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016fc:	611c                	ld	a5,0(a0)
    800016fe:	9bbd                	andi	a5,a5,-17
    80001700:	e11c                	sd	a5,0(a0)
}
    80001702:	60a2                	ld	ra,8(sp)
    80001704:	6402                	ld	s0,0(sp)
    80001706:	0141                	addi	sp,sp,16
    80001708:	8082                	ret
    panic("uvmclear");
    8000170a:	00007517          	auipc	a0,0x7
    8000170e:	a4650513          	addi	a0,a0,-1466 # 80008150 <digits+0x110>
    80001712:	fffff097          	auipc	ra,0xfffff
    80001716:	e36080e7          	jalr	-458(ra) # 80000548 <panic>

000000008000171a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000171a:	c6bd                	beqz	a3,80001788 <copyout+0x6e>
{
    8000171c:	715d                	addi	sp,sp,-80
    8000171e:	e486                	sd	ra,72(sp)
    80001720:	e0a2                	sd	s0,64(sp)
    80001722:	fc26                	sd	s1,56(sp)
    80001724:	f84a                	sd	s2,48(sp)
    80001726:	f44e                	sd	s3,40(sp)
    80001728:	f052                	sd	s4,32(sp)
    8000172a:	ec56                	sd	s5,24(sp)
    8000172c:	e85a                	sd	s6,16(sp)
    8000172e:	e45e                	sd	s7,8(sp)
    80001730:	e062                	sd	s8,0(sp)
    80001732:	0880                	addi	s0,sp,80
    80001734:	8b2a                	mv	s6,a0
    80001736:	8c2e                	mv	s8,a1
    80001738:	8a32                	mv	s4,a2
    8000173a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000173c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000173e:	6a85                	lui	s5,0x1
    80001740:	a015                	j	80001764 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001742:	9562                	add	a0,a0,s8
    80001744:	0004861b          	sext.w	a2,s1
    80001748:	85d2                	mv	a1,s4
    8000174a:	41250533          	sub	a0,a0,s2
    8000174e:	fffff097          	auipc	ra,0xfffff
    80001752:	61e080e7          	jalr	1566(ra) # 80000d6c <memmove>

    len -= n;
    80001756:	409989b3          	sub	s3,s3,s1
    src += n;
    8000175a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000175c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001760:	02098263          	beqz	s3,80001784 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001764:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001768:	85ca                	mv	a1,s2
    8000176a:	855a                	mv	a0,s6
    8000176c:	00000097          	auipc	ra,0x0
    80001770:	a1e080e7          	jalr	-1506(ra) # 8000118a <walkaddr>
    if(pa0 == 0)
    80001774:	cd01                	beqz	a0,8000178c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001776:	418904b3          	sub	s1,s2,s8
    8000177a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000177c:	fc99f3e3          	bgeu	s3,s1,80001742 <copyout+0x28>
    80001780:	84ce                	mv	s1,s3
    80001782:	b7c1                	j	80001742 <copyout+0x28>
  }
  return 0;
    80001784:	4501                	li	a0,0
    80001786:	a021                	j	8000178e <copyout+0x74>
    80001788:	4501                	li	a0,0
}
    8000178a:	8082                	ret
      return -1;
    8000178c:	557d                	li	a0,-1
}
    8000178e:	60a6                	ld	ra,72(sp)
    80001790:	6406                	ld	s0,64(sp)
    80001792:	74e2                	ld	s1,56(sp)
    80001794:	7942                	ld	s2,48(sp)
    80001796:	79a2                	ld	s3,40(sp)
    80001798:	7a02                	ld	s4,32(sp)
    8000179a:	6ae2                	ld	s5,24(sp)
    8000179c:	6b42                	ld	s6,16(sp)
    8000179e:	6ba2                	ld	s7,8(sp)
    800017a0:	6c02                	ld	s8,0(sp)
    800017a2:	6161                	addi	sp,sp,80
    800017a4:	8082                	ret

00000000800017a6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017a6:	c6bd                	beqz	a3,80001814 <copyin+0x6e>
{
    800017a8:	715d                	addi	sp,sp,-80
    800017aa:	e486                	sd	ra,72(sp)
    800017ac:	e0a2                	sd	s0,64(sp)
    800017ae:	fc26                	sd	s1,56(sp)
    800017b0:	f84a                	sd	s2,48(sp)
    800017b2:	f44e                	sd	s3,40(sp)
    800017b4:	f052                	sd	s4,32(sp)
    800017b6:	ec56                	sd	s5,24(sp)
    800017b8:	e85a                	sd	s6,16(sp)
    800017ba:	e45e                	sd	s7,8(sp)
    800017bc:	e062                	sd	s8,0(sp)
    800017be:	0880                	addi	s0,sp,80
    800017c0:	8b2a                	mv	s6,a0
    800017c2:	8a2e                	mv	s4,a1
    800017c4:	8c32                	mv	s8,a2
    800017c6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017c8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ca:	6a85                	lui	s5,0x1
    800017cc:	a015                	j	800017f0 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017ce:	9562                	add	a0,a0,s8
    800017d0:	0004861b          	sext.w	a2,s1
    800017d4:	412505b3          	sub	a1,a0,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	fffff097          	auipc	ra,0xfffff
    800017de:	592080e7          	jalr	1426(ra) # 80000d6c <memmove>

    len -= n;
    800017e2:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017e6:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017e8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017ec:	02098263          	beqz	s3,80001810 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017f0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017f4:	85ca                	mv	a1,s2
    800017f6:	855a                	mv	a0,s6
    800017f8:	00000097          	auipc	ra,0x0
    800017fc:	992080e7          	jalr	-1646(ra) # 8000118a <walkaddr>
    if(pa0 == 0)
    80001800:	cd01                	beqz	a0,80001818 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001802:	418904b3          	sub	s1,s2,s8
    80001806:	94d6                	add	s1,s1,s5
    if(n > len)
    80001808:	fc99f3e3          	bgeu	s3,s1,800017ce <copyin+0x28>
    8000180c:	84ce                	mv	s1,s3
    8000180e:	b7c1                	j	800017ce <copyin+0x28>
  }
  return 0;
    80001810:	4501                	li	a0,0
    80001812:	a021                	j	8000181a <copyin+0x74>
    80001814:	4501                	li	a0,0
}
    80001816:	8082                	ret
      return -1;
    80001818:	557d                	li	a0,-1
}
    8000181a:	60a6                	ld	ra,72(sp)
    8000181c:	6406                	ld	s0,64(sp)
    8000181e:	74e2                	ld	s1,56(sp)
    80001820:	7942                	ld	s2,48(sp)
    80001822:	79a2                	ld	s3,40(sp)
    80001824:	7a02                	ld	s4,32(sp)
    80001826:	6ae2                	ld	s5,24(sp)
    80001828:	6b42                	ld	s6,16(sp)
    8000182a:	6ba2                	ld	s7,8(sp)
    8000182c:	6c02                	ld	s8,0(sp)
    8000182e:	6161                	addi	sp,sp,80
    80001830:	8082                	ret

0000000080001832 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001832:	c6c5                	beqz	a3,800018da <copyinstr+0xa8>
{
    80001834:	715d                	addi	sp,sp,-80
    80001836:	e486                	sd	ra,72(sp)
    80001838:	e0a2                	sd	s0,64(sp)
    8000183a:	fc26                	sd	s1,56(sp)
    8000183c:	f84a                	sd	s2,48(sp)
    8000183e:	f44e                	sd	s3,40(sp)
    80001840:	f052                	sd	s4,32(sp)
    80001842:	ec56                	sd	s5,24(sp)
    80001844:	e85a                	sd	s6,16(sp)
    80001846:	e45e                	sd	s7,8(sp)
    80001848:	0880                	addi	s0,sp,80
    8000184a:	8a2a                	mv	s4,a0
    8000184c:	8b2e                	mv	s6,a1
    8000184e:	8bb2                	mv	s7,a2
    80001850:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001852:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001854:	6985                	lui	s3,0x1
    80001856:	a035                	j	80001882 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001858:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000185c:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000185e:	0017b793          	seqz	a5,a5
    80001862:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001866:	60a6                	ld	ra,72(sp)
    80001868:	6406                	ld	s0,64(sp)
    8000186a:	74e2                	ld	s1,56(sp)
    8000186c:	7942                	ld	s2,48(sp)
    8000186e:	79a2                	ld	s3,40(sp)
    80001870:	7a02                	ld	s4,32(sp)
    80001872:	6ae2                	ld	s5,24(sp)
    80001874:	6b42                	ld	s6,16(sp)
    80001876:	6ba2                	ld	s7,8(sp)
    80001878:	6161                	addi	sp,sp,80
    8000187a:	8082                	ret
    srcva = va0 + PGSIZE;
    8000187c:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001880:	c8a9                	beqz	s1,800018d2 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001882:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001886:	85ca                	mv	a1,s2
    80001888:	8552                	mv	a0,s4
    8000188a:	00000097          	auipc	ra,0x0
    8000188e:	900080e7          	jalr	-1792(ra) # 8000118a <walkaddr>
    if(pa0 == 0)
    80001892:	c131                	beqz	a0,800018d6 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001894:	41790833          	sub	a6,s2,s7
    80001898:	984e                	add	a6,a6,s3
    if(n > max)
    8000189a:	0104f363          	bgeu	s1,a6,800018a0 <copyinstr+0x6e>
    8000189e:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018a0:	955e                	add	a0,a0,s7
    800018a2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018a6:	fc080be3          	beqz	a6,8000187c <copyinstr+0x4a>
    800018aa:	985a                	add	a6,a6,s6
    800018ac:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018ae:	41650633          	sub	a2,a0,s6
    800018b2:	14fd                	addi	s1,s1,-1
    800018b4:	9b26                	add	s6,s6,s1
    800018b6:	00f60733          	add	a4,a2,a5
    800018ba:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018be:	df49                	beqz	a4,80001858 <copyinstr+0x26>
        *dst = *p;
    800018c0:	00e78023          	sb	a4,0(a5)
      --max;
    800018c4:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018c8:	0785                	addi	a5,a5,1
    while(n > 0){
    800018ca:	ff0796e3          	bne	a5,a6,800018b6 <copyinstr+0x84>
      dst++;
    800018ce:	8b42                	mv	s6,a6
    800018d0:	b775                	j	8000187c <copyinstr+0x4a>
    800018d2:	4781                	li	a5,0
    800018d4:	b769                	j	8000185e <copyinstr+0x2c>
      return -1;
    800018d6:	557d                	li	a0,-1
    800018d8:	b779                	j	80001866 <copyinstr+0x34>
  int got_null = 0;
    800018da:	4781                	li	a5,0
  if(got_null){
    800018dc:	0017b793          	seqz	a5,a5
    800018e0:	40f00533          	neg	a0,a5
}
    800018e4:	8082                	ret

00000000800018e6 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018e6:	1101                	addi	sp,sp,-32
    800018e8:	ec06                	sd	ra,24(sp)
    800018ea:	e822                	sd	s0,16(sp)
    800018ec:	e426                	sd	s1,8(sp)
    800018ee:	1000                	addi	s0,sp,32
    800018f0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018f2:	fffff097          	auipc	ra,0xfffff
    800018f6:	2a4080e7          	jalr	676(ra) # 80000b96 <holding>
    800018fa:	c909                	beqz	a0,8000190c <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018fc:	749c                	ld	a5,40(s1)
    800018fe:	00978f63          	beq	a5,s1,8000191c <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001902:	60e2                	ld	ra,24(sp)
    80001904:	6442                	ld	s0,16(sp)
    80001906:	64a2                	ld	s1,8(sp)
    80001908:	6105                	addi	sp,sp,32
    8000190a:	8082                	ret
    panic("wakeup1");
    8000190c:	00007517          	auipc	a0,0x7
    80001910:	85450513          	addi	a0,a0,-1964 # 80008160 <digits+0x120>
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	c34080e7          	jalr	-972(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000191c:	4c98                	lw	a4,24(s1)
    8000191e:	4785                	li	a5,1
    80001920:	fef711e3          	bne	a4,a5,80001902 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001924:	4789                	li	a5,2
    80001926:	cc9c                	sw	a5,24(s1)
}
    80001928:	bfe9                	j	80001902 <wakeup1+0x1c>

000000008000192a <procinit>:
{
    8000192a:	715d                	addi	sp,sp,-80
    8000192c:	e486                	sd	ra,72(sp)
    8000192e:	e0a2                	sd	s0,64(sp)
    80001930:	fc26                	sd	s1,56(sp)
    80001932:	f84a                	sd	s2,48(sp)
    80001934:	f44e                	sd	s3,40(sp)
    80001936:	f052                	sd	s4,32(sp)
    80001938:	ec56                	sd	s5,24(sp)
    8000193a:	e85a                	sd	s6,16(sp)
    8000193c:	e45e                	sd	s7,8(sp)
    8000193e:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001940:	00007597          	auipc	a1,0x7
    80001944:	82858593          	addi	a1,a1,-2008 # 80008168 <digits+0x128>
    80001948:	00010517          	auipc	a0,0x10
    8000194c:	00850513          	addi	a0,a0,8 # 80011950 <pid_lock>
    80001950:	fffff097          	auipc	ra,0xfffff
    80001954:	230080e7          	jalr	560(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001958:	00010917          	auipc	s2,0x10
    8000195c:	41090913          	addi	s2,s2,1040 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001960:	00007b97          	auipc	s7,0x7
    80001964:	810b8b93          	addi	s7,s7,-2032 # 80008170 <digits+0x130>
      uint64 va = KSTACK((int) (p - proc));
    80001968:	8b4a                	mv	s6,s2
    8000196a:	00006a97          	auipc	s5,0x6
    8000196e:	696a8a93          	addi	s5,s5,1686 # 80008000 <etext>
    80001972:	040009b7          	lui	s3,0x4000
    80001976:	19fd                	addi	s3,s3,-1
    80001978:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197a:	00016a17          	auipc	s4,0x16
    8000197e:	deea0a13          	addi	s4,s4,-530 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001982:	85de                	mv	a1,s7
    80001984:	854a                	mv	a0,s2
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	1fa080e7          	jalr	506(ra) # 80000b80 <initlock>
      char *pa = kalloc();
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	192080e7          	jalr	402(ra) # 80000b20 <kalloc>
    80001996:	85aa                	mv	a1,a0
      if(pa == 0)
    80001998:	c929                	beqz	a0,800019ea <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000199a:	416904b3          	sub	s1,s2,s6
    8000199e:	848d                	srai	s1,s1,0x3
    800019a0:	000ab783          	ld	a5,0(s5)
    800019a4:	02f484b3          	mul	s1,s1,a5
    800019a8:	2485                	addiw	s1,s1,1
    800019aa:	00d4949b          	slliw	s1,s1,0xd
    800019ae:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019b2:	4699                	li	a3,6
    800019b4:	6605                	lui	a2,0x1
    800019b6:	8526                	mv	a0,s1
    800019b8:	00000097          	auipc	ra,0x0
    800019bc:	896080e7          	jalr	-1898(ra) # 8000124e <kvmmap>
      p->kstack = va;
    800019c0:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c4:	16890913          	addi	s2,s2,360
    800019c8:	fb491de3          	bne	s2,s4,80001982 <procinit+0x58>
  kvminithart();
    800019cc:	fffff097          	auipc	ra,0xfffff
    800019d0:	608080e7          	jalr	1544(ra) # 80000fd4 <kvminithart>
}
    800019d4:	60a6                	ld	ra,72(sp)
    800019d6:	6406                	ld	s0,64(sp)
    800019d8:	74e2                	ld	s1,56(sp)
    800019da:	7942                	ld	s2,48(sp)
    800019dc:	79a2                	ld	s3,40(sp)
    800019de:	7a02                	ld	s4,32(sp)
    800019e0:	6ae2                	ld	s5,24(sp)
    800019e2:	6b42                	ld	s6,16(sp)
    800019e4:	6ba2                	ld	s7,8(sp)
    800019e6:	6161                	addi	sp,sp,80
    800019e8:	8082                	ret
        panic("kalloc");
    800019ea:	00006517          	auipc	a0,0x6
    800019ee:	78e50513          	addi	a0,a0,1934 # 80008178 <digits+0x138>
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	b56080e7          	jalr	-1194(ra) # 80000548 <panic>

00000000800019fa <cpuid>:
{
    800019fa:	1141                	addi	sp,sp,-16
    800019fc:	e422                	sd	s0,8(sp)
    800019fe:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a00:	8512                	mv	a0,tp
}
    80001a02:	2501                	sext.w	a0,a0
    80001a04:	6422                	ld	s0,8(sp)
    80001a06:	0141                	addi	sp,sp,16
    80001a08:	8082                	ret

0000000080001a0a <mycpu>:
mycpu(void) {
    80001a0a:	1141                	addi	sp,sp,-16
    80001a0c:	e422                	sd	s0,8(sp)
    80001a0e:	0800                	addi	s0,sp,16
    80001a10:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a12:	2781                	sext.w	a5,a5
    80001a14:	079e                	slli	a5,a5,0x7
}
    80001a16:	00010517          	auipc	a0,0x10
    80001a1a:	f5250513          	addi	a0,a0,-174 # 80011968 <cpus>
    80001a1e:	953e                	add	a0,a0,a5
    80001a20:	6422                	ld	s0,8(sp)
    80001a22:	0141                	addi	sp,sp,16
    80001a24:	8082                	ret

0000000080001a26 <myproc>:
myproc(void) {
    80001a26:	1101                	addi	sp,sp,-32
    80001a28:	ec06                	sd	ra,24(sp)
    80001a2a:	e822                	sd	s0,16(sp)
    80001a2c:	e426                	sd	s1,8(sp)
    80001a2e:	1000                	addi	s0,sp,32
  push_off();
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	194080e7          	jalr	404(ra) # 80000bc4 <push_off>
    80001a38:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a3a:	2781                	sext.w	a5,a5
    80001a3c:	079e                	slli	a5,a5,0x7
    80001a3e:	00010717          	auipc	a4,0x10
    80001a42:	f1270713          	addi	a4,a4,-238 # 80011950 <pid_lock>
    80001a46:	97ba                	add	a5,a5,a4
    80001a48:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	21a080e7          	jalr	538(ra) # 80000c64 <pop_off>
}
    80001a52:	8526                	mv	a0,s1
    80001a54:	60e2                	ld	ra,24(sp)
    80001a56:	6442                	ld	s0,16(sp)
    80001a58:	64a2                	ld	s1,8(sp)
    80001a5a:	6105                	addi	sp,sp,32
    80001a5c:	8082                	ret

0000000080001a5e <forkret>:
{
    80001a5e:	1141                	addi	sp,sp,-16
    80001a60:	e406                	sd	ra,8(sp)
    80001a62:	e022                	sd	s0,0(sp)
    80001a64:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a66:	00000097          	auipc	ra,0x0
    80001a6a:	fc0080e7          	jalr	-64(ra) # 80001a26 <myproc>
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	256080e7          	jalr	598(ra) # 80000cc4 <release>
  if (first) {
    80001a76:	00007797          	auipc	a5,0x7
    80001a7a:	dda7a783          	lw	a5,-550(a5) # 80008850 <first.1662>
    80001a7e:	eb89                	bnez	a5,80001a90 <forkret+0x32>
  usertrapret();
    80001a80:	00001097          	auipc	ra,0x1
    80001a84:	c1c080e7          	jalr	-996(ra) # 8000269c <usertrapret>
}
    80001a88:	60a2                	ld	ra,8(sp)
    80001a8a:	6402                	ld	s0,0(sp)
    80001a8c:	0141                	addi	sp,sp,16
    80001a8e:	8082                	ret
    first = 0;
    80001a90:	00007797          	auipc	a5,0x7
    80001a94:	dc07a023          	sw	zero,-576(a5) # 80008850 <first.1662>
    fsinit(ROOTDEV);
    80001a98:	4505                	li	a0,1
    80001a9a:	00002097          	auipc	ra,0x2
    80001a9e:	a3a080e7          	jalr	-1478(ra) # 800034d4 <fsinit>
    80001aa2:	bff9                	j	80001a80 <forkret+0x22>

0000000080001aa4 <allocpid>:
allocpid() {
    80001aa4:	1101                	addi	sp,sp,-32
    80001aa6:	ec06                	sd	ra,24(sp)
    80001aa8:	e822                	sd	s0,16(sp)
    80001aaa:	e426                	sd	s1,8(sp)
    80001aac:	e04a                	sd	s2,0(sp)
    80001aae:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ab0:	00010917          	auipc	s2,0x10
    80001ab4:	ea090913          	addi	s2,s2,-352 # 80011950 <pid_lock>
    80001ab8:	854a                	mv	a0,s2
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	156080e7          	jalr	342(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001ac2:	00007797          	auipc	a5,0x7
    80001ac6:	d9278793          	addi	a5,a5,-622 # 80008854 <nextpid>
    80001aca:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001acc:	0014871b          	addiw	a4,s1,1
    80001ad0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad2:	854a                	mv	a0,s2
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	1f0080e7          	jalr	496(ra) # 80000cc4 <release>
}
    80001adc:	8526                	mv	a0,s1
    80001ade:	60e2                	ld	ra,24(sp)
    80001ae0:	6442                	ld	s0,16(sp)
    80001ae2:	64a2                	ld	s1,8(sp)
    80001ae4:	6902                	ld	s2,0(sp)
    80001ae6:	6105                	addi	sp,sp,32
    80001ae8:	8082                	ret

0000000080001aea <proc_pagetable>:
{
    80001aea:	1101                	addi	sp,sp,-32
    80001aec:	ec06                	sd	ra,24(sp)
    80001aee:	e822                	sd	s0,16(sp)
    80001af0:	e426                	sd	s1,8(sp)
    80001af2:	e04a                	sd	s2,0(sp)
    80001af4:	1000                	addi	s0,sp,32
    80001af6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001af8:	00000097          	auipc	ra,0x0
    80001afc:	906080e7          	jalr	-1786(ra) # 800013fe <uvmcreate>
    80001b00:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b02:	c121                	beqz	a0,80001b42 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b04:	4729                	li	a4,10
    80001b06:	00005697          	auipc	a3,0x5
    80001b0a:	4fa68693          	addi	a3,a3,1274 # 80007000 <_trampoline>
    80001b0e:	6605                	lui	a2,0x1
    80001b10:	040005b7          	lui	a1,0x4000
    80001b14:	15fd                	addi	a1,a1,-1
    80001b16:	05b2                	slli	a1,a1,0xc
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	5e4080e7          	jalr	1508(ra) # 800010fc <mappages>
    80001b20:	02054863          	bltz	a0,80001b50 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b24:	4719                	li	a4,6
    80001b26:	05893683          	ld	a3,88(s2)
    80001b2a:	6605                	lui	a2,0x1
    80001b2c:	020005b7          	lui	a1,0x2000
    80001b30:	15fd                	addi	a1,a1,-1
    80001b32:	05b6                	slli	a1,a1,0xd
    80001b34:	8526                	mv	a0,s1
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	5c6080e7          	jalr	1478(ra) # 800010fc <mappages>
    80001b3e:	02054163          	bltz	a0,80001b60 <proc_pagetable+0x76>
}
    80001b42:	8526                	mv	a0,s1
    80001b44:	60e2                	ld	ra,24(sp)
    80001b46:	6442                	ld	s0,16(sp)
    80001b48:	64a2                	ld	s1,8(sp)
    80001b4a:	6902                	ld	s2,0(sp)
    80001b4c:	6105                	addi	sp,sp,32
    80001b4e:	8082                	ret
    uvmfree(pagetable, 0);
    80001b50:	4581                	li	a1,0
    80001b52:	8526                	mv	a0,s1
    80001b54:	00000097          	auipc	ra,0x0
    80001b58:	aa6080e7          	jalr	-1370(ra) # 800015fa <uvmfree>
    return 0;
    80001b5c:	4481                	li	s1,0
    80001b5e:	b7d5                	j	80001b42 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b60:	4681                	li	a3,0
    80001b62:	4605                	li	a2,1
    80001b64:	040005b7          	lui	a1,0x4000
    80001b68:	15fd                	addi	a1,a1,-1
    80001b6a:	05b2                	slli	a1,a1,0xc
    80001b6c:	8526                	mv	a0,s1
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	7ea080e7          	jalr	2026(ra) # 80001358 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b76:	4581                	li	a1,0
    80001b78:	8526                	mv	a0,s1
    80001b7a:	00000097          	auipc	ra,0x0
    80001b7e:	a80080e7          	jalr	-1408(ra) # 800015fa <uvmfree>
    return 0;
    80001b82:	4481                	li	s1,0
    80001b84:	bf7d                	j	80001b42 <proc_pagetable+0x58>

0000000080001b86 <proc_freepagetable>:
{
    80001b86:	1101                	addi	sp,sp,-32
    80001b88:	ec06                	sd	ra,24(sp)
    80001b8a:	e822                	sd	s0,16(sp)
    80001b8c:	e426                	sd	s1,8(sp)
    80001b8e:	e04a                	sd	s2,0(sp)
    80001b90:	1000                	addi	s0,sp,32
    80001b92:	84aa                	mv	s1,a0
    80001b94:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b96:	4681                	li	a3,0
    80001b98:	4605                	li	a2,1
    80001b9a:	040005b7          	lui	a1,0x4000
    80001b9e:	15fd                	addi	a1,a1,-1
    80001ba0:	05b2                	slli	a1,a1,0xc
    80001ba2:	fffff097          	auipc	ra,0xfffff
    80001ba6:	7b6080e7          	jalr	1974(ra) # 80001358 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001baa:	4681                	li	a3,0
    80001bac:	4605                	li	a2,1
    80001bae:	020005b7          	lui	a1,0x2000
    80001bb2:	15fd                	addi	a1,a1,-1
    80001bb4:	05b6                	slli	a1,a1,0xd
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	7a0080e7          	jalr	1952(ra) # 80001358 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc0:	85ca                	mv	a1,s2
    80001bc2:	8526                	mv	a0,s1
    80001bc4:	00000097          	auipc	ra,0x0
    80001bc8:	a36080e7          	jalr	-1482(ra) # 800015fa <uvmfree>
}
    80001bcc:	60e2                	ld	ra,24(sp)
    80001bce:	6442                	ld	s0,16(sp)
    80001bd0:	64a2                	ld	s1,8(sp)
    80001bd2:	6902                	ld	s2,0(sp)
    80001bd4:	6105                	addi	sp,sp,32
    80001bd6:	8082                	ret

0000000080001bd8 <freeproc>:
{
    80001bd8:	1101                	addi	sp,sp,-32
    80001bda:	ec06                	sd	ra,24(sp)
    80001bdc:	e822                	sd	s0,16(sp)
    80001bde:	e426                	sd	s1,8(sp)
    80001be0:	1000                	addi	s0,sp,32
    80001be2:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001be4:	6d28                	ld	a0,88(a0)
    80001be6:	c509                	beqz	a0,80001bf0 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001be8:	fffff097          	auipc	ra,0xfffff
    80001bec:	e3c080e7          	jalr	-452(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001bf0:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bf4:	68a8                	ld	a0,80(s1)
    80001bf6:	c511                	beqz	a0,80001c02 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bf8:	64ac                	ld	a1,72(s1)
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	f8c080e7          	jalr	-116(ra) # 80001b86 <proc_freepagetable>
  p->pagetable = 0;
    80001c02:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c06:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c0a:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c0e:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c12:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c16:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c1a:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c1e:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c22:	0004ac23          	sw	zero,24(s1)
}
    80001c26:	60e2                	ld	ra,24(sp)
    80001c28:	6442                	ld	s0,16(sp)
    80001c2a:	64a2                	ld	s1,8(sp)
    80001c2c:	6105                	addi	sp,sp,32
    80001c2e:	8082                	ret

0000000080001c30 <allocproc>:
{
    80001c30:	1101                	addi	sp,sp,-32
    80001c32:	ec06                	sd	ra,24(sp)
    80001c34:	e822                	sd	s0,16(sp)
    80001c36:	e426                	sd	s1,8(sp)
    80001c38:	e04a                	sd	s2,0(sp)
    80001c3a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c3c:	00010497          	auipc	s1,0x10
    80001c40:	12c48493          	addi	s1,s1,300 # 80011d68 <proc>
    80001c44:	00016917          	auipc	s2,0x16
    80001c48:	b2490913          	addi	s2,s2,-1244 # 80017768 <tickslock>
    acquire(&p->lock);
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	fc2080e7          	jalr	-62(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001c56:	4c9c                	lw	a5,24(s1)
    80001c58:	cf81                	beqz	a5,80001c70 <allocproc+0x40>
      release(&p->lock);
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	068080e7          	jalr	104(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c64:	16848493          	addi	s1,s1,360
    80001c68:	ff2492e3          	bne	s1,s2,80001c4c <allocproc+0x1c>
  return 0;
    80001c6c:	4481                	li	s1,0
    80001c6e:	a0b9                	j	80001cbc <allocproc+0x8c>
  p->pid = allocpid();
    80001c70:	00000097          	auipc	ra,0x0
    80001c74:	e34080e7          	jalr	-460(ra) # 80001aa4 <allocpid>
    80001c78:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	ea6080e7          	jalr	-346(ra) # 80000b20 <kalloc>
    80001c82:	892a                	mv	s2,a0
    80001c84:	eca8                	sd	a0,88(s1)
    80001c86:	c131                	beqz	a0,80001cca <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c88:	8526                	mv	a0,s1
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	e60080e7          	jalr	-416(ra) # 80001aea <proc_pagetable>
    80001c92:	892a                	mv	s2,a0
    80001c94:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c96:	c129                	beqz	a0,80001cd8 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c98:	07000613          	li	a2,112
    80001c9c:	4581                	li	a1,0
    80001c9e:	06048513          	addi	a0,s1,96
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	06a080e7          	jalr	106(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001caa:	00000797          	auipc	a5,0x0
    80001cae:	db478793          	addi	a5,a5,-588 # 80001a5e <forkret>
    80001cb2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cb4:	60bc                	ld	a5,64(s1)
    80001cb6:	6705                	lui	a4,0x1
    80001cb8:	97ba                	add	a5,a5,a4
    80001cba:	f4bc                	sd	a5,104(s1)
}
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	60e2                	ld	ra,24(sp)
    80001cc0:	6442                	ld	s0,16(sp)
    80001cc2:	64a2                	ld	s1,8(sp)
    80001cc4:	6902                	ld	s2,0(sp)
    80001cc6:	6105                	addi	sp,sp,32
    80001cc8:	8082                	ret
    release(&p->lock);
    80001cca:	8526                	mv	a0,s1
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	ff8080e7          	jalr	-8(ra) # 80000cc4 <release>
    return 0;
    80001cd4:	84ca                	mv	s1,s2
    80001cd6:	b7dd                	j	80001cbc <allocproc+0x8c>
    freeproc(p);
    80001cd8:	8526                	mv	a0,s1
    80001cda:	00000097          	auipc	ra,0x0
    80001cde:	efe080e7          	jalr	-258(ra) # 80001bd8 <freeproc>
    release(&p->lock);
    80001ce2:	8526                	mv	a0,s1
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	fe0080e7          	jalr	-32(ra) # 80000cc4 <release>
    return 0;
    80001cec:	84ca                	mv	s1,s2
    80001cee:	b7f9                	j	80001cbc <allocproc+0x8c>

0000000080001cf0 <userinit>:
{
    80001cf0:	1101                	addi	sp,sp,-32
    80001cf2:	ec06                	sd	ra,24(sp)
    80001cf4:	e822                	sd	s0,16(sp)
    80001cf6:	e426                	sd	s1,8(sp)
    80001cf8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cfa:	00000097          	auipc	ra,0x0
    80001cfe:	f36080e7          	jalr	-202(ra) # 80001c30 <allocproc>
    80001d02:	84aa                	mv	s1,a0
  initproc = p;
    80001d04:	00007797          	auipc	a5,0x7
    80001d08:	30a7ba23          	sd	a0,788(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d0c:	03400613          	li	a2,52
    80001d10:	00007597          	auipc	a1,0x7
    80001d14:	b5058593          	addi	a1,a1,-1200 # 80008860 <initcode>
    80001d18:	6928                	ld	a0,80(a0)
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	712080e7          	jalr	1810(ra) # 8000142c <uvminit>
  p->sz = PGSIZE;
    80001d22:	6785                	lui	a5,0x1
    80001d24:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d26:	6cb8                	ld	a4,88(s1)
    80001d28:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d2c:	6cb8                	ld	a4,88(s1)
    80001d2e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d30:	4641                	li	a2,16
    80001d32:	00006597          	auipc	a1,0x6
    80001d36:	44e58593          	addi	a1,a1,1102 # 80008180 <digits+0x140>
    80001d3a:	15848513          	addi	a0,s1,344
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	124080e7          	jalr	292(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001d46:	00006517          	auipc	a0,0x6
    80001d4a:	44a50513          	addi	a0,a0,1098 # 80008190 <digits+0x150>
    80001d4e:	00002097          	auipc	ra,0x2
    80001d52:	1b2080e7          	jalr	434(ra) # 80003f00 <namei>
    80001d56:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d5a:	4789                	li	a5,2
    80001d5c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d5e:	8526                	mv	a0,s1
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	f64080e7          	jalr	-156(ra) # 80000cc4 <release>
}
    80001d68:	60e2                	ld	ra,24(sp)
    80001d6a:	6442                	ld	s0,16(sp)
    80001d6c:	64a2                	ld	s1,8(sp)
    80001d6e:	6105                	addi	sp,sp,32
    80001d70:	8082                	ret

0000000080001d72 <growproc>:
{
    80001d72:	1101                	addi	sp,sp,-32
    80001d74:	ec06                	sd	ra,24(sp)
    80001d76:	e822                	sd	s0,16(sp)
    80001d78:	e426                	sd	s1,8(sp)
    80001d7a:	e04a                	sd	s2,0(sp)
    80001d7c:	1000                	addi	s0,sp,32
    80001d7e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	ca6080e7          	jalr	-858(ra) # 80001a26 <myproc>
    80001d88:	892a                	mv	s2,a0
  sz = p->sz;
    80001d8a:	652c                	ld	a1,72(a0)
    80001d8c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d90:	00904f63          	bgtz	s1,80001dae <growproc+0x3c>
  } else if(n < 0){
    80001d94:	0204cc63          	bltz	s1,80001dcc <growproc+0x5a>
  p->sz = sz;
    80001d98:	1602                	slli	a2,a2,0x20
    80001d9a:	9201                	srli	a2,a2,0x20
    80001d9c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001da0:	4501                	li	a0,0
}
    80001da2:	60e2                	ld	ra,24(sp)
    80001da4:	6442                	ld	s0,16(sp)
    80001da6:	64a2                	ld	s1,8(sp)
    80001da8:	6902                	ld	s2,0(sp)
    80001daa:	6105                	addi	sp,sp,32
    80001dac:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dae:	9e25                	addw	a2,a2,s1
    80001db0:	1602                	slli	a2,a2,0x20
    80001db2:	9201                	srli	a2,a2,0x20
    80001db4:	1582                	slli	a1,a1,0x20
    80001db6:	9181                	srli	a1,a1,0x20
    80001db8:	6928                	ld	a0,80(a0)
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	72c080e7          	jalr	1836(ra) # 800014e6 <uvmalloc>
    80001dc2:	0005061b          	sext.w	a2,a0
    80001dc6:	fa69                	bnez	a2,80001d98 <growproc+0x26>
      return -1;
    80001dc8:	557d                	li	a0,-1
    80001dca:	bfe1                	j	80001da2 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dcc:	9e25                	addw	a2,a2,s1
    80001dce:	1602                	slli	a2,a2,0x20
    80001dd0:	9201                	srli	a2,a2,0x20
    80001dd2:	1582                	slli	a1,a1,0x20
    80001dd4:	9181                	srli	a1,a1,0x20
    80001dd6:	6928                	ld	a0,80(a0)
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	6c6080e7          	jalr	1734(ra) # 8000149e <uvmdealloc>
    80001de0:	0005061b          	sext.w	a2,a0
    80001de4:	bf55                	j	80001d98 <growproc+0x26>

0000000080001de6 <fork>:
{
    80001de6:	7179                	addi	sp,sp,-48
    80001de8:	f406                	sd	ra,40(sp)
    80001dea:	f022                	sd	s0,32(sp)
    80001dec:	ec26                	sd	s1,24(sp)
    80001dee:	e84a                	sd	s2,16(sp)
    80001df0:	e44e                	sd	s3,8(sp)
    80001df2:	e052                	sd	s4,0(sp)
    80001df4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	c30080e7          	jalr	-976(ra) # 80001a26 <myproc>
    80001dfe:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e00:	00000097          	auipc	ra,0x0
    80001e04:	e30080e7          	jalr	-464(ra) # 80001c30 <allocproc>
    80001e08:	c175                	beqz	a0,80001eec <fork+0x106>
    80001e0a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e0c:	04893603          	ld	a2,72(s2)
    80001e10:	692c                	ld	a1,80(a0)
    80001e12:	05093503          	ld	a0,80(s2)
    80001e16:	00000097          	auipc	ra,0x0
    80001e1a:	81c080e7          	jalr	-2020(ra) # 80001632 <uvmcopy>
    80001e1e:	04054863          	bltz	a0,80001e6e <fork+0x88>
  np->sz = p->sz;
    80001e22:	04893783          	ld	a5,72(s2)
    80001e26:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e2a:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e2e:	05893683          	ld	a3,88(s2)
    80001e32:	87b6                	mv	a5,a3
    80001e34:	0589b703          	ld	a4,88(s3)
    80001e38:	12068693          	addi	a3,a3,288
    80001e3c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e40:	6788                	ld	a0,8(a5)
    80001e42:	6b8c                	ld	a1,16(a5)
    80001e44:	6f90                	ld	a2,24(a5)
    80001e46:	01073023          	sd	a6,0(a4)
    80001e4a:	e708                	sd	a0,8(a4)
    80001e4c:	eb0c                	sd	a1,16(a4)
    80001e4e:	ef10                	sd	a2,24(a4)
    80001e50:	02078793          	addi	a5,a5,32
    80001e54:	02070713          	addi	a4,a4,32
    80001e58:	fed792e3          	bne	a5,a3,80001e3c <fork+0x56>
  np->trapframe->a0 = 0;
    80001e5c:	0589b783          	ld	a5,88(s3)
    80001e60:	0607b823          	sd	zero,112(a5)
    80001e64:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e68:	15000a13          	li	s4,336
    80001e6c:	a03d                	j	80001e9a <fork+0xb4>
    freeproc(np);
    80001e6e:	854e                	mv	a0,s3
    80001e70:	00000097          	auipc	ra,0x0
    80001e74:	d68080e7          	jalr	-664(ra) # 80001bd8 <freeproc>
    release(&np->lock);
    80001e78:	854e                	mv	a0,s3
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	e4a080e7          	jalr	-438(ra) # 80000cc4 <release>
    return -1;
    80001e82:	54fd                	li	s1,-1
    80001e84:	a899                	j	80001eda <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e86:	00002097          	auipc	ra,0x2
    80001e8a:	706080e7          	jalr	1798(ra) # 8000458c <filedup>
    80001e8e:	009987b3          	add	a5,s3,s1
    80001e92:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e94:	04a1                	addi	s1,s1,8
    80001e96:	01448763          	beq	s1,s4,80001ea4 <fork+0xbe>
    if(p->ofile[i])
    80001e9a:	009907b3          	add	a5,s2,s1
    80001e9e:	6388                	ld	a0,0(a5)
    80001ea0:	f17d                	bnez	a0,80001e86 <fork+0xa0>
    80001ea2:	bfcd                	j	80001e94 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001ea4:	15093503          	ld	a0,336(s2)
    80001ea8:	00002097          	auipc	ra,0x2
    80001eac:	866080e7          	jalr	-1946(ra) # 8000370e <idup>
    80001eb0:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eb4:	4641                	li	a2,16
    80001eb6:	15890593          	addi	a1,s2,344
    80001eba:	15898513          	addi	a0,s3,344
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	fa4080e7          	jalr	-92(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80001ec6:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001eca:	4789                	li	a5,2
    80001ecc:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ed0:	854e                	mv	a0,s3
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	df2080e7          	jalr	-526(ra) # 80000cc4 <release>
}
    80001eda:	8526                	mv	a0,s1
    80001edc:	70a2                	ld	ra,40(sp)
    80001ede:	7402                	ld	s0,32(sp)
    80001ee0:	64e2                	ld	s1,24(sp)
    80001ee2:	6942                	ld	s2,16(sp)
    80001ee4:	69a2                	ld	s3,8(sp)
    80001ee6:	6a02                	ld	s4,0(sp)
    80001ee8:	6145                	addi	sp,sp,48
    80001eea:	8082                	ret
    return -1;
    80001eec:	54fd                	li	s1,-1
    80001eee:	b7f5                	j	80001eda <fork+0xf4>

0000000080001ef0 <reparent>:
{
    80001ef0:	7179                	addi	sp,sp,-48
    80001ef2:	f406                	sd	ra,40(sp)
    80001ef4:	f022                	sd	s0,32(sp)
    80001ef6:	ec26                	sd	s1,24(sp)
    80001ef8:	e84a                	sd	s2,16(sp)
    80001efa:	e44e                	sd	s3,8(sp)
    80001efc:	e052                	sd	s4,0(sp)
    80001efe:	1800                	addi	s0,sp,48
    80001f00:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f02:	00010497          	auipc	s1,0x10
    80001f06:	e6648493          	addi	s1,s1,-410 # 80011d68 <proc>
      pp->parent = initproc;
    80001f0a:	00007a17          	auipc	s4,0x7
    80001f0e:	10ea0a13          	addi	s4,s4,270 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f12:	00016997          	auipc	s3,0x16
    80001f16:	85698993          	addi	s3,s3,-1962 # 80017768 <tickslock>
    80001f1a:	a029                	j	80001f24 <reparent+0x34>
    80001f1c:	16848493          	addi	s1,s1,360
    80001f20:	03348363          	beq	s1,s3,80001f46 <reparent+0x56>
    if(pp->parent == p){
    80001f24:	709c                	ld	a5,32(s1)
    80001f26:	ff279be3          	bne	a5,s2,80001f1c <reparent+0x2c>
      acquire(&pp->lock);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	ce4080e7          	jalr	-796(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    80001f34:	000a3783          	ld	a5,0(s4)
    80001f38:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f3a:	8526                	mv	a0,s1
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	d88080e7          	jalr	-632(ra) # 80000cc4 <release>
    80001f44:	bfe1                	j	80001f1c <reparent+0x2c>
}
    80001f46:	70a2                	ld	ra,40(sp)
    80001f48:	7402                	ld	s0,32(sp)
    80001f4a:	64e2                	ld	s1,24(sp)
    80001f4c:	6942                	ld	s2,16(sp)
    80001f4e:	69a2                	ld	s3,8(sp)
    80001f50:	6a02                	ld	s4,0(sp)
    80001f52:	6145                	addi	sp,sp,48
    80001f54:	8082                	ret

0000000080001f56 <scheduler>:
{
    80001f56:	711d                	addi	sp,sp,-96
    80001f58:	ec86                	sd	ra,88(sp)
    80001f5a:	e8a2                	sd	s0,80(sp)
    80001f5c:	e4a6                	sd	s1,72(sp)
    80001f5e:	e0ca                	sd	s2,64(sp)
    80001f60:	fc4e                	sd	s3,56(sp)
    80001f62:	f852                	sd	s4,48(sp)
    80001f64:	f456                	sd	s5,40(sp)
    80001f66:	f05a                	sd	s6,32(sp)
    80001f68:	ec5e                	sd	s7,24(sp)
    80001f6a:	e862                	sd	s8,16(sp)
    80001f6c:	e466                	sd	s9,8(sp)
    80001f6e:	1080                	addi	s0,sp,96
    80001f70:	8792                	mv	a5,tp
  int id = r_tp();
    80001f72:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f74:	00779c13          	slli	s8,a5,0x7
    80001f78:	00010717          	auipc	a4,0x10
    80001f7c:	9d870713          	addi	a4,a4,-1576 # 80011950 <pid_lock>
    80001f80:	9762                	add	a4,a4,s8
    80001f82:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f86:	00010717          	auipc	a4,0x10
    80001f8a:	9ea70713          	addi	a4,a4,-1558 # 80011970 <cpus+0x8>
    80001f8e:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80001f90:	4a89                	li	s5,2
        c->proc = p;
    80001f92:	079e                	slli	a5,a5,0x7
    80001f94:	00010b17          	auipc	s6,0x10
    80001f98:	9bcb0b13          	addi	s6,s6,-1604 # 80011950 <pid_lock>
    80001f9c:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f9e:	00015a17          	auipc	s4,0x15
    80001fa2:	7caa0a13          	addi	s4,s4,1994 # 80017768 <tickslock>
    int nproc = 0;
    80001fa6:	4c81                	li	s9,0
    80001fa8:	a8a1                	j	80002000 <scheduler+0xaa>
        p->state = RUNNING;
    80001faa:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001fae:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80001fb2:	06048593          	addi	a1,s1,96
    80001fb6:	8562                	mv	a0,s8
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	63a080e7          	jalr	1594(ra) # 800025f2 <swtch>
        c->proc = 0;
    80001fc0:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	cfe080e7          	jalr	-770(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fce:	16848493          	addi	s1,s1,360
    80001fd2:	01448d63          	beq	s1,s4,80001fec <scheduler+0x96>
      acquire(&p->lock);
    80001fd6:	8526                	mv	a0,s1
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	c38080e7          	jalr	-968(ra) # 80000c10 <acquire>
      if(p->state != UNUSED) {
    80001fe0:	4c9c                	lw	a5,24(s1)
    80001fe2:	d3ed                	beqz	a5,80001fc4 <scheduler+0x6e>
        nproc++;
    80001fe4:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80001fe6:	fd579fe3          	bne	a5,s5,80001fc4 <scheduler+0x6e>
    80001fea:	b7c1                	j	80001faa <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80001fec:	013aca63          	blt	s5,s3,80002000 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ff0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ff4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ff8:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001ffc:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002000:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002004:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002008:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    8000200c:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    8000200e:	00010497          	auipc	s1,0x10
    80002012:	d5a48493          	addi	s1,s1,-678 # 80011d68 <proc>
        p->state = RUNNING;
    80002016:	4b8d                	li	s7,3
    80002018:	bf7d                	j	80001fd6 <scheduler+0x80>

000000008000201a <sched>:
{
    8000201a:	7179                	addi	sp,sp,-48
    8000201c:	f406                	sd	ra,40(sp)
    8000201e:	f022                	sd	s0,32(sp)
    80002020:	ec26                	sd	s1,24(sp)
    80002022:	e84a                	sd	s2,16(sp)
    80002024:	e44e                	sd	s3,8(sp)
    80002026:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002028:	00000097          	auipc	ra,0x0
    8000202c:	9fe080e7          	jalr	-1538(ra) # 80001a26 <myproc>
    80002030:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002032:	fffff097          	auipc	ra,0xfffff
    80002036:	b64080e7          	jalr	-1180(ra) # 80000b96 <holding>
    8000203a:	c93d                	beqz	a0,800020b0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000203c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000203e:	2781                	sext.w	a5,a5
    80002040:	079e                	slli	a5,a5,0x7
    80002042:	00010717          	auipc	a4,0x10
    80002046:	90e70713          	addi	a4,a4,-1778 # 80011950 <pid_lock>
    8000204a:	97ba                	add	a5,a5,a4
    8000204c:	0907a703          	lw	a4,144(a5)
    80002050:	4785                	li	a5,1
    80002052:	06f71763          	bne	a4,a5,800020c0 <sched+0xa6>
  if(p->state == RUNNING)
    80002056:	4c98                	lw	a4,24(s1)
    80002058:	478d                	li	a5,3
    8000205a:	06f70b63          	beq	a4,a5,800020d0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000205e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002062:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002064:	efb5                	bnez	a5,800020e0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002066:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002068:	00010917          	auipc	s2,0x10
    8000206c:	8e890913          	addi	s2,s2,-1816 # 80011950 <pid_lock>
    80002070:	2781                	sext.w	a5,a5
    80002072:	079e                	slli	a5,a5,0x7
    80002074:	97ca                	add	a5,a5,s2
    80002076:	0947a983          	lw	s3,148(a5)
    8000207a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000207c:	2781                	sext.w	a5,a5
    8000207e:	079e                	slli	a5,a5,0x7
    80002080:	00010597          	auipc	a1,0x10
    80002084:	8f058593          	addi	a1,a1,-1808 # 80011970 <cpus+0x8>
    80002088:	95be                	add	a1,a1,a5
    8000208a:	06048513          	addi	a0,s1,96
    8000208e:	00000097          	auipc	ra,0x0
    80002092:	564080e7          	jalr	1380(ra) # 800025f2 <swtch>
    80002096:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002098:	2781                	sext.w	a5,a5
    8000209a:	079e                	slli	a5,a5,0x7
    8000209c:	97ca                	add	a5,a5,s2
    8000209e:	0937aa23          	sw	s3,148(a5)
}
    800020a2:	70a2                	ld	ra,40(sp)
    800020a4:	7402                	ld	s0,32(sp)
    800020a6:	64e2                	ld	s1,24(sp)
    800020a8:	6942                	ld	s2,16(sp)
    800020aa:	69a2                	ld	s3,8(sp)
    800020ac:	6145                	addi	sp,sp,48
    800020ae:	8082                	ret
    panic("sched p->lock");
    800020b0:	00006517          	auipc	a0,0x6
    800020b4:	0e850513          	addi	a0,a0,232 # 80008198 <digits+0x158>
    800020b8:	ffffe097          	auipc	ra,0xffffe
    800020bc:	490080e7          	jalr	1168(ra) # 80000548 <panic>
    panic("sched locks");
    800020c0:	00006517          	auipc	a0,0x6
    800020c4:	0e850513          	addi	a0,a0,232 # 800081a8 <digits+0x168>
    800020c8:	ffffe097          	auipc	ra,0xffffe
    800020cc:	480080e7          	jalr	1152(ra) # 80000548 <panic>
    panic("sched running");
    800020d0:	00006517          	auipc	a0,0x6
    800020d4:	0e850513          	addi	a0,a0,232 # 800081b8 <digits+0x178>
    800020d8:	ffffe097          	auipc	ra,0xffffe
    800020dc:	470080e7          	jalr	1136(ra) # 80000548 <panic>
    panic("sched interruptible");
    800020e0:	00006517          	auipc	a0,0x6
    800020e4:	0e850513          	addi	a0,a0,232 # 800081c8 <digits+0x188>
    800020e8:	ffffe097          	auipc	ra,0xffffe
    800020ec:	460080e7          	jalr	1120(ra) # 80000548 <panic>

00000000800020f0 <exit>:
{
    800020f0:	7179                	addi	sp,sp,-48
    800020f2:	f406                	sd	ra,40(sp)
    800020f4:	f022                	sd	s0,32(sp)
    800020f6:	ec26                	sd	s1,24(sp)
    800020f8:	e84a                	sd	s2,16(sp)
    800020fa:	e44e                	sd	s3,8(sp)
    800020fc:	e052                	sd	s4,0(sp)
    800020fe:	1800                	addi	s0,sp,48
    80002100:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002102:	00000097          	auipc	ra,0x0
    80002106:	924080e7          	jalr	-1756(ra) # 80001a26 <myproc>
    8000210a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000210c:	00007797          	auipc	a5,0x7
    80002110:	f0c7b783          	ld	a5,-244(a5) # 80009018 <initproc>
    80002114:	0d050493          	addi	s1,a0,208
    80002118:	15050913          	addi	s2,a0,336
    8000211c:	02a79363          	bne	a5,a0,80002142 <exit+0x52>
    panic("init exiting");
    80002120:	00006517          	auipc	a0,0x6
    80002124:	0c050513          	addi	a0,a0,192 # 800081e0 <digits+0x1a0>
    80002128:	ffffe097          	auipc	ra,0xffffe
    8000212c:	420080e7          	jalr	1056(ra) # 80000548 <panic>
      fileclose(f);
    80002130:	00002097          	auipc	ra,0x2
    80002134:	4ae080e7          	jalr	1198(ra) # 800045de <fileclose>
      p->ofile[fd] = 0;
    80002138:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000213c:	04a1                	addi	s1,s1,8
    8000213e:	01248563          	beq	s1,s2,80002148 <exit+0x58>
    if(p->ofile[fd]){
    80002142:	6088                	ld	a0,0(s1)
    80002144:	f575                	bnez	a0,80002130 <exit+0x40>
    80002146:	bfdd                	j	8000213c <exit+0x4c>
  begin_op();
    80002148:	00002097          	auipc	ra,0x2
    8000214c:	fc4080e7          	jalr	-60(ra) # 8000410c <begin_op>
  iput(p->cwd);
    80002150:	1509b503          	ld	a0,336(s3)
    80002154:	00001097          	auipc	ra,0x1
    80002158:	7b2080e7          	jalr	1970(ra) # 80003906 <iput>
  end_op();
    8000215c:	00002097          	auipc	ra,0x2
    80002160:	030080e7          	jalr	48(ra) # 8000418c <end_op>
  p->cwd = 0;
    80002164:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002168:	00007497          	auipc	s1,0x7
    8000216c:	eb048493          	addi	s1,s1,-336 # 80009018 <initproc>
    80002170:	6088                	ld	a0,0(s1)
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	a9e080e7          	jalr	-1378(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    8000217a:	6088                	ld	a0,0(s1)
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	76a080e7          	jalr	1898(ra) # 800018e6 <wakeup1>
  release(&initproc->lock);
    80002184:	6088                	ld	a0,0(s1)
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	b3e080e7          	jalr	-1218(ra) # 80000cc4 <release>
  acquire(&p->lock);
    8000218e:	854e                	mv	a0,s3
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	a80080e7          	jalr	-1408(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    80002198:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000219c:	854e                	mv	a0,s3
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	b26080e7          	jalr	-1242(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	a68080e7          	jalr	-1432(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    800021b0:	854e                	mv	a0,s3
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	a5e080e7          	jalr	-1442(ra) # 80000c10 <acquire>
  reparent(p);
    800021ba:	854e                	mv	a0,s3
    800021bc:	00000097          	auipc	ra,0x0
    800021c0:	d34080e7          	jalr	-716(ra) # 80001ef0 <reparent>
  wakeup1(original_parent);
    800021c4:	8526                	mv	a0,s1
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	720080e7          	jalr	1824(ra) # 800018e6 <wakeup1>
  p->xstate = status;
    800021ce:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021d2:	4791                	li	a5,4
    800021d4:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021d8:	8526                	mv	a0,s1
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	aea080e7          	jalr	-1302(ra) # 80000cc4 <release>
  sched();
    800021e2:	00000097          	auipc	ra,0x0
    800021e6:	e38080e7          	jalr	-456(ra) # 8000201a <sched>
  panic("zombie exit");
    800021ea:	00006517          	auipc	a0,0x6
    800021ee:	00650513          	addi	a0,a0,6 # 800081f0 <digits+0x1b0>
    800021f2:	ffffe097          	auipc	ra,0xffffe
    800021f6:	356080e7          	jalr	854(ra) # 80000548 <panic>

00000000800021fa <yield>:
{
    800021fa:	1101                	addi	sp,sp,-32
    800021fc:	ec06                	sd	ra,24(sp)
    800021fe:	e822                	sd	s0,16(sp)
    80002200:	e426                	sd	s1,8(sp)
    80002202:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002204:	00000097          	auipc	ra,0x0
    80002208:	822080e7          	jalr	-2014(ra) # 80001a26 <myproc>
    8000220c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	a02080e7          	jalr	-1534(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    80002216:	4789                	li	a5,2
    80002218:	cc9c                	sw	a5,24(s1)
  sched();
    8000221a:	00000097          	auipc	ra,0x0
    8000221e:	e00080e7          	jalr	-512(ra) # 8000201a <sched>
  release(&p->lock);
    80002222:	8526                	mv	a0,s1
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	aa0080e7          	jalr	-1376(ra) # 80000cc4 <release>
}
    8000222c:	60e2                	ld	ra,24(sp)
    8000222e:	6442                	ld	s0,16(sp)
    80002230:	64a2                	ld	s1,8(sp)
    80002232:	6105                	addi	sp,sp,32
    80002234:	8082                	ret

0000000080002236 <sleep>:
{
    80002236:	7179                	addi	sp,sp,-48
    80002238:	f406                	sd	ra,40(sp)
    8000223a:	f022                	sd	s0,32(sp)
    8000223c:	ec26                	sd	s1,24(sp)
    8000223e:	e84a                	sd	s2,16(sp)
    80002240:	e44e                	sd	s3,8(sp)
    80002242:	1800                	addi	s0,sp,48
    80002244:	89aa                	mv	s3,a0
    80002246:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	7de080e7          	jalr	2014(ra) # 80001a26 <myproc>
    80002250:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002252:	05250663          	beq	a0,s2,8000229e <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	9ba080e7          	jalr	-1606(ra) # 80000c10 <acquire>
    release(lk);
    8000225e:	854a                	mv	a0,s2
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	a64080e7          	jalr	-1436(ra) # 80000cc4 <release>
  p->chan = chan;
    80002268:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000226c:	4785                	li	a5,1
    8000226e:	cc9c                	sw	a5,24(s1)
  sched();
    80002270:	00000097          	auipc	ra,0x0
    80002274:	daa080e7          	jalr	-598(ra) # 8000201a <sched>
  p->chan = 0;
    80002278:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000227c:	8526                	mv	a0,s1
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	a46080e7          	jalr	-1466(ra) # 80000cc4 <release>
    acquire(lk);
    80002286:	854a                	mv	a0,s2
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	988080e7          	jalr	-1656(ra) # 80000c10 <acquire>
}
    80002290:	70a2                	ld	ra,40(sp)
    80002292:	7402                	ld	s0,32(sp)
    80002294:	64e2                	ld	s1,24(sp)
    80002296:	6942                	ld	s2,16(sp)
    80002298:	69a2                	ld	s3,8(sp)
    8000229a:	6145                	addi	sp,sp,48
    8000229c:	8082                	ret
  p->chan = chan;
    8000229e:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022a2:	4785                	li	a5,1
    800022a4:	cd1c                	sw	a5,24(a0)
  sched();
    800022a6:	00000097          	auipc	ra,0x0
    800022aa:	d74080e7          	jalr	-652(ra) # 8000201a <sched>
  p->chan = 0;
    800022ae:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022b2:	bff9                	j	80002290 <sleep+0x5a>

00000000800022b4 <wait>:
{
    800022b4:	715d                	addi	sp,sp,-80
    800022b6:	e486                	sd	ra,72(sp)
    800022b8:	e0a2                	sd	s0,64(sp)
    800022ba:	fc26                	sd	s1,56(sp)
    800022bc:	f84a                	sd	s2,48(sp)
    800022be:	f44e                	sd	s3,40(sp)
    800022c0:	f052                	sd	s4,32(sp)
    800022c2:	ec56                	sd	s5,24(sp)
    800022c4:	e85a                	sd	s6,16(sp)
    800022c6:	e45e                	sd	s7,8(sp)
    800022c8:	e062                	sd	s8,0(sp)
    800022ca:	0880                	addi	s0,sp,80
    800022cc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	758080e7          	jalr	1880(ra) # 80001a26 <myproc>
    800022d6:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022d8:	8c2a                	mv	s8,a0
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	936080e7          	jalr	-1738(ra) # 80000c10 <acquire>
    havekids = 0;
    800022e2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022e4:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022e6:	00015997          	auipc	s3,0x15
    800022ea:	48298993          	addi	s3,s3,1154 # 80017768 <tickslock>
        havekids = 1;
    800022ee:	4a85                	li	s5,1
    havekids = 0;
    800022f0:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022f2:	00010497          	auipc	s1,0x10
    800022f6:	a7648493          	addi	s1,s1,-1418 # 80011d68 <proc>
    800022fa:	a08d                	j	8000235c <wait+0xa8>
          pid = np->pid;
    800022fc:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002300:	000b0e63          	beqz	s6,8000231c <wait+0x68>
    80002304:	4691                	li	a3,4
    80002306:	03448613          	addi	a2,s1,52
    8000230a:	85da                	mv	a1,s6
    8000230c:	05093503          	ld	a0,80(s2)
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	40a080e7          	jalr	1034(ra) # 8000171a <copyout>
    80002318:	02054263          	bltz	a0,8000233c <wait+0x88>
          freeproc(np);
    8000231c:	8526                	mv	a0,s1
    8000231e:	00000097          	auipc	ra,0x0
    80002322:	8ba080e7          	jalr	-1862(ra) # 80001bd8 <freeproc>
          release(&np->lock);
    80002326:	8526                	mv	a0,s1
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	99c080e7          	jalr	-1636(ra) # 80000cc4 <release>
          release(&p->lock);
    80002330:	854a                	mv	a0,s2
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	992080e7          	jalr	-1646(ra) # 80000cc4 <release>
          return pid;
    8000233a:	a8a9                	j	80002394 <wait+0xe0>
            release(&np->lock);
    8000233c:	8526                	mv	a0,s1
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	986080e7          	jalr	-1658(ra) # 80000cc4 <release>
            release(&p->lock);
    80002346:	854a                	mv	a0,s2
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	97c080e7          	jalr	-1668(ra) # 80000cc4 <release>
            return -1;
    80002350:	59fd                	li	s3,-1
    80002352:	a089                	j	80002394 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002354:	16848493          	addi	s1,s1,360
    80002358:	03348463          	beq	s1,s3,80002380 <wait+0xcc>
      if(np->parent == p){
    8000235c:	709c                	ld	a5,32(s1)
    8000235e:	ff279be3          	bne	a5,s2,80002354 <wait+0xa0>
        acquire(&np->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	8ac080e7          	jalr	-1876(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    8000236c:	4c9c                	lw	a5,24(s1)
    8000236e:	f94787e3          	beq	a5,s4,800022fc <wait+0x48>
        release(&np->lock);
    80002372:	8526                	mv	a0,s1
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	950080e7          	jalr	-1712(ra) # 80000cc4 <release>
        havekids = 1;
    8000237c:	8756                	mv	a4,s5
    8000237e:	bfd9                	j	80002354 <wait+0xa0>
    if(!havekids || p->killed){
    80002380:	c701                	beqz	a4,80002388 <wait+0xd4>
    80002382:	03092783          	lw	a5,48(s2)
    80002386:	c785                	beqz	a5,800023ae <wait+0xfa>
      release(&p->lock);
    80002388:	854a                	mv	a0,s2
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	93a080e7          	jalr	-1734(ra) # 80000cc4 <release>
      return -1;
    80002392:	59fd                	li	s3,-1
}
    80002394:	854e                	mv	a0,s3
    80002396:	60a6                	ld	ra,72(sp)
    80002398:	6406                	ld	s0,64(sp)
    8000239a:	74e2                	ld	s1,56(sp)
    8000239c:	7942                	ld	s2,48(sp)
    8000239e:	79a2                	ld	s3,40(sp)
    800023a0:	7a02                	ld	s4,32(sp)
    800023a2:	6ae2                	ld	s5,24(sp)
    800023a4:	6b42                	ld	s6,16(sp)
    800023a6:	6ba2                	ld	s7,8(sp)
    800023a8:	6c02                	ld	s8,0(sp)
    800023aa:	6161                	addi	sp,sp,80
    800023ac:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023ae:	85e2                	mv	a1,s8
    800023b0:	854a                	mv	a0,s2
    800023b2:	00000097          	auipc	ra,0x0
    800023b6:	e84080e7          	jalr	-380(ra) # 80002236 <sleep>
    havekids = 0;
    800023ba:	bf1d                	j	800022f0 <wait+0x3c>

00000000800023bc <wakeup>:
{
    800023bc:	7139                	addi	sp,sp,-64
    800023be:	fc06                	sd	ra,56(sp)
    800023c0:	f822                	sd	s0,48(sp)
    800023c2:	f426                	sd	s1,40(sp)
    800023c4:	f04a                	sd	s2,32(sp)
    800023c6:	ec4e                	sd	s3,24(sp)
    800023c8:	e852                	sd	s4,16(sp)
    800023ca:	e456                	sd	s5,8(sp)
    800023cc:	0080                	addi	s0,sp,64
    800023ce:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023d0:	00010497          	auipc	s1,0x10
    800023d4:	99848493          	addi	s1,s1,-1640 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023d8:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023da:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023dc:	00015917          	auipc	s2,0x15
    800023e0:	38c90913          	addi	s2,s2,908 # 80017768 <tickslock>
    800023e4:	a821                	j	800023fc <wakeup+0x40>
      p->state = RUNNABLE;
    800023e6:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	8d8080e7          	jalr	-1832(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023f4:	16848493          	addi	s1,s1,360
    800023f8:	01248e63          	beq	s1,s2,80002414 <wakeup+0x58>
    acquire(&p->lock);
    800023fc:	8526                	mv	a0,s1
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	812080e7          	jalr	-2030(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002406:	4c9c                	lw	a5,24(s1)
    80002408:	ff3791e3          	bne	a5,s3,800023ea <wakeup+0x2e>
    8000240c:	749c                	ld	a5,40(s1)
    8000240e:	fd479ee3          	bne	a5,s4,800023ea <wakeup+0x2e>
    80002412:	bfd1                	j	800023e6 <wakeup+0x2a>
}
    80002414:	70e2                	ld	ra,56(sp)
    80002416:	7442                	ld	s0,48(sp)
    80002418:	74a2                	ld	s1,40(sp)
    8000241a:	7902                	ld	s2,32(sp)
    8000241c:	69e2                	ld	s3,24(sp)
    8000241e:	6a42                	ld	s4,16(sp)
    80002420:	6aa2                	ld	s5,8(sp)
    80002422:	6121                	addi	sp,sp,64
    80002424:	8082                	ret

0000000080002426 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002426:	7179                	addi	sp,sp,-48
    80002428:	f406                	sd	ra,40(sp)
    8000242a:	f022                	sd	s0,32(sp)
    8000242c:	ec26                	sd	s1,24(sp)
    8000242e:	e84a                	sd	s2,16(sp)
    80002430:	e44e                	sd	s3,8(sp)
    80002432:	1800                	addi	s0,sp,48
    80002434:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002436:	00010497          	auipc	s1,0x10
    8000243a:	93248493          	addi	s1,s1,-1742 # 80011d68 <proc>
    8000243e:	00015997          	auipc	s3,0x15
    80002442:	32a98993          	addi	s3,s3,810 # 80017768 <tickslock>
    acquire(&p->lock);
    80002446:	8526                	mv	a0,s1
    80002448:	ffffe097          	auipc	ra,0xffffe
    8000244c:	7c8080e7          	jalr	1992(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    80002450:	5c9c                	lw	a5,56(s1)
    80002452:	01278d63          	beq	a5,s2,8000246c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	86c080e7          	jalr	-1940(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002460:	16848493          	addi	s1,s1,360
    80002464:	ff3491e3          	bne	s1,s3,80002446 <kill+0x20>
  }
  return -1;
    80002468:	557d                	li	a0,-1
    8000246a:	a829                	j	80002484 <kill+0x5e>
      p->killed = 1;
    8000246c:	4785                	li	a5,1
    8000246e:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002470:	4c98                	lw	a4,24(s1)
    80002472:	4785                	li	a5,1
    80002474:	00f70f63          	beq	a4,a5,80002492 <kill+0x6c>
      release(&p->lock);
    80002478:	8526                	mv	a0,s1
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	84a080e7          	jalr	-1974(ra) # 80000cc4 <release>
      return 0;
    80002482:	4501                	li	a0,0
}
    80002484:	70a2                	ld	ra,40(sp)
    80002486:	7402                	ld	s0,32(sp)
    80002488:	64e2                	ld	s1,24(sp)
    8000248a:	6942                	ld	s2,16(sp)
    8000248c:	69a2                	ld	s3,8(sp)
    8000248e:	6145                	addi	sp,sp,48
    80002490:	8082                	ret
        p->state = RUNNABLE;
    80002492:	4789                	li	a5,2
    80002494:	cc9c                	sw	a5,24(s1)
    80002496:	b7cd                	j	80002478 <kill+0x52>

0000000080002498 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002498:	7179                	addi	sp,sp,-48
    8000249a:	f406                	sd	ra,40(sp)
    8000249c:	f022                	sd	s0,32(sp)
    8000249e:	ec26                	sd	s1,24(sp)
    800024a0:	e84a                	sd	s2,16(sp)
    800024a2:	e44e                	sd	s3,8(sp)
    800024a4:	e052                	sd	s4,0(sp)
    800024a6:	1800                	addi	s0,sp,48
    800024a8:	84aa                	mv	s1,a0
    800024aa:	892e                	mv	s2,a1
    800024ac:	89b2                	mv	s3,a2
    800024ae:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	576080e7          	jalr	1398(ra) # 80001a26 <myproc>
  if(user_dst){
    800024b8:	c08d                	beqz	s1,800024da <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024ba:	86d2                	mv	a3,s4
    800024bc:	864e                	mv	a2,s3
    800024be:	85ca                	mv	a1,s2
    800024c0:	6928                	ld	a0,80(a0)
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	258080e7          	jalr	600(ra) # 8000171a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024ca:	70a2                	ld	ra,40(sp)
    800024cc:	7402                	ld	s0,32(sp)
    800024ce:	64e2                	ld	s1,24(sp)
    800024d0:	6942                	ld	s2,16(sp)
    800024d2:	69a2                	ld	s3,8(sp)
    800024d4:	6a02                	ld	s4,0(sp)
    800024d6:	6145                	addi	sp,sp,48
    800024d8:	8082                	ret
    memmove((char *)dst, src, len);
    800024da:	000a061b          	sext.w	a2,s4
    800024de:	85ce                	mv	a1,s3
    800024e0:	854a                	mv	a0,s2
    800024e2:	fffff097          	auipc	ra,0xfffff
    800024e6:	88a080e7          	jalr	-1910(ra) # 80000d6c <memmove>
    return 0;
    800024ea:	8526                	mv	a0,s1
    800024ec:	bff9                	j	800024ca <either_copyout+0x32>

00000000800024ee <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024ee:	7179                	addi	sp,sp,-48
    800024f0:	f406                	sd	ra,40(sp)
    800024f2:	f022                	sd	s0,32(sp)
    800024f4:	ec26                	sd	s1,24(sp)
    800024f6:	e84a                	sd	s2,16(sp)
    800024f8:	e44e                	sd	s3,8(sp)
    800024fa:	e052                	sd	s4,0(sp)
    800024fc:	1800                	addi	s0,sp,48
    800024fe:	892a                	mv	s2,a0
    80002500:	84ae                	mv	s1,a1
    80002502:	89b2                	mv	s3,a2
    80002504:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	520080e7          	jalr	1312(ra) # 80001a26 <myproc>
  if(user_src){
    8000250e:	c08d                	beqz	s1,80002530 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002510:	86d2                	mv	a3,s4
    80002512:	864e                	mv	a2,s3
    80002514:	85ca                	mv	a1,s2
    80002516:	6928                	ld	a0,80(a0)
    80002518:	fffff097          	auipc	ra,0xfffff
    8000251c:	28e080e7          	jalr	654(ra) # 800017a6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002520:	70a2                	ld	ra,40(sp)
    80002522:	7402                	ld	s0,32(sp)
    80002524:	64e2                	ld	s1,24(sp)
    80002526:	6942                	ld	s2,16(sp)
    80002528:	69a2                	ld	s3,8(sp)
    8000252a:	6a02                	ld	s4,0(sp)
    8000252c:	6145                	addi	sp,sp,48
    8000252e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002530:	000a061b          	sext.w	a2,s4
    80002534:	85ce                	mv	a1,s3
    80002536:	854a                	mv	a0,s2
    80002538:	fffff097          	auipc	ra,0xfffff
    8000253c:	834080e7          	jalr	-1996(ra) # 80000d6c <memmove>
    return 0;
    80002540:	8526                	mv	a0,s1
    80002542:	bff9                	j	80002520 <either_copyin+0x32>

0000000080002544 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002544:	715d                	addi	sp,sp,-80
    80002546:	e486                	sd	ra,72(sp)
    80002548:	e0a2                	sd	s0,64(sp)
    8000254a:	fc26                	sd	s1,56(sp)
    8000254c:	f84a                	sd	s2,48(sp)
    8000254e:	f44e                	sd	s3,40(sp)
    80002550:	f052                	sd	s4,32(sp)
    80002552:	ec56                	sd	s5,24(sp)
    80002554:	e85a                	sd	s6,16(sp)
    80002556:	e45e                	sd	s7,8(sp)
    80002558:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000255a:	00006517          	auipc	a0,0x6
    8000255e:	b6e50513          	addi	a0,a0,-1170 # 800080c8 <digits+0x88>
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	030080e7          	jalr	48(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000256a:	00010497          	auipc	s1,0x10
    8000256e:	95648493          	addi	s1,s1,-1706 # 80011ec0 <proc+0x158>
    80002572:	00015917          	auipc	s2,0x15
    80002576:	34e90913          	addi	s2,s2,846 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000257a:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000257c:	00006997          	auipc	s3,0x6
    80002580:	c8498993          	addi	s3,s3,-892 # 80008200 <digits+0x1c0>
    printf("%d %s %s", p->pid, state, p->name);
    80002584:	00006a97          	auipc	s5,0x6
    80002588:	c84a8a93          	addi	s5,s5,-892 # 80008208 <digits+0x1c8>
    printf("\n");
    8000258c:	00006a17          	auipc	s4,0x6
    80002590:	b3ca0a13          	addi	s4,s4,-1220 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002594:	00006b97          	auipc	s7,0x6
    80002598:	cacb8b93          	addi	s7,s7,-852 # 80008240 <states.1702>
    8000259c:	a00d                	j	800025be <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000259e:	ee06a583          	lw	a1,-288(a3)
    800025a2:	8556                	mv	a0,s5
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	fee080e7          	jalr	-18(ra) # 80000592 <printf>
    printf("\n");
    800025ac:	8552                	mv	a0,s4
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	fe4080e7          	jalr	-28(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025b6:	16848493          	addi	s1,s1,360
    800025ba:	03248163          	beq	s1,s2,800025dc <procdump+0x98>
    if(p->state == UNUSED)
    800025be:	86a6                	mv	a3,s1
    800025c0:	ec04a783          	lw	a5,-320(s1)
    800025c4:	dbed                	beqz	a5,800025b6 <procdump+0x72>
      state = "???";
    800025c6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025c8:	fcfb6be3          	bltu	s6,a5,8000259e <procdump+0x5a>
    800025cc:	1782                	slli	a5,a5,0x20
    800025ce:	9381                	srli	a5,a5,0x20
    800025d0:	078e                	slli	a5,a5,0x3
    800025d2:	97de                	add	a5,a5,s7
    800025d4:	6390                	ld	a2,0(a5)
    800025d6:	f661                	bnez	a2,8000259e <procdump+0x5a>
      state = "???";
    800025d8:	864e                	mv	a2,s3
    800025da:	b7d1                	j	8000259e <procdump+0x5a>
  }
}
    800025dc:	60a6                	ld	ra,72(sp)
    800025de:	6406                	ld	s0,64(sp)
    800025e0:	74e2                	ld	s1,56(sp)
    800025e2:	7942                	ld	s2,48(sp)
    800025e4:	79a2                	ld	s3,40(sp)
    800025e6:	7a02                	ld	s4,32(sp)
    800025e8:	6ae2                	ld	s5,24(sp)
    800025ea:	6b42                	ld	s6,16(sp)
    800025ec:	6ba2                	ld	s7,8(sp)
    800025ee:	6161                	addi	sp,sp,80
    800025f0:	8082                	ret

00000000800025f2 <swtch>:
    800025f2:	00153023          	sd	ra,0(a0)
    800025f6:	00253423          	sd	sp,8(a0)
    800025fa:	e900                	sd	s0,16(a0)
    800025fc:	ed04                	sd	s1,24(a0)
    800025fe:	03253023          	sd	s2,32(a0)
    80002602:	03353423          	sd	s3,40(a0)
    80002606:	03453823          	sd	s4,48(a0)
    8000260a:	03553c23          	sd	s5,56(a0)
    8000260e:	05653023          	sd	s6,64(a0)
    80002612:	05753423          	sd	s7,72(a0)
    80002616:	05853823          	sd	s8,80(a0)
    8000261a:	05953c23          	sd	s9,88(a0)
    8000261e:	07a53023          	sd	s10,96(a0)
    80002622:	07b53423          	sd	s11,104(a0)
    80002626:	0005b083          	ld	ra,0(a1)
    8000262a:	0085b103          	ld	sp,8(a1)
    8000262e:	6980                	ld	s0,16(a1)
    80002630:	6d84                	ld	s1,24(a1)
    80002632:	0205b903          	ld	s2,32(a1)
    80002636:	0285b983          	ld	s3,40(a1)
    8000263a:	0305ba03          	ld	s4,48(a1)
    8000263e:	0385ba83          	ld	s5,56(a1)
    80002642:	0405bb03          	ld	s6,64(a1)
    80002646:	0485bb83          	ld	s7,72(a1)
    8000264a:	0505bc03          	ld	s8,80(a1)
    8000264e:	0585bc83          	ld	s9,88(a1)
    80002652:	0605bd03          	ld	s10,96(a1)
    80002656:	0685bd83          	ld	s11,104(a1)
    8000265a:	8082                	ret

000000008000265c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000265c:	1141                	addi	sp,sp,-16
    8000265e:	e406                	sd	ra,8(sp)
    80002660:	e022                	sd	s0,0(sp)
    80002662:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002664:	00006597          	auipc	a1,0x6
    80002668:	c0458593          	addi	a1,a1,-1020 # 80008268 <states.1702+0x28>
    8000266c:	00015517          	auipc	a0,0x15
    80002670:	0fc50513          	addi	a0,a0,252 # 80017768 <tickslock>
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	50c080e7          	jalr	1292(ra) # 80000b80 <initlock>
}
    8000267c:	60a2                	ld	ra,8(sp)
    8000267e:	6402                	ld	s0,0(sp)
    80002680:	0141                	addi	sp,sp,16
    80002682:	8082                	ret

0000000080002684 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002684:	1141                	addi	sp,sp,-16
    80002686:	e422                	sd	s0,8(sp)
    80002688:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000268a:	00003797          	auipc	a5,0x3
    8000268e:	5c678793          	addi	a5,a5,1478 # 80005c50 <kernelvec>
    80002692:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002696:	6422                	ld	s0,8(sp)
    80002698:	0141                	addi	sp,sp,16
    8000269a:	8082                	ret

000000008000269c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000269c:	1141                	addi	sp,sp,-16
    8000269e:	e406                	sd	ra,8(sp)
    800026a0:	e022                	sd	s0,0(sp)
    800026a2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026a4:	fffff097          	auipc	ra,0xfffff
    800026a8:	382080e7          	jalr	898(ra) # 80001a26 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026b0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026b2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026b6:	00005617          	auipc	a2,0x5
    800026ba:	94a60613          	addi	a2,a2,-1718 # 80007000 <_trampoline>
    800026be:	00005697          	auipc	a3,0x5
    800026c2:	94268693          	addi	a3,a3,-1726 # 80007000 <_trampoline>
    800026c6:	8e91                	sub	a3,a3,a2
    800026c8:	040007b7          	lui	a5,0x4000
    800026cc:	17fd                	addi	a5,a5,-1
    800026ce:	07b2                	slli	a5,a5,0xc
    800026d0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026d2:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026d6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026d8:	180026f3          	csrr	a3,satp
    800026dc:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026de:	6d38                	ld	a4,88(a0)
    800026e0:	6134                	ld	a3,64(a0)
    800026e2:	6585                	lui	a1,0x1
    800026e4:	96ae                	add	a3,a3,a1
    800026e6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026e8:	6d38                	ld	a4,88(a0)
    800026ea:	00000697          	auipc	a3,0x0
    800026ee:	13868693          	addi	a3,a3,312 # 80002822 <usertrap>
    800026f2:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026f4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026f6:	8692                	mv	a3,tp
    800026f8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026fa:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026fe:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002702:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002706:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000270a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000270c:	6f18                	ld	a4,24(a4)
    8000270e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002712:	692c                	ld	a1,80(a0)
    80002714:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002716:	00005717          	auipc	a4,0x5
    8000271a:	97a70713          	addi	a4,a4,-1670 # 80007090 <userret>
    8000271e:	8f11                	sub	a4,a4,a2
    80002720:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002722:	577d                	li	a4,-1
    80002724:	177e                	slli	a4,a4,0x3f
    80002726:	8dd9                	or	a1,a1,a4
    80002728:	02000537          	lui	a0,0x2000
    8000272c:	157d                	addi	a0,a0,-1
    8000272e:	0536                	slli	a0,a0,0xd
    80002730:	9782                	jalr	a5
}
    80002732:	60a2                	ld	ra,8(sp)
    80002734:	6402                	ld	s0,0(sp)
    80002736:	0141                	addi	sp,sp,16
    80002738:	8082                	ret

000000008000273a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000273a:	1101                	addi	sp,sp,-32
    8000273c:	ec06                	sd	ra,24(sp)
    8000273e:	e822                	sd	s0,16(sp)
    80002740:	e426                	sd	s1,8(sp)
    80002742:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002744:	00015497          	auipc	s1,0x15
    80002748:	02448493          	addi	s1,s1,36 # 80017768 <tickslock>
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	4c2080e7          	jalr	1218(ra) # 80000c10 <acquire>
  ticks++;
    80002756:	00007517          	auipc	a0,0x7
    8000275a:	8ca50513          	addi	a0,a0,-1846 # 80009020 <ticks>
    8000275e:	411c                	lw	a5,0(a0)
    80002760:	2785                	addiw	a5,a5,1
    80002762:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002764:	00000097          	auipc	ra,0x0
    80002768:	c58080e7          	jalr	-936(ra) # 800023bc <wakeup>
  release(&tickslock);
    8000276c:	8526                	mv	a0,s1
    8000276e:	ffffe097          	auipc	ra,0xffffe
    80002772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
}
    80002776:	60e2                	ld	ra,24(sp)
    80002778:	6442                	ld	s0,16(sp)
    8000277a:	64a2                	ld	s1,8(sp)
    8000277c:	6105                	addi	sp,sp,32
    8000277e:	8082                	ret

0000000080002780 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002780:	1101                	addi	sp,sp,-32
    80002782:	ec06                	sd	ra,24(sp)
    80002784:	e822                	sd	s0,16(sp)
    80002786:	e426                	sd	s1,8(sp)
    80002788:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000278a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000278e:	00074d63          	bltz	a4,800027a8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002792:	57fd                	li	a5,-1
    80002794:	17fe                	slli	a5,a5,0x3f
    80002796:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002798:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000279a:	06f70363          	beq	a4,a5,80002800 <devintr+0x80>
  }
}
    8000279e:	60e2                	ld	ra,24(sp)
    800027a0:	6442                	ld	s0,16(sp)
    800027a2:	64a2                	ld	s1,8(sp)
    800027a4:	6105                	addi	sp,sp,32
    800027a6:	8082                	ret
     (scause & 0xff) == 9){
    800027a8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027ac:	46a5                	li	a3,9
    800027ae:	fed792e3          	bne	a5,a3,80002792 <devintr+0x12>
    int irq = plic_claim();
    800027b2:	00003097          	auipc	ra,0x3
    800027b6:	5a6080e7          	jalr	1446(ra) # 80005d58 <plic_claim>
    800027ba:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027bc:	47a9                	li	a5,10
    800027be:	02f50763          	beq	a0,a5,800027ec <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027c2:	4785                	li	a5,1
    800027c4:	02f50963          	beq	a0,a5,800027f6 <devintr+0x76>
    return 1;
    800027c8:	4505                	li	a0,1
    } else if(irq){
    800027ca:	d8f1                	beqz	s1,8000279e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027cc:	85a6                	mv	a1,s1
    800027ce:	00006517          	auipc	a0,0x6
    800027d2:	aa250513          	addi	a0,a0,-1374 # 80008270 <states.1702+0x30>
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	dbc080e7          	jalr	-580(ra) # 80000592 <printf>
      plic_complete(irq);
    800027de:	8526                	mv	a0,s1
    800027e0:	00003097          	auipc	ra,0x3
    800027e4:	59c080e7          	jalr	1436(ra) # 80005d7c <plic_complete>
    return 1;
    800027e8:	4505                	li	a0,1
    800027ea:	bf55                	j	8000279e <devintr+0x1e>
      uartintr();
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	1e8080e7          	jalr	488(ra) # 800009d4 <uartintr>
    800027f4:	b7ed                	j	800027de <devintr+0x5e>
      virtio_disk_intr();
    800027f6:	00004097          	auipc	ra,0x4
    800027fa:	a20080e7          	jalr	-1504(ra) # 80006216 <virtio_disk_intr>
    800027fe:	b7c5                	j	800027de <devintr+0x5e>
    if(cpuid() == 0){
    80002800:	fffff097          	auipc	ra,0xfffff
    80002804:	1fa080e7          	jalr	506(ra) # 800019fa <cpuid>
    80002808:	c901                	beqz	a0,80002818 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000280a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000280e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002810:	14479073          	csrw	sip,a5
    return 2;
    80002814:	4509                	li	a0,2
    80002816:	b761                	j	8000279e <devintr+0x1e>
      clockintr();
    80002818:	00000097          	auipc	ra,0x0
    8000281c:	f22080e7          	jalr	-222(ra) # 8000273a <clockintr>
    80002820:	b7ed                	j	8000280a <devintr+0x8a>

0000000080002822 <usertrap>:
{
    80002822:	7179                	addi	sp,sp,-48
    80002824:	f406                	sd	ra,40(sp)
    80002826:	f022                	sd	s0,32(sp)
    80002828:	ec26                	sd	s1,24(sp)
    8000282a:	e84a                	sd	s2,16(sp)
    8000282c:	e44e                	sd	s3,8(sp)
    8000282e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002830:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002834:	1007f793          	andi	a5,a5,256
    80002838:	e7cd                	bnez	a5,800028e2 <usertrap+0xc0>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000283a:	00003797          	auipc	a5,0x3
    8000283e:	41678793          	addi	a5,a5,1046 # 80005c50 <kernelvec>
    80002842:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002846:	fffff097          	auipc	ra,0xfffff
    8000284a:	1e0080e7          	jalr	480(ra) # 80001a26 <myproc>
    8000284e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002850:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002852:	14102773          	csrr	a4,sepc
    80002856:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002858:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000285c:	47a1                	li	a5,8
    8000285e:	08f70a63          	beq	a4,a5,800028f2 <usertrap+0xd0>
    80002862:	14202773          	csrr	a4,scause
  } else if (r_scause() == 13 || r_scause() == 15) {    //new code
    80002866:	47b5                	li	a5,13
    80002868:	00f70763          	beq	a4,a5,80002876 <usertrap+0x54>
    8000286c:	14202773          	csrr	a4,scause
    80002870:	47bd                	li	a5,15
    80002872:	12f71363          	bne	a4,a5,80002998 <usertrap+0x176>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002876:	14302973          	csrr	s2,stval
    if(va >= p->sz){
    8000287a:	64b0                	ld	a2,72(s1)
    8000287c:	0ac97e63          	bgeu	s2,a2,80002938 <usertrap+0x116>
    if(va < PGROUNDUP(p->trapframe->sp)) {  
    80002880:	6cbc                	ld	a5,88(s1)
    80002882:	7b90                	ld	a2,48(a5)
    80002884:	6785                	lui	a5,0x1
    80002886:	17fd                	addi	a5,a5,-1
    80002888:	97b2                	add	a5,a5,a2
    8000288a:	777d                	lui	a4,0xfffff
    8000288c:	8ff9                	and	a5,a5,a4
    8000288e:	0cf96163          	bltu	s2,a5,80002950 <usertrap+0x12e>
    if ((pa = kalloc()) == 0) {
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	28e080e7          	jalr	654(ra) # 80000b20 <kalloc>
    8000289a:	89aa                	mv	s3,a0
    8000289c:	c17d                	beqz	a0,80002982 <usertrap+0x160>
    memset(pa, 0, PGSIZE);
    8000289e:	6605                	lui	a2,0x1
    800028a0:	4581                	li	a1,0
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	46a080e7          	jalr	1130(ra) # 80000d0c <memset>
    if (mappages(p->pagetable, PGROUNDDOWN(va), PGSIZE, (uint64) pa, PTE_W | PTE_R | PTE_U) != 0) {
    800028aa:	4759                	li	a4,22
    800028ac:	86ce                	mv	a3,s3
    800028ae:	6605                	lui	a2,0x1
    800028b0:	75fd                	lui	a1,0xfffff
    800028b2:	00b975b3          	and	a1,s2,a1
    800028b6:	68a8                	ld	a0,80(s1)
    800028b8:	fffff097          	auipc	ra,0xfffff
    800028bc:	844080e7          	jalr	-1980(ra) # 800010fc <mappages>
    800028c0:	c929                	beqz	a0,80002912 <usertrap+0xf0>
        kfree(pa);
    800028c2:	854e                	mv	a0,s3
    800028c4:	ffffe097          	auipc	ra,0xffffe
    800028c8:	160080e7          	jalr	352(ra) # 80000a24 <kfree>
        printf("usertrap(): mappages() failed\n");
    800028cc:	00006517          	auipc	a0,0x6
    800028d0:	a6c50513          	addi	a0,a0,-1428 # 80008338 <states.1702+0xf8>
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	cbe080e7          	jalr	-834(ra) # 80000592 <printf>
        p->killed = 1;
    800028dc:	4785                	li	a5,1
    800028de:	d89c                	sw	a5,48(s1)
        goto end;
    800028e0:	a059                	j	80002966 <usertrap+0x144>
    panic("usertrap: not from user mode");
    800028e2:	00006517          	auipc	a0,0x6
    800028e6:	9ae50513          	addi	a0,a0,-1618 # 80008290 <states.1702+0x50>
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	c5e080e7          	jalr	-930(ra) # 80000548 <panic>
    if(p->killed)
    800028f2:	591c                	lw	a5,48(a0)
    800028f4:	ef85                	bnez	a5,8000292c <usertrap+0x10a>
    p->trapframe->epc += 4;
    800028f6:	6cb8                	ld	a4,88(s1)
    800028f8:	6f1c                	ld	a5,24(a4)
    800028fa:	0791                	addi	a5,a5,4
    800028fc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002902:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002906:	10079073          	csrw	sstatus,a5
    syscall();
    8000290a:	00000097          	auipc	ra,0x0
    8000290e:	31a080e7          	jalr	794(ra) # 80002c24 <syscall>
  if(p->killed)
    80002912:	589c                	lw	a5,48(s1)
    80002914:	e7e9                	bnez	a5,800029de <usertrap+0x1bc>
  usertrapret();
    80002916:	00000097          	auipc	ra,0x0
    8000291a:	d86080e7          	jalr	-634(ra) # 8000269c <usertrapret>
}
    8000291e:	70a2                	ld	ra,40(sp)
    80002920:	7402                	ld	s0,32(sp)
    80002922:	64e2                	ld	s1,24(sp)
    80002924:	6942                	ld	s2,16(sp)
    80002926:	69a2                	ld	s3,8(sp)
    80002928:	6145                	addi	sp,sp,48
    8000292a:	8082                	ret
      exit(-1);
    8000292c:	557d                	li	a0,-1
    8000292e:	fffff097          	auipc	ra,0xfffff
    80002932:	7c2080e7          	jalr	1986(ra) # 800020f0 <exit>
    80002936:	b7c1                	j	800028f6 <usertrap+0xd4>
      printf("usertrap(): invalid va=%p higher than p->sz=%p\n",
    80002938:	85ca                	mv	a1,s2
    8000293a:	00006517          	auipc	a0,0x6
    8000293e:	97650513          	addi	a0,a0,-1674 # 800082b0 <states.1702+0x70>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	c50080e7          	jalr	-944(ra) # 80000592 <printf>
      p->killed = 1;
    8000294a:	4785                	li	a5,1
    8000294c:	d89c                	sw	a5,48(s1)
      goto end;
    8000294e:	a821                	j	80002966 <usertrap+0x144>
      printf("usertrap(): invalid va=%p below the user stack sp=%p\n",
    80002950:	85ca                	mv	a1,s2
    80002952:	00006517          	auipc	a0,0x6
    80002956:	98e50513          	addi	a0,a0,-1650 # 800082e0 <states.1702+0xa0>
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	c38080e7          	jalr	-968(ra) # 80000592 <printf>
      p->killed = 1;
    80002962:	4785                	li	a5,1
    80002964:	d89c                	sw	a5,48(s1)
{
    80002966:	4901                	li	s2,0
    exit(-1);
    80002968:	557d                	li	a0,-1
    8000296a:	fffff097          	auipc	ra,0xfffff
    8000296e:	786080e7          	jalr	1926(ra) # 800020f0 <exit>
  if(which_dev == 2)
    80002972:	4789                	li	a5,2
    80002974:	faf911e3          	bne	s2,a5,80002916 <usertrap+0xf4>
    yield();
    80002978:	00000097          	auipc	ra,0x0
    8000297c:	882080e7          	jalr	-1918(ra) # 800021fa <yield>
    80002980:	bf59                	j	80002916 <usertrap+0xf4>
        printf("usertrap(): kalloc() failed\n");
    80002982:	00006517          	auipc	a0,0x6
    80002986:	99650513          	addi	a0,a0,-1642 # 80008318 <states.1702+0xd8>
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	c08080e7          	jalr	-1016(ra) # 80000592 <printf>
        p->killed = 1;
    80002992:	4785                	li	a5,1
    80002994:	d89c                	sw	a5,48(s1)
        goto end;
    80002996:	bfc1                	j	80002966 <usertrap+0x144>
  } else if((which_dev = devintr()) != 0){
    80002998:	00000097          	auipc	ra,0x0
    8000299c:	de8080e7          	jalr	-536(ra) # 80002780 <devintr>
    800029a0:	892a                	mv	s2,a0
    800029a2:	c501                	beqz	a0,800029aa <usertrap+0x188>
  if(p->killed)
    800029a4:	589c                	lw	a5,48(s1)
    800029a6:	d7f1                	beqz	a5,80002972 <usertrap+0x150>
    800029a8:	b7c1                	j	80002968 <usertrap+0x146>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029aa:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029ae:	5c90                	lw	a2,56(s1)
    800029b0:	00006517          	auipc	a0,0x6
    800029b4:	9a850513          	addi	a0,a0,-1624 # 80008358 <states.1702+0x118>
    800029b8:	ffffe097          	auipc	ra,0xffffe
    800029bc:	bda080e7          	jalr	-1062(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029c4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029c8:	00006517          	auipc	a0,0x6
    800029cc:	9c050513          	addi	a0,a0,-1600 # 80008388 <states.1702+0x148>
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	bc2080e7          	jalr	-1086(ra) # 80000592 <printf>
    p->killed = 1;
    800029d8:	4785                	li	a5,1
    800029da:	d89c                	sw	a5,48(s1)
    800029dc:	b769                	j	80002966 <usertrap+0x144>
  if(p->killed)
    800029de:	4901                	li	s2,0
    800029e0:	b761                	j	80002968 <usertrap+0x146>

00000000800029e2 <kerneltrap>:
{
    800029e2:	7179                	addi	sp,sp,-48
    800029e4:	f406                	sd	ra,40(sp)
    800029e6:	f022                	sd	s0,32(sp)
    800029e8:	ec26                	sd	s1,24(sp)
    800029ea:	e84a                	sd	s2,16(sp)
    800029ec:	e44e                	sd	s3,8(sp)
    800029ee:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029f8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029fc:	1004f793          	andi	a5,s1,256
    80002a00:	cb85                	beqz	a5,80002a30 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a02:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a06:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a08:	ef85                	bnez	a5,80002a40 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a0a:	00000097          	auipc	ra,0x0
    80002a0e:	d76080e7          	jalr	-650(ra) # 80002780 <devintr>
    80002a12:	cd1d                	beqz	a0,80002a50 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a14:	4789                	li	a5,2
    80002a16:	06f50a63          	beq	a0,a5,80002a8a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a1a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a1e:	10049073          	csrw	sstatus,s1
}
    80002a22:	70a2                	ld	ra,40(sp)
    80002a24:	7402                	ld	s0,32(sp)
    80002a26:	64e2                	ld	s1,24(sp)
    80002a28:	6942                	ld	s2,16(sp)
    80002a2a:	69a2                	ld	s3,8(sp)
    80002a2c:	6145                	addi	sp,sp,48
    80002a2e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a30:	00006517          	auipc	a0,0x6
    80002a34:	97850513          	addi	a0,a0,-1672 # 800083a8 <states.1702+0x168>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	b10080e7          	jalr	-1264(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a40:	00006517          	auipc	a0,0x6
    80002a44:	99050513          	addi	a0,a0,-1648 # 800083d0 <states.1702+0x190>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	b00080e7          	jalr	-1280(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002a50:	85ce                	mv	a1,s3
    80002a52:	00006517          	auipc	a0,0x6
    80002a56:	99e50513          	addi	a0,a0,-1634 # 800083f0 <states.1702+0x1b0>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	b38080e7          	jalr	-1224(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a62:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a66:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	99650513          	addi	a0,a0,-1642 # 80008400 <states.1702+0x1c0>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	b20080e7          	jalr	-1248(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	99e50513          	addi	a0,a0,-1634 # 80008418 <states.1702+0x1d8>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	ac6080e7          	jalr	-1338(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	f9c080e7          	jalr	-100(ra) # 80001a26 <myproc>
    80002a92:	d541                	beqz	a0,80002a1a <kerneltrap+0x38>
    80002a94:	fffff097          	auipc	ra,0xfffff
    80002a98:	f92080e7          	jalr	-110(ra) # 80001a26 <myproc>
    80002a9c:	4d18                	lw	a4,24(a0)
    80002a9e:	478d                	li	a5,3
    80002aa0:	f6f71de3          	bne	a4,a5,80002a1a <kerneltrap+0x38>
    yield();
    80002aa4:	fffff097          	auipc	ra,0xfffff
    80002aa8:	756080e7          	jalr	1878(ra) # 800021fa <yield>
    80002aac:	b7bd                	j	80002a1a <kerneltrap+0x38>

0000000080002aae <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002aae:	1101                	addi	sp,sp,-32
    80002ab0:	ec06                	sd	ra,24(sp)
    80002ab2:	e822                	sd	s0,16(sp)
    80002ab4:	e426                	sd	s1,8(sp)
    80002ab6:	1000                	addi	s0,sp,32
    80002ab8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	f6c080e7          	jalr	-148(ra) # 80001a26 <myproc>
  switch (n) {
    80002ac2:	4795                	li	a5,5
    80002ac4:	0497e163          	bltu	a5,s1,80002b06 <argraw+0x58>
    80002ac8:	048a                	slli	s1,s1,0x2
    80002aca:	00006717          	auipc	a4,0x6
    80002ace:	98670713          	addi	a4,a4,-1658 # 80008450 <states.1702+0x210>
    80002ad2:	94ba                	add	s1,s1,a4
    80002ad4:	409c                	lw	a5,0(s1)
    80002ad6:	97ba                	add	a5,a5,a4
    80002ad8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ada:	6d3c                	ld	a5,88(a0)
    80002adc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ade:	60e2                	ld	ra,24(sp)
    80002ae0:	6442                	ld	s0,16(sp)
    80002ae2:	64a2                	ld	s1,8(sp)
    80002ae4:	6105                	addi	sp,sp,32
    80002ae6:	8082                	ret
    return p->trapframe->a1;
    80002ae8:	6d3c                	ld	a5,88(a0)
    80002aea:	7fa8                	ld	a0,120(a5)
    80002aec:	bfcd                	j	80002ade <argraw+0x30>
    return p->trapframe->a2;
    80002aee:	6d3c                	ld	a5,88(a0)
    80002af0:	63c8                	ld	a0,128(a5)
    80002af2:	b7f5                	j	80002ade <argraw+0x30>
    return p->trapframe->a3;
    80002af4:	6d3c                	ld	a5,88(a0)
    80002af6:	67c8                	ld	a0,136(a5)
    80002af8:	b7dd                	j	80002ade <argraw+0x30>
    return p->trapframe->a4;
    80002afa:	6d3c                	ld	a5,88(a0)
    80002afc:	6bc8                	ld	a0,144(a5)
    80002afe:	b7c5                	j	80002ade <argraw+0x30>
    return p->trapframe->a5;
    80002b00:	6d3c                	ld	a5,88(a0)
    80002b02:	6fc8                	ld	a0,152(a5)
    80002b04:	bfe9                	j	80002ade <argraw+0x30>
  panic("argraw");
    80002b06:	00006517          	auipc	a0,0x6
    80002b0a:	92250513          	addi	a0,a0,-1758 # 80008428 <states.1702+0x1e8>
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	a3a080e7          	jalr	-1478(ra) # 80000548 <panic>

0000000080002b16 <fetchaddr>:
{
    80002b16:	1101                	addi	sp,sp,-32
    80002b18:	ec06                	sd	ra,24(sp)
    80002b1a:	e822                	sd	s0,16(sp)
    80002b1c:	e426                	sd	s1,8(sp)
    80002b1e:	e04a                	sd	s2,0(sp)
    80002b20:	1000                	addi	s0,sp,32
    80002b22:	84aa                	mv	s1,a0
    80002b24:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	f00080e7          	jalr	-256(ra) # 80001a26 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b2e:	653c                	ld	a5,72(a0)
    80002b30:	02f4f863          	bgeu	s1,a5,80002b60 <fetchaddr+0x4a>
    80002b34:	00848713          	addi	a4,s1,8
    80002b38:	02e7e663          	bltu	a5,a4,80002b64 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b3c:	46a1                	li	a3,8
    80002b3e:	8626                	mv	a2,s1
    80002b40:	85ca                	mv	a1,s2
    80002b42:	6928                	ld	a0,80(a0)
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	c62080e7          	jalr	-926(ra) # 800017a6 <copyin>
    80002b4c:	00a03533          	snez	a0,a0
    80002b50:	40a00533          	neg	a0,a0
}
    80002b54:	60e2                	ld	ra,24(sp)
    80002b56:	6442                	ld	s0,16(sp)
    80002b58:	64a2                	ld	s1,8(sp)
    80002b5a:	6902                	ld	s2,0(sp)
    80002b5c:	6105                	addi	sp,sp,32
    80002b5e:	8082                	ret
    return -1;
    80002b60:	557d                	li	a0,-1
    80002b62:	bfcd                	j	80002b54 <fetchaddr+0x3e>
    80002b64:	557d                	li	a0,-1
    80002b66:	b7fd                	j	80002b54 <fetchaddr+0x3e>

0000000080002b68 <fetchstr>:
{
    80002b68:	7179                	addi	sp,sp,-48
    80002b6a:	f406                	sd	ra,40(sp)
    80002b6c:	f022                	sd	s0,32(sp)
    80002b6e:	ec26                	sd	s1,24(sp)
    80002b70:	e84a                	sd	s2,16(sp)
    80002b72:	e44e                	sd	s3,8(sp)
    80002b74:	1800                	addi	s0,sp,48
    80002b76:	892a                	mv	s2,a0
    80002b78:	84ae                	mv	s1,a1
    80002b7a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b7c:	fffff097          	auipc	ra,0xfffff
    80002b80:	eaa080e7          	jalr	-342(ra) # 80001a26 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b84:	86ce                	mv	a3,s3
    80002b86:	864a                	mv	a2,s2
    80002b88:	85a6                	mv	a1,s1
    80002b8a:	6928                	ld	a0,80(a0)
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	ca6080e7          	jalr	-858(ra) # 80001832 <copyinstr>
  if(err < 0)
    80002b94:	00054763          	bltz	a0,80002ba2 <fetchstr+0x3a>
  return strlen(buf);
    80002b98:	8526                	mv	a0,s1
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	2fa080e7          	jalr	762(ra) # 80000e94 <strlen>
}
    80002ba2:	70a2                	ld	ra,40(sp)
    80002ba4:	7402                	ld	s0,32(sp)
    80002ba6:	64e2                	ld	s1,24(sp)
    80002ba8:	6942                	ld	s2,16(sp)
    80002baa:	69a2                	ld	s3,8(sp)
    80002bac:	6145                	addi	sp,sp,48
    80002bae:	8082                	ret

0000000080002bb0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bb0:	1101                	addi	sp,sp,-32
    80002bb2:	ec06                	sd	ra,24(sp)
    80002bb4:	e822                	sd	s0,16(sp)
    80002bb6:	e426                	sd	s1,8(sp)
    80002bb8:	1000                	addi	s0,sp,32
    80002bba:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bbc:	00000097          	auipc	ra,0x0
    80002bc0:	ef2080e7          	jalr	-270(ra) # 80002aae <argraw>
    80002bc4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bc6:	4501                	li	a0,0
    80002bc8:	60e2                	ld	ra,24(sp)
    80002bca:	6442                	ld	s0,16(sp)
    80002bcc:	64a2                	ld	s1,8(sp)
    80002bce:	6105                	addi	sp,sp,32
    80002bd0:	8082                	ret

0000000080002bd2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bd2:	1101                	addi	sp,sp,-32
    80002bd4:	ec06                	sd	ra,24(sp)
    80002bd6:	e822                	sd	s0,16(sp)
    80002bd8:	e426                	sd	s1,8(sp)
    80002bda:	1000                	addi	s0,sp,32
    80002bdc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bde:	00000097          	auipc	ra,0x0
    80002be2:	ed0080e7          	jalr	-304(ra) # 80002aae <argraw>
    80002be6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002be8:	4501                	li	a0,0
    80002bea:	60e2                	ld	ra,24(sp)
    80002bec:	6442                	ld	s0,16(sp)
    80002bee:	64a2                	ld	s1,8(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret

0000000080002bf4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bf4:	1101                	addi	sp,sp,-32
    80002bf6:	ec06                	sd	ra,24(sp)
    80002bf8:	e822                	sd	s0,16(sp)
    80002bfa:	e426                	sd	s1,8(sp)
    80002bfc:	e04a                	sd	s2,0(sp)
    80002bfe:	1000                	addi	s0,sp,32
    80002c00:	84ae                	mv	s1,a1
    80002c02:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	eaa080e7          	jalr	-342(ra) # 80002aae <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c0c:	864a                	mv	a2,s2
    80002c0e:	85a6                	mv	a1,s1
    80002c10:	00000097          	auipc	ra,0x0
    80002c14:	f58080e7          	jalr	-168(ra) # 80002b68 <fetchstr>
}
    80002c18:	60e2                	ld	ra,24(sp)
    80002c1a:	6442                	ld	s0,16(sp)
    80002c1c:	64a2                	ld	s1,8(sp)
    80002c1e:	6902                	ld	s2,0(sp)
    80002c20:	6105                	addi	sp,sp,32
    80002c22:	8082                	ret

0000000080002c24 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	e426                	sd	s1,8(sp)
    80002c2c:	e04a                	sd	s2,0(sp)
    80002c2e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	df6080e7          	jalr	-522(ra) # 80001a26 <myproc>
    80002c38:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c3a:	05853903          	ld	s2,88(a0)
    80002c3e:	0a893783          	ld	a5,168(s2)
    80002c42:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c46:	37fd                	addiw	a5,a5,-1
    80002c48:	4751                	li	a4,20
    80002c4a:	00f76f63          	bltu	a4,a5,80002c68 <syscall+0x44>
    80002c4e:	00369713          	slli	a4,a3,0x3
    80002c52:	00006797          	auipc	a5,0x6
    80002c56:	81678793          	addi	a5,a5,-2026 # 80008468 <syscalls>
    80002c5a:	97ba                	add	a5,a5,a4
    80002c5c:	639c                	ld	a5,0(a5)
    80002c5e:	c789                	beqz	a5,80002c68 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c60:	9782                	jalr	a5
    80002c62:	06a93823          	sd	a0,112(s2)
    80002c66:	a839                	j	80002c84 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c68:	15848613          	addi	a2,s1,344
    80002c6c:	5c8c                	lw	a1,56(s1)
    80002c6e:	00005517          	auipc	a0,0x5
    80002c72:	7c250513          	addi	a0,a0,1986 # 80008430 <states.1702+0x1f0>
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	91c080e7          	jalr	-1764(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c7e:	6cbc                	ld	a5,88(s1)
    80002c80:	577d                	li	a4,-1
    80002c82:	fbb8                	sd	a4,112(a5)
  }
}
    80002c84:	60e2                	ld	ra,24(sp)
    80002c86:	6442                	ld	s0,16(sp)
    80002c88:	64a2                	ld	s1,8(sp)
    80002c8a:	6902                	ld	s2,0(sp)
    80002c8c:	6105                	addi	sp,sp,32
    80002c8e:	8082                	ret

0000000080002c90 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c90:	1101                	addi	sp,sp,-32
    80002c92:	ec06                	sd	ra,24(sp)
    80002c94:	e822                	sd	s0,16(sp)
    80002c96:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c98:	fec40593          	addi	a1,s0,-20
    80002c9c:	4501                	li	a0,0
    80002c9e:	00000097          	auipc	ra,0x0
    80002ca2:	f12080e7          	jalr	-238(ra) # 80002bb0 <argint>
    return -1;
    80002ca6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ca8:	00054963          	bltz	a0,80002cba <sys_exit+0x2a>
  exit(n);
    80002cac:	fec42503          	lw	a0,-20(s0)
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	440080e7          	jalr	1088(ra) # 800020f0 <exit>
  return 0;  // not reached
    80002cb8:	4781                	li	a5,0
}
    80002cba:	853e                	mv	a0,a5
    80002cbc:	60e2                	ld	ra,24(sp)
    80002cbe:	6442                	ld	s0,16(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret

0000000080002cc4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cc4:	1141                	addi	sp,sp,-16
    80002cc6:	e406                	sd	ra,8(sp)
    80002cc8:	e022                	sd	s0,0(sp)
    80002cca:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	d5a080e7          	jalr	-678(ra) # 80001a26 <myproc>
}
    80002cd4:	5d08                	lw	a0,56(a0)
    80002cd6:	60a2                	ld	ra,8(sp)
    80002cd8:	6402                	ld	s0,0(sp)
    80002cda:	0141                	addi	sp,sp,16
    80002cdc:	8082                	ret

0000000080002cde <sys_fork>:

uint64
sys_fork(void)
{
    80002cde:	1141                	addi	sp,sp,-16
    80002ce0:	e406                	sd	ra,8(sp)
    80002ce2:	e022                	sd	s0,0(sp)
    80002ce4:	0800                	addi	s0,sp,16
  return fork();
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	100080e7          	jalr	256(ra) # 80001de6 <fork>
}
    80002cee:	60a2                	ld	ra,8(sp)
    80002cf0:	6402                	ld	s0,0(sp)
    80002cf2:	0141                	addi	sp,sp,16
    80002cf4:	8082                	ret

0000000080002cf6 <sys_wait>:

uint64
sys_wait(void)
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cfe:	fe840593          	addi	a1,s0,-24
    80002d02:	4501                	li	a0,0
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	ece080e7          	jalr	-306(ra) # 80002bd2 <argaddr>
    80002d0c:	87aa                	mv	a5,a0
    return -1;
    80002d0e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d10:	0007c863          	bltz	a5,80002d20 <sys_wait+0x2a>
  return wait(p);
    80002d14:	fe843503          	ld	a0,-24(s0)
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	59c080e7          	jalr	1436(ra) # 800022b4 <wait>
}
    80002d20:	60e2                	ld	ra,24(sp)
    80002d22:	6442                	ld	s0,16(sp)
    80002d24:	6105                	addi	sp,sp,32
    80002d26:	8082                	ret

0000000080002d28 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d28:	7179                	addi	sp,sp,-48
    80002d2a:	f406                	sd	ra,40(sp)
    80002d2c:	f022                	sd	s0,32(sp)
    80002d2e:	ec26                	sd	s1,24(sp)
    80002d30:	e84a                	sd	s2,16(sp)
    80002d32:	1800                	addi	s0,sp,48
  int addr;
  int n;
  struct proc *p;

  if(argint(0, &n) < 0)
    80002d34:	fdc40593          	addi	a1,s0,-36
    80002d38:	4501                	li	a0,0
    80002d3a:	00000097          	auipc	ra,0x0
    80002d3e:	e76080e7          	jalr	-394(ra) # 80002bb0 <argint>
    return -1;
    80002d42:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d44:	02054163          	bltz	a0,80002d66 <sys_sbrk+0x3e>
  p = myproc();
    80002d48:	fffff097          	auipc	ra,0xfffff
    80002d4c:	cde080e7          	jalr	-802(ra) # 80001a26 <myproc>
    80002d50:	84aa                	mv	s1,a0
  addr = p->sz;
    80002d52:	653c                	ld	a5,72(a0)
    80002d54:	0007891b          	sext.w	s2,a5
  // new code
  if(n >= 0 && addr + n >= addr){
    80002d58:	fdc42603          	lw	a2,-36(s0)
    80002d5c:	00064c63          	bltz	a2,80002d74 <sys_sbrk+0x4c>
    p->sz += n;    
    80002d60:	963e                	add	a2,a2,a5
    80002d62:	e530                	sd	a2,72(a0)
    return -1;
  }

//  if(growproc(n) < 0)
//    return -1;
  return addr;
    80002d64:	87ca                	mv	a5,s2
}
    80002d66:	853e                	mv	a0,a5
    80002d68:	70a2                	ld	ra,40(sp)
    80002d6a:	7402                	ld	s0,32(sp)
    80002d6c:	64e2                	ld	s1,24(sp)
    80002d6e:	6942                	ld	s2,16(sp)
    80002d70:	6145                	addi	sp,sp,48
    80002d72:	8082                	ret
  } else if(n < 0 && addr + n >= PGROUNDUP(p->trapframe->sp)){
    80002d74:	0126063b          	addw	a2,a2,s2
    80002d78:	6d3c                	ld	a5,88(a0)
    80002d7a:	7b98                	ld	a4,48(a5)
    80002d7c:	6785                	lui	a5,0x1
    80002d7e:	17fd                	addi	a5,a5,-1
    80002d80:	973e                	add	a4,a4,a5
    80002d82:	77fd                	lui	a5,0xfffff
    80002d84:	8f7d                	and	a4,a4,a5
    return -1;
    80002d86:	57fd                	li	a5,-1
  } else if(n < 0 && addr + n >= PGROUNDUP(p->trapframe->sp)){
    80002d88:	fce66fe3          	bltu	a2,a4,80002d66 <sys_sbrk+0x3e>
    p->sz = uvmdealloc(p->pagetable, addr, addr + n);
    80002d8c:	85ca                	mv	a1,s2
    80002d8e:	6928                	ld	a0,80(a0)
    80002d90:	ffffe097          	auipc	ra,0xffffe
    80002d94:	70e080e7          	jalr	1806(ra) # 8000149e <uvmdealloc>
    80002d98:	e4a8                	sd	a0,72(s1)
    80002d9a:	b7e9                	j	80002d64 <sys_sbrk+0x3c>

0000000080002d9c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d9c:	7139                	addi	sp,sp,-64
    80002d9e:	fc06                	sd	ra,56(sp)
    80002da0:	f822                	sd	s0,48(sp)
    80002da2:	f426                	sd	s1,40(sp)
    80002da4:	f04a                	sd	s2,32(sp)
    80002da6:	ec4e                	sd	s3,24(sp)
    80002da8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002daa:	fcc40593          	addi	a1,s0,-52
    80002dae:	4501                	li	a0,0
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	e00080e7          	jalr	-512(ra) # 80002bb0 <argint>
    return -1;
    80002db8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dba:	06054563          	bltz	a0,80002e24 <sys_sleep+0x88>
  acquire(&tickslock);
    80002dbe:	00015517          	auipc	a0,0x15
    80002dc2:	9aa50513          	addi	a0,a0,-1622 # 80017768 <tickslock>
    80002dc6:	ffffe097          	auipc	ra,0xffffe
    80002dca:	e4a080e7          	jalr	-438(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002dce:	00006917          	auipc	s2,0x6
    80002dd2:	25292903          	lw	s2,594(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002dd6:	fcc42783          	lw	a5,-52(s0)
    80002dda:	cf85                	beqz	a5,80002e12 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ddc:	00015997          	auipc	s3,0x15
    80002de0:	98c98993          	addi	s3,s3,-1652 # 80017768 <tickslock>
    80002de4:	00006497          	auipc	s1,0x6
    80002de8:	23c48493          	addi	s1,s1,572 # 80009020 <ticks>
    if(myproc()->killed){
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	c3a080e7          	jalr	-966(ra) # 80001a26 <myproc>
    80002df4:	591c                	lw	a5,48(a0)
    80002df6:	ef9d                	bnez	a5,80002e34 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002df8:	85ce                	mv	a1,s3
    80002dfa:	8526                	mv	a0,s1
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	43a080e7          	jalr	1082(ra) # 80002236 <sleep>
  while(ticks - ticks0 < n){
    80002e04:	409c                	lw	a5,0(s1)
    80002e06:	412787bb          	subw	a5,a5,s2
    80002e0a:	fcc42703          	lw	a4,-52(s0)
    80002e0e:	fce7efe3          	bltu	a5,a4,80002dec <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e12:	00015517          	auipc	a0,0x15
    80002e16:	95650513          	addi	a0,a0,-1706 # 80017768 <tickslock>
    80002e1a:	ffffe097          	auipc	ra,0xffffe
    80002e1e:	eaa080e7          	jalr	-342(ra) # 80000cc4 <release>
  return 0;
    80002e22:	4781                	li	a5,0
}
    80002e24:	853e                	mv	a0,a5
    80002e26:	70e2                	ld	ra,56(sp)
    80002e28:	7442                	ld	s0,48(sp)
    80002e2a:	74a2                	ld	s1,40(sp)
    80002e2c:	7902                	ld	s2,32(sp)
    80002e2e:	69e2                	ld	s3,24(sp)
    80002e30:	6121                	addi	sp,sp,64
    80002e32:	8082                	ret
      release(&tickslock);
    80002e34:	00015517          	auipc	a0,0x15
    80002e38:	93450513          	addi	a0,a0,-1740 # 80017768 <tickslock>
    80002e3c:	ffffe097          	auipc	ra,0xffffe
    80002e40:	e88080e7          	jalr	-376(ra) # 80000cc4 <release>
      return -1;
    80002e44:	57fd                	li	a5,-1
    80002e46:	bff9                	j	80002e24 <sys_sleep+0x88>

0000000080002e48 <sys_kill>:

uint64
sys_kill(void)
{
    80002e48:	1101                	addi	sp,sp,-32
    80002e4a:	ec06                	sd	ra,24(sp)
    80002e4c:	e822                	sd	s0,16(sp)
    80002e4e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e50:	fec40593          	addi	a1,s0,-20
    80002e54:	4501                	li	a0,0
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	d5a080e7          	jalr	-678(ra) # 80002bb0 <argint>
    80002e5e:	87aa                	mv	a5,a0
    return -1;
    80002e60:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e62:	0007c863          	bltz	a5,80002e72 <sys_kill+0x2a>
  return kill(pid);
    80002e66:	fec42503          	lw	a0,-20(s0)
    80002e6a:	fffff097          	auipc	ra,0xfffff
    80002e6e:	5bc080e7          	jalr	1468(ra) # 80002426 <kill>
}
    80002e72:	60e2                	ld	ra,24(sp)
    80002e74:	6442                	ld	s0,16(sp)
    80002e76:	6105                	addi	sp,sp,32
    80002e78:	8082                	ret

0000000080002e7a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e7a:	1101                	addi	sp,sp,-32
    80002e7c:	ec06                	sd	ra,24(sp)
    80002e7e:	e822                	sd	s0,16(sp)
    80002e80:	e426                	sd	s1,8(sp)
    80002e82:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e84:	00015517          	auipc	a0,0x15
    80002e88:	8e450513          	addi	a0,a0,-1820 # 80017768 <tickslock>
    80002e8c:	ffffe097          	auipc	ra,0xffffe
    80002e90:	d84080e7          	jalr	-636(ra) # 80000c10 <acquire>
  xticks = ticks;
    80002e94:	00006497          	auipc	s1,0x6
    80002e98:	18c4a483          	lw	s1,396(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e9c:	00015517          	auipc	a0,0x15
    80002ea0:	8cc50513          	addi	a0,a0,-1844 # 80017768 <tickslock>
    80002ea4:	ffffe097          	auipc	ra,0xffffe
    80002ea8:	e20080e7          	jalr	-480(ra) # 80000cc4 <release>
  return xticks;
}
    80002eac:	02049513          	slli	a0,s1,0x20
    80002eb0:	9101                	srli	a0,a0,0x20
    80002eb2:	60e2                	ld	ra,24(sp)
    80002eb4:	6442                	ld	s0,16(sp)
    80002eb6:	64a2                	ld	s1,8(sp)
    80002eb8:	6105                	addi	sp,sp,32
    80002eba:	8082                	ret

0000000080002ebc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ebc:	7179                	addi	sp,sp,-48
    80002ebe:	f406                	sd	ra,40(sp)
    80002ec0:	f022                	sd	s0,32(sp)
    80002ec2:	ec26                	sd	s1,24(sp)
    80002ec4:	e84a                	sd	s2,16(sp)
    80002ec6:	e44e                	sd	s3,8(sp)
    80002ec8:	e052                	sd	s4,0(sp)
    80002eca:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ecc:	00005597          	auipc	a1,0x5
    80002ed0:	64c58593          	addi	a1,a1,1612 # 80008518 <syscalls+0xb0>
    80002ed4:	00015517          	auipc	a0,0x15
    80002ed8:	8ac50513          	addi	a0,a0,-1876 # 80017780 <bcache>
    80002edc:	ffffe097          	auipc	ra,0xffffe
    80002ee0:	ca4080e7          	jalr	-860(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ee4:	0001d797          	auipc	a5,0x1d
    80002ee8:	89c78793          	addi	a5,a5,-1892 # 8001f780 <bcache+0x8000>
    80002eec:	0001d717          	auipc	a4,0x1d
    80002ef0:	afc70713          	addi	a4,a4,-1284 # 8001f9e8 <bcache+0x8268>
    80002ef4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ef8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002efc:	00015497          	auipc	s1,0x15
    80002f00:	89c48493          	addi	s1,s1,-1892 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002f04:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f06:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f08:	00005a17          	auipc	s4,0x5
    80002f0c:	618a0a13          	addi	s4,s4,1560 # 80008520 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002f10:	2b893783          	ld	a5,696(s2)
    80002f14:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f16:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f1a:	85d2                	mv	a1,s4
    80002f1c:	01048513          	addi	a0,s1,16
    80002f20:	00001097          	auipc	ra,0x1
    80002f24:	4b0080e7          	jalr	1200(ra) # 800043d0 <initsleeplock>
    bcache.head.next->prev = b;
    80002f28:	2b893783          	ld	a5,696(s2)
    80002f2c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f2e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f32:	45848493          	addi	s1,s1,1112
    80002f36:	fd349de3          	bne	s1,s3,80002f10 <binit+0x54>
  }
}
    80002f3a:	70a2                	ld	ra,40(sp)
    80002f3c:	7402                	ld	s0,32(sp)
    80002f3e:	64e2                	ld	s1,24(sp)
    80002f40:	6942                	ld	s2,16(sp)
    80002f42:	69a2                	ld	s3,8(sp)
    80002f44:	6a02                	ld	s4,0(sp)
    80002f46:	6145                	addi	sp,sp,48
    80002f48:	8082                	ret

0000000080002f4a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f4a:	7179                	addi	sp,sp,-48
    80002f4c:	f406                	sd	ra,40(sp)
    80002f4e:	f022                	sd	s0,32(sp)
    80002f50:	ec26                	sd	s1,24(sp)
    80002f52:	e84a                	sd	s2,16(sp)
    80002f54:	e44e                	sd	s3,8(sp)
    80002f56:	1800                	addi	s0,sp,48
    80002f58:	89aa                	mv	s3,a0
    80002f5a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f5c:	00015517          	auipc	a0,0x15
    80002f60:	82450513          	addi	a0,a0,-2012 # 80017780 <bcache>
    80002f64:	ffffe097          	auipc	ra,0xffffe
    80002f68:	cac080e7          	jalr	-852(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f6c:	0001d497          	auipc	s1,0x1d
    80002f70:	acc4b483          	ld	s1,-1332(s1) # 8001fa38 <bcache+0x82b8>
    80002f74:	0001d797          	auipc	a5,0x1d
    80002f78:	a7478793          	addi	a5,a5,-1420 # 8001f9e8 <bcache+0x8268>
    80002f7c:	02f48f63          	beq	s1,a5,80002fba <bread+0x70>
    80002f80:	873e                	mv	a4,a5
    80002f82:	a021                	j	80002f8a <bread+0x40>
    80002f84:	68a4                	ld	s1,80(s1)
    80002f86:	02e48a63          	beq	s1,a4,80002fba <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f8a:	449c                	lw	a5,8(s1)
    80002f8c:	ff379ce3          	bne	a5,s3,80002f84 <bread+0x3a>
    80002f90:	44dc                	lw	a5,12(s1)
    80002f92:	ff2799e3          	bne	a5,s2,80002f84 <bread+0x3a>
      b->refcnt++;
    80002f96:	40bc                	lw	a5,64(s1)
    80002f98:	2785                	addiw	a5,a5,1
    80002f9a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f9c:	00014517          	auipc	a0,0x14
    80002fa0:	7e450513          	addi	a0,a0,2020 # 80017780 <bcache>
    80002fa4:	ffffe097          	auipc	ra,0xffffe
    80002fa8:	d20080e7          	jalr	-736(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002fac:	01048513          	addi	a0,s1,16
    80002fb0:	00001097          	auipc	ra,0x1
    80002fb4:	45a080e7          	jalr	1114(ra) # 8000440a <acquiresleep>
      return b;
    80002fb8:	a8b9                	j	80003016 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fba:	0001d497          	auipc	s1,0x1d
    80002fbe:	a764b483          	ld	s1,-1418(s1) # 8001fa30 <bcache+0x82b0>
    80002fc2:	0001d797          	auipc	a5,0x1d
    80002fc6:	a2678793          	addi	a5,a5,-1498 # 8001f9e8 <bcache+0x8268>
    80002fca:	00f48863          	beq	s1,a5,80002fda <bread+0x90>
    80002fce:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fd0:	40bc                	lw	a5,64(s1)
    80002fd2:	cf81                	beqz	a5,80002fea <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fd4:	64a4                	ld	s1,72(s1)
    80002fd6:	fee49de3          	bne	s1,a4,80002fd0 <bread+0x86>
  panic("bget: no buffers");
    80002fda:	00005517          	auipc	a0,0x5
    80002fde:	54e50513          	addi	a0,a0,1358 # 80008528 <syscalls+0xc0>
    80002fe2:	ffffd097          	auipc	ra,0xffffd
    80002fe6:	566080e7          	jalr	1382(ra) # 80000548 <panic>
      b->dev = dev;
    80002fea:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fee:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002ff2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ff6:	4785                	li	a5,1
    80002ff8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ffa:	00014517          	auipc	a0,0x14
    80002ffe:	78650513          	addi	a0,a0,1926 # 80017780 <bcache>
    80003002:	ffffe097          	auipc	ra,0xffffe
    80003006:	cc2080e7          	jalr	-830(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    8000300a:	01048513          	addi	a0,s1,16
    8000300e:	00001097          	auipc	ra,0x1
    80003012:	3fc080e7          	jalr	1020(ra) # 8000440a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003016:	409c                	lw	a5,0(s1)
    80003018:	cb89                	beqz	a5,8000302a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000301a:	8526                	mv	a0,s1
    8000301c:	70a2                	ld	ra,40(sp)
    8000301e:	7402                	ld	s0,32(sp)
    80003020:	64e2                	ld	s1,24(sp)
    80003022:	6942                	ld	s2,16(sp)
    80003024:	69a2                	ld	s3,8(sp)
    80003026:	6145                	addi	sp,sp,48
    80003028:	8082                	ret
    virtio_disk_rw(b, 0);
    8000302a:	4581                	li	a1,0
    8000302c:	8526                	mv	a0,s1
    8000302e:	00003097          	auipc	ra,0x3
    80003032:	f3e080e7          	jalr	-194(ra) # 80005f6c <virtio_disk_rw>
    b->valid = 1;
    80003036:	4785                	li	a5,1
    80003038:	c09c                	sw	a5,0(s1)
  return b;
    8000303a:	b7c5                	j	8000301a <bread+0xd0>

000000008000303c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000303c:	1101                	addi	sp,sp,-32
    8000303e:	ec06                	sd	ra,24(sp)
    80003040:	e822                	sd	s0,16(sp)
    80003042:	e426                	sd	s1,8(sp)
    80003044:	1000                	addi	s0,sp,32
    80003046:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003048:	0541                	addi	a0,a0,16
    8000304a:	00001097          	auipc	ra,0x1
    8000304e:	45a080e7          	jalr	1114(ra) # 800044a4 <holdingsleep>
    80003052:	cd01                	beqz	a0,8000306a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003054:	4585                	li	a1,1
    80003056:	8526                	mv	a0,s1
    80003058:	00003097          	auipc	ra,0x3
    8000305c:	f14080e7          	jalr	-236(ra) # 80005f6c <virtio_disk_rw>
}
    80003060:	60e2                	ld	ra,24(sp)
    80003062:	6442                	ld	s0,16(sp)
    80003064:	64a2                	ld	s1,8(sp)
    80003066:	6105                	addi	sp,sp,32
    80003068:	8082                	ret
    panic("bwrite");
    8000306a:	00005517          	auipc	a0,0x5
    8000306e:	4d650513          	addi	a0,a0,1238 # 80008540 <syscalls+0xd8>
    80003072:	ffffd097          	auipc	ra,0xffffd
    80003076:	4d6080e7          	jalr	1238(ra) # 80000548 <panic>

000000008000307a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000307a:	1101                	addi	sp,sp,-32
    8000307c:	ec06                	sd	ra,24(sp)
    8000307e:	e822                	sd	s0,16(sp)
    80003080:	e426                	sd	s1,8(sp)
    80003082:	e04a                	sd	s2,0(sp)
    80003084:	1000                	addi	s0,sp,32
    80003086:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003088:	01050913          	addi	s2,a0,16
    8000308c:	854a                	mv	a0,s2
    8000308e:	00001097          	auipc	ra,0x1
    80003092:	416080e7          	jalr	1046(ra) # 800044a4 <holdingsleep>
    80003096:	c92d                	beqz	a0,80003108 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003098:	854a                	mv	a0,s2
    8000309a:	00001097          	auipc	ra,0x1
    8000309e:	3c6080e7          	jalr	966(ra) # 80004460 <releasesleep>

  acquire(&bcache.lock);
    800030a2:	00014517          	auipc	a0,0x14
    800030a6:	6de50513          	addi	a0,a0,1758 # 80017780 <bcache>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	b66080e7          	jalr	-1178(ra) # 80000c10 <acquire>
  b->refcnt--;
    800030b2:	40bc                	lw	a5,64(s1)
    800030b4:	37fd                	addiw	a5,a5,-1
    800030b6:	0007871b          	sext.w	a4,a5
    800030ba:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030bc:	eb05                	bnez	a4,800030ec <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030be:	68bc                	ld	a5,80(s1)
    800030c0:	64b8                	ld	a4,72(s1)
    800030c2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030c4:	64bc                	ld	a5,72(s1)
    800030c6:	68b8                	ld	a4,80(s1)
    800030c8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030ca:	0001c797          	auipc	a5,0x1c
    800030ce:	6b678793          	addi	a5,a5,1718 # 8001f780 <bcache+0x8000>
    800030d2:	2b87b703          	ld	a4,696(a5)
    800030d6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030d8:	0001d717          	auipc	a4,0x1d
    800030dc:	91070713          	addi	a4,a4,-1776 # 8001f9e8 <bcache+0x8268>
    800030e0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030e2:	2b87b703          	ld	a4,696(a5)
    800030e6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030e8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030ec:	00014517          	auipc	a0,0x14
    800030f0:	69450513          	addi	a0,a0,1684 # 80017780 <bcache>
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	bd0080e7          	jalr	-1072(ra) # 80000cc4 <release>
}
    800030fc:	60e2                	ld	ra,24(sp)
    800030fe:	6442                	ld	s0,16(sp)
    80003100:	64a2                	ld	s1,8(sp)
    80003102:	6902                	ld	s2,0(sp)
    80003104:	6105                	addi	sp,sp,32
    80003106:	8082                	ret
    panic("brelse");
    80003108:	00005517          	auipc	a0,0x5
    8000310c:	44050513          	addi	a0,a0,1088 # 80008548 <syscalls+0xe0>
    80003110:	ffffd097          	auipc	ra,0xffffd
    80003114:	438080e7          	jalr	1080(ra) # 80000548 <panic>

0000000080003118 <bpin>:

void
bpin(struct buf *b) {
    80003118:	1101                	addi	sp,sp,-32
    8000311a:	ec06                	sd	ra,24(sp)
    8000311c:	e822                	sd	s0,16(sp)
    8000311e:	e426                	sd	s1,8(sp)
    80003120:	1000                	addi	s0,sp,32
    80003122:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003124:	00014517          	auipc	a0,0x14
    80003128:	65c50513          	addi	a0,a0,1628 # 80017780 <bcache>
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	ae4080e7          	jalr	-1308(ra) # 80000c10 <acquire>
  b->refcnt++;
    80003134:	40bc                	lw	a5,64(s1)
    80003136:	2785                	addiw	a5,a5,1
    80003138:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000313a:	00014517          	auipc	a0,0x14
    8000313e:	64650513          	addi	a0,a0,1606 # 80017780 <bcache>
    80003142:	ffffe097          	auipc	ra,0xffffe
    80003146:	b82080e7          	jalr	-1150(ra) # 80000cc4 <release>
}
    8000314a:	60e2                	ld	ra,24(sp)
    8000314c:	6442                	ld	s0,16(sp)
    8000314e:	64a2                	ld	s1,8(sp)
    80003150:	6105                	addi	sp,sp,32
    80003152:	8082                	ret

0000000080003154 <bunpin>:

void
bunpin(struct buf *b) {
    80003154:	1101                	addi	sp,sp,-32
    80003156:	ec06                	sd	ra,24(sp)
    80003158:	e822                	sd	s0,16(sp)
    8000315a:	e426                	sd	s1,8(sp)
    8000315c:	1000                	addi	s0,sp,32
    8000315e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003160:	00014517          	auipc	a0,0x14
    80003164:	62050513          	addi	a0,a0,1568 # 80017780 <bcache>
    80003168:	ffffe097          	auipc	ra,0xffffe
    8000316c:	aa8080e7          	jalr	-1368(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003170:	40bc                	lw	a5,64(s1)
    80003172:	37fd                	addiw	a5,a5,-1
    80003174:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003176:	00014517          	auipc	a0,0x14
    8000317a:	60a50513          	addi	a0,a0,1546 # 80017780 <bcache>
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	b46080e7          	jalr	-1210(ra) # 80000cc4 <release>
}
    80003186:	60e2                	ld	ra,24(sp)
    80003188:	6442                	ld	s0,16(sp)
    8000318a:	64a2                	ld	s1,8(sp)
    8000318c:	6105                	addi	sp,sp,32
    8000318e:	8082                	ret

0000000080003190 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003190:	1101                	addi	sp,sp,-32
    80003192:	ec06                	sd	ra,24(sp)
    80003194:	e822                	sd	s0,16(sp)
    80003196:	e426                	sd	s1,8(sp)
    80003198:	e04a                	sd	s2,0(sp)
    8000319a:	1000                	addi	s0,sp,32
    8000319c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000319e:	00d5d59b          	srliw	a1,a1,0xd
    800031a2:	0001d797          	auipc	a5,0x1d
    800031a6:	cba7a783          	lw	a5,-838(a5) # 8001fe5c <sb+0x1c>
    800031aa:	9dbd                	addw	a1,a1,a5
    800031ac:	00000097          	auipc	ra,0x0
    800031b0:	d9e080e7          	jalr	-610(ra) # 80002f4a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031b4:	0074f713          	andi	a4,s1,7
    800031b8:	4785                	li	a5,1
    800031ba:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031be:	14ce                	slli	s1,s1,0x33
    800031c0:	90d9                	srli	s1,s1,0x36
    800031c2:	00950733          	add	a4,a0,s1
    800031c6:	05874703          	lbu	a4,88(a4)
    800031ca:	00e7f6b3          	and	a3,a5,a4
    800031ce:	c69d                	beqz	a3,800031fc <bfree+0x6c>
    800031d0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031d2:	94aa                	add	s1,s1,a0
    800031d4:	fff7c793          	not	a5,a5
    800031d8:	8ff9                	and	a5,a5,a4
    800031da:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031de:	00001097          	auipc	ra,0x1
    800031e2:	104080e7          	jalr	260(ra) # 800042e2 <log_write>
  brelse(bp);
    800031e6:	854a                	mv	a0,s2
    800031e8:	00000097          	auipc	ra,0x0
    800031ec:	e92080e7          	jalr	-366(ra) # 8000307a <brelse>
}
    800031f0:	60e2                	ld	ra,24(sp)
    800031f2:	6442                	ld	s0,16(sp)
    800031f4:	64a2                	ld	s1,8(sp)
    800031f6:	6902                	ld	s2,0(sp)
    800031f8:	6105                	addi	sp,sp,32
    800031fa:	8082                	ret
    panic("freeing free block");
    800031fc:	00005517          	auipc	a0,0x5
    80003200:	35450513          	addi	a0,a0,852 # 80008550 <syscalls+0xe8>
    80003204:	ffffd097          	auipc	ra,0xffffd
    80003208:	344080e7          	jalr	836(ra) # 80000548 <panic>

000000008000320c <balloc>:
{
    8000320c:	711d                	addi	sp,sp,-96
    8000320e:	ec86                	sd	ra,88(sp)
    80003210:	e8a2                	sd	s0,80(sp)
    80003212:	e4a6                	sd	s1,72(sp)
    80003214:	e0ca                	sd	s2,64(sp)
    80003216:	fc4e                	sd	s3,56(sp)
    80003218:	f852                	sd	s4,48(sp)
    8000321a:	f456                	sd	s5,40(sp)
    8000321c:	f05a                	sd	s6,32(sp)
    8000321e:	ec5e                	sd	s7,24(sp)
    80003220:	e862                	sd	s8,16(sp)
    80003222:	e466                	sd	s9,8(sp)
    80003224:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003226:	0001d797          	auipc	a5,0x1d
    8000322a:	c1e7a783          	lw	a5,-994(a5) # 8001fe44 <sb+0x4>
    8000322e:	cbd1                	beqz	a5,800032c2 <balloc+0xb6>
    80003230:	8baa                	mv	s7,a0
    80003232:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003234:	0001db17          	auipc	s6,0x1d
    80003238:	c0cb0b13          	addi	s6,s6,-1012 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000323c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000323e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003240:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003242:	6c89                	lui	s9,0x2
    80003244:	a831                	j	80003260 <balloc+0x54>
    brelse(bp);
    80003246:	854a                	mv	a0,s2
    80003248:	00000097          	auipc	ra,0x0
    8000324c:	e32080e7          	jalr	-462(ra) # 8000307a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003250:	015c87bb          	addw	a5,s9,s5
    80003254:	00078a9b          	sext.w	s5,a5
    80003258:	004b2703          	lw	a4,4(s6)
    8000325c:	06eaf363          	bgeu	s5,a4,800032c2 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003260:	41fad79b          	sraiw	a5,s5,0x1f
    80003264:	0137d79b          	srliw	a5,a5,0x13
    80003268:	015787bb          	addw	a5,a5,s5
    8000326c:	40d7d79b          	sraiw	a5,a5,0xd
    80003270:	01cb2583          	lw	a1,28(s6)
    80003274:	9dbd                	addw	a1,a1,a5
    80003276:	855e                	mv	a0,s7
    80003278:	00000097          	auipc	ra,0x0
    8000327c:	cd2080e7          	jalr	-814(ra) # 80002f4a <bread>
    80003280:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003282:	004b2503          	lw	a0,4(s6)
    80003286:	000a849b          	sext.w	s1,s5
    8000328a:	8662                	mv	a2,s8
    8000328c:	faa4fde3          	bgeu	s1,a0,80003246 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003290:	41f6579b          	sraiw	a5,a2,0x1f
    80003294:	01d7d69b          	srliw	a3,a5,0x1d
    80003298:	00c6873b          	addw	a4,a3,a2
    8000329c:	00777793          	andi	a5,a4,7
    800032a0:	9f95                	subw	a5,a5,a3
    800032a2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032a6:	4037571b          	sraiw	a4,a4,0x3
    800032aa:	00e906b3          	add	a3,s2,a4
    800032ae:	0586c683          	lbu	a3,88(a3)
    800032b2:	00d7f5b3          	and	a1,a5,a3
    800032b6:	cd91                	beqz	a1,800032d2 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032b8:	2605                	addiw	a2,a2,1
    800032ba:	2485                	addiw	s1,s1,1
    800032bc:	fd4618e3          	bne	a2,s4,8000328c <balloc+0x80>
    800032c0:	b759                	j	80003246 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032c2:	00005517          	auipc	a0,0x5
    800032c6:	2a650513          	addi	a0,a0,678 # 80008568 <syscalls+0x100>
    800032ca:	ffffd097          	auipc	ra,0xffffd
    800032ce:	27e080e7          	jalr	638(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032d2:	974a                	add	a4,a4,s2
    800032d4:	8fd5                	or	a5,a5,a3
    800032d6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032da:	854a                	mv	a0,s2
    800032dc:	00001097          	auipc	ra,0x1
    800032e0:	006080e7          	jalr	6(ra) # 800042e2 <log_write>
        brelse(bp);
    800032e4:	854a                	mv	a0,s2
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	d94080e7          	jalr	-620(ra) # 8000307a <brelse>
  bp = bread(dev, bno);
    800032ee:	85a6                	mv	a1,s1
    800032f0:	855e                	mv	a0,s7
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	c58080e7          	jalr	-936(ra) # 80002f4a <bread>
    800032fa:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032fc:	40000613          	li	a2,1024
    80003300:	4581                	li	a1,0
    80003302:	05850513          	addi	a0,a0,88
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	a06080e7          	jalr	-1530(ra) # 80000d0c <memset>
  log_write(bp);
    8000330e:	854a                	mv	a0,s2
    80003310:	00001097          	auipc	ra,0x1
    80003314:	fd2080e7          	jalr	-46(ra) # 800042e2 <log_write>
  brelse(bp);
    80003318:	854a                	mv	a0,s2
    8000331a:	00000097          	auipc	ra,0x0
    8000331e:	d60080e7          	jalr	-672(ra) # 8000307a <brelse>
}
    80003322:	8526                	mv	a0,s1
    80003324:	60e6                	ld	ra,88(sp)
    80003326:	6446                	ld	s0,80(sp)
    80003328:	64a6                	ld	s1,72(sp)
    8000332a:	6906                	ld	s2,64(sp)
    8000332c:	79e2                	ld	s3,56(sp)
    8000332e:	7a42                	ld	s4,48(sp)
    80003330:	7aa2                	ld	s5,40(sp)
    80003332:	7b02                	ld	s6,32(sp)
    80003334:	6be2                	ld	s7,24(sp)
    80003336:	6c42                	ld	s8,16(sp)
    80003338:	6ca2                	ld	s9,8(sp)
    8000333a:	6125                	addi	sp,sp,96
    8000333c:	8082                	ret

000000008000333e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000333e:	7179                	addi	sp,sp,-48
    80003340:	f406                	sd	ra,40(sp)
    80003342:	f022                	sd	s0,32(sp)
    80003344:	ec26                	sd	s1,24(sp)
    80003346:	e84a                	sd	s2,16(sp)
    80003348:	e44e                	sd	s3,8(sp)
    8000334a:	e052                	sd	s4,0(sp)
    8000334c:	1800                	addi	s0,sp,48
    8000334e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003350:	47ad                	li	a5,11
    80003352:	04b7fe63          	bgeu	a5,a1,800033ae <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003356:	ff45849b          	addiw	s1,a1,-12
    8000335a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000335e:	0ff00793          	li	a5,255
    80003362:	0ae7e363          	bltu	a5,a4,80003408 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003366:	08052583          	lw	a1,128(a0)
    8000336a:	c5ad                	beqz	a1,800033d4 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000336c:	00092503          	lw	a0,0(s2)
    80003370:	00000097          	auipc	ra,0x0
    80003374:	bda080e7          	jalr	-1062(ra) # 80002f4a <bread>
    80003378:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000337a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000337e:	02049593          	slli	a1,s1,0x20
    80003382:	9181                	srli	a1,a1,0x20
    80003384:	058a                	slli	a1,a1,0x2
    80003386:	00b784b3          	add	s1,a5,a1
    8000338a:	0004a983          	lw	s3,0(s1)
    8000338e:	04098d63          	beqz	s3,800033e8 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003392:	8552                	mv	a0,s4
    80003394:	00000097          	auipc	ra,0x0
    80003398:	ce6080e7          	jalr	-794(ra) # 8000307a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000339c:	854e                	mv	a0,s3
    8000339e:	70a2                	ld	ra,40(sp)
    800033a0:	7402                	ld	s0,32(sp)
    800033a2:	64e2                	ld	s1,24(sp)
    800033a4:	6942                	ld	s2,16(sp)
    800033a6:	69a2                	ld	s3,8(sp)
    800033a8:	6a02                	ld	s4,0(sp)
    800033aa:	6145                	addi	sp,sp,48
    800033ac:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033ae:	02059493          	slli	s1,a1,0x20
    800033b2:	9081                	srli	s1,s1,0x20
    800033b4:	048a                	slli	s1,s1,0x2
    800033b6:	94aa                	add	s1,s1,a0
    800033b8:	0504a983          	lw	s3,80(s1)
    800033bc:	fe0990e3          	bnez	s3,8000339c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033c0:	4108                	lw	a0,0(a0)
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	e4a080e7          	jalr	-438(ra) # 8000320c <balloc>
    800033ca:	0005099b          	sext.w	s3,a0
    800033ce:	0534a823          	sw	s3,80(s1)
    800033d2:	b7e9                	j	8000339c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033d4:	4108                	lw	a0,0(a0)
    800033d6:	00000097          	auipc	ra,0x0
    800033da:	e36080e7          	jalr	-458(ra) # 8000320c <balloc>
    800033de:	0005059b          	sext.w	a1,a0
    800033e2:	08b92023          	sw	a1,128(s2)
    800033e6:	b759                	j	8000336c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033e8:	00092503          	lw	a0,0(s2)
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	e20080e7          	jalr	-480(ra) # 8000320c <balloc>
    800033f4:	0005099b          	sext.w	s3,a0
    800033f8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033fc:	8552                	mv	a0,s4
    800033fe:	00001097          	auipc	ra,0x1
    80003402:	ee4080e7          	jalr	-284(ra) # 800042e2 <log_write>
    80003406:	b771                	j	80003392 <bmap+0x54>
  panic("bmap: out of range");
    80003408:	00005517          	auipc	a0,0x5
    8000340c:	17850513          	addi	a0,a0,376 # 80008580 <syscalls+0x118>
    80003410:	ffffd097          	auipc	ra,0xffffd
    80003414:	138080e7          	jalr	312(ra) # 80000548 <panic>

0000000080003418 <iget>:
{
    80003418:	7179                	addi	sp,sp,-48
    8000341a:	f406                	sd	ra,40(sp)
    8000341c:	f022                	sd	s0,32(sp)
    8000341e:	ec26                	sd	s1,24(sp)
    80003420:	e84a                	sd	s2,16(sp)
    80003422:	e44e                	sd	s3,8(sp)
    80003424:	e052                	sd	s4,0(sp)
    80003426:	1800                	addi	s0,sp,48
    80003428:	89aa                	mv	s3,a0
    8000342a:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000342c:	0001d517          	auipc	a0,0x1d
    80003430:	a3450513          	addi	a0,a0,-1484 # 8001fe60 <icache>
    80003434:	ffffd097          	auipc	ra,0xffffd
    80003438:	7dc080e7          	jalr	2012(ra) # 80000c10 <acquire>
  empty = 0;
    8000343c:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000343e:	0001d497          	auipc	s1,0x1d
    80003442:	a3a48493          	addi	s1,s1,-1478 # 8001fe78 <icache+0x18>
    80003446:	0001e697          	auipc	a3,0x1e
    8000344a:	4c268693          	addi	a3,a3,1218 # 80021908 <log>
    8000344e:	a039                	j	8000345c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003450:	02090b63          	beqz	s2,80003486 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003454:	08848493          	addi	s1,s1,136
    80003458:	02d48a63          	beq	s1,a3,8000348c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000345c:	449c                	lw	a5,8(s1)
    8000345e:	fef059e3          	blez	a5,80003450 <iget+0x38>
    80003462:	4098                	lw	a4,0(s1)
    80003464:	ff3716e3          	bne	a4,s3,80003450 <iget+0x38>
    80003468:	40d8                	lw	a4,4(s1)
    8000346a:	ff4713e3          	bne	a4,s4,80003450 <iget+0x38>
      ip->ref++;
    8000346e:	2785                	addiw	a5,a5,1
    80003470:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003472:	0001d517          	auipc	a0,0x1d
    80003476:	9ee50513          	addi	a0,a0,-1554 # 8001fe60 <icache>
    8000347a:	ffffe097          	auipc	ra,0xffffe
    8000347e:	84a080e7          	jalr	-1974(ra) # 80000cc4 <release>
      return ip;
    80003482:	8926                	mv	s2,s1
    80003484:	a03d                	j	800034b2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003486:	f7f9                	bnez	a5,80003454 <iget+0x3c>
    80003488:	8926                	mv	s2,s1
    8000348a:	b7e9                	j	80003454 <iget+0x3c>
  if(empty == 0)
    8000348c:	02090c63          	beqz	s2,800034c4 <iget+0xac>
  ip->dev = dev;
    80003490:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003494:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003498:	4785                	li	a5,1
    8000349a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000349e:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034a2:	0001d517          	auipc	a0,0x1d
    800034a6:	9be50513          	addi	a0,a0,-1602 # 8001fe60 <icache>
    800034aa:	ffffe097          	auipc	ra,0xffffe
    800034ae:	81a080e7          	jalr	-2022(ra) # 80000cc4 <release>
}
    800034b2:	854a                	mv	a0,s2
    800034b4:	70a2                	ld	ra,40(sp)
    800034b6:	7402                	ld	s0,32(sp)
    800034b8:	64e2                	ld	s1,24(sp)
    800034ba:	6942                	ld	s2,16(sp)
    800034bc:	69a2                	ld	s3,8(sp)
    800034be:	6a02                	ld	s4,0(sp)
    800034c0:	6145                	addi	sp,sp,48
    800034c2:	8082                	ret
    panic("iget: no inodes");
    800034c4:	00005517          	auipc	a0,0x5
    800034c8:	0d450513          	addi	a0,a0,212 # 80008598 <syscalls+0x130>
    800034cc:	ffffd097          	auipc	ra,0xffffd
    800034d0:	07c080e7          	jalr	124(ra) # 80000548 <panic>

00000000800034d4 <fsinit>:
fsinit(int dev) {
    800034d4:	7179                	addi	sp,sp,-48
    800034d6:	f406                	sd	ra,40(sp)
    800034d8:	f022                	sd	s0,32(sp)
    800034da:	ec26                	sd	s1,24(sp)
    800034dc:	e84a                	sd	s2,16(sp)
    800034de:	e44e                	sd	s3,8(sp)
    800034e0:	1800                	addi	s0,sp,48
    800034e2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034e4:	4585                	li	a1,1
    800034e6:	00000097          	auipc	ra,0x0
    800034ea:	a64080e7          	jalr	-1436(ra) # 80002f4a <bread>
    800034ee:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034f0:	0001d997          	auipc	s3,0x1d
    800034f4:	95098993          	addi	s3,s3,-1712 # 8001fe40 <sb>
    800034f8:	02000613          	li	a2,32
    800034fc:	05850593          	addi	a1,a0,88
    80003500:	854e                	mv	a0,s3
    80003502:	ffffe097          	auipc	ra,0xffffe
    80003506:	86a080e7          	jalr	-1942(ra) # 80000d6c <memmove>
  brelse(bp);
    8000350a:	8526                	mv	a0,s1
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	b6e080e7          	jalr	-1170(ra) # 8000307a <brelse>
  if(sb.magic != FSMAGIC)
    80003514:	0009a703          	lw	a4,0(s3)
    80003518:	102037b7          	lui	a5,0x10203
    8000351c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003520:	02f71263          	bne	a4,a5,80003544 <fsinit+0x70>
  initlog(dev, &sb);
    80003524:	0001d597          	auipc	a1,0x1d
    80003528:	91c58593          	addi	a1,a1,-1764 # 8001fe40 <sb>
    8000352c:	854a                	mv	a0,s2
    8000352e:	00001097          	auipc	ra,0x1
    80003532:	b3c080e7          	jalr	-1220(ra) # 8000406a <initlog>
}
    80003536:	70a2                	ld	ra,40(sp)
    80003538:	7402                	ld	s0,32(sp)
    8000353a:	64e2                	ld	s1,24(sp)
    8000353c:	6942                	ld	s2,16(sp)
    8000353e:	69a2                	ld	s3,8(sp)
    80003540:	6145                	addi	sp,sp,48
    80003542:	8082                	ret
    panic("invalid file system");
    80003544:	00005517          	auipc	a0,0x5
    80003548:	06450513          	addi	a0,a0,100 # 800085a8 <syscalls+0x140>
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	ffc080e7          	jalr	-4(ra) # 80000548 <panic>

0000000080003554 <iinit>:
{
    80003554:	7179                	addi	sp,sp,-48
    80003556:	f406                	sd	ra,40(sp)
    80003558:	f022                	sd	s0,32(sp)
    8000355a:	ec26                	sd	s1,24(sp)
    8000355c:	e84a                	sd	s2,16(sp)
    8000355e:	e44e                	sd	s3,8(sp)
    80003560:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003562:	00005597          	auipc	a1,0x5
    80003566:	05e58593          	addi	a1,a1,94 # 800085c0 <syscalls+0x158>
    8000356a:	0001d517          	auipc	a0,0x1d
    8000356e:	8f650513          	addi	a0,a0,-1802 # 8001fe60 <icache>
    80003572:	ffffd097          	auipc	ra,0xffffd
    80003576:	60e080e7          	jalr	1550(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000357a:	0001d497          	auipc	s1,0x1d
    8000357e:	90e48493          	addi	s1,s1,-1778 # 8001fe88 <icache+0x28>
    80003582:	0001e997          	auipc	s3,0x1e
    80003586:	39698993          	addi	s3,s3,918 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000358a:	00005917          	auipc	s2,0x5
    8000358e:	03e90913          	addi	s2,s2,62 # 800085c8 <syscalls+0x160>
    80003592:	85ca                	mv	a1,s2
    80003594:	8526                	mv	a0,s1
    80003596:	00001097          	auipc	ra,0x1
    8000359a:	e3a080e7          	jalr	-454(ra) # 800043d0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000359e:	08848493          	addi	s1,s1,136
    800035a2:	ff3498e3          	bne	s1,s3,80003592 <iinit+0x3e>
}
    800035a6:	70a2                	ld	ra,40(sp)
    800035a8:	7402                	ld	s0,32(sp)
    800035aa:	64e2                	ld	s1,24(sp)
    800035ac:	6942                	ld	s2,16(sp)
    800035ae:	69a2                	ld	s3,8(sp)
    800035b0:	6145                	addi	sp,sp,48
    800035b2:	8082                	ret

00000000800035b4 <ialloc>:
{
    800035b4:	715d                	addi	sp,sp,-80
    800035b6:	e486                	sd	ra,72(sp)
    800035b8:	e0a2                	sd	s0,64(sp)
    800035ba:	fc26                	sd	s1,56(sp)
    800035bc:	f84a                	sd	s2,48(sp)
    800035be:	f44e                	sd	s3,40(sp)
    800035c0:	f052                	sd	s4,32(sp)
    800035c2:	ec56                	sd	s5,24(sp)
    800035c4:	e85a                	sd	s6,16(sp)
    800035c6:	e45e                	sd	s7,8(sp)
    800035c8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035ca:	0001d717          	auipc	a4,0x1d
    800035ce:	88272703          	lw	a4,-1918(a4) # 8001fe4c <sb+0xc>
    800035d2:	4785                	li	a5,1
    800035d4:	04e7fa63          	bgeu	a5,a4,80003628 <ialloc+0x74>
    800035d8:	8aaa                	mv	s5,a0
    800035da:	8bae                	mv	s7,a1
    800035dc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035de:	0001da17          	auipc	s4,0x1d
    800035e2:	862a0a13          	addi	s4,s4,-1950 # 8001fe40 <sb>
    800035e6:	00048b1b          	sext.w	s6,s1
    800035ea:	0044d593          	srli	a1,s1,0x4
    800035ee:	018a2783          	lw	a5,24(s4)
    800035f2:	9dbd                	addw	a1,a1,a5
    800035f4:	8556                	mv	a0,s5
    800035f6:	00000097          	auipc	ra,0x0
    800035fa:	954080e7          	jalr	-1708(ra) # 80002f4a <bread>
    800035fe:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003600:	05850993          	addi	s3,a0,88
    80003604:	00f4f793          	andi	a5,s1,15
    80003608:	079a                	slli	a5,a5,0x6
    8000360a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000360c:	00099783          	lh	a5,0(s3)
    80003610:	c785                	beqz	a5,80003638 <ialloc+0x84>
    brelse(bp);
    80003612:	00000097          	auipc	ra,0x0
    80003616:	a68080e7          	jalr	-1432(ra) # 8000307a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000361a:	0485                	addi	s1,s1,1
    8000361c:	00ca2703          	lw	a4,12(s4)
    80003620:	0004879b          	sext.w	a5,s1
    80003624:	fce7e1e3          	bltu	a5,a4,800035e6 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003628:	00005517          	auipc	a0,0x5
    8000362c:	fa850513          	addi	a0,a0,-88 # 800085d0 <syscalls+0x168>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	f18080e7          	jalr	-232(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003638:	04000613          	li	a2,64
    8000363c:	4581                	li	a1,0
    8000363e:	854e                	mv	a0,s3
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	6cc080e7          	jalr	1740(ra) # 80000d0c <memset>
      dip->type = type;
    80003648:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000364c:	854a                	mv	a0,s2
    8000364e:	00001097          	auipc	ra,0x1
    80003652:	c94080e7          	jalr	-876(ra) # 800042e2 <log_write>
      brelse(bp);
    80003656:	854a                	mv	a0,s2
    80003658:	00000097          	auipc	ra,0x0
    8000365c:	a22080e7          	jalr	-1502(ra) # 8000307a <brelse>
      return iget(dev, inum);
    80003660:	85da                	mv	a1,s6
    80003662:	8556                	mv	a0,s5
    80003664:	00000097          	auipc	ra,0x0
    80003668:	db4080e7          	jalr	-588(ra) # 80003418 <iget>
}
    8000366c:	60a6                	ld	ra,72(sp)
    8000366e:	6406                	ld	s0,64(sp)
    80003670:	74e2                	ld	s1,56(sp)
    80003672:	7942                	ld	s2,48(sp)
    80003674:	79a2                	ld	s3,40(sp)
    80003676:	7a02                	ld	s4,32(sp)
    80003678:	6ae2                	ld	s5,24(sp)
    8000367a:	6b42                	ld	s6,16(sp)
    8000367c:	6ba2                	ld	s7,8(sp)
    8000367e:	6161                	addi	sp,sp,80
    80003680:	8082                	ret

0000000080003682 <iupdate>:
{
    80003682:	1101                	addi	sp,sp,-32
    80003684:	ec06                	sd	ra,24(sp)
    80003686:	e822                	sd	s0,16(sp)
    80003688:	e426                	sd	s1,8(sp)
    8000368a:	e04a                	sd	s2,0(sp)
    8000368c:	1000                	addi	s0,sp,32
    8000368e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003690:	415c                	lw	a5,4(a0)
    80003692:	0047d79b          	srliw	a5,a5,0x4
    80003696:	0001c597          	auipc	a1,0x1c
    8000369a:	7c25a583          	lw	a1,1986(a1) # 8001fe58 <sb+0x18>
    8000369e:	9dbd                	addw	a1,a1,a5
    800036a0:	4108                	lw	a0,0(a0)
    800036a2:	00000097          	auipc	ra,0x0
    800036a6:	8a8080e7          	jalr	-1880(ra) # 80002f4a <bread>
    800036aa:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036ac:	05850793          	addi	a5,a0,88
    800036b0:	40c8                	lw	a0,4(s1)
    800036b2:	893d                	andi	a0,a0,15
    800036b4:	051a                	slli	a0,a0,0x6
    800036b6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036b8:	04449703          	lh	a4,68(s1)
    800036bc:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036c0:	04649703          	lh	a4,70(s1)
    800036c4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036c8:	04849703          	lh	a4,72(s1)
    800036cc:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036d0:	04a49703          	lh	a4,74(s1)
    800036d4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036d8:	44f8                	lw	a4,76(s1)
    800036da:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036dc:	03400613          	li	a2,52
    800036e0:	05048593          	addi	a1,s1,80
    800036e4:	0531                	addi	a0,a0,12
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	686080e7          	jalr	1670(ra) # 80000d6c <memmove>
  log_write(bp);
    800036ee:	854a                	mv	a0,s2
    800036f0:	00001097          	auipc	ra,0x1
    800036f4:	bf2080e7          	jalr	-1038(ra) # 800042e2 <log_write>
  brelse(bp);
    800036f8:	854a                	mv	a0,s2
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	980080e7          	jalr	-1664(ra) # 8000307a <brelse>
}
    80003702:	60e2                	ld	ra,24(sp)
    80003704:	6442                	ld	s0,16(sp)
    80003706:	64a2                	ld	s1,8(sp)
    80003708:	6902                	ld	s2,0(sp)
    8000370a:	6105                	addi	sp,sp,32
    8000370c:	8082                	ret

000000008000370e <idup>:
{
    8000370e:	1101                	addi	sp,sp,-32
    80003710:	ec06                	sd	ra,24(sp)
    80003712:	e822                	sd	s0,16(sp)
    80003714:	e426                	sd	s1,8(sp)
    80003716:	1000                	addi	s0,sp,32
    80003718:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000371a:	0001c517          	auipc	a0,0x1c
    8000371e:	74650513          	addi	a0,a0,1862 # 8001fe60 <icache>
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	4ee080e7          	jalr	1262(ra) # 80000c10 <acquire>
  ip->ref++;
    8000372a:	449c                	lw	a5,8(s1)
    8000372c:	2785                	addiw	a5,a5,1
    8000372e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003730:	0001c517          	auipc	a0,0x1c
    80003734:	73050513          	addi	a0,a0,1840 # 8001fe60 <icache>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	58c080e7          	jalr	1420(ra) # 80000cc4 <release>
}
    80003740:	8526                	mv	a0,s1
    80003742:	60e2                	ld	ra,24(sp)
    80003744:	6442                	ld	s0,16(sp)
    80003746:	64a2                	ld	s1,8(sp)
    80003748:	6105                	addi	sp,sp,32
    8000374a:	8082                	ret

000000008000374c <ilock>:
{
    8000374c:	1101                	addi	sp,sp,-32
    8000374e:	ec06                	sd	ra,24(sp)
    80003750:	e822                	sd	s0,16(sp)
    80003752:	e426                	sd	s1,8(sp)
    80003754:	e04a                	sd	s2,0(sp)
    80003756:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003758:	c115                	beqz	a0,8000377c <ilock+0x30>
    8000375a:	84aa                	mv	s1,a0
    8000375c:	451c                	lw	a5,8(a0)
    8000375e:	00f05f63          	blez	a5,8000377c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003762:	0541                	addi	a0,a0,16
    80003764:	00001097          	auipc	ra,0x1
    80003768:	ca6080e7          	jalr	-858(ra) # 8000440a <acquiresleep>
  if(ip->valid == 0){
    8000376c:	40bc                	lw	a5,64(s1)
    8000376e:	cf99                	beqz	a5,8000378c <ilock+0x40>
}
    80003770:	60e2                	ld	ra,24(sp)
    80003772:	6442                	ld	s0,16(sp)
    80003774:	64a2                	ld	s1,8(sp)
    80003776:	6902                	ld	s2,0(sp)
    80003778:	6105                	addi	sp,sp,32
    8000377a:	8082                	ret
    panic("ilock");
    8000377c:	00005517          	auipc	a0,0x5
    80003780:	e6c50513          	addi	a0,a0,-404 # 800085e8 <syscalls+0x180>
    80003784:	ffffd097          	auipc	ra,0xffffd
    80003788:	dc4080e7          	jalr	-572(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000378c:	40dc                	lw	a5,4(s1)
    8000378e:	0047d79b          	srliw	a5,a5,0x4
    80003792:	0001c597          	auipc	a1,0x1c
    80003796:	6c65a583          	lw	a1,1734(a1) # 8001fe58 <sb+0x18>
    8000379a:	9dbd                	addw	a1,a1,a5
    8000379c:	4088                	lw	a0,0(s1)
    8000379e:	fffff097          	auipc	ra,0xfffff
    800037a2:	7ac080e7          	jalr	1964(ra) # 80002f4a <bread>
    800037a6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037a8:	05850593          	addi	a1,a0,88
    800037ac:	40dc                	lw	a5,4(s1)
    800037ae:	8bbd                	andi	a5,a5,15
    800037b0:	079a                	slli	a5,a5,0x6
    800037b2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037b4:	00059783          	lh	a5,0(a1)
    800037b8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037bc:	00259783          	lh	a5,2(a1)
    800037c0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037c4:	00459783          	lh	a5,4(a1)
    800037c8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037cc:	00659783          	lh	a5,6(a1)
    800037d0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037d4:	459c                	lw	a5,8(a1)
    800037d6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037d8:	03400613          	li	a2,52
    800037dc:	05b1                	addi	a1,a1,12
    800037de:	05048513          	addi	a0,s1,80
    800037e2:	ffffd097          	auipc	ra,0xffffd
    800037e6:	58a080e7          	jalr	1418(ra) # 80000d6c <memmove>
    brelse(bp);
    800037ea:	854a                	mv	a0,s2
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	88e080e7          	jalr	-1906(ra) # 8000307a <brelse>
    ip->valid = 1;
    800037f4:	4785                	li	a5,1
    800037f6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037f8:	04449783          	lh	a5,68(s1)
    800037fc:	fbb5                	bnez	a5,80003770 <ilock+0x24>
      panic("ilock: no type");
    800037fe:	00005517          	auipc	a0,0x5
    80003802:	df250513          	addi	a0,a0,-526 # 800085f0 <syscalls+0x188>
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	d42080e7          	jalr	-702(ra) # 80000548 <panic>

000000008000380e <iunlock>:
{
    8000380e:	1101                	addi	sp,sp,-32
    80003810:	ec06                	sd	ra,24(sp)
    80003812:	e822                	sd	s0,16(sp)
    80003814:	e426                	sd	s1,8(sp)
    80003816:	e04a                	sd	s2,0(sp)
    80003818:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000381a:	c905                	beqz	a0,8000384a <iunlock+0x3c>
    8000381c:	84aa                	mv	s1,a0
    8000381e:	01050913          	addi	s2,a0,16
    80003822:	854a                	mv	a0,s2
    80003824:	00001097          	auipc	ra,0x1
    80003828:	c80080e7          	jalr	-896(ra) # 800044a4 <holdingsleep>
    8000382c:	cd19                	beqz	a0,8000384a <iunlock+0x3c>
    8000382e:	449c                	lw	a5,8(s1)
    80003830:	00f05d63          	blez	a5,8000384a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003834:	854a                	mv	a0,s2
    80003836:	00001097          	auipc	ra,0x1
    8000383a:	c2a080e7          	jalr	-982(ra) # 80004460 <releasesleep>
}
    8000383e:	60e2                	ld	ra,24(sp)
    80003840:	6442                	ld	s0,16(sp)
    80003842:	64a2                	ld	s1,8(sp)
    80003844:	6902                	ld	s2,0(sp)
    80003846:	6105                	addi	sp,sp,32
    80003848:	8082                	ret
    panic("iunlock");
    8000384a:	00005517          	auipc	a0,0x5
    8000384e:	db650513          	addi	a0,a0,-586 # 80008600 <syscalls+0x198>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	cf6080e7          	jalr	-778(ra) # 80000548 <panic>

000000008000385a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000385a:	7179                	addi	sp,sp,-48
    8000385c:	f406                	sd	ra,40(sp)
    8000385e:	f022                	sd	s0,32(sp)
    80003860:	ec26                	sd	s1,24(sp)
    80003862:	e84a                	sd	s2,16(sp)
    80003864:	e44e                	sd	s3,8(sp)
    80003866:	e052                	sd	s4,0(sp)
    80003868:	1800                	addi	s0,sp,48
    8000386a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000386c:	05050493          	addi	s1,a0,80
    80003870:	08050913          	addi	s2,a0,128
    80003874:	a021                	j	8000387c <itrunc+0x22>
    80003876:	0491                	addi	s1,s1,4
    80003878:	01248d63          	beq	s1,s2,80003892 <itrunc+0x38>
    if(ip->addrs[i]){
    8000387c:	408c                	lw	a1,0(s1)
    8000387e:	dde5                	beqz	a1,80003876 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003880:	0009a503          	lw	a0,0(s3)
    80003884:	00000097          	auipc	ra,0x0
    80003888:	90c080e7          	jalr	-1780(ra) # 80003190 <bfree>
      ip->addrs[i] = 0;
    8000388c:	0004a023          	sw	zero,0(s1)
    80003890:	b7dd                	j	80003876 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003892:	0809a583          	lw	a1,128(s3)
    80003896:	e185                	bnez	a1,800038b6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003898:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000389c:	854e                	mv	a0,s3
    8000389e:	00000097          	auipc	ra,0x0
    800038a2:	de4080e7          	jalr	-540(ra) # 80003682 <iupdate>
}
    800038a6:	70a2                	ld	ra,40(sp)
    800038a8:	7402                	ld	s0,32(sp)
    800038aa:	64e2                	ld	s1,24(sp)
    800038ac:	6942                	ld	s2,16(sp)
    800038ae:	69a2                	ld	s3,8(sp)
    800038b0:	6a02                	ld	s4,0(sp)
    800038b2:	6145                	addi	sp,sp,48
    800038b4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038b6:	0009a503          	lw	a0,0(s3)
    800038ba:	fffff097          	auipc	ra,0xfffff
    800038be:	690080e7          	jalr	1680(ra) # 80002f4a <bread>
    800038c2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038c4:	05850493          	addi	s1,a0,88
    800038c8:	45850913          	addi	s2,a0,1112
    800038cc:	a811                	j	800038e0 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038ce:	0009a503          	lw	a0,0(s3)
    800038d2:	00000097          	auipc	ra,0x0
    800038d6:	8be080e7          	jalr	-1858(ra) # 80003190 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038da:	0491                	addi	s1,s1,4
    800038dc:	01248563          	beq	s1,s2,800038e6 <itrunc+0x8c>
      if(a[j])
    800038e0:	408c                	lw	a1,0(s1)
    800038e2:	dde5                	beqz	a1,800038da <itrunc+0x80>
    800038e4:	b7ed                	j	800038ce <itrunc+0x74>
    brelse(bp);
    800038e6:	8552                	mv	a0,s4
    800038e8:	fffff097          	auipc	ra,0xfffff
    800038ec:	792080e7          	jalr	1938(ra) # 8000307a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038f0:	0809a583          	lw	a1,128(s3)
    800038f4:	0009a503          	lw	a0,0(s3)
    800038f8:	00000097          	auipc	ra,0x0
    800038fc:	898080e7          	jalr	-1896(ra) # 80003190 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003900:	0809a023          	sw	zero,128(s3)
    80003904:	bf51                	j	80003898 <itrunc+0x3e>

0000000080003906 <iput>:
{
    80003906:	1101                	addi	sp,sp,-32
    80003908:	ec06                	sd	ra,24(sp)
    8000390a:	e822                	sd	s0,16(sp)
    8000390c:	e426                	sd	s1,8(sp)
    8000390e:	e04a                	sd	s2,0(sp)
    80003910:	1000                	addi	s0,sp,32
    80003912:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003914:	0001c517          	auipc	a0,0x1c
    80003918:	54c50513          	addi	a0,a0,1356 # 8001fe60 <icache>
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	2f4080e7          	jalr	756(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003924:	4498                	lw	a4,8(s1)
    80003926:	4785                	li	a5,1
    80003928:	02f70363          	beq	a4,a5,8000394e <iput+0x48>
  ip->ref--;
    8000392c:	449c                	lw	a5,8(s1)
    8000392e:	37fd                	addiw	a5,a5,-1
    80003930:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003932:	0001c517          	auipc	a0,0x1c
    80003936:	52e50513          	addi	a0,a0,1326 # 8001fe60 <icache>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	38a080e7          	jalr	906(ra) # 80000cc4 <release>
}
    80003942:	60e2                	ld	ra,24(sp)
    80003944:	6442                	ld	s0,16(sp)
    80003946:	64a2                	ld	s1,8(sp)
    80003948:	6902                	ld	s2,0(sp)
    8000394a:	6105                	addi	sp,sp,32
    8000394c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000394e:	40bc                	lw	a5,64(s1)
    80003950:	dff1                	beqz	a5,8000392c <iput+0x26>
    80003952:	04a49783          	lh	a5,74(s1)
    80003956:	fbf9                	bnez	a5,8000392c <iput+0x26>
    acquiresleep(&ip->lock);
    80003958:	01048913          	addi	s2,s1,16
    8000395c:	854a                	mv	a0,s2
    8000395e:	00001097          	auipc	ra,0x1
    80003962:	aac080e7          	jalr	-1364(ra) # 8000440a <acquiresleep>
    release(&icache.lock);
    80003966:	0001c517          	auipc	a0,0x1c
    8000396a:	4fa50513          	addi	a0,a0,1274 # 8001fe60 <icache>
    8000396e:	ffffd097          	auipc	ra,0xffffd
    80003972:	356080e7          	jalr	854(ra) # 80000cc4 <release>
    itrunc(ip);
    80003976:	8526                	mv	a0,s1
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	ee2080e7          	jalr	-286(ra) # 8000385a <itrunc>
    ip->type = 0;
    80003980:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003984:	8526                	mv	a0,s1
    80003986:	00000097          	auipc	ra,0x0
    8000398a:	cfc080e7          	jalr	-772(ra) # 80003682 <iupdate>
    ip->valid = 0;
    8000398e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003992:	854a                	mv	a0,s2
    80003994:	00001097          	auipc	ra,0x1
    80003998:	acc080e7          	jalr	-1332(ra) # 80004460 <releasesleep>
    acquire(&icache.lock);
    8000399c:	0001c517          	auipc	a0,0x1c
    800039a0:	4c450513          	addi	a0,a0,1220 # 8001fe60 <icache>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	26c080e7          	jalr	620(ra) # 80000c10 <acquire>
    800039ac:	b741                	j	8000392c <iput+0x26>

00000000800039ae <iunlockput>:
{
    800039ae:	1101                	addi	sp,sp,-32
    800039b0:	ec06                	sd	ra,24(sp)
    800039b2:	e822                	sd	s0,16(sp)
    800039b4:	e426                	sd	s1,8(sp)
    800039b6:	1000                	addi	s0,sp,32
    800039b8:	84aa                	mv	s1,a0
  iunlock(ip);
    800039ba:	00000097          	auipc	ra,0x0
    800039be:	e54080e7          	jalr	-428(ra) # 8000380e <iunlock>
  iput(ip);
    800039c2:	8526                	mv	a0,s1
    800039c4:	00000097          	auipc	ra,0x0
    800039c8:	f42080e7          	jalr	-190(ra) # 80003906 <iput>
}
    800039cc:	60e2                	ld	ra,24(sp)
    800039ce:	6442                	ld	s0,16(sp)
    800039d0:	64a2                	ld	s1,8(sp)
    800039d2:	6105                	addi	sp,sp,32
    800039d4:	8082                	ret

00000000800039d6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039d6:	1141                	addi	sp,sp,-16
    800039d8:	e422                	sd	s0,8(sp)
    800039da:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039dc:	411c                	lw	a5,0(a0)
    800039de:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039e0:	415c                	lw	a5,4(a0)
    800039e2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039e4:	04451783          	lh	a5,68(a0)
    800039e8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039ec:	04a51783          	lh	a5,74(a0)
    800039f0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039f4:	04c56783          	lwu	a5,76(a0)
    800039f8:	e99c                	sd	a5,16(a1)
}
    800039fa:	6422                	ld	s0,8(sp)
    800039fc:	0141                	addi	sp,sp,16
    800039fe:	8082                	ret

0000000080003a00 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a00:	457c                	lw	a5,76(a0)
    80003a02:	0ed7e963          	bltu	a5,a3,80003af4 <readi+0xf4>
{
    80003a06:	7159                	addi	sp,sp,-112
    80003a08:	f486                	sd	ra,104(sp)
    80003a0a:	f0a2                	sd	s0,96(sp)
    80003a0c:	eca6                	sd	s1,88(sp)
    80003a0e:	e8ca                	sd	s2,80(sp)
    80003a10:	e4ce                	sd	s3,72(sp)
    80003a12:	e0d2                	sd	s4,64(sp)
    80003a14:	fc56                	sd	s5,56(sp)
    80003a16:	f85a                	sd	s6,48(sp)
    80003a18:	f45e                	sd	s7,40(sp)
    80003a1a:	f062                	sd	s8,32(sp)
    80003a1c:	ec66                	sd	s9,24(sp)
    80003a1e:	e86a                	sd	s10,16(sp)
    80003a20:	e46e                	sd	s11,8(sp)
    80003a22:	1880                	addi	s0,sp,112
    80003a24:	8baa                	mv	s7,a0
    80003a26:	8c2e                	mv	s8,a1
    80003a28:	8ab2                	mv	s5,a2
    80003a2a:	84b6                	mv	s1,a3
    80003a2c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a2e:	9f35                	addw	a4,a4,a3
    return 0;
    80003a30:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a32:	0ad76063          	bltu	a4,a3,80003ad2 <readi+0xd2>
  if(off + n > ip->size)
    80003a36:	00e7f463          	bgeu	a5,a4,80003a3e <readi+0x3e>
    n = ip->size - off;
    80003a3a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a3e:	0a0b0963          	beqz	s6,80003af0 <readi+0xf0>
    80003a42:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a44:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a48:	5cfd                	li	s9,-1
    80003a4a:	a82d                	j	80003a84 <readi+0x84>
    80003a4c:	020a1d93          	slli	s11,s4,0x20
    80003a50:	020ddd93          	srli	s11,s11,0x20
    80003a54:	05890613          	addi	a2,s2,88
    80003a58:	86ee                	mv	a3,s11
    80003a5a:	963a                	add	a2,a2,a4
    80003a5c:	85d6                	mv	a1,s5
    80003a5e:	8562                	mv	a0,s8
    80003a60:	fffff097          	auipc	ra,0xfffff
    80003a64:	a38080e7          	jalr	-1480(ra) # 80002498 <either_copyout>
    80003a68:	05950d63          	beq	a0,s9,80003ac2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a6c:	854a                	mv	a0,s2
    80003a6e:	fffff097          	auipc	ra,0xfffff
    80003a72:	60c080e7          	jalr	1548(ra) # 8000307a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a76:	013a09bb          	addw	s3,s4,s3
    80003a7a:	009a04bb          	addw	s1,s4,s1
    80003a7e:	9aee                	add	s5,s5,s11
    80003a80:	0569f763          	bgeu	s3,s6,80003ace <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a84:	000ba903          	lw	s2,0(s7)
    80003a88:	00a4d59b          	srliw	a1,s1,0xa
    80003a8c:	855e                	mv	a0,s7
    80003a8e:	00000097          	auipc	ra,0x0
    80003a92:	8b0080e7          	jalr	-1872(ra) # 8000333e <bmap>
    80003a96:	0005059b          	sext.w	a1,a0
    80003a9a:	854a                	mv	a0,s2
    80003a9c:	fffff097          	auipc	ra,0xfffff
    80003aa0:	4ae080e7          	jalr	1198(ra) # 80002f4a <bread>
    80003aa4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa6:	3ff4f713          	andi	a4,s1,1023
    80003aaa:	40ed07bb          	subw	a5,s10,a4
    80003aae:	413b06bb          	subw	a3,s6,s3
    80003ab2:	8a3e                	mv	s4,a5
    80003ab4:	2781                	sext.w	a5,a5
    80003ab6:	0006861b          	sext.w	a2,a3
    80003aba:	f8f679e3          	bgeu	a2,a5,80003a4c <readi+0x4c>
    80003abe:	8a36                	mv	s4,a3
    80003ac0:	b771                	j	80003a4c <readi+0x4c>
      brelse(bp);
    80003ac2:	854a                	mv	a0,s2
    80003ac4:	fffff097          	auipc	ra,0xfffff
    80003ac8:	5b6080e7          	jalr	1462(ra) # 8000307a <brelse>
      tot = -1;
    80003acc:	59fd                	li	s3,-1
  }
  return tot;
    80003ace:	0009851b          	sext.w	a0,s3
}
    80003ad2:	70a6                	ld	ra,104(sp)
    80003ad4:	7406                	ld	s0,96(sp)
    80003ad6:	64e6                	ld	s1,88(sp)
    80003ad8:	6946                	ld	s2,80(sp)
    80003ada:	69a6                	ld	s3,72(sp)
    80003adc:	6a06                	ld	s4,64(sp)
    80003ade:	7ae2                	ld	s5,56(sp)
    80003ae0:	7b42                	ld	s6,48(sp)
    80003ae2:	7ba2                	ld	s7,40(sp)
    80003ae4:	7c02                	ld	s8,32(sp)
    80003ae6:	6ce2                	ld	s9,24(sp)
    80003ae8:	6d42                	ld	s10,16(sp)
    80003aea:	6da2                	ld	s11,8(sp)
    80003aec:	6165                	addi	sp,sp,112
    80003aee:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003af0:	89da                	mv	s3,s6
    80003af2:	bff1                	j	80003ace <readi+0xce>
    return 0;
    80003af4:	4501                	li	a0,0
}
    80003af6:	8082                	ret

0000000080003af8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003af8:	457c                	lw	a5,76(a0)
    80003afa:	10d7e763          	bltu	a5,a3,80003c08 <writei+0x110>
{
    80003afe:	7159                	addi	sp,sp,-112
    80003b00:	f486                	sd	ra,104(sp)
    80003b02:	f0a2                	sd	s0,96(sp)
    80003b04:	eca6                	sd	s1,88(sp)
    80003b06:	e8ca                	sd	s2,80(sp)
    80003b08:	e4ce                	sd	s3,72(sp)
    80003b0a:	e0d2                	sd	s4,64(sp)
    80003b0c:	fc56                	sd	s5,56(sp)
    80003b0e:	f85a                	sd	s6,48(sp)
    80003b10:	f45e                	sd	s7,40(sp)
    80003b12:	f062                	sd	s8,32(sp)
    80003b14:	ec66                	sd	s9,24(sp)
    80003b16:	e86a                	sd	s10,16(sp)
    80003b18:	e46e                	sd	s11,8(sp)
    80003b1a:	1880                	addi	s0,sp,112
    80003b1c:	8baa                	mv	s7,a0
    80003b1e:	8c2e                	mv	s8,a1
    80003b20:	8ab2                	mv	s5,a2
    80003b22:	8936                	mv	s2,a3
    80003b24:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b26:	00e687bb          	addw	a5,a3,a4
    80003b2a:	0ed7e163          	bltu	a5,a3,80003c0c <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b2e:	00043737          	lui	a4,0x43
    80003b32:	0cf76f63          	bltu	a4,a5,80003c10 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b36:	0a0b0863          	beqz	s6,80003be6 <writei+0xee>
    80003b3a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b3c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b40:	5cfd                	li	s9,-1
    80003b42:	a091                	j	80003b86 <writei+0x8e>
    80003b44:	02099d93          	slli	s11,s3,0x20
    80003b48:	020ddd93          	srli	s11,s11,0x20
    80003b4c:	05848513          	addi	a0,s1,88
    80003b50:	86ee                	mv	a3,s11
    80003b52:	8656                	mv	a2,s5
    80003b54:	85e2                	mv	a1,s8
    80003b56:	953a                	add	a0,a0,a4
    80003b58:	fffff097          	auipc	ra,0xfffff
    80003b5c:	996080e7          	jalr	-1642(ra) # 800024ee <either_copyin>
    80003b60:	07950263          	beq	a0,s9,80003bc4 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003b64:	8526                	mv	a0,s1
    80003b66:	00000097          	auipc	ra,0x0
    80003b6a:	77c080e7          	jalr	1916(ra) # 800042e2 <log_write>
    brelse(bp);
    80003b6e:	8526                	mv	a0,s1
    80003b70:	fffff097          	auipc	ra,0xfffff
    80003b74:	50a080e7          	jalr	1290(ra) # 8000307a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b78:	01498a3b          	addw	s4,s3,s4
    80003b7c:	0129893b          	addw	s2,s3,s2
    80003b80:	9aee                	add	s5,s5,s11
    80003b82:	056a7763          	bgeu	s4,s6,80003bd0 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b86:	000ba483          	lw	s1,0(s7)
    80003b8a:	00a9559b          	srliw	a1,s2,0xa
    80003b8e:	855e                	mv	a0,s7
    80003b90:	fffff097          	auipc	ra,0xfffff
    80003b94:	7ae080e7          	jalr	1966(ra) # 8000333e <bmap>
    80003b98:	0005059b          	sext.w	a1,a0
    80003b9c:	8526                	mv	a0,s1
    80003b9e:	fffff097          	auipc	ra,0xfffff
    80003ba2:	3ac080e7          	jalr	940(ra) # 80002f4a <bread>
    80003ba6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba8:	3ff97713          	andi	a4,s2,1023
    80003bac:	40ed07bb          	subw	a5,s10,a4
    80003bb0:	414b06bb          	subw	a3,s6,s4
    80003bb4:	89be                	mv	s3,a5
    80003bb6:	2781                	sext.w	a5,a5
    80003bb8:	0006861b          	sext.w	a2,a3
    80003bbc:	f8f674e3          	bgeu	a2,a5,80003b44 <writei+0x4c>
    80003bc0:	89b6                	mv	s3,a3
    80003bc2:	b749                	j	80003b44 <writei+0x4c>
      brelse(bp);
    80003bc4:	8526                	mv	a0,s1
    80003bc6:	fffff097          	auipc	ra,0xfffff
    80003bca:	4b4080e7          	jalr	1204(ra) # 8000307a <brelse>
      n = -1;
    80003bce:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003bd0:	04cba783          	lw	a5,76(s7)
    80003bd4:	0127f463          	bgeu	a5,s2,80003bdc <writei+0xe4>
      ip->size = off;
    80003bd8:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003bdc:	855e                	mv	a0,s7
    80003bde:	00000097          	auipc	ra,0x0
    80003be2:	aa4080e7          	jalr	-1372(ra) # 80003682 <iupdate>
  }

  return n;
    80003be6:	000b051b          	sext.w	a0,s6
}
    80003bea:	70a6                	ld	ra,104(sp)
    80003bec:	7406                	ld	s0,96(sp)
    80003bee:	64e6                	ld	s1,88(sp)
    80003bf0:	6946                	ld	s2,80(sp)
    80003bf2:	69a6                	ld	s3,72(sp)
    80003bf4:	6a06                	ld	s4,64(sp)
    80003bf6:	7ae2                	ld	s5,56(sp)
    80003bf8:	7b42                	ld	s6,48(sp)
    80003bfa:	7ba2                	ld	s7,40(sp)
    80003bfc:	7c02                	ld	s8,32(sp)
    80003bfe:	6ce2                	ld	s9,24(sp)
    80003c00:	6d42                	ld	s10,16(sp)
    80003c02:	6da2                	ld	s11,8(sp)
    80003c04:	6165                	addi	sp,sp,112
    80003c06:	8082                	ret
    return -1;
    80003c08:	557d                	li	a0,-1
}
    80003c0a:	8082                	ret
    return -1;
    80003c0c:	557d                	li	a0,-1
    80003c0e:	bff1                	j	80003bea <writei+0xf2>
    return -1;
    80003c10:	557d                	li	a0,-1
    80003c12:	bfe1                	j	80003bea <writei+0xf2>

0000000080003c14 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c14:	1141                	addi	sp,sp,-16
    80003c16:	e406                	sd	ra,8(sp)
    80003c18:	e022                	sd	s0,0(sp)
    80003c1a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c1c:	4639                	li	a2,14
    80003c1e:	ffffd097          	auipc	ra,0xffffd
    80003c22:	1ca080e7          	jalr	458(ra) # 80000de8 <strncmp>
}
    80003c26:	60a2                	ld	ra,8(sp)
    80003c28:	6402                	ld	s0,0(sp)
    80003c2a:	0141                	addi	sp,sp,16
    80003c2c:	8082                	ret

0000000080003c2e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c2e:	7139                	addi	sp,sp,-64
    80003c30:	fc06                	sd	ra,56(sp)
    80003c32:	f822                	sd	s0,48(sp)
    80003c34:	f426                	sd	s1,40(sp)
    80003c36:	f04a                	sd	s2,32(sp)
    80003c38:	ec4e                	sd	s3,24(sp)
    80003c3a:	e852                	sd	s4,16(sp)
    80003c3c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c3e:	04451703          	lh	a4,68(a0)
    80003c42:	4785                	li	a5,1
    80003c44:	00f71a63          	bne	a4,a5,80003c58 <dirlookup+0x2a>
    80003c48:	892a                	mv	s2,a0
    80003c4a:	89ae                	mv	s3,a1
    80003c4c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c4e:	457c                	lw	a5,76(a0)
    80003c50:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c52:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c54:	e79d                	bnez	a5,80003c82 <dirlookup+0x54>
    80003c56:	a8a5                	j	80003cce <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c58:	00005517          	auipc	a0,0x5
    80003c5c:	9b050513          	addi	a0,a0,-1616 # 80008608 <syscalls+0x1a0>
    80003c60:	ffffd097          	auipc	ra,0xffffd
    80003c64:	8e8080e7          	jalr	-1816(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c68:	00005517          	auipc	a0,0x5
    80003c6c:	9b850513          	addi	a0,a0,-1608 # 80008620 <syscalls+0x1b8>
    80003c70:	ffffd097          	auipc	ra,0xffffd
    80003c74:	8d8080e7          	jalr	-1832(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c78:	24c1                	addiw	s1,s1,16
    80003c7a:	04c92783          	lw	a5,76(s2)
    80003c7e:	04f4f763          	bgeu	s1,a5,80003ccc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c82:	4741                	li	a4,16
    80003c84:	86a6                	mv	a3,s1
    80003c86:	fc040613          	addi	a2,s0,-64
    80003c8a:	4581                	li	a1,0
    80003c8c:	854a                	mv	a0,s2
    80003c8e:	00000097          	auipc	ra,0x0
    80003c92:	d72080e7          	jalr	-654(ra) # 80003a00 <readi>
    80003c96:	47c1                	li	a5,16
    80003c98:	fcf518e3          	bne	a0,a5,80003c68 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c9c:	fc045783          	lhu	a5,-64(s0)
    80003ca0:	dfe1                	beqz	a5,80003c78 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ca2:	fc240593          	addi	a1,s0,-62
    80003ca6:	854e                	mv	a0,s3
    80003ca8:	00000097          	auipc	ra,0x0
    80003cac:	f6c080e7          	jalr	-148(ra) # 80003c14 <namecmp>
    80003cb0:	f561                	bnez	a0,80003c78 <dirlookup+0x4a>
      if(poff)
    80003cb2:	000a0463          	beqz	s4,80003cba <dirlookup+0x8c>
        *poff = off;
    80003cb6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cba:	fc045583          	lhu	a1,-64(s0)
    80003cbe:	00092503          	lw	a0,0(s2)
    80003cc2:	fffff097          	auipc	ra,0xfffff
    80003cc6:	756080e7          	jalr	1878(ra) # 80003418 <iget>
    80003cca:	a011                	j	80003cce <dirlookup+0xa0>
  return 0;
    80003ccc:	4501                	li	a0,0
}
    80003cce:	70e2                	ld	ra,56(sp)
    80003cd0:	7442                	ld	s0,48(sp)
    80003cd2:	74a2                	ld	s1,40(sp)
    80003cd4:	7902                	ld	s2,32(sp)
    80003cd6:	69e2                	ld	s3,24(sp)
    80003cd8:	6a42                	ld	s4,16(sp)
    80003cda:	6121                	addi	sp,sp,64
    80003cdc:	8082                	ret

0000000080003cde <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cde:	711d                	addi	sp,sp,-96
    80003ce0:	ec86                	sd	ra,88(sp)
    80003ce2:	e8a2                	sd	s0,80(sp)
    80003ce4:	e4a6                	sd	s1,72(sp)
    80003ce6:	e0ca                	sd	s2,64(sp)
    80003ce8:	fc4e                	sd	s3,56(sp)
    80003cea:	f852                	sd	s4,48(sp)
    80003cec:	f456                	sd	s5,40(sp)
    80003cee:	f05a                	sd	s6,32(sp)
    80003cf0:	ec5e                	sd	s7,24(sp)
    80003cf2:	e862                	sd	s8,16(sp)
    80003cf4:	e466                	sd	s9,8(sp)
    80003cf6:	1080                	addi	s0,sp,96
    80003cf8:	84aa                	mv	s1,a0
    80003cfa:	8b2e                	mv	s6,a1
    80003cfc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cfe:	00054703          	lbu	a4,0(a0)
    80003d02:	02f00793          	li	a5,47
    80003d06:	02f70363          	beq	a4,a5,80003d2c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d0a:	ffffe097          	auipc	ra,0xffffe
    80003d0e:	d1c080e7          	jalr	-740(ra) # 80001a26 <myproc>
    80003d12:	15053503          	ld	a0,336(a0)
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	9f8080e7          	jalr	-1544(ra) # 8000370e <idup>
    80003d1e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d20:	02f00913          	li	s2,47
  len = path - s;
    80003d24:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d26:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d28:	4c05                	li	s8,1
    80003d2a:	a865                	j	80003de2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d2c:	4585                	li	a1,1
    80003d2e:	4505                	li	a0,1
    80003d30:	fffff097          	auipc	ra,0xfffff
    80003d34:	6e8080e7          	jalr	1768(ra) # 80003418 <iget>
    80003d38:	89aa                	mv	s3,a0
    80003d3a:	b7dd                	j	80003d20 <namex+0x42>
      iunlockput(ip);
    80003d3c:	854e                	mv	a0,s3
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	c70080e7          	jalr	-912(ra) # 800039ae <iunlockput>
      return 0;
    80003d46:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d48:	854e                	mv	a0,s3
    80003d4a:	60e6                	ld	ra,88(sp)
    80003d4c:	6446                	ld	s0,80(sp)
    80003d4e:	64a6                	ld	s1,72(sp)
    80003d50:	6906                	ld	s2,64(sp)
    80003d52:	79e2                	ld	s3,56(sp)
    80003d54:	7a42                	ld	s4,48(sp)
    80003d56:	7aa2                	ld	s5,40(sp)
    80003d58:	7b02                	ld	s6,32(sp)
    80003d5a:	6be2                	ld	s7,24(sp)
    80003d5c:	6c42                	ld	s8,16(sp)
    80003d5e:	6ca2                	ld	s9,8(sp)
    80003d60:	6125                	addi	sp,sp,96
    80003d62:	8082                	ret
      iunlock(ip);
    80003d64:	854e                	mv	a0,s3
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	aa8080e7          	jalr	-1368(ra) # 8000380e <iunlock>
      return ip;
    80003d6e:	bfe9                	j	80003d48 <namex+0x6a>
      iunlockput(ip);
    80003d70:	854e                	mv	a0,s3
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	c3c080e7          	jalr	-964(ra) # 800039ae <iunlockput>
      return 0;
    80003d7a:	89d2                	mv	s3,s4
    80003d7c:	b7f1                	j	80003d48 <namex+0x6a>
  len = path - s;
    80003d7e:	40b48633          	sub	a2,s1,a1
    80003d82:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d86:	094cd463          	bge	s9,s4,80003e0e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d8a:	4639                	li	a2,14
    80003d8c:	8556                	mv	a0,s5
    80003d8e:	ffffd097          	auipc	ra,0xffffd
    80003d92:	fde080e7          	jalr	-34(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003d96:	0004c783          	lbu	a5,0(s1)
    80003d9a:	01279763          	bne	a5,s2,80003da8 <namex+0xca>
    path++;
    80003d9e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003da0:	0004c783          	lbu	a5,0(s1)
    80003da4:	ff278de3          	beq	a5,s2,80003d9e <namex+0xc0>
    ilock(ip);
    80003da8:	854e                	mv	a0,s3
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	9a2080e7          	jalr	-1630(ra) # 8000374c <ilock>
    if(ip->type != T_DIR){
    80003db2:	04499783          	lh	a5,68(s3)
    80003db6:	f98793e3          	bne	a5,s8,80003d3c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dba:	000b0563          	beqz	s6,80003dc4 <namex+0xe6>
    80003dbe:	0004c783          	lbu	a5,0(s1)
    80003dc2:	d3cd                	beqz	a5,80003d64 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dc4:	865e                	mv	a2,s7
    80003dc6:	85d6                	mv	a1,s5
    80003dc8:	854e                	mv	a0,s3
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	e64080e7          	jalr	-412(ra) # 80003c2e <dirlookup>
    80003dd2:	8a2a                	mv	s4,a0
    80003dd4:	dd51                	beqz	a0,80003d70 <namex+0x92>
    iunlockput(ip);
    80003dd6:	854e                	mv	a0,s3
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	bd6080e7          	jalr	-1066(ra) # 800039ae <iunlockput>
    ip = next;
    80003de0:	89d2                	mv	s3,s4
  while(*path == '/')
    80003de2:	0004c783          	lbu	a5,0(s1)
    80003de6:	05279763          	bne	a5,s2,80003e34 <namex+0x156>
    path++;
    80003dea:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dec:	0004c783          	lbu	a5,0(s1)
    80003df0:	ff278de3          	beq	a5,s2,80003dea <namex+0x10c>
  if(*path == 0)
    80003df4:	c79d                	beqz	a5,80003e22 <namex+0x144>
    path++;
    80003df6:	85a6                	mv	a1,s1
  len = path - s;
    80003df8:	8a5e                	mv	s4,s7
    80003dfa:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dfc:	01278963          	beq	a5,s2,80003e0e <namex+0x130>
    80003e00:	dfbd                	beqz	a5,80003d7e <namex+0xa0>
    path++;
    80003e02:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e04:	0004c783          	lbu	a5,0(s1)
    80003e08:	ff279ce3          	bne	a5,s2,80003e00 <namex+0x122>
    80003e0c:	bf8d                	j	80003d7e <namex+0xa0>
    memmove(name, s, len);
    80003e0e:	2601                	sext.w	a2,a2
    80003e10:	8556                	mv	a0,s5
    80003e12:	ffffd097          	auipc	ra,0xffffd
    80003e16:	f5a080e7          	jalr	-166(ra) # 80000d6c <memmove>
    name[len] = 0;
    80003e1a:	9a56                	add	s4,s4,s5
    80003e1c:	000a0023          	sb	zero,0(s4)
    80003e20:	bf9d                	j	80003d96 <namex+0xb8>
  if(nameiparent){
    80003e22:	f20b03e3          	beqz	s6,80003d48 <namex+0x6a>
    iput(ip);
    80003e26:	854e                	mv	a0,s3
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	ade080e7          	jalr	-1314(ra) # 80003906 <iput>
    return 0;
    80003e30:	4981                	li	s3,0
    80003e32:	bf19                	j	80003d48 <namex+0x6a>
  if(*path == 0)
    80003e34:	d7fd                	beqz	a5,80003e22 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e36:	0004c783          	lbu	a5,0(s1)
    80003e3a:	85a6                	mv	a1,s1
    80003e3c:	b7d1                	j	80003e00 <namex+0x122>

0000000080003e3e <dirlink>:
{
    80003e3e:	7139                	addi	sp,sp,-64
    80003e40:	fc06                	sd	ra,56(sp)
    80003e42:	f822                	sd	s0,48(sp)
    80003e44:	f426                	sd	s1,40(sp)
    80003e46:	f04a                	sd	s2,32(sp)
    80003e48:	ec4e                	sd	s3,24(sp)
    80003e4a:	e852                	sd	s4,16(sp)
    80003e4c:	0080                	addi	s0,sp,64
    80003e4e:	892a                	mv	s2,a0
    80003e50:	8a2e                	mv	s4,a1
    80003e52:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e54:	4601                	li	a2,0
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	dd8080e7          	jalr	-552(ra) # 80003c2e <dirlookup>
    80003e5e:	e93d                	bnez	a0,80003ed4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e60:	04c92483          	lw	s1,76(s2)
    80003e64:	c49d                	beqz	s1,80003e92 <dirlink+0x54>
    80003e66:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e68:	4741                	li	a4,16
    80003e6a:	86a6                	mv	a3,s1
    80003e6c:	fc040613          	addi	a2,s0,-64
    80003e70:	4581                	li	a1,0
    80003e72:	854a                	mv	a0,s2
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	b8c080e7          	jalr	-1140(ra) # 80003a00 <readi>
    80003e7c:	47c1                	li	a5,16
    80003e7e:	06f51163          	bne	a0,a5,80003ee0 <dirlink+0xa2>
    if(de.inum == 0)
    80003e82:	fc045783          	lhu	a5,-64(s0)
    80003e86:	c791                	beqz	a5,80003e92 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e88:	24c1                	addiw	s1,s1,16
    80003e8a:	04c92783          	lw	a5,76(s2)
    80003e8e:	fcf4ede3          	bltu	s1,a5,80003e68 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e92:	4639                	li	a2,14
    80003e94:	85d2                	mv	a1,s4
    80003e96:	fc240513          	addi	a0,s0,-62
    80003e9a:	ffffd097          	auipc	ra,0xffffd
    80003e9e:	f8a080e7          	jalr	-118(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80003ea2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea6:	4741                	li	a4,16
    80003ea8:	86a6                	mv	a3,s1
    80003eaa:	fc040613          	addi	a2,s0,-64
    80003eae:	4581                	li	a1,0
    80003eb0:	854a                	mv	a0,s2
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	c46080e7          	jalr	-954(ra) # 80003af8 <writei>
    80003eba:	872a                	mv	a4,a0
    80003ebc:	47c1                	li	a5,16
  return 0;
    80003ebe:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ec0:	02f71863          	bne	a4,a5,80003ef0 <dirlink+0xb2>
}
    80003ec4:	70e2                	ld	ra,56(sp)
    80003ec6:	7442                	ld	s0,48(sp)
    80003ec8:	74a2                	ld	s1,40(sp)
    80003eca:	7902                	ld	s2,32(sp)
    80003ecc:	69e2                	ld	s3,24(sp)
    80003ece:	6a42                	ld	s4,16(sp)
    80003ed0:	6121                	addi	sp,sp,64
    80003ed2:	8082                	ret
    iput(ip);
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	a32080e7          	jalr	-1486(ra) # 80003906 <iput>
    return -1;
    80003edc:	557d                	li	a0,-1
    80003ede:	b7dd                	j	80003ec4 <dirlink+0x86>
      panic("dirlink read");
    80003ee0:	00004517          	auipc	a0,0x4
    80003ee4:	75050513          	addi	a0,a0,1872 # 80008630 <syscalls+0x1c8>
    80003ee8:	ffffc097          	auipc	ra,0xffffc
    80003eec:	660080e7          	jalr	1632(ra) # 80000548 <panic>
    panic("dirlink");
    80003ef0:	00005517          	auipc	a0,0x5
    80003ef4:	86050513          	addi	a0,a0,-1952 # 80008750 <syscalls+0x2e8>
    80003ef8:	ffffc097          	auipc	ra,0xffffc
    80003efc:	650080e7          	jalr	1616(ra) # 80000548 <panic>

0000000080003f00 <namei>:

struct inode*
namei(char *path)
{
    80003f00:	1101                	addi	sp,sp,-32
    80003f02:	ec06                	sd	ra,24(sp)
    80003f04:	e822                	sd	s0,16(sp)
    80003f06:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f08:	fe040613          	addi	a2,s0,-32
    80003f0c:	4581                	li	a1,0
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	dd0080e7          	jalr	-560(ra) # 80003cde <namex>
}
    80003f16:	60e2                	ld	ra,24(sp)
    80003f18:	6442                	ld	s0,16(sp)
    80003f1a:	6105                	addi	sp,sp,32
    80003f1c:	8082                	ret

0000000080003f1e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f1e:	1141                	addi	sp,sp,-16
    80003f20:	e406                	sd	ra,8(sp)
    80003f22:	e022                	sd	s0,0(sp)
    80003f24:	0800                	addi	s0,sp,16
    80003f26:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f28:	4585                	li	a1,1
    80003f2a:	00000097          	auipc	ra,0x0
    80003f2e:	db4080e7          	jalr	-588(ra) # 80003cde <namex>
}
    80003f32:	60a2                	ld	ra,8(sp)
    80003f34:	6402                	ld	s0,0(sp)
    80003f36:	0141                	addi	sp,sp,16
    80003f38:	8082                	ret

0000000080003f3a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f3a:	1101                	addi	sp,sp,-32
    80003f3c:	ec06                	sd	ra,24(sp)
    80003f3e:	e822                	sd	s0,16(sp)
    80003f40:	e426                	sd	s1,8(sp)
    80003f42:	e04a                	sd	s2,0(sp)
    80003f44:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f46:	0001e917          	auipc	s2,0x1e
    80003f4a:	9c290913          	addi	s2,s2,-1598 # 80021908 <log>
    80003f4e:	01892583          	lw	a1,24(s2)
    80003f52:	02892503          	lw	a0,40(s2)
    80003f56:	fffff097          	auipc	ra,0xfffff
    80003f5a:	ff4080e7          	jalr	-12(ra) # 80002f4a <bread>
    80003f5e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f60:	02c92683          	lw	a3,44(s2)
    80003f64:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f66:	02d05763          	blez	a3,80003f94 <write_head+0x5a>
    80003f6a:	0001e797          	auipc	a5,0x1e
    80003f6e:	9ce78793          	addi	a5,a5,-1586 # 80021938 <log+0x30>
    80003f72:	05c50713          	addi	a4,a0,92
    80003f76:	36fd                	addiw	a3,a3,-1
    80003f78:	1682                	slli	a3,a3,0x20
    80003f7a:	9281                	srli	a3,a3,0x20
    80003f7c:	068a                	slli	a3,a3,0x2
    80003f7e:	0001e617          	auipc	a2,0x1e
    80003f82:	9be60613          	addi	a2,a2,-1602 # 8002193c <log+0x34>
    80003f86:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f88:	4390                	lw	a2,0(a5)
    80003f8a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f8c:	0791                	addi	a5,a5,4
    80003f8e:	0711                	addi	a4,a4,4
    80003f90:	fed79ce3          	bne	a5,a3,80003f88 <write_head+0x4e>
  }
  bwrite(buf);
    80003f94:	8526                	mv	a0,s1
    80003f96:	fffff097          	auipc	ra,0xfffff
    80003f9a:	0a6080e7          	jalr	166(ra) # 8000303c <bwrite>
  brelse(buf);
    80003f9e:	8526                	mv	a0,s1
    80003fa0:	fffff097          	auipc	ra,0xfffff
    80003fa4:	0da080e7          	jalr	218(ra) # 8000307a <brelse>
}
    80003fa8:	60e2                	ld	ra,24(sp)
    80003faa:	6442                	ld	s0,16(sp)
    80003fac:	64a2                	ld	s1,8(sp)
    80003fae:	6902                	ld	s2,0(sp)
    80003fb0:	6105                	addi	sp,sp,32
    80003fb2:	8082                	ret

0000000080003fb4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb4:	0001e797          	auipc	a5,0x1e
    80003fb8:	9807a783          	lw	a5,-1664(a5) # 80021934 <log+0x2c>
    80003fbc:	0af05663          	blez	a5,80004068 <install_trans+0xb4>
{
    80003fc0:	7139                	addi	sp,sp,-64
    80003fc2:	fc06                	sd	ra,56(sp)
    80003fc4:	f822                	sd	s0,48(sp)
    80003fc6:	f426                	sd	s1,40(sp)
    80003fc8:	f04a                	sd	s2,32(sp)
    80003fca:	ec4e                	sd	s3,24(sp)
    80003fcc:	e852                	sd	s4,16(sp)
    80003fce:	e456                	sd	s5,8(sp)
    80003fd0:	0080                	addi	s0,sp,64
    80003fd2:	0001ea97          	auipc	s5,0x1e
    80003fd6:	966a8a93          	addi	s5,s5,-1690 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fda:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fdc:	0001e997          	auipc	s3,0x1e
    80003fe0:	92c98993          	addi	s3,s3,-1748 # 80021908 <log>
    80003fe4:	0189a583          	lw	a1,24(s3)
    80003fe8:	014585bb          	addw	a1,a1,s4
    80003fec:	2585                	addiw	a1,a1,1
    80003fee:	0289a503          	lw	a0,40(s3)
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	f58080e7          	jalr	-168(ra) # 80002f4a <bread>
    80003ffa:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ffc:	000aa583          	lw	a1,0(s5)
    80004000:	0289a503          	lw	a0,40(s3)
    80004004:	fffff097          	auipc	ra,0xfffff
    80004008:	f46080e7          	jalr	-186(ra) # 80002f4a <bread>
    8000400c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000400e:	40000613          	li	a2,1024
    80004012:	05890593          	addi	a1,s2,88
    80004016:	05850513          	addi	a0,a0,88
    8000401a:	ffffd097          	auipc	ra,0xffffd
    8000401e:	d52080e7          	jalr	-686(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    80004022:	8526                	mv	a0,s1
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	018080e7          	jalr	24(ra) # 8000303c <bwrite>
    bunpin(dbuf);
    8000402c:	8526                	mv	a0,s1
    8000402e:	fffff097          	auipc	ra,0xfffff
    80004032:	126080e7          	jalr	294(ra) # 80003154 <bunpin>
    brelse(lbuf);
    80004036:	854a                	mv	a0,s2
    80004038:	fffff097          	auipc	ra,0xfffff
    8000403c:	042080e7          	jalr	66(ra) # 8000307a <brelse>
    brelse(dbuf);
    80004040:	8526                	mv	a0,s1
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	038080e7          	jalr	56(ra) # 8000307a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000404a:	2a05                	addiw	s4,s4,1
    8000404c:	0a91                	addi	s5,s5,4
    8000404e:	02c9a783          	lw	a5,44(s3)
    80004052:	f8fa49e3          	blt	s4,a5,80003fe4 <install_trans+0x30>
}
    80004056:	70e2                	ld	ra,56(sp)
    80004058:	7442                	ld	s0,48(sp)
    8000405a:	74a2                	ld	s1,40(sp)
    8000405c:	7902                	ld	s2,32(sp)
    8000405e:	69e2                	ld	s3,24(sp)
    80004060:	6a42                	ld	s4,16(sp)
    80004062:	6aa2                	ld	s5,8(sp)
    80004064:	6121                	addi	sp,sp,64
    80004066:	8082                	ret
    80004068:	8082                	ret

000000008000406a <initlog>:
{
    8000406a:	7179                	addi	sp,sp,-48
    8000406c:	f406                	sd	ra,40(sp)
    8000406e:	f022                	sd	s0,32(sp)
    80004070:	ec26                	sd	s1,24(sp)
    80004072:	e84a                	sd	s2,16(sp)
    80004074:	e44e                	sd	s3,8(sp)
    80004076:	1800                	addi	s0,sp,48
    80004078:	892a                	mv	s2,a0
    8000407a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000407c:	0001e497          	auipc	s1,0x1e
    80004080:	88c48493          	addi	s1,s1,-1908 # 80021908 <log>
    80004084:	00004597          	auipc	a1,0x4
    80004088:	5bc58593          	addi	a1,a1,1468 # 80008640 <syscalls+0x1d8>
    8000408c:	8526                	mv	a0,s1
    8000408e:	ffffd097          	auipc	ra,0xffffd
    80004092:	af2080e7          	jalr	-1294(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80004096:	0149a583          	lw	a1,20(s3)
    8000409a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000409c:	0109a783          	lw	a5,16(s3)
    800040a0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040a2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040a6:	854a                	mv	a0,s2
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	ea2080e7          	jalr	-350(ra) # 80002f4a <bread>
  log.lh.n = lh->n;
    800040b0:	4d3c                	lw	a5,88(a0)
    800040b2:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040b4:	02f05563          	blez	a5,800040de <initlog+0x74>
    800040b8:	05c50713          	addi	a4,a0,92
    800040bc:	0001e697          	auipc	a3,0x1e
    800040c0:	87c68693          	addi	a3,a3,-1924 # 80021938 <log+0x30>
    800040c4:	37fd                	addiw	a5,a5,-1
    800040c6:	1782                	slli	a5,a5,0x20
    800040c8:	9381                	srli	a5,a5,0x20
    800040ca:	078a                	slli	a5,a5,0x2
    800040cc:	06050613          	addi	a2,a0,96
    800040d0:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040d2:	4310                	lw	a2,0(a4)
    800040d4:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040d6:	0711                	addi	a4,a4,4
    800040d8:	0691                	addi	a3,a3,4
    800040da:	fef71ce3          	bne	a4,a5,800040d2 <initlog+0x68>
  brelse(buf);
    800040de:	fffff097          	auipc	ra,0xfffff
    800040e2:	f9c080e7          	jalr	-100(ra) # 8000307a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800040e6:	00000097          	auipc	ra,0x0
    800040ea:	ece080e7          	jalr	-306(ra) # 80003fb4 <install_trans>
  log.lh.n = 0;
    800040ee:	0001e797          	auipc	a5,0x1e
    800040f2:	8407a323          	sw	zero,-1978(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	e44080e7          	jalr	-444(ra) # 80003f3a <write_head>
}
    800040fe:	70a2                	ld	ra,40(sp)
    80004100:	7402                	ld	s0,32(sp)
    80004102:	64e2                	ld	s1,24(sp)
    80004104:	6942                	ld	s2,16(sp)
    80004106:	69a2                	ld	s3,8(sp)
    80004108:	6145                	addi	sp,sp,48
    8000410a:	8082                	ret

000000008000410c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000410c:	1101                	addi	sp,sp,-32
    8000410e:	ec06                	sd	ra,24(sp)
    80004110:	e822                	sd	s0,16(sp)
    80004112:	e426                	sd	s1,8(sp)
    80004114:	e04a                	sd	s2,0(sp)
    80004116:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004118:	0001d517          	auipc	a0,0x1d
    8000411c:	7f050513          	addi	a0,a0,2032 # 80021908 <log>
    80004120:	ffffd097          	auipc	ra,0xffffd
    80004124:	af0080e7          	jalr	-1296(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    80004128:	0001d497          	auipc	s1,0x1d
    8000412c:	7e048493          	addi	s1,s1,2016 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004130:	4979                	li	s2,30
    80004132:	a039                	j	80004140 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004134:	85a6                	mv	a1,s1
    80004136:	8526                	mv	a0,s1
    80004138:	ffffe097          	auipc	ra,0xffffe
    8000413c:	0fe080e7          	jalr	254(ra) # 80002236 <sleep>
    if(log.committing){
    80004140:	50dc                	lw	a5,36(s1)
    80004142:	fbed                	bnez	a5,80004134 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004144:	509c                	lw	a5,32(s1)
    80004146:	0017871b          	addiw	a4,a5,1
    8000414a:	0007069b          	sext.w	a3,a4
    8000414e:	0027179b          	slliw	a5,a4,0x2
    80004152:	9fb9                	addw	a5,a5,a4
    80004154:	0017979b          	slliw	a5,a5,0x1
    80004158:	54d8                	lw	a4,44(s1)
    8000415a:	9fb9                	addw	a5,a5,a4
    8000415c:	00f95963          	bge	s2,a5,8000416e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004160:	85a6                	mv	a1,s1
    80004162:	8526                	mv	a0,s1
    80004164:	ffffe097          	auipc	ra,0xffffe
    80004168:	0d2080e7          	jalr	210(ra) # 80002236 <sleep>
    8000416c:	bfd1                	j	80004140 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000416e:	0001d517          	auipc	a0,0x1d
    80004172:	79a50513          	addi	a0,a0,1946 # 80021908 <log>
    80004176:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004178:	ffffd097          	auipc	ra,0xffffd
    8000417c:	b4c080e7          	jalr	-1204(ra) # 80000cc4 <release>
      break;
    }
  }
}
    80004180:	60e2                	ld	ra,24(sp)
    80004182:	6442                	ld	s0,16(sp)
    80004184:	64a2                	ld	s1,8(sp)
    80004186:	6902                	ld	s2,0(sp)
    80004188:	6105                	addi	sp,sp,32
    8000418a:	8082                	ret

000000008000418c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000418c:	7139                	addi	sp,sp,-64
    8000418e:	fc06                	sd	ra,56(sp)
    80004190:	f822                	sd	s0,48(sp)
    80004192:	f426                	sd	s1,40(sp)
    80004194:	f04a                	sd	s2,32(sp)
    80004196:	ec4e                	sd	s3,24(sp)
    80004198:	e852                	sd	s4,16(sp)
    8000419a:	e456                	sd	s5,8(sp)
    8000419c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000419e:	0001d497          	auipc	s1,0x1d
    800041a2:	76a48493          	addi	s1,s1,1898 # 80021908 <log>
    800041a6:	8526                	mv	a0,s1
    800041a8:	ffffd097          	auipc	ra,0xffffd
    800041ac:	a68080e7          	jalr	-1432(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    800041b0:	509c                	lw	a5,32(s1)
    800041b2:	37fd                	addiw	a5,a5,-1
    800041b4:	0007891b          	sext.w	s2,a5
    800041b8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041ba:	50dc                	lw	a5,36(s1)
    800041bc:	efb9                	bnez	a5,8000421a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041be:	06091663          	bnez	s2,8000422a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041c2:	0001d497          	auipc	s1,0x1d
    800041c6:	74648493          	addi	s1,s1,1862 # 80021908 <log>
    800041ca:	4785                	li	a5,1
    800041cc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041ce:	8526                	mv	a0,s1
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	af4080e7          	jalr	-1292(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041d8:	54dc                	lw	a5,44(s1)
    800041da:	06f04763          	bgtz	a5,80004248 <end_op+0xbc>
    acquire(&log.lock);
    800041de:	0001d497          	auipc	s1,0x1d
    800041e2:	72a48493          	addi	s1,s1,1834 # 80021908 <log>
    800041e6:	8526                	mv	a0,s1
    800041e8:	ffffd097          	auipc	ra,0xffffd
    800041ec:	a28080e7          	jalr	-1496(ra) # 80000c10 <acquire>
    log.committing = 0;
    800041f0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041f4:	8526                	mv	a0,s1
    800041f6:	ffffe097          	auipc	ra,0xffffe
    800041fa:	1c6080e7          	jalr	454(ra) # 800023bc <wakeup>
    release(&log.lock);
    800041fe:	8526                	mv	a0,s1
    80004200:	ffffd097          	auipc	ra,0xffffd
    80004204:	ac4080e7          	jalr	-1340(ra) # 80000cc4 <release>
}
    80004208:	70e2                	ld	ra,56(sp)
    8000420a:	7442                	ld	s0,48(sp)
    8000420c:	74a2                	ld	s1,40(sp)
    8000420e:	7902                	ld	s2,32(sp)
    80004210:	69e2                	ld	s3,24(sp)
    80004212:	6a42                	ld	s4,16(sp)
    80004214:	6aa2                	ld	s5,8(sp)
    80004216:	6121                	addi	sp,sp,64
    80004218:	8082                	ret
    panic("log.committing");
    8000421a:	00004517          	auipc	a0,0x4
    8000421e:	42e50513          	addi	a0,a0,1070 # 80008648 <syscalls+0x1e0>
    80004222:	ffffc097          	auipc	ra,0xffffc
    80004226:	326080e7          	jalr	806(ra) # 80000548 <panic>
    wakeup(&log);
    8000422a:	0001d497          	auipc	s1,0x1d
    8000422e:	6de48493          	addi	s1,s1,1758 # 80021908 <log>
    80004232:	8526                	mv	a0,s1
    80004234:	ffffe097          	auipc	ra,0xffffe
    80004238:	188080e7          	jalr	392(ra) # 800023bc <wakeup>
  release(&log.lock);
    8000423c:	8526                	mv	a0,s1
    8000423e:	ffffd097          	auipc	ra,0xffffd
    80004242:	a86080e7          	jalr	-1402(ra) # 80000cc4 <release>
  if(do_commit){
    80004246:	b7c9                	j	80004208 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004248:	0001da97          	auipc	s5,0x1d
    8000424c:	6f0a8a93          	addi	s5,s5,1776 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004250:	0001da17          	auipc	s4,0x1d
    80004254:	6b8a0a13          	addi	s4,s4,1720 # 80021908 <log>
    80004258:	018a2583          	lw	a1,24(s4)
    8000425c:	012585bb          	addw	a1,a1,s2
    80004260:	2585                	addiw	a1,a1,1
    80004262:	028a2503          	lw	a0,40(s4)
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	ce4080e7          	jalr	-796(ra) # 80002f4a <bread>
    8000426e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004270:	000aa583          	lw	a1,0(s5)
    80004274:	028a2503          	lw	a0,40(s4)
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	cd2080e7          	jalr	-814(ra) # 80002f4a <bread>
    80004280:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004282:	40000613          	li	a2,1024
    80004286:	05850593          	addi	a1,a0,88
    8000428a:	05848513          	addi	a0,s1,88
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	ade080e7          	jalr	-1314(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    80004296:	8526                	mv	a0,s1
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	da4080e7          	jalr	-604(ra) # 8000303c <bwrite>
    brelse(from);
    800042a0:	854e                	mv	a0,s3
    800042a2:	fffff097          	auipc	ra,0xfffff
    800042a6:	dd8080e7          	jalr	-552(ra) # 8000307a <brelse>
    brelse(to);
    800042aa:	8526                	mv	a0,s1
    800042ac:	fffff097          	auipc	ra,0xfffff
    800042b0:	dce080e7          	jalr	-562(ra) # 8000307a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b4:	2905                	addiw	s2,s2,1
    800042b6:	0a91                	addi	s5,s5,4
    800042b8:	02ca2783          	lw	a5,44(s4)
    800042bc:	f8f94ee3          	blt	s2,a5,80004258 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042c0:	00000097          	auipc	ra,0x0
    800042c4:	c7a080e7          	jalr	-902(ra) # 80003f3a <write_head>
    install_trans(); // Now install writes to home locations
    800042c8:	00000097          	auipc	ra,0x0
    800042cc:	cec080e7          	jalr	-788(ra) # 80003fb4 <install_trans>
    log.lh.n = 0;
    800042d0:	0001d797          	auipc	a5,0x1d
    800042d4:	6607a223          	sw	zero,1636(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	c62080e7          	jalr	-926(ra) # 80003f3a <write_head>
    800042e0:	bdfd                	j	800041de <end_op+0x52>

00000000800042e2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042e2:	1101                	addi	sp,sp,-32
    800042e4:	ec06                	sd	ra,24(sp)
    800042e6:	e822                	sd	s0,16(sp)
    800042e8:	e426                	sd	s1,8(sp)
    800042ea:	e04a                	sd	s2,0(sp)
    800042ec:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042ee:	0001d717          	auipc	a4,0x1d
    800042f2:	64672703          	lw	a4,1606(a4) # 80021934 <log+0x2c>
    800042f6:	47f5                	li	a5,29
    800042f8:	08e7c063          	blt	a5,a4,80004378 <log_write+0x96>
    800042fc:	84aa                	mv	s1,a0
    800042fe:	0001d797          	auipc	a5,0x1d
    80004302:	6267a783          	lw	a5,1574(a5) # 80021924 <log+0x1c>
    80004306:	37fd                	addiw	a5,a5,-1
    80004308:	06f75863          	bge	a4,a5,80004378 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000430c:	0001d797          	auipc	a5,0x1d
    80004310:	61c7a783          	lw	a5,1564(a5) # 80021928 <log+0x20>
    80004314:	06f05a63          	blez	a5,80004388 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004318:	0001d917          	auipc	s2,0x1d
    8000431c:	5f090913          	addi	s2,s2,1520 # 80021908 <log>
    80004320:	854a                	mv	a0,s2
    80004322:	ffffd097          	auipc	ra,0xffffd
    80004326:	8ee080e7          	jalr	-1810(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000432a:	02c92603          	lw	a2,44(s2)
    8000432e:	06c05563          	blez	a2,80004398 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004332:	44cc                	lw	a1,12(s1)
    80004334:	0001d717          	auipc	a4,0x1d
    80004338:	60470713          	addi	a4,a4,1540 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000433c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000433e:	4314                	lw	a3,0(a4)
    80004340:	04b68d63          	beq	a3,a1,8000439a <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004344:	2785                	addiw	a5,a5,1
    80004346:	0711                	addi	a4,a4,4
    80004348:	fec79be3          	bne	a5,a2,8000433e <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000434c:	0621                	addi	a2,a2,8
    8000434e:	060a                	slli	a2,a2,0x2
    80004350:	0001d797          	auipc	a5,0x1d
    80004354:	5b878793          	addi	a5,a5,1464 # 80021908 <log>
    80004358:	963e                	add	a2,a2,a5
    8000435a:	44dc                	lw	a5,12(s1)
    8000435c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000435e:	8526                	mv	a0,s1
    80004360:	fffff097          	auipc	ra,0xfffff
    80004364:	db8080e7          	jalr	-584(ra) # 80003118 <bpin>
    log.lh.n++;
    80004368:	0001d717          	auipc	a4,0x1d
    8000436c:	5a070713          	addi	a4,a4,1440 # 80021908 <log>
    80004370:	575c                	lw	a5,44(a4)
    80004372:	2785                	addiw	a5,a5,1
    80004374:	d75c                	sw	a5,44(a4)
    80004376:	a83d                	j	800043b4 <log_write+0xd2>
    panic("too big a transaction");
    80004378:	00004517          	auipc	a0,0x4
    8000437c:	2e050513          	addi	a0,a0,736 # 80008658 <syscalls+0x1f0>
    80004380:	ffffc097          	auipc	ra,0xffffc
    80004384:	1c8080e7          	jalr	456(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004388:	00004517          	auipc	a0,0x4
    8000438c:	2e850513          	addi	a0,a0,744 # 80008670 <syscalls+0x208>
    80004390:	ffffc097          	auipc	ra,0xffffc
    80004394:	1b8080e7          	jalr	440(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004398:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000439a:	00878713          	addi	a4,a5,8
    8000439e:	00271693          	slli	a3,a4,0x2
    800043a2:	0001d717          	auipc	a4,0x1d
    800043a6:	56670713          	addi	a4,a4,1382 # 80021908 <log>
    800043aa:	9736                	add	a4,a4,a3
    800043ac:	44d4                	lw	a3,12(s1)
    800043ae:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043b0:	faf607e3          	beq	a2,a5,8000435e <log_write+0x7c>
  }
  release(&log.lock);
    800043b4:	0001d517          	auipc	a0,0x1d
    800043b8:	55450513          	addi	a0,a0,1364 # 80021908 <log>
    800043bc:	ffffd097          	auipc	ra,0xffffd
    800043c0:	908080e7          	jalr	-1784(ra) # 80000cc4 <release>
}
    800043c4:	60e2                	ld	ra,24(sp)
    800043c6:	6442                	ld	s0,16(sp)
    800043c8:	64a2                	ld	s1,8(sp)
    800043ca:	6902                	ld	s2,0(sp)
    800043cc:	6105                	addi	sp,sp,32
    800043ce:	8082                	ret

00000000800043d0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043d0:	1101                	addi	sp,sp,-32
    800043d2:	ec06                	sd	ra,24(sp)
    800043d4:	e822                	sd	s0,16(sp)
    800043d6:	e426                	sd	s1,8(sp)
    800043d8:	e04a                	sd	s2,0(sp)
    800043da:	1000                	addi	s0,sp,32
    800043dc:	84aa                	mv	s1,a0
    800043de:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043e0:	00004597          	auipc	a1,0x4
    800043e4:	2b058593          	addi	a1,a1,688 # 80008690 <syscalls+0x228>
    800043e8:	0521                	addi	a0,a0,8
    800043ea:	ffffc097          	auipc	ra,0xffffc
    800043ee:	796080e7          	jalr	1942(ra) # 80000b80 <initlock>
  lk->name = name;
    800043f2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043f6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043fa:	0204a423          	sw	zero,40(s1)
}
    800043fe:	60e2                	ld	ra,24(sp)
    80004400:	6442                	ld	s0,16(sp)
    80004402:	64a2                	ld	s1,8(sp)
    80004404:	6902                	ld	s2,0(sp)
    80004406:	6105                	addi	sp,sp,32
    80004408:	8082                	ret

000000008000440a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000440a:	1101                	addi	sp,sp,-32
    8000440c:	ec06                	sd	ra,24(sp)
    8000440e:	e822                	sd	s0,16(sp)
    80004410:	e426                	sd	s1,8(sp)
    80004412:	e04a                	sd	s2,0(sp)
    80004414:	1000                	addi	s0,sp,32
    80004416:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004418:	00850913          	addi	s2,a0,8
    8000441c:	854a                	mv	a0,s2
    8000441e:	ffffc097          	auipc	ra,0xffffc
    80004422:	7f2080e7          	jalr	2034(ra) # 80000c10 <acquire>
  while (lk->locked) {
    80004426:	409c                	lw	a5,0(s1)
    80004428:	cb89                	beqz	a5,8000443a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000442a:	85ca                	mv	a1,s2
    8000442c:	8526                	mv	a0,s1
    8000442e:	ffffe097          	auipc	ra,0xffffe
    80004432:	e08080e7          	jalr	-504(ra) # 80002236 <sleep>
  while (lk->locked) {
    80004436:	409c                	lw	a5,0(s1)
    80004438:	fbed                	bnez	a5,8000442a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000443a:	4785                	li	a5,1
    8000443c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000443e:	ffffd097          	auipc	ra,0xffffd
    80004442:	5e8080e7          	jalr	1512(ra) # 80001a26 <myproc>
    80004446:	5d1c                	lw	a5,56(a0)
    80004448:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000444a:	854a                	mv	a0,s2
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	878080e7          	jalr	-1928(ra) # 80000cc4 <release>
}
    80004454:	60e2                	ld	ra,24(sp)
    80004456:	6442                	ld	s0,16(sp)
    80004458:	64a2                	ld	s1,8(sp)
    8000445a:	6902                	ld	s2,0(sp)
    8000445c:	6105                	addi	sp,sp,32
    8000445e:	8082                	ret

0000000080004460 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004460:	1101                	addi	sp,sp,-32
    80004462:	ec06                	sd	ra,24(sp)
    80004464:	e822                	sd	s0,16(sp)
    80004466:	e426                	sd	s1,8(sp)
    80004468:	e04a                	sd	s2,0(sp)
    8000446a:	1000                	addi	s0,sp,32
    8000446c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000446e:	00850913          	addi	s2,a0,8
    80004472:	854a                	mv	a0,s2
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	79c080e7          	jalr	1948(ra) # 80000c10 <acquire>
  lk->locked = 0;
    8000447c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004480:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004484:	8526                	mv	a0,s1
    80004486:	ffffe097          	auipc	ra,0xffffe
    8000448a:	f36080e7          	jalr	-202(ra) # 800023bc <wakeup>
  release(&lk->lk);
    8000448e:	854a                	mv	a0,s2
    80004490:	ffffd097          	auipc	ra,0xffffd
    80004494:	834080e7          	jalr	-1996(ra) # 80000cc4 <release>
}
    80004498:	60e2                	ld	ra,24(sp)
    8000449a:	6442                	ld	s0,16(sp)
    8000449c:	64a2                	ld	s1,8(sp)
    8000449e:	6902                	ld	s2,0(sp)
    800044a0:	6105                	addi	sp,sp,32
    800044a2:	8082                	ret

00000000800044a4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044a4:	7179                	addi	sp,sp,-48
    800044a6:	f406                	sd	ra,40(sp)
    800044a8:	f022                	sd	s0,32(sp)
    800044aa:	ec26                	sd	s1,24(sp)
    800044ac:	e84a                	sd	s2,16(sp)
    800044ae:	e44e                	sd	s3,8(sp)
    800044b0:	1800                	addi	s0,sp,48
    800044b2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044b4:	00850913          	addi	s2,a0,8
    800044b8:	854a                	mv	a0,s2
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	756080e7          	jalr	1878(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044c2:	409c                	lw	a5,0(s1)
    800044c4:	ef99                	bnez	a5,800044e2 <holdingsleep+0x3e>
    800044c6:	4481                	li	s1,0
  release(&lk->lk);
    800044c8:	854a                	mv	a0,s2
    800044ca:	ffffc097          	auipc	ra,0xffffc
    800044ce:	7fa080e7          	jalr	2042(ra) # 80000cc4 <release>
  return r;
}
    800044d2:	8526                	mv	a0,s1
    800044d4:	70a2                	ld	ra,40(sp)
    800044d6:	7402                	ld	s0,32(sp)
    800044d8:	64e2                	ld	s1,24(sp)
    800044da:	6942                	ld	s2,16(sp)
    800044dc:	69a2                	ld	s3,8(sp)
    800044de:	6145                	addi	sp,sp,48
    800044e0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044e2:	0284a983          	lw	s3,40(s1)
    800044e6:	ffffd097          	auipc	ra,0xffffd
    800044ea:	540080e7          	jalr	1344(ra) # 80001a26 <myproc>
    800044ee:	5d04                	lw	s1,56(a0)
    800044f0:	413484b3          	sub	s1,s1,s3
    800044f4:	0014b493          	seqz	s1,s1
    800044f8:	bfc1                	j	800044c8 <holdingsleep+0x24>

00000000800044fa <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044fa:	1141                	addi	sp,sp,-16
    800044fc:	e406                	sd	ra,8(sp)
    800044fe:	e022                	sd	s0,0(sp)
    80004500:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004502:	00004597          	auipc	a1,0x4
    80004506:	19e58593          	addi	a1,a1,414 # 800086a0 <syscalls+0x238>
    8000450a:	0001d517          	auipc	a0,0x1d
    8000450e:	54650513          	addi	a0,a0,1350 # 80021a50 <ftable>
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	66e080e7          	jalr	1646(ra) # 80000b80 <initlock>
}
    8000451a:	60a2                	ld	ra,8(sp)
    8000451c:	6402                	ld	s0,0(sp)
    8000451e:	0141                	addi	sp,sp,16
    80004520:	8082                	ret

0000000080004522 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004522:	1101                	addi	sp,sp,-32
    80004524:	ec06                	sd	ra,24(sp)
    80004526:	e822                	sd	s0,16(sp)
    80004528:	e426                	sd	s1,8(sp)
    8000452a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000452c:	0001d517          	auipc	a0,0x1d
    80004530:	52450513          	addi	a0,a0,1316 # 80021a50 <ftable>
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	6dc080e7          	jalr	1756(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000453c:	0001d497          	auipc	s1,0x1d
    80004540:	52c48493          	addi	s1,s1,1324 # 80021a68 <ftable+0x18>
    80004544:	0001e717          	auipc	a4,0x1e
    80004548:	4c470713          	addi	a4,a4,1220 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    8000454c:	40dc                	lw	a5,4(s1)
    8000454e:	cf99                	beqz	a5,8000456c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004550:	02848493          	addi	s1,s1,40
    80004554:	fee49ce3          	bne	s1,a4,8000454c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004558:	0001d517          	auipc	a0,0x1d
    8000455c:	4f850513          	addi	a0,a0,1272 # 80021a50 <ftable>
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	764080e7          	jalr	1892(ra) # 80000cc4 <release>
  return 0;
    80004568:	4481                	li	s1,0
    8000456a:	a819                	j	80004580 <filealloc+0x5e>
      f->ref = 1;
    8000456c:	4785                	li	a5,1
    8000456e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004570:	0001d517          	auipc	a0,0x1d
    80004574:	4e050513          	addi	a0,a0,1248 # 80021a50 <ftable>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	74c080e7          	jalr	1868(ra) # 80000cc4 <release>
}
    80004580:	8526                	mv	a0,s1
    80004582:	60e2                	ld	ra,24(sp)
    80004584:	6442                	ld	s0,16(sp)
    80004586:	64a2                	ld	s1,8(sp)
    80004588:	6105                	addi	sp,sp,32
    8000458a:	8082                	ret

000000008000458c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000458c:	1101                	addi	sp,sp,-32
    8000458e:	ec06                	sd	ra,24(sp)
    80004590:	e822                	sd	s0,16(sp)
    80004592:	e426                	sd	s1,8(sp)
    80004594:	1000                	addi	s0,sp,32
    80004596:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004598:	0001d517          	auipc	a0,0x1d
    8000459c:	4b850513          	addi	a0,a0,1208 # 80021a50 <ftable>
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	670080e7          	jalr	1648(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800045a8:	40dc                	lw	a5,4(s1)
    800045aa:	02f05263          	blez	a5,800045ce <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045ae:	2785                	addiw	a5,a5,1
    800045b0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045b2:	0001d517          	auipc	a0,0x1d
    800045b6:	49e50513          	addi	a0,a0,1182 # 80021a50 <ftable>
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	70a080e7          	jalr	1802(ra) # 80000cc4 <release>
  return f;
}
    800045c2:	8526                	mv	a0,s1
    800045c4:	60e2                	ld	ra,24(sp)
    800045c6:	6442                	ld	s0,16(sp)
    800045c8:	64a2                	ld	s1,8(sp)
    800045ca:	6105                	addi	sp,sp,32
    800045cc:	8082                	ret
    panic("filedup");
    800045ce:	00004517          	auipc	a0,0x4
    800045d2:	0da50513          	addi	a0,a0,218 # 800086a8 <syscalls+0x240>
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	f72080e7          	jalr	-142(ra) # 80000548 <panic>

00000000800045de <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045de:	7139                	addi	sp,sp,-64
    800045e0:	fc06                	sd	ra,56(sp)
    800045e2:	f822                	sd	s0,48(sp)
    800045e4:	f426                	sd	s1,40(sp)
    800045e6:	f04a                	sd	s2,32(sp)
    800045e8:	ec4e                	sd	s3,24(sp)
    800045ea:	e852                	sd	s4,16(sp)
    800045ec:	e456                	sd	s5,8(sp)
    800045ee:	0080                	addi	s0,sp,64
    800045f0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045f2:	0001d517          	auipc	a0,0x1d
    800045f6:	45e50513          	addi	a0,a0,1118 # 80021a50 <ftable>
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	616080e7          	jalr	1558(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    80004602:	40dc                	lw	a5,4(s1)
    80004604:	06f05163          	blez	a5,80004666 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004608:	37fd                	addiw	a5,a5,-1
    8000460a:	0007871b          	sext.w	a4,a5
    8000460e:	c0dc                	sw	a5,4(s1)
    80004610:	06e04363          	bgtz	a4,80004676 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004614:	0004a903          	lw	s2,0(s1)
    80004618:	0094ca83          	lbu	s5,9(s1)
    8000461c:	0104ba03          	ld	s4,16(s1)
    80004620:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004624:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004628:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000462c:	0001d517          	auipc	a0,0x1d
    80004630:	42450513          	addi	a0,a0,1060 # 80021a50 <ftable>
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	690080e7          	jalr	1680(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    8000463c:	4785                	li	a5,1
    8000463e:	04f90d63          	beq	s2,a5,80004698 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004642:	3979                	addiw	s2,s2,-2
    80004644:	4785                	li	a5,1
    80004646:	0527e063          	bltu	a5,s2,80004686 <fileclose+0xa8>
    begin_op();
    8000464a:	00000097          	auipc	ra,0x0
    8000464e:	ac2080e7          	jalr	-1342(ra) # 8000410c <begin_op>
    iput(ff.ip);
    80004652:	854e                	mv	a0,s3
    80004654:	fffff097          	auipc	ra,0xfffff
    80004658:	2b2080e7          	jalr	690(ra) # 80003906 <iput>
    end_op();
    8000465c:	00000097          	auipc	ra,0x0
    80004660:	b30080e7          	jalr	-1232(ra) # 8000418c <end_op>
    80004664:	a00d                	j	80004686 <fileclose+0xa8>
    panic("fileclose");
    80004666:	00004517          	auipc	a0,0x4
    8000466a:	04a50513          	addi	a0,a0,74 # 800086b0 <syscalls+0x248>
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	eda080e7          	jalr	-294(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004676:	0001d517          	auipc	a0,0x1d
    8000467a:	3da50513          	addi	a0,a0,986 # 80021a50 <ftable>
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	646080e7          	jalr	1606(ra) # 80000cc4 <release>
  }
}
    80004686:	70e2                	ld	ra,56(sp)
    80004688:	7442                	ld	s0,48(sp)
    8000468a:	74a2                	ld	s1,40(sp)
    8000468c:	7902                	ld	s2,32(sp)
    8000468e:	69e2                	ld	s3,24(sp)
    80004690:	6a42                	ld	s4,16(sp)
    80004692:	6aa2                	ld	s5,8(sp)
    80004694:	6121                	addi	sp,sp,64
    80004696:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004698:	85d6                	mv	a1,s5
    8000469a:	8552                	mv	a0,s4
    8000469c:	00000097          	auipc	ra,0x0
    800046a0:	372080e7          	jalr	882(ra) # 80004a0e <pipeclose>
    800046a4:	b7cd                	j	80004686 <fileclose+0xa8>

00000000800046a6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046a6:	715d                	addi	sp,sp,-80
    800046a8:	e486                	sd	ra,72(sp)
    800046aa:	e0a2                	sd	s0,64(sp)
    800046ac:	fc26                	sd	s1,56(sp)
    800046ae:	f84a                	sd	s2,48(sp)
    800046b0:	f44e                	sd	s3,40(sp)
    800046b2:	0880                	addi	s0,sp,80
    800046b4:	84aa                	mv	s1,a0
    800046b6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046b8:	ffffd097          	auipc	ra,0xffffd
    800046bc:	36e080e7          	jalr	878(ra) # 80001a26 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046c0:	409c                	lw	a5,0(s1)
    800046c2:	37f9                	addiw	a5,a5,-2
    800046c4:	4705                	li	a4,1
    800046c6:	04f76763          	bltu	a4,a5,80004714 <filestat+0x6e>
    800046ca:	892a                	mv	s2,a0
    ilock(f->ip);
    800046cc:	6c88                	ld	a0,24(s1)
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	07e080e7          	jalr	126(ra) # 8000374c <ilock>
    stati(f->ip, &st);
    800046d6:	fb840593          	addi	a1,s0,-72
    800046da:	6c88                	ld	a0,24(s1)
    800046dc:	fffff097          	auipc	ra,0xfffff
    800046e0:	2fa080e7          	jalr	762(ra) # 800039d6 <stati>
    iunlock(f->ip);
    800046e4:	6c88                	ld	a0,24(s1)
    800046e6:	fffff097          	auipc	ra,0xfffff
    800046ea:	128080e7          	jalr	296(ra) # 8000380e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046ee:	46e1                	li	a3,24
    800046f0:	fb840613          	addi	a2,s0,-72
    800046f4:	85ce                	mv	a1,s3
    800046f6:	05093503          	ld	a0,80(s2)
    800046fa:	ffffd097          	auipc	ra,0xffffd
    800046fe:	020080e7          	jalr	32(ra) # 8000171a <copyout>
    80004702:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004706:	60a6                	ld	ra,72(sp)
    80004708:	6406                	ld	s0,64(sp)
    8000470a:	74e2                	ld	s1,56(sp)
    8000470c:	7942                	ld	s2,48(sp)
    8000470e:	79a2                	ld	s3,40(sp)
    80004710:	6161                	addi	sp,sp,80
    80004712:	8082                	ret
  return -1;
    80004714:	557d                	li	a0,-1
    80004716:	bfc5                	j	80004706 <filestat+0x60>

0000000080004718 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004718:	7179                	addi	sp,sp,-48
    8000471a:	f406                	sd	ra,40(sp)
    8000471c:	f022                	sd	s0,32(sp)
    8000471e:	ec26                	sd	s1,24(sp)
    80004720:	e84a                	sd	s2,16(sp)
    80004722:	e44e                	sd	s3,8(sp)
    80004724:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004726:	00854783          	lbu	a5,8(a0)
    8000472a:	c3d5                	beqz	a5,800047ce <fileread+0xb6>
    8000472c:	84aa                	mv	s1,a0
    8000472e:	89ae                	mv	s3,a1
    80004730:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004732:	411c                	lw	a5,0(a0)
    80004734:	4705                	li	a4,1
    80004736:	04e78963          	beq	a5,a4,80004788 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000473a:	470d                	li	a4,3
    8000473c:	04e78d63          	beq	a5,a4,80004796 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004740:	4709                	li	a4,2
    80004742:	06e79e63          	bne	a5,a4,800047be <fileread+0xa6>
    ilock(f->ip);
    80004746:	6d08                	ld	a0,24(a0)
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	004080e7          	jalr	4(ra) # 8000374c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004750:	874a                	mv	a4,s2
    80004752:	5094                	lw	a3,32(s1)
    80004754:	864e                	mv	a2,s3
    80004756:	4585                	li	a1,1
    80004758:	6c88                	ld	a0,24(s1)
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	2a6080e7          	jalr	678(ra) # 80003a00 <readi>
    80004762:	892a                	mv	s2,a0
    80004764:	00a05563          	blez	a0,8000476e <fileread+0x56>
      f->off += r;
    80004768:	509c                	lw	a5,32(s1)
    8000476a:	9fa9                	addw	a5,a5,a0
    8000476c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000476e:	6c88                	ld	a0,24(s1)
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	09e080e7          	jalr	158(ra) # 8000380e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004778:	854a                	mv	a0,s2
    8000477a:	70a2                	ld	ra,40(sp)
    8000477c:	7402                	ld	s0,32(sp)
    8000477e:	64e2                	ld	s1,24(sp)
    80004780:	6942                	ld	s2,16(sp)
    80004782:	69a2                	ld	s3,8(sp)
    80004784:	6145                	addi	sp,sp,48
    80004786:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004788:	6908                	ld	a0,16(a0)
    8000478a:	00000097          	auipc	ra,0x0
    8000478e:	418080e7          	jalr	1048(ra) # 80004ba2 <piperead>
    80004792:	892a                	mv	s2,a0
    80004794:	b7d5                	j	80004778 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004796:	02451783          	lh	a5,36(a0)
    8000479a:	03079693          	slli	a3,a5,0x30
    8000479e:	92c1                	srli	a3,a3,0x30
    800047a0:	4725                	li	a4,9
    800047a2:	02d76863          	bltu	a4,a3,800047d2 <fileread+0xba>
    800047a6:	0792                	slli	a5,a5,0x4
    800047a8:	0001d717          	auipc	a4,0x1d
    800047ac:	20870713          	addi	a4,a4,520 # 800219b0 <devsw>
    800047b0:	97ba                	add	a5,a5,a4
    800047b2:	639c                	ld	a5,0(a5)
    800047b4:	c38d                	beqz	a5,800047d6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047b6:	4505                	li	a0,1
    800047b8:	9782                	jalr	a5
    800047ba:	892a                	mv	s2,a0
    800047bc:	bf75                	j	80004778 <fileread+0x60>
    panic("fileread");
    800047be:	00004517          	auipc	a0,0x4
    800047c2:	f0250513          	addi	a0,a0,-254 # 800086c0 <syscalls+0x258>
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	d82080e7          	jalr	-638(ra) # 80000548 <panic>
    return -1;
    800047ce:	597d                	li	s2,-1
    800047d0:	b765                	j	80004778 <fileread+0x60>
      return -1;
    800047d2:	597d                	li	s2,-1
    800047d4:	b755                	j	80004778 <fileread+0x60>
    800047d6:	597d                	li	s2,-1
    800047d8:	b745                	j	80004778 <fileread+0x60>

00000000800047da <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047da:	00954783          	lbu	a5,9(a0)
    800047de:	14078563          	beqz	a5,80004928 <filewrite+0x14e>
{
    800047e2:	715d                	addi	sp,sp,-80
    800047e4:	e486                	sd	ra,72(sp)
    800047e6:	e0a2                	sd	s0,64(sp)
    800047e8:	fc26                	sd	s1,56(sp)
    800047ea:	f84a                	sd	s2,48(sp)
    800047ec:	f44e                	sd	s3,40(sp)
    800047ee:	f052                	sd	s4,32(sp)
    800047f0:	ec56                	sd	s5,24(sp)
    800047f2:	e85a                	sd	s6,16(sp)
    800047f4:	e45e                	sd	s7,8(sp)
    800047f6:	e062                	sd	s8,0(sp)
    800047f8:	0880                	addi	s0,sp,80
    800047fa:	892a                	mv	s2,a0
    800047fc:	8aae                	mv	s5,a1
    800047fe:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004800:	411c                	lw	a5,0(a0)
    80004802:	4705                	li	a4,1
    80004804:	02e78263          	beq	a5,a4,80004828 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004808:	470d                	li	a4,3
    8000480a:	02e78563          	beq	a5,a4,80004834 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000480e:	4709                	li	a4,2
    80004810:	10e79463          	bne	a5,a4,80004918 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004814:	0ec05e63          	blez	a2,80004910 <filewrite+0x136>
    int i = 0;
    80004818:	4981                	li	s3,0
    8000481a:	6b05                	lui	s6,0x1
    8000481c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004820:	6b85                	lui	s7,0x1
    80004822:	c00b8b9b          	addiw	s7,s7,-1024
    80004826:	a851                	j	800048ba <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004828:	6908                	ld	a0,16(a0)
    8000482a:	00000097          	auipc	ra,0x0
    8000482e:	254080e7          	jalr	596(ra) # 80004a7e <pipewrite>
    80004832:	a85d                	j	800048e8 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004834:	02451783          	lh	a5,36(a0)
    80004838:	03079693          	slli	a3,a5,0x30
    8000483c:	92c1                	srli	a3,a3,0x30
    8000483e:	4725                	li	a4,9
    80004840:	0ed76663          	bltu	a4,a3,8000492c <filewrite+0x152>
    80004844:	0792                	slli	a5,a5,0x4
    80004846:	0001d717          	auipc	a4,0x1d
    8000484a:	16a70713          	addi	a4,a4,362 # 800219b0 <devsw>
    8000484e:	97ba                	add	a5,a5,a4
    80004850:	679c                	ld	a5,8(a5)
    80004852:	cff9                	beqz	a5,80004930 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004854:	4505                	li	a0,1
    80004856:	9782                	jalr	a5
    80004858:	a841                	j	800048e8 <filewrite+0x10e>
    8000485a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000485e:	00000097          	auipc	ra,0x0
    80004862:	8ae080e7          	jalr	-1874(ra) # 8000410c <begin_op>
      ilock(f->ip);
    80004866:	01893503          	ld	a0,24(s2)
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	ee2080e7          	jalr	-286(ra) # 8000374c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004872:	8762                	mv	a4,s8
    80004874:	02092683          	lw	a3,32(s2)
    80004878:	01598633          	add	a2,s3,s5
    8000487c:	4585                	li	a1,1
    8000487e:	01893503          	ld	a0,24(s2)
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	276080e7          	jalr	630(ra) # 80003af8 <writei>
    8000488a:	84aa                	mv	s1,a0
    8000488c:	02a05f63          	blez	a0,800048ca <filewrite+0xf0>
        f->off += r;
    80004890:	02092783          	lw	a5,32(s2)
    80004894:	9fa9                	addw	a5,a5,a0
    80004896:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000489a:	01893503          	ld	a0,24(s2)
    8000489e:	fffff097          	auipc	ra,0xfffff
    800048a2:	f70080e7          	jalr	-144(ra) # 8000380e <iunlock>
      end_op();
    800048a6:	00000097          	auipc	ra,0x0
    800048aa:	8e6080e7          	jalr	-1818(ra) # 8000418c <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800048ae:	049c1963          	bne	s8,s1,80004900 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800048b2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048b6:	0349d663          	bge	s3,s4,800048e2 <filewrite+0x108>
      int n1 = n - i;
    800048ba:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048be:	84be                	mv	s1,a5
    800048c0:	2781                	sext.w	a5,a5
    800048c2:	f8fb5ce3          	bge	s6,a5,8000485a <filewrite+0x80>
    800048c6:	84de                	mv	s1,s7
    800048c8:	bf49                	j	8000485a <filewrite+0x80>
      iunlock(f->ip);
    800048ca:	01893503          	ld	a0,24(s2)
    800048ce:	fffff097          	auipc	ra,0xfffff
    800048d2:	f40080e7          	jalr	-192(ra) # 8000380e <iunlock>
      end_op();
    800048d6:	00000097          	auipc	ra,0x0
    800048da:	8b6080e7          	jalr	-1866(ra) # 8000418c <end_op>
      if(r < 0)
    800048de:	fc04d8e3          	bgez	s1,800048ae <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800048e2:	8552                	mv	a0,s4
    800048e4:	033a1863          	bne	s4,s3,80004914 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048e8:	60a6                	ld	ra,72(sp)
    800048ea:	6406                	ld	s0,64(sp)
    800048ec:	74e2                	ld	s1,56(sp)
    800048ee:	7942                	ld	s2,48(sp)
    800048f0:	79a2                	ld	s3,40(sp)
    800048f2:	7a02                	ld	s4,32(sp)
    800048f4:	6ae2                	ld	s5,24(sp)
    800048f6:	6b42                	ld	s6,16(sp)
    800048f8:	6ba2                	ld	s7,8(sp)
    800048fa:	6c02                	ld	s8,0(sp)
    800048fc:	6161                	addi	sp,sp,80
    800048fe:	8082                	ret
        panic("short filewrite");
    80004900:	00004517          	auipc	a0,0x4
    80004904:	dd050513          	addi	a0,a0,-560 # 800086d0 <syscalls+0x268>
    80004908:	ffffc097          	auipc	ra,0xffffc
    8000490c:	c40080e7          	jalr	-960(ra) # 80000548 <panic>
    int i = 0;
    80004910:	4981                	li	s3,0
    80004912:	bfc1                	j	800048e2 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004914:	557d                	li	a0,-1
    80004916:	bfc9                	j	800048e8 <filewrite+0x10e>
    panic("filewrite");
    80004918:	00004517          	auipc	a0,0x4
    8000491c:	dc850513          	addi	a0,a0,-568 # 800086e0 <syscalls+0x278>
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	c28080e7          	jalr	-984(ra) # 80000548 <panic>
    return -1;
    80004928:	557d                	li	a0,-1
}
    8000492a:	8082                	ret
      return -1;
    8000492c:	557d                	li	a0,-1
    8000492e:	bf6d                	j	800048e8 <filewrite+0x10e>
    80004930:	557d                	li	a0,-1
    80004932:	bf5d                	j	800048e8 <filewrite+0x10e>

0000000080004934 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004934:	7179                	addi	sp,sp,-48
    80004936:	f406                	sd	ra,40(sp)
    80004938:	f022                	sd	s0,32(sp)
    8000493a:	ec26                	sd	s1,24(sp)
    8000493c:	e84a                	sd	s2,16(sp)
    8000493e:	e44e                	sd	s3,8(sp)
    80004940:	e052                	sd	s4,0(sp)
    80004942:	1800                	addi	s0,sp,48
    80004944:	84aa                	mv	s1,a0
    80004946:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004948:	0005b023          	sd	zero,0(a1)
    8000494c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004950:	00000097          	auipc	ra,0x0
    80004954:	bd2080e7          	jalr	-1070(ra) # 80004522 <filealloc>
    80004958:	e088                	sd	a0,0(s1)
    8000495a:	c551                	beqz	a0,800049e6 <pipealloc+0xb2>
    8000495c:	00000097          	auipc	ra,0x0
    80004960:	bc6080e7          	jalr	-1082(ra) # 80004522 <filealloc>
    80004964:	00aa3023          	sd	a0,0(s4)
    80004968:	c92d                	beqz	a0,800049da <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	1b6080e7          	jalr	438(ra) # 80000b20 <kalloc>
    80004972:	892a                	mv	s2,a0
    80004974:	c125                	beqz	a0,800049d4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004976:	4985                	li	s3,1
    80004978:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000497c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004980:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004984:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004988:	00004597          	auipc	a1,0x4
    8000498c:	d6858593          	addi	a1,a1,-664 # 800086f0 <syscalls+0x288>
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	1f0080e7          	jalr	496(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004998:	609c                	ld	a5,0(s1)
    8000499a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000499e:	609c                	ld	a5,0(s1)
    800049a0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049a4:	609c                	ld	a5,0(s1)
    800049a6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049aa:	609c                	ld	a5,0(s1)
    800049ac:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049b0:	000a3783          	ld	a5,0(s4)
    800049b4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049b8:	000a3783          	ld	a5,0(s4)
    800049bc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049c0:	000a3783          	ld	a5,0(s4)
    800049c4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049c8:	000a3783          	ld	a5,0(s4)
    800049cc:	0127b823          	sd	s2,16(a5)
  return 0;
    800049d0:	4501                	li	a0,0
    800049d2:	a025                	j	800049fa <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049d4:	6088                	ld	a0,0(s1)
    800049d6:	e501                	bnez	a0,800049de <pipealloc+0xaa>
    800049d8:	a039                	j	800049e6 <pipealloc+0xb2>
    800049da:	6088                	ld	a0,0(s1)
    800049dc:	c51d                	beqz	a0,80004a0a <pipealloc+0xd6>
    fileclose(*f0);
    800049de:	00000097          	auipc	ra,0x0
    800049e2:	c00080e7          	jalr	-1024(ra) # 800045de <fileclose>
  if(*f1)
    800049e6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049ea:	557d                	li	a0,-1
  if(*f1)
    800049ec:	c799                	beqz	a5,800049fa <pipealloc+0xc6>
    fileclose(*f1);
    800049ee:	853e                	mv	a0,a5
    800049f0:	00000097          	auipc	ra,0x0
    800049f4:	bee080e7          	jalr	-1042(ra) # 800045de <fileclose>
  return -1;
    800049f8:	557d                	li	a0,-1
}
    800049fa:	70a2                	ld	ra,40(sp)
    800049fc:	7402                	ld	s0,32(sp)
    800049fe:	64e2                	ld	s1,24(sp)
    80004a00:	6942                	ld	s2,16(sp)
    80004a02:	69a2                	ld	s3,8(sp)
    80004a04:	6a02                	ld	s4,0(sp)
    80004a06:	6145                	addi	sp,sp,48
    80004a08:	8082                	ret
  return -1;
    80004a0a:	557d                	li	a0,-1
    80004a0c:	b7fd                	j	800049fa <pipealloc+0xc6>

0000000080004a0e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a0e:	1101                	addi	sp,sp,-32
    80004a10:	ec06                	sd	ra,24(sp)
    80004a12:	e822                	sd	s0,16(sp)
    80004a14:	e426                	sd	s1,8(sp)
    80004a16:	e04a                	sd	s2,0(sp)
    80004a18:	1000                	addi	s0,sp,32
    80004a1a:	84aa                	mv	s1,a0
    80004a1c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	1f2080e7          	jalr	498(ra) # 80000c10 <acquire>
  if(writable){
    80004a26:	02090d63          	beqz	s2,80004a60 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a2a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a2e:	21848513          	addi	a0,s1,536
    80004a32:	ffffe097          	auipc	ra,0xffffe
    80004a36:	98a080e7          	jalr	-1654(ra) # 800023bc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a3a:	2204b783          	ld	a5,544(s1)
    80004a3e:	eb95                	bnez	a5,80004a72 <pipeclose+0x64>
    release(&pi->lock);
    80004a40:	8526                	mv	a0,s1
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	282080e7          	jalr	642(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004a4a:	8526                	mv	a0,s1
    80004a4c:	ffffc097          	auipc	ra,0xffffc
    80004a50:	fd8080e7          	jalr	-40(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004a54:	60e2                	ld	ra,24(sp)
    80004a56:	6442                	ld	s0,16(sp)
    80004a58:	64a2                	ld	s1,8(sp)
    80004a5a:	6902                	ld	s2,0(sp)
    80004a5c:	6105                	addi	sp,sp,32
    80004a5e:	8082                	ret
    pi->readopen = 0;
    80004a60:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a64:	21c48513          	addi	a0,s1,540
    80004a68:	ffffe097          	auipc	ra,0xffffe
    80004a6c:	954080e7          	jalr	-1708(ra) # 800023bc <wakeup>
    80004a70:	b7e9                	j	80004a3a <pipeclose+0x2c>
    release(&pi->lock);
    80004a72:	8526                	mv	a0,s1
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	250080e7          	jalr	592(ra) # 80000cc4 <release>
}
    80004a7c:	bfe1                	j	80004a54 <pipeclose+0x46>

0000000080004a7e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a7e:	7119                	addi	sp,sp,-128
    80004a80:	fc86                	sd	ra,120(sp)
    80004a82:	f8a2                	sd	s0,112(sp)
    80004a84:	f4a6                	sd	s1,104(sp)
    80004a86:	f0ca                	sd	s2,96(sp)
    80004a88:	ecce                	sd	s3,88(sp)
    80004a8a:	e8d2                	sd	s4,80(sp)
    80004a8c:	e4d6                	sd	s5,72(sp)
    80004a8e:	e0da                	sd	s6,64(sp)
    80004a90:	fc5e                	sd	s7,56(sp)
    80004a92:	f862                	sd	s8,48(sp)
    80004a94:	f466                	sd	s9,40(sp)
    80004a96:	f06a                	sd	s10,32(sp)
    80004a98:	ec6e                	sd	s11,24(sp)
    80004a9a:	0100                	addi	s0,sp,128
    80004a9c:	84aa                	mv	s1,a0
    80004a9e:	8cae                	mv	s9,a1
    80004aa0:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004aa2:	ffffd097          	auipc	ra,0xffffd
    80004aa6:	f84080e7          	jalr	-124(ra) # 80001a26 <myproc>
    80004aaa:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004aac:	8526                	mv	a0,s1
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	162080e7          	jalr	354(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004ab6:	0d605963          	blez	s6,80004b88 <pipewrite+0x10a>
    80004aba:	89a6                	mv	s3,s1
    80004abc:	3b7d                	addiw	s6,s6,-1
    80004abe:	1b02                	slli	s6,s6,0x20
    80004ac0:	020b5b13          	srli	s6,s6,0x20
    80004ac4:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ac6:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004aca:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ace:	5dfd                	li	s11,-1
    80004ad0:	000b8d1b          	sext.w	s10,s7
    80004ad4:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ad6:	2184a783          	lw	a5,536(s1)
    80004ada:	21c4a703          	lw	a4,540(s1)
    80004ade:	2007879b          	addiw	a5,a5,512
    80004ae2:	02f71b63          	bne	a4,a5,80004b18 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004ae6:	2204a783          	lw	a5,544(s1)
    80004aea:	cbad                	beqz	a5,80004b5c <pipewrite+0xde>
    80004aec:	03092783          	lw	a5,48(s2)
    80004af0:	e7b5                	bnez	a5,80004b5c <pipewrite+0xde>
      wakeup(&pi->nread);
    80004af2:	8556                	mv	a0,s5
    80004af4:	ffffe097          	auipc	ra,0xffffe
    80004af8:	8c8080e7          	jalr	-1848(ra) # 800023bc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004afc:	85ce                	mv	a1,s3
    80004afe:	8552                	mv	a0,s4
    80004b00:	ffffd097          	auipc	ra,0xffffd
    80004b04:	736080e7          	jalr	1846(ra) # 80002236 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b08:	2184a783          	lw	a5,536(s1)
    80004b0c:	21c4a703          	lw	a4,540(s1)
    80004b10:	2007879b          	addiw	a5,a5,512
    80004b14:	fcf709e3          	beq	a4,a5,80004ae6 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b18:	4685                	li	a3,1
    80004b1a:	019b8633          	add	a2,s7,s9
    80004b1e:	f8f40593          	addi	a1,s0,-113
    80004b22:	05093503          	ld	a0,80(s2)
    80004b26:	ffffd097          	auipc	ra,0xffffd
    80004b2a:	c80080e7          	jalr	-896(ra) # 800017a6 <copyin>
    80004b2e:	05b50e63          	beq	a0,s11,80004b8a <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b32:	21c4a783          	lw	a5,540(s1)
    80004b36:	0017871b          	addiw	a4,a5,1
    80004b3a:	20e4ae23          	sw	a4,540(s1)
    80004b3e:	1ff7f793          	andi	a5,a5,511
    80004b42:	97a6                	add	a5,a5,s1
    80004b44:	f8f44703          	lbu	a4,-113(s0)
    80004b48:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b4c:	001d0c1b          	addiw	s8,s10,1
    80004b50:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b54:	036b8b63          	beq	s7,s6,80004b8a <pipewrite+0x10c>
    80004b58:	8bbe                	mv	s7,a5
    80004b5a:	bf9d                	j	80004ad0 <pipewrite+0x52>
        release(&pi->lock);
    80004b5c:	8526                	mv	a0,s1
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	166080e7          	jalr	358(ra) # 80000cc4 <release>
        return -1;
    80004b66:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b68:	8562                	mv	a0,s8
    80004b6a:	70e6                	ld	ra,120(sp)
    80004b6c:	7446                	ld	s0,112(sp)
    80004b6e:	74a6                	ld	s1,104(sp)
    80004b70:	7906                	ld	s2,96(sp)
    80004b72:	69e6                	ld	s3,88(sp)
    80004b74:	6a46                	ld	s4,80(sp)
    80004b76:	6aa6                	ld	s5,72(sp)
    80004b78:	6b06                	ld	s6,64(sp)
    80004b7a:	7be2                	ld	s7,56(sp)
    80004b7c:	7c42                	ld	s8,48(sp)
    80004b7e:	7ca2                	ld	s9,40(sp)
    80004b80:	7d02                	ld	s10,32(sp)
    80004b82:	6de2                	ld	s11,24(sp)
    80004b84:	6109                	addi	sp,sp,128
    80004b86:	8082                	ret
  for(i = 0; i < n; i++){
    80004b88:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004b8a:	21848513          	addi	a0,s1,536
    80004b8e:	ffffe097          	auipc	ra,0xffffe
    80004b92:	82e080e7          	jalr	-2002(ra) # 800023bc <wakeup>
  release(&pi->lock);
    80004b96:	8526                	mv	a0,s1
    80004b98:	ffffc097          	auipc	ra,0xffffc
    80004b9c:	12c080e7          	jalr	300(ra) # 80000cc4 <release>
  return i;
    80004ba0:	b7e1                	j	80004b68 <pipewrite+0xea>

0000000080004ba2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ba2:	715d                	addi	sp,sp,-80
    80004ba4:	e486                	sd	ra,72(sp)
    80004ba6:	e0a2                	sd	s0,64(sp)
    80004ba8:	fc26                	sd	s1,56(sp)
    80004baa:	f84a                	sd	s2,48(sp)
    80004bac:	f44e                	sd	s3,40(sp)
    80004bae:	f052                	sd	s4,32(sp)
    80004bb0:	ec56                	sd	s5,24(sp)
    80004bb2:	e85a                	sd	s6,16(sp)
    80004bb4:	0880                	addi	s0,sp,80
    80004bb6:	84aa                	mv	s1,a0
    80004bb8:	892e                	mv	s2,a1
    80004bba:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	e6a080e7          	jalr	-406(ra) # 80001a26 <myproc>
    80004bc4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bc6:	8b26                	mv	s6,s1
    80004bc8:	8526                	mv	a0,s1
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	046080e7          	jalr	70(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bd2:	2184a703          	lw	a4,536(s1)
    80004bd6:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bda:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bde:	02f71463          	bne	a4,a5,80004c06 <piperead+0x64>
    80004be2:	2244a783          	lw	a5,548(s1)
    80004be6:	c385                	beqz	a5,80004c06 <piperead+0x64>
    if(pr->killed){
    80004be8:	030a2783          	lw	a5,48(s4)
    80004bec:	ebc1                	bnez	a5,80004c7c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bee:	85da                	mv	a1,s6
    80004bf0:	854e                	mv	a0,s3
    80004bf2:	ffffd097          	auipc	ra,0xffffd
    80004bf6:	644080e7          	jalr	1604(ra) # 80002236 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bfa:	2184a703          	lw	a4,536(s1)
    80004bfe:	21c4a783          	lw	a5,540(s1)
    80004c02:	fef700e3          	beq	a4,a5,80004be2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c06:	09505263          	blez	s5,80004c8a <piperead+0xe8>
    80004c0a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c0c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c0e:	2184a783          	lw	a5,536(s1)
    80004c12:	21c4a703          	lw	a4,540(s1)
    80004c16:	02f70d63          	beq	a4,a5,80004c50 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c1a:	0017871b          	addiw	a4,a5,1
    80004c1e:	20e4ac23          	sw	a4,536(s1)
    80004c22:	1ff7f793          	andi	a5,a5,511
    80004c26:	97a6                	add	a5,a5,s1
    80004c28:	0187c783          	lbu	a5,24(a5)
    80004c2c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c30:	4685                	li	a3,1
    80004c32:	fbf40613          	addi	a2,s0,-65
    80004c36:	85ca                	mv	a1,s2
    80004c38:	050a3503          	ld	a0,80(s4)
    80004c3c:	ffffd097          	auipc	ra,0xffffd
    80004c40:	ade080e7          	jalr	-1314(ra) # 8000171a <copyout>
    80004c44:	01650663          	beq	a0,s6,80004c50 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c48:	2985                	addiw	s3,s3,1
    80004c4a:	0905                	addi	s2,s2,1
    80004c4c:	fd3a91e3          	bne	s5,s3,80004c0e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c50:	21c48513          	addi	a0,s1,540
    80004c54:	ffffd097          	auipc	ra,0xffffd
    80004c58:	768080e7          	jalr	1896(ra) # 800023bc <wakeup>
  release(&pi->lock);
    80004c5c:	8526                	mv	a0,s1
    80004c5e:	ffffc097          	auipc	ra,0xffffc
    80004c62:	066080e7          	jalr	102(ra) # 80000cc4 <release>
  return i;
}
    80004c66:	854e                	mv	a0,s3
    80004c68:	60a6                	ld	ra,72(sp)
    80004c6a:	6406                	ld	s0,64(sp)
    80004c6c:	74e2                	ld	s1,56(sp)
    80004c6e:	7942                	ld	s2,48(sp)
    80004c70:	79a2                	ld	s3,40(sp)
    80004c72:	7a02                	ld	s4,32(sp)
    80004c74:	6ae2                	ld	s5,24(sp)
    80004c76:	6b42                	ld	s6,16(sp)
    80004c78:	6161                	addi	sp,sp,80
    80004c7a:	8082                	ret
      release(&pi->lock);
    80004c7c:	8526                	mv	a0,s1
    80004c7e:	ffffc097          	auipc	ra,0xffffc
    80004c82:	046080e7          	jalr	70(ra) # 80000cc4 <release>
      return -1;
    80004c86:	59fd                	li	s3,-1
    80004c88:	bff9                	j	80004c66 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c8a:	4981                	li	s3,0
    80004c8c:	b7d1                	j	80004c50 <piperead+0xae>

0000000080004c8e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c8e:	df010113          	addi	sp,sp,-528
    80004c92:	20113423          	sd	ra,520(sp)
    80004c96:	20813023          	sd	s0,512(sp)
    80004c9a:	ffa6                	sd	s1,504(sp)
    80004c9c:	fbca                	sd	s2,496(sp)
    80004c9e:	f7ce                	sd	s3,488(sp)
    80004ca0:	f3d2                	sd	s4,480(sp)
    80004ca2:	efd6                	sd	s5,472(sp)
    80004ca4:	ebda                	sd	s6,464(sp)
    80004ca6:	e7de                	sd	s7,456(sp)
    80004ca8:	e3e2                	sd	s8,448(sp)
    80004caa:	ff66                	sd	s9,440(sp)
    80004cac:	fb6a                	sd	s10,432(sp)
    80004cae:	f76e                	sd	s11,424(sp)
    80004cb0:	0c00                	addi	s0,sp,528
    80004cb2:	84aa                	mv	s1,a0
    80004cb4:	dea43c23          	sd	a0,-520(s0)
    80004cb8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cbc:	ffffd097          	auipc	ra,0xffffd
    80004cc0:	d6a080e7          	jalr	-662(ra) # 80001a26 <myproc>
    80004cc4:	892a                	mv	s2,a0

  begin_op();
    80004cc6:	fffff097          	auipc	ra,0xfffff
    80004cca:	446080e7          	jalr	1094(ra) # 8000410c <begin_op>

  if((ip = namei(path)) == 0){
    80004cce:	8526                	mv	a0,s1
    80004cd0:	fffff097          	auipc	ra,0xfffff
    80004cd4:	230080e7          	jalr	560(ra) # 80003f00 <namei>
    80004cd8:	c92d                	beqz	a0,80004d4a <exec+0xbc>
    80004cda:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cdc:	fffff097          	auipc	ra,0xfffff
    80004ce0:	a70080e7          	jalr	-1424(ra) # 8000374c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ce4:	04000713          	li	a4,64
    80004ce8:	4681                	li	a3,0
    80004cea:	e4840613          	addi	a2,s0,-440
    80004cee:	4581                	li	a1,0
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	d0e080e7          	jalr	-754(ra) # 80003a00 <readi>
    80004cfa:	04000793          	li	a5,64
    80004cfe:	00f51a63          	bne	a0,a5,80004d12 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d02:	e4842703          	lw	a4,-440(s0)
    80004d06:	464c47b7          	lui	a5,0x464c4
    80004d0a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d0e:	04f70463          	beq	a4,a5,80004d56 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d12:	8526                	mv	a0,s1
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	c9a080e7          	jalr	-870(ra) # 800039ae <iunlockput>
    end_op();
    80004d1c:	fffff097          	auipc	ra,0xfffff
    80004d20:	470080e7          	jalr	1136(ra) # 8000418c <end_op>
  }
  return -1;
    80004d24:	557d                	li	a0,-1
}
    80004d26:	20813083          	ld	ra,520(sp)
    80004d2a:	20013403          	ld	s0,512(sp)
    80004d2e:	74fe                	ld	s1,504(sp)
    80004d30:	795e                	ld	s2,496(sp)
    80004d32:	79be                	ld	s3,488(sp)
    80004d34:	7a1e                	ld	s4,480(sp)
    80004d36:	6afe                	ld	s5,472(sp)
    80004d38:	6b5e                	ld	s6,464(sp)
    80004d3a:	6bbe                	ld	s7,456(sp)
    80004d3c:	6c1e                	ld	s8,448(sp)
    80004d3e:	7cfa                	ld	s9,440(sp)
    80004d40:	7d5a                	ld	s10,432(sp)
    80004d42:	7dba                	ld	s11,424(sp)
    80004d44:	21010113          	addi	sp,sp,528
    80004d48:	8082                	ret
    end_op();
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	442080e7          	jalr	1090(ra) # 8000418c <end_op>
    return -1;
    80004d52:	557d                	li	a0,-1
    80004d54:	bfc9                	j	80004d26 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d56:	854a                	mv	a0,s2
    80004d58:	ffffd097          	auipc	ra,0xffffd
    80004d5c:	d92080e7          	jalr	-622(ra) # 80001aea <proc_pagetable>
    80004d60:	8baa                	mv	s7,a0
    80004d62:	d945                	beqz	a0,80004d12 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d64:	e6842983          	lw	s3,-408(s0)
    80004d68:	e8045783          	lhu	a5,-384(s0)
    80004d6c:	c7ad                	beqz	a5,80004dd6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d6e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d70:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d72:	6c85                	lui	s9,0x1
    80004d74:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d78:	def43823          	sd	a5,-528(s0)
    80004d7c:	a42d                	j	80004fa6 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d7e:	00004517          	auipc	a0,0x4
    80004d82:	97a50513          	addi	a0,a0,-1670 # 800086f8 <syscalls+0x290>
    80004d86:	ffffb097          	auipc	ra,0xffffb
    80004d8a:	7c2080e7          	jalr	1986(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d8e:	8756                	mv	a4,s5
    80004d90:	012d86bb          	addw	a3,s11,s2
    80004d94:	4581                	li	a1,0
    80004d96:	8526                	mv	a0,s1
    80004d98:	fffff097          	auipc	ra,0xfffff
    80004d9c:	c68080e7          	jalr	-920(ra) # 80003a00 <readi>
    80004da0:	2501                	sext.w	a0,a0
    80004da2:	1aaa9963          	bne	s5,a0,80004f54 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004da6:	6785                	lui	a5,0x1
    80004da8:	0127893b          	addw	s2,a5,s2
    80004dac:	77fd                	lui	a5,0xfffff
    80004dae:	01478a3b          	addw	s4,a5,s4
    80004db2:	1f897163          	bgeu	s2,s8,80004f94 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004db6:	02091593          	slli	a1,s2,0x20
    80004dba:	9181                	srli	a1,a1,0x20
    80004dbc:	95ea                	add	a1,a1,s10
    80004dbe:	855e                	mv	a0,s7
    80004dc0:	ffffc097          	auipc	ra,0xffffc
    80004dc4:	3ca080e7          	jalr	970(ra) # 8000118a <walkaddr>
    80004dc8:	862a                	mv	a2,a0
    if(pa == 0)
    80004dca:	d955                	beqz	a0,80004d7e <exec+0xf0>
      n = PGSIZE;
    80004dcc:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004dce:	fd9a70e3          	bgeu	s4,s9,80004d8e <exec+0x100>
      n = sz - i;
    80004dd2:	8ad2                	mv	s5,s4
    80004dd4:	bf6d                	j	80004d8e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dd6:	4901                	li	s2,0
  iunlockput(ip);
    80004dd8:	8526                	mv	a0,s1
    80004dda:	fffff097          	auipc	ra,0xfffff
    80004dde:	bd4080e7          	jalr	-1068(ra) # 800039ae <iunlockput>
  end_op();
    80004de2:	fffff097          	auipc	ra,0xfffff
    80004de6:	3aa080e7          	jalr	938(ra) # 8000418c <end_op>
  p = myproc();
    80004dea:	ffffd097          	auipc	ra,0xffffd
    80004dee:	c3c080e7          	jalr	-964(ra) # 80001a26 <myproc>
    80004df2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004df4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004df8:	6785                	lui	a5,0x1
    80004dfa:	17fd                	addi	a5,a5,-1
    80004dfc:	993e                	add	s2,s2,a5
    80004dfe:	757d                	lui	a0,0xfffff
    80004e00:	00a977b3          	and	a5,s2,a0
    80004e04:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e08:	6609                	lui	a2,0x2
    80004e0a:	963e                	add	a2,a2,a5
    80004e0c:	85be                	mv	a1,a5
    80004e0e:	855e                	mv	a0,s7
    80004e10:	ffffc097          	auipc	ra,0xffffc
    80004e14:	6d6080e7          	jalr	1750(ra) # 800014e6 <uvmalloc>
    80004e18:	8b2a                	mv	s6,a0
  ip = 0;
    80004e1a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e1c:	12050c63          	beqz	a0,80004f54 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e20:	75f9                	lui	a1,0xffffe
    80004e22:	95aa                	add	a1,a1,a0
    80004e24:	855e                	mv	a0,s7
    80004e26:	ffffd097          	auipc	ra,0xffffd
    80004e2a:	8c2080e7          	jalr	-1854(ra) # 800016e8 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e2e:	7c7d                	lui	s8,0xfffff
    80004e30:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e32:	e0043783          	ld	a5,-512(s0)
    80004e36:	6388                	ld	a0,0(a5)
    80004e38:	c535                	beqz	a0,80004ea4 <exec+0x216>
    80004e3a:	e8840993          	addi	s3,s0,-376
    80004e3e:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e42:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	050080e7          	jalr	80(ra) # 80000e94 <strlen>
    80004e4c:	2505                	addiw	a0,a0,1
    80004e4e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e52:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e56:	13896363          	bltu	s2,s8,80004f7c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e5a:	e0043d83          	ld	s11,-512(s0)
    80004e5e:	000dba03          	ld	s4,0(s11)
    80004e62:	8552                	mv	a0,s4
    80004e64:	ffffc097          	auipc	ra,0xffffc
    80004e68:	030080e7          	jalr	48(ra) # 80000e94 <strlen>
    80004e6c:	0015069b          	addiw	a3,a0,1
    80004e70:	8652                	mv	a2,s4
    80004e72:	85ca                	mv	a1,s2
    80004e74:	855e                	mv	a0,s7
    80004e76:	ffffd097          	auipc	ra,0xffffd
    80004e7a:	8a4080e7          	jalr	-1884(ra) # 8000171a <copyout>
    80004e7e:	10054363          	bltz	a0,80004f84 <exec+0x2f6>
    ustack[argc] = sp;
    80004e82:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e86:	0485                	addi	s1,s1,1
    80004e88:	008d8793          	addi	a5,s11,8
    80004e8c:	e0f43023          	sd	a5,-512(s0)
    80004e90:	008db503          	ld	a0,8(s11)
    80004e94:	c911                	beqz	a0,80004ea8 <exec+0x21a>
    if(argc >= MAXARG)
    80004e96:	09a1                	addi	s3,s3,8
    80004e98:	fb3c96e3          	bne	s9,s3,80004e44 <exec+0x1b6>
  sz = sz1;
    80004e9c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ea0:	4481                	li	s1,0
    80004ea2:	a84d                	j	80004f54 <exec+0x2c6>
  sp = sz;
    80004ea4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ea6:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ea8:	00349793          	slli	a5,s1,0x3
    80004eac:	f9040713          	addi	a4,s0,-112
    80004eb0:	97ba                	add	a5,a5,a4
    80004eb2:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004eb6:	00148693          	addi	a3,s1,1
    80004eba:	068e                	slli	a3,a3,0x3
    80004ebc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ec0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ec4:	01897663          	bgeu	s2,s8,80004ed0 <exec+0x242>
  sz = sz1;
    80004ec8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ecc:	4481                	li	s1,0
    80004ece:	a059                	j	80004f54 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ed0:	e8840613          	addi	a2,s0,-376
    80004ed4:	85ca                	mv	a1,s2
    80004ed6:	855e                	mv	a0,s7
    80004ed8:	ffffd097          	auipc	ra,0xffffd
    80004edc:	842080e7          	jalr	-1982(ra) # 8000171a <copyout>
    80004ee0:	0a054663          	bltz	a0,80004f8c <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004ee4:	058ab783          	ld	a5,88(s5)
    80004ee8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004eec:	df843783          	ld	a5,-520(s0)
    80004ef0:	0007c703          	lbu	a4,0(a5)
    80004ef4:	cf11                	beqz	a4,80004f10 <exec+0x282>
    80004ef6:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ef8:	02f00693          	li	a3,47
    80004efc:	a029                	j	80004f06 <exec+0x278>
  for(last=s=path; *s; s++)
    80004efe:	0785                	addi	a5,a5,1
    80004f00:	fff7c703          	lbu	a4,-1(a5)
    80004f04:	c711                	beqz	a4,80004f10 <exec+0x282>
    if(*s == '/')
    80004f06:	fed71ce3          	bne	a4,a3,80004efe <exec+0x270>
      last = s+1;
    80004f0a:	def43c23          	sd	a5,-520(s0)
    80004f0e:	bfc5                	j	80004efe <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f10:	4641                	li	a2,16
    80004f12:	df843583          	ld	a1,-520(s0)
    80004f16:	158a8513          	addi	a0,s5,344
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	f48080e7          	jalr	-184(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f22:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f26:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f2a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f2e:	058ab783          	ld	a5,88(s5)
    80004f32:	e6043703          	ld	a4,-416(s0)
    80004f36:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f38:	058ab783          	ld	a5,88(s5)
    80004f3c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f40:	85ea                	mv	a1,s10
    80004f42:	ffffd097          	auipc	ra,0xffffd
    80004f46:	c44080e7          	jalr	-956(ra) # 80001b86 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f4a:	0004851b          	sext.w	a0,s1
    80004f4e:	bbe1                	j	80004d26 <exec+0x98>
    80004f50:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f54:	e0843583          	ld	a1,-504(s0)
    80004f58:	855e                	mv	a0,s7
    80004f5a:	ffffd097          	auipc	ra,0xffffd
    80004f5e:	c2c080e7          	jalr	-980(ra) # 80001b86 <proc_freepagetable>
  if(ip){
    80004f62:	da0498e3          	bnez	s1,80004d12 <exec+0x84>
  return -1;
    80004f66:	557d                	li	a0,-1
    80004f68:	bb7d                	j	80004d26 <exec+0x98>
    80004f6a:	e1243423          	sd	s2,-504(s0)
    80004f6e:	b7dd                	j	80004f54 <exec+0x2c6>
    80004f70:	e1243423          	sd	s2,-504(s0)
    80004f74:	b7c5                	j	80004f54 <exec+0x2c6>
    80004f76:	e1243423          	sd	s2,-504(s0)
    80004f7a:	bfe9                	j	80004f54 <exec+0x2c6>
  sz = sz1;
    80004f7c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f80:	4481                	li	s1,0
    80004f82:	bfc9                	j	80004f54 <exec+0x2c6>
  sz = sz1;
    80004f84:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f88:	4481                	li	s1,0
    80004f8a:	b7e9                	j	80004f54 <exec+0x2c6>
  sz = sz1;
    80004f8c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f90:	4481                	li	s1,0
    80004f92:	b7c9                	j	80004f54 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f94:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f98:	2b05                	addiw	s6,s6,1
    80004f9a:	0389899b          	addiw	s3,s3,56
    80004f9e:	e8045783          	lhu	a5,-384(s0)
    80004fa2:	e2fb5be3          	bge	s6,a5,80004dd8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fa6:	2981                	sext.w	s3,s3
    80004fa8:	03800713          	li	a4,56
    80004fac:	86ce                	mv	a3,s3
    80004fae:	e1040613          	addi	a2,s0,-496
    80004fb2:	4581                	li	a1,0
    80004fb4:	8526                	mv	a0,s1
    80004fb6:	fffff097          	auipc	ra,0xfffff
    80004fba:	a4a080e7          	jalr	-1462(ra) # 80003a00 <readi>
    80004fbe:	03800793          	li	a5,56
    80004fc2:	f8f517e3          	bne	a0,a5,80004f50 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fc6:	e1042783          	lw	a5,-496(s0)
    80004fca:	4705                	li	a4,1
    80004fcc:	fce796e3          	bne	a5,a4,80004f98 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004fd0:	e3843603          	ld	a2,-456(s0)
    80004fd4:	e3043783          	ld	a5,-464(s0)
    80004fd8:	f8f669e3          	bltu	a2,a5,80004f6a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fdc:	e2043783          	ld	a5,-480(s0)
    80004fe0:	963e                	add	a2,a2,a5
    80004fe2:	f8f667e3          	bltu	a2,a5,80004f70 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fe6:	85ca                	mv	a1,s2
    80004fe8:	855e                	mv	a0,s7
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	4fc080e7          	jalr	1276(ra) # 800014e6 <uvmalloc>
    80004ff2:	e0a43423          	sd	a0,-504(s0)
    80004ff6:	d141                	beqz	a0,80004f76 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004ff8:	e2043d03          	ld	s10,-480(s0)
    80004ffc:	df043783          	ld	a5,-528(s0)
    80005000:	00fd77b3          	and	a5,s10,a5
    80005004:	fba1                	bnez	a5,80004f54 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005006:	e1842d83          	lw	s11,-488(s0)
    8000500a:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000500e:	f80c03e3          	beqz	s8,80004f94 <exec+0x306>
    80005012:	8a62                	mv	s4,s8
    80005014:	4901                	li	s2,0
    80005016:	b345                	j	80004db6 <exec+0x128>

0000000080005018 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005018:	7179                	addi	sp,sp,-48
    8000501a:	f406                	sd	ra,40(sp)
    8000501c:	f022                	sd	s0,32(sp)
    8000501e:	ec26                	sd	s1,24(sp)
    80005020:	e84a                	sd	s2,16(sp)
    80005022:	1800                	addi	s0,sp,48
    80005024:	892e                	mv	s2,a1
    80005026:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005028:	fdc40593          	addi	a1,s0,-36
    8000502c:	ffffe097          	auipc	ra,0xffffe
    80005030:	b84080e7          	jalr	-1148(ra) # 80002bb0 <argint>
    80005034:	04054063          	bltz	a0,80005074 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005038:	fdc42703          	lw	a4,-36(s0)
    8000503c:	47bd                	li	a5,15
    8000503e:	02e7ed63          	bltu	a5,a4,80005078 <argfd+0x60>
    80005042:	ffffd097          	auipc	ra,0xffffd
    80005046:	9e4080e7          	jalr	-1564(ra) # 80001a26 <myproc>
    8000504a:	fdc42703          	lw	a4,-36(s0)
    8000504e:	01a70793          	addi	a5,a4,26
    80005052:	078e                	slli	a5,a5,0x3
    80005054:	953e                	add	a0,a0,a5
    80005056:	611c                	ld	a5,0(a0)
    80005058:	c395                	beqz	a5,8000507c <argfd+0x64>
    return -1;
  if(pfd)
    8000505a:	00090463          	beqz	s2,80005062 <argfd+0x4a>
    *pfd = fd;
    8000505e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005062:	4501                	li	a0,0
  if(pf)
    80005064:	c091                	beqz	s1,80005068 <argfd+0x50>
    *pf = f;
    80005066:	e09c                	sd	a5,0(s1)
}
    80005068:	70a2                	ld	ra,40(sp)
    8000506a:	7402                	ld	s0,32(sp)
    8000506c:	64e2                	ld	s1,24(sp)
    8000506e:	6942                	ld	s2,16(sp)
    80005070:	6145                	addi	sp,sp,48
    80005072:	8082                	ret
    return -1;
    80005074:	557d                	li	a0,-1
    80005076:	bfcd                	j	80005068 <argfd+0x50>
    return -1;
    80005078:	557d                	li	a0,-1
    8000507a:	b7fd                	j	80005068 <argfd+0x50>
    8000507c:	557d                	li	a0,-1
    8000507e:	b7ed                	j	80005068 <argfd+0x50>

0000000080005080 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005080:	1101                	addi	sp,sp,-32
    80005082:	ec06                	sd	ra,24(sp)
    80005084:	e822                	sd	s0,16(sp)
    80005086:	e426                	sd	s1,8(sp)
    80005088:	1000                	addi	s0,sp,32
    8000508a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000508c:	ffffd097          	auipc	ra,0xffffd
    80005090:	99a080e7          	jalr	-1638(ra) # 80001a26 <myproc>
    80005094:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005096:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000509a:	4501                	li	a0,0
    8000509c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000509e:	6398                	ld	a4,0(a5)
    800050a0:	cb19                	beqz	a4,800050b6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050a2:	2505                	addiw	a0,a0,1
    800050a4:	07a1                	addi	a5,a5,8
    800050a6:	fed51ce3          	bne	a0,a3,8000509e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050aa:	557d                	li	a0,-1
}
    800050ac:	60e2                	ld	ra,24(sp)
    800050ae:	6442                	ld	s0,16(sp)
    800050b0:	64a2                	ld	s1,8(sp)
    800050b2:	6105                	addi	sp,sp,32
    800050b4:	8082                	ret
      p->ofile[fd] = f;
    800050b6:	01a50793          	addi	a5,a0,26
    800050ba:	078e                	slli	a5,a5,0x3
    800050bc:	963e                	add	a2,a2,a5
    800050be:	e204                	sd	s1,0(a2)
      return fd;
    800050c0:	b7f5                	j	800050ac <fdalloc+0x2c>

00000000800050c2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050c2:	715d                	addi	sp,sp,-80
    800050c4:	e486                	sd	ra,72(sp)
    800050c6:	e0a2                	sd	s0,64(sp)
    800050c8:	fc26                	sd	s1,56(sp)
    800050ca:	f84a                	sd	s2,48(sp)
    800050cc:	f44e                	sd	s3,40(sp)
    800050ce:	f052                	sd	s4,32(sp)
    800050d0:	ec56                	sd	s5,24(sp)
    800050d2:	0880                	addi	s0,sp,80
    800050d4:	89ae                	mv	s3,a1
    800050d6:	8ab2                	mv	s5,a2
    800050d8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050da:	fb040593          	addi	a1,s0,-80
    800050de:	fffff097          	auipc	ra,0xfffff
    800050e2:	e40080e7          	jalr	-448(ra) # 80003f1e <nameiparent>
    800050e6:	892a                	mv	s2,a0
    800050e8:	12050f63          	beqz	a0,80005226 <create+0x164>
    return 0;

  ilock(dp);
    800050ec:	ffffe097          	auipc	ra,0xffffe
    800050f0:	660080e7          	jalr	1632(ra) # 8000374c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050f4:	4601                	li	a2,0
    800050f6:	fb040593          	addi	a1,s0,-80
    800050fa:	854a                	mv	a0,s2
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	b32080e7          	jalr	-1230(ra) # 80003c2e <dirlookup>
    80005104:	84aa                	mv	s1,a0
    80005106:	c921                	beqz	a0,80005156 <create+0x94>
    iunlockput(dp);
    80005108:	854a                	mv	a0,s2
    8000510a:	fffff097          	auipc	ra,0xfffff
    8000510e:	8a4080e7          	jalr	-1884(ra) # 800039ae <iunlockput>
    ilock(ip);
    80005112:	8526                	mv	a0,s1
    80005114:	ffffe097          	auipc	ra,0xffffe
    80005118:	638080e7          	jalr	1592(ra) # 8000374c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000511c:	2981                	sext.w	s3,s3
    8000511e:	4789                	li	a5,2
    80005120:	02f99463          	bne	s3,a5,80005148 <create+0x86>
    80005124:	0444d783          	lhu	a5,68(s1)
    80005128:	37f9                	addiw	a5,a5,-2
    8000512a:	17c2                	slli	a5,a5,0x30
    8000512c:	93c1                	srli	a5,a5,0x30
    8000512e:	4705                	li	a4,1
    80005130:	00f76c63          	bltu	a4,a5,80005148 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005134:	8526                	mv	a0,s1
    80005136:	60a6                	ld	ra,72(sp)
    80005138:	6406                	ld	s0,64(sp)
    8000513a:	74e2                	ld	s1,56(sp)
    8000513c:	7942                	ld	s2,48(sp)
    8000513e:	79a2                	ld	s3,40(sp)
    80005140:	7a02                	ld	s4,32(sp)
    80005142:	6ae2                	ld	s5,24(sp)
    80005144:	6161                	addi	sp,sp,80
    80005146:	8082                	ret
    iunlockput(ip);
    80005148:	8526                	mv	a0,s1
    8000514a:	fffff097          	auipc	ra,0xfffff
    8000514e:	864080e7          	jalr	-1948(ra) # 800039ae <iunlockput>
    return 0;
    80005152:	4481                	li	s1,0
    80005154:	b7c5                	j	80005134 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005156:	85ce                	mv	a1,s3
    80005158:	00092503          	lw	a0,0(s2)
    8000515c:	ffffe097          	auipc	ra,0xffffe
    80005160:	458080e7          	jalr	1112(ra) # 800035b4 <ialloc>
    80005164:	84aa                	mv	s1,a0
    80005166:	c529                	beqz	a0,800051b0 <create+0xee>
  ilock(ip);
    80005168:	ffffe097          	auipc	ra,0xffffe
    8000516c:	5e4080e7          	jalr	1508(ra) # 8000374c <ilock>
  ip->major = major;
    80005170:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005174:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005178:	4785                	li	a5,1
    8000517a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000517e:	8526                	mv	a0,s1
    80005180:	ffffe097          	auipc	ra,0xffffe
    80005184:	502080e7          	jalr	1282(ra) # 80003682 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005188:	2981                	sext.w	s3,s3
    8000518a:	4785                	li	a5,1
    8000518c:	02f98a63          	beq	s3,a5,800051c0 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005190:	40d0                	lw	a2,4(s1)
    80005192:	fb040593          	addi	a1,s0,-80
    80005196:	854a                	mv	a0,s2
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	ca6080e7          	jalr	-858(ra) # 80003e3e <dirlink>
    800051a0:	06054b63          	bltz	a0,80005216 <create+0x154>
  iunlockput(dp);
    800051a4:	854a                	mv	a0,s2
    800051a6:	fffff097          	auipc	ra,0xfffff
    800051aa:	808080e7          	jalr	-2040(ra) # 800039ae <iunlockput>
  return ip;
    800051ae:	b759                	j	80005134 <create+0x72>
    panic("create: ialloc");
    800051b0:	00003517          	auipc	a0,0x3
    800051b4:	56850513          	addi	a0,a0,1384 # 80008718 <syscalls+0x2b0>
    800051b8:	ffffb097          	auipc	ra,0xffffb
    800051bc:	390080e7          	jalr	912(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800051c0:	04a95783          	lhu	a5,74(s2)
    800051c4:	2785                	addiw	a5,a5,1
    800051c6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051ca:	854a                	mv	a0,s2
    800051cc:	ffffe097          	auipc	ra,0xffffe
    800051d0:	4b6080e7          	jalr	1206(ra) # 80003682 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051d4:	40d0                	lw	a2,4(s1)
    800051d6:	00003597          	auipc	a1,0x3
    800051da:	55258593          	addi	a1,a1,1362 # 80008728 <syscalls+0x2c0>
    800051de:	8526                	mv	a0,s1
    800051e0:	fffff097          	auipc	ra,0xfffff
    800051e4:	c5e080e7          	jalr	-930(ra) # 80003e3e <dirlink>
    800051e8:	00054f63          	bltz	a0,80005206 <create+0x144>
    800051ec:	00492603          	lw	a2,4(s2)
    800051f0:	00003597          	auipc	a1,0x3
    800051f4:	54058593          	addi	a1,a1,1344 # 80008730 <syscalls+0x2c8>
    800051f8:	8526                	mv	a0,s1
    800051fa:	fffff097          	auipc	ra,0xfffff
    800051fe:	c44080e7          	jalr	-956(ra) # 80003e3e <dirlink>
    80005202:	f80557e3          	bgez	a0,80005190 <create+0xce>
      panic("create dots");
    80005206:	00003517          	auipc	a0,0x3
    8000520a:	53250513          	addi	a0,a0,1330 # 80008738 <syscalls+0x2d0>
    8000520e:	ffffb097          	auipc	ra,0xffffb
    80005212:	33a080e7          	jalr	826(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005216:	00003517          	auipc	a0,0x3
    8000521a:	53250513          	addi	a0,a0,1330 # 80008748 <syscalls+0x2e0>
    8000521e:	ffffb097          	auipc	ra,0xffffb
    80005222:	32a080e7          	jalr	810(ra) # 80000548 <panic>
    return 0;
    80005226:	84aa                	mv	s1,a0
    80005228:	b731                	j	80005134 <create+0x72>

000000008000522a <sys_dup>:
{
    8000522a:	7179                	addi	sp,sp,-48
    8000522c:	f406                	sd	ra,40(sp)
    8000522e:	f022                	sd	s0,32(sp)
    80005230:	ec26                	sd	s1,24(sp)
    80005232:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005234:	fd840613          	addi	a2,s0,-40
    80005238:	4581                	li	a1,0
    8000523a:	4501                	li	a0,0
    8000523c:	00000097          	auipc	ra,0x0
    80005240:	ddc080e7          	jalr	-548(ra) # 80005018 <argfd>
    return -1;
    80005244:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005246:	02054363          	bltz	a0,8000526c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000524a:	fd843503          	ld	a0,-40(s0)
    8000524e:	00000097          	auipc	ra,0x0
    80005252:	e32080e7          	jalr	-462(ra) # 80005080 <fdalloc>
    80005256:	84aa                	mv	s1,a0
    return -1;
    80005258:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000525a:	00054963          	bltz	a0,8000526c <sys_dup+0x42>
  filedup(f);
    8000525e:	fd843503          	ld	a0,-40(s0)
    80005262:	fffff097          	auipc	ra,0xfffff
    80005266:	32a080e7          	jalr	810(ra) # 8000458c <filedup>
  return fd;
    8000526a:	87a6                	mv	a5,s1
}
    8000526c:	853e                	mv	a0,a5
    8000526e:	70a2                	ld	ra,40(sp)
    80005270:	7402                	ld	s0,32(sp)
    80005272:	64e2                	ld	s1,24(sp)
    80005274:	6145                	addi	sp,sp,48
    80005276:	8082                	ret

0000000080005278 <sys_read>:
{
    80005278:	7179                	addi	sp,sp,-48
    8000527a:	f406                	sd	ra,40(sp)
    8000527c:	f022                	sd	s0,32(sp)
    8000527e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005280:	fe840613          	addi	a2,s0,-24
    80005284:	4581                	li	a1,0
    80005286:	4501                	li	a0,0
    80005288:	00000097          	auipc	ra,0x0
    8000528c:	d90080e7          	jalr	-624(ra) # 80005018 <argfd>
    return -1;
    80005290:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005292:	04054163          	bltz	a0,800052d4 <sys_read+0x5c>
    80005296:	fe440593          	addi	a1,s0,-28
    8000529a:	4509                	li	a0,2
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	914080e7          	jalr	-1772(ra) # 80002bb0 <argint>
    return -1;
    800052a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a6:	02054763          	bltz	a0,800052d4 <sys_read+0x5c>
    800052aa:	fd840593          	addi	a1,s0,-40
    800052ae:	4505                	li	a0,1
    800052b0:	ffffe097          	auipc	ra,0xffffe
    800052b4:	922080e7          	jalr	-1758(ra) # 80002bd2 <argaddr>
    return -1;
    800052b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ba:	00054d63          	bltz	a0,800052d4 <sys_read+0x5c>
  return fileread(f, p, n);
    800052be:	fe442603          	lw	a2,-28(s0)
    800052c2:	fd843583          	ld	a1,-40(s0)
    800052c6:	fe843503          	ld	a0,-24(s0)
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	44e080e7          	jalr	1102(ra) # 80004718 <fileread>
    800052d2:	87aa                	mv	a5,a0
}
    800052d4:	853e                	mv	a0,a5
    800052d6:	70a2                	ld	ra,40(sp)
    800052d8:	7402                	ld	s0,32(sp)
    800052da:	6145                	addi	sp,sp,48
    800052dc:	8082                	ret

00000000800052de <sys_write>:
{
    800052de:	7179                	addi	sp,sp,-48
    800052e0:	f406                	sd	ra,40(sp)
    800052e2:	f022                	sd	s0,32(sp)
    800052e4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e6:	fe840613          	addi	a2,s0,-24
    800052ea:	4581                	li	a1,0
    800052ec:	4501                	li	a0,0
    800052ee:	00000097          	auipc	ra,0x0
    800052f2:	d2a080e7          	jalr	-726(ra) # 80005018 <argfd>
    return -1;
    800052f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f8:	04054163          	bltz	a0,8000533a <sys_write+0x5c>
    800052fc:	fe440593          	addi	a1,s0,-28
    80005300:	4509                	li	a0,2
    80005302:	ffffe097          	auipc	ra,0xffffe
    80005306:	8ae080e7          	jalr	-1874(ra) # 80002bb0 <argint>
    return -1;
    8000530a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530c:	02054763          	bltz	a0,8000533a <sys_write+0x5c>
    80005310:	fd840593          	addi	a1,s0,-40
    80005314:	4505                	li	a0,1
    80005316:	ffffe097          	auipc	ra,0xffffe
    8000531a:	8bc080e7          	jalr	-1860(ra) # 80002bd2 <argaddr>
    return -1;
    8000531e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005320:	00054d63          	bltz	a0,8000533a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005324:	fe442603          	lw	a2,-28(s0)
    80005328:	fd843583          	ld	a1,-40(s0)
    8000532c:	fe843503          	ld	a0,-24(s0)
    80005330:	fffff097          	auipc	ra,0xfffff
    80005334:	4aa080e7          	jalr	1194(ra) # 800047da <filewrite>
    80005338:	87aa                	mv	a5,a0
}
    8000533a:	853e                	mv	a0,a5
    8000533c:	70a2                	ld	ra,40(sp)
    8000533e:	7402                	ld	s0,32(sp)
    80005340:	6145                	addi	sp,sp,48
    80005342:	8082                	ret

0000000080005344 <sys_close>:
{
    80005344:	1101                	addi	sp,sp,-32
    80005346:	ec06                	sd	ra,24(sp)
    80005348:	e822                	sd	s0,16(sp)
    8000534a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000534c:	fe040613          	addi	a2,s0,-32
    80005350:	fec40593          	addi	a1,s0,-20
    80005354:	4501                	li	a0,0
    80005356:	00000097          	auipc	ra,0x0
    8000535a:	cc2080e7          	jalr	-830(ra) # 80005018 <argfd>
    return -1;
    8000535e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005360:	02054463          	bltz	a0,80005388 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005364:	ffffc097          	auipc	ra,0xffffc
    80005368:	6c2080e7          	jalr	1730(ra) # 80001a26 <myproc>
    8000536c:	fec42783          	lw	a5,-20(s0)
    80005370:	07e9                	addi	a5,a5,26
    80005372:	078e                	slli	a5,a5,0x3
    80005374:	97aa                	add	a5,a5,a0
    80005376:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000537a:	fe043503          	ld	a0,-32(s0)
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	260080e7          	jalr	608(ra) # 800045de <fileclose>
  return 0;
    80005386:	4781                	li	a5,0
}
    80005388:	853e                	mv	a0,a5
    8000538a:	60e2                	ld	ra,24(sp)
    8000538c:	6442                	ld	s0,16(sp)
    8000538e:	6105                	addi	sp,sp,32
    80005390:	8082                	ret

0000000080005392 <sys_fstat>:
{
    80005392:	1101                	addi	sp,sp,-32
    80005394:	ec06                	sd	ra,24(sp)
    80005396:	e822                	sd	s0,16(sp)
    80005398:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000539a:	fe840613          	addi	a2,s0,-24
    8000539e:	4581                	li	a1,0
    800053a0:	4501                	li	a0,0
    800053a2:	00000097          	auipc	ra,0x0
    800053a6:	c76080e7          	jalr	-906(ra) # 80005018 <argfd>
    return -1;
    800053aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ac:	02054563          	bltz	a0,800053d6 <sys_fstat+0x44>
    800053b0:	fe040593          	addi	a1,s0,-32
    800053b4:	4505                	li	a0,1
    800053b6:	ffffe097          	auipc	ra,0xffffe
    800053ba:	81c080e7          	jalr	-2020(ra) # 80002bd2 <argaddr>
    return -1;
    800053be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c0:	00054b63          	bltz	a0,800053d6 <sys_fstat+0x44>
  return filestat(f, st);
    800053c4:	fe043583          	ld	a1,-32(s0)
    800053c8:	fe843503          	ld	a0,-24(s0)
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	2da080e7          	jalr	730(ra) # 800046a6 <filestat>
    800053d4:	87aa                	mv	a5,a0
}
    800053d6:	853e                	mv	a0,a5
    800053d8:	60e2                	ld	ra,24(sp)
    800053da:	6442                	ld	s0,16(sp)
    800053dc:	6105                	addi	sp,sp,32
    800053de:	8082                	ret

00000000800053e0 <sys_link>:
{
    800053e0:	7169                	addi	sp,sp,-304
    800053e2:	f606                	sd	ra,296(sp)
    800053e4:	f222                	sd	s0,288(sp)
    800053e6:	ee26                	sd	s1,280(sp)
    800053e8:	ea4a                	sd	s2,272(sp)
    800053ea:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ec:	08000613          	li	a2,128
    800053f0:	ed040593          	addi	a1,s0,-304
    800053f4:	4501                	li	a0,0
    800053f6:	ffffd097          	auipc	ra,0xffffd
    800053fa:	7fe080e7          	jalr	2046(ra) # 80002bf4 <argstr>
    return -1;
    800053fe:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005400:	10054e63          	bltz	a0,8000551c <sys_link+0x13c>
    80005404:	08000613          	li	a2,128
    80005408:	f5040593          	addi	a1,s0,-176
    8000540c:	4505                	li	a0,1
    8000540e:	ffffd097          	auipc	ra,0xffffd
    80005412:	7e6080e7          	jalr	2022(ra) # 80002bf4 <argstr>
    return -1;
    80005416:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005418:	10054263          	bltz	a0,8000551c <sys_link+0x13c>
  begin_op();
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	cf0080e7          	jalr	-784(ra) # 8000410c <begin_op>
  if((ip = namei(old)) == 0){
    80005424:	ed040513          	addi	a0,s0,-304
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	ad8080e7          	jalr	-1320(ra) # 80003f00 <namei>
    80005430:	84aa                	mv	s1,a0
    80005432:	c551                	beqz	a0,800054be <sys_link+0xde>
  ilock(ip);
    80005434:	ffffe097          	auipc	ra,0xffffe
    80005438:	318080e7          	jalr	792(ra) # 8000374c <ilock>
  if(ip->type == T_DIR){
    8000543c:	04449703          	lh	a4,68(s1)
    80005440:	4785                	li	a5,1
    80005442:	08f70463          	beq	a4,a5,800054ca <sys_link+0xea>
  ip->nlink++;
    80005446:	04a4d783          	lhu	a5,74(s1)
    8000544a:	2785                	addiw	a5,a5,1
    8000544c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005450:	8526                	mv	a0,s1
    80005452:	ffffe097          	auipc	ra,0xffffe
    80005456:	230080e7          	jalr	560(ra) # 80003682 <iupdate>
  iunlock(ip);
    8000545a:	8526                	mv	a0,s1
    8000545c:	ffffe097          	auipc	ra,0xffffe
    80005460:	3b2080e7          	jalr	946(ra) # 8000380e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005464:	fd040593          	addi	a1,s0,-48
    80005468:	f5040513          	addi	a0,s0,-176
    8000546c:	fffff097          	auipc	ra,0xfffff
    80005470:	ab2080e7          	jalr	-1358(ra) # 80003f1e <nameiparent>
    80005474:	892a                	mv	s2,a0
    80005476:	c935                	beqz	a0,800054ea <sys_link+0x10a>
  ilock(dp);
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	2d4080e7          	jalr	724(ra) # 8000374c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005480:	00092703          	lw	a4,0(s2)
    80005484:	409c                	lw	a5,0(s1)
    80005486:	04f71d63          	bne	a4,a5,800054e0 <sys_link+0x100>
    8000548a:	40d0                	lw	a2,4(s1)
    8000548c:	fd040593          	addi	a1,s0,-48
    80005490:	854a                	mv	a0,s2
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	9ac080e7          	jalr	-1620(ra) # 80003e3e <dirlink>
    8000549a:	04054363          	bltz	a0,800054e0 <sys_link+0x100>
  iunlockput(dp);
    8000549e:	854a                	mv	a0,s2
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	50e080e7          	jalr	1294(ra) # 800039ae <iunlockput>
  iput(ip);
    800054a8:	8526                	mv	a0,s1
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	45c080e7          	jalr	1116(ra) # 80003906 <iput>
  end_op();
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	cda080e7          	jalr	-806(ra) # 8000418c <end_op>
  return 0;
    800054ba:	4781                	li	a5,0
    800054bc:	a085                	j	8000551c <sys_link+0x13c>
    end_op();
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	cce080e7          	jalr	-818(ra) # 8000418c <end_op>
    return -1;
    800054c6:	57fd                	li	a5,-1
    800054c8:	a891                	j	8000551c <sys_link+0x13c>
    iunlockput(ip);
    800054ca:	8526                	mv	a0,s1
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	4e2080e7          	jalr	1250(ra) # 800039ae <iunlockput>
    end_op();
    800054d4:	fffff097          	auipc	ra,0xfffff
    800054d8:	cb8080e7          	jalr	-840(ra) # 8000418c <end_op>
    return -1;
    800054dc:	57fd                	li	a5,-1
    800054de:	a83d                	j	8000551c <sys_link+0x13c>
    iunlockput(dp);
    800054e0:	854a                	mv	a0,s2
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	4cc080e7          	jalr	1228(ra) # 800039ae <iunlockput>
  ilock(ip);
    800054ea:	8526                	mv	a0,s1
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	260080e7          	jalr	608(ra) # 8000374c <ilock>
  ip->nlink--;
    800054f4:	04a4d783          	lhu	a5,74(s1)
    800054f8:	37fd                	addiw	a5,a5,-1
    800054fa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054fe:	8526                	mv	a0,s1
    80005500:	ffffe097          	auipc	ra,0xffffe
    80005504:	182080e7          	jalr	386(ra) # 80003682 <iupdate>
  iunlockput(ip);
    80005508:	8526                	mv	a0,s1
    8000550a:	ffffe097          	auipc	ra,0xffffe
    8000550e:	4a4080e7          	jalr	1188(ra) # 800039ae <iunlockput>
  end_op();
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	c7a080e7          	jalr	-902(ra) # 8000418c <end_op>
  return -1;
    8000551a:	57fd                	li	a5,-1
}
    8000551c:	853e                	mv	a0,a5
    8000551e:	70b2                	ld	ra,296(sp)
    80005520:	7412                	ld	s0,288(sp)
    80005522:	64f2                	ld	s1,280(sp)
    80005524:	6952                	ld	s2,272(sp)
    80005526:	6155                	addi	sp,sp,304
    80005528:	8082                	ret

000000008000552a <sys_unlink>:
{
    8000552a:	7151                	addi	sp,sp,-240
    8000552c:	f586                	sd	ra,232(sp)
    8000552e:	f1a2                	sd	s0,224(sp)
    80005530:	eda6                	sd	s1,216(sp)
    80005532:	e9ca                	sd	s2,208(sp)
    80005534:	e5ce                	sd	s3,200(sp)
    80005536:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005538:	08000613          	li	a2,128
    8000553c:	f3040593          	addi	a1,s0,-208
    80005540:	4501                	li	a0,0
    80005542:	ffffd097          	auipc	ra,0xffffd
    80005546:	6b2080e7          	jalr	1714(ra) # 80002bf4 <argstr>
    8000554a:	18054163          	bltz	a0,800056cc <sys_unlink+0x1a2>
  begin_op();
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	bbe080e7          	jalr	-1090(ra) # 8000410c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005556:	fb040593          	addi	a1,s0,-80
    8000555a:	f3040513          	addi	a0,s0,-208
    8000555e:	fffff097          	auipc	ra,0xfffff
    80005562:	9c0080e7          	jalr	-1600(ra) # 80003f1e <nameiparent>
    80005566:	84aa                	mv	s1,a0
    80005568:	c979                	beqz	a0,8000563e <sys_unlink+0x114>
  ilock(dp);
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	1e2080e7          	jalr	482(ra) # 8000374c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005572:	00003597          	auipc	a1,0x3
    80005576:	1b658593          	addi	a1,a1,438 # 80008728 <syscalls+0x2c0>
    8000557a:	fb040513          	addi	a0,s0,-80
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	696080e7          	jalr	1686(ra) # 80003c14 <namecmp>
    80005586:	14050a63          	beqz	a0,800056da <sys_unlink+0x1b0>
    8000558a:	00003597          	auipc	a1,0x3
    8000558e:	1a658593          	addi	a1,a1,422 # 80008730 <syscalls+0x2c8>
    80005592:	fb040513          	addi	a0,s0,-80
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	67e080e7          	jalr	1662(ra) # 80003c14 <namecmp>
    8000559e:	12050e63          	beqz	a0,800056da <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055a2:	f2c40613          	addi	a2,s0,-212
    800055a6:	fb040593          	addi	a1,s0,-80
    800055aa:	8526                	mv	a0,s1
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	682080e7          	jalr	1666(ra) # 80003c2e <dirlookup>
    800055b4:	892a                	mv	s2,a0
    800055b6:	12050263          	beqz	a0,800056da <sys_unlink+0x1b0>
  ilock(ip);
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	192080e7          	jalr	402(ra) # 8000374c <ilock>
  if(ip->nlink < 1)
    800055c2:	04a91783          	lh	a5,74(s2)
    800055c6:	08f05263          	blez	a5,8000564a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055ca:	04491703          	lh	a4,68(s2)
    800055ce:	4785                	li	a5,1
    800055d0:	08f70563          	beq	a4,a5,8000565a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055d4:	4641                	li	a2,16
    800055d6:	4581                	li	a1,0
    800055d8:	fc040513          	addi	a0,s0,-64
    800055dc:	ffffb097          	auipc	ra,0xffffb
    800055e0:	730080e7          	jalr	1840(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055e4:	4741                	li	a4,16
    800055e6:	f2c42683          	lw	a3,-212(s0)
    800055ea:	fc040613          	addi	a2,s0,-64
    800055ee:	4581                	li	a1,0
    800055f0:	8526                	mv	a0,s1
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	506080e7          	jalr	1286(ra) # 80003af8 <writei>
    800055fa:	47c1                	li	a5,16
    800055fc:	0af51563          	bne	a0,a5,800056a6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005600:	04491703          	lh	a4,68(s2)
    80005604:	4785                	li	a5,1
    80005606:	0af70863          	beq	a4,a5,800056b6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000560a:	8526                	mv	a0,s1
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	3a2080e7          	jalr	930(ra) # 800039ae <iunlockput>
  ip->nlink--;
    80005614:	04a95783          	lhu	a5,74(s2)
    80005618:	37fd                	addiw	a5,a5,-1
    8000561a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000561e:	854a                	mv	a0,s2
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	062080e7          	jalr	98(ra) # 80003682 <iupdate>
  iunlockput(ip);
    80005628:	854a                	mv	a0,s2
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	384080e7          	jalr	900(ra) # 800039ae <iunlockput>
  end_op();
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	b5a080e7          	jalr	-1190(ra) # 8000418c <end_op>
  return 0;
    8000563a:	4501                	li	a0,0
    8000563c:	a84d                	j	800056ee <sys_unlink+0x1c4>
    end_op();
    8000563e:	fffff097          	auipc	ra,0xfffff
    80005642:	b4e080e7          	jalr	-1202(ra) # 8000418c <end_op>
    return -1;
    80005646:	557d                	li	a0,-1
    80005648:	a05d                	j	800056ee <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000564a:	00003517          	auipc	a0,0x3
    8000564e:	10e50513          	addi	a0,a0,270 # 80008758 <syscalls+0x2f0>
    80005652:	ffffb097          	auipc	ra,0xffffb
    80005656:	ef6080e7          	jalr	-266(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000565a:	04c92703          	lw	a4,76(s2)
    8000565e:	02000793          	li	a5,32
    80005662:	f6e7f9e3          	bgeu	a5,a4,800055d4 <sys_unlink+0xaa>
    80005666:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000566a:	4741                	li	a4,16
    8000566c:	86ce                	mv	a3,s3
    8000566e:	f1840613          	addi	a2,s0,-232
    80005672:	4581                	li	a1,0
    80005674:	854a                	mv	a0,s2
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	38a080e7          	jalr	906(ra) # 80003a00 <readi>
    8000567e:	47c1                	li	a5,16
    80005680:	00f51b63          	bne	a0,a5,80005696 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005684:	f1845783          	lhu	a5,-232(s0)
    80005688:	e7a1                	bnez	a5,800056d0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000568a:	29c1                	addiw	s3,s3,16
    8000568c:	04c92783          	lw	a5,76(s2)
    80005690:	fcf9ede3          	bltu	s3,a5,8000566a <sys_unlink+0x140>
    80005694:	b781                	j	800055d4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005696:	00003517          	auipc	a0,0x3
    8000569a:	0da50513          	addi	a0,a0,218 # 80008770 <syscalls+0x308>
    8000569e:	ffffb097          	auipc	ra,0xffffb
    800056a2:	eaa080e7          	jalr	-342(ra) # 80000548 <panic>
    panic("unlink: writei");
    800056a6:	00003517          	auipc	a0,0x3
    800056aa:	0e250513          	addi	a0,a0,226 # 80008788 <syscalls+0x320>
    800056ae:	ffffb097          	auipc	ra,0xffffb
    800056b2:	e9a080e7          	jalr	-358(ra) # 80000548 <panic>
    dp->nlink--;
    800056b6:	04a4d783          	lhu	a5,74(s1)
    800056ba:	37fd                	addiw	a5,a5,-1
    800056bc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056c0:	8526                	mv	a0,s1
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	fc0080e7          	jalr	-64(ra) # 80003682 <iupdate>
    800056ca:	b781                	j	8000560a <sys_unlink+0xe0>
    return -1;
    800056cc:	557d                	li	a0,-1
    800056ce:	a005                	j	800056ee <sys_unlink+0x1c4>
    iunlockput(ip);
    800056d0:	854a                	mv	a0,s2
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	2dc080e7          	jalr	732(ra) # 800039ae <iunlockput>
  iunlockput(dp);
    800056da:	8526                	mv	a0,s1
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	2d2080e7          	jalr	722(ra) # 800039ae <iunlockput>
  end_op();
    800056e4:	fffff097          	auipc	ra,0xfffff
    800056e8:	aa8080e7          	jalr	-1368(ra) # 8000418c <end_op>
  return -1;
    800056ec:	557d                	li	a0,-1
}
    800056ee:	70ae                	ld	ra,232(sp)
    800056f0:	740e                	ld	s0,224(sp)
    800056f2:	64ee                	ld	s1,216(sp)
    800056f4:	694e                	ld	s2,208(sp)
    800056f6:	69ae                	ld	s3,200(sp)
    800056f8:	616d                	addi	sp,sp,240
    800056fa:	8082                	ret

00000000800056fc <sys_open>:

uint64
sys_open(void)
{
    800056fc:	7131                	addi	sp,sp,-192
    800056fe:	fd06                	sd	ra,184(sp)
    80005700:	f922                	sd	s0,176(sp)
    80005702:	f526                	sd	s1,168(sp)
    80005704:	f14a                	sd	s2,160(sp)
    80005706:	ed4e                	sd	s3,152(sp)
    80005708:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000570a:	08000613          	li	a2,128
    8000570e:	f5040593          	addi	a1,s0,-176
    80005712:	4501                	li	a0,0
    80005714:	ffffd097          	auipc	ra,0xffffd
    80005718:	4e0080e7          	jalr	1248(ra) # 80002bf4 <argstr>
    return -1;
    8000571c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000571e:	0c054163          	bltz	a0,800057e0 <sys_open+0xe4>
    80005722:	f4c40593          	addi	a1,s0,-180
    80005726:	4505                	li	a0,1
    80005728:	ffffd097          	auipc	ra,0xffffd
    8000572c:	488080e7          	jalr	1160(ra) # 80002bb0 <argint>
    80005730:	0a054863          	bltz	a0,800057e0 <sys_open+0xe4>

  begin_op();
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	9d8080e7          	jalr	-1576(ra) # 8000410c <begin_op>

  if(omode & O_CREATE){
    8000573c:	f4c42783          	lw	a5,-180(s0)
    80005740:	2007f793          	andi	a5,a5,512
    80005744:	cbdd                	beqz	a5,800057fa <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005746:	4681                	li	a3,0
    80005748:	4601                	li	a2,0
    8000574a:	4589                	li	a1,2
    8000574c:	f5040513          	addi	a0,s0,-176
    80005750:	00000097          	auipc	ra,0x0
    80005754:	972080e7          	jalr	-1678(ra) # 800050c2 <create>
    80005758:	892a                	mv	s2,a0
    if(ip == 0){
    8000575a:	c959                	beqz	a0,800057f0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000575c:	04491703          	lh	a4,68(s2)
    80005760:	478d                	li	a5,3
    80005762:	00f71763          	bne	a4,a5,80005770 <sys_open+0x74>
    80005766:	04695703          	lhu	a4,70(s2)
    8000576a:	47a5                	li	a5,9
    8000576c:	0ce7ec63          	bltu	a5,a4,80005844 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	db2080e7          	jalr	-590(ra) # 80004522 <filealloc>
    80005778:	89aa                	mv	s3,a0
    8000577a:	10050263          	beqz	a0,8000587e <sys_open+0x182>
    8000577e:	00000097          	auipc	ra,0x0
    80005782:	902080e7          	jalr	-1790(ra) # 80005080 <fdalloc>
    80005786:	84aa                	mv	s1,a0
    80005788:	0e054663          	bltz	a0,80005874 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000578c:	04491703          	lh	a4,68(s2)
    80005790:	478d                	li	a5,3
    80005792:	0cf70463          	beq	a4,a5,8000585a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005796:	4789                	li	a5,2
    80005798:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000579c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057a0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057a4:	f4c42783          	lw	a5,-180(s0)
    800057a8:	0017c713          	xori	a4,a5,1
    800057ac:	8b05                	andi	a4,a4,1
    800057ae:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057b2:	0037f713          	andi	a4,a5,3
    800057b6:	00e03733          	snez	a4,a4
    800057ba:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057be:	4007f793          	andi	a5,a5,1024
    800057c2:	c791                	beqz	a5,800057ce <sys_open+0xd2>
    800057c4:	04491703          	lh	a4,68(s2)
    800057c8:	4789                	li	a5,2
    800057ca:	08f70f63          	beq	a4,a5,80005868 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057ce:	854a                	mv	a0,s2
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	03e080e7          	jalr	62(ra) # 8000380e <iunlock>
  end_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	9b4080e7          	jalr	-1612(ra) # 8000418c <end_op>

  return fd;
}
    800057e0:	8526                	mv	a0,s1
    800057e2:	70ea                	ld	ra,184(sp)
    800057e4:	744a                	ld	s0,176(sp)
    800057e6:	74aa                	ld	s1,168(sp)
    800057e8:	790a                	ld	s2,160(sp)
    800057ea:	69ea                	ld	s3,152(sp)
    800057ec:	6129                	addi	sp,sp,192
    800057ee:	8082                	ret
      end_op();
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	99c080e7          	jalr	-1636(ra) # 8000418c <end_op>
      return -1;
    800057f8:	b7e5                	j	800057e0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057fa:	f5040513          	addi	a0,s0,-176
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	702080e7          	jalr	1794(ra) # 80003f00 <namei>
    80005806:	892a                	mv	s2,a0
    80005808:	c905                	beqz	a0,80005838 <sys_open+0x13c>
    ilock(ip);
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	f42080e7          	jalr	-190(ra) # 8000374c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005812:	04491703          	lh	a4,68(s2)
    80005816:	4785                	li	a5,1
    80005818:	f4f712e3          	bne	a4,a5,8000575c <sys_open+0x60>
    8000581c:	f4c42783          	lw	a5,-180(s0)
    80005820:	dba1                	beqz	a5,80005770 <sys_open+0x74>
      iunlockput(ip);
    80005822:	854a                	mv	a0,s2
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	18a080e7          	jalr	394(ra) # 800039ae <iunlockput>
      end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	960080e7          	jalr	-1696(ra) # 8000418c <end_op>
      return -1;
    80005834:	54fd                	li	s1,-1
    80005836:	b76d                	j	800057e0 <sys_open+0xe4>
      end_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	954080e7          	jalr	-1708(ra) # 8000418c <end_op>
      return -1;
    80005840:	54fd                	li	s1,-1
    80005842:	bf79                	j	800057e0 <sys_open+0xe4>
    iunlockput(ip);
    80005844:	854a                	mv	a0,s2
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	168080e7          	jalr	360(ra) # 800039ae <iunlockput>
    end_op();
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	93e080e7          	jalr	-1730(ra) # 8000418c <end_op>
    return -1;
    80005856:	54fd                	li	s1,-1
    80005858:	b761                	j	800057e0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000585a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000585e:	04691783          	lh	a5,70(s2)
    80005862:	02f99223          	sh	a5,36(s3)
    80005866:	bf2d                	j	800057a0 <sys_open+0xa4>
    itrunc(ip);
    80005868:	854a                	mv	a0,s2
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	ff0080e7          	jalr	-16(ra) # 8000385a <itrunc>
    80005872:	bfb1                	j	800057ce <sys_open+0xd2>
      fileclose(f);
    80005874:	854e                	mv	a0,s3
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	d68080e7          	jalr	-664(ra) # 800045de <fileclose>
    iunlockput(ip);
    8000587e:	854a                	mv	a0,s2
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	12e080e7          	jalr	302(ra) # 800039ae <iunlockput>
    end_op();
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	904080e7          	jalr	-1788(ra) # 8000418c <end_op>
    return -1;
    80005890:	54fd                	li	s1,-1
    80005892:	b7b9                	j	800057e0 <sys_open+0xe4>

0000000080005894 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005894:	7175                	addi	sp,sp,-144
    80005896:	e506                	sd	ra,136(sp)
    80005898:	e122                	sd	s0,128(sp)
    8000589a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	870080e7          	jalr	-1936(ra) # 8000410c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058a4:	08000613          	li	a2,128
    800058a8:	f7040593          	addi	a1,s0,-144
    800058ac:	4501                	li	a0,0
    800058ae:	ffffd097          	auipc	ra,0xffffd
    800058b2:	346080e7          	jalr	838(ra) # 80002bf4 <argstr>
    800058b6:	02054963          	bltz	a0,800058e8 <sys_mkdir+0x54>
    800058ba:	4681                	li	a3,0
    800058bc:	4601                	li	a2,0
    800058be:	4585                	li	a1,1
    800058c0:	f7040513          	addi	a0,s0,-144
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	7fe080e7          	jalr	2046(ra) # 800050c2 <create>
    800058cc:	cd11                	beqz	a0,800058e8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	0e0080e7          	jalr	224(ra) # 800039ae <iunlockput>
  end_op();
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	8b6080e7          	jalr	-1866(ra) # 8000418c <end_op>
  return 0;
    800058de:	4501                	li	a0,0
}
    800058e0:	60aa                	ld	ra,136(sp)
    800058e2:	640a                	ld	s0,128(sp)
    800058e4:	6149                	addi	sp,sp,144
    800058e6:	8082                	ret
    end_op();
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	8a4080e7          	jalr	-1884(ra) # 8000418c <end_op>
    return -1;
    800058f0:	557d                	li	a0,-1
    800058f2:	b7fd                	j	800058e0 <sys_mkdir+0x4c>

00000000800058f4 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058f4:	7135                	addi	sp,sp,-160
    800058f6:	ed06                	sd	ra,152(sp)
    800058f8:	e922                	sd	s0,144(sp)
    800058fa:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	810080e7          	jalr	-2032(ra) # 8000410c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005904:	08000613          	li	a2,128
    80005908:	f7040593          	addi	a1,s0,-144
    8000590c:	4501                	li	a0,0
    8000590e:	ffffd097          	auipc	ra,0xffffd
    80005912:	2e6080e7          	jalr	742(ra) # 80002bf4 <argstr>
    80005916:	04054a63          	bltz	a0,8000596a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000591a:	f6c40593          	addi	a1,s0,-148
    8000591e:	4505                	li	a0,1
    80005920:	ffffd097          	auipc	ra,0xffffd
    80005924:	290080e7          	jalr	656(ra) # 80002bb0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005928:	04054163          	bltz	a0,8000596a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000592c:	f6840593          	addi	a1,s0,-152
    80005930:	4509                	li	a0,2
    80005932:	ffffd097          	auipc	ra,0xffffd
    80005936:	27e080e7          	jalr	638(ra) # 80002bb0 <argint>
     argint(1, &major) < 0 ||
    8000593a:	02054863          	bltz	a0,8000596a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000593e:	f6841683          	lh	a3,-152(s0)
    80005942:	f6c41603          	lh	a2,-148(s0)
    80005946:	458d                	li	a1,3
    80005948:	f7040513          	addi	a0,s0,-144
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	776080e7          	jalr	1910(ra) # 800050c2 <create>
     argint(2, &minor) < 0 ||
    80005954:	c919                	beqz	a0,8000596a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	058080e7          	jalr	88(ra) # 800039ae <iunlockput>
  end_op();
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	82e080e7          	jalr	-2002(ra) # 8000418c <end_op>
  return 0;
    80005966:	4501                	li	a0,0
    80005968:	a031                	j	80005974 <sys_mknod+0x80>
    end_op();
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	822080e7          	jalr	-2014(ra) # 8000418c <end_op>
    return -1;
    80005972:	557d                	li	a0,-1
}
    80005974:	60ea                	ld	ra,152(sp)
    80005976:	644a                	ld	s0,144(sp)
    80005978:	610d                	addi	sp,sp,160
    8000597a:	8082                	ret

000000008000597c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000597c:	7135                	addi	sp,sp,-160
    8000597e:	ed06                	sd	ra,152(sp)
    80005980:	e922                	sd	s0,144(sp)
    80005982:	e526                	sd	s1,136(sp)
    80005984:	e14a                	sd	s2,128(sp)
    80005986:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005988:	ffffc097          	auipc	ra,0xffffc
    8000598c:	09e080e7          	jalr	158(ra) # 80001a26 <myproc>
    80005990:	892a                	mv	s2,a0
  
  begin_op();
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	77a080e7          	jalr	1914(ra) # 8000410c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000599a:	08000613          	li	a2,128
    8000599e:	f6040593          	addi	a1,s0,-160
    800059a2:	4501                	li	a0,0
    800059a4:	ffffd097          	auipc	ra,0xffffd
    800059a8:	250080e7          	jalr	592(ra) # 80002bf4 <argstr>
    800059ac:	04054b63          	bltz	a0,80005a02 <sys_chdir+0x86>
    800059b0:	f6040513          	addi	a0,s0,-160
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	54c080e7          	jalr	1356(ra) # 80003f00 <namei>
    800059bc:	84aa                	mv	s1,a0
    800059be:	c131                	beqz	a0,80005a02 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	d8c080e7          	jalr	-628(ra) # 8000374c <ilock>
  if(ip->type != T_DIR){
    800059c8:	04449703          	lh	a4,68(s1)
    800059cc:	4785                	li	a5,1
    800059ce:	04f71063          	bne	a4,a5,80005a0e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059d2:	8526                	mv	a0,s1
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	e3a080e7          	jalr	-454(ra) # 8000380e <iunlock>
  iput(p->cwd);
    800059dc:	15093503          	ld	a0,336(s2)
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	f26080e7          	jalr	-218(ra) # 80003906 <iput>
  end_op();
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	7a4080e7          	jalr	1956(ra) # 8000418c <end_op>
  p->cwd = ip;
    800059f0:	14993823          	sd	s1,336(s2)
  return 0;
    800059f4:	4501                	li	a0,0
}
    800059f6:	60ea                	ld	ra,152(sp)
    800059f8:	644a                	ld	s0,144(sp)
    800059fa:	64aa                	ld	s1,136(sp)
    800059fc:	690a                	ld	s2,128(sp)
    800059fe:	610d                	addi	sp,sp,160
    80005a00:	8082                	ret
    end_op();
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	78a080e7          	jalr	1930(ra) # 8000418c <end_op>
    return -1;
    80005a0a:	557d                	li	a0,-1
    80005a0c:	b7ed                	j	800059f6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a0e:	8526                	mv	a0,s1
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	f9e080e7          	jalr	-98(ra) # 800039ae <iunlockput>
    end_op();
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	774080e7          	jalr	1908(ra) # 8000418c <end_op>
    return -1;
    80005a20:	557d                	li	a0,-1
    80005a22:	bfd1                	j	800059f6 <sys_chdir+0x7a>

0000000080005a24 <sys_exec>:

uint64
sys_exec(void)
{
    80005a24:	7145                	addi	sp,sp,-464
    80005a26:	e786                	sd	ra,456(sp)
    80005a28:	e3a2                	sd	s0,448(sp)
    80005a2a:	ff26                	sd	s1,440(sp)
    80005a2c:	fb4a                	sd	s2,432(sp)
    80005a2e:	f74e                	sd	s3,424(sp)
    80005a30:	f352                	sd	s4,416(sp)
    80005a32:	ef56                	sd	s5,408(sp)
    80005a34:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a36:	08000613          	li	a2,128
    80005a3a:	f4040593          	addi	a1,s0,-192
    80005a3e:	4501                	li	a0,0
    80005a40:	ffffd097          	auipc	ra,0xffffd
    80005a44:	1b4080e7          	jalr	436(ra) # 80002bf4 <argstr>
    return -1;
    80005a48:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a4a:	0c054a63          	bltz	a0,80005b1e <sys_exec+0xfa>
    80005a4e:	e3840593          	addi	a1,s0,-456
    80005a52:	4505                	li	a0,1
    80005a54:	ffffd097          	auipc	ra,0xffffd
    80005a58:	17e080e7          	jalr	382(ra) # 80002bd2 <argaddr>
    80005a5c:	0c054163          	bltz	a0,80005b1e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a60:	10000613          	li	a2,256
    80005a64:	4581                	li	a1,0
    80005a66:	e4040513          	addi	a0,s0,-448
    80005a6a:	ffffb097          	auipc	ra,0xffffb
    80005a6e:	2a2080e7          	jalr	674(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a72:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a76:	89a6                	mv	s3,s1
    80005a78:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a7a:	02000a13          	li	s4,32
    80005a7e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a82:	00391513          	slli	a0,s2,0x3
    80005a86:	e3040593          	addi	a1,s0,-464
    80005a8a:	e3843783          	ld	a5,-456(s0)
    80005a8e:	953e                	add	a0,a0,a5
    80005a90:	ffffd097          	auipc	ra,0xffffd
    80005a94:	086080e7          	jalr	134(ra) # 80002b16 <fetchaddr>
    80005a98:	02054a63          	bltz	a0,80005acc <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a9c:	e3043783          	ld	a5,-464(s0)
    80005aa0:	c3b9                	beqz	a5,80005ae6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005aa2:	ffffb097          	auipc	ra,0xffffb
    80005aa6:	07e080e7          	jalr	126(ra) # 80000b20 <kalloc>
    80005aaa:	85aa                	mv	a1,a0
    80005aac:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ab0:	cd11                	beqz	a0,80005acc <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ab2:	6605                	lui	a2,0x1
    80005ab4:	e3043503          	ld	a0,-464(s0)
    80005ab8:	ffffd097          	auipc	ra,0xffffd
    80005abc:	0b0080e7          	jalr	176(ra) # 80002b68 <fetchstr>
    80005ac0:	00054663          	bltz	a0,80005acc <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ac4:	0905                	addi	s2,s2,1
    80005ac6:	09a1                	addi	s3,s3,8
    80005ac8:	fb491be3          	bne	s2,s4,80005a7e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005acc:	10048913          	addi	s2,s1,256
    80005ad0:	6088                	ld	a0,0(s1)
    80005ad2:	c529                	beqz	a0,80005b1c <sys_exec+0xf8>
    kfree(argv[i]);
    80005ad4:	ffffb097          	auipc	ra,0xffffb
    80005ad8:	f50080e7          	jalr	-176(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005adc:	04a1                	addi	s1,s1,8
    80005ade:	ff2499e3          	bne	s1,s2,80005ad0 <sys_exec+0xac>
  return -1;
    80005ae2:	597d                	li	s2,-1
    80005ae4:	a82d                	j	80005b1e <sys_exec+0xfa>
      argv[i] = 0;
    80005ae6:	0a8e                	slli	s5,s5,0x3
    80005ae8:	fc040793          	addi	a5,s0,-64
    80005aec:	9abe                	add	s5,s5,a5
    80005aee:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005af2:	e4040593          	addi	a1,s0,-448
    80005af6:	f4040513          	addi	a0,s0,-192
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	194080e7          	jalr	404(ra) # 80004c8e <exec>
    80005b02:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b04:	10048993          	addi	s3,s1,256
    80005b08:	6088                	ld	a0,0(s1)
    80005b0a:	c911                	beqz	a0,80005b1e <sys_exec+0xfa>
    kfree(argv[i]);
    80005b0c:	ffffb097          	auipc	ra,0xffffb
    80005b10:	f18080e7          	jalr	-232(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b14:	04a1                	addi	s1,s1,8
    80005b16:	ff3499e3          	bne	s1,s3,80005b08 <sys_exec+0xe4>
    80005b1a:	a011                	j	80005b1e <sys_exec+0xfa>
  return -1;
    80005b1c:	597d                	li	s2,-1
}
    80005b1e:	854a                	mv	a0,s2
    80005b20:	60be                	ld	ra,456(sp)
    80005b22:	641e                	ld	s0,448(sp)
    80005b24:	74fa                	ld	s1,440(sp)
    80005b26:	795a                	ld	s2,432(sp)
    80005b28:	79ba                	ld	s3,424(sp)
    80005b2a:	7a1a                	ld	s4,416(sp)
    80005b2c:	6afa                	ld	s5,408(sp)
    80005b2e:	6179                	addi	sp,sp,464
    80005b30:	8082                	ret

0000000080005b32 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b32:	7139                	addi	sp,sp,-64
    80005b34:	fc06                	sd	ra,56(sp)
    80005b36:	f822                	sd	s0,48(sp)
    80005b38:	f426                	sd	s1,40(sp)
    80005b3a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b3c:	ffffc097          	auipc	ra,0xffffc
    80005b40:	eea080e7          	jalr	-278(ra) # 80001a26 <myproc>
    80005b44:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b46:	fd840593          	addi	a1,s0,-40
    80005b4a:	4501                	li	a0,0
    80005b4c:	ffffd097          	auipc	ra,0xffffd
    80005b50:	086080e7          	jalr	134(ra) # 80002bd2 <argaddr>
    return -1;
    80005b54:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b56:	0e054063          	bltz	a0,80005c36 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b5a:	fc840593          	addi	a1,s0,-56
    80005b5e:	fd040513          	addi	a0,s0,-48
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	dd2080e7          	jalr	-558(ra) # 80004934 <pipealloc>
    return -1;
    80005b6a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b6c:	0c054563          	bltz	a0,80005c36 <sys_pipe+0x104>
  fd0 = -1;
    80005b70:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b74:	fd043503          	ld	a0,-48(s0)
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	508080e7          	jalr	1288(ra) # 80005080 <fdalloc>
    80005b80:	fca42223          	sw	a0,-60(s0)
    80005b84:	08054c63          	bltz	a0,80005c1c <sys_pipe+0xea>
    80005b88:	fc843503          	ld	a0,-56(s0)
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	4f4080e7          	jalr	1268(ra) # 80005080 <fdalloc>
    80005b94:	fca42023          	sw	a0,-64(s0)
    80005b98:	06054863          	bltz	a0,80005c08 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b9c:	4691                	li	a3,4
    80005b9e:	fc440613          	addi	a2,s0,-60
    80005ba2:	fd843583          	ld	a1,-40(s0)
    80005ba6:	68a8                	ld	a0,80(s1)
    80005ba8:	ffffc097          	auipc	ra,0xffffc
    80005bac:	b72080e7          	jalr	-1166(ra) # 8000171a <copyout>
    80005bb0:	02054063          	bltz	a0,80005bd0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bb4:	4691                	li	a3,4
    80005bb6:	fc040613          	addi	a2,s0,-64
    80005bba:	fd843583          	ld	a1,-40(s0)
    80005bbe:	0591                	addi	a1,a1,4
    80005bc0:	68a8                	ld	a0,80(s1)
    80005bc2:	ffffc097          	auipc	ra,0xffffc
    80005bc6:	b58080e7          	jalr	-1192(ra) # 8000171a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bca:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bcc:	06055563          	bgez	a0,80005c36 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bd0:	fc442783          	lw	a5,-60(s0)
    80005bd4:	07e9                	addi	a5,a5,26
    80005bd6:	078e                	slli	a5,a5,0x3
    80005bd8:	97a6                	add	a5,a5,s1
    80005bda:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bde:	fc042503          	lw	a0,-64(s0)
    80005be2:	0569                	addi	a0,a0,26
    80005be4:	050e                	slli	a0,a0,0x3
    80005be6:	9526                	add	a0,a0,s1
    80005be8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bec:	fd043503          	ld	a0,-48(s0)
    80005bf0:	fffff097          	auipc	ra,0xfffff
    80005bf4:	9ee080e7          	jalr	-1554(ra) # 800045de <fileclose>
    fileclose(wf);
    80005bf8:	fc843503          	ld	a0,-56(s0)
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	9e2080e7          	jalr	-1566(ra) # 800045de <fileclose>
    return -1;
    80005c04:	57fd                	li	a5,-1
    80005c06:	a805                	j	80005c36 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c08:	fc442783          	lw	a5,-60(s0)
    80005c0c:	0007c863          	bltz	a5,80005c1c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c10:	01a78513          	addi	a0,a5,26
    80005c14:	050e                	slli	a0,a0,0x3
    80005c16:	9526                	add	a0,a0,s1
    80005c18:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c1c:	fd043503          	ld	a0,-48(s0)
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	9be080e7          	jalr	-1602(ra) # 800045de <fileclose>
    fileclose(wf);
    80005c28:	fc843503          	ld	a0,-56(s0)
    80005c2c:	fffff097          	auipc	ra,0xfffff
    80005c30:	9b2080e7          	jalr	-1614(ra) # 800045de <fileclose>
    return -1;
    80005c34:	57fd                	li	a5,-1
}
    80005c36:	853e                	mv	a0,a5
    80005c38:	70e2                	ld	ra,56(sp)
    80005c3a:	7442                	ld	s0,48(sp)
    80005c3c:	74a2                	ld	s1,40(sp)
    80005c3e:	6121                	addi	sp,sp,64
    80005c40:	8082                	ret
	...

0000000080005c50 <kernelvec>:
    80005c50:	7111                	addi	sp,sp,-256
    80005c52:	e006                	sd	ra,0(sp)
    80005c54:	e40a                	sd	sp,8(sp)
    80005c56:	e80e                	sd	gp,16(sp)
    80005c58:	ec12                	sd	tp,24(sp)
    80005c5a:	f016                	sd	t0,32(sp)
    80005c5c:	f41a                	sd	t1,40(sp)
    80005c5e:	f81e                	sd	t2,48(sp)
    80005c60:	fc22                	sd	s0,56(sp)
    80005c62:	e0a6                	sd	s1,64(sp)
    80005c64:	e4aa                	sd	a0,72(sp)
    80005c66:	e8ae                	sd	a1,80(sp)
    80005c68:	ecb2                	sd	a2,88(sp)
    80005c6a:	f0b6                	sd	a3,96(sp)
    80005c6c:	f4ba                	sd	a4,104(sp)
    80005c6e:	f8be                	sd	a5,112(sp)
    80005c70:	fcc2                	sd	a6,120(sp)
    80005c72:	e146                	sd	a7,128(sp)
    80005c74:	e54a                	sd	s2,136(sp)
    80005c76:	e94e                	sd	s3,144(sp)
    80005c78:	ed52                	sd	s4,152(sp)
    80005c7a:	f156                	sd	s5,160(sp)
    80005c7c:	f55a                	sd	s6,168(sp)
    80005c7e:	f95e                	sd	s7,176(sp)
    80005c80:	fd62                	sd	s8,184(sp)
    80005c82:	e1e6                	sd	s9,192(sp)
    80005c84:	e5ea                	sd	s10,200(sp)
    80005c86:	e9ee                	sd	s11,208(sp)
    80005c88:	edf2                	sd	t3,216(sp)
    80005c8a:	f1f6                	sd	t4,224(sp)
    80005c8c:	f5fa                	sd	t5,232(sp)
    80005c8e:	f9fe                	sd	t6,240(sp)
    80005c90:	d53fc0ef          	jal	ra,800029e2 <kerneltrap>
    80005c94:	6082                	ld	ra,0(sp)
    80005c96:	6122                	ld	sp,8(sp)
    80005c98:	61c2                	ld	gp,16(sp)
    80005c9a:	7282                	ld	t0,32(sp)
    80005c9c:	7322                	ld	t1,40(sp)
    80005c9e:	73c2                	ld	t2,48(sp)
    80005ca0:	7462                	ld	s0,56(sp)
    80005ca2:	6486                	ld	s1,64(sp)
    80005ca4:	6526                	ld	a0,72(sp)
    80005ca6:	65c6                	ld	a1,80(sp)
    80005ca8:	6666                	ld	a2,88(sp)
    80005caa:	7686                	ld	a3,96(sp)
    80005cac:	7726                	ld	a4,104(sp)
    80005cae:	77c6                	ld	a5,112(sp)
    80005cb0:	7866                	ld	a6,120(sp)
    80005cb2:	688a                	ld	a7,128(sp)
    80005cb4:	692a                	ld	s2,136(sp)
    80005cb6:	69ca                	ld	s3,144(sp)
    80005cb8:	6a6a                	ld	s4,152(sp)
    80005cba:	7a8a                	ld	s5,160(sp)
    80005cbc:	7b2a                	ld	s6,168(sp)
    80005cbe:	7bca                	ld	s7,176(sp)
    80005cc0:	7c6a                	ld	s8,184(sp)
    80005cc2:	6c8e                	ld	s9,192(sp)
    80005cc4:	6d2e                	ld	s10,200(sp)
    80005cc6:	6dce                	ld	s11,208(sp)
    80005cc8:	6e6e                	ld	t3,216(sp)
    80005cca:	7e8e                	ld	t4,224(sp)
    80005ccc:	7f2e                	ld	t5,232(sp)
    80005cce:	7fce                	ld	t6,240(sp)
    80005cd0:	6111                	addi	sp,sp,256
    80005cd2:	10200073          	sret
    80005cd6:	00000013          	nop
    80005cda:	00000013          	nop
    80005cde:	0001                	nop

0000000080005ce0 <timervec>:
    80005ce0:	34051573          	csrrw	a0,mscratch,a0
    80005ce4:	e10c                	sd	a1,0(a0)
    80005ce6:	e510                	sd	a2,8(a0)
    80005ce8:	e914                	sd	a3,16(a0)
    80005cea:	710c                	ld	a1,32(a0)
    80005cec:	7510                	ld	a2,40(a0)
    80005cee:	6194                	ld	a3,0(a1)
    80005cf0:	96b2                	add	a3,a3,a2
    80005cf2:	e194                	sd	a3,0(a1)
    80005cf4:	4589                	li	a1,2
    80005cf6:	14459073          	csrw	sip,a1
    80005cfa:	6914                	ld	a3,16(a0)
    80005cfc:	6510                	ld	a2,8(a0)
    80005cfe:	610c                	ld	a1,0(a0)
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	30200073          	mret
	...

0000000080005d0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d0a:	1141                	addi	sp,sp,-16
    80005d0c:	e422                	sd	s0,8(sp)
    80005d0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d10:	0c0007b7          	lui	a5,0xc000
    80005d14:	4705                	li	a4,1
    80005d16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d18:	c3d8                	sw	a4,4(a5)
}
    80005d1a:	6422                	ld	s0,8(sp)
    80005d1c:	0141                	addi	sp,sp,16
    80005d1e:	8082                	ret

0000000080005d20 <plicinithart>:

void
plicinithart(void)
{
    80005d20:	1141                	addi	sp,sp,-16
    80005d22:	e406                	sd	ra,8(sp)
    80005d24:	e022                	sd	s0,0(sp)
    80005d26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	cd2080e7          	jalr	-814(ra) # 800019fa <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d30:	0085171b          	slliw	a4,a0,0x8
    80005d34:	0c0027b7          	lui	a5,0xc002
    80005d38:	97ba                	add	a5,a5,a4
    80005d3a:	40200713          	li	a4,1026
    80005d3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d42:	00d5151b          	slliw	a0,a0,0xd
    80005d46:	0c2017b7          	lui	a5,0xc201
    80005d4a:	953e                	add	a0,a0,a5
    80005d4c:	00052023          	sw	zero,0(a0)
}
    80005d50:	60a2                	ld	ra,8(sp)
    80005d52:	6402                	ld	s0,0(sp)
    80005d54:	0141                	addi	sp,sp,16
    80005d56:	8082                	ret

0000000080005d58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d58:	1141                	addi	sp,sp,-16
    80005d5a:	e406                	sd	ra,8(sp)
    80005d5c:	e022                	sd	s0,0(sp)
    80005d5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d60:	ffffc097          	auipc	ra,0xffffc
    80005d64:	c9a080e7          	jalr	-870(ra) # 800019fa <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d68:	00d5179b          	slliw	a5,a0,0xd
    80005d6c:	0c201537          	lui	a0,0xc201
    80005d70:	953e                	add	a0,a0,a5
  return irq;
}
    80005d72:	4148                	lw	a0,4(a0)
    80005d74:	60a2                	ld	ra,8(sp)
    80005d76:	6402                	ld	s0,0(sp)
    80005d78:	0141                	addi	sp,sp,16
    80005d7a:	8082                	ret

0000000080005d7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d7c:	1101                	addi	sp,sp,-32
    80005d7e:	ec06                	sd	ra,24(sp)
    80005d80:	e822                	sd	s0,16(sp)
    80005d82:	e426                	sd	s1,8(sp)
    80005d84:	1000                	addi	s0,sp,32
    80005d86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d88:	ffffc097          	auipc	ra,0xffffc
    80005d8c:	c72080e7          	jalr	-910(ra) # 800019fa <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d90:	00d5151b          	slliw	a0,a0,0xd
    80005d94:	0c2017b7          	lui	a5,0xc201
    80005d98:	97aa                	add	a5,a5,a0
    80005d9a:	c3c4                	sw	s1,4(a5)
}
    80005d9c:	60e2                	ld	ra,24(sp)
    80005d9e:	6442                	ld	s0,16(sp)
    80005da0:	64a2                	ld	s1,8(sp)
    80005da2:	6105                	addi	sp,sp,32
    80005da4:	8082                	ret

0000000080005da6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005da6:	1141                	addi	sp,sp,-16
    80005da8:	e406                	sd	ra,8(sp)
    80005daa:	e022                	sd	s0,0(sp)
    80005dac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dae:	479d                	li	a5,7
    80005db0:	04a7cc63          	blt	a5,a0,80005e08 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005db4:	0001d797          	auipc	a5,0x1d
    80005db8:	24c78793          	addi	a5,a5,588 # 80023000 <disk>
    80005dbc:	00a78733          	add	a4,a5,a0
    80005dc0:	6789                	lui	a5,0x2
    80005dc2:	97ba                	add	a5,a5,a4
    80005dc4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005dc8:	eba1                	bnez	a5,80005e18 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005dca:	00451713          	slli	a4,a0,0x4
    80005dce:	0001f797          	auipc	a5,0x1f
    80005dd2:	2327b783          	ld	a5,562(a5) # 80025000 <disk+0x2000>
    80005dd6:	97ba                	add	a5,a5,a4
    80005dd8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005ddc:	0001d797          	auipc	a5,0x1d
    80005de0:	22478793          	addi	a5,a5,548 # 80023000 <disk>
    80005de4:	97aa                	add	a5,a5,a0
    80005de6:	6509                	lui	a0,0x2
    80005de8:	953e                	add	a0,a0,a5
    80005dea:	4785                	li	a5,1
    80005dec:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005df0:	0001f517          	auipc	a0,0x1f
    80005df4:	22850513          	addi	a0,a0,552 # 80025018 <disk+0x2018>
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	5c4080e7          	jalr	1476(ra) # 800023bc <wakeup>
}
    80005e00:	60a2                	ld	ra,8(sp)
    80005e02:	6402                	ld	s0,0(sp)
    80005e04:	0141                	addi	sp,sp,16
    80005e06:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e08:	00003517          	auipc	a0,0x3
    80005e0c:	99050513          	addi	a0,a0,-1648 # 80008798 <syscalls+0x330>
    80005e10:	ffffa097          	auipc	ra,0xffffa
    80005e14:	738080e7          	jalr	1848(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005e18:	00003517          	auipc	a0,0x3
    80005e1c:	99850513          	addi	a0,a0,-1640 # 800087b0 <syscalls+0x348>
    80005e20:	ffffa097          	auipc	ra,0xffffa
    80005e24:	728080e7          	jalr	1832(ra) # 80000548 <panic>

0000000080005e28 <virtio_disk_init>:
{
    80005e28:	1101                	addi	sp,sp,-32
    80005e2a:	ec06                	sd	ra,24(sp)
    80005e2c:	e822                	sd	s0,16(sp)
    80005e2e:	e426                	sd	s1,8(sp)
    80005e30:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e32:	00003597          	auipc	a1,0x3
    80005e36:	99658593          	addi	a1,a1,-1642 # 800087c8 <syscalls+0x360>
    80005e3a:	0001f517          	auipc	a0,0x1f
    80005e3e:	26e50513          	addi	a0,a0,622 # 800250a8 <disk+0x20a8>
    80005e42:	ffffb097          	auipc	ra,0xffffb
    80005e46:	d3e080e7          	jalr	-706(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e4a:	100017b7          	lui	a5,0x10001
    80005e4e:	4398                	lw	a4,0(a5)
    80005e50:	2701                	sext.w	a4,a4
    80005e52:	747277b7          	lui	a5,0x74727
    80005e56:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e5a:	0ef71163          	bne	a4,a5,80005f3c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e5e:	100017b7          	lui	a5,0x10001
    80005e62:	43dc                	lw	a5,4(a5)
    80005e64:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e66:	4705                	li	a4,1
    80005e68:	0ce79a63          	bne	a5,a4,80005f3c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e6c:	100017b7          	lui	a5,0x10001
    80005e70:	479c                	lw	a5,8(a5)
    80005e72:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e74:	4709                	li	a4,2
    80005e76:	0ce79363          	bne	a5,a4,80005f3c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e7a:	100017b7          	lui	a5,0x10001
    80005e7e:	47d8                	lw	a4,12(a5)
    80005e80:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e82:	554d47b7          	lui	a5,0x554d4
    80005e86:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e8a:	0af71963          	bne	a4,a5,80005f3c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8e:	100017b7          	lui	a5,0x10001
    80005e92:	4705                	li	a4,1
    80005e94:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e96:	470d                	li	a4,3
    80005e98:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e9a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e9c:	c7ffe737          	lui	a4,0xc7ffe
    80005ea0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ea4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ea6:	2701                	sext.w	a4,a4
    80005ea8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eaa:	472d                	li	a4,11
    80005eac:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eae:	473d                	li	a4,15
    80005eb0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005eb2:	6705                	lui	a4,0x1
    80005eb4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005eb6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eba:	5bdc                	lw	a5,52(a5)
    80005ebc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ebe:	c7d9                	beqz	a5,80005f4c <virtio_disk_init+0x124>
  if(max < NUM)
    80005ec0:	471d                	li	a4,7
    80005ec2:	08f77d63          	bgeu	a4,a5,80005f5c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ec6:	100014b7          	lui	s1,0x10001
    80005eca:	47a1                	li	a5,8
    80005ecc:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ece:	6609                	lui	a2,0x2
    80005ed0:	4581                	li	a1,0
    80005ed2:	0001d517          	auipc	a0,0x1d
    80005ed6:	12e50513          	addi	a0,a0,302 # 80023000 <disk>
    80005eda:	ffffb097          	auipc	ra,0xffffb
    80005ede:	e32080e7          	jalr	-462(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ee2:	0001d717          	auipc	a4,0x1d
    80005ee6:	11e70713          	addi	a4,a4,286 # 80023000 <disk>
    80005eea:	00c75793          	srli	a5,a4,0xc
    80005eee:	2781                	sext.w	a5,a5
    80005ef0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005ef2:	0001f797          	auipc	a5,0x1f
    80005ef6:	10e78793          	addi	a5,a5,270 # 80025000 <disk+0x2000>
    80005efa:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005efc:	0001d717          	auipc	a4,0x1d
    80005f00:	18470713          	addi	a4,a4,388 # 80023080 <disk+0x80>
    80005f04:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f06:	0001e717          	auipc	a4,0x1e
    80005f0a:	0fa70713          	addi	a4,a4,250 # 80024000 <disk+0x1000>
    80005f0e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f10:	4705                	li	a4,1
    80005f12:	00e78c23          	sb	a4,24(a5)
    80005f16:	00e78ca3          	sb	a4,25(a5)
    80005f1a:	00e78d23          	sb	a4,26(a5)
    80005f1e:	00e78da3          	sb	a4,27(a5)
    80005f22:	00e78e23          	sb	a4,28(a5)
    80005f26:	00e78ea3          	sb	a4,29(a5)
    80005f2a:	00e78f23          	sb	a4,30(a5)
    80005f2e:	00e78fa3          	sb	a4,31(a5)
}
    80005f32:	60e2                	ld	ra,24(sp)
    80005f34:	6442                	ld	s0,16(sp)
    80005f36:	64a2                	ld	s1,8(sp)
    80005f38:	6105                	addi	sp,sp,32
    80005f3a:	8082                	ret
    panic("could not find virtio disk");
    80005f3c:	00003517          	auipc	a0,0x3
    80005f40:	89c50513          	addi	a0,a0,-1892 # 800087d8 <syscalls+0x370>
    80005f44:	ffffa097          	auipc	ra,0xffffa
    80005f48:	604080e7          	jalr	1540(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f4c:	00003517          	auipc	a0,0x3
    80005f50:	8ac50513          	addi	a0,a0,-1876 # 800087f8 <syscalls+0x390>
    80005f54:	ffffa097          	auipc	ra,0xffffa
    80005f58:	5f4080e7          	jalr	1524(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f5c:	00003517          	auipc	a0,0x3
    80005f60:	8bc50513          	addi	a0,a0,-1860 # 80008818 <syscalls+0x3b0>
    80005f64:	ffffa097          	auipc	ra,0xffffa
    80005f68:	5e4080e7          	jalr	1508(ra) # 80000548 <panic>

0000000080005f6c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f6c:	7119                	addi	sp,sp,-128
    80005f6e:	fc86                	sd	ra,120(sp)
    80005f70:	f8a2                	sd	s0,112(sp)
    80005f72:	f4a6                	sd	s1,104(sp)
    80005f74:	f0ca                	sd	s2,96(sp)
    80005f76:	ecce                	sd	s3,88(sp)
    80005f78:	e8d2                	sd	s4,80(sp)
    80005f7a:	e4d6                	sd	s5,72(sp)
    80005f7c:	e0da                	sd	s6,64(sp)
    80005f7e:	fc5e                	sd	s7,56(sp)
    80005f80:	f862                	sd	s8,48(sp)
    80005f82:	f466                	sd	s9,40(sp)
    80005f84:	f06a                	sd	s10,32(sp)
    80005f86:	0100                	addi	s0,sp,128
    80005f88:	892a                	mv	s2,a0
    80005f8a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f8c:	00c52c83          	lw	s9,12(a0)
    80005f90:	001c9c9b          	slliw	s9,s9,0x1
    80005f94:	1c82                	slli	s9,s9,0x20
    80005f96:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f9a:	0001f517          	auipc	a0,0x1f
    80005f9e:	10e50513          	addi	a0,a0,270 # 800250a8 <disk+0x20a8>
    80005fa2:	ffffb097          	auipc	ra,0xffffb
    80005fa6:	c6e080e7          	jalr	-914(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    80005faa:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fac:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fae:	0001db97          	auipc	s7,0x1d
    80005fb2:	052b8b93          	addi	s7,s7,82 # 80023000 <disk>
    80005fb6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005fb8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005fba:	8a4e                	mv	s4,s3
    80005fbc:	a051                	j	80006040 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005fbe:	00fb86b3          	add	a3,s7,a5
    80005fc2:	96da                	add	a3,a3,s6
    80005fc4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fc8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005fca:	0207c563          	bltz	a5,80005ff4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fce:	2485                	addiw	s1,s1,1
    80005fd0:	0711                	addi	a4,a4,4
    80005fd2:	23548d63          	beq	s1,s5,8000620c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005fd6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fd8:	0001f697          	auipc	a3,0x1f
    80005fdc:	04068693          	addi	a3,a3,64 # 80025018 <disk+0x2018>
    80005fe0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fe2:	0006c583          	lbu	a1,0(a3)
    80005fe6:	fde1                	bnez	a1,80005fbe <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fe8:	2785                	addiw	a5,a5,1
    80005fea:	0685                	addi	a3,a3,1
    80005fec:	ff879be3          	bne	a5,s8,80005fe2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005ff0:	57fd                	li	a5,-1
    80005ff2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005ff4:	02905a63          	blez	s1,80006028 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ff8:	f9042503          	lw	a0,-112(s0)
    80005ffc:	00000097          	auipc	ra,0x0
    80006000:	daa080e7          	jalr	-598(ra) # 80005da6 <free_desc>
      for(int j = 0; j < i; j++)
    80006004:	4785                	li	a5,1
    80006006:	0297d163          	bge	a5,s1,80006028 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000600a:	f9442503          	lw	a0,-108(s0)
    8000600e:	00000097          	auipc	ra,0x0
    80006012:	d98080e7          	jalr	-616(ra) # 80005da6 <free_desc>
      for(int j = 0; j < i; j++)
    80006016:	4789                	li	a5,2
    80006018:	0097d863          	bge	a5,s1,80006028 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000601c:	f9842503          	lw	a0,-104(s0)
    80006020:	00000097          	auipc	ra,0x0
    80006024:	d86080e7          	jalr	-634(ra) # 80005da6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006028:	0001f597          	auipc	a1,0x1f
    8000602c:	08058593          	addi	a1,a1,128 # 800250a8 <disk+0x20a8>
    80006030:	0001f517          	auipc	a0,0x1f
    80006034:	fe850513          	addi	a0,a0,-24 # 80025018 <disk+0x2018>
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	1fe080e7          	jalr	510(ra) # 80002236 <sleep>
  for(int i = 0; i < 3; i++){
    80006040:	f9040713          	addi	a4,s0,-112
    80006044:	84ce                	mv	s1,s3
    80006046:	bf41                	j	80005fd6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006048:	4785                	li	a5,1
    8000604a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000604e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006052:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006056:	f9042983          	lw	s3,-112(s0)
    8000605a:	00499493          	slli	s1,s3,0x4
    8000605e:	0001fa17          	auipc	s4,0x1f
    80006062:	fa2a0a13          	addi	s4,s4,-94 # 80025000 <disk+0x2000>
    80006066:	000a3a83          	ld	s5,0(s4)
    8000606a:	9aa6                	add	s5,s5,s1
    8000606c:	f8040513          	addi	a0,s0,-128
    80006070:	ffffb097          	auipc	ra,0xffffb
    80006074:	02e080e7          	jalr	46(ra) # 8000109e <kvmpa>
    80006078:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000607c:	000a3783          	ld	a5,0(s4)
    80006080:	97a6                	add	a5,a5,s1
    80006082:	4741                	li	a4,16
    80006084:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006086:	000a3783          	ld	a5,0(s4)
    8000608a:	97a6                	add	a5,a5,s1
    8000608c:	4705                	li	a4,1
    8000608e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006092:	f9442703          	lw	a4,-108(s0)
    80006096:	000a3783          	ld	a5,0(s4)
    8000609a:	97a6                	add	a5,a5,s1
    8000609c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060a0:	0712                	slli	a4,a4,0x4
    800060a2:	000a3783          	ld	a5,0(s4)
    800060a6:	97ba                	add	a5,a5,a4
    800060a8:	05890693          	addi	a3,s2,88
    800060ac:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800060ae:	000a3783          	ld	a5,0(s4)
    800060b2:	97ba                	add	a5,a5,a4
    800060b4:	40000693          	li	a3,1024
    800060b8:	c794                	sw	a3,8(a5)
  if(write)
    800060ba:	100d0a63          	beqz	s10,800061ce <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060be:	0001f797          	auipc	a5,0x1f
    800060c2:	f427b783          	ld	a5,-190(a5) # 80025000 <disk+0x2000>
    800060c6:	97ba                	add	a5,a5,a4
    800060c8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060cc:	0001d517          	auipc	a0,0x1d
    800060d0:	f3450513          	addi	a0,a0,-204 # 80023000 <disk>
    800060d4:	0001f797          	auipc	a5,0x1f
    800060d8:	f2c78793          	addi	a5,a5,-212 # 80025000 <disk+0x2000>
    800060dc:	6394                	ld	a3,0(a5)
    800060de:	96ba                	add	a3,a3,a4
    800060e0:	00c6d603          	lhu	a2,12(a3)
    800060e4:	00166613          	ori	a2,a2,1
    800060e8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060ec:	f9842683          	lw	a3,-104(s0)
    800060f0:	6390                	ld	a2,0(a5)
    800060f2:	9732                	add	a4,a4,a2
    800060f4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800060f8:	20098613          	addi	a2,s3,512
    800060fc:	0612                	slli	a2,a2,0x4
    800060fe:	962a                	add	a2,a2,a0
    80006100:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006104:	00469713          	slli	a4,a3,0x4
    80006108:	6394                	ld	a3,0(a5)
    8000610a:	96ba                	add	a3,a3,a4
    8000610c:	6589                	lui	a1,0x2
    8000610e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006112:	94ae                	add	s1,s1,a1
    80006114:	94aa                	add	s1,s1,a0
    80006116:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006118:	6394                	ld	a3,0(a5)
    8000611a:	96ba                	add	a3,a3,a4
    8000611c:	4585                	li	a1,1
    8000611e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006120:	6394                	ld	a3,0(a5)
    80006122:	96ba                	add	a3,a3,a4
    80006124:	4509                	li	a0,2
    80006126:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000612a:	6394                	ld	a3,0(a5)
    8000612c:	9736                	add	a4,a4,a3
    8000612e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006132:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006136:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000613a:	6794                	ld	a3,8(a5)
    8000613c:	0026d703          	lhu	a4,2(a3)
    80006140:	8b1d                	andi	a4,a4,7
    80006142:	2709                	addiw	a4,a4,2
    80006144:	0706                	slli	a4,a4,0x1
    80006146:	9736                	add	a4,a4,a3
    80006148:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000614c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006150:	6798                	ld	a4,8(a5)
    80006152:	00275783          	lhu	a5,2(a4)
    80006156:	2785                	addiw	a5,a5,1
    80006158:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000615c:	100017b7          	lui	a5,0x10001
    80006160:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006164:	00492703          	lw	a4,4(s2)
    80006168:	4785                	li	a5,1
    8000616a:	02f71163          	bne	a4,a5,8000618c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000616e:	0001f997          	auipc	s3,0x1f
    80006172:	f3a98993          	addi	s3,s3,-198 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006176:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006178:	85ce                	mv	a1,s3
    8000617a:	854a                	mv	a0,s2
    8000617c:	ffffc097          	auipc	ra,0xffffc
    80006180:	0ba080e7          	jalr	186(ra) # 80002236 <sleep>
  while(b->disk == 1) {
    80006184:	00492783          	lw	a5,4(s2)
    80006188:	fe9788e3          	beq	a5,s1,80006178 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000618c:	f9042483          	lw	s1,-112(s0)
    80006190:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006194:	00479713          	slli	a4,a5,0x4
    80006198:	0001d797          	auipc	a5,0x1d
    8000619c:	e6878793          	addi	a5,a5,-408 # 80023000 <disk>
    800061a0:	97ba                	add	a5,a5,a4
    800061a2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061a6:	0001f917          	auipc	s2,0x1f
    800061aa:	e5a90913          	addi	s2,s2,-422 # 80025000 <disk+0x2000>
    free_desc(i);
    800061ae:	8526                	mv	a0,s1
    800061b0:	00000097          	auipc	ra,0x0
    800061b4:	bf6080e7          	jalr	-1034(ra) # 80005da6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061b8:	0492                	slli	s1,s1,0x4
    800061ba:	00093783          	ld	a5,0(s2)
    800061be:	94be                	add	s1,s1,a5
    800061c0:	00c4d783          	lhu	a5,12(s1)
    800061c4:	8b85                	andi	a5,a5,1
    800061c6:	cf89                	beqz	a5,800061e0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800061c8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800061cc:	b7cd                	j	800061ae <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ce:	0001f797          	auipc	a5,0x1f
    800061d2:	e327b783          	ld	a5,-462(a5) # 80025000 <disk+0x2000>
    800061d6:	97ba                	add	a5,a5,a4
    800061d8:	4689                	li	a3,2
    800061da:	00d79623          	sh	a3,12(a5)
    800061de:	b5fd                	j	800060cc <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061e0:	0001f517          	auipc	a0,0x1f
    800061e4:	ec850513          	addi	a0,a0,-312 # 800250a8 <disk+0x20a8>
    800061e8:	ffffb097          	auipc	ra,0xffffb
    800061ec:	adc080e7          	jalr	-1316(ra) # 80000cc4 <release>
}
    800061f0:	70e6                	ld	ra,120(sp)
    800061f2:	7446                	ld	s0,112(sp)
    800061f4:	74a6                	ld	s1,104(sp)
    800061f6:	7906                	ld	s2,96(sp)
    800061f8:	69e6                	ld	s3,88(sp)
    800061fa:	6a46                	ld	s4,80(sp)
    800061fc:	6aa6                	ld	s5,72(sp)
    800061fe:	6b06                	ld	s6,64(sp)
    80006200:	7be2                	ld	s7,56(sp)
    80006202:	7c42                	ld	s8,48(sp)
    80006204:	7ca2                	ld	s9,40(sp)
    80006206:	7d02                	ld	s10,32(sp)
    80006208:	6109                	addi	sp,sp,128
    8000620a:	8082                	ret
  if(write)
    8000620c:	e20d1ee3          	bnez	s10,80006048 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006210:	f8042023          	sw	zero,-128(s0)
    80006214:	bd2d                	j	8000604e <virtio_disk_rw+0xe2>

0000000080006216 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006216:	1101                	addi	sp,sp,-32
    80006218:	ec06                	sd	ra,24(sp)
    8000621a:	e822                	sd	s0,16(sp)
    8000621c:	e426                	sd	s1,8(sp)
    8000621e:	e04a                	sd	s2,0(sp)
    80006220:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006222:	0001f517          	auipc	a0,0x1f
    80006226:	e8650513          	addi	a0,a0,-378 # 800250a8 <disk+0x20a8>
    8000622a:	ffffb097          	auipc	ra,0xffffb
    8000622e:	9e6080e7          	jalr	-1562(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006232:	0001f717          	auipc	a4,0x1f
    80006236:	dce70713          	addi	a4,a4,-562 # 80025000 <disk+0x2000>
    8000623a:	02075783          	lhu	a5,32(a4)
    8000623e:	6b18                	ld	a4,16(a4)
    80006240:	00275683          	lhu	a3,2(a4)
    80006244:	8ebd                	xor	a3,a3,a5
    80006246:	8a9d                	andi	a3,a3,7
    80006248:	cab9                	beqz	a3,8000629e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000624a:	0001d917          	auipc	s2,0x1d
    8000624e:	db690913          	addi	s2,s2,-586 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006252:	0001f497          	auipc	s1,0x1f
    80006256:	dae48493          	addi	s1,s1,-594 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000625a:	078e                	slli	a5,a5,0x3
    8000625c:	97ba                	add	a5,a5,a4
    8000625e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006260:	20078713          	addi	a4,a5,512
    80006264:	0712                	slli	a4,a4,0x4
    80006266:	974a                	add	a4,a4,s2
    80006268:	03074703          	lbu	a4,48(a4)
    8000626c:	ef21                	bnez	a4,800062c4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000626e:	20078793          	addi	a5,a5,512
    80006272:	0792                	slli	a5,a5,0x4
    80006274:	97ca                	add	a5,a5,s2
    80006276:	7798                	ld	a4,40(a5)
    80006278:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000627c:	7788                	ld	a0,40(a5)
    8000627e:	ffffc097          	auipc	ra,0xffffc
    80006282:	13e080e7          	jalr	318(ra) # 800023bc <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006286:	0204d783          	lhu	a5,32(s1)
    8000628a:	2785                	addiw	a5,a5,1
    8000628c:	8b9d                	andi	a5,a5,7
    8000628e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006292:	6898                	ld	a4,16(s1)
    80006294:	00275683          	lhu	a3,2(a4)
    80006298:	8a9d                	andi	a3,a3,7
    8000629a:	fcf690e3          	bne	a3,a5,8000625a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000629e:	10001737          	lui	a4,0x10001
    800062a2:	533c                	lw	a5,96(a4)
    800062a4:	8b8d                	andi	a5,a5,3
    800062a6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800062a8:	0001f517          	auipc	a0,0x1f
    800062ac:	e0050513          	addi	a0,a0,-512 # 800250a8 <disk+0x20a8>
    800062b0:	ffffb097          	auipc	ra,0xffffb
    800062b4:	a14080e7          	jalr	-1516(ra) # 80000cc4 <release>
}
    800062b8:	60e2                	ld	ra,24(sp)
    800062ba:	6442                	ld	s0,16(sp)
    800062bc:	64a2                	ld	s1,8(sp)
    800062be:	6902                	ld	s2,0(sp)
    800062c0:	6105                	addi	sp,sp,32
    800062c2:	8082                	ret
      panic("virtio_disk_intr status");
    800062c4:	00002517          	auipc	a0,0x2
    800062c8:	57450513          	addi	a0,a0,1396 # 80008838 <syscalls+0x3d0>
    800062cc:	ffffa097          	auipc	ra,0xffffa
    800062d0:	27c080e7          	jalr	636(ra) # 80000548 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
