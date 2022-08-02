
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
    80000060:	ed478793          	addi	a5,a5,-300 # 80005f30 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
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
    8000012a:	176080e7          	jalr	374(ra) # 8000229c <either_copyin>
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
    800001d2:	99a080e7          	jalr	-1638(ra) # 80001b68 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	f0e080e7          	jalr	-242(ra) # 800020ec <sleep>
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
    8000021e:	02c080e7          	jalr	44(ra) # 80002246 <either_copyout>
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
    80000300:	ff6080e7          	jalr	-10(ra) # 800022f2 <procdump>
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
    80000454:	d1a080e7          	jalr	-742(ra) # 8000216a <wakeup>
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
    80000486:	72e78793          	addi	a5,a5,1838 # 80021bb0 <devsw>
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
    800008ba:	8b4080e7          	jalr	-1868(ra) # 8000216a <wakeup>
    
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
    80000950:	00001097          	auipc	ra,0x1
    80000954:	79c080e7          	jalr	1948(ra) # 800020ec <sleep>
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
    80000a38:	00026797          	auipc	a5,0x26
    80000a3c:	5e878793          	addi	a5,a5,1512 # 80027020 <end>
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
    80000b08:	00026517          	auipc	a0,0x26
    80000b0c:	51850513          	addi	a0,a0,1304 # 80027020 <end>
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
    80000bae:	fa2080e7          	jalr	-94(ra) # 80001b4c <mycpu>
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
    80000be0:	f70080e7          	jalr	-144(ra) # 80001b4c <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	f64080e7          	jalr	-156(ra) # 80001b4c <mycpu>
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
    80000c04:	f4c080e7          	jalr	-180(ra) # 80001b4c <mycpu>
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
    80000c44:	f0c080e7          	jalr	-244(ra) # 80001b4c <mycpu>
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
    80000c70:	ee0080e7          	jalr	-288(ra) # 80001b4c <mycpu>
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
    80000eca:	c76080e7          	jalr	-906(ra) # 80001b3c <cpuid>
#endif    
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
    80000ee6:	c5a080e7          	jalr	-934(ra) # 80001b3c <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0e0080e7          	jalr	224(ra) # 80000fdc <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	a2c080e7          	jalr	-1492(ra) # 80002930 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	064080e7          	jalr	100(ra) # 80005f70 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	ee0080e7          	jalr	-288(ra) # 80001df4 <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    statsinit();
    80000f24:	00006097          	auipc	ra,0x6
    80000f28:	80e080e7          	jalr	-2034(ra) # 80006732 <statsinit>
    printfinit();
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	84c080e7          	jalr	-1972(ra) # 80000778 <printfinit>
    printf("\n");
    80000f34:	00007517          	auipc	a0,0x7
    80000f38:	19450513          	addi	a0,a0,404 # 800080c8 <digits+0x88>
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	656080e7          	jalr	1622(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f44:	00007517          	auipc	a0,0x7
    80000f48:	15c50513          	addi	a0,a0,348 # 800080a0 <digits+0x60>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	646080e7          	jalr	1606(ra) # 80000592 <printf>
    printf("\n");
    80000f54:	00007517          	auipc	a0,0x7
    80000f58:	17450513          	addi	a0,a0,372 # 800080c8 <digits+0x88>
    80000f5c:	fffff097          	auipc	ra,0xfffff
    80000f60:	636080e7          	jalr	1590(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	b80080e7          	jalr	-1152(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	2aa080e7          	jalr	682(ra) # 80001216 <kvminit>
    kvminithart();   // turn on paging
    80000f74:	00000097          	auipc	ra,0x0
    80000f78:	068080e7          	jalr	104(ra) # 80000fdc <kvminithart>
    procinit();      // process table
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	af0080e7          	jalr	-1296(ra) # 80001a6c <procinit>
    trapinit();      // trap vectors
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	984080e7          	jalr	-1660(ra) # 80002908 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	9a4080e7          	jalr	-1628(ra) # 80002930 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	fc6080e7          	jalr	-58(ra) # 80005f5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	fd4080e7          	jalr	-44(ra) # 80005f70 <plicinithart>
    binit();         // buffer cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	136080e7          	jalr	310(ra) # 800030da <binit>
    iinit();         // inode cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	7c6080e7          	jalr	1990(ra) # 80003772 <iinit>
    fileinit();      // file table
    80000fb4:	00003097          	auipc	ra,0x3
    80000fb8:	760080e7          	jalr	1888(ra) # 80004714 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fbc:	00005097          	auipc	ra,0x5
    80000fc0:	0bc080e7          	jalr	188(ra) # 80006078 <virtio_disk_init>
    userinit();      // first user process
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	61a080e7          	jalr	1562(ra) # 800025de <userinit>
    __sync_synchronize();
    80000fcc:	0ff0000f          	fence
    started = 1;
    80000fd0:	4785                	li	a5,1
    80000fd2:	00008717          	auipc	a4,0x8
    80000fd6:	02f72d23          	sw	a5,58(a4) # 8000900c <started>
    80000fda:	bf2d                	j	80000f14 <main+0x56>

0000000080000fdc <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fdc:	1141                	addi	sp,sp,-16
    80000fde:	e422                	sd	s0,8(sp)
    80000fe0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe2:	00008797          	auipc	a5,0x8
    80000fe6:	02e7b783          	ld	a5,46(a5) # 80009010 <kernel_pagetable>
    80000fea:	83b1                	srli	a5,a5,0xc
    80000fec:	577d                	li	a4,-1
    80000fee:	177e                	slli	a4,a4,0x3f
    80000ff0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff6:	12000073          	sfence.vma
  sfence_vma();
}
    80000ffa:	6422                	ld	s0,8(sp)
    80000ffc:	0141                	addi	sp,sp,16
    80000ffe:	8082                	ret

0000000080001000 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001000:	7139                	addi	sp,sp,-64
    80001002:	fc06                	sd	ra,56(sp)
    80001004:	f822                	sd	s0,48(sp)
    80001006:	f426                	sd	s1,40(sp)
    80001008:	f04a                	sd	s2,32(sp)
    8000100a:	ec4e                	sd	s3,24(sp)
    8000100c:	e852                	sd	s4,16(sp)
    8000100e:	e456                	sd	s5,8(sp)
    80001010:	e05a                	sd	s6,0(sp)
    80001012:	0080                	addi	s0,sp,64
    80001014:	84aa                	mv	s1,a0
    80001016:	89ae                	mv	s3,a1
    80001018:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000101a:	57fd                	li	a5,-1
    8000101c:	83e9                	srli	a5,a5,0x1a
    8000101e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001020:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001022:	04b7f263          	bgeu	a5,a1,80001066 <walk+0x66>
    panic("walk");
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	0aa50513          	addi	a0,a0,170 # 800080d0 <digits+0x90>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	51a080e7          	jalr	1306(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001036:	060a8663          	beqz	s5,800010a2 <walk+0xa2>
    8000103a:	00000097          	auipc	ra,0x0
    8000103e:	ae6080e7          	jalr	-1306(ra) # 80000b20 <kalloc>
    80001042:	84aa                	mv	s1,a0
    80001044:	c529                	beqz	a0,8000108e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001046:	6605                	lui	a2,0x1
    80001048:	4581                	li	a1,0
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	cc2080e7          	jalr	-830(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001052:	00c4d793          	srli	a5,s1,0xc
    80001056:	07aa                	slli	a5,a5,0xa
    80001058:	0017e793          	ori	a5,a5,1
    8000105c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001060:	3a5d                	addiw	s4,s4,-9
    80001062:	036a0063          	beq	s4,s6,80001082 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001066:	0149d933          	srl	s2,s3,s4
    8000106a:	1ff97913          	andi	s2,s2,511
    8000106e:	090e                	slli	s2,s2,0x3
    80001070:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001072:	00093483          	ld	s1,0(s2)
    80001076:	0014f793          	andi	a5,s1,1
    8000107a:	dfd5                	beqz	a5,80001036 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000107c:	80a9                	srli	s1,s1,0xa
    8000107e:	04b2                	slli	s1,s1,0xc
    80001080:	b7c5                	j	80001060 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001082:	00c9d513          	srli	a0,s3,0xc
    80001086:	1ff57513          	andi	a0,a0,511
    8000108a:	050e                	slli	a0,a0,0x3
    8000108c:	9526                	add	a0,a0,s1
}
    8000108e:	70e2                	ld	ra,56(sp)
    80001090:	7442                	ld	s0,48(sp)
    80001092:	74a2                	ld	s1,40(sp)
    80001094:	7902                	ld	s2,32(sp)
    80001096:	69e2                	ld	s3,24(sp)
    80001098:	6a42                	ld	s4,16(sp)
    8000109a:	6aa2                	ld	s5,8(sp)
    8000109c:	6b02                	ld	s6,0(sp)
    8000109e:	6121                	addi	sp,sp,64
    800010a0:	8082                	ret
        return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7ed                	j	8000108e <walk+0x8e>

00000000800010a6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010a6:	57fd                	li	a5,-1
    800010a8:	83e9                	srli	a5,a5,0x1a
    800010aa:	00b7f463          	bgeu	a5,a1,800010b2 <walkaddr+0xc>
    return 0;
    800010ae:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b0:	8082                	ret
{
    800010b2:	1141                	addi	sp,sp,-16
    800010b4:	e406                	sd	ra,8(sp)
    800010b6:	e022                	sd	s0,0(sp)
    800010b8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ba:	4601                	li	a2,0
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	f44080e7          	jalr	-188(ra) # 80001000 <walk>
  if(pte == 0)
    800010c4:	c105                	beqz	a0,800010e4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010c6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c8:	0117f693          	andi	a3,a5,17
    800010cc:	4745                	li	a4,17
    return 0;
    800010ce:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d0:	00e68663          	beq	a3,a4,800010dc <walkaddr+0x36>
}
    800010d4:	60a2                	ld	ra,8(sp)
    800010d6:	6402                	ld	s0,0(sp)
    800010d8:	0141                	addi	sp,sp,16
    800010da:	8082                	ret
  pa = PTE2PA(*pte);
    800010dc:	00a7d513          	srli	a0,a5,0xa
    800010e0:	0532                	slli	a0,a0,0xc
  return pa;
    800010e2:	bfcd                	j	800010d4 <walkaddr+0x2e>
    return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7fd                	j	800010d4 <walkaddr+0x2e>

00000000800010e8 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010e8:	1101                	addi	sp,sp,-32
    800010ea:	ec06                	sd	ra,24(sp)
    800010ec:	e822                	sd	s0,16(sp)
    800010ee:	e426                	sd	s1,8(sp)
    800010f0:	e04a                	sd	s2,0(sp)
    800010f2:	1000                	addi	s0,sp,32
    800010f4:	84aa                	mv	s1,a0
  uint64 off = va % PGSIZE;
    800010f6:	1552                	slli	a0,a0,0x34
    800010f8:	03455913          	srli	s2,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(myproc()->kpagetable, va, 0);
    800010fc:	00001097          	auipc	ra,0x1
    80001100:	a6c080e7          	jalr	-1428(ra) # 80001b68 <myproc>
    80001104:	4601                	li	a2,0
    80001106:	85a6                	mv	a1,s1
    80001108:	16853503          	ld	a0,360(a0)
    8000110c:	00000097          	auipc	ra,0x0
    80001110:	ef4080e7          	jalr	-268(ra) # 80001000 <walk>
  if(pte == 0)
    80001114:	cd11                	beqz	a0,80001130 <kvmpa+0x48>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001116:	6108                	ld	a0,0(a0)
    80001118:	00157793          	andi	a5,a0,1
    8000111c:	c395                	beqz	a5,80001140 <kvmpa+0x58>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000111e:	8129                	srli	a0,a0,0xa
    80001120:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001122:	954a                	add	a0,a0,s2
    80001124:	60e2                	ld	ra,24(sp)
    80001126:	6442                	ld	s0,16(sp)
    80001128:	64a2                	ld	s1,8(sp)
    8000112a:	6902                	ld	s2,0(sp)
    8000112c:	6105                	addi	sp,sp,32
    8000112e:	8082                	ret
    panic("kvmpa");
    80001130:	00007517          	auipc	a0,0x7
    80001134:	fa850513          	addi	a0,a0,-88 # 800080d8 <digits+0x98>
    80001138:	fffff097          	auipc	ra,0xfffff
    8000113c:	410080e7          	jalr	1040(ra) # 80000548 <panic>
    panic("kvmpa");
    80001140:	00007517          	auipc	a0,0x7
    80001144:	f9850513          	addi	a0,a0,-104 # 800080d8 <digits+0x98>
    80001148:	fffff097          	auipc	ra,0xfffff
    8000114c:	400080e7          	jalr	1024(ra) # 80000548 <panic>

0000000080001150 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001150:	715d                	addi	sp,sp,-80
    80001152:	e486                	sd	ra,72(sp)
    80001154:	e0a2                	sd	s0,64(sp)
    80001156:	fc26                	sd	s1,56(sp)
    80001158:	f84a                	sd	s2,48(sp)
    8000115a:	f44e                	sd	s3,40(sp)
    8000115c:	f052                	sd	s4,32(sp)
    8000115e:	ec56                	sd	s5,24(sp)
    80001160:	e85a                	sd	s6,16(sp)
    80001162:	e45e                	sd	s7,8(sp)
    80001164:	0880                	addi	s0,sp,80
    80001166:	8aaa                	mv	s5,a0
    80001168:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000116a:	777d                	lui	a4,0xfffff
    8000116c:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001170:	167d                	addi	a2,a2,-1
    80001172:	00b609b3          	add	s3,a2,a1
    80001176:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000117a:	893e                	mv	s2,a5
    8000117c:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001180:	6b85                	lui	s7,0x1
    80001182:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001186:	4605                	li	a2,1
    80001188:	85ca                	mv	a1,s2
    8000118a:	8556                	mv	a0,s5
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	e74080e7          	jalr	-396(ra) # 80001000 <walk>
    80001194:	c51d                	beqz	a0,800011c2 <mappages+0x72>
    if(*pte & PTE_V)
    80001196:	611c                	ld	a5,0(a0)
    80001198:	8b85                	andi	a5,a5,1
    8000119a:	ef81                	bnez	a5,800011b2 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000119c:	80b1                	srli	s1,s1,0xc
    8000119e:	04aa                	slli	s1,s1,0xa
    800011a0:	0164e4b3          	or	s1,s1,s6
    800011a4:	0014e493          	ori	s1,s1,1
    800011a8:	e104                	sd	s1,0(a0)
    if(a == last)
    800011aa:	03390863          	beq	s2,s3,800011da <mappages+0x8a>
    a += PGSIZE;
    800011ae:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011b0:	bfc9                	j	80001182 <mappages+0x32>
      panic("remap");
    800011b2:	00007517          	auipc	a0,0x7
    800011b6:	f2e50513          	addi	a0,a0,-210 # 800080e0 <digits+0xa0>
    800011ba:	fffff097          	auipc	ra,0xfffff
    800011be:	38e080e7          	jalr	910(ra) # 80000548 <panic>
      return -1;
    800011c2:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011c4:	60a6                	ld	ra,72(sp)
    800011c6:	6406                	ld	s0,64(sp)
    800011c8:	74e2                	ld	s1,56(sp)
    800011ca:	7942                	ld	s2,48(sp)
    800011cc:	79a2                	ld	s3,40(sp)
    800011ce:	7a02                	ld	s4,32(sp)
    800011d0:	6ae2                	ld	s5,24(sp)
    800011d2:	6b42                	ld	s6,16(sp)
    800011d4:	6ba2                	ld	s7,8(sp)
    800011d6:	6161                	addi	sp,sp,80
    800011d8:	8082                	ret
  return 0;
    800011da:	4501                	li	a0,0
    800011dc:	b7e5                	j	800011c4 <mappages+0x74>

00000000800011de <kvmmap>:
{
    800011de:	1141                	addi	sp,sp,-16
    800011e0:	e406                	sd	ra,8(sp)
    800011e2:	e022                	sd	s0,0(sp)
    800011e4:	0800                	addi	s0,sp,16
    800011e6:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011e8:	86ae                	mv	a3,a1
    800011ea:	85aa                	mv	a1,a0
    800011ec:	00008517          	auipc	a0,0x8
    800011f0:	e2453503          	ld	a0,-476(a0) # 80009010 <kernel_pagetable>
    800011f4:	00000097          	auipc	ra,0x0
    800011f8:	f5c080e7          	jalr	-164(ra) # 80001150 <mappages>
    800011fc:	e509                	bnez	a0,80001206 <kvmmap+0x28>
}
    800011fe:	60a2                	ld	ra,8(sp)
    80001200:	6402                	ld	s0,0(sp)
    80001202:	0141                	addi	sp,sp,16
    80001204:	8082                	ret
    panic("kvmmap");
    80001206:	00007517          	auipc	a0,0x7
    8000120a:	ee250513          	addi	a0,a0,-286 # 800080e8 <digits+0xa8>
    8000120e:	fffff097          	auipc	ra,0xfffff
    80001212:	33a080e7          	jalr	826(ra) # 80000548 <panic>

0000000080001216 <kvminit>:
{
    80001216:	1101                	addi	sp,sp,-32
    80001218:	ec06                	sd	ra,24(sp)
    8000121a:	e822                	sd	s0,16(sp)
    8000121c:	e426                	sd	s1,8(sp)
    8000121e:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001220:	00000097          	auipc	ra,0x0
    80001224:	900080e7          	jalr	-1792(ra) # 80000b20 <kalloc>
    80001228:	00008797          	auipc	a5,0x8
    8000122c:	dea7b423          	sd	a0,-536(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001230:	6605                	lui	a2,0x1
    80001232:	4581                	li	a1,0
    80001234:	00000097          	auipc	ra,0x0
    80001238:	ad8080e7          	jalr	-1320(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000123c:	4699                	li	a3,6
    8000123e:	6605                	lui	a2,0x1
    80001240:	100005b7          	lui	a1,0x10000
    80001244:	10000537          	lui	a0,0x10000
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	f96080e7          	jalr	-106(ra) # 800011de <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001250:	4699                	li	a3,6
    80001252:	6605                	lui	a2,0x1
    80001254:	100015b7          	lui	a1,0x10001
    80001258:	10001537          	lui	a0,0x10001
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	f82080e7          	jalr	-126(ra) # 800011de <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001264:	4699                	li	a3,6
    80001266:	6641                	lui	a2,0x10
    80001268:	020005b7          	lui	a1,0x2000
    8000126c:	02000537          	lui	a0,0x2000
    80001270:	00000097          	auipc	ra,0x0
    80001274:	f6e080e7          	jalr	-146(ra) # 800011de <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001278:	4699                	li	a3,6
    8000127a:	00400637          	lui	a2,0x400
    8000127e:	0c0005b7          	lui	a1,0xc000
    80001282:	0c000537          	lui	a0,0xc000
    80001286:	00000097          	auipc	ra,0x0
    8000128a:	f58080e7          	jalr	-168(ra) # 800011de <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000128e:	00007497          	auipc	s1,0x7
    80001292:	d7248493          	addi	s1,s1,-654 # 80008000 <etext>
    80001296:	46a9                	li	a3,10
    80001298:	80007617          	auipc	a2,0x80007
    8000129c:	d6860613          	addi	a2,a2,-664 # 8000 <_entry-0x7fff8000>
    800012a0:	4585                	li	a1,1
    800012a2:	05fe                	slli	a1,a1,0x1f
    800012a4:	852e                	mv	a0,a1
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	f38080e7          	jalr	-200(ra) # 800011de <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012ae:	4699                	li	a3,6
    800012b0:	4645                	li	a2,17
    800012b2:	066e                	slli	a2,a2,0x1b
    800012b4:	8e05                	sub	a2,a2,s1
    800012b6:	85a6                	mv	a1,s1
    800012b8:	8526                	mv	a0,s1
    800012ba:	00000097          	auipc	ra,0x0
    800012be:	f24080e7          	jalr	-220(ra) # 800011de <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012c2:	46a9                	li	a3,10
    800012c4:	6605                	lui	a2,0x1
    800012c6:	00006597          	auipc	a1,0x6
    800012ca:	d3a58593          	addi	a1,a1,-710 # 80007000 <_trampoline>
    800012ce:	04000537          	lui	a0,0x4000
    800012d2:	157d                	addi	a0,a0,-1
    800012d4:	0532                	slli	a0,a0,0xc
    800012d6:	00000097          	auipc	ra,0x0
    800012da:	f08080e7          	jalr	-248(ra) # 800011de <kvmmap>
}
    800012de:	60e2                	ld	ra,24(sp)
    800012e0:	6442                	ld	s0,16(sp)
    800012e2:	64a2                	ld	s1,8(sp)
    800012e4:	6105                	addi	sp,sp,32
    800012e6:	8082                	ret

00000000800012e8 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012e8:	715d                	addi	sp,sp,-80
    800012ea:	e486                	sd	ra,72(sp)
    800012ec:	e0a2                	sd	s0,64(sp)
    800012ee:	fc26                	sd	s1,56(sp)
    800012f0:	f84a                	sd	s2,48(sp)
    800012f2:	f44e                	sd	s3,40(sp)
    800012f4:	f052                	sd	s4,32(sp)
    800012f6:	ec56                	sd	s5,24(sp)
    800012f8:	e85a                	sd	s6,16(sp)
    800012fa:	e45e                	sd	s7,8(sp)
    800012fc:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012fe:	03459793          	slli	a5,a1,0x34
    80001302:	e795                	bnez	a5,8000132e <uvmunmap+0x46>
    80001304:	8a2a                	mv	s4,a0
    80001306:	892e                	mv	s2,a1
    80001308:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130a:	0632                	slli	a2,a2,0xc
    8000130c:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001310:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001312:	6b05                	lui	s6,0x1
    80001314:	0735e863          	bltu	a1,s3,80001384 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001318:	60a6                	ld	ra,72(sp)
    8000131a:	6406                	ld	s0,64(sp)
    8000131c:	74e2                	ld	s1,56(sp)
    8000131e:	7942                	ld	s2,48(sp)
    80001320:	79a2                	ld	s3,40(sp)
    80001322:	7a02                	ld	s4,32(sp)
    80001324:	6ae2                	ld	s5,24(sp)
    80001326:	6b42                	ld	s6,16(sp)
    80001328:	6ba2                	ld	s7,8(sp)
    8000132a:	6161                	addi	sp,sp,80
    8000132c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000132e:	00007517          	auipc	a0,0x7
    80001332:	dc250513          	addi	a0,a0,-574 # 800080f0 <digits+0xb0>
    80001336:	fffff097          	auipc	ra,0xfffff
    8000133a:	212080e7          	jalr	530(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    8000133e:	00007517          	auipc	a0,0x7
    80001342:	dca50513          	addi	a0,a0,-566 # 80008108 <digits+0xc8>
    80001346:	fffff097          	auipc	ra,0xfffff
    8000134a:	202080e7          	jalr	514(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    8000134e:	00007517          	auipc	a0,0x7
    80001352:	dca50513          	addi	a0,a0,-566 # 80008118 <digits+0xd8>
    80001356:	fffff097          	auipc	ra,0xfffff
    8000135a:	1f2080e7          	jalr	498(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    8000135e:	00007517          	auipc	a0,0x7
    80001362:	dd250513          	addi	a0,a0,-558 # 80008130 <digits+0xf0>
    80001366:	fffff097          	auipc	ra,0xfffff
    8000136a:	1e2080e7          	jalr	482(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    8000136e:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001370:	0532                	slli	a0,a0,0xc
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	6b2080e7          	jalr	1714(ra) # 80000a24 <kfree>
    *pte = 0;
    8000137a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000137e:	995a                	add	s2,s2,s6
    80001380:	f9397ce3          	bgeu	s2,s3,80001318 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001384:	4601                	li	a2,0
    80001386:	85ca                	mv	a1,s2
    80001388:	8552                	mv	a0,s4
    8000138a:	00000097          	auipc	ra,0x0
    8000138e:	c76080e7          	jalr	-906(ra) # 80001000 <walk>
    80001392:	84aa                	mv	s1,a0
    80001394:	d54d                	beqz	a0,8000133e <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001396:	6108                	ld	a0,0(a0)
    80001398:	00157793          	andi	a5,a0,1
    8000139c:	dbcd                	beqz	a5,8000134e <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000139e:	3ff57793          	andi	a5,a0,1023
    800013a2:	fb778ee3          	beq	a5,s7,8000135e <uvmunmap+0x76>
    if(do_free){
    800013a6:	fc0a8ae3          	beqz	s5,8000137a <uvmunmap+0x92>
    800013aa:	b7d1                	j	8000136e <uvmunmap+0x86>

00000000800013ac <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013ac:	1101                	addi	sp,sp,-32
    800013ae:	ec06                	sd	ra,24(sp)
    800013b0:	e822                	sd	s0,16(sp)
    800013b2:	e426                	sd	s1,8(sp)
    800013b4:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	76a080e7          	jalr	1898(ra) # 80000b20 <kalloc>
    800013be:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013c0:	c519                	beqz	a0,800013ce <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013c2:	6605                	lui	a2,0x1
    800013c4:	4581                	li	a1,0
    800013c6:	00000097          	auipc	ra,0x0
    800013ca:	946080e7          	jalr	-1722(ra) # 80000d0c <memset>
  return pagetable;
}
    800013ce:	8526                	mv	a0,s1
    800013d0:	60e2                	ld	ra,24(sp)
    800013d2:	6442                	ld	s0,16(sp)
    800013d4:	64a2                	ld	s1,8(sp)
    800013d6:	6105                	addi	sp,sp,32
    800013d8:	8082                	ret

00000000800013da <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013da:	7179                	addi	sp,sp,-48
    800013dc:	f406                	sd	ra,40(sp)
    800013de:	f022                	sd	s0,32(sp)
    800013e0:	ec26                	sd	s1,24(sp)
    800013e2:	e84a                	sd	s2,16(sp)
    800013e4:	e44e                	sd	s3,8(sp)
    800013e6:	e052                	sd	s4,0(sp)
    800013e8:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013ea:	6785                	lui	a5,0x1
    800013ec:	04f67863          	bgeu	a2,a5,8000143c <uvminit+0x62>
    800013f0:	8a2a                	mv	s4,a0
    800013f2:	89ae                	mv	s3,a1
    800013f4:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013f6:	fffff097          	auipc	ra,0xfffff
    800013fa:	72a080e7          	jalr	1834(ra) # 80000b20 <kalloc>
    800013fe:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001400:	6605                	lui	a2,0x1
    80001402:	4581                	li	a1,0
    80001404:	00000097          	auipc	ra,0x0
    80001408:	908080e7          	jalr	-1784(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000140c:	4779                	li	a4,30
    8000140e:	86ca                	mv	a3,s2
    80001410:	6605                	lui	a2,0x1
    80001412:	4581                	li	a1,0
    80001414:	8552                	mv	a0,s4
    80001416:	00000097          	auipc	ra,0x0
    8000141a:	d3a080e7          	jalr	-710(ra) # 80001150 <mappages>
  memmove(mem, src, sz);
    8000141e:	8626                	mv	a2,s1
    80001420:	85ce                	mv	a1,s3
    80001422:	854a                	mv	a0,s2
    80001424:	00000097          	auipc	ra,0x0
    80001428:	948080e7          	jalr	-1720(ra) # 80000d6c <memmove>
}
    8000142c:	70a2                	ld	ra,40(sp)
    8000142e:	7402                	ld	s0,32(sp)
    80001430:	64e2                	ld	s1,24(sp)
    80001432:	6942                	ld	s2,16(sp)
    80001434:	69a2                	ld	s3,8(sp)
    80001436:	6a02                	ld	s4,0(sp)
    80001438:	6145                	addi	sp,sp,48
    8000143a:	8082                	ret
    panic("inituvm: more than a page");
    8000143c:	00007517          	auipc	a0,0x7
    80001440:	d0c50513          	addi	a0,a0,-756 # 80008148 <digits+0x108>
    80001444:	fffff097          	auipc	ra,0xfffff
    80001448:	104080e7          	jalr	260(ra) # 80000548 <panic>

000000008000144c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000144c:	1101                	addi	sp,sp,-32
    8000144e:	ec06                	sd	ra,24(sp)
    80001450:	e822                	sd	s0,16(sp)
    80001452:	e426                	sd	s1,8(sp)
    80001454:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001456:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001458:	00b67d63          	bgeu	a2,a1,80001472 <uvmdealloc+0x26>
    8000145c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000145e:	6785                	lui	a5,0x1
    80001460:	17fd                	addi	a5,a5,-1
    80001462:	00f60733          	add	a4,a2,a5
    80001466:	767d                	lui	a2,0xfffff
    80001468:	8f71                	and	a4,a4,a2
    8000146a:	97ae                	add	a5,a5,a1
    8000146c:	8ff1                	and	a5,a5,a2
    8000146e:	00f76863          	bltu	a4,a5,8000147e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001472:	8526                	mv	a0,s1
    80001474:	60e2                	ld	ra,24(sp)
    80001476:	6442                	ld	s0,16(sp)
    80001478:	64a2                	ld	s1,8(sp)
    8000147a:	6105                	addi	sp,sp,32
    8000147c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000147e:	8f99                	sub	a5,a5,a4
    80001480:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001482:	4685                	li	a3,1
    80001484:	0007861b          	sext.w	a2,a5
    80001488:	85ba                	mv	a1,a4
    8000148a:	00000097          	auipc	ra,0x0
    8000148e:	e5e080e7          	jalr	-418(ra) # 800012e8 <uvmunmap>
    80001492:	b7c5                	j	80001472 <uvmdealloc+0x26>

0000000080001494 <uvmalloc>:
  if(newsz < oldsz)
    80001494:	0ab66163          	bltu	a2,a1,80001536 <uvmalloc+0xa2>
{
    80001498:	7139                	addi	sp,sp,-64
    8000149a:	fc06                	sd	ra,56(sp)
    8000149c:	f822                	sd	s0,48(sp)
    8000149e:	f426                	sd	s1,40(sp)
    800014a0:	f04a                	sd	s2,32(sp)
    800014a2:	ec4e                	sd	s3,24(sp)
    800014a4:	e852                	sd	s4,16(sp)
    800014a6:	e456                	sd	s5,8(sp)
    800014a8:	0080                	addi	s0,sp,64
    800014aa:	8aaa                	mv	s5,a0
    800014ac:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014ae:	6985                	lui	s3,0x1
    800014b0:	19fd                	addi	s3,s3,-1
    800014b2:	95ce                	add	a1,a1,s3
    800014b4:	79fd                	lui	s3,0xfffff
    800014b6:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ba:	08c9f063          	bgeu	s3,a2,8000153a <uvmalloc+0xa6>
    800014be:	894e                	mv	s2,s3
    mem = kalloc();
    800014c0:	fffff097          	auipc	ra,0xfffff
    800014c4:	660080e7          	jalr	1632(ra) # 80000b20 <kalloc>
    800014c8:	84aa                	mv	s1,a0
    if(mem == 0){
    800014ca:	c51d                	beqz	a0,800014f8 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014cc:	6605                	lui	a2,0x1
    800014ce:	4581                	li	a1,0
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	83c080e7          	jalr	-1988(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014d8:	4779                	li	a4,30
    800014da:	86a6                	mv	a3,s1
    800014dc:	6605                	lui	a2,0x1
    800014de:	85ca                	mv	a1,s2
    800014e0:	8556                	mv	a0,s5
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	c6e080e7          	jalr	-914(ra) # 80001150 <mappages>
    800014ea:	e905                	bnez	a0,8000151a <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ec:	6785                	lui	a5,0x1
    800014ee:	993e                	add	s2,s2,a5
    800014f0:	fd4968e3          	bltu	s2,s4,800014c0 <uvmalloc+0x2c>
  return newsz;
    800014f4:	8552                	mv	a0,s4
    800014f6:	a809                	j	80001508 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014f8:	864e                	mv	a2,s3
    800014fa:	85ca                	mv	a1,s2
    800014fc:	8556                	mv	a0,s5
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	f4e080e7          	jalr	-178(ra) # 8000144c <uvmdealloc>
      return 0;
    80001506:	4501                	li	a0,0
}
    80001508:	70e2                	ld	ra,56(sp)
    8000150a:	7442                	ld	s0,48(sp)
    8000150c:	74a2                	ld	s1,40(sp)
    8000150e:	7902                	ld	s2,32(sp)
    80001510:	69e2                	ld	s3,24(sp)
    80001512:	6a42                	ld	s4,16(sp)
    80001514:	6aa2                	ld	s5,8(sp)
    80001516:	6121                	addi	sp,sp,64
    80001518:	8082                	ret
      kfree(mem);
    8000151a:	8526                	mv	a0,s1
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	508080e7          	jalr	1288(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001524:	864e                	mv	a2,s3
    80001526:	85ca                	mv	a1,s2
    80001528:	8556                	mv	a0,s5
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	f22080e7          	jalr	-222(ra) # 8000144c <uvmdealloc>
      return 0;
    80001532:	4501                	li	a0,0
    80001534:	bfd1                	j	80001508 <uvmalloc+0x74>
    return oldsz;
    80001536:	852e                	mv	a0,a1
}
    80001538:	8082                	ret
  return newsz;
    8000153a:	8532                	mv	a0,a2
    8000153c:	b7f1                	j	80001508 <uvmalloc+0x74>

000000008000153e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000153e:	7179                	addi	sp,sp,-48
    80001540:	f406                	sd	ra,40(sp)
    80001542:	f022                	sd	s0,32(sp)
    80001544:	ec26                	sd	s1,24(sp)
    80001546:	e84a                	sd	s2,16(sp)
    80001548:	e44e                	sd	s3,8(sp)
    8000154a:	e052                	sd	s4,0(sp)
    8000154c:	1800                	addi	s0,sp,48
    8000154e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001550:	84aa                	mv	s1,a0
    80001552:	6905                	lui	s2,0x1
    80001554:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001556:	4985                	li	s3,1
    80001558:	a821                	j	80001570 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000155a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000155c:	0532                	slli	a0,a0,0xc
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	fe0080e7          	jalr	-32(ra) # 8000153e <freewalk>
      pagetable[i] = 0;
    80001566:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000156a:	04a1                	addi	s1,s1,8
    8000156c:	03248163          	beq	s1,s2,8000158e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001570:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001572:	00f57793          	andi	a5,a0,15
    80001576:	ff3782e3          	beq	a5,s3,8000155a <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000157a:	8905                	andi	a0,a0,1
    8000157c:	d57d                	beqz	a0,8000156a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000157e:	00007517          	auipc	a0,0x7
    80001582:	bea50513          	addi	a0,a0,-1046 # 80008168 <digits+0x128>
    80001586:	fffff097          	auipc	ra,0xfffff
    8000158a:	fc2080e7          	jalr	-62(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158e:	8552                	mv	a0,s4
    80001590:	fffff097          	auipc	ra,0xfffff
    80001594:	494080e7          	jalr	1172(ra) # 80000a24 <kfree>
}
    80001598:	70a2                	ld	ra,40(sp)
    8000159a:	7402                	ld	s0,32(sp)
    8000159c:	64e2                	ld	s1,24(sp)
    8000159e:	6942                	ld	s2,16(sp)
    800015a0:	69a2                	ld	s3,8(sp)
    800015a2:	6a02                	ld	s4,0(sp)
    800015a4:	6145                	addi	sp,sp,48
    800015a6:	8082                	ret

00000000800015a8 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a8:	1101                	addi	sp,sp,-32
    800015aa:	ec06                	sd	ra,24(sp)
    800015ac:	e822                	sd	s0,16(sp)
    800015ae:	e426                	sd	s1,8(sp)
    800015b0:	1000                	addi	s0,sp,32
    800015b2:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b4:	e999                	bnez	a1,800015ca <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b6:	8526                	mv	a0,s1
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	f86080e7          	jalr	-122(ra) # 8000153e <freewalk>
}
    800015c0:	60e2                	ld	ra,24(sp)
    800015c2:	6442                	ld	s0,16(sp)
    800015c4:	64a2                	ld	s1,8(sp)
    800015c6:	6105                	addi	sp,sp,32
    800015c8:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015ca:	6605                	lui	a2,0x1
    800015cc:	167d                	addi	a2,a2,-1
    800015ce:	962e                	add	a2,a2,a1
    800015d0:	4685                	li	a3,1
    800015d2:	8231                	srli	a2,a2,0xc
    800015d4:	4581                	li	a1,0
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	d12080e7          	jalr	-750(ra) # 800012e8 <uvmunmap>
    800015de:	bfe1                	j	800015b6 <uvmfree+0xe>

00000000800015e0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015e0:	c679                	beqz	a2,800016ae <uvmcopy+0xce>
{
    800015e2:	715d                	addi	sp,sp,-80
    800015e4:	e486                	sd	ra,72(sp)
    800015e6:	e0a2                	sd	s0,64(sp)
    800015e8:	fc26                	sd	s1,56(sp)
    800015ea:	f84a                	sd	s2,48(sp)
    800015ec:	f44e                	sd	s3,40(sp)
    800015ee:	f052                	sd	s4,32(sp)
    800015f0:	ec56                	sd	s5,24(sp)
    800015f2:	e85a                	sd	s6,16(sp)
    800015f4:	e45e                	sd	s7,8(sp)
    800015f6:	0880                	addi	s0,sp,80
    800015f8:	8b2a                	mv	s6,a0
    800015fa:	8aae                	mv	s5,a1
    800015fc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fe:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001600:	4601                	li	a2,0
    80001602:	85ce                	mv	a1,s3
    80001604:	855a                	mv	a0,s6
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	9fa080e7          	jalr	-1542(ra) # 80001000 <walk>
    8000160e:	c531                	beqz	a0,8000165a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001610:	6118                	ld	a4,0(a0)
    80001612:	00177793          	andi	a5,a4,1
    80001616:	cbb1                	beqz	a5,8000166a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001618:	00a75593          	srli	a1,a4,0xa
    8000161c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001620:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	4fc080e7          	jalr	1276(ra) # 80000b20 <kalloc>
    8000162c:	892a                	mv	s2,a0
    8000162e:	c939                	beqz	a0,80001684 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001630:	6605                	lui	a2,0x1
    80001632:	85de                	mv	a1,s7
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	738080e7          	jalr	1848(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163c:	8726                	mv	a4,s1
    8000163e:	86ca                	mv	a3,s2
    80001640:	6605                	lui	a2,0x1
    80001642:	85ce                	mv	a1,s3
    80001644:	8556                	mv	a0,s5
    80001646:	00000097          	auipc	ra,0x0
    8000164a:	b0a080e7          	jalr	-1270(ra) # 80001150 <mappages>
    8000164e:	e515                	bnez	a0,8000167a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001650:	6785                	lui	a5,0x1
    80001652:	99be                	add	s3,s3,a5
    80001654:	fb49e6e3          	bltu	s3,s4,80001600 <uvmcopy+0x20>
    80001658:	a081                	j	80001698 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000165a:	00007517          	auipc	a0,0x7
    8000165e:	b1e50513          	addi	a0,a0,-1250 # 80008178 <digits+0x138>
    80001662:	fffff097          	auipc	ra,0xfffff
    80001666:	ee6080e7          	jalr	-282(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b2e50513          	addi	a0,a0,-1234 # 80008198 <digits+0x158>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ed6080e7          	jalr	-298(ra) # 80000548 <panic>
      kfree(mem);
    8000167a:	854a                	mv	a0,s2
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	3a8080e7          	jalr	936(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001684:	4685                	li	a3,1
    80001686:	00c9d613          	srli	a2,s3,0xc
    8000168a:	4581                	li	a1,0
    8000168c:	8556                	mv	a0,s5
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	c5a080e7          	jalr	-934(ra) # 800012e8 <uvmunmap>
  return -1;
    80001696:	557d                	li	a0,-1
}
    80001698:	60a6                	ld	ra,72(sp)
    8000169a:	6406                	ld	s0,64(sp)
    8000169c:	74e2                	ld	s1,56(sp)
    8000169e:	7942                	ld	s2,48(sp)
    800016a0:	79a2                	ld	s3,40(sp)
    800016a2:	7a02                	ld	s4,32(sp)
    800016a4:	6ae2                	ld	s5,24(sp)
    800016a6:	6b42                	ld	s6,16(sp)
    800016a8:	6ba2                	ld	s7,8(sp)
    800016aa:	6161                	addi	sp,sp,80
    800016ac:	8082                	ret
  return 0;
    800016ae:	4501                	li	a0,0
}
    800016b0:	8082                	ret

00000000800016b2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016b2:	1141                	addi	sp,sp,-16
    800016b4:	e406                	sd	ra,8(sp)
    800016b6:	e022                	sd	s0,0(sp)
    800016b8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016ba:	4601                	li	a2,0
    800016bc:	00000097          	auipc	ra,0x0
    800016c0:	944080e7          	jalr	-1724(ra) # 80001000 <walk>
  if(pte == 0)
    800016c4:	c901                	beqz	a0,800016d4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c6:	611c                	ld	a5,0(a0)
    800016c8:	9bbd                	andi	a5,a5,-17
    800016ca:	e11c                	sd	a5,0(a0)
}
    800016cc:	60a2                	ld	ra,8(sp)
    800016ce:	6402                	ld	s0,0(sp)
    800016d0:	0141                	addi	sp,sp,16
    800016d2:	8082                	ret
    panic("uvmclear");
    800016d4:	00007517          	auipc	a0,0x7
    800016d8:	ae450513          	addi	a0,a0,-1308 # 800081b8 <digits+0x178>
    800016dc:	fffff097          	auipc	ra,0xfffff
    800016e0:	e6c080e7          	jalr	-404(ra) # 80000548 <panic>

00000000800016e4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e4:	c6bd                	beqz	a3,80001752 <copyout+0x6e>
{
    800016e6:	715d                	addi	sp,sp,-80
    800016e8:	e486                	sd	ra,72(sp)
    800016ea:	e0a2                	sd	s0,64(sp)
    800016ec:	fc26                	sd	s1,56(sp)
    800016ee:	f84a                	sd	s2,48(sp)
    800016f0:	f44e                	sd	s3,40(sp)
    800016f2:	f052                	sd	s4,32(sp)
    800016f4:	ec56                	sd	s5,24(sp)
    800016f6:	e85a                	sd	s6,16(sp)
    800016f8:	e45e                	sd	s7,8(sp)
    800016fa:	e062                	sd	s8,0(sp)
    800016fc:	0880                	addi	s0,sp,80
    800016fe:	8b2a                	mv	s6,a0
    80001700:	8c2e                	mv	s8,a1
    80001702:	8a32                	mv	s4,a2
    80001704:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001706:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001708:	6a85                	lui	s5,0x1
    8000170a:	a015                	j	8000172e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000170c:	9562                	add	a0,a0,s8
    8000170e:	0004861b          	sext.w	a2,s1
    80001712:	85d2                	mv	a1,s4
    80001714:	41250533          	sub	a0,a0,s2
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	654080e7          	jalr	1620(ra) # 80000d6c <memmove>

    len -= n;
    80001720:	409989b3          	sub	s3,s3,s1
    src += n;
    80001724:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001726:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172a:	02098263          	beqz	s3,8000174e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001732:	85ca                	mv	a1,s2
    80001734:	855a                	mv	a0,s6
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	970080e7          	jalr	-1680(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000173e:	cd01                	beqz	a0,80001756 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001740:	418904b3          	sub	s1,s2,s8
    80001744:	94d6                	add	s1,s1,s5
    if(n > len)
    80001746:	fc99f3e3          	bgeu	s3,s1,8000170c <copyout+0x28>
    8000174a:	84ce                	mv	s1,s3
    8000174c:	b7c1                	j	8000170c <copyout+0x28>
  }
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	a021                	j	80001758 <copyout+0x74>
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret
      return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6c02                	ld	s8,0(sp)
    8000176c:	6161                	addi	sp,sp,80
    8000176e:	8082                	ret

0000000080001770 <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80001770:	1141                	addi	sp,sp,-16
    80001772:	e406                	sd	ra,8(sp)
    80001774:	e022                	sd	s0,0(sp)
    80001776:	0800                	addi	s0,sp,16
  return copyin_new(pagetable,dst,srcva,len);
    80001778:	00005097          	auipc	ra,0x5
    8000177c:	e08080e7          	jalr	-504(ra) # 80006580 <copyin_new>
}
    80001780:	60a2                	ld	ra,8(sp)
    80001782:	6402                	ld	s0,0(sp)
    80001784:	0141                	addi	sp,sp,16
    80001786:	8082                	ret

0000000080001788 <copyinstr>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80001788:	1141                	addi	sp,sp,-16
    8000178a:	e406                	sd	ra,8(sp)
    8000178c:	e022                	sd	s0,0(sp)
    8000178e:	0800                	addi	s0,sp,16
  return copyinstr_new(pagetable,dst,srcva,max);
    80001790:	00005097          	auipc	ra,0x5
    80001794:	e58080e7          	jalr	-424(ra) # 800065e8 <copyinstr_new>
}
    80001798:	60a2                	ld	ra,8(sp)
    8000179a:	6402                	ld	s0,0(sp)
    8000179c:	0141                	addi	sp,sp,16
    8000179e:	8082                	ret

00000000800017a0 <_vmprint>:


void _vmprint(pagetable_t pagetable, int level) {
    800017a0:	7159                	addi	sp,sp,-112
    800017a2:	f486                	sd	ra,104(sp)
    800017a4:	f0a2                	sd	s0,96(sp)
    800017a6:	eca6                	sd	s1,88(sp)
    800017a8:	e8ca                	sd	s2,80(sp)
    800017aa:	e4ce                	sd	s3,72(sp)
    800017ac:	e0d2                	sd	s4,64(sp)
    800017ae:	fc56                	sd	s5,56(sp)
    800017b0:	f85a                	sd	s6,48(sp)
    800017b2:	f45e                	sd	s7,40(sp)
    800017b4:	f062                	sd	s8,32(sp)
    800017b6:	ec66                	sd	s9,24(sp)
    800017b8:	e86a                	sd	s10,16(sp)
    800017ba:	e46e                	sd	s11,8(sp)
    800017bc:	1880                	addi	s0,sp,112
    800017be:	8aae                	mv	s5,a1
  for (int i = 0; i < 512; i++) {
    800017c0:	8a2a                	mv	s4,a0
    800017c2:	4981                	li	s3,0
    pte_t pte = pagetable[i];
	if (pte & PTE_V) {
      uint64 pa = PTE2PA(pte);
      for (int j = 0; j < level; j++) {
		if (j) printf(" ");
		printf("..");
    800017c4:	00007b17          	auipc	s6,0x7
    800017c8:	a0cb0b13          	addi	s6,s6,-1524 # 800081d0 <digits+0x190>
		if (j) printf(" ");
    800017cc:	00007c17          	auipc	s8,0x7
    800017d0:	9fcc0c13          	addi	s8,s8,-1540 # 800081c8 <digits+0x188>
	  }
	  printf("%d: pte %p pa %p\n", i, pte, pa);
    800017d4:	00007d17          	auipc	s10,0x7
    800017d8:	a04d0d13          	addi	s10,s10,-1532 # 800081d8 <digits+0x198>
	  if ((pte & (PTE_R | PTE_W | PTE_X)) == 0) {
	    _vmprint((pagetable_t)pa, level+1);
    800017dc:	00158d9b          	addiw	s11,a1,1
  for (int i = 0; i < 512; i++) {
    800017e0:	20000c93          	li	s9,512
    800017e4:	a081                	j	80001824 <_vmprint+0x84>
		if (j) printf(" ");
    800017e6:	8562                	mv	a0,s8
    800017e8:	fffff097          	auipc	ra,0xfffff
    800017ec:	daa080e7          	jalr	-598(ra) # 80000592 <printf>
		printf("..");
    800017f0:	855a                	mv	a0,s6
    800017f2:	fffff097          	auipc	ra,0xfffff
    800017f6:	da0080e7          	jalr	-608(ra) # 80000592 <printf>
      for (int j = 0; j < level; j++) {
    800017fa:	2485                	addiw	s1,s1,1
    800017fc:	009a8463          	beq	s5,s1,80001804 <_vmprint+0x64>
		if (j) printf(" ");
    80001800:	f0fd                	bnez	s1,800017e6 <_vmprint+0x46>
    80001802:	b7fd                	j	800017f0 <_vmprint+0x50>
	  printf("%d: pte %p pa %p\n", i, pte, pa);
    80001804:	86de                	mv	a3,s7
    80001806:	864a                	mv	a2,s2
    80001808:	85ce                	mv	a1,s3
    8000180a:	856a                	mv	a0,s10
    8000180c:	fffff097          	auipc	ra,0xfffff
    80001810:	d86080e7          	jalr	-634(ra) # 80000592 <printf>
	  if ((pte & (PTE_R | PTE_W | PTE_X)) == 0) {
    80001814:	00e97913          	andi	s2,s2,14
    80001818:	02090263          	beqz	s2,8000183c <_vmprint+0x9c>
  for (int i = 0; i < 512; i++) {
    8000181c:	2985                	addiw	s3,s3,1
    8000181e:	0a21                	addi	s4,s4,8
    80001820:	03998563          	beq	s3,s9,8000184a <_vmprint+0xaa>
    pte_t pte = pagetable[i];
    80001824:	000a3903          	ld	s2,0(s4) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
	if (pte & PTE_V) {
    80001828:	00197793          	andi	a5,s2,1
    8000182c:	dbe5                	beqz	a5,8000181c <_vmprint+0x7c>
      uint64 pa = PTE2PA(pte);
    8000182e:	00a95b93          	srli	s7,s2,0xa
    80001832:	0bb2                	slli	s7,s7,0xc
      for (int j = 0; j < level; j++) {
    80001834:	4481                	li	s1,0
    80001836:	fb504de3          	bgtz	s5,800017f0 <_vmprint+0x50>
    8000183a:	b7e9                	j	80001804 <_vmprint+0x64>
	    _vmprint((pagetable_t)pa, level+1);
    8000183c:	85ee                	mv	a1,s11
    8000183e:	855e                	mv	a0,s7
    80001840:	00000097          	auipc	ra,0x0
    80001844:	f60080e7          	jalr	-160(ra) # 800017a0 <_vmprint>
    80001848:	bfd1                	j	8000181c <_vmprint+0x7c>
	  }
	}
  }
}
    8000184a:	70a6                	ld	ra,104(sp)
    8000184c:	7406                	ld	s0,96(sp)
    8000184e:	64e6                	ld	s1,88(sp)
    80001850:	6946                	ld	s2,80(sp)
    80001852:	69a6                	ld	s3,72(sp)
    80001854:	6a06                	ld	s4,64(sp)
    80001856:	7ae2                	ld	s5,56(sp)
    80001858:	7b42                	ld	s6,48(sp)
    8000185a:	7ba2                	ld	s7,40(sp)
    8000185c:	7c02                	ld	s8,32(sp)
    8000185e:	6ce2                	ld	s9,24(sp)
    80001860:	6d42                	ld	s10,16(sp)
    80001862:	6da2                	ld	s11,8(sp)
    80001864:	6165                	addi	sp,sp,112
    80001866:	8082                	ret

0000000080001868 <vmprint>:

void vmprint(pagetable_t pagetable) {
    80001868:	1101                	addi	sp,sp,-32
    8000186a:	ec06                	sd	ra,24(sp)
    8000186c:	e822                	sd	s0,16(sp)
    8000186e:	e426                	sd	s1,8(sp)
    80001870:	1000                	addi	s0,sp,32
    80001872:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    80001874:	85aa                	mv	a1,a0
    80001876:	00007517          	auipc	a0,0x7
    8000187a:	97a50513          	addi	a0,a0,-1670 # 800081f0 <digits+0x1b0>
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	d14080e7          	jalr	-748(ra) # 80000592 <printf>
  _vmprint(pagetable, 1);
    80001886:	4585                	li	a1,1
    80001888:	8526                	mv	a0,s1
    8000188a:	00000097          	auipc	ra,0x0
    8000188e:	f16080e7          	jalr	-234(ra) # 800017a0 <_vmprint>
}
    80001892:	60e2                	ld	ra,24(sp)
    80001894:	6442                	ld	s0,16(sp)
    80001896:	64a2                	ld	s1,8(sp)
    80001898:	6105                	addi	sp,sp,32
    8000189a:	8082                	ret

000000008000189c <ukvmmap>:

void ukvmmap(pagetable_t kpagetable, uint64 va, uint64 pa, uint64 sz, int perm)
{
    8000189c:	1141                	addi	sp,sp,-16
    8000189e:	e406                	sd	ra,8(sp)
    800018a0:	e022                	sd	s0,0(sp)
    800018a2:	0800                	addi	s0,sp,16
    800018a4:	87b6                	mv	a5,a3
  if (mappages(kpagetable, va, sz, pa, perm) != 0)
    800018a6:	86b2                	mv	a3,a2
    800018a8:	863e                	mv	a2,a5
    800018aa:	00000097          	auipc	ra,0x0
    800018ae:	8a6080e7          	jalr	-1882(ra) # 80001150 <mappages>
    800018b2:	e509                	bnez	a0,800018bc <ukvmmap+0x20>
    panic("uvmmap");
}
    800018b4:	60a2                	ld	ra,8(sp)
    800018b6:	6402                	ld	s0,0(sp)
    800018b8:	0141                	addi	sp,sp,16
    800018ba:	8082                	ret
    panic("uvmmap");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	94450513          	addi	a0,a0,-1724 # 80008200 <digits+0x1c0>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c84080e7          	jalr	-892(ra) # 80000548 <panic>

00000000800018cc <ukvminit>:

pagetable_t ukvminit() {
    800018cc:	1101                	addi	sp,sp,-32
    800018ce:	ec06                	sd	ra,24(sp)
    800018d0:	e822                	sd	s0,16(sp)
    800018d2:	e426                	sd	s1,8(sp)
    800018d4:	e04a                	sd	s2,0(sp)
    800018d6:	1000                	addi	s0,sp,32
  pagetable_t kpagetable = (pagetable_t) kalloc();
    800018d8:	fffff097          	auipc	ra,0xfffff
    800018dc:	248080e7          	jalr	584(ra) # 80000b20 <kalloc>
    800018e0:	84aa                	mv	s1,a0
  memset(kpagetable, 0, PGSIZE);
    800018e2:	6605                	lui	a2,0x1
    800018e4:	4581                	li	a1,0
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	426080e7          	jalr	1062(ra) # 80000d0c <memset>
  ukvmmap(kpagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800018ee:	4719                	li	a4,6
    800018f0:	6685                	lui	a3,0x1
    800018f2:	10000637          	lui	a2,0x10000
    800018f6:	100005b7          	lui	a1,0x10000
    800018fa:	8526                	mv	a0,s1
    800018fc:	00000097          	auipc	ra,0x0
    80001900:	fa0080e7          	jalr	-96(ra) # 8000189c <ukvmmap>
  ukvmmap(kpagetable, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001904:	4719                	li	a4,6
    80001906:	6685                	lui	a3,0x1
    80001908:	10001637          	lui	a2,0x10001
    8000190c:	100015b7          	lui	a1,0x10001
    80001910:	8526                	mv	a0,s1
    80001912:	00000097          	auipc	ra,0x0
    80001916:	f8a080e7          	jalr	-118(ra) # 8000189c <ukvmmap>
  ukvmmap(kpagetable, CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000191a:	4719                	li	a4,6
    8000191c:	66c1                	lui	a3,0x10
    8000191e:	02000637          	lui	a2,0x2000
    80001922:	020005b7          	lui	a1,0x2000
    80001926:	8526                	mv	a0,s1
    80001928:	00000097          	auipc	ra,0x0
    8000192c:	f74080e7          	jalr	-140(ra) # 8000189c <ukvmmap>
  ukvmmap(kpagetable, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001930:	4719                	li	a4,6
    80001932:	004006b7          	lui	a3,0x400
    80001936:	0c000637          	lui	a2,0xc000
    8000193a:	0c0005b7          	lui	a1,0xc000
    8000193e:	8526                	mv	a0,s1
    80001940:	00000097          	auipc	ra,0x0
    80001944:	f5c080e7          	jalr	-164(ra) # 8000189c <ukvmmap>
  ukvmmap(kpagetable, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001948:	00006917          	auipc	s2,0x6
    8000194c:	6b890913          	addi	s2,s2,1720 # 80008000 <etext>
    80001950:	4729                	li	a4,10
    80001952:	80006697          	auipc	a3,0x80006
    80001956:	6ae68693          	addi	a3,a3,1710 # 8000 <_entry-0x7fff8000>
    8000195a:	4605                	li	a2,1
    8000195c:	067e                	slli	a2,a2,0x1f
    8000195e:	85b2                	mv	a1,a2
    80001960:	8526                	mv	a0,s1
    80001962:	00000097          	auipc	ra,0x0
    80001966:	f3a080e7          	jalr	-198(ra) # 8000189c <ukvmmap>
  ukvmmap(kpagetable, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000196a:	4719                	li	a4,6
    8000196c:	46c5                	li	a3,17
    8000196e:	06ee                	slli	a3,a3,0x1b
    80001970:	412686b3          	sub	a3,a3,s2
    80001974:	864a                	mv	a2,s2
    80001976:	85ca                	mv	a1,s2
    80001978:	8526                	mv	a0,s1
    8000197a:	00000097          	auipc	ra,0x0
    8000197e:	f22080e7          	jalr	-222(ra) # 8000189c <ukvmmap>
  ukvmmap(kpagetable, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001982:	4729                	li	a4,10
    80001984:	6685                	lui	a3,0x1
    80001986:	00005617          	auipc	a2,0x5
    8000198a:	67a60613          	addi	a2,a2,1658 # 80007000 <_trampoline>
    8000198e:	040005b7          	lui	a1,0x4000
    80001992:	15fd                	addi	a1,a1,-1
    80001994:	05b2                	slli	a1,a1,0xc
    80001996:	8526                	mv	a0,s1
    80001998:	00000097          	auipc	ra,0x0
    8000199c:	f04080e7          	jalr	-252(ra) # 8000189c <ukvmmap>
  return kpagetable;
}
    800019a0:	8526                	mv	a0,s1
    800019a2:	60e2                	ld	ra,24(sp)
    800019a4:	6442                	ld	s0,16(sp)
    800019a6:	64a2                	ld	s1,8(sp)
    800019a8:	6902                	ld	s2,0(sp)
    800019aa:	6105                	addi	sp,sp,32
    800019ac:	8082                	ret

00000000800019ae <vmcopypage>:

void vmcopypage(pagetable_t pagetable, pagetable_t kpagetable, uint64 start, uint64 sz)
{
    800019ae:	7139                	addi	sp,sp,-64
    800019b0:	fc06                	sd	ra,56(sp)
    800019b2:	f822                	sd	s0,48(sp)
    800019b4:	f426                	sd	s1,40(sp)
    800019b6:	f04a                	sd	s2,32(sp)
    800019b8:	ec4e                	sd	s3,24(sp)
    800019ba:	e852                	sd	s4,16(sp)
    800019bc:	e456                	sd	s5,8(sp)
    800019be:	e05a                	sd	s6,0(sp)
    800019c0:	0080                	addi	s0,sp,64
  for (uint64 i = start; i < start + sz; i += PGSIZE)
    800019c2:	00d609b3          	add	s3,a2,a3
    800019c6:	03367f63          	bgeu	a2,s3,80001a04 <vmcopypage+0x56>
    800019ca:	8a2a                	mv	s4,a0
    800019cc:	8aae                	mv	s5,a1
    800019ce:	84b2                	mv	s1,a2
    800019d0:	6b05                	lui	s6,0x1
  {
    pte_t *pte = walk(pagetable, i, 0);
    800019d2:	4601                	li	a2,0
    800019d4:	85a6                	mv	a1,s1
    800019d6:	8552                	mv	a0,s4
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	628080e7          	jalr	1576(ra) # 80001000 <walk>
    800019e0:	892a                	mv	s2,a0
    pte_t *kpte = walk(kpagetable, i, 1);
    800019e2:	4605                	li	a2,1
    800019e4:	85a6                	mv	a1,s1
    800019e6:	8556                	mv	a0,s5
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	618080e7          	jalr	1560(ra) # 80001000 <walk>
    if (!pte || !kpte)
    800019f0:	02090463          	beqz	s2,80001a18 <vmcopypage+0x6a>
    800019f4:	c115                	beqz	a0,80001a18 <vmcopypage+0x6a>
    {
      panic("vmcopypage");
    }
    *kpte = (*pte) & ~(PTE_U | PTE_W | PTE_X);
    800019f6:	00093783          	ld	a5,0(s2)
    800019fa:	9b8d                	andi	a5,a5,-29
    800019fc:	e11c                	sd	a5,0(a0)
  for (uint64 i = start; i < start + sz; i += PGSIZE)
    800019fe:	94da                	add	s1,s1,s6
    80001a00:	fd34e9e3          	bltu	s1,s3,800019d2 <vmcopypage+0x24>
  }
}
    80001a04:	70e2                	ld	ra,56(sp)
    80001a06:	7442                	ld	s0,48(sp)
    80001a08:	74a2                	ld	s1,40(sp)
    80001a0a:	7902                	ld	s2,32(sp)
    80001a0c:	69e2                	ld	s3,24(sp)
    80001a0e:	6a42                	ld	s4,16(sp)
    80001a10:	6aa2                	ld	s5,8(sp)
    80001a12:	6b02                	ld	s6,0(sp)
    80001a14:	6121                	addi	sp,sp,64
    80001a16:	8082                	ret
      panic("vmcopypage");
    80001a18:	00006517          	auipc	a0,0x6
    80001a1c:	7f050513          	addi	a0,a0,2032 # 80008208 <digits+0x1c8>
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	b28080e7          	jalr	-1240(ra) # 80000548 <panic>

0000000080001a28 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001a28:	1101                	addi	sp,sp,-32
    80001a2a:	ec06                	sd	ra,24(sp)
    80001a2c:	e822                	sd	s0,16(sp)
    80001a2e:	e426                	sd	s1,8(sp)
    80001a30:	1000                	addi	s0,sp,32
    80001a32:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001a34:	fffff097          	auipc	ra,0xfffff
    80001a38:	162080e7          	jalr	354(ra) # 80000b96 <holding>
    80001a3c:	c909                	beqz	a0,80001a4e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001a3e:	749c                	ld	a5,40(s1)
    80001a40:	00978f63          	beq	a5,s1,80001a5e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001a44:	60e2                	ld	ra,24(sp)
    80001a46:	6442                	ld	s0,16(sp)
    80001a48:	64a2                	ld	s1,8(sp)
    80001a4a:	6105                	addi	sp,sp,32
    80001a4c:	8082                	ret
    panic("wakeup1");
    80001a4e:	00006517          	auipc	a0,0x6
    80001a52:	7ca50513          	addi	a0,a0,1994 # 80008218 <digits+0x1d8>
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	af2080e7          	jalr	-1294(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001a5e:	4c98                	lw	a4,24(s1)
    80001a60:	4785                	li	a5,1
    80001a62:	fef711e3          	bne	a4,a5,80001a44 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001a66:	4789                	li	a5,2
    80001a68:	cc9c                	sw	a5,24(s1)
}
    80001a6a:	bfe9                	j	80001a44 <wakeup1+0x1c>

0000000080001a6c <procinit>:
{
    80001a6c:	715d                	addi	sp,sp,-80
    80001a6e:	e486                	sd	ra,72(sp)
    80001a70:	e0a2                	sd	s0,64(sp)
    80001a72:	fc26                	sd	s1,56(sp)
    80001a74:	f84a                	sd	s2,48(sp)
    80001a76:	f44e                	sd	s3,40(sp)
    80001a78:	f052                	sd	s4,32(sp)
    80001a7a:	ec56                	sd	s5,24(sp)
    80001a7c:	e85a                	sd	s6,16(sp)
    80001a7e:	e45e                	sd	s7,8(sp)
    80001a80:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001a82:	00006597          	auipc	a1,0x6
    80001a86:	79e58593          	addi	a1,a1,1950 # 80008220 <digits+0x1e0>
    80001a8a:	00010517          	auipc	a0,0x10
    80001a8e:	ec650513          	addi	a0,a0,-314 # 80011950 <pid_lock>
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	0ee080e7          	jalr	238(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a9a:	00010917          	auipc	s2,0x10
    80001a9e:	2ce90913          	addi	s2,s2,718 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001aa2:	00006b97          	auipc	s7,0x6
    80001aa6:	786b8b93          	addi	s7,s7,1926 # 80008228 <digits+0x1e8>
      uint64 va = KSTACK((int) (p - proc));
    80001aaa:	8b4a                	mv	s6,s2
    80001aac:	00006a97          	auipc	s5,0x6
    80001ab0:	554a8a93          	addi	s5,s5,1364 # 80008000 <etext>
    80001ab4:	040009b7          	lui	s3,0x4000
    80001ab8:	19fd                	addi	s3,s3,-1
    80001aba:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001abc:	00016a17          	auipc	s4,0x16
    80001ac0:	eaca0a13          	addi	s4,s4,-340 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    80001ac4:	85de                	mv	a1,s7
    80001ac6:	854a                	mv	a0,s2
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	0b8080e7          	jalr	184(ra) # 80000b80 <initlock>
      char *pa = kalloc();
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	050080e7          	jalr	80(ra) # 80000b20 <kalloc>
    80001ad8:	85aa                	mv	a1,a0
      if(pa == 0)
    80001ada:	c929                	beqz	a0,80001b2c <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001adc:	416904b3          	sub	s1,s2,s6
    80001ae0:	8491                	srai	s1,s1,0x4
    80001ae2:	000ab783          	ld	a5,0(s5)
    80001ae6:	02f484b3          	mul	s1,s1,a5
    80001aea:	2485                	addiw	s1,s1,1
    80001aec:	00d4949b          	slliw	s1,s1,0xd
    80001af0:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001af4:	4699                	li	a3,6
    80001af6:	6605                	lui	a2,0x1
    80001af8:	8526                	mv	a0,s1
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	6e4080e7          	jalr	1764(ra) # 800011de <kvmmap>
      p->kstack = va;
    80001b02:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b06:	17090913          	addi	s2,s2,368
    80001b0a:	fb491de3          	bne	s2,s4,80001ac4 <procinit+0x58>
  kvminithart();
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	4ce080e7          	jalr	1230(ra) # 80000fdc <kvminithart>
}
    80001b16:	60a6                	ld	ra,72(sp)
    80001b18:	6406                	ld	s0,64(sp)
    80001b1a:	74e2                	ld	s1,56(sp)
    80001b1c:	7942                	ld	s2,48(sp)
    80001b1e:	79a2                	ld	s3,40(sp)
    80001b20:	7a02                	ld	s4,32(sp)
    80001b22:	6ae2                	ld	s5,24(sp)
    80001b24:	6b42                	ld	s6,16(sp)
    80001b26:	6ba2                	ld	s7,8(sp)
    80001b28:	6161                	addi	sp,sp,80
    80001b2a:	8082                	ret
        panic("kalloc");
    80001b2c:	00006517          	auipc	a0,0x6
    80001b30:	70450513          	addi	a0,a0,1796 # 80008230 <digits+0x1f0>
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	a14080e7          	jalr	-1516(ra) # 80000548 <panic>

0000000080001b3c <cpuid>:
{
    80001b3c:	1141                	addi	sp,sp,-16
    80001b3e:	e422                	sd	s0,8(sp)
    80001b40:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b42:	8512                	mv	a0,tp
}
    80001b44:	2501                	sext.w	a0,a0
    80001b46:	6422                	ld	s0,8(sp)
    80001b48:	0141                	addi	sp,sp,16
    80001b4a:	8082                	ret

0000000080001b4c <mycpu>:
mycpu(void) {
    80001b4c:	1141                	addi	sp,sp,-16
    80001b4e:	e422                	sd	s0,8(sp)
    80001b50:	0800                	addi	s0,sp,16
    80001b52:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001b54:	2781                	sext.w	a5,a5
    80001b56:	079e                	slli	a5,a5,0x7
}
    80001b58:	00010517          	auipc	a0,0x10
    80001b5c:	e1050513          	addi	a0,a0,-496 # 80011968 <cpus>
    80001b60:	953e                	add	a0,a0,a5
    80001b62:	6422                	ld	s0,8(sp)
    80001b64:	0141                	addi	sp,sp,16
    80001b66:	8082                	ret

0000000080001b68 <myproc>:
myproc(void) {
    80001b68:	1101                	addi	sp,sp,-32
    80001b6a:	ec06                	sd	ra,24(sp)
    80001b6c:	e822                	sd	s0,16(sp)
    80001b6e:	e426                	sd	s1,8(sp)
    80001b70:	1000                	addi	s0,sp,32
  push_off();
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	052080e7          	jalr	82(ra) # 80000bc4 <push_off>
    80001b7a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b7c:	2781                	sext.w	a5,a5
    80001b7e:	079e                	slli	a5,a5,0x7
    80001b80:	00010717          	auipc	a4,0x10
    80001b84:	dd070713          	addi	a4,a4,-560 # 80011950 <pid_lock>
    80001b88:	97ba                	add	a5,a5,a4
    80001b8a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	0d8080e7          	jalr	216(ra) # 80000c64 <pop_off>
}
    80001b94:	8526                	mv	a0,s1
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret

0000000080001ba0 <forkret>:
{
    80001ba0:	1141                	addi	sp,sp,-16
    80001ba2:	e406                	sd	ra,8(sp)
    80001ba4:	e022                	sd	s0,0(sp)
    80001ba6:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001ba8:	00000097          	auipc	ra,0x0
    80001bac:	fc0080e7          	jalr	-64(ra) # 80001b68 <myproc>
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	114080e7          	jalr	276(ra) # 80000cc4 <release>
  if (first) {
    80001bb8:	00007797          	auipc	a5,0x7
    80001bbc:	cf87a783          	lw	a5,-776(a5) # 800088b0 <first.1705>
    80001bc0:	eb89                	bnez	a5,80001bd2 <forkret+0x32>
  usertrapret();
    80001bc2:	00001097          	auipc	ra,0x1
    80001bc6:	d86080e7          	jalr	-634(ra) # 80002948 <usertrapret>
}
    80001bca:	60a2                	ld	ra,8(sp)
    80001bcc:	6402                	ld	s0,0(sp)
    80001bce:	0141                	addi	sp,sp,16
    80001bd0:	8082                	ret
    first = 0;
    80001bd2:	00007797          	auipc	a5,0x7
    80001bd6:	cc07af23          	sw	zero,-802(a5) # 800088b0 <first.1705>
    fsinit(ROOTDEV);
    80001bda:	4505                	li	a0,1
    80001bdc:	00002097          	auipc	ra,0x2
    80001be0:	b16080e7          	jalr	-1258(ra) # 800036f2 <fsinit>
    80001be4:	bff9                	j	80001bc2 <forkret+0x22>

0000000080001be6 <allocpid>:
allocpid() {
    80001be6:	1101                	addi	sp,sp,-32
    80001be8:	ec06                	sd	ra,24(sp)
    80001bea:	e822                	sd	s0,16(sp)
    80001bec:	e426                	sd	s1,8(sp)
    80001bee:	e04a                	sd	s2,0(sp)
    80001bf0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001bf2:	00010917          	auipc	s2,0x10
    80001bf6:	d5e90913          	addi	s2,s2,-674 # 80011950 <pid_lock>
    80001bfa:	854a                	mv	a0,s2
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	014080e7          	jalr	20(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001c04:	00007797          	auipc	a5,0x7
    80001c08:	cb078793          	addi	a5,a5,-848 # 800088b4 <nextpid>
    80001c0c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c0e:	0014871b          	addiw	a4,s1,1
    80001c12:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c14:	854a                	mv	a0,s2
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	0ae080e7          	jalr	174(ra) # 80000cc4 <release>
}
    80001c1e:	8526                	mv	a0,s1
    80001c20:	60e2                	ld	ra,24(sp)
    80001c22:	6442                	ld	s0,16(sp)
    80001c24:	64a2                	ld	s1,8(sp)
    80001c26:	6902                	ld	s2,0(sp)
    80001c28:	6105                	addi	sp,sp,32
    80001c2a:	8082                	ret

0000000080001c2c <proc_pagetable>:
{
    80001c2c:	1101                	addi	sp,sp,-32
    80001c2e:	ec06                	sd	ra,24(sp)
    80001c30:	e822                	sd	s0,16(sp)
    80001c32:	e426                	sd	s1,8(sp)
    80001c34:	e04a                	sd	s2,0(sp)
    80001c36:	1000                	addi	s0,sp,32
    80001c38:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c3a:	fffff097          	auipc	ra,0xfffff
    80001c3e:	772080e7          	jalr	1906(ra) # 800013ac <uvmcreate>
    80001c42:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c44:	c121                	beqz	a0,80001c84 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c46:	4729                	li	a4,10
    80001c48:	00005697          	auipc	a3,0x5
    80001c4c:	3b868693          	addi	a3,a3,952 # 80007000 <_trampoline>
    80001c50:	6605                	lui	a2,0x1
    80001c52:	040005b7          	lui	a1,0x4000
    80001c56:	15fd                	addi	a1,a1,-1
    80001c58:	05b2                	slli	a1,a1,0xc
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	4f6080e7          	jalr	1270(ra) # 80001150 <mappages>
    80001c62:	02054863          	bltz	a0,80001c92 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c66:	4719                	li	a4,6
    80001c68:	05893683          	ld	a3,88(s2)
    80001c6c:	6605                	lui	a2,0x1
    80001c6e:	020005b7          	lui	a1,0x2000
    80001c72:	15fd                	addi	a1,a1,-1
    80001c74:	05b6                	slli	a1,a1,0xd
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	4d8080e7          	jalr	1240(ra) # 80001150 <mappages>
    80001c80:	02054163          	bltz	a0,80001ca2 <proc_pagetable+0x76>
}
    80001c84:	8526                	mv	a0,s1
    80001c86:	60e2                	ld	ra,24(sp)
    80001c88:	6442                	ld	s0,16(sp)
    80001c8a:	64a2                	ld	s1,8(sp)
    80001c8c:	6902                	ld	s2,0(sp)
    80001c8e:	6105                	addi	sp,sp,32
    80001c90:	8082                	ret
    uvmfree(pagetable, 0);
    80001c92:	4581                	li	a1,0
    80001c94:	8526                	mv	a0,s1
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	912080e7          	jalr	-1774(ra) # 800015a8 <uvmfree>
    return 0;
    80001c9e:	4481                	li	s1,0
    80001ca0:	b7d5                	j	80001c84 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ca2:	4681                	li	a3,0
    80001ca4:	4605                	li	a2,1
    80001ca6:	040005b7          	lui	a1,0x4000
    80001caa:	15fd                	addi	a1,a1,-1
    80001cac:	05b2                	slli	a1,a1,0xc
    80001cae:	8526                	mv	a0,s1
    80001cb0:	fffff097          	auipc	ra,0xfffff
    80001cb4:	638080e7          	jalr	1592(ra) # 800012e8 <uvmunmap>
    uvmfree(pagetable, 0);
    80001cb8:	4581                	li	a1,0
    80001cba:	8526                	mv	a0,s1
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	8ec080e7          	jalr	-1812(ra) # 800015a8 <uvmfree>
    return 0;
    80001cc4:	4481                	li	s1,0
    80001cc6:	bf7d                	j	80001c84 <proc_pagetable+0x58>

0000000080001cc8 <proc_freepagetable>:
{
    80001cc8:	1101                	addi	sp,sp,-32
    80001cca:	ec06                	sd	ra,24(sp)
    80001ccc:	e822                	sd	s0,16(sp)
    80001cce:	e426                	sd	s1,8(sp)
    80001cd0:	e04a                	sd	s2,0(sp)
    80001cd2:	1000                	addi	s0,sp,32
    80001cd4:	84aa                	mv	s1,a0
    80001cd6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cd8:	4681                	li	a3,0
    80001cda:	4605                	li	a2,1
    80001cdc:	040005b7          	lui	a1,0x4000
    80001ce0:	15fd                	addi	a1,a1,-1
    80001ce2:	05b2                	slli	a1,a1,0xc
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	604080e7          	jalr	1540(ra) # 800012e8 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cec:	4681                	li	a3,0
    80001cee:	4605                	li	a2,1
    80001cf0:	020005b7          	lui	a1,0x2000
    80001cf4:	15fd                	addi	a1,a1,-1
    80001cf6:	05b6                	slli	a1,a1,0xd
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	5ee080e7          	jalr	1518(ra) # 800012e8 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d02:	85ca                	mv	a1,s2
    80001d04:	8526                	mv	a0,s1
    80001d06:	00000097          	auipc	ra,0x0
    80001d0a:	8a2080e7          	jalr	-1886(ra) # 800015a8 <uvmfree>
}
    80001d0e:	60e2                	ld	ra,24(sp)
    80001d10:	6442                	ld	s0,16(sp)
    80001d12:	64a2                	ld	s1,8(sp)
    80001d14:	6902                	ld	s2,0(sp)
    80001d16:	6105                	addi	sp,sp,32
    80001d18:	8082                	ret

0000000080001d1a <growproc>:
{
    80001d1a:	1101                	addi	sp,sp,-32
    80001d1c:	ec06                	sd	ra,24(sp)
    80001d1e:	e822                	sd	s0,16(sp)
    80001d20:	e426                	sd	s1,8(sp)
    80001d22:	e04a                	sd	s2,0(sp)
    80001d24:	1000                	addi	s0,sp,32
    80001d26:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	e40080e7          	jalr	-448(ra) # 80001b68 <myproc>
    80001d30:	892a                	mv	s2,a0
  sz = p->sz;
    80001d32:	652c                	ld	a1,72(a0)
    80001d34:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d38:	00904f63          	bgtz	s1,80001d56 <growproc+0x3c>
  } else if(n < 0){
    80001d3c:	0204cc63          	bltz	s1,80001d74 <growproc+0x5a>
  p->sz = sz;
    80001d40:	1602                	slli	a2,a2,0x20
    80001d42:	9201                	srli	a2,a2,0x20
    80001d44:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d48:	4501                	li	a0,0
}
    80001d4a:	60e2                	ld	ra,24(sp)
    80001d4c:	6442                	ld	s0,16(sp)
    80001d4e:	64a2                	ld	s1,8(sp)
    80001d50:	6902                	ld	s2,0(sp)
    80001d52:	6105                	addi	sp,sp,32
    80001d54:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d56:	9e25                	addw	a2,a2,s1
    80001d58:	1602                	slli	a2,a2,0x20
    80001d5a:	9201                	srli	a2,a2,0x20
    80001d5c:	1582                	slli	a1,a1,0x20
    80001d5e:	9181                	srli	a1,a1,0x20
    80001d60:	6928                	ld	a0,80(a0)
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	732080e7          	jalr	1842(ra) # 80001494 <uvmalloc>
    80001d6a:	0005061b          	sext.w	a2,a0
    80001d6e:	fa69                	bnez	a2,80001d40 <growproc+0x26>
      return -1;
    80001d70:	557d                	li	a0,-1
    80001d72:	bfe1                	j	80001d4a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d74:	9e25                	addw	a2,a2,s1
    80001d76:	1602                	slli	a2,a2,0x20
    80001d78:	9201                	srli	a2,a2,0x20
    80001d7a:	1582                	slli	a1,a1,0x20
    80001d7c:	9181                	srli	a1,a1,0x20
    80001d7e:	6928                	ld	a0,80(a0)
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	6cc080e7          	jalr	1740(ra) # 8000144c <uvmdealloc>
    80001d88:	0005061b          	sext.w	a2,a0
    80001d8c:	bf55                	j	80001d40 <growproc+0x26>

0000000080001d8e <reparent>:
{
    80001d8e:	7179                	addi	sp,sp,-48
    80001d90:	f406                	sd	ra,40(sp)
    80001d92:	f022                	sd	s0,32(sp)
    80001d94:	ec26                	sd	s1,24(sp)
    80001d96:	e84a                	sd	s2,16(sp)
    80001d98:	e44e                	sd	s3,8(sp)
    80001d9a:	e052                	sd	s4,0(sp)
    80001d9c:	1800                	addi	s0,sp,48
    80001d9e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001da0:	00010497          	auipc	s1,0x10
    80001da4:	fc848493          	addi	s1,s1,-56 # 80011d68 <proc>
      pp->parent = initproc;
    80001da8:	00007a17          	auipc	s4,0x7
    80001dac:	270a0a13          	addi	s4,s4,624 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001db0:	00016997          	auipc	s3,0x16
    80001db4:	bb898993          	addi	s3,s3,-1096 # 80017968 <tickslock>
    80001db8:	a029                	j	80001dc2 <reparent+0x34>
    80001dba:	17048493          	addi	s1,s1,368
    80001dbe:	03348363          	beq	s1,s3,80001de4 <reparent+0x56>
    if(pp->parent == p){
    80001dc2:	709c                	ld	a5,32(s1)
    80001dc4:	ff279be3          	bne	a5,s2,80001dba <reparent+0x2c>
      acquire(&pp->lock);
    80001dc8:	8526                	mv	a0,s1
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	e46080e7          	jalr	-442(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    80001dd2:	000a3783          	ld	a5,0(s4)
    80001dd6:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001dd8:	8526                	mv	a0,s1
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	eea080e7          	jalr	-278(ra) # 80000cc4 <release>
    80001de2:	bfe1                	j	80001dba <reparent+0x2c>
}
    80001de4:	70a2                	ld	ra,40(sp)
    80001de6:	7402                	ld	s0,32(sp)
    80001de8:	64e2                	ld	s1,24(sp)
    80001dea:	6942                	ld	s2,16(sp)
    80001dec:	69a2                	ld	s3,8(sp)
    80001dee:	6a02                	ld	s4,0(sp)
    80001df0:	6145                	addi	sp,sp,48
    80001df2:	8082                	ret

0000000080001df4 <scheduler>:
{
    80001df4:	715d                	addi	sp,sp,-80
    80001df6:	e486                	sd	ra,72(sp)
    80001df8:	e0a2                	sd	s0,64(sp)
    80001dfa:	fc26                	sd	s1,56(sp)
    80001dfc:	f84a                	sd	s2,48(sp)
    80001dfe:	f44e                	sd	s3,40(sp)
    80001e00:	f052                	sd	s4,32(sp)
    80001e02:	ec56                	sd	s5,24(sp)
    80001e04:	e85a                	sd	s6,16(sp)
    80001e06:	e45e                	sd	s7,8(sp)
    80001e08:	e062                	sd	s8,0(sp)
    80001e0a:	0880                	addi	s0,sp,80
    80001e0c:	8792                	mv	a5,tp
  int id = r_tp();
    80001e0e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001e10:	00779b13          	slli	s6,a5,0x7
    80001e14:	00010717          	auipc	a4,0x10
    80001e18:	b3c70713          	addi	a4,a4,-1220 # 80011950 <pid_lock>
    80001e1c:	975a                	add	a4,a4,s6
    80001e1e:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001e22:	00010717          	auipc	a4,0x10
    80001e26:	b4e70713          	addi	a4,a4,-1202 # 80011970 <cpus+0x8>
    80001e2a:	9b3a                	add	s6,s6,a4
        c->proc = p;
    80001e2c:	079e                	slli	a5,a5,0x7
    80001e2e:	00010a17          	auipc	s4,0x10
    80001e32:	b22a0a13          	addi	s4,s4,-1246 # 80011950 <pid_lock>
    80001e36:	9a3e                	add	s4,s4,a5
        w_satp(MAKE_SATP(p->kpagetable));
    80001e38:	5bfd                	li	s7,-1
    80001e3a:	1bfe                	slli	s7,s7,0x3f
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e3c:	00016997          	auipc	s3,0x16
    80001e40:	b2c98993          	addi	s3,s3,-1236 # 80017968 <tickslock>
    80001e44:	a885                	j	80001eb4 <scheduler+0xc0>
        p->state = RUNNING;
    80001e46:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    80001e4a:	009a3c23          	sd	s1,24(s4)
        w_satp(MAKE_SATP(p->kpagetable));
    80001e4e:	1684b783          	ld	a5,360(s1)
    80001e52:	83b1                	srli	a5,a5,0xc
    80001e54:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    80001e58:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001e5c:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    80001e60:	06048593          	addi	a1,s1,96
    80001e64:	855a                	mv	a0,s6
    80001e66:	00001097          	auipc	ra,0x1
    80001e6a:	a38080e7          	jalr	-1480(ra) # 8000289e <swtch>
        kvminithart();
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	16e080e7          	jalr	366(ra) # 80000fdc <kvminithart>
        c->proc = 0;
    80001e76:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001e7a:	4c05                	li	s8,1
      release(&p->lock);
    80001e7c:	8526                	mv	a0,s1
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	e46080e7          	jalr	-442(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e86:	17048493          	addi	s1,s1,368
    80001e8a:	01348b63          	beq	s1,s3,80001ea0 <scheduler+0xac>
      acquire(&p->lock);
    80001e8e:	8526                	mv	a0,s1
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	d80080e7          	jalr	-640(ra) # 80000c10 <acquire>
      if(p->state == RUNNABLE) {
    80001e98:	4c9c                	lw	a5,24(s1)
    80001e9a:	ff2791e3          	bne	a5,s2,80001e7c <scheduler+0x88>
    80001e9e:	b765                	j	80001e46 <scheduler+0x52>
    if(found == 0) {
    80001ea0:	000c1a63          	bnez	s8,80001eb4 <scheduler+0xc0>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ea4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ea8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001eac:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001eb0:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eb4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001eb8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ebc:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001ec0:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ec2:	00010497          	auipc	s1,0x10
    80001ec6:	ea648493          	addi	s1,s1,-346 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80001eca:	4909                	li	s2,2
        p->state = RUNNING;
    80001ecc:	4a8d                	li	s5,3
    80001ece:	b7c1                	j	80001e8e <scheduler+0x9a>

0000000080001ed0 <sched>:
{
    80001ed0:	7179                	addi	sp,sp,-48
    80001ed2:	f406                	sd	ra,40(sp)
    80001ed4:	f022                	sd	s0,32(sp)
    80001ed6:	ec26                	sd	s1,24(sp)
    80001ed8:	e84a                	sd	s2,16(sp)
    80001eda:	e44e                	sd	s3,8(sp)
    80001edc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ede:	00000097          	auipc	ra,0x0
    80001ee2:	c8a080e7          	jalr	-886(ra) # 80001b68 <myproc>
    80001ee6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	cae080e7          	jalr	-850(ra) # 80000b96 <holding>
    80001ef0:	c93d                	beqz	a0,80001f66 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ef2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ef4:	2781                	sext.w	a5,a5
    80001ef6:	079e                	slli	a5,a5,0x7
    80001ef8:	00010717          	auipc	a4,0x10
    80001efc:	a5870713          	addi	a4,a4,-1448 # 80011950 <pid_lock>
    80001f00:	97ba                	add	a5,a5,a4
    80001f02:	0907a703          	lw	a4,144(a5)
    80001f06:	4785                	li	a5,1
    80001f08:	06f71763          	bne	a4,a5,80001f76 <sched+0xa6>
  if(p->state == RUNNING)
    80001f0c:	4c98                	lw	a4,24(s1)
    80001f0e:	478d                	li	a5,3
    80001f10:	06f70b63          	beq	a4,a5,80001f86 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f14:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f18:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f1a:	efb5                	bnez	a5,80001f96 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f1c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f1e:	00010917          	auipc	s2,0x10
    80001f22:	a3290913          	addi	s2,s2,-1486 # 80011950 <pid_lock>
    80001f26:	2781                	sext.w	a5,a5
    80001f28:	079e                	slli	a5,a5,0x7
    80001f2a:	97ca                	add	a5,a5,s2
    80001f2c:	0947a983          	lw	s3,148(a5)
    80001f30:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f32:	2781                	sext.w	a5,a5
    80001f34:	079e                	slli	a5,a5,0x7
    80001f36:	00010597          	auipc	a1,0x10
    80001f3a:	a3a58593          	addi	a1,a1,-1478 # 80011970 <cpus+0x8>
    80001f3e:	95be                	add	a1,a1,a5
    80001f40:	06048513          	addi	a0,s1,96
    80001f44:	00001097          	auipc	ra,0x1
    80001f48:	95a080e7          	jalr	-1702(ra) # 8000289e <swtch>
    80001f4c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f4e:	2781                	sext.w	a5,a5
    80001f50:	079e                	slli	a5,a5,0x7
    80001f52:	97ca                	add	a5,a5,s2
    80001f54:	0937aa23          	sw	s3,148(a5)
}
    80001f58:	70a2                	ld	ra,40(sp)
    80001f5a:	7402                	ld	s0,32(sp)
    80001f5c:	64e2                	ld	s1,24(sp)
    80001f5e:	6942                	ld	s2,16(sp)
    80001f60:	69a2                	ld	s3,8(sp)
    80001f62:	6145                	addi	sp,sp,48
    80001f64:	8082                	ret
    panic("sched p->lock");
    80001f66:	00006517          	auipc	a0,0x6
    80001f6a:	2d250513          	addi	a0,a0,722 # 80008238 <digits+0x1f8>
    80001f6e:	ffffe097          	auipc	ra,0xffffe
    80001f72:	5da080e7          	jalr	1498(ra) # 80000548 <panic>
    panic("sched locks");
    80001f76:	00006517          	auipc	a0,0x6
    80001f7a:	2d250513          	addi	a0,a0,722 # 80008248 <digits+0x208>
    80001f7e:	ffffe097          	auipc	ra,0xffffe
    80001f82:	5ca080e7          	jalr	1482(ra) # 80000548 <panic>
    panic("sched running");
    80001f86:	00006517          	auipc	a0,0x6
    80001f8a:	2d250513          	addi	a0,a0,722 # 80008258 <digits+0x218>
    80001f8e:	ffffe097          	auipc	ra,0xffffe
    80001f92:	5ba080e7          	jalr	1466(ra) # 80000548 <panic>
    panic("sched interruptible");
    80001f96:	00006517          	auipc	a0,0x6
    80001f9a:	2d250513          	addi	a0,a0,722 # 80008268 <digits+0x228>
    80001f9e:	ffffe097          	auipc	ra,0xffffe
    80001fa2:	5aa080e7          	jalr	1450(ra) # 80000548 <panic>

0000000080001fa6 <exit>:
{
    80001fa6:	7179                	addi	sp,sp,-48
    80001fa8:	f406                	sd	ra,40(sp)
    80001faa:	f022                	sd	s0,32(sp)
    80001fac:	ec26                	sd	s1,24(sp)
    80001fae:	e84a                	sd	s2,16(sp)
    80001fb0:	e44e                	sd	s3,8(sp)
    80001fb2:	e052                	sd	s4,0(sp)
    80001fb4:	1800                	addi	s0,sp,48
    80001fb6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	bb0080e7          	jalr	-1104(ra) # 80001b68 <myproc>
    80001fc0:	89aa                	mv	s3,a0
  if(p == initproc)
    80001fc2:	00007797          	auipc	a5,0x7
    80001fc6:	0567b783          	ld	a5,86(a5) # 80009018 <initproc>
    80001fca:	0d050493          	addi	s1,a0,208
    80001fce:	15050913          	addi	s2,a0,336
    80001fd2:	02a79363          	bne	a5,a0,80001ff8 <exit+0x52>
    panic("init exiting");
    80001fd6:	00006517          	auipc	a0,0x6
    80001fda:	2aa50513          	addi	a0,a0,682 # 80008280 <digits+0x240>
    80001fde:	ffffe097          	auipc	ra,0xffffe
    80001fe2:	56a080e7          	jalr	1386(ra) # 80000548 <panic>
      fileclose(f);
    80001fe6:	00003097          	auipc	ra,0x3
    80001fea:	812080e7          	jalr	-2030(ra) # 800047f8 <fileclose>
      p->ofile[fd] = 0;
    80001fee:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80001ff2:	04a1                	addi	s1,s1,8
    80001ff4:	01248563          	beq	s1,s2,80001ffe <exit+0x58>
    if(p->ofile[fd]){
    80001ff8:	6088                	ld	a0,0(s1)
    80001ffa:	f575                	bnez	a0,80001fe6 <exit+0x40>
    80001ffc:	bfdd                	j	80001ff2 <exit+0x4c>
  begin_op();
    80001ffe:	00002097          	auipc	ra,0x2
    80002002:	328080e7          	jalr	808(ra) # 80004326 <begin_op>
  iput(p->cwd);
    80002006:	1509b503          	ld	a0,336(s3)
    8000200a:	00002097          	auipc	ra,0x2
    8000200e:	b1a080e7          	jalr	-1254(ra) # 80003b24 <iput>
  end_op();
    80002012:	00002097          	auipc	ra,0x2
    80002016:	394080e7          	jalr	916(ra) # 800043a6 <end_op>
  p->cwd = 0;
    8000201a:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000201e:	00007497          	auipc	s1,0x7
    80002022:	ffa48493          	addi	s1,s1,-6 # 80009018 <initproc>
    80002026:	6088                	ld	a0,0(s1)
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	be8080e7          	jalr	-1048(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    80002030:	6088                	ld	a0,0(s1)
    80002032:	00000097          	auipc	ra,0x0
    80002036:	9f6080e7          	jalr	-1546(ra) # 80001a28 <wakeup1>
  release(&initproc->lock);
    8000203a:	6088                	ld	a0,0(s1)
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	c88080e7          	jalr	-888(ra) # 80000cc4 <release>
  acquire(&p->lock);
    80002044:	854e                	mv	a0,s3
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	bca080e7          	jalr	-1078(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    8000204e:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002052:	854e                	mv	a0,s3
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	c70080e7          	jalr	-912(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    8000205c:	8526                	mv	a0,s1
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	bb2080e7          	jalr	-1102(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    80002066:	854e                	mv	a0,s3
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	ba8080e7          	jalr	-1112(ra) # 80000c10 <acquire>
  reparent(p);
    80002070:	854e                	mv	a0,s3
    80002072:	00000097          	auipc	ra,0x0
    80002076:	d1c080e7          	jalr	-740(ra) # 80001d8e <reparent>
  wakeup1(original_parent);
    8000207a:	8526                	mv	a0,s1
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	9ac080e7          	jalr	-1620(ra) # 80001a28 <wakeup1>
  p->xstate = status;
    80002084:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002088:	4791                	li	a5,4
    8000208a:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000208e:	8526                	mv	a0,s1
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	c34080e7          	jalr	-972(ra) # 80000cc4 <release>
  sched();
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	e38080e7          	jalr	-456(ra) # 80001ed0 <sched>
  panic("zombie exit");
    800020a0:	00006517          	auipc	a0,0x6
    800020a4:	1f050513          	addi	a0,a0,496 # 80008290 <digits+0x250>
    800020a8:	ffffe097          	auipc	ra,0xffffe
    800020ac:	4a0080e7          	jalr	1184(ra) # 80000548 <panic>

00000000800020b0 <yield>:
{
    800020b0:	1101                	addi	sp,sp,-32
    800020b2:	ec06                	sd	ra,24(sp)
    800020b4:	e822                	sd	s0,16(sp)
    800020b6:	e426                	sd	s1,8(sp)
    800020b8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020ba:	00000097          	auipc	ra,0x0
    800020be:	aae080e7          	jalr	-1362(ra) # 80001b68 <myproc>
    800020c2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	b4c080e7          	jalr	-1204(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    800020cc:	4789                	li	a5,2
    800020ce:	cc9c                	sw	a5,24(s1)
  sched();
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	e00080e7          	jalr	-512(ra) # 80001ed0 <sched>
  release(&p->lock);
    800020d8:	8526                	mv	a0,s1
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	bea080e7          	jalr	-1046(ra) # 80000cc4 <release>
}
    800020e2:	60e2                	ld	ra,24(sp)
    800020e4:	6442                	ld	s0,16(sp)
    800020e6:	64a2                	ld	s1,8(sp)
    800020e8:	6105                	addi	sp,sp,32
    800020ea:	8082                	ret

00000000800020ec <sleep>:
{
    800020ec:	7179                	addi	sp,sp,-48
    800020ee:	f406                	sd	ra,40(sp)
    800020f0:	f022                	sd	s0,32(sp)
    800020f2:	ec26                	sd	s1,24(sp)
    800020f4:	e84a                	sd	s2,16(sp)
    800020f6:	e44e                	sd	s3,8(sp)
    800020f8:	1800                	addi	s0,sp,48
    800020fa:	89aa                	mv	s3,a0
    800020fc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	a6a080e7          	jalr	-1430(ra) # 80001b68 <myproc>
    80002106:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002108:	05250663          	beq	a0,s2,80002154 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
    release(lk);
    80002114:	854a                	mv	a0,s2
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	bae080e7          	jalr	-1106(ra) # 80000cc4 <release>
  p->chan = chan;
    8000211e:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002122:	4785                	li	a5,1
    80002124:	cc9c                	sw	a5,24(s1)
  sched();
    80002126:	00000097          	auipc	ra,0x0
    8000212a:	daa080e7          	jalr	-598(ra) # 80001ed0 <sched>
  p->chan = 0;
    8000212e:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002132:	8526                	mv	a0,s1
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	b90080e7          	jalr	-1136(ra) # 80000cc4 <release>
    acquire(lk);
    8000213c:	854a                	mv	a0,s2
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	ad2080e7          	jalr	-1326(ra) # 80000c10 <acquire>
}
    80002146:	70a2                	ld	ra,40(sp)
    80002148:	7402                	ld	s0,32(sp)
    8000214a:	64e2                	ld	s1,24(sp)
    8000214c:	6942                	ld	s2,16(sp)
    8000214e:	69a2                	ld	s3,8(sp)
    80002150:	6145                	addi	sp,sp,48
    80002152:	8082                	ret
  p->chan = chan;
    80002154:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002158:	4785                	li	a5,1
    8000215a:	cd1c                	sw	a5,24(a0)
  sched();
    8000215c:	00000097          	auipc	ra,0x0
    80002160:	d74080e7          	jalr	-652(ra) # 80001ed0 <sched>
  p->chan = 0;
    80002164:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002168:	bff9                	j	80002146 <sleep+0x5a>

000000008000216a <wakeup>:
{
    8000216a:	7139                	addi	sp,sp,-64
    8000216c:	fc06                	sd	ra,56(sp)
    8000216e:	f822                	sd	s0,48(sp)
    80002170:	f426                	sd	s1,40(sp)
    80002172:	f04a                	sd	s2,32(sp)
    80002174:	ec4e                	sd	s3,24(sp)
    80002176:	e852                	sd	s4,16(sp)
    80002178:	e456                	sd	s5,8(sp)
    8000217a:	0080                	addi	s0,sp,64
    8000217c:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000217e:	00010497          	auipc	s1,0x10
    80002182:	bea48493          	addi	s1,s1,-1046 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002186:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002188:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000218a:	00015917          	auipc	s2,0x15
    8000218e:	7de90913          	addi	s2,s2,2014 # 80017968 <tickslock>
    80002192:	a821                	j	800021aa <wakeup+0x40>
      p->state = RUNNABLE;
    80002194:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002198:	8526                	mv	a0,s1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	b2a080e7          	jalr	-1238(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021a2:	17048493          	addi	s1,s1,368
    800021a6:	01248e63          	beq	s1,s2,800021c2 <wakeup+0x58>
    acquire(&p->lock);
    800021aa:	8526                	mv	a0,s1
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	a64080e7          	jalr	-1436(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800021b4:	4c9c                	lw	a5,24(s1)
    800021b6:	ff3791e3          	bne	a5,s3,80002198 <wakeup+0x2e>
    800021ba:	749c                	ld	a5,40(s1)
    800021bc:	fd479ee3          	bne	a5,s4,80002198 <wakeup+0x2e>
    800021c0:	bfd1                	j	80002194 <wakeup+0x2a>
}
    800021c2:	70e2                	ld	ra,56(sp)
    800021c4:	7442                	ld	s0,48(sp)
    800021c6:	74a2                	ld	s1,40(sp)
    800021c8:	7902                	ld	s2,32(sp)
    800021ca:	69e2                	ld	s3,24(sp)
    800021cc:	6a42                	ld	s4,16(sp)
    800021ce:	6aa2                	ld	s5,8(sp)
    800021d0:	6121                	addi	sp,sp,64
    800021d2:	8082                	ret

00000000800021d4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800021d4:	7179                	addi	sp,sp,-48
    800021d6:	f406                	sd	ra,40(sp)
    800021d8:	f022                	sd	s0,32(sp)
    800021da:	ec26                	sd	s1,24(sp)
    800021dc:	e84a                	sd	s2,16(sp)
    800021de:	e44e                	sd	s3,8(sp)
    800021e0:	1800                	addi	s0,sp,48
    800021e2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800021e4:	00010497          	auipc	s1,0x10
    800021e8:	b8448493          	addi	s1,s1,-1148 # 80011d68 <proc>
    800021ec:	00015997          	auipc	s3,0x15
    800021f0:	77c98993          	addi	s3,s3,1916 # 80017968 <tickslock>
    acquire(&p->lock);
    800021f4:	8526                	mv	a0,s1
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	a1a080e7          	jalr	-1510(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    800021fe:	5c9c                	lw	a5,56(s1)
    80002200:	01278d63          	beq	a5,s2,8000221a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002204:	8526                	mv	a0,s1
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	abe080e7          	jalr	-1346(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000220e:	17048493          	addi	s1,s1,368
    80002212:	ff3491e3          	bne	s1,s3,800021f4 <kill+0x20>
  }
  return -1;
    80002216:	557d                	li	a0,-1
    80002218:	a829                	j	80002232 <kill+0x5e>
      p->killed = 1;
    8000221a:	4785                	li	a5,1
    8000221c:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000221e:	4c98                	lw	a4,24(s1)
    80002220:	4785                	li	a5,1
    80002222:	00f70f63          	beq	a4,a5,80002240 <kill+0x6c>
      release(&p->lock);
    80002226:	8526                	mv	a0,s1
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	a9c080e7          	jalr	-1380(ra) # 80000cc4 <release>
      return 0;
    80002230:	4501                	li	a0,0
}
    80002232:	70a2                	ld	ra,40(sp)
    80002234:	7402                	ld	s0,32(sp)
    80002236:	64e2                	ld	s1,24(sp)
    80002238:	6942                	ld	s2,16(sp)
    8000223a:	69a2                	ld	s3,8(sp)
    8000223c:	6145                	addi	sp,sp,48
    8000223e:	8082                	ret
        p->state = RUNNABLE;
    80002240:	4789                	li	a5,2
    80002242:	cc9c                	sw	a5,24(s1)
    80002244:	b7cd                	j	80002226 <kill+0x52>

0000000080002246 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002246:	7179                	addi	sp,sp,-48
    80002248:	f406                	sd	ra,40(sp)
    8000224a:	f022                	sd	s0,32(sp)
    8000224c:	ec26                	sd	s1,24(sp)
    8000224e:	e84a                	sd	s2,16(sp)
    80002250:	e44e                	sd	s3,8(sp)
    80002252:	e052                	sd	s4,0(sp)
    80002254:	1800                	addi	s0,sp,48
    80002256:	84aa                	mv	s1,a0
    80002258:	892e                	mv	s2,a1
    8000225a:	89b2                	mv	s3,a2
    8000225c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000225e:	00000097          	auipc	ra,0x0
    80002262:	90a080e7          	jalr	-1782(ra) # 80001b68 <myproc>
  if(user_dst){
    80002266:	c08d                	beqz	s1,80002288 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002268:	86d2                	mv	a3,s4
    8000226a:	864e                	mv	a2,s3
    8000226c:	85ca                	mv	a1,s2
    8000226e:	6928                	ld	a0,80(a0)
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	474080e7          	jalr	1140(ra) # 800016e4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002278:	70a2                	ld	ra,40(sp)
    8000227a:	7402                	ld	s0,32(sp)
    8000227c:	64e2                	ld	s1,24(sp)
    8000227e:	6942                	ld	s2,16(sp)
    80002280:	69a2                	ld	s3,8(sp)
    80002282:	6a02                	ld	s4,0(sp)
    80002284:	6145                	addi	sp,sp,48
    80002286:	8082                	ret
    memmove((char *)dst, src, len);
    80002288:	000a061b          	sext.w	a2,s4
    8000228c:	85ce                	mv	a1,s3
    8000228e:	854a                	mv	a0,s2
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	adc080e7          	jalr	-1316(ra) # 80000d6c <memmove>
    return 0;
    80002298:	8526                	mv	a0,s1
    8000229a:	bff9                	j	80002278 <either_copyout+0x32>

000000008000229c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000229c:	7179                	addi	sp,sp,-48
    8000229e:	f406                	sd	ra,40(sp)
    800022a0:	f022                	sd	s0,32(sp)
    800022a2:	ec26                	sd	s1,24(sp)
    800022a4:	e84a                	sd	s2,16(sp)
    800022a6:	e44e                	sd	s3,8(sp)
    800022a8:	e052                	sd	s4,0(sp)
    800022aa:	1800                	addi	s0,sp,48
    800022ac:	892a                	mv	s2,a0
    800022ae:	84ae                	mv	s1,a1
    800022b0:	89b2                	mv	s3,a2
    800022b2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800022b4:	00000097          	auipc	ra,0x0
    800022b8:	8b4080e7          	jalr	-1868(ra) # 80001b68 <myproc>
  if(user_src){
    800022bc:	c08d                	beqz	s1,800022de <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800022be:	86d2                	mv	a3,s4
    800022c0:	864e                	mv	a2,s3
    800022c2:	85ca                	mv	a1,s2
    800022c4:	6928                	ld	a0,80(a0)
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	4aa080e7          	jalr	1194(ra) # 80001770 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800022ce:	70a2                	ld	ra,40(sp)
    800022d0:	7402                	ld	s0,32(sp)
    800022d2:	64e2                	ld	s1,24(sp)
    800022d4:	6942                	ld	s2,16(sp)
    800022d6:	69a2                	ld	s3,8(sp)
    800022d8:	6a02                	ld	s4,0(sp)
    800022da:	6145                	addi	sp,sp,48
    800022dc:	8082                	ret
    memmove(dst, (char*)src, len);
    800022de:	000a061b          	sext.w	a2,s4
    800022e2:	85ce                	mv	a1,s3
    800022e4:	854a                	mv	a0,s2
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	a86080e7          	jalr	-1402(ra) # 80000d6c <memmove>
    return 0;
    800022ee:	8526                	mv	a0,s1
    800022f0:	bff9                	j	800022ce <either_copyin+0x32>

00000000800022f2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800022f2:	715d                	addi	sp,sp,-80
    800022f4:	e486                	sd	ra,72(sp)
    800022f6:	e0a2                	sd	s0,64(sp)
    800022f8:	fc26                	sd	s1,56(sp)
    800022fa:	f84a                	sd	s2,48(sp)
    800022fc:	f44e                	sd	s3,40(sp)
    800022fe:	f052                	sd	s4,32(sp)
    80002300:	ec56                	sd	s5,24(sp)
    80002302:	e85a                	sd	s6,16(sp)
    80002304:	e45e                	sd	s7,8(sp)
    80002306:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002308:	00006517          	auipc	a0,0x6
    8000230c:	dc050513          	addi	a0,a0,-576 # 800080c8 <digits+0x88>
    80002310:	ffffe097          	auipc	ra,0xffffe
    80002314:	282080e7          	jalr	642(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002318:	00010497          	auipc	s1,0x10
    8000231c:	ba848493          	addi	s1,s1,-1112 # 80011ec0 <proc+0x158>
    80002320:	00015917          	auipc	s2,0x15
    80002324:	7a090913          	addi	s2,s2,1952 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002328:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000232a:	00006997          	auipc	s3,0x6
    8000232e:	f7698993          	addi	s3,s3,-138 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002332:	00006a97          	auipc	s5,0x6
    80002336:	f76a8a93          	addi	s5,s5,-138 # 800082a8 <digits+0x268>
    printf("\n");
    8000233a:	00006a17          	auipc	s4,0x6
    8000233e:	d8ea0a13          	addi	s4,s4,-626 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002342:	00006b97          	auipc	s7,0x6
    80002346:	fc6b8b93          	addi	s7,s7,-58 # 80008308 <states.1745>
    8000234a:	a00d                	j	8000236c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000234c:	ee06a583          	lw	a1,-288(a3)
    80002350:	8556                	mv	a0,s5
    80002352:	ffffe097          	auipc	ra,0xffffe
    80002356:	240080e7          	jalr	576(ra) # 80000592 <printf>
    printf("\n");
    8000235a:	8552                	mv	a0,s4
    8000235c:	ffffe097          	auipc	ra,0xffffe
    80002360:	236080e7          	jalr	566(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002364:	17048493          	addi	s1,s1,368
    80002368:	03248163          	beq	s1,s2,8000238a <procdump+0x98>
    if(p->state == UNUSED)
    8000236c:	86a6                	mv	a3,s1
    8000236e:	ec04a783          	lw	a5,-320(s1)
    80002372:	dbed                	beqz	a5,80002364 <procdump+0x72>
      state = "???";
    80002374:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002376:	fcfb6be3          	bltu	s6,a5,8000234c <procdump+0x5a>
    8000237a:	1782                	slli	a5,a5,0x20
    8000237c:	9381                	srli	a5,a5,0x20
    8000237e:	078e                	slli	a5,a5,0x3
    80002380:	97de                	add	a5,a5,s7
    80002382:	6390                	ld	a2,0(a5)
    80002384:	f661                	bnez	a2,8000234c <procdump+0x5a>
      state = "???";
    80002386:	864e                	mv	a2,s3
    80002388:	b7d1                	j	8000234c <procdump+0x5a>
  }
}
    8000238a:	60a6                	ld	ra,72(sp)
    8000238c:	6406                	ld	s0,64(sp)
    8000238e:	74e2                	ld	s1,56(sp)
    80002390:	7942                	ld	s2,48(sp)
    80002392:	79a2                	ld	s3,40(sp)
    80002394:	7a02                	ld	s4,32(sp)
    80002396:	6ae2                	ld	s5,24(sp)
    80002398:	6b42                	ld	s6,16(sp)
    8000239a:	6ba2                	ld	s7,8(sp)
    8000239c:	6161                	addi	sp,sp,80
    8000239e:	8082                	ret

00000000800023a0 <proc_freewalk>:


void proc_freewalk(pagetable_t pagetable) {
    800023a0:	7179                	addi	sp,sp,-48
    800023a2:	f406                	sd	ra,40(sp)
    800023a4:	f022                	sd	s0,32(sp)
    800023a6:	ec26                	sd	s1,24(sp)
    800023a8:	e84a                	sd	s2,16(sp)
    800023aa:	e44e                	sd	s3,8(sp)
    800023ac:	1800                	addi	s0,sp,48
    800023ae:	89aa                	mv	s3,a0
  for (int i = 0; i < 512; i++) {
    800023b0:	84aa                	mv	s1,a0
    800023b2:	6905                	lui	s2,0x1
    800023b4:	992a                	add	s2,s2,a0
    800023b6:	a811                	j	800023ca <proc_freewalk+0x2a>
    pte_t pte = pagetable[i];
	if (pte & PTE_V) {
	  pagetable[i] = 0;
	  if ((pte & (PTE_R | PTE_W | PTE_X)) == 0) {
	    uint64 child = PTE2PA(pte);
    800023b8:	8129                	srli	a0,a0,0xa
		proc_freewalk((pagetable_t)child);
    800023ba:	0532                	slli	a0,a0,0xc
    800023bc:	00000097          	auipc	ra,0x0
    800023c0:	fe4080e7          	jalr	-28(ra) # 800023a0 <proc_freewalk>
  for (int i = 0; i < 512; i++) {
    800023c4:	04a1                	addi	s1,s1,8
    800023c6:	01248c63          	beq	s1,s2,800023de <proc_freewalk+0x3e>
    pte_t pte = pagetable[i];
    800023ca:	6088                	ld	a0,0(s1)
	if (pte & PTE_V) {
    800023cc:	00157793          	andi	a5,a0,1
    800023d0:	dbf5                	beqz	a5,800023c4 <proc_freewalk+0x24>
	  pagetable[i] = 0;
    800023d2:	0004b023          	sd	zero,0(s1)
	  if ((pte & (PTE_R | PTE_W | PTE_X)) == 0) {
    800023d6:	00e57793          	andi	a5,a0,14
    800023da:	f7ed                	bnez	a5,800023c4 <proc_freewalk+0x24>
    800023dc:	bff1                	j	800023b8 <proc_freewalk+0x18>
	  }
	}
  }
  kfree((void*)pagetable);
    800023de:	854e                	mv	a0,s3
    800023e0:	ffffe097          	auipc	ra,0xffffe
    800023e4:	644080e7          	jalr	1604(ra) # 80000a24 <kfree>
}
    800023e8:	70a2                	ld	ra,40(sp)
    800023ea:	7402                	ld	s0,32(sp)
    800023ec:	64e2                	ld	s1,24(sp)
    800023ee:	6942                	ld	s2,16(sp)
    800023f0:	69a2                	ld	s3,8(sp)
    800023f2:	6145                	addi	sp,sp,48
    800023f4:	8082                	ret

00000000800023f6 <freeproc>:
{
    800023f6:	1101                	addi	sp,sp,-32
    800023f8:	ec06                	sd	ra,24(sp)
    800023fa:	e822                	sd	s0,16(sp)
    800023fc:	e426                	sd	s1,8(sp)
    800023fe:	1000                	addi	s0,sp,32
    80002400:	84aa                	mv	s1,a0
  if(p->kstack) {
    80002402:	612c                	ld	a1,64(a0)
    80002404:	e1b5                	bnez	a1,80002468 <freeproc+0x72>
  p->kstack = 0;
    80002406:	0404b023          	sd	zero,64(s1)
  if(p->trapframe)
    8000240a:	6ca8                	ld	a0,88(s1)
    8000240c:	c509                	beqz	a0,80002416 <freeproc+0x20>
    kfree((void*)p->trapframe);
    8000240e:	ffffe097          	auipc	ra,0xffffe
    80002412:	616080e7          	jalr	1558(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80002416:	0404bc23          	sd	zero,88(s1)
  if (p->kpagetable)
    8000241a:	1684b503          	ld	a0,360(s1)
    8000241e:	c509                	beqz	a0,80002428 <freeproc+0x32>
    proc_freewalk(p->kpagetable);
    80002420:	00000097          	auipc	ra,0x0
    80002424:	f80080e7          	jalr	-128(ra) # 800023a0 <proc_freewalk>
  p->kpagetable = 0;
    80002428:	1604b423          	sd	zero,360(s1)
  if(p->pagetable)
    8000242c:	68a8                	ld	a0,80(s1)
    8000242e:	c511                	beqz	a0,8000243a <freeproc+0x44>
    proc_freepagetable(p->pagetable, p->sz);
    80002430:	64ac                	ld	a1,72(s1)
    80002432:	00000097          	auipc	ra,0x0
    80002436:	896080e7          	jalr	-1898(ra) # 80001cc8 <proc_freepagetable>
  p->pagetable = 0;
    8000243a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    8000243e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80002442:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80002446:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    8000244a:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    8000244e:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80002452:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80002456:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    8000245a:	0004ac23          	sw	zero,24(s1)
}
    8000245e:	60e2                	ld	ra,24(sp)
    80002460:	6442                	ld	s0,16(sp)
    80002462:	64a2                	ld	s1,8(sp)
    80002464:	6105                	addi	sp,sp,32
    80002466:	8082                	ret
    pte_t* pte = walk(p->kpagetable, p->kstack, 0);
    80002468:	4601                	li	a2,0
    8000246a:	16853503          	ld	a0,360(a0)
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	b92080e7          	jalr	-1134(ra) # 80001000 <walk>
	if(pte == 0)
    80002476:	c909                	beqz	a0,80002488 <freeproc+0x92>
	kfree((void*)PTE2PA(*pte));
    80002478:	6108                	ld	a0,0(a0)
    8000247a:	8129                	srli	a0,a0,0xa
    8000247c:	0532                	slli	a0,a0,0xc
    8000247e:	ffffe097          	auipc	ra,0xffffe
    80002482:	5a6080e7          	jalr	1446(ra) # 80000a24 <kfree>
    80002486:	b741                	j	80002406 <freeproc+0x10>
      panic("freeproc: walk");
    80002488:	00006517          	auipc	a0,0x6
    8000248c:	e3050513          	addi	a0,a0,-464 # 800082b8 <digits+0x278>
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	0b8080e7          	jalr	184(ra) # 80000548 <panic>

0000000080002498 <allocproc>:
{
    80002498:	1101                	addi	sp,sp,-32
    8000249a:	ec06                	sd	ra,24(sp)
    8000249c:	e822                	sd	s0,16(sp)
    8000249e:	e426                	sd	s1,8(sp)
    800024a0:	e04a                	sd	s2,0(sp)
    800024a2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    800024a4:	00010497          	auipc	s1,0x10
    800024a8:	8c448493          	addi	s1,s1,-1852 # 80011d68 <proc>
    800024ac:	00015917          	auipc	s2,0x15
    800024b0:	4bc90913          	addi	s2,s2,1212 # 80017968 <tickslock>
    acquire(&p->lock);
    800024b4:	8526                	mv	a0,s1
    800024b6:	ffffe097          	auipc	ra,0xffffe
    800024ba:	75a080e7          	jalr	1882(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    800024be:	4c9c                	lw	a5,24(s1)
    800024c0:	cf81                	beqz	a5,800024d8 <allocproc+0x40>
      release(&p->lock);
    800024c2:	8526                	mv	a0,s1
    800024c4:	fffff097          	auipc	ra,0xfffff
    800024c8:	800080e7          	jalr	-2048(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024cc:	17048493          	addi	s1,s1,368
    800024d0:	ff2492e3          	bne	s1,s2,800024b4 <allocproc+0x1c>
  return 0;
    800024d4:	4481                	li	s1,0
    800024d6:	a075                	j	80002582 <allocproc+0xea>
  p->pid = allocpid();
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	70e080e7          	jalr	1806(ra) # 80001be6 <allocpid>
    800024e0:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	63e080e7          	jalr	1598(ra) # 80000b20 <kalloc>
    800024ea:	892a                	mv	s2,a0
    800024ec:	eca8                	sd	a0,88(s1)
    800024ee:	c14d                	beqz	a0,80002590 <allocproc+0xf8>
  p->pagetable = proc_pagetable(p);
    800024f0:	8526                	mv	a0,s1
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	73a080e7          	jalr	1850(ra) # 80001c2c <proc_pagetable>
    800024fa:	892a                	mv	s2,a0
    800024fc:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    800024fe:	c145                	beqz	a0,8000259e <allocproc+0x106>
  p->kpagetable = ukvminit();
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	3cc080e7          	jalr	972(ra) # 800018cc <ukvminit>
    80002508:	892a                	mv	s2,a0
    8000250a:	16a4b423          	sd	a0,360(s1)
  if (p->kpagetable == 0)
    8000250e:	c545                	beqz	a0,800025b6 <allocproc+0x11e>
  char *pa = kalloc();
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	610080e7          	jalr	1552(ra) # 80000b20 <kalloc>
    80002518:	862a                	mv	a2,a0
  if (pa == 0)
    8000251a:	c955                	beqz	a0,800025ce <allocproc+0x136>
  uint64 va = KSTACK((int)(p - proc));
    8000251c:	00010797          	auipc	a5,0x10
    80002520:	84c78793          	addi	a5,a5,-1972 # 80011d68 <proc>
    80002524:	40f487b3          	sub	a5,s1,a5
    80002528:	8791                	srai	a5,a5,0x4
    8000252a:	00006717          	auipc	a4,0x6
    8000252e:	ad673703          	ld	a4,-1322(a4) # 80008000 <etext>
    80002532:	02e787b3          	mul	a5,a5,a4
    80002536:	2785                	addiw	a5,a5,1
    80002538:	00d7979b          	slliw	a5,a5,0xd
    8000253c:	04000937          	lui	s2,0x4000
    80002540:	197d                	addi	s2,s2,-1
    80002542:	0932                	slli	s2,s2,0xc
    80002544:	40f90933          	sub	s2,s2,a5
  ukvmmap(p->kpagetable, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80002548:	4719                	li	a4,6
    8000254a:	6685                	lui	a3,0x1
    8000254c:	85ca                	mv	a1,s2
    8000254e:	1684b503          	ld	a0,360(s1)
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	34a080e7          	jalr	842(ra) # 8000189c <ukvmmap>
  p->kstack = va;
    8000255a:	0524b023          	sd	s2,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    8000255e:	07000613          	li	a2,112
    80002562:	4581                	li	a1,0
    80002564:	06048513          	addi	a0,s1,96
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	7a4080e7          	jalr	1956(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80002570:	fffff797          	auipc	a5,0xfffff
    80002574:	63078793          	addi	a5,a5,1584 # 80001ba0 <forkret>
    80002578:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    8000257a:	60bc                	ld	a5,64(s1)
    8000257c:	6705                	lui	a4,0x1
    8000257e:	97ba                	add	a5,a5,a4
    80002580:	f4bc                	sd	a5,104(s1)
}
    80002582:	8526                	mv	a0,s1
    80002584:	60e2                	ld	ra,24(sp)
    80002586:	6442                	ld	s0,16(sp)
    80002588:	64a2                	ld	s1,8(sp)
    8000258a:	6902                	ld	s2,0(sp)
    8000258c:	6105                	addi	sp,sp,32
    8000258e:	8082                	ret
    release(&p->lock);
    80002590:	8526                	mv	a0,s1
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	732080e7          	jalr	1842(ra) # 80000cc4 <release>
    return 0;
    8000259a:	84ca                	mv	s1,s2
    8000259c:	b7dd                	j	80002582 <allocproc+0xea>
    freeproc(p);
    8000259e:	8526                	mv	a0,s1
    800025a0:	00000097          	auipc	ra,0x0
    800025a4:	e56080e7          	jalr	-426(ra) # 800023f6 <freeproc>
    release(&p->lock);
    800025a8:	8526                	mv	a0,s1
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	71a080e7          	jalr	1818(ra) # 80000cc4 <release>
    return 0;
    800025b2:	84ca                	mv	s1,s2
    800025b4:	b7f9                	j	80002582 <allocproc+0xea>
    freeproc(p);
    800025b6:	8526                	mv	a0,s1
    800025b8:	00000097          	auipc	ra,0x0
    800025bc:	e3e080e7          	jalr	-450(ra) # 800023f6 <freeproc>
    release(&p->lock);
    800025c0:	8526                	mv	a0,s1
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	702080e7          	jalr	1794(ra) # 80000cc4 <release>
    return 0;
    800025ca:	84ca                	mv	s1,s2
    800025cc:	bf5d                	j	80002582 <allocproc+0xea>
    panic("kalloc");
    800025ce:	00006517          	auipc	a0,0x6
    800025d2:	c6250513          	addi	a0,a0,-926 # 80008230 <digits+0x1f0>
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	f72080e7          	jalr	-142(ra) # 80000548 <panic>

00000000800025de <userinit>:
{
    800025de:	1101                	addi	sp,sp,-32
    800025e0:	ec06                	sd	ra,24(sp)
    800025e2:	e822                	sd	s0,16(sp)
    800025e4:	e426                	sd	s1,8(sp)
    800025e6:	e04a                	sd	s2,0(sp)
    800025e8:	1000                	addi	s0,sp,32
  p = allocproc();
    800025ea:	00000097          	auipc	ra,0x0
    800025ee:	eae080e7          	jalr	-338(ra) # 80002498 <allocproc>
    800025f2:	84aa                	mv	s1,a0
  initproc = p;
    800025f4:	00007797          	auipc	a5,0x7
    800025f8:	a2a7b223          	sd	a0,-1500(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800025fc:	03400613          	li	a2,52
    80002600:	00006597          	auipc	a1,0x6
    80002604:	2c058593          	addi	a1,a1,704 # 800088c0 <initcode>
    80002608:	6928                	ld	a0,80(a0)
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	dd0080e7          	jalr	-560(ra) # 800013da <uvminit>
  p->sz = PGSIZE;
    80002612:	6905                	lui	s2,0x1
    80002614:	0524b423          	sd	s2,72(s1)
  vmcopypage(p->pagetable, p->kpagetable, 0, PGSIZE);
    80002618:	6685                	lui	a3,0x1
    8000261a:	4601                	li	a2,0
    8000261c:	1684b583          	ld	a1,360(s1)
    80002620:	68a8                	ld	a0,80(s1)
    80002622:	fffff097          	auipc	ra,0xfffff
    80002626:	38c080e7          	jalr	908(ra) # 800019ae <vmcopypage>
  p->trapframe->epc = 0;      // user program counter
    8000262a:	6cbc                	ld	a5,88(s1)
    8000262c:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002630:	6cbc                	ld	a5,88(s1)
    80002632:	0327b823          	sd	s2,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002636:	4641                	li	a2,16
    80002638:	00006597          	auipc	a1,0x6
    8000263c:	c9058593          	addi	a1,a1,-880 # 800082c8 <digits+0x288>
    80002640:	15848513          	addi	a0,s1,344
    80002644:	fffff097          	auipc	ra,0xfffff
    80002648:	81e080e7          	jalr	-2018(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    8000264c:	00006517          	auipc	a0,0x6
    80002650:	c8c50513          	addi	a0,a0,-884 # 800082d8 <digits+0x298>
    80002654:	00002097          	auipc	ra,0x2
    80002658:	ac6080e7          	jalr	-1338(ra) # 8000411a <namei>
    8000265c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002660:	4789                	li	a5,2
    80002662:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002664:	8526                	mv	a0,s1
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	65e080e7          	jalr	1630(ra) # 80000cc4 <release>
}
    8000266e:	60e2                	ld	ra,24(sp)
    80002670:	6442                	ld	s0,16(sp)
    80002672:	64a2                	ld	s1,8(sp)
    80002674:	6902                	ld	s2,0(sp)
    80002676:	6105                	addi	sp,sp,32
    80002678:	8082                	ret

000000008000267a <fork>:
{
    8000267a:	7179                	addi	sp,sp,-48
    8000267c:	f406                	sd	ra,40(sp)
    8000267e:	f022                	sd	s0,32(sp)
    80002680:	ec26                	sd	s1,24(sp)
    80002682:	e84a                	sd	s2,16(sp)
    80002684:	e44e                	sd	s3,8(sp)
    80002686:	e052                	sd	s4,0(sp)
    80002688:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000268a:	fffff097          	auipc	ra,0xfffff
    8000268e:	4de080e7          	jalr	1246(ra) # 80001b68 <myproc>
    80002692:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002694:	00000097          	auipc	ra,0x0
    80002698:	e04080e7          	jalr	-508(ra) # 80002498 <allocproc>
    8000269c:	c97d                	beqz	a0,80002792 <fork+0x118>
    8000269e:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800026a0:	04893603          	ld	a2,72(s2) # 1048 <_entry-0x7fffefb8>
    800026a4:	692c                	ld	a1,80(a0)
    800026a6:	05093503          	ld	a0,80(s2)
    800026aa:	fffff097          	auipc	ra,0xfffff
    800026ae:	f36080e7          	jalr	-202(ra) # 800015e0 <uvmcopy>
    800026b2:	06054163          	bltz	a0,80002714 <fork+0x9a>
  np->sz = p->sz;
    800026b6:	04893683          	ld	a3,72(s2)
    800026ba:	04d9b423          	sd	a3,72(s3)
  vmcopypage(np->pagetable, np->kpagetable, 0, np->sz);
    800026be:	4601                	li	a2,0
    800026c0:	1689b583          	ld	a1,360(s3)
    800026c4:	0509b503          	ld	a0,80(s3)
    800026c8:	fffff097          	auipc	ra,0xfffff
    800026cc:	2e6080e7          	jalr	742(ra) # 800019ae <vmcopypage>
  np->parent = p;
    800026d0:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    800026d4:	05893683          	ld	a3,88(s2)
    800026d8:	87b6                	mv	a5,a3
    800026da:	0589b703          	ld	a4,88(s3)
    800026de:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    800026e2:	0007b803          	ld	a6,0(a5)
    800026e6:	6788                	ld	a0,8(a5)
    800026e8:	6b8c                	ld	a1,16(a5)
    800026ea:	6f90                	ld	a2,24(a5)
    800026ec:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    800026f0:	e708                	sd	a0,8(a4)
    800026f2:	eb0c                	sd	a1,16(a4)
    800026f4:	ef10                	sd	a2,24(a4)
    800026f6:	02078793          	addi	a5,a5,32
    800026fa:	02070713          	addi	a4,a4,32
    800026fe:	fed792e3          	bne	a5,a3,800026e2 <fork+0x68>
  np->trapframe->a0 = 0;
    80002702:	0589b783          	ld	a5,88(s3)
    80002706:	0607b823          	sd	zero,112(a5)
    8000270a:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    8000270e:	15000a13          	li	s4,336
    80002712:	a03d                	j	80002740 <fork+0xc6>
    freeproc(np);
    80002714:	854e                	mv	a0,s3
    80002716:	00000097          	auipc	ra,0x0
    8000271a:	ce0080e7          	jalr	-800(ra) # 800023f6 <freeproc>
    release(&np->lock);
    8000271e:	854e                	mv	a0,s3
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	5a4080e7          	jalr	1444(ra) # 80000cc4 <release>
    return -1;
    80002728:	54fd                	li	s1,-1
    8000272a:	a899                	j	80002780 <fork+0x106>
      np->ofile[i] = filedup(p->ofile[i]);
    8000272c:	00002097          	auipc	ra,0x2
    80002730:	07a080e7          	jalr	122(ra) # 800047a6 <filedup>
    80002734:	009987b3          	add	a5,s3,s1
    80002738:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    8000273a:	04a1                	addi	s1,s1,8
    8000273c:	01448763          	beq	s1,s4,8000274a <fork+0xd0>
    if(p->ofile[i])
    80002740:	009907b3          	add	a5,s2,s1
    80002744:	6388                	ld	a0,0(a5)
    80002746:	f17d                	bnez	a0,8000272c <fork+0xb2>
    80002748:	bfcd                	j	8000273a <fork+0xc0>
  np->cwd = idup(p->cwd);
    8000274a:	15093503          	ld	a0,336(s2)
    8000274e:	00001097          	auipc	ra,0x1
    80002752:	1de080e7          	jalr	478(ra) # 8000392c <idup>
    80002756:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000275a:	4641                	li	a2,16
    8000275c:	15890593          	addi	a1,s2,344
    80002760:	15898513          	addi	a0,s3,344
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	6fe080e7          	jalr	1790(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    8000276c:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80002770:	4789                	li	a5,2
    80002772:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002776:	854e                	mv	a0,s3
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	54c080e7          	jalr	1356(ra) # 80000cc4 <release>
}
    80002780:	8526                	mv	a0,s1
    80002782:	70a2                	ld	ra,40(sp)
    80002784:	7402                	ld	s0,32(sp)
    80002786:	64e2                	ld	s1,24(sp)
    80002788:	6942                	ld	s2,16(sp)
    8000278a:	69a2                	ld	s3,8(sp)
    8000278c:	6a02                	ld	s4,0(sp)
    8000278e:	6145                	addi	sp,sp,48
    80002790:	8082                	ret
    return -1;
    80002792:	54fd                	li	s1,-1
    80002794:	b7f5                	j	80002780 <fork+0x106>

0000000080002796 <wait>:
{
    80002796:	715d                	addi	sp,sp,-80
    80002798:	e486                	sd	ra,72(sp)
    8000279a:	e0a2                	sd	s0,64(sp)
    8000279c:	fc26                	sd	s1,56(sp)
    8000279e:	f84a                	sd	s2,48(sp)
    800027a0:	f44e                	sd	s3,40(sp)
    800027a2:	f052                	sd	s4,32(sp)
    800027a4:	ec56                	sd	s5,24(sp)
    800027a6:	e85a                	sd	s6,16(sp)
    800027a8:	e45e                	sd	s7,8(sp)
    800027aa:	e062                	sd	s8,0(sp)
    800027ac:	0880                	addi	s0,sp,80
    800027ae:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800027b0:	fffff097          	auipc	ra,0xfffff
    800027b4:	3b8080e7          	jalr	952(ra) # 80001b68 <myproc>
    800027b8:	892a                	mv	s2,a0
  acquire(&p->lock);
    800027ba:	8c2a                	mv	s8,a0
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	454080e7          	jalr	1108(ra) # 80000c10 <acquire>
    havekids = 0;
    800027c4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800027c6:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800027c8:	00015997          	auipc	s3,0x15
    800027cc:	1a098993          	addi	s3,s3,416 # 80017968 <tickslock>
        havekids = 1;
    800027d0:	4a85                	li	s5,1
    havekids = 0;
    800027d2:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800027d4:	0000f497          	auipc	s1,0xf
    800027d8:	59448493          	addi	s1,s1,1428 # 80011d68 <proc>
    800027dc:	a08d                	j	8000283e <wait+0xa8>
          pid = np->pid;
    800027de:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027e2:	000b0e63          	beqz	s6,800027fe <wait+0x68>
    800027e6:	4691                	li	a3,4
    800027e8:	03448613          	addi	a2,s1,52
    800027ec:	85da                	mv	a1,s6
    800027ee:	05093503          	ld	a0,80(s2)
    800027f2:	fffff097          	auipc	ra,0xfffff
    800027f6:	ef2080e7          	jalr	-270(ra) # 800016e4 <copyout>
    800027fa:	02054263          	bltz	a0,8000281e <wait+0x88>
          freeproc(np);
    800027fe:	8526                	mv	a0,s1
    80002800:	00000097          	auipc	ra,0x0
    80002804:	bf6080e7          	jalr	-1034(ra) # 800023f6 <freeproc>
          release(&np->lock);
    80002808:	8526                	mv	a0,s1
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	4ba080e7          	jalr	1210(ra) # 80000cc4 <release>
          release(&p->lock);
    80002812:	854a                	mv	a0,s2
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	4b0080e7          	jalr	1200(ra) # 80000cc4 <release>
          return pid;
    8000281c:	a8a9                	j	80002876 <wait+0xe0>
            release(&np->lock);
    8000281e:	8526                	mv	a0,s1
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	4a4080e7          	jalr	1188(ra) # 80000cc4 <release>
            release(&p->lock);
    80002828:	854a                	mv	a0,s2
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	49a080e7          	jalr	1178(ra) # 80000cc4 <release>
            return -1;
    80002832:	59fd                	li	s3,-1
    80002834:	a089                	j	80002876 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002836:	17048493          	addi	s1,s1,368
    8000283a:	03348463          	beq	s1,s3,80002862 <wait+0xcc>
      if(np->parent == p){
    8000283e:	709c                	ld	a5,32(s1)
    80002840:	ff279be3          	bne	a5,s2,80002836 <wait+0xa0>
        acquire(&np->lock);
    80002844:	8526                	mv	a0,s1
    80002846:	ffffe097          	auipc	ra,0xffffe
    8000284a:	3ca080e7          	jalr	970(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    8000284e:	4c9c                	lw	a5,24(s1)
    80002850:	f94787e3          	beq	a5,s4,800027de <wait+0x48>
        release(&np->lock);
    80002854:	8526                	mv	a0,s1
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	46e080e7          	jalr	1134(ra) # 80000cc4 <release>
        havekids = 1;
    8000285e:	8756                	mv	a4,s5
    80002860:	bfd9                	j	80002836 <wait+0xa0>
    if(!havekids || p->killed){
    80002862:	c701                	beqz	a4,8000286a <wait+0xd4>
    80002864:	03092783          	lw	a5,48(s2)
    80002868:	c785                	beqz	a5,80002890 <wait+0xfa>
      release(&p->lock);
    8000286a:	854a                	mv	a0,s2
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	458080e7          	jalr	1112(ra) # 80000cc4 <release>
      return -1;
    80002874:	59fd                	li	s3,-1
}
    80002876:	854e                	mv	a0,s3
    80002878:	60a6                	ld	ra,72(sp)
    8000287a:	6406                	ld	s0,64(sp)
    8000287c:	74e2                	ld	s1,56(sp)
    8000287e:	7942                	ld	s2,48(sp)
    80002880:	79a2                	ld	s3,40(sp)
    80002882:	7a02                	ld	s4,32(sp)
    80002884:	6ae2                	ld	s5,24(sp)
    80002886:	6b42                	ld	s6,16(sp)
    80002888:	6ba2                	ld	s7,8(sp)
    8000288a:	6c02                	ld	s8,0(sp)
    8000288c:	6161                	addi	sp,sp,80
    8000288e:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002890:	85e2                	mv	a1,s8
    80002892:	854a                	mv	a0,s2
    80002894:	00000097          	auipc	ra,0x0
    80002898:	858080e7          	jalr	-1960(ra) # 800020ec <sleep>
    havekids = 0;
    8000289c:	bf1d                	j	800027d2 <wait+0x3c>

000000008000289e <swtch>:
    8000289e:	00153023          	sd	ra,0(a0)
    800028a2:	00253423          	sd	sp,8(a0)
    800028a6:	e900                	sd	s0,16(a0)
    800028a8:	ed04                	sd	s1,24(a0)
    800028aa:	03253023          	sd	s2,32(a0)
    800028ae:	03353423          	sd	s3,40(a0)
    800028b2:	03453823          	sd	s4,48(a0)
    800028b6:	03553c23          	sd	s5,56(a0)
    800028ba:	05653023          	sd	s6,64(a0)
    800028be:	05753423          	sd	s7,72(a0)
    800028c2:	05853823          	sd	s8,80(a0)
    800028c6:	05953c23          	sd	s9,88(a0)
    800028ca:	07a53023          	sd	s10,96(a0)
    800028ce:	07b53423          	sd	s11,104(a0)
    800028d2:	0005b083          	ld	ra,0(a1)
    800028d6:	0085b103          	ld	sp,8(a1)
    800028da:	6980                	ld	s0,16(a1)
    800028dc:	6d84                	ld	s1,24(a1)
    800028de:	0205b903          	ld	s2,32(a1)
    800028e2:	0285b983          	ld	s3,40(a1)
    800028e6:	0305ba03          	ld	s4,48(a1)
    800028ea:	0385ba83          	ld	s5,56(a1)
    800028ee:	0405bb03          	ld	s6,64(a1)
    800028f2:	0485bb83          	ld	s7,72(a1)
    800028f6:	0505bc03          	ld	s8,80(a1)
    800028fa:	0585bc83          	ld	s9,88(a1)
    800028fe:	0605bd03          	ld	s10,96(a1)
    80002902:	0685bd83          	ld	s11,104(a1)
    80002906:	8082                	ret

0000000080002908 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002908:	1141                	addi	sp,sp,-16
    8000290a:	e406                	sd	ra,8(sp)
    8000290c:	e022                	sd	s0,0(sp)
    8000290e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002910:	00006597          	auipc	a1,0x6
    80002914:	a2058593          	addi	a1,a1,-1504 # 80008330 <states.1745+0x28>
    80002918:	00015517          	auipc	a0,0x15
    8000291c:	05050513          	addi	a0,a0,80 # 80017968 <tickslock>
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	260080e7          	jalr	608(ra) # 80000b80 <initlock>
}
    80002928:	60a2                	ld	ra,8(sp)
    8000292a:	6402                	ld	s0,0(sp)
    8000292c:	0141                	addi	sp,sp,16
    8000292e:	8082                	ret

0000000080002930 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002930:	1141                	addi	sp,sp,-16
    80002932:	e422                	sd	s0,8(sp)
    80002934:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002936:	00003797          	auipc	a5,0x3
    8000293a:	56a78793          	addi	a5,a5,1386 # 80005ea0 <kernelvec>
    8000293e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002942:	6422                	ld	s0,8(sp)
    80002944:	0141                	addi	sp,sp,16
    80002946:	8082                	ret

0000000080002948 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002948:	1141                	addi	sp,sp,-16
    8000294a:	e406                	sd	ra,8(sp)
    8000294c:	e022                	sd	s0,0(sp)
    8000294e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002950:	fffff097          	auipc	ra,0xfffff
    80002954:	218080e7          	jalr	536(ra) # 80001b68 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002958:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000295c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000295e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002962:	00004617          	auipc	a2,0x4
    80002966:	69e60613          	addi	a2,a2,1694 # 80007000 <_trampoline>
    8000296a:	00004697          	auipc	a3,0x4
    8000296e:	69668693          	addi	a3,a3,1686 # 80007000 <_trampoline>
    80002972:	8e91                	sub	a3,a3,a2
    80002974:	040007b7          	lui	a5,0x4000
    80002978:	17fd                	addi	a5,a5,-1
    8000297a:	07b2                	slli	a5,a5,0xc
    8000297c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000297e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002982:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002984:	180026f3          	csrr	a3,satp
    80002988:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000298a:	6d38                	ld	a4,88(a0)
    8000298c:	6134                	ld	a3,64(a0)
    8000298e:	6585                	lui	a1,0x1
    80002990:	96ae                	add	a3,a3,a1
    80002992:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002994:	6d38                	ld	a4,88(a0)
    80002996:	00000697          	auipc	a3,0x0
    8000299a:	13868693          	addi	a3,a3,312 # 80002ace <usertrap>
    8000299e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029a0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029a2:	8692                	mv	a3,tp
    800029a4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029aa:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029ae:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029b6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029b8:	6f18                	ld	a4,24(a4)
    800029ba:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029be:	692c                	ld	a1,80(a0)
    800029c0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029c2:	00004717          	auipc	a4,0x4
    800029c6:	6ce70713          	addi	a4,a4,1742 # 80007090 <userret>
    800029ca:	8f11                	sub	a4,a4,a2
    800029cc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029ce:	577d                	li	a4,-1
    800029d0:	177e                	slli	a4,a4,0x3f
    800029d2:	8dd9                	or	a1,a1,a4
    800029d4:	02000537          	lui	a0,0x2000
    800029d8:	157d                	addi	a0,a0,-1
    800029da:	0536                	slli	a0,a0,0xd
    800029dc:	9782                	jalr	a5
}
    800029de:	60a2                	ld	ra,8(sp)
    800029e0:	6402                	ld	s0,0(sp)
    800029e2:	0141                	addi	sp,sp,16
    800029e4:	8082                	ret

00000000800029e6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029e6:	1101                	addi	sp,sp,-32
    800029e8:	ec06                	sd	ra,24(sp)
    800029ea:	e822                	sd	s0,16(sp)
    800029ec:	e426                	sd	s1,8(sp)
    800029ee:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029f0:	00015497          	auipc	s1,0x15
    800029f4:	f7848493          	addi	s1,s1,-136 # 80017968 <tickslock>
    800029f8:	8526                	mv	a0,s1
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	216080e7          	jalr	534(ra) # 80000c10 <acquire>
  ticks++;
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	61e50513          	addi	a0,a0,1566 # 80009020 <ticks>
    80002a0a:	411c                	lw	a5,0(a0)
    80002a0c:	2785                	addiw	a5,a5,1
    80002a0e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a10:	fffff097          	auipc	ra,0xfffff
    80002a14:	75a080e7          	jalr	1882(ra) # 8000216a <wakeup>
  release(&tickslock);
    80002a18:	8526                	mv	a0,s1
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	2aa080e7          	jalr	682(ra) # 80000cc4 <release>
}
    80002a22:	60e2                	ld	ra,24(sp)
    80002a24:	6442                	ld	s0,16(sp)
    80002a26:	64a2                	ld	s1,8(sp)
    80002a28:	6105                	addi	sp,sp,32
    80002a2a:	8082                	ret

0000000080002a2c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a2c:	1101                	addi	sp,sp,-32
    80002a2e:	ec06                	sd	ra,24(sp)
    80002a30:	e822                	sd	s0,16(sp)
    80002a32:	e426                	sd	s1,8(sp)
    80002a34:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a36:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a3a:	00074d63          	bltz	a4,80002a54 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a3e:	57fd                	li	a5,-1
    80002a40:	17fe                	slli	a5,a5,0x3f
    80002a42:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a44:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a46:	06f70363          	beq	a4,a5,80002aac <devintr+0x80>
  }
}
    80002a4a:	60e2                	ld	ra,24(sp)
    80002a4c:	6442                	ld	s0,16(sp)
    80002a4e:	64a2                	ld	s1,8(sp)
    80002a50:	6105                	addi	sp,sp,32
    80002a52:	8082                	ret
     (scause & 0xff) == 9){
    80002a54:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a58:	46a5                	li	a3,9
    80002a5a:	fed792e3          	bne	a5,a3,80002a3e <devintr+0x12>
    int irq = plic_claim();
    80002a5e:	00003097          	auipc	ra,0x3
    80002a62:	54a080e7          	jalr	1354(ra) # 80005fa8 <plic_claim>
    80002a66:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a68:	47a9                	li	a5,10
    80002a6a:	02f50763          	beq	a0,a5,80002a98 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a6e:	4785                	li	a5,1
    80002a70:	02f50963          	beq	a0,a5,80002aa2 <devintr+0x76>
    return 1;
    80002a74:	4505                	li	a0,1
    } else if(irq){
    80002a76:	d8f1                	beqz	s1,80002a4a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a78:	85a6                	mv	a1,s1
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	8be50513          	addi	a0,a0,-1858 # 80008338 <states.1745+0x30>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	b10080e7          	jalr	-1264(ra) # 80000592 <printf>
      plic_complete(irq);
    80002a8a:	8526                	mv	a0,s1
    80002a8c:	00003097          	auipc	ra,0x3
    80002a90:	540080e7          	jalr	1344(ra) # 80005fcc <plic_complete>
    return 1;
    80002a94:	4505                	li	a0,1
    80002a96:	bf55                	j	80002a4a <devintr+0x1e>
      uartintr();
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	f3c080e7          	jalr	-196(ra) # 800009d4 <uartintr>
    80002aa0:	b7ed                	j	80002a8a <devintr+0x5e>
      virtio_disk_intr();
    80002aa2:	00004097          	auipc	ra,0x4
    80002aa6:	9c4080e7          	jalr	-1596(ra) # 80006466 <virtio_disk_intr>
    80002aaa:	b7c5                	j	80002a8a <devintr+0x5e>
    if(cpuid() == 0){
    80002aac:	fffff097          	auipc	ra,0xfffff
    80002ab0:	090080e7          	jalr	144(ra) # 80001b3c <cpuid>
    80002ab4:	c901                	beqz	a0,80002ac4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ab6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002aba:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002abc:	14479073          	csrw	sip,a5
    return 2;
    80002ac0:	4509                	li	a0,2
    80002ac2:	b761                	j	80002a4a <devintr+0x1e>
      clockintr();
    80002ac4:	00000097          	auipc	ra,0x0
    80002ac8:	f22080e7          	jalr	-222(ra) # 800029e6 <clockintr>
    80002acc:	b7ed                	j	80002ab6 <devintr+0x8a>

0000000080002ace <usertrap>:
{
    80002ace:	1101                	addi	sp,sp,-32
    80002ad0:	ec06                	sd	ra,24(sp)
    80002ad2:	e822                	sd	s0,16(sp)
    80002ad4:	e426                	sd	s1,8(sp)
    80002ad6:	e04a                	sd	s2,0(sp)
    80002ad8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ada:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ade:	1007f793          	andi	a5,a5,256
    80002ae2:	e3ad                	bnez	a5,80002b44 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ae4:	00003797          	auipc	a5,0x3
    80002ae8:	3bc78793          	addi	a5,a5,956 # 80005ea0 <kernelvec>
    80002aec:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002af0:	fffff097          	auipc	ra,0xfffff
    80002af4:	078080e7          	jalr	120(ra) # 80001b68 <myproc>
    80002af8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002afa:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002afc:	14102773          	csrr	a4,sepc
    80002b00:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b02:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b06:	47a1                	li	a5,8
    80002b08:	04f71c63          	bne	a4,a5,80002b60 <usertrap+0x92>
    if(p->killed)
    80002b0c:	591c                	lw	a5,48(a0)
    80002b0e:	e3b9                	bnez	a5,80002b54 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b10:	6cb8                	ld	a4,88(s1)
    80002b12:	6f1c                	ld	a5,24(a4)
    80002b14:	0791                	addi	a5,a5,4
    80002b16:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b18:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b1c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b20:	10079073          	csrw	sstatus,a5
    syscall();
    80002b24:	00000097          	auipc	ra,0x0
    80002b28:	2e0080e7          	jalr	736(ra) # 80002e04 <syscall>
  if(p->killed)
    80002b2c:	589c                	lw	a5,48(s1)
    80002b2e:	ebc1                	bnez	a5,80002bbe <usertrap+0xf0>
  usertrapret();
    80002b30:	00000097          	auipc	ra,0x0
    80002b34:	e18080e7          	jalr	-488(ra) # 80002948 <usertrapret>
}
    80002b38:	60e2                	ld	ra,24(sp)
    80002b3a:	6442                	ld	s0,16(sp)
    80002b3c:	64a2                	ld	s1,8(sp)
    80002b3e:	6902                	ld	s2,0(sp)
    80002b40:	6105                	addi	sp,sp,32
    80002b42:	8082                	ret
    panic("usertrap: not from user mode");
    80002b44:	00006517          	auipc	a0,0x6
    80002b48:	81450513          	addi	a0,a0,-2028 # 80008358 <states.1745+0x50>
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	9fc080e7          	jalr	-1540(ra) # 80000548 <panic>
      exit(-1);
    80002b54:	557d                	li	a0,-1
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	450080e7          	jalr	1104(ra) # 80001fa6 <exit>
    80002b5e:	bf4d                	j	80002b10 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b60:	00000097          	auipc	ra,0x0
    80002b64:	ecc080e7          	jalr	-308(ra) # 80002a2c <devintr>
    80002b68:	892a                	mv	s2,a0
    80002b6a:	c501                	beqz	a0,80002b72 <usertrap+0xa4>
  if(p->killed)
    80002b6c:	589c                	lw	a5,48(s1)
    80002b6e:	c3a1                	beqz	a5,80002bae <usertrap+0xe0>
    80002b70:	a815                	j	80002ba4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b72:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b76:	5c90                	lw	a2,56(s1)
    80002b78:	00006517          	auipc	a0,0x6
    80002b7c:	80050513          	addi	a0,a0,-2048 # 80008378 <states.1745+0x70>
    80002b80:	ffffe097          	auipc	ra,0xffffe
    80002b84:	a12080e7          	jalr	-1518(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b88:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b8c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b90:	00006517          	auipc	a0,0x6
    80002b94:	81850513          	addi	a0,a0,-2024 # 800083a8 <states.1745+0xa0>
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	9fa080e7          	jalr	-1542(ra) # 80000592 <printf>
    p->killed = 1;
    80002ba0:	4785                	li	a5,1
    80002ba2:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002ba4:	557d                	li	a0,-1
    80002ba6:	fffff097          	auipc	ra,0xfffff
    80002baa:	400080e7          	jalr	1024(ra) # 80001fa6 <exit>
  if(which_dev == 2)
    80002bae:	4789                	li	a5,2
    80002bb0:	f8f910e3          	bne	s2,a5,80002b30 <usertrap+0x62>
    yield();
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	4fc080e7          	jalr	1276(ra) # 800020b0 <yield>
    80002bbc:	bf95                	j	80002b30 <usertrap+0x62>
  int which_dev = 0;
    80002bbe:	4901                	li	s2,0
    80002bc0:	b7d5                	j	80002ba4 <usertrap+0xd6>

0000000080002bc2 <kerneltrap>:
{
    80002bc2:	7179                	addi	sp,sp,-48
    80002bc4:	f406                	sd	ra,40(sp)
    80002bc6:	f022                	sd	s0,32(sp)
    80002bc8:	ec26                	sd	s1,24(sp)
    80002bca:	e84a                	sd	s2,16(sp)
    80002bcc:	e44e                	sd	s3,8(sp)
    80002bce:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bdc:	1004f793          	andi	a5,s1,256
    80002be0:	cb85                	beqz	a5,80002c10 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002be2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002be6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002be8:	ef85                	bnez	a5,80002c20 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bea:	00000097          	auipc	ra,0x0
    80002bee:	e42080e7          	jalr	-446(ra) # 80002a2c <devintr>
    80002bf2:	cd1d                	beqz	a0,80002c30 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bf4:	4789                	li	a5,2
    80002bf6:	06f50a63          	beq	a0,a5,80002c6a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bfa:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bfe:	10049073          	csrw	sstatus,s1
}
    80002c02:	70a2                	ld	ra,40(sp)
    80002c04:	7402                	ld	s0,32(sp)
    80002c06:	64e2                	ld	s1,24(sp)
    80002c08:	6942                	ld	s2,16(sp)
    80002c0a:	69a2                	ld	s3,8(sp)
    80002c0c:	6145                	addi	sp,sp,48
    80002c0e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c10:	00005517          	auipc	a0,0x5
    80002c14:	7b850513          	addi	a0,a0,1976 # 800083c8 <states.1745+0xc0>
    80002c18:	ffffe097          	auipc	ra,0xffffe
    80002c1c:	930080e7          	jalr	-1744(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c20:	00005517          	auipc	a0,0x5
    80002c24:	7d050513          	addi	a0,a0,2000 # 800083f0 <states.1745+0xe8>
    80002c28:	ffffe097          	auipc	ra,0xffffe
    80002c2c:	920080e7          	jalr	-1760(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002c30:	85ce                	mv	a1,s3
    80002c32:	00005517          	auipc	a0,0x5
    80002c36:	7de50513          	addi	a0,a0,2014 # 80008410 <states.1745+0x108>
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	958080e7          	jalr	-1704(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c42:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c46:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c4a:	00005517          	auipc	a0,0x5
    80002c4e:	7d650513          	addi	a0,a0,2006 # 80008420 <states.1745+0x118>
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	940080e7          	jalr	-1728(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002c5a:	00005517          	auipc	a0,0x5
    80002c5e:	7de50513          	addi	a0,a0,2014 # 80008438 <states.1745+0x130>
    80002c62:	ffffe097          	auipc	ra,0xffffe
    80002c66:	8e6080e7          	jalr	-1818(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	efe080e7          	jalr	-258(ra) # 80001b68 <myproc>
    80002c72:	d541                	beqz	a0,80002bfa <kerneltrap+0x38>
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	ef4080e7          	jalr	-268(ra) # 80001b68 <myproc>
    80002c7c:	4d18                	lw	a4,24(a0)
    80002c7e:	478d                	li	a5,3
    80002c80:	f6f71de3          	bne	a4,a5,80002bfa <kerneltrap+0x38>
    yield();
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	42c080e7          	jalr	1068(ra) # 800020b0 <yield>
    80002c8c:	b7bd                	j	80002bfa <kerneltrap+0x38>

0000000080002c8e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c8e:	1101                	addi	sp,sp,-32
    80002c90:	ec06                	sd	ra,24(sp)
    80002c92:	e822                	sd	s0,16(sp)
    80002c94:	e426                	sd	s1,8(sp)
    80002c96:	1000                	addi	s0,sp,32
    80002c98:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	ece080e7          	jalr	-306(ra) # 80001b68 <myproc>
  switch (n) {
    80002ca2:	4795                	li	a5,5
    80002ca4:	0497e163          	bltu	a5,s1,80002ce6 <argraw+0x58>
    80002ca8:	048a                	slli	s1,s1,0x2
    80002caa:	00005717          	auipc	a4,0x5
    80002cae:	7c670713          	addi	a4,a4,1990 # 80008470 <states.1745+0x168>
    80002cb2:	94ba                	add	s1,s1,a4
    80002cb4:	409c                	lw	a5,0(s1)
    80002cb6:	97ba                	add	a5,a5,a4
    80002cb8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cba:	6d3c                	ld	a5,88(a0)
    80002cbc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cbe:	60e2                	ld	ra,24(sp)
    80002cc0:	6442                	ld	s0,16(sp)
    80002cc2:	64a2                	ld	s1,8(sp)
    80002cc4:	6105                	addi	sp,sp,32
    80002cc6:	8082                	ret
    return p->trapframe->a1;
    80002cc8:	6d3c                	ld	a5,88(a0)
    80002cca:	7fa8                	ld	a0,120(a5)
    80002ccc:	bfcd                	j	80002cbe <argraw+0x30>
    return p->trapframe->a2;
    80002cce:	6d3c                	ld	a5,88(a0)
    80002cd0:	63c8                	ld	a0,128(a5)
    80002cd2:	b7f5                	j	80002cbe <argraw+0x30>
    return p->trapframe->a3;
    80002cd4:	6d3c                	ld	a5,88(a0)
    80002cd6:	67c8                	ld	a0,136(a5)
    80002cd8:	b7dd                	j	80002cbe <argraw+0x30>
    return p->trapframe->a4;
    80002cda:	6d3c                	ld	a5,88(a0)
    80002cdc:	6bc8                	ld	a0,144(a5)
    80002cde:	b7c5                	j	80002cbe <argraw+0x30>
    return p->trapframe->a5;
    80002ce0:	6d3c                	ld	a5,88(a0)
    80002ce2:	6fc8                	ld	a0,152(a5)
    80002ce4:	bfe9                	j	80002cbe <argraw+0x30>
  panic("argraw");
    80002ce6:	00005517          	auipc	a0,0x5
    80002cea:	76250513          	addi	a0,a0,1890 # 80008448 <states.1745+0x140>
    80002cee:	ffffe097          	auipc	ra,0xffffe
    80002cf2:	85a080e7          	jalr	-1958(ra) # 80000548 <panic>

0000000080002cf6 <fetchaddr>:
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	e426                	sd	s1,8(sp)
    80002cfe:	e04a                	sd	s2,0(sp)
    80002d00:	1000                	addi	s0,sp,32
    80002d02:	84aa                	mv	s1,a0
    80002d04:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	e62080e7          	jalr	-414(ra) # 80001b68 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d0e:	653c                	ld	a5,72(a0)
    80002d10:	02f4f863          	bgeu	s1,a5,80002d40 <fetchaddr+0x4a>
    80002d14:	00848713          	addi	a4,s1,8
    80002d18:	02e7e663          	bltu	a5,a4,80002d44 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d1c:	46a1                	li	a3,8
    80002d1e:	8626                	mv	a2,s1
    80002d20:	85ca                	mv	a1,s2
    80002d22:	6928                	ld	a0,80(a0)
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	a4c080e7          	jalr	-1460(ra) # 80001770 <copyin>
    80002d2c:	00a03533          	snez	a0,a0
    80002d30:	40a00533          	neg	a0,a0
}
    80002d34:	60e2                	ld	ra,24(sp)
    80002d36:	6442                	ld	s0,16(sp)
    80002d38:	64a2                	ld	s1,8(sp)
    80002d3a:	6902                	ld	s2,0(sp)
    80002d3c:	6105                	addi	sp,sp,32
    80002d3e:	8082                	ret
    return -1;
    80002d40:	557d                	li	a0,-1
    80002d42:	bfcd                	j	80002d34 <fetchaddr+0x3e>
    80002d44:	557d                	li	a0,-1
    80002d46:	b7fd                	j	80002d34 <fetchaddr+0x3e>

0000000080002d48 <fetchstr>:
{
    80002d48:	7179                	addi	sp,sp,-48
    80002d4a:	f406                	sd	ra,40(sp)
    80002d4c:	f022                	sd	s0,32(sp)
    80002d4e:	ec26                	sd	s1,24(sp)
    80002d50:	e84a                	sd	s2,16(sp)
    80002d52:	e44e                	sd	s3,8(sp)
    80002d54:	1800                	addi	s0,sp,48
    80002d56:	892a                	mv	s2,a0
    80002d58:	84ae                	mv	s1,a1
    80002d5a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	e0c080e7          	jalr	-500(ra) # 80001b68 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d64:	86ce                	mv	a3,s3
    80002d66:	864a                	mv	a2,s2
    80002d68:	85a6                	mv	a1,s1
    80002d6a:	6928                	ld	a0,80(a0)
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	a1c080e7          	jalr	-1508(ra) # 80001788 <copyinstr>
  if(err < 0)
    80002d74:	00054763          	bltz	a0,80002d82 <fetchstr+0x3a>
  return strlen(buf);
    80002d78:	8526                	mv	a0,s1
    80002d7a:	ffffe097          	auipc	ra,0xffffe
    80002d7e:	11a080e7          	jalr	282(ra) # 80000e94 <strlen>
}
    80002d82:	70a2                	ld	ra,40(sp)
    80002d84:	7402                	ld	s0,32(sp)
    80002d86:	64e2                	ld	s1,24(sp)
    80002d88:	6942                	ld	s2,16(sp)
    80002d8a:	69a2                	ld	s3,8(sp)
    80002d8c:	6145                	addi	sp,sp,48
    80002d8e:	8082                	ret

0000000080002d90 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d90:	1101                	addi	sp,sp,-32
    80002d92:	ec06                	sd	ra,24(sp)
    80002d94:	e822                	sd	s0,16(sp)
    80002d96:	e426                	sd	s1,8(sp)
    80002d98:	1000                	addi	s0,sp,32
    80002d9a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d9c:	00000097          	auipc	ra,0x0
    80002da0:	ef2080e7          	jalr	-270(ra) # 80002c8e <argraw>
    80002da4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002da6:	4501                	li	a0,0
    80002da8:	60e2                	ld	ra,24(sp)
    80002daa:	6442                	ld	s0,16(sp)
    80002dac:	64a2                	ld	s1,8(sp)
    80002dae:	6105                	addi	sp,sp,32
    80002db0:	8082                	ret

0000000080002db2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002db2:	1101                	addi	sp,sp,-32
    80002db4:	ec06                	sd	ra,24(sp)
    80002db6:	e822                	sd	s0,16(sp)
    80002db8:	e426                	sd	s1,8(sp)
    80002dba:	1000                	addi	s0,sp,32
    80002dbc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dbe:	00000097          	auipc	ra,0x0
    80002dc2:	ed0080e7          	jalr	-304(ra) # 80002c8e <argraw>
    80002dc6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002dc8:	4501                	li	a0,0
    80002dca:	60e2                	ld	ra,24(sp)
    80002dcc:	6442                	ld	s0,16(sp)
    80002dce:	64a2                	ld	s1,8(sp)
    80002dd0:	6105                	addi	sp,sp,32
    80002dd2:	8082                	ret

0000000080002dd4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002dd4:	1101                	addi	sp,sp,-32
    80002dd6:	ec06                	sd	ra,24(sp)
    80002dd8:	e822                	sd	s0,16(sp)
    80002dda:	e426                	sd	s1,8(sp)
    80002ddc:	e04a                	sd	s2,0(sp)
    80002dde:	1000                	addi	s0,sp,32
    80002de0:	84ae                	mv	s1,a1
    80002de2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002de4:	00000097          	auipc	ra,0x0
    80002de8:	eaa080e7          	jalr	-342(ra) # 80002c8e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002dec:	864a                	mv	a2,s2
    80002dee:	85a6                	mv	a1,s1
    80002df0:	00000097          	auipc	ra,0x0
    80002df4:	f58080e7          	jalr	-168(ra) # 80002d48 <fetchstr>
}
    80002df8:	60e2                	ld	ra,24(sp)
    80002dfa:	6442                	ld	s0,16(sp)
    80002dfc:	64a2                	ld	s1,8(sp)
    80002dfe:	6902                	ld	s2,0(sp)
    80002e00:	6105                	addi	sp,sp,32
    80002e02:	8082                	ret

0000000080002e04 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e04:	1101                	addi	sp,sp,-32
    80002e06:	ec06                	sd	ra,24(sp)
    80002e08:	e822                	sd	s0,16(sp)
    80002e0a:	e426                	sd	s1,8(sp)
    80002e0c:	e04a                	sd	s2,0(sp)
    80002e0e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e10:	fffff097          	auipc	ra,0xfffff
    80002e14:	d58080e7          	jalr	-680(ra) # 80001b68 <myproc>
    80002e18:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e1a:	05853903          	ld	s2,88(a0)
    80002e1e:	0a893783          	ld	a5,168(s2)
    80002e22:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e26:	37fd                	addiw	a5,a5,-1
    80002e28:	4751                	li	a4,20
    80002e2a:	00f76f63          	bltu	a4,a5,80002e48 <syscall+0x44>
    80002e2e:	00369713          	slli	a4,a3,0x3
    80002e32:	00005797          	auipc	a5,0x5
    80002e36:	65678793          	addi	a5,a5,1622 # 80008488 <syscalls>
    80002e3a:	97ba                	add	a5,a5,a4
    80002e3c:	639c                	ld	a5,0(a5)
    80002e3e:	c789                	beqz	a5,80002e48 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e40:	9782                	jalr	a5
    80002e42:	06a93823          	sd	a0,112(s2)
    80002e46:	a839                	j	80002e64 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e48:	15848613          	addi	a2,s1,344
    80002e4c:	5c8c                	lw	a1,56(s1)
    80002e4e:	00005517          	auipc	a0,0x5
    80002e52:	60250513          	addi	a0,a0,1538 # 80008450 <states.1745+0x148>
    80002e56:	ffffd097          	auipc	ra,0xffffd
    80002e5a:	73c080e7          	jalr	1852(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e5e:	6cbc                	ld	a5,88(s1)
    80002e60:	577d                	li	a4,-1
    80002e62:	fbb8                	sd	a4,112(a5)
  }
}
    80002e64:	60e2                	ld	ra,24(sp)
    80002e66:	6442                	ld	s0,16(sp)
    80002e68:	64a2                	ld	s1,8(sp)
    80002e6a:	6902                	ld	s2,0(sp)
    80002e6c:	6105                	addi	sp,sp,32
    80002e6e:	8082                	ret

0000000080002e70 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e70:	1101                	addi	sp,sp,-32
    80002e72:	ec06                	sd	ra,24(sp)
    80002e74:	e822                	sd	s0,16(sp)
    80002e76:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e78:	fec40593          	addi	a1,s0,-20
    80002e7c:	4501                	li	a0,0
    80002e7e:	00000097          	auipc	ra,0x0
    80002e82:	f12080e7          	jalr	-238(ra) # 80002d90 <argint>
    return -1;
    80002e86:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e88:	00054963          	bltz	a0,80002e9a <sys_exit+0x2a>
  exit(n);
    80002e8c:	fec42503          	lw	a0,-20(s0)
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	116080e7          	jalr	278(ra) # 80001fa6 <exit>
  return 0;  // not reached
    80002e98:	4781                	li	a5,0
}
    80002e9a:	853e                	mv	a0,a5
    80002e9c:	60e2                	ld	ra,24(sp)
    80002e9e:	6442                	ld	s0,16(sp)
    80002ea0:	6105                	addi	sp,sp,32
    80002ea2:	8082                	ret

0000000080002ea4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ea4:	1141                	addi	sp,sp,-16
    80002ea6:	e406                	sd	ra,8(sp)
    80002ea8:	e022                	sd	s0,0(sp)
    80002eaa:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002eac:	fffff097          	auipc	ra,0xfffff
    80002eb0:	cbc080e7          	jalr	-836(ra) # 80001b68 <myproc>
}
    80002eb4:	5d08                	lw	a0,56(a0)
    80002eb6:	60a2                	ld	ra,8(sp)
    80002eb8:	6402                	ld	s0,0(sp)
    80002eba:	0141                	addi	sp,sp,16
    80002ebc:	8082                	ret

0000000080002ebe <sys_fork>:

uint64
sys_fork(void)
{
    80002ebe:	1141                	addi	sp,sp,-16
    80002ec0:	e406                	sd	ra,8(sp)
    80002ec2:	e022                	sd	s0,0(sp)
    80002ec4:	0800                	addi	s0,sp,16
  return fork();
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	7b4080e7          	jalr	1972(ra) # 8000267a <fork>
}
    80002ece:	60a2                	ld	ra,8(sp)
    80002ed0:	6402                	ld	s0,0(sp)
    80002ed2:	0141                	addi	sp,sp,16
    80002ed4:	8082                	ret

0000000080002ed6 <sys_wait>:

uint64
sys_wait(void)
{
    80002ed6:	1101                	addi	sp,sp,-32
    80002ed8:	ec06                	sd	ra,24(sp)
    80002eda:	e822                	sd	s0,16(sp)
    80002edc:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ede:	fe840593          	addi	a1,s0,-24
    80002ee2:	4501                	li	a0,0
    80002ee4:	00000097          	auipc	ra,0x0
    80002ee8:	ece080e7          	jalr	-306(ra) # 80002db2 <argaddr>
    80002eec:	87aa                	mv	a5,a0
    return -1;
    80002eee:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ef0:	0007c863          	bltz	a5,80002f00 <sys_wait+0x2a>
  return wait(p);
    80002ef4:	fe843503          	ld	a0,-24(s0)
    80002ef8:	00000097          	auipc	ra,0x0
    80002efc:	89e080e7          	jalr	-1890(ra) # 80002796 <wait>
}
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	6105                	addi	sp,sp,32
    80002f06:	8082                	ret

0000000080002f08 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f08:	715d                	addi	sp,sp,-80
    80002f0a:	e486                	sd	ra,72(sp)
    80002f0c:	e0a2                	sd	s0,64(sp)
    80002f0e:	fc26                	sd	s1,56(sp)
    80002f10:	f84a                	sd	s2,48(sp)
    80002f12:	f44e                	sd	s3,40(sp)
    80002f14:	f052                	sd	s4,32(sp)
    80002f16:	ec56                	sd	s5,24(sp)
    80002f18:	e85a                	sd	s6,16(sp)
    80002f1a:	0880                	addi	s0,sp,80
  int addr;
  int n;
  struct proc *p=myproc();
    80002f1c:	fffff097          	auipc	ra,0xfffff
    80002f20:	c4c080e7          	jalr	-948(ra) # 80001b68 <myproc>
    80002f24:	8a2a                	mv	s4,a0
  if(argint(0, &n) < 0)
    80002f26:	fbc40593          	addi	a1,s0,-68
    80002f2a:	4501                	li	a0,0
    80002f2c:	00000097          	auipc	ra,0x0
    80002f30:	e64080e7          	jalr	-412(ra) # 80002d90 <argint>
    return -1;
    80002f34:	59fd                	li	s3,-1
  if(argint(0, &n) < 0)
    80002f36:	04054b63          	bltz	a0,80002f8c <sys_sbrk+0x84>
  addr = p->sz;
    80002f3a:	048a2983          	lw	s3,72(s4)
  if(growproc(n) < 0)
    80002f3e:	fbc42503          	lw	a0,-68(s0)
    80002f42:	fffff097          	auipc	ra,0xfffff
    80002f46:	dd8080e7          	jalr	-552(ra) # 80001d1a <growproc>
    80002f4a:	06054663          	bltz	a0,80002fb6 <sys_sbrk+0xae>
    return -1;
  if(n>0){
    80002f4e:	fbc42683          	lw	a3,-68(s0)
    80002f52:	04d04863          	bgtz	a3,80002fa2 <sys_sbrk+0x9a>
    vmcopypage(p->pagetable,p->kpagetable,addr,n);
  }else{
      for(int j=addr-PGSIZE;j>=addr+n;j-=PGSIZE){
    80002f56:	74fd                	lui	s1,0xfffff
    80002f58:	013484bb          	addw	s1,s1,s3
    80002f5c:	77fd                	lui	a5,0xfffff
    80002f5e:	02d7c763          	blt	a5,a3,80002f8c <sys_sbrk+0x84>
    80002f62:	8926                	mv	s2,s1
    80002f64:	7b7d                	lui	s6,0xfffff
    80002f66:	7afd                	lui	s5,0xfffff
          uvmunmap(p->kpagetable,j,1,0);
    80002f68:	4681                	li	a3,0
    80002f6a:	4605                	li	a2,1
    80002f6c:	85ca                	mv	a1,s2
    80002f6e:	168a3503          	ld	a0,360(s4)
    80002f72:	ffffe097          	auipc	ra,0xffffe
    80002f76:	376080e7          	jalr	886(ra) # 800012e8 <uvmunmap>
      for(int j=addr-PGSIZE;j>=addr+n;j-=PGSIZE){
    80002f7a:	009b04bb          	addw	s1,s6,s1
    80002f7e:	9956                	add	s2,s2,s5
    80002f80:	fbc42783          	lw	a5,-68(s0)
    80002f84:	013787bb          	addw	a5,a5,s3
    80002f88:	fef4d0e3          	bge	s1,a5,80002f68 <sys_sbrk+0x60>
      }
  }
  return addr;
}
    80002f8c:	854e                	mv	a0,s3
    80002f8e:	60a6                	ld	ra,72(sp)
    80002f90:	6406                	ld	s0,64(sp)
    80002f92:	74e2                	ld	s1,56(sp)
    80002f94:	7942                	ld	s2,48(sp)
    80002f96:	79a2                	ld	s3,40(sp)
    80002f98:	7a02                	ld	s4,32(sp)
    80002f9a:	6ae2                	ld	s5,24(sp)
    80002f9c:	6b42                	ld	s6,16(sp)
    80002f9e:	6161                	addi	sp,sp,80
    80002fa0:	8082                	ret
    vmcopypage(p->pagetable,p->kpagetable,addr,n);
    80002fa2:	864e                	mv	a2,s3
    80002fa4:	168a3583          	ld	a1,360(s4)
    80002fa8:	050a3503          	ld	a0,80(s4)
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	a02080e7          	jalr	-1534(ra) # 800019ae <vmcopypage>
    80002fb4:	bfe1                	j	80002f8c <sys_sbrk+0x84>
    return -1;
    80002fb6:	59fd                	li	s3,-1
    80002fb8:	bfd1                	j	80002f8c <sys_sbrk+0x84>

0000000080002fba <sys_sleep>:


uint64
sys_sleep(void)
{
    80002fba:	7139                	addi	sp,sp,-64
    80002fbc:	fc06                	sd	ra,56(sp)
    80002fbe:	f822                	sd	s0,48(sp)
    80002fc0:	f426                	sd	s1,40(sp)
    80002fc2:	f04a                	sd	s2,32(sp)
    80002fc4:	ec4e                	sd	s3,24(sp)
    80002fc6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fc8:	fcc40593          	addi	a1,s0,-52
    80002fcc:	4501                	li	a0,0
    80002fce:	00000097          	auipc	ra,0x0
    80002fd2:	dc2080e7          	jalr	-574(ra) # 80002d90 <argint>
    return -1;
    80002fd6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fd8:	06054563          	bltz	a0,80003042 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fdc:	00015517          	auipc	a0,0x15
    80002fe0:	98c50513          	addi	a0,a0,-1652 # 80017968 <tickslock>
    80002fe4:	ffffe097          	auipc	ra,0xffffe
    80002fe8:	c2c080e7          	jalr	-980(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002fec:	00006917          	auipc	s2,0x6
    80002ff0:	03492903          	lw	s2,52(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002ff4:	fcc42783          	lw	a5,-52(s0)
    80002ff8:	cf85                	beqz	a5,80003030 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ffa:	00015997          	auipc	s3,0x15
    80002ffe:	96e98993          	addi	s3,s3,-1682 # 80017968 <tickslock>
    80003002:	00006497          	auipc	s1,0x6
    80003006:	01e48493          	addi	s1,s1,30 # 80009020 <ticks>
    if(myproc()->killed){
    8000300a:	fffff097          	auipc	ra,0xfffff
    8000300e:	b5e080e7          	jalr	-1186(ra) # 80001b68 <myproc>
    80003012:	591c                	lw	a5,48(a0)
    80003014:	ef9d                	bnez	a5,80003052 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003016:	85ce                	mv	a1,s3
    80003018:	8526                	mv	a0,s1
    8000301a:	fffff097          	auipc	ra,0xfffff
    8000301e:	0d2080e7          	jalr	210(ra) # 800020ec <sleep>
  while(ticks - ticks0 < n){
    80003022:	409c                	lw	a5,0(s1)
    80003024:	412787bb          	subw	a5,a5,s2
    80003028:	fcc42703          	lw	a4,-52(s0)
    8000302c:	fce7efe3          	bltu	a5,a4,8000300a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003030:	00015517          	auipc	a0,0x15
    80003034:	93850513          	addi	a0,a0,-1736 # 80017968 <tickslock>
    80003038:	ffffe097          	auipc	ra,0xffffe
    8000303c:	c8c080e7          	jalr	-884(ra) # 80000cc4 <release>
  return 0;
    80003040:	4781                	li	a5,0
}
    80003042:	853e                	mv	a0,a5
    80003044:	70e2                	ld	ra,56(sp)
    80003046:	7442                	ld	s0,48(sp)
    80003048:	74a2                	ld	s1,40(sp)
    8000304a:	7902                	ld	s2,32(sp)
    8000304c:	69e2                	ld	s3,24(sp)
    8000304e:	6121                	addi	sp,sp,64
    80003050:	8082                	ret
      release(&tickslock);
    80003052:	00015517          	auipc	a0,0x15
    80003056:	91650513          	addi	a0,a0,-1770 # 80017968 <tickslock>
    8000305a:	ffffe097          	auipc	ra,0xffffe
    8000305e:	c6a080e7          	jalr	-918(ra) # 80000cc4 <release>
      return -1;
    80003062:	57fd                	li	a5,-1
    80003064:	bff9                	j	80003042 <sys_sleep+0x88>

0000000080003066 <sys_kill>:

uint64
sys_kill(void)
{
    80003066:	1101                	addi	sp,sp,-32
    80003068:	ec06                	sd	ra,24(sp)
    8000306a:	e822                	sd	s0,16(sp)
    8000306c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000306e:	fec40593          	addi	a1,s0,-20
    80003072:	4501                	li	a0,0
    80003074:	00000097          	auipc	ra,0x0
    80003078:	d1c080e7          	jalr	-740(ra) # 80002d90 <argint>
    8000307c:	87aa                	mv	a5,a0
    return -1;
    8000307e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003080:	0007c863          	bltz	a5,80003090 <sys_kill+0x2a>
  return kill(pid);
    80003084:	fec42503          	lw	a0,-20(s0)
    80003088:	fffff097          	auipc	ra,0xfffff
    8000308c:	14c080e7          	jalr	332(ra) # 800021d4 <kill>
}
    80003090:	60e2                	ld	ra,24(sp)
    80003092:	6442                	ld	s0,16(sp)
    80003094:	6105                	addi	sp,sp,32
    80003096:	8082                	ret

0000000080003098 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003098:	1101                	addi	sp,sp,-32
    8000309a:	ec06                	sd	ra,24(sp)
    8000309c:	e822                	sd	s0,16(sp)
    8000309e:	e426                	sd	s1,8(sp)
    800030a0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030a2:	00015517          	auipc	a0,0x15
    800030a6:	8c650513          	addi	a0,a0,-1850 # 80017968 <tickslock>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	b66080e7          	jalr	-1178(ra) # 80000c10 <acquire>
  xticks = ticks;
    800030b2:	00006497          	auipc	s1,0x6
    800030b6:	f6e4a483          	lw	s1,-146(s1) # 80009020 <ticks>
  release(&tickslock);
    800030ba:	00015517          	auipc	a0,0x15
    800030be:	8ae50513          	addi	a0,a0,-1874 # 80017968 <tickslock>
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	c02080e7          	jalr	-1022(ra) # 80000cc4 <release>
  return xticks;
}
    800030ca:	02049513          	slli	a0,s1,0x20
    800030ce:	9101                	srli	a0,a0,0x20
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	64a2                	ld	s1,8(sp)
    800030d6:	6105                	addi	sp,sp,32
    800030d8:	8082                	ret

00000000800030da <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030da:	7179                	addi	sp,sp,-48
    800030dc:	f406                	sd	ra,40(sp)
    800030de:	f022                	sd	s0,32(sp)
    800030e0:	ec26                	sd	s1,24(sp)
    800030e2:	e84a                	sd	s2,16(sp)
    800030e4:	e44e                	sd	s3,8(sp)
    800030e6:	e052                	sd	s4,0(sp)
    800030e8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030ea:	00005597          	auipc	a1,0x5
    800030ee:	44e58593          	addi	a1,a1,1102 # 80008538 <syscalls+0xb0>
    800030f2:	00015517          	auipc	a0,0x15
    800030f6:	88e50513          	addi	a0,a0,-1906 # 80017980 <bcache>
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	a86080e7          	jalr	-1402(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003102:	0001d797          	auipc	a5,0x1d
    80003106:	87e78793          	addi	a5,a5,-1922 # 8001f980 <bcache+0x8000>
    8000310a:	0001d717          	auipc	a4,0x1d
    8000310e:	ade70713          	addi	a4,a4,-1314 # 8001fbe8 <bcache+0x8268>
    80003112:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003116:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000311a:	00015497          	auipc	s1,0x15
    8000311e:	87e48493          	addi	s1,s1,-1922 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80003122:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003124:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003126:	00005a17          	auipc	s4,0x5
    8000312a:	41aa0a13          	addi	s4,s4,1050 # 80008540 <syscalls+0xb8>
    b->next = bcache.head.next;
    8000312e:	2b893783          	ld	a5,696(s2)
    80003132:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003134:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003138:	85d2                	mv	a1,s4
    8000313a:	01048513          	addi	a0,s1,16
    8000313e:	00001097          	auipc	ra,0x1
    80003142:	4ac080e7          	jalr	1196(ra) # 800045ea <initsleeplock>
    bcache.head.next->prev = b;
    80003146:	2b893783          	ld	a5,696(s2)
    8000314a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000314c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003150:	45848493          	addi	s1,s1,1112
    80003154:	fd349de3          	bne	s1,s3,8000312e <binit+0x54>
  }
}
    80003158:	70a2                	ld	ra,40(sp)
    8000315a:	7402                	ld	s0,32(sp)
    8000315c:	64e2                	ld	s1,24(sp)
    8000315e:	6942                	ld	s2,16(sp)
    80003160:	69a2                	ld	s3,8(sp)
    80003162:	6a02                	ld	s4,0(sp)
    80003164:	6145                	addi	sp,sp,48
    80003166:	8082                	ret

0000000080003168 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003168:	7179                	addi	sp,sp,-48
    8000316a:	f406                	sd	ra,40(sp)
    8000316c:	f022                	sd	s0,32(sp)
    8000316e:	ec26                	sd	s1,24(sp)
    80003170:	e84a                	sd	s2,16(sp)
    80003172:	e44e                	sd	s3,8(sp)
    80003174:	1800                	addi	s0,sp,48
    80003176:	89aa                	mv	s3,a0
    80003178:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000317a:	00015517          	auipc	a0,0x15
    8000317e:	80650513          	addi	a0,a0,-2042 # 80017980 <bcache>
    80003182:	ffffe097          	auipc	ra,0xffffe
    80003186:	a8e080e7          	jalr	-1394(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000318a:	0001d497          	auipc	s1,0x1d
    8000318e:	aae4b483          	ld	s1,-1362(s1) # 8001fc38 <bcache+0x82b8>
    80003192:	0001d797          	auipc	a5,0x1d
    80003196:	a5678793          	addi	a5,a5,-1450 # 8001fbe8 <bcache+0x8268>
    8000319a:	02f48f63          	beq	s1,a5,800031d8 <bread+0x70>
    8000319e:	873e                	mv	a4,a5
    800031a0:	a021                	j	800031a8 <bread+0x40>
    800031a2:	68a4                	ld	s1,80(s1)
    800031a4:	02e48a63          	beq	s1,a4,800031d8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031a8:	449c                	lw	a5,8(s1)
    800031aa:	ff379ce3          	bne	a5,s3,800031a2 <bread+0x3a>
    800031ae:	44dc                	lw	a5,12(s1)
    800031b0:	ff2799e3          	bne	a5,s2,800031a2 <bread+0x3a>
      b->refcnt++;
    800031b4:	40bc                	lw	a5,64(s1)
    800031b6:	2785                	addiw	a5,a5,1
    800031b8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031ba:	00014517          	auipc	a0,0x14
    800031be:	7c650513          	addi	a0,a0,1990 # 80017980 <bcache>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	b02080e7          	jalr	-1278(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    800031ca:	01048513          	addi	a0,s1,16
    800031ce:	00001097          	auipc	ra,0x1
    800031d2:	456080e7          	jalr	1110(ra) # 80004624 <acquiresleep>
      return b;
    800031d6:	a8b9                	j	80003234 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031d8:	0001d497          	auipc	s1,0x1d
    800031dc:	a584b483          	ld	s1,-1448(s1) # 8001fc30 <bcache+0x82b0>
    800031e0:	0001d797          	auipc	a5,0x1d
    800031e4:	a0878793          	addi	a5,a5,-1528 # 8001fbe8 <bcache+0x8268>
    800031e8:	00f48863          	beq	s1,a5,800031f8 <bread+0x90>
    800031ec:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031ee:	40bc                	lw	a5,64(s1)
    800031f0:	cf81                	beqz	a5,80003208 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031f2:	64a4                	ld	s1,72(s1)
    800031f4:	fee49de3          	bne	s1,a4,800031ee <bread+0x86>
  panic("bget: no buffers");
    800031f8:	00005517          	auipc	a0,0x5
    800031fc:	35050513          	addi	a0,a0,848 # 80008548 <syscalls+0xc0>
    80003200:	ffffd097          	auipc	ra,0xffffd
    80003204:	348080e7          	jalr	840(ra) # 80000548 <panic>
      b->dev = dev;
    80003208:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000320c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003210:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003214:	4785                	li	a5,1
    80003216:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003218:	00014517          	auipc	a0,0x14
    8000321c:	76850513          	addi	a0,a0,1896 # 80017980 <bcache>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	aa4080e7          	jalr	-1372(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80003228:	01048513          	addi	a0,s1,16
    8000322c:	00001097          	auipc	ra,0x1
    80003230:	3f8080e7          	jalr	1016(ra) # 80004624 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003234:	409c                	lw	a5,0(s1)
    80003236:	cb89                	beqz	a5,80003248 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003238:	8526                	mv	a0,s1
    8000323a:	70a2                	ld	ra,40(sp)
    8000323c:	7402                	ld	s0,32(sp)
    8000323e:	64e2                	ld	s1,24(sp)
    80003240:	6942                	ld	s2,16(sp)
    80003242:	69a2                	ld	s3,8(sp)
    80003244:	6145                	addi	sp,sp,48
    80003246:	8082                	ret
    virtio_disk_rw(b, 0);
    80003248:	4581                	li	a1,0
    8000324a:	8526                	mv	a0,s1
    8000324c:	00003097          	auipc	ra,0x3
    80003250:	f70080e7          	jalr	-144(ra) # 800061bc <virtio_disk_rw>
    b->valid = 1;
    80003254:	4785                	li	a5,1
    80003256:	c09c                	sw	a5,0(s1)
  return b;
    80003258:	b7c5                	j	80003238 <bread+0xd0>

000000008000325a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000325a:	1101                	addi	sp,sp,-32
    8000325c:	ec06                	sd	ra,24(sp)
    8000325e:	e822                	sd	s0,16(sp)
    80003260:	e426                	sd	s1,8(sp)
    80003262:	1000                	addi	s0,sp,32
    80003264:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003266:	0541                	addi	a0,a0,16
    80003268:	00001097          	auipc	ra,0x1
    8000326c:	456080e7          	jalr	1110(ra) # 800046be <holdingsleep>
    80003270:	cd01                	beqz	a0,80003288 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003272:	4585                	li	a1,1
    80003274:	8526                	mv	a0,s1
    80003276:	00003097          	auipc	ra,0x3
    8000327a:	f46080e7          	jalr	-186(ra) # 800061bc <virtio_disk_rw>
}
    8000327e:	60e2                	ld	ra,24(sp)
    80003280:	6442                	ld	s0,16(sp)
    80003282:	64a2                	ld	s1,8(sp)
    80003284:	6105                	addi	sp,sp,32
    80003286:	8082                	ret
    panic("bwrite");
    80003288:	00005517          	auipc	a0,0x5
    8000328c:	2d850513          	addi	a0,a0,728 # 80008560 <syscalls+0xd8>
    80003290:	ffffd097          	auipc	ra,0xffffd
    80003294:	2b8080e7          	jalr	696(ra) # 80000548 <panic>

0000000080003298 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003298:	1101                	addi	sp,sp,-32
    8000329a:	ec06                	sd	ra,24(sp)
    8000329c:	e822                	sd	s0,16(sp)
    8000329e:	e426                	sd	s1,8(sp)
    800032a0:	e04a                	sd	s2,0(sp)
    800032a2:	1000                	addi	s0,sp,32
    800032a4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032a6:	01050913          	addi	s2,a0,16
    800032aa:	854a                	mv	a0,s2
    800032ac:	00001097          	auipc	ra,0x1
    800032b0:	412080e7          	jalr	1042(ra) # 800046be <holdingsleep>
    800032b4:	c92d                	beqz	a0,80003326 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032b6:	854a                	mv	a0,s2
    800032b8:	00001097          	auipc	ra,0x1
    800032bc:	3c2080e7          	jalr	962(ra) # 8000467a <releasesleep>

  acquire(&bcache.lock);
    800032c0:	00014517          	auipc	a0,0x14
    800032c4:	6c050513          	addi	a0,a0,1728 # 80017980 <bcache>
    800032c8:	ffffe097          	auipc	ra,0xffffe
    800032cc:	948080e7          	jalr	-1720(ra) # 80000c10 <acquire>
  b->refcnt--;
    800032d0:	40bc                	lw	a5,64(s1)
    800032d2:	37fd                	addiw	a5,a5,-1
    800032d4:	0007871b          	sext.w	a4,a5
    800032d8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032da:	eb05                	bnez	a4,8000330a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032dc:	68bc                	ld	a5,80(s1)
    800032de:	64b8                	ld	a4,72(s1)
    800032e0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032e2:	64bc                	ld	a5,72(s1)
    800032e4:	68b8                	ld	a4,80(s1)
    800032e6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032e8:	0001c797          	auipc	a5,0x1c
    800032ec:	69878793          	addi	a5,a5,1688 # 8001f980 <bcache+0x8000>
    800032f0:	2b87b703          	ld	a4,696(a5)
    800032f4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032f6:	0001d717          	auipc	a4,0x1d
    800032fa:	8f270713          	addi	a4,a4,-1806 # 8001fbe8 <bcache+0x8268>
    800032fe:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003300:	2b87b703          	ld	a4,696(a5)
    80003304:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003306:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000330a:	00014517          	auipc	a0,0x14
    8000330e:	67650513          	addi	a0,a0,1654 # 80017980 <bcache>
    80003312:	ffffe097          	auipc	ra,0xffffe
    80003316:	9b2080e7          	jalr	-1614(ra) # 80000cc4 <release>
}
    8000331a:	60e2                	ld	ra,24(sp)
    8000331c:	6442                	ld	s0,16(sp)
    8000331e:	64a2                	ld	s1,8(sp)
    80003320:	6902                	ld	s2,0(sp)
    80003322:	6105                	addi	sp,sp,32
    80003324:	8082                	ret
    panic("brelse");
    80003326:	00005517          	auipc	a0,0x5
    8000332a:	24250513          	addi	a0,a0,578 # 80008568 <syscalls+0xe0>
    8000332e:	ffffd097          	auipc	ra,0xffffd
    80003332:	21a080e7          	jalr	538(ra) # 80000548 <panic>

0000000080003336 <bpin>:

void
bpin(struct buf *b) {
    80003336:	1101                	addi	sp,sp,-32
    80003338:	ec06                	sd	ra,24(sp)
    8000333a:	e822                	sd	s0,16(sp)
    8000333c:	e426                	sd	s1,8(sp)
    8000333e:	1000                	addi	s0,sp,32
    80003340:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003342:	00014517          	auipc	a0,0x14
    80003346:	63e50513          	addi	a0,a0,1598 # 80017980 <bcache>
    8000334a:	ffffe097          	auipc	ra,0xffffe
    8000334e:	8c6080e7          	jalr	-1850(ra) # 80000c10 <acquire>
  b->refcnt++;
    80003352:	40bc                	lw	a5,64(s1)
    80003354:	2785                	addiw	a5,a5,1
    80003356:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003358:	00014517          	auipc	a0,0x14
    8000335c:	62850513          	addi	a0,a0,1576 # 80017980 <bcache>
    80003360:	ffffe097          	auipc	ra,0xffffe
    80003364:	964080e7          	jalr	-1692(ra) # 80000cc4 <release>
}
    80003368:	60e2                	ld	ra,24(sp)
    8000336a:	6442                	ld	s0,16(sp)
    8000336c:	64a2                	ld	s1,8(sp)
    8000336e:	6105                	addi	sp,sp,32
    80003370:	8082                	ret

0000000080003372 <bunpin>:

void
bunpin(struct buf *b) {
    80003372:	1101                	addi	sp,sp,-32
    80003374:	ec06                	sd	ra,24(sp)
    80003376:	e822                	sd	s0,16(sp)
    80003378:	e426                	sd	s1,8(sp)
    8000337a:	1000                	addi	s0,sp,32
    8000337c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000337e:	00014517          	auipc	a0,0x14
    80003382:	60250513          	addi	a0,a0,1538 # 80017980 <bcache>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	88a080e7          	jalr	-1910(ra) # 80000c10 <acquire>
  b->refcnt--;
    8000338e:	40bc                	lw	a5,64(s1)
    80003390:	37fd                	addiw	a5,a5,-1
    80003392:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003394:	00014517          	auipc	a0,0x14
    80003398:	5ec50513          	addi	a0,a0,1516 # 80017980 <bcache>
    8000339c:	ffffe097          	auipc	ra,0xffffe
    800033a0:	928080e7          	jalr	-1752(ra) # 80000cc4 <release>
}
    800033a4:	60e2                	ld	ra,24(sp)
    800033a6:	6442                	ld	s0,16(sp)
    800033a8:	64a2                	ld	s1,8(sp)
    800033aa:	6105                	addi	sp,sp,32
    800033ac:	8082                	ret

00000000800033ae <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033ae:	1101                	addi	sp,sp,-32
    800033b0:	ec06                	sd	ra,24(sp)
    800033b2:	e822                	sd	s0,16(sp)
    800033b4:	e426                	sd	s1,8(sp)
    800033b6:	e04a                	sd	s2,0(sp)
    800033b8:	1000                	addi	s0,sp,32
    800033ba:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033bc:	00d5d59b          	srliw	a1,a1,0xd
    800033c0:	0001d797          	auipc	a5,0x1d
    800033c4:	c9c7a783          	lw	a5,-868(a5) # 8002005c <sb+0x1c>
    800033c8:	9dbd                	addw	a1,a1,a5
    800033ca:	00000097          	auipc	ra,0x0
    800033ce:	d9e080e7          	jalr	-610(ra) # 80003168 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033d2:	0074f713          	andi	a4,s1,7
    800033d6:	4785                	li	a5,1
    800033d8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033dc:	14ce                	slli	s1,s1,0x33
    800033de:	90d9                	srli	s1,s1,0x36
    800033e0:	00950733          	add	a4,a0,s1
    800033e4:	05874703          	lbu	a4,88(a4)
    800033e8:	00e7f6b3          	and	a3,a5,a4
    800033ec:	c69d                	beqz	a3,8000341a <bfree+0x6c>
    800033ee:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033f0:	94aa                	add	s1,s1,a0
    800033f2:	fff7c793          	not	a5,a5
    800033f6:	8ff9                	and	a5,a5,a4
    800033f8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033fc:	00001097          	auipc	ra,0x1
    80003400:	100080e7          	jalr	256(ra) # 800044fc <log_write>
  brelse(bp);
    80003404:	854a                	mv	a0,s2
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	e92080e7          	jalr	-366(ra) # 80003298 <brelse>
}
    8000340e:	60e2                	ld	ra,24(sp)
    80003410:	6442                	ld	s0,16(sp)
    80003412:	64a2                	ld	s1,8(sp)
    80003414:	6902                	ld	s2,0(sp)
    80003416:	6105                	addi	sp,sp,32
    80003418:	8082                	ret
    panic("freeing free block");
    8000341a:	00005517          	auipc	a0,0x5
    8000341e:	15650513          	addi	a0,a0,342 # 80008570 <syscalls+0xe8>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	126080e7          	jalr	294(ra) # 80000548 <panic>

000000008000342a <balloc>:
{
    8000342a:	711d                	addi	sp,sp,-96
    8000342c:	ec86                	sd	ra,88(sp)
    8000342e:	e8a2                	sd	s0,80(sp)
    80003430:	e4a6                	sd	s1,72(sp)
    80003432:	e0ca                	sd	s2,64(sp)
    80003434:	fc4e                	sd	s3,56(sp)
    80003436:	f852                	sd	s4,48(sp)
    80003438:	f456                	sd	s5,40(sp)
    8000343a:	f05a                	sd	s6,32(sp)
    8000343c:	ec5e                	sd	s7,24(sp)
    8000343e:	e862                	sd	s8,16(sp)
    80003440:	e466                	sd	s9,8(sp)
    80003442:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003444:	0001d797          	auipc	a5,0x1d
    80003448:	c007a783          	lw	a5,-1024(a5) # 80020044 <sb+0x4>
    8000344c:	cbd1                	beqz	a5,800034e0 <balloc+0xb6>
    8000344e:	8baa                	mv	s7,a0
    80003450:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003452:	0001db17          	auipc	s6,0x1d
    80003456:	beeb0b13          	addi	s6,s6,-1042 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000345a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000345c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000345e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003460:	6c89                	lui	s9,0x2
    80003462:	a831                	j	8000347e <balloc+0x54>
    brelse(bp);
    80003464:	854a                	mv	a0,s2
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	e32080e7          	jalr	-462(ra) # 80003298 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000346e:	015c87bb          	addw	a5,s9,s5
    80003472:	00078a9b          	sext.w	s5,a5
    80003476:	004b2703          	lw	a4,4(s6)
    8000347a:	06eaf363          	bgeu	s5,a4,800034e0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000347e:	41fad79b          	sraiw	a5,s5,0x1f
    80003482:	0137d79b          	srliw	a5,a5,0x13
    80003486:	015787bb          	addw	a5,a5,s5
    8000348a:	40d7d79b          	sraiw	a5,a5,0xd
    8000348e:	01cb2583          	lw	a1,28(s6)
    80003492:	9dbd                	addw	a1,a1,a5
    80003494:	855e                	mv	a0,s7
    80003496:	00000097          	auipc	ra,0x0
    8000349a:	cd2080e7          	jalr	-814(ra) # 80003168 <bread>
    8000349e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a0:	004b2503          	lw	a0,4(s6)
    800034a4:	000a849b          	sext.w	s1,s5
    800034a8:	8662                	mv	a2,s8
    800034aa:	faa4fde3          	bgeu	s1,a0,80003464 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034ae:	41f6579b          	sraiw	a5,a2,0x1f
    800034b2:	01d7d69b          	srliw	a3,a5,0x1d
    800034b6:	00c6873b          	addw	a4,a3,a2
    800034ba:	00777793          	andi	a5,a4,7
    800034be:	9f95                	subw	a5,a5,a3
    800034c0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034c4:	4037571b          	sraiw	a4,a4,0x3
    800034c8:	00e906b3          	add	a3,s2,a4
    800034cc:	0586c683          	lbu	a3,88(a3)
    800034d0:	00d7f5b3          	and	a1,a5,a3
    800034d4:	cd91                	beqz	a1,800034f0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034d6:	2605                	addiw	a2,a2,1
    800034d8:	2485                	addiw	s1,s1,1
    800034da:	fd4618e3          	bne	a2,s4,800034aa <balloc+0x80>
    800034de:	b759                	j	80003464 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034e0:	00005517          	auipc	a0,0x5
    800034e4:	0a850513          	addi	a0,a0,168 # 80008588 <syscalls+0x100>
    800034e8:	ffffd097          	auipc	ra,0xffffd
    800034ec:	060080e7          	jalr	96(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034f0:	974a                	add	a4,a4,s2
    800034f2:	8fd5                	or	a5,a5,a3
    800034f4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034f8:	854a                	mv	a0,s2
    800034fa:	00001097          	auipc	ra,0x1
    800034fe:	002080e7          	jalr	2(ra) # 800044fc <log_write>
        brelse(bp);
    80003502:	854a                	mv	a0,s2
    80003504:	00000097          	auipc	ra,0x0
    80003508:	d94080e7          	jalr	-620(ra) # 80003298 <brelse>
  bp = bread(dev, bno);
    8000350c:	85a6                	mv	a1,s1
    8000350e:	855e                	mv	a0,s7
    80003510:	00000097          	auipc	ra,0x0
    80003514:	c58080e7          	jalr	-936(ra) # 80003168 <bread>
    80003518:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000351a:	40000613          	li	a2,1024
    8000351e:	4581                	li	a1,0
    80003520:	05850513          	addi	a0,a0,88
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	7e8080e7          	jalr	2024(ra) # 80000d0c <memset>
  log_write(bp);
    8000352c:	854a                	mv	a0,s2
    8000352e:	00001097          	auipc	ra,0x1
    80003532:	fce080e7          	jalr	-50(ra) # 800044fc <log_write>
  brelse(bp);
    80003536:	854a                	mv	a0,s2
    80003538:	00000097          	auipc	ra,0x0
    8000353c:	d60080e7          	jalr	-672(ra) # 80003298 <brelse>
}
    80003540:	8526                	mv	a0,s1
    80003542:	60e6                	ld	ra,88(sp)
    80003544:	6446                	ld	s0,80(sp)
    80003546:	64a6                	ld	s1,72(sp)
    80003548:	6906                	ld	s2,64(sp)
    8000354a:	79e2                	ld	s3,56(sp)
    8000354c:	7a42                	ld	s4,48(sp)
    8000354e:	7aa2                	ld	s5,40(sp)
    80003550:	7b02                	ld	s6,32(sp)
    80003552:	6be2                	ld	s7,24(sp)
    80003554:	6c42                	ld	s8,16(sp)
    80003556:	6ca2                	ld	s9,8(sp)
    80003558:	6125                	addi	sp,sp,96
    8000355a:	8082                	ret

000000008000355c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000355c:	7179                	addi	sp,sp,-48
    8000355e:	f406                	sd	ra,40(sp)
    80003560:	f022                	sd	s0,32(sp)
    80003562:	ec26                	sd	s1,24(sp)
    80003564:	e84a                	sd	s2,16(sp)
    80003566:	e44e                	sd	s3,8(sp)
    80003568:	e052                	sd	s4,0(sp)
    8000356a:	1800                	addi	s0,sp,48
    8000356c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000356e:	47ad                	li	a5,11
    80003570:	04b7fe63          	bgeu	a5,a1,800035cc <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003574:	ff45849b          	addiw	s1,a1,-12
    80003578:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000357c:	0ff00793          	li	a5,255
    80003580:	0ae7e363          	bltu	a5,a4,80003626 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003584:	08052583          	lw	a1,128(a0)
    80003588:	c5ad                	beqz	a1,800035f2 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000358a:	00092503          	lw	a0,0(s2)
    8000358e:	00000097          	auipc	ra,0x0
    80003592:	bda080e7          	jalr	-1062(ra) # 80003168 <bread>
    80003596:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003598:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000359c:	02049593          	slli	a1,s1,0x20
    800035a0:	9181                	srli	a1,a1,0x20
    800035a2:	058a                	slli	a1,a1,0x2
    800035a4:	00b784b3          	add	s1,a5,a1
    800035a8:	0004a983          	lw	s3,0(s1)
    800035ac:	04098d63          	beqz	s3,80003606 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035b0:	8552                	mv	a0,s4
    800035b2:	00000097          	auipc	ra,0x0
    800035b6:	ce6080e7          	jalr	-794(ra) # 80003298 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035ba:	854e                	mv	a0,s3
    800035bc:	70a2                	ld	ra,40(sp)
    800035be:	7402                	ld	s0,32(sp)
    800035c0:	64e2                	ld	s1,24(sp)
    800035c2:	6942                	ld	s2,16(sp)
    800035c4:	69a2                	ld	s3,8(sp)
    800035c6:	6a02                	ld	s4,0(sp)
    800035c8:	6145                	addi	sp,sp,48
    800035ca:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035cc:	02059493          	slli	s1,a1,0x20
    800035d0:	9081                	srli	s1,s1,0x20
    800035d2:	048a                	slli	s1,s1,0x2
    800035d4:	94aa                	add	s1,s1,a0
    800035d6:	0504a983          	lw	s3,80(s1)
    800035da:	fe0990e3          	bnez	s3,800035ba <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035de:	4108                	lw	a0,0(a0)
    800035e0:	00000097          	auipc	ra,0x0
    800035e4:	e4a080e7          	jalr	-438(ra) # 8000342a <balloc>
    800035e8:	0005099b          	sext.w	s3,a0
    800035ec:	0534a823          	sw	s3,80(s1)
    800035f0:	b7e9                	j	800035ba <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035f2:	4108                	lw	a0,0(a0)
    800035f4:	00000097          	auipc	ra,0x0
    800035f8:	e36080e7          	jalr	-458(ra) # 8000342a <balloc>
    800035fc:	0005059b          	sext.w	a1,a0
    80003600:	08b92023          	sw	a1,128(s2)
    80003604:	b759                	j	8000358a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003606:	00092503          	lw	a0,0(s2)
    8000360a:	00000097          	auipc	ra,0x0
    8000360e:	e20080e7          	jalr	-480(ra) # 8000342a <balloc>
    80003612:	0005099b          	sext.w	s3,a0
    80003616:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000361a:	8552                	mv	a0,s4
    8000361c:	00001097          	auipc	ra,0x1
    80003620:	ee0080e7          	jalr	-288(ra) # 800044fc <log_write>
    80003624:	b771                	j	800035b0 <bmap+0x54>
  panic("bmap: out of range");
    80003626:	00005517          	auipc	a0,0x5
    8000362a:	f7a50513          	addi	a0,a0,-134 # 800085a0 <syscalls+0x118>
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	f1a080e7          	jalr	-230(ra) # 80000548 <panic>

0000000080003636 <iget>:
{
    80003636:	7179                	addi	sp,sp,-48
    80003638:	f406                	sd	ra,40(sp)
    8000363a:	f022                	sd	s0,32(sp)
    8000363c:	ec26                	sd	s1,24(sp)
    8000363e:	e84a                	sd	s2,16(sp)
    80003640:	e44e                	sd	s3,8(sp)
    80003642:	e052                	sd	s4,0(sp)
    80003644:	1800                	addi	s0,sp,48
    80003646:	89aa                	mv	s3,a0
    80003648:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000364a:	0001d517          	auipc	a0,0x1d
    8000364e:	a1650513          	addi	a0,a0,-1514 # 80020060 <icache>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	5be080e7          	jalr	1470(ra) # 80000c10 <acquire>
  empty = 0;
    8000365a:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000365c:	0001d497          	auipc	s1,0x1d
    80003660:	a1c48493          	addi	s1,s1,-1508 # 80020078 <icache+0x18>
    80003664:	0001e697          	auipc	a3,0x1e
    80003668:	4a468693          	addi	a3,a3,1188 # 80021b08 <log>
    8000366c:	a039                	j	8000367a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000366e:	02090b63          	beqz	s2,800036a4 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003672:	08848493          	addi	s1,s1,136
    80003676:	02d48a63          	beq	s1,a3,800036aa <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000367a:	449c                	lw	a5,8(s1)
    8000367c:	fef059e3          	blez	a5,8000366e <iget+0x38>
    80003680:	4098                	lw	a4,0(s1)
    80003682:	ff3716e3          	bne	a4,s3,8000366e <iget+0x38>
    80003686:	40d8                	lw	a4,4(s1)
    80003688:	ff4713e3          	bne	a4,s4,8000366e <iget+0x38>
      ip->ref++;
    8000368c:	2785                	addiw	a5,a5,1
    8000368e:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003690:	0001d517          	auipc	a0,0x1d
    80003694:	9d050513          	addi	a0,a0,-1584 # 80020060 <icache>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	62c080e7          	jalr	1580(ra) # 80000cc4 <release>
      return ip;
    800036a0:	8926                	mv	s2,s1
    800036a2:	a03d                	j	800036d0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036a4:	f7f9                	bnez	a5,80003672 <iget+0x3c>
    800036a6:	8926                	mv	s2,s1
    800036a8:	b7e9                	j	80003672 <iget+0x3c>
  if(empty == 0)
    800036aa:	02090c63          	beqz	s2,800036e2 <iget+0xac>
  ip->dev = dev;
    800036ae:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036b2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036b6:	4785                	li	a5,1
    800036b8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036bc:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036c0:	0001d517          	auipc	a0,0x1d
    800036c4:	9a050513          	addi	a0,a0,-1632 # 80020060 <icache>
    800036c8:	ffffd097          	auipc	ra,0xffffd
    800036cc:	5fc080e7          	jalr	1532(ra) # 80000cc4 <release>
}
    800036d0:	854a                	mv	a0,s2
    800036d2:	70a2                	ld	ra,40(sp)
    800036d4:	7402                	ld	s0,32(sp)
    800036d6:	64e2                	ld	s1,24(sp)
    800036d8:	6942                	ld	s2,16(sp)
    800036da:	69a2                	ld	s3,8(sp)
    800036dc:	6a02                	ld	s4,0(sp)
    800036de:	6145                	addi	sp,sp,48
    800036e0:	8082                	ret
    panic("iget: no inodes");
    800036e2:	00005517          	auipc	a0,0x5
    800036e6:	ed650513          	addi	a0,a0,-298 # 800085b8 <syscalls+0x130>
    800036ea:	ffffd097          	auipc	ra,0xffffd
    800036ee:	e5e080e7          	jalr	-418(ra) # 80000548 <panic>

00000000800036f2 <fsinit>:
fsinit(int dev) {
    800036f2:	7179                	addi	sp,sp,-48
    800036f4:	f406                	sd	ra,40(sp)
    800036f6:	f022                	sd	s0,32(sp)
    800036f8:	ec26                	sd	s1,24(sp)
    800036fa:	e84a                	sd	s2,16(sp)
    800036fc:	e44e                	sd	s3,8(sp)
    800036fe:	1800                	addi	s0,sp,48
    80003700:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003702:	4585                	li	a1,1
    80003704:	00000097          	auipc	ra,0x0
    80003708:	a64080e7          	jalr	-1436(ra) # 80003168 <bread>
    8000370c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000370e:	0001d997          	auipc	s3,0x1d
    80003712:	93298993          	addi	s3,s3,-1742 # 80020040 <sb>
    80003716:	02000613          	li	a2,32
    8000371a:	05850593          	addi	a1,a0,88
    8000371e:	854e                	mv	a0,s3
    80003720:	ffffd097          	auipc	ra,0xffffd
    80003724:	64c080e7          	jalr	1612(ra) # 80000d6c <memmove>
  brelse(bp);
    80003728:	8526                	mv	a0,s1
    8000372a:	00000097          	auipc	ra,0x0
    8000372e:	b6e080e7          	jalr	-1170(ra) # 80003298 <brelse>
  if(sb.magic != FSMAGIC)
    80003732:	0009a703          	lw	a4,0(s3)
    80003736:	102037b7          	lui	a5,0x10203
    8000373a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000373e:	02f71263          	bne	a4,a5,80003762 <fsinit+0x70>
  initlog(dev, &sb);
    80003742:	0001d597          	auipc	a1,0x1d
    80003746:	8fe58593          	addi	a1,a1,-1794 # 80020040 <sb>
    8000374a:	854a                	mv	a0,s2
    8000374c:	00001097          	auipc	ra,0x1
    80003750:	b38080e7          	jalr	-1224(ra) # 80004284 <initlog>
}
    80003754:	70a2                	ld	ra,40(sp)
    80003756:	7402                	ld	s0,32(sp)
    80003758:	64e2                	ld	s1,24(sp)
    8000375a:	6942                	ld	s2,16(sp)
    8000375c:	69a2                	ld	s3,8(sp)
    8000375e:	6145                	addi	sp,sp,48
    80003760:	8082                	ret
    panic("invalid file system");
    80003762:	00005517          	auipc	a0,0x5
    80003766:	e6650513          	addi	a0,a0,-410 # 800085c8 <syscalls+0x140>
    8000376a:	ffffd097          	auipc	ra,0xffffd
    8000376e:	dde080e7          	jalr	-546(ra) # 80000548 <panic>

0000000080003772 <iinit>:
{
    80003772:	7179                	addi	sp,sp,-48
    80003774:	f406                	sd	ra,40(sp)
    80003776:	f022                	sd	s0,32(sp)
    80003778:	ec26                	sd	s1,24(sp)
    8000377a:	e84a                	sd	s2,16(sp)
    8000377c:	e44e                	sd	s3,8(sp)
    8000377e:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003780:	00005597          	auipc	a1,0x5
    80003784:	e6058593          	addi	a1,a1,-416 # 800085e0 <syscalls+0x158>
    80003788:	0001d517          	auipc	a0,0x1d
    8000378c:	8d850513          	addi	a0,a0,-1832 # 80020060 <icache>
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	3f0080e7          	jalr	1008(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003798:	0001d497          	auipc	s1,0x1d
    8000379c:	8f048493          	addi	s1,s1,-1808 # 80020088 <icache+0x28>
    800037a0:	0001e997          	auipc	s3,0x1e
    800037a4:	37898993          	addi	s3,s3,888 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037a8:	00005917          	auipc	s2,0x5
    800037ac:	e4090913          	addi	s2,s2,-448 # 800085e8 <syscalls+0x160>
    800037b0:	85ca                	mv	a1,s2
    800037b2:	8526                	mv	a0,s1
    800037b4:	00001097          	auipc	ra,0x1
    800037b8:	e36080e7          	jalr	-458(ra) # 800045ea <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037bc:	08848493          	addi	s1,s1,136
    800037c0:	ff3498e3          	bne	s1,s3,800037b0 <iinit+0x3e>
}
    800037c4:	70a2                	ld	ra,40(sp)
    800037c6:	7402                	ld	s0,32(sp)
    800037c8:	64e2                	ld	s1,24(sp)
    800037ca:	6942                	ld	s2,16(sp)
    800037cc:	69a2                	ld	s3,8(sp)
    800037ce:	6145                	addi	sp,sp,48
    800037d0:	8082                	ret

00000000800037d2 <ialloc>:
{
    800037d2:	715d                	addi	sp,sp,-80
    800037d4:	e486                	sd	ra,72(sp)
    800037d6:	e0a2                	sd	s0,64(sp)
    800037d8:	fc26                	sd	s1,56(sp)
    800037da:	f84a                	sd	s2,48(sp)
    800037dc:	f44e                	sd	s3,40(sp)
    800037de:	f052                	sd	s4,32(sp)
    800037e0:	ec56                	sd	s5,24(sp)
    800037e2:	e85a                	sd	s6,16(sp)
    800037e4:	e45e                	sd	s7,8(sp)
    800037e6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037e8:	0001d717          	auipc	a4,0x1d
    800037ec:	86472703          	lw	a4,-1948(a4) # 8002004c <sb+0xc>
    800037f0:	4785                	li	a5,1
    800037f2:	04e7fa63          	bgeu	a5,a4,80003846 <ialloc+0x74>
    800037f6:	8aaa                	mv	s5,a0
    800037f8:	8bae                	mv	s7,a1
    800037fa:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037fc:	0001da17          	auipc	s4,0x1d
    80003800:	844a0a13          	addi	s4,s4,-1980 # 80020040 <sb>
    80003804:	00048b1b          	sext.w	s6,s1
    80003808:	0044d593          	srli	a1,s1,0x4
    8000380c:	018a2783          	lw	a5,24(s4)
    80003810:	9dbd                	addw	a1,a1,a5
    80003812:	8556                	mv	a0,s5
    80003814:	00000097          	auipc	ra,0x0
    80003818:	954080e7          	jalr	-1708(ra) # 80003168 <bread>
    8000381c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000381e:	05850993          	addi	s3,a0,88
    80003822:	00f4f793          	andi	a5,s1,15
    80003826:	079a                	slli	a5,a5,0x6
    80003828:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000382a:	00099783          	lh	a5,0(s3)
    8000382e:	c785                	beqz	a5,80003856 <ialloc+0x84>
    brelse(bp);
    80003830:	00000097          	auipc	ra,0x0
    80003834:	a68080e7          	jalr	-1432(ra) # 80003298 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003838:	0485                	addi	s1,s1,1
    8000383a:	00ca2703          	lw	a4,12(s4)
    8000383e:	0004879b          	sext.w	a5,s1
    80003842:	fce7e1e3          	bltu	a5,a4,80003804 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003846:	00005517          	auipc	a0,0x5
    8000384a:	daa50513          	addi	a0,a0,-598 # 800085f0 <syscalls+0x168>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	cfa080e7          	jalr	-774(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003856:	04000613          	li	a2,64
    8000385a:	4581                	li	a1,0
    8000385c:	854e                	mv	a0,s3
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	4ae080e7          	jalr	1198(ra) # 80000d0c <memset>
      dip->type = type;
    80003866:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000386a:	854a                	mv	a0,s2
    8000386c:	00001097          	auipc	ra,0x1
    80003870:	c90080e7          	jalr	-880(ra) # 800044fc <log_write>
      brelse(bp);
    80003874:	854a                	mv	a0,s2
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	a22080e7          	jalr	-1502(ra) # 80003298 <brelse>
      return iget(dev, inum);
    8000387e:	85da                	mv	a1,s6
    80003880:	8556                	mv	a0,s5
    80003882:	00000097          	auipc	ra,0x0
    80003886:	db4080e7          	jalr	-588(ra) # 80003636 <iget>
}
    8000388a:	60a6                	ld	ra,72(sp)
    8000388c:	6406                	ld	s0,64(sp)
    8000388e:	74e2                	ld	s1,56(sp)
    80003890:	7942                	ld	s2,48(sp)
    80003892:	79a2                	ld	s3,40(sp)
    80003894:	7a02                	ld	s4,32(sp)
    80003896:	6ae2                	ld	s5,24(sp)
    80003898:	6b42                	ld	s6,16(sp)
    8000389a:	6ba2                	ld	s7,8(sp)
    8000389c:	6161                	addi	sp,sp,80
    8000389e:	8082                	ret

00000000800038a0 <iupdate>:
{
    800038a0:	1101                	addi	sp,sp,-32
    800038a2:	ec06                	sd	ra,24(sp)
    800038a4:	e822                	sd	s0,16(sp)
    800038a6:	e426                	sd	s1,8(sp)
    800038a8:	e04a                	sd	s2,0(sp)
    800038aa:	1000                	addi	s0,sp,32
    800038ac:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038ae:	415c                	lw	a5,4(a0)
    800038b0:	0047d79b          	srliw	a5,a5,0x4
    800038b4:	0001c597          	auipc	a1,0x1c
    800038b8:	7a45a583          	lw	a1,1956(a1) # 80020058 <sb+0x18>
    800038bc:	9dbd                	addw	a1,a1,a5
    800038be:	4108                	lw	a0,0(a0)
    800038c0:	00000097          	auipc	ra,0x0
    800038c4:	8a8080e7          	jalr	-1880(ra) # 80003168 <bread>
    800038c8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038ca:	05850793          	addi	a5,a0,88
    800038ce:	40c8                	lw	a0,4(s1)
    800038d0:	893d                	andi	a0,a0,15
    800038d2:	051a                	slli	a0,a0,0x6
    800038d4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038d6:	04449703          	lh	a4,68(s1)
    800038da:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038de:	04649703          	lh	a4,70(s1)
    800038e2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038e6:	04849703          	lh	a4,72(s1)
    800038ea:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038ee:	04a49703          	lh	a4,74(s1)
    800038f2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038f6:	44f8                	lw	a4,76(s1)
    800038f8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038fa:	03400613          	li	a2,52
    800038fe:	05048593          	addi	a1,s1,80
    80003902:	0531                	addi	a0,a0,12
    80003904:	ffffd097          	auipc	ra,0xffffd
    80003908:	468080e7          	jalr	1128(ra) # 80000d6c <memmove>
  log_write(bp);
    8000390c:	854a                	mv	a0,s2
    8000390e:	00001097          	auipc	ra,0x1
    80003912:	bee080e7          	jalr	-1042(ra) # 800044fc <log_write>
  brelse(bp);
    80003916:	854a                	mv	a0,s2
    80003918:	00000097          	auipc	ra,0x0
    8000391c:	980080e7          	jalr	-1664(ra) # 80003298 <brelse>
}
    80003920:	60e2                	ld	ra,24(sp)
    80003922:	6442                	ld	s0,16(sp)
    80003924:	64a2                	ld	s1,8(sp)
    80003926:	6902                	ld	s2,0(sp)
    80003928:	6105                	addi	sp,sp,32
    8000392a:	8082                	ret

000000008000392c <idup>:
{
    8000392c:	1101                	addi	sp,sp,-32
    8000392e:	ec06                	sd	ra,24(sp)
    80003930:	e822                	sd	s0,16(sp)
    80003932:	e426                	sd	s1,8(sp)
    80003934:	1000                	addi	s0,sp,32
    80003936:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003938:	0001c517          	auipc	a0,0x1c
    8000393c:	72850513          	addi	a0,a0,1832 # 80020060 <icache>
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	2d0080e7          	jalr	720(ra) # 80000c10 <acquire>
  ip->ref++;
    80003948:	449c                	lw	a5,8(s1)
    8000394a:	2785                	addiw	a5,a5,1
    8000394c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000394e:	0001c517          	auipc	a0,0x1c
    80003952:	71250513          	addi	a0,a0,1810 # 80020060 <icache>
    80003956:	ffffd097          	auipc	ra,0xffffd
    8000395a:	36e080e7          	jalr	878(ra) # 80000cc4 <release>
}
    8000395e:	8526                	mv	a0,s1
    80003960:	60e2                	ld	ra,24(sp)
    80003962:	6442                	ld	s0,16(sp)
    80003964:	64a2                	ld	s1,8(sp)
    80003966:	6105                	addi	sp,sp,32
    80003968:	8082                	ret

000000008000396a <ilock>:
{
    8000396a:	1101                	addi	sp,sp,-32
    8000396c:	ec06                	sd	ra,24(sp)
    8000396e:	e822                	sd	s0,16(sp)
    80003970:	e426                	sd	s1,8(sp)
    80003972:	e04a                	sd	s2,0(sp)
    80003974:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003976:	c115                	beqz	a0,8000399a <ilock+0x30>
    80003978:	84aa                	mv	s1,a0
    8000397a:	451c                	lw	a5,8(a0)
    8000397c:	00f05f63          	blez	a5,8000399a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003980:	0541                	addi	a0,a0,16
    80003982:	00001097          	auipc	ra,0x1
    80003986:	ca2080e7          	jalr	-862(ra) # 80004624 <acquiresleep>
  if(ip->valid == 0){
    8000398a:	40bc                	lw	a5,64(s1)
    8000398c:	cf99                	beqz	a5,800039aa <ilock+0x40>
}
    8000398e:	60e2                	ld	ra,24(sp)
    80003990:	6442                	ld	s0,16(sp)
    80003992:	64a2                	ld	s1,8(sp)
    80003994:	6902                	ld	s2,0(sp)
    80003996:	6105                	addi	sp,sp,32
    80003998:	8082                	ret
    panic("ilock");
    8000399a:	00005517          	auipc	a0,0x5
    8000399e:	c6e50513          	addi	a0,a0,-914 # 80008608 <syscalls+0x180>
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	ba6080e7          	jalr	-1114(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039aa:	40dc                	lw	a5,4(s1)
    800039ac:	0047d79b          	srliw	a5,a5,0x4
    800039b0:	0001c597          	auipc	a1,0x1c
    800039b4:	6a85a583          	lw	a1,1704(a1) # 80020058 <sb+0x18>
    800039b8:	9dbd                	addw	a1,a1,a5
    800039ba:	4088                	lw	a0,0(s1)
    800039bc:	fffff097          	auipc	ra,0xfffff
    800039c0:	7ac080e7          	jalr	1964(ra) # 80003168 <bread>
    800039c4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039c6:	05850593          	addi	a1,a0,88
    800039ca:	40dc                	lw	a5,4(s1)
    800039cc:	8bbd                	andi	a5,a5,15
    800039ce:	079a                	slli	a5,a5,0x6
    800039d0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039d2:	00059783          	lh	a5,0(a1)
    800039d6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039da:	00259783          	lh	a5,2(a1)
    800039de:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039e2:	00459783          	lh	a5,4(a1)
    800039e6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039ea:	00659783          	lh	a5,6(a1)
    800039ee:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039f2:	459c                	lw	a5,8(a1)
    800039f4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039f6:	03400613          	li	a2,52
    800039fa:	05b1                	addi	a1,a1,12
    800039fc:	05048513          	addi	a0,s1,80
    80003a00:	ffffd097          	auipc	ra,0xffffd
    80003a04:	36c080e7          	jalr	876(ra) # 80000d6c <memmove>
    brelse(bp);
    80003a08:	854a                	mv	a0,s2
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	88e080e7          	jalr	-1906(ra) # 80003298 <brelse>
    ip->valid = 1;
    80003a12:	4785                	li	a5,1
    80003a14:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a16:	04449783          	lh	a5,68(s1)
    80003a1a:	fbb5                	bnez	a5,8000398e <ilock+0x24>
      panic("ilock: no type");
    80003a1c:	00005517          	auipc	a0,0x5
    80003a20:	bf450513          	addi	a0,a0,-1036 # 80008610 <syscalls+0x188>
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	b24080e7          	jalr	-1244(ra) # 80000548 <panic>

0000000080003a2c <iunlock>:
{
    80003a2c:	1101                	addi	sp,sp,-32
    80003a2e:	ec06                	sd	ra,24(sp)
    80003a30:	e822                	sd	s0,16(sp)
    80003a32:	e426                	sd	s1,8(sp)
    80003a34:	e04a                	sd	s2,0(sp)
    80003a36:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a38:	c905                	beqz	a0,80003a68 <iunlock+0x3c>
    80003a3a:	84aa                	mv	s1,a0
    80003a3c:	01050913          	addi	s2,a0,16
    80003a40:	854a                	mv	a0,s2
    80003a42:	00001097          	auipc	ra,0x1
    80003a46:	c7c080e7          	jalr	-900(ra) # 800046be <holdingsleep>
    80003a4a:	cd19                	beqz	a0,80003a68 <iunlock+0x3c>
    80003a4c:	449c                	lw	a5,8(s1)
    80003a4e:	00f05d63          	blez	a5,80003a68 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a52:	854a                	mv	a0,s2
    80003a54:	00001097          	auipc	ra,0x1
    80003a58:	c26080e7          	jalr	-986(ra) # 8000467a <releasesleep>
}
    80003a5c:	60e2                	ld	ra,24(sp)
    80003a5e:	6442                	ld	s0,16(sp)
    80003a60:	64a2                	ld	s1,8(sp)
    80003a62:	6902                	ld	s2,0(sp)
    80003a64:	6105                	addi	sp,sp,32
    80003a66:	8082                	ret
    panic("iunlock");
    80003a68:	00005517          	auipc	a0,0x5
    80003a6c:	bb850513          	addi	a0,a0,-1096 # 80008620 <syscalls+0x198>
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	ad8080e7          	jalr	-1320(ra) # 80000548 <panic>

0000000080003a78 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a78:	7179                	addi	sp,sp,-48
    80003a7a:	f406                	sd	ra,40(sp)
    80003a7c:	f022                	sd	s0,32(sp)
    80003a7e:	ec26                	sd	s1,24(sp)
    80003a80:	e84a                	sd	s2,16(sp)
    80003a82:	e44e                	sd	s3,8(sp)
    80003a84:	e052                	sd	s4,0(sp)
    80003a86:	1800                	addi	s0,sp,48
    80003a88:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a8a:	05050493          	addi	s1,a0,80
    80003a8e:	08050913          	addi	s2,a0,128
    80003a92:	a021                	j	80003a9a <itrunc+0x22>
    80003a94:	0491                	addi	s1,s1,4
    80003a96:	01248d63          	beq	s1,s2,80003ab0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a9a:	408c                	lw	a1,0(s1)
    80003a9c:	dde5                	beqz	a1,80003a94 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a9e:	0009a503          	lw	a0,0(s3)
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	90c080e7          	jalr	-1780(ra) # 800033ae <bfree>
      ip->addrs[i] = 0;
    80003aaa:	0004a023          	sw	zero,0(s1)
    80003aae:	b7dd                	j	80003a94 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ab0:	0809a583          	lw	a1,128(s3)
    80003ab4:	e185                	bnez	a1,80003ad4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ab6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003aba:	854e                	mv	a0,s3
    80003abc:	00000097          	auipc	ra,0x0
    80003ac0:	de4080e7          	jalr	-540(ra) # 800038a0 <iupdate>
}
    80003ac4:	70a2                	ld	ra,40(sp)
    80003ac6:	7402                	ld	s0,32(sp)
    80003ac8:	64e2                	ld	s1,24(sp)
    80003aca:	6942                	ld	s2,16(sp)
    80003acc:	69a2                	ld	s3,8(sp)
    80003ace:	6a02                	ld	s4,0(sp)
    80003ad0:	6145                	addi	sp,sp,48
    80003ad2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ad4:	0009a503          	lw	a0,0(s3)
    80003ad8:	fffff097          	auipc	ra,0xfffff
    80003adc:	690080e7          	jalr	1680(ra) # 80003168 <bread>
    80003ae0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ae2:	05850493          	addi	s1,a0,88
    80003ae6:	45850913          	addi	s2,a0,1112
    80003aea:	a811                	j	80003afe <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003aec:	0009a503          	lw	a0,0(s3)
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	8be080e7          	jalr	-1858(ra) # 800033ae <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003af8:	0491                	addi	s1,s1,4
    80003afa:	01248563          	beq	s1,s2,80003b04 <itrunc+0x8c>
      if(a[j])
    80003afe:	408c                	lw	a1,0(s1)
    80003b00:	dde5                	beqz	a1,80003af8 <itrunc+0x80>
    80003b02:	b7ed                	j	80003aec <itrunc+0x74>
    brelse(bp);
    80003b04:	8552                	mv	a0,s4
    80003b06:	fffff097          	auipc	ra,0xfffff
    80003b0a:	792080e7          	jalr	1938(ra) # 80003298 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b0e:	0809a583          	lw	a1,128(s3)
    80003b12:	0009a503          	lw	a0,0(s3)
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	898080e7          	jalr	-1896(ra) # 800033ae <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b1e:	0809a023          	sw	zero,128(s3)
    80003b22:	bf51                	j	80003ab6 <itrunc+0x3e>

0000000080003b24 <iput>:
{
    80003b24:	1101                	addi	sp,sp,-32
    80003b26:	ec06                	sd	ra,24(sp)
    80003b28:	e822                	sd	s0,16(sp)
    80003b2a:	e426                	sd	s1,8(sp)
    80003b2c:	e04a                	sd	s2,0(sp)
    80003b2e:	1000                	addi	s0,sp,32
    80003b30:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b32:	0001c517          	auipc	a0,0x1c
    80003b36:	52e50513          	addi	a0,a0,1326 # 80020060 <icache>
    80003b3a:	ffffd097          	auipc	ra,0xffffd
    80003b3e:	0d6080e7          	jalr	214(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b42:	4498                	lw	a4,8(s1)
    80003b44:	4785                	li	a5,1
    80003b46:	02f70363          	beq	a4,a5,80003b6c <iput+0x48>
  ip->ref--;
    80003b4a:	449c                	lw	a5,8(s1)
    80003b4c:	37fd                	addiw	a5,a5,-1
    80003b4e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b50:	0001c517          	auipc	a0,0x1c
    80003b54:	51050513          	addi	a0,a0,1296 # 80020060 <icache>
    80003b58:	ffffd097          	auipc	ra,0xffffd
    80003b5c:	16c080e7          	jalr	364(ra) # 80000cc4 <release>
}
    80003b60:	60e2                	ld	ra,24(sp)
    80003b62:	6442                	ld	s0,16(sp)
    80003b64:	64a2                	ld	s1,8(sp)
    80003b66:	6902                	ld	s2,0(sp)
    80003b68:	6105                	addi	sp,sp,32
    80003b6a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b6c:	40bc                	lw	a5,64(s1)
    80003b6e:	dff1                	beqz	a5,80003b4a <iput+0x26>
    80003b70:	04a49783          	lh	a5,74(s1)
    80003b74:	fbf9                	bnez	a5,80003b4a <iput+0x26>
    acquiresleep(&ip->lock);
    80003b76:	01048913          	addi	s2,s1,16
    80003b7a:	854a                	mv	a0,s2
    80003b7c:	00001097          	auipc	ra,0x1
    80003b80:	aa8080e7          	jalr	-1368(ra) # 80004624 <acquiresleep>
    release(&icache.lock);
    80003b84:	0001c517          	auipc	a0,0x1c
    80003b88:	4dc50513          	addi	a0,a0,1244 # 80020060 <icache>
    80003b8c:	ffffd097          	auipc	ra,0xffffd
    80003b90:	138080e7          	jalr	312(ra) # 80000cc4 <release>
    itrunc(ip);
    80003b94:	8526                	mv	a0,s1
    80003b96:	00000097          	auipc	ra,0x0
    80003b9a:	ee2080e7          	jalr	-286(ra) # 80003a78 <itrunc>
    ip->type = 0;
    80003b9e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ba2:	8526                	mv	a0,s1
    80003ba4:	00000097          	auipc	ra,0x0
    80003ba8:	cfc080e7          	jalr	-772(ra) # 800038a0 <iupdate>
    ip->valid = 0;
    80003bac:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bb0:	854a                	mv	a0,s2
    80003bb2:	00001097          	auipc	ra,0x1
    80003bb6:	ac8080e7          	jalr	-1336(ra) # 8000467a <releasesleep>
    acquire(&icache.lock);
    80003bba:	0001c517          	auipc	a0,0x1c
    80003bbe:	4a650513          	addi	a0,a0,1190 # 80020060 <icache>
    80003bc2:	ffffd097          	auipc	ra,0xffffd
    80003bc6:	04e080e7          	jalr	78(ra) # 80000c10 <acquire>
    80003bca:	b741                	j	80003b4a <iput+0x26>

0000000080003bcc <iunlockput>:
{
    80003bcc:	1101                	addi	sp,sp,-32
    80003bce:	ec06                	sd	ra,24(sp)
    80003bd0:	e822                	sd	s0,16(sp)
    80003bd2:	e426                	sd	s1,8(sp)
    80003bd4:	1000                	addi	s0,sp,32
    80003bd6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	e54080e7          	jalr	-428(ra) # 80003a2c <iunlock>
  iput(ip);
    80003be0:	8526                	mv	a0,s1
    80003be2:	00000097          	auipc	ra,0x0
    80003be6:	f42080e7          	jalr	-190(ra) # 80003b24 <iput>
}
    80003bea:	60e2                	ld	ra,24(sp)
    80003bec:	6442                	ld	s0,16(sp)
    80003bee:	64a2                	ld	s1,8(sp)
    80003bf0:	6105                	addi	sp,sp,32
    80003bf2:	8082                	ret

0000000080003bf4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bf4:	1141                	addi	sp,sp,-16
    80003bf6:	e422                	sd	s0,8(sp)
    80003bf8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bfa:	411c                	lw	a5,0(a0)
    80003bfc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bfe:	415c                	lw	a5,4(a0)
    80003c00:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c02:	04451783          	lh	a5,68(a0)
    80003c06:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c0a:	04a51783          	lh	a5,74(a0)
    80003c0e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c12:	04c56783          	lwu	a5,76(a0)
    80003c16:	e99c                	sd	a5,16(a1)
}
    80003c18:	6422                	ld	s0,8(sp)
    80003c1a:	0141                	addi	sp,sp,16
    80003c1c:	8082                	ret

0000000080003c1e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c1e:	457c                	lw	a5,76(a0)
    80003c20:	0ed7e863          	bltu	a5,a3,80003d10 <readi+0xf2>
{
    80003c24:	7159                	addi	sp,sp,-112
    80003c26:	f486                	sd	ra,104(sp)
    80003c28:	f0a2                	sd	s0,96(sp)
    80003c2a:	eca6                	sd	s1,88(sp)
    80003c2c:	e8ca                	sd	s2,80(sp)
    80003c2e:	e4ce                	sd	s3,72(sp)
    80003c30:	e0d2                	sd	s4,64(sp)
    80003c32:	fc56                	sd	s5,56(sp)
    80003c34:	f85a                	sd	s6,48(sp)
    80003c36:	f45e                	sd	s7,40(sp)
    80003c38:	f062                	sd	s8,32(sp)
    80003c3a:	ec66                	sd	s9,24(sp)
    80003c3c:	e86a                	sd	s10,16(sp)
    80003c3e:	e46e                	sd	s11,8(sp)
    80003c40:	1880                	addi	s0,sp,112
    80003c42:	8baa                	mv	s7,a0
    80003c44:	8c2e                	mv	s8,a1
    80003c46:	8ab2                	mv	s5,a2
    80003c48:	84b6                	mv	s1,a3
    80003c4a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c4c:	9f35                	addw	a4,a4,a3
    return 0;
    80003c4e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c50:	08d76f63          	bltu	a4,a3,80003cee <readi+0xd0>
  if(off + n > ip->size)
    80003c54:	00e7f463          	bgeu	a5,a4,80003c5c <readi+0x3e>
    n = ip->size - off;
    80003c58:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c5c:	0a0b0863          	beqz	s6,80003d0c <readi+0xee>
    80003c60:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c62:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c66:	5cfd                	li	s9,-1
    80003c68:	a82d                	j	80003ca2 <readi+0x84>
    80003c6a:	020a1d93          	slli	s11,s4,0x20
    80003c6e:	020ddd93          	srli	s11,s11,0x20
    80003c72:	05890613          	addi	a2,s2,88
    80003c76:	86ee                	mv	a3,s11
    80003c78:	963a                	add	a2,a2,a4
    80003c7a:	85d6                	mv	a1,s5
    80003c7c:	8562                	mv	a0,s8
    80003c7e:	ffffe097          	auipc	ra,0xffffe
    80003c82:	5c8080e7          	jalr	1480(ra) # 80002246 <either_copyout>
    80003c86:	05950d63          	beq	a0,s9,80003ce0 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003c8a:	854a                	mv	a0,s2
    80003c8c:	fffff097          	auipc	ra,0xfffff
    80003c90:	60c080e7          	jalr	1548(ra) # 80003298 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c94:	013a09bb          	addw	s3,s4,s3
    80003c98:	009a04bb          	addw	s1,s4,s1
    80003c9c:	9aee                	add	s5,s5,s11
    80003c9e:	0569f663          	bgeu	s3,s6,80003cea <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ca2:	000ba903          	lw	s2,0(s7)
    80003ca6:	00a4d59b          	srliw	a1,s1,0xa
    80003caa:	855e                	mv	a0,s7
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	8b0080e7          	jalr	-1872(ra) # 8000355c <bmap>
    80003cb4:	0005059b          	sext.w	a1,a0
    80003cb8:	854a                	mv	a0,s2
    80003cba:	fffff097          	auipc	ra,0xfffff
    80003cbe:	4ae080e7          	jalr	1198(ra) # 80003168 <bread>
    80003cc2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cc4:	3ff4f713          	andi	a4,s1,1023
    80003cc8:	40ed07bb          	subw	a5,s10,a4
    80003ccc:	413b06bb          	subw	a3,s6,s3
    80003cd0:	8a3e                	mv	s4,a5
    80003cd2:	2781                	sext.w	a5,a5
    80003cd4:	0006861b          	sext.w	a2,a3
    80003cd8:	f8f679e3          	bgeu	a2,a5,80003c6a <readi+0x4c>
    80003cdc:	8a36                	mv	s4,a3
    80003cde:	b771                	j	80003c6a <readi+0x4c>
      brelse(bp);
    80003ce0:	854a                	mv	a0,s2
    80003ce2:	fffff097          	auipc	ra,0xfffff
    80003ce6:	5b6080e7          	jalr	1462(ra) # 80003298 <brelse>
  }
  return tot;
    80003cea:	0009851b          	sext.w	a0,s3
}
    80003cee:	70a6                	ld	ra,104(sp)
    80003cf0:	7406                	ld	s0,96(sp)
    80003cf2:	64e6                	ld	s1,88(sp)
    80003cf4:	6946                	ld	s2,80(sp)
    80003cf6:	69a6                	ld	s3,72(sp)
    80003cf8:	6a06                	ld	s4,64(sp)
    80003cfa:	7ae2                	ld	s5,56(sp)
    80003cfc:	7b42                	ld	s6,48(sp)
    80003cfe:	7ba2                	ld	s7,40(sp)
    80003d00:	7c02                	ld	s8,32(sp)
    80003d02:	6ce2                	ld	s9,24(sp)
    80003d04:	6d42                	ld	s10,16(sp)
    80003d06:	6da2                	ld	s11,8(sp)
    80003d08:	6165                	addi	sp,sp,112
    80003d0a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d0c:	89da                	mv	s3,s6
    80003d0e:	bff1                	j	80003cea <readi+0xcc>
    return 0;
    80003d10:	4501                	li	a0,0
}
    80003d12:	8082                	ret

0000000080003d14 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d14:	457c                	lw	a5,76(a0)
    80003d16:	10d7e663          	bltu	a5,a3,80003e22 <writei+0x10e>
{
    80003d1a:	7159                	addi	sp,sp,-112
    80003d1c:	f486                	sd	ra,104(sp)
    80003d1e:	f0a2                	sd	s0,96(sp)
    80003d20:	eca6                	sd	s1,88(sp)
    80003d22:	e8ca                	sd	s2,80(sp)
    80003d24:	e4ce                	sd	s3,72(sp)
    80003d26:	e0d2                	sd	s4,64(sp)
    80003d28:	fc56                	sd	s5,56(sp)
    80003d2a:	f85a                	sd	s6,48(sp)
    80003d2c:	f45e                	sd	s7,40(sp)
    80003d2e:	f062                	sd	s8,32(sp)
    80003d30:	ec66                	sd	s9,24(sp)
    80003d32:	e86a                	sd	s10,16(sp)
    80003d34:	e46e                	sd	s11,8(sp)
    80003d36:	1880                	addi	s0,sp,112
    80003d38:	8baa                	mv	s7,a0
    80003d3a:	8c2e                	mv	s8,a1
    80003d3c:	8ab2                	mv	s5,a2
    80003d3e:	8936                	mv	s2,a3
    80003d40:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d42:	00e687bb          	addw	a5,a3,a4
    80003d46:	0ed7e063          	bltu	a5,a3,80003e26 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d4a:	00043737          	lui	a4,0x43
    80003d4e:	0cf76e63          	bltu	a4,a5,80003e2a <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d52:	0a0b0763          	beqz	s6,80003e00 <writei+0xec>
    80003d56:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d58:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d5c:	5cfd                	li	s9,-1
    80003d5e:	a091                	j	80003da2 <writei+0x8e>
    80003d60:	02099d93          	slli	s11,s3,0x20
    80003d64:	020ddd93          	srli	s11,s11,0x20
    80003d68:	05848513          	addi	a0,s1,88
    80003d6c:	86ee                	mv	a3,s11
    80003d6e:	8656                	mv	a2,s5
    80003d70:	85e2                	mv	a1,s8
    80003d72:	953a                	add	a0,a0,a4
    80003d74:	ffffe097          	auipc	ra,0xffffe
    80003d78:	528080e7          	jalr	1320(ra) # 8000229c <either_copyin>
    80003d7c:	07950263          	beq	a0,s9,80003de0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d80:	8526                	mv	a0,s1
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	77a080e7          	jalr	1914(ra) # 800044fc <log_write>
    brelse(bp);
    80003d8a:	8526                	mv	a0,s1
    80003d8c:	fffff097          	auipc	ra,0xfffff
    80003d90:	50c080e7          	jalr	1292(ra) # 80003298 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d94:	01498a3b          	addw	s4,s3,s4
    80003d98:	0129893b          	addw	s2,s3,s2
    80003d9c:	9aee                	add	s5,s5,s11
    80003d9e:	056a7663          	bgeu	s4,s6,80003dea <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003da2:	000ba483          	lw	s1,0(s7)
    80003da6:	00a9559b          	srliw	a1,s2,0xa
    80003daa:	855e                	mv	a0,s7
    80003dac:	fffff097          	auipc	ra,0xfffff
    80003db0:	7b0080e7          	jalr	1968(ra) # 8000355c <bmap>
    80003db4:	0005059b          	sext.w	a1,a0
    80003db8:	8526                	mv	a0,s1
    80003dba:	fffff097          	auipc	ra,0xfffff
    80003dbe:	3ae080e7          	jalr	942(ra) # 80003168 <bread>
    80003dc2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dc4:	3ff97713          	andi	a4,s2,1023
    80003dc8:	40ed07bb          	subw	a5,s10,a4
    80003dcc:	414b06bb          	subw	a3,s6,s4
    80003dd0:	89be                	mv	s3,a5
    80003dd2:	2781                	sext.w	a5,a5
    80003dd4:	0006861b          	sext.w	a2,a3
    80003dd8:	f8f674e3          	bgeu	a2,a5,80003d60 <writei+0x4c>
    80003ddc:	89b6                	mv	s3,a3
    80003dde:	b749                	j	80003d60 <writei+0x4c>
      brelse(bp);
    80003de0:	8526                	mv	a0,s1
    80003de2:	fffff097          	auipc	ra,0xfffff
    80003de6:	4b6080e7          	jalr	1206(ra) # 80003298 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003dea:	04cba783          	lw	a5,76(s7)
    80003dee:	0127f463          	bgeu	a5,s2,80003df6 <writei+0xe2>
      ip->size = off;
    80003df2:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003df6:	855e                	mv	a0,s7
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	aa8080e7          	jalr	-1368(ra) # 800038a0 <iupdate>
  }

  return n;
    80003e00:	000b051b          	sext.w	a0,s6
}
    80003e04:	70a6                	ld	ra,104(sp)
    80003e06:	7406                	ld	s0,96(sp)
    80003e08:	64e6                	ld	s1,88(sp)
    80003e0a:	6946                	ld	s2,80(sp)
    80003e0c:	69a6                	ld	s3,72(sp)
    80003e0e:	6a06                	ld	s4,64(sp)
    80003e10:	7ae2                	ld	s5,56(sp)
    80003e12:	7b42                	ld	s6,48(sp)
    80003e14:	7ba2                	ld	s7,40(sp)
    80003e16:	7c02                	ld	s8,32(sp)
    80003e18:	6ce2                	ld	s9,24(sp)
    80003e1a:	6d42                	ld	s10,16(sp)
    80003e1c:	6da2                	ld	s11,8(sp)
    80003e1e:	6165                	addi	sp,sp,112
    80003e20:	8082                	ret
    return -1;
    80003e22:	557d                	li	a0,-1
}
    80003e24:	8082                	ret
    return -1;
    80003e26:	557d                	li	a0,-1
    80003e28:	bff1                	j	80003e04 <writei+0xf0>
    return -1;
    80003e2a:	557d                	li	a0,-1
    80003e2c:	bfe1                	j	80003e04 <writei+0xf0>

0000000080003e2e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e2e:	1141                	addi	sp,sp,-16
    80003e30:	e406                	sd	ra,8(sp)
    80003e32:	e022                	sd	s0,0(sp)
    80003e34:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e36:	4639                	li	a2,14
    80003e38:	ffffd097          	auipc	ra,0xffffd
    80003e3c:	fb0080e7          	jalr	-80(ra) # 80000de8 <strncmp>
}
    80003e40:	60a2                	ld	ra,8(sp)
    80003e42:	6402                	ld	s0,0(sp)
    80003e44:	0141                	addi	sp,sp,16
    80003e46:	8082                	ret

0000000080003e48 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e48:	7139                	addi	sp,sp,-64
    80003e4a:	fc06                	sd	ra,56(sp)
    80003e4c:	f822                	sd	s0,48(sp)
    80003e4e:	f426                	sd	s1,40(sp)
    80003e50:	f04a                	sd	s2,32(sp)
    80003e52:	ec4e                	sd	s3,24(sp)
    80003e54:	e852                	sd	s4,16(sp)
    80003e56:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e58:	04451703          	lh	a4,68(a0)
    80003e5c:	4785                	li	a5,1
    80003e5e:	00f71a63          	bne	a4,a5,80003e72 <dirlookup+0x2a>
    80003e62:	892a                	mv	s2,a0
    80003e64:	89ae                	mv	s3,a1
    80003e66:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e68:	457c                	lw	a5,76(a0)
    80003e6a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e6c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6e:	e79d                	bnez	a5,80003e9c <dirlookup+0x54>
    80003e70:	a8a5                	j	80003ee8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e72:	00004517          	auipc	a0,0x4
    80003e76:	7b650513          	addi	a0,a0,1974 # 80008628 <syscalls+0x1a0>
    80003e7a:	ffffc097          	auipc	ra,0xffffc
    80003e7e:	6ce080e7          	jalr	1742(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003e82:	00004517          	auipc	a0,0x4
    80003e86:	7be50513          	addi	a0,a0,1982 # 80008640 <syscalls+0x1b8>
    80003e8a:	ffffc097          	auipc	ra,0xffffc
    80003e8e:	6be080e7          	jalr	1726(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e92:	24c1                	addiw	s1,s1,16
    80003e94:	04c92783          	lw	a5,76(s2)
    80003e98:	04f4f763          	bgeu	s1,a5,80003ee6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e9c:	4741                	li	a4,16
    80003e9e:	86a6                	mv	a3,s1
    80003ea0:	fc040613          	addi	a2,s0,-64
    80003ea4:	4581                	li	a1,0
    80003ea6:	854a                	mv	a0,s2
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	d76080e7          	jalr	-650(ra) # 80003c1e <readi>
    80003eb0:	47c1                	li	a5,16
    80003eb2:	fcf518e3          	bne	a0,a5,80003e82 <dirlookup+0x3a>
    if(de.inum == 0)
    80003eb6:	fc045783          	lhu	a5,-64(s0)
    80003eba:	dfe1                	beqz	a5,80003e92 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ebc:	fc240593          	addi	a1,s0,-62
    80003ec0:	854e                	mv	a0,s3
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	f6c080e7          	jalr	-148(ra) # 80003e2e <namecmp>
    80003eca:	f561                	bnez	a0,80003e92 <dirlookup+0x4a>
      if(poff)
    80003ecc:	000a0463          	beqz	s4,80003ed4 <dirlookup+0x8c>
        *poff = off;
    80003ed0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ed4:	fc045583          	lhu	a1,-64(s0)
    80003ed8:	00092503          	lw	a0,0(s2)
    80003edc:	fffff097          	auipc	ra,0xfffff
    80003ee0:	75a080e7          	jalr	1882(ra) # 80003636 <iget>
    80003ee4:	a011                	j	80003ee8 <dirlookup+0xa0>
  return 0;
    80003ee6:	4501                	li	a0,0
}
    80003ee8:	70e2                	ld	ra,56(sp)
    80003eea:	7442                	ld	s0,48(sp)
    80003eec:	74a2                	ld	s1,40(sp)
    80003eee:	7902                	ld	s2,32(sp)
    80003ef0:	69e2                	ld	s3,24(sp)
    80003ef2:	6a42                	ld	s4,16(sp)
    80003ef4:	6121                	addi	sp,sp,64
    80003ef6:	8082                	ret

0000000080003ef8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ef8:	711d                	addi	sp,sp,-96
    80003efa:	ec86                	sd	ra,88(sp)
    80003efc:	e8a2                	sd	s0,80(sp)
    80003efe:	e4a6                	sd	s1,72(sp)
    80003f00:	e0ca                	sd	s2,64(sp)
    80003f02:	fc4e                	sd	s3,56(sp)
    80003f04:	f852                	sd	s4,48(sp)
    80003f06:	f456                	sd	s5,40(sp)
    80003f08:	f05a                	sd	s6,32(sp)
    80003f0a:	ec5e                	sd	s7,24(sp)
    80003f0c:	e862                	sd	s8,16(sp)
    80003f0e:	e466                	sd	s9,8(sp)
    80003f10:	1080                	addi	s0,sp,96
    80003f12:	84aa                	mv	s1,a0
    80003f14:	8b2e                	mv	s6,a1
    80003f16:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f18:	00054703          	lbu	a4,0(a0)
    80003f1c:	02f00793          	li	a5,47
    80003f20:	02f70363          	beq	a4,a5,80003f46 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f24:	ffffe097          	auipc	ra,0xffffe
    80003f28:	c44080e7          	jalr	-956(ra) # 80001b68 <myproc>
    80003f2c:	15053503          	ld	a0,336(a0)
    80003f30:	00000097          	auipc	ra,0x0
    80003f34:	9fc080e7          	jalr	-1540(ra) # 8000392c <idup>
    80003f38:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f3a:	02f00913          	li	s2,47
  len = path - s;
    80003f3e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f40:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f42:	4c05                	li	s8,1
    80003f44:	a865                	j	80003ffc <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f46:	4585                	li	a1,1
    80003f48:	4505                	li	a0,1
    80003f4a:	fffff097          	auipc	ra,0xfffff
    80003f4e:	6ec080e7          	jalr	1772(ra) # 80003636 <iget>
    80003f52:	89aa                	mv	s3,a0
    80003f54:	b7dd                	j	80003f3a <namex+0x42>
      iunlockput(ip);
    80003f56:	854e                	mv	a0,s3
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	c74080e7          	jalr	-908(ra) # 80003bcc <iunlockput>
      return 0;
    80003f60:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f62:	854e                	mv	a0,s3
    80003f64:	60e6                	ld	ra,88(sp)
    80003f66:	6446                	ld	s0,80(sp)
    80003f68:	64a6                	ld	s1,72(sp)
    80003f6a:	6906                	ld	s2,64(sp)
    80003f6c:	79e2                	ld	s3,56(sp)
    80003f6e:	7a42                	ld	s4,48(sp)
    80003f70:	7aa2                	ld	s5,40(sp)
    80003f72:	7b02                	ld	s6,32(sp)
    80003f74:	6be2                	ld	s7,24(sp)
    80003f76:	6c42                	ld	s8,16(sp)
    80003f78:	6ca2                	ld	s9,8(sp)
    80003f7a:	6125                	addi	sp,sp,96
    80003f7c:	8082                	ret
      iunlock(ip);
    80003f7e:	854e                	mv	a0,s3
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	aac080e7          	jalr	-1364(ra) # 80003a2c <iunlock>
      return ip;
    80003f88:	bfe9                	j	80003f62 <namex+0x6a>
      iunlockput(ip);
    80003f8a:	854e                	mv	a0,s3
    80003f8c:	00000097          	auipc	ra,0x0
    80003f90:	c40080e7          	jalr	-960(ra) # 80003bcc <iunlockput>
      return 0;
    80003f94:	89d2                	mv	s3,s4
    80003f96:	b7f1                	j	80003f62 <namex+0x6a>
  len = path - s;
    80003f98:	40b48633          	sub	a2,s1,a1
    80003f9c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003fa0:	094cd463          	bge	s9,s4,80004028 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fa4:	4639                	li	a2,14
    80003fa6:	8556                	mv	a0,s5
    80003fa8:	ffffd097          	auipc	ra,0xffffd
    80003fac:	dc4080e7          	jalr	-572(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003fb0:	0004c783          	lbu	a5,0(s1)
    80003fb4:	01279763          	bne	a5,s2,80003fc2 <namex+0xca>
    path++;
    80003fb8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fba:	0004c783          	lbu	a5,0(s1)
    80003fbe:	ff278de3          	beq	a5,s2,80003fb8 <namex+0xc0>
    ilock(ip);
    80003fc2:	854e                	mv	a0,s3
    80003fc4:	00000097          	auipc	ra,0x0
    80003fc8:	9a6080e7          	jalr	-1626(ra) # 8000396a <ilock>
    if(ip->type != T_DIR){
    80003fcc:	04499783          	lh	a5,68(s3)
    80003fd0:	f98793e3          	bne	a5,s8,80003f56 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fd4:	000b0563          	beqz	s6,80003fde <namex+0xe6>
    80003fd8:	0004c783          	lbu	a5,0(s1)
    80003fdc:	d3cd                	beqz	a5,80003f7e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fde:	865e                	mv	a2,s7
    80003fe0:	85d6                	mv	a1,s5
    80003fe2:	854e                	mv	a0,s3
    80003fe4:	00000097          	auipc	ra,0x0
    80003fe8:	e64080e7          	jalr	-412(ra) # 80003e48 <dirlookup>
    80003fec:	8a2a                	mv	s4,a0
    80003fee:	dd51                	beqz	a0,80003f8a <namex+0x92>
    iunlockput(ip);
    80003ff0:	854e                	mv	a0,s3
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	bda080e7          	jalr	-1062(ra) # 80003bcc <iunlockput>
    ip = next;
    80003ffa:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ffc:	0004c783          	lbu	a5,0(s1)
    80004000:	05279763          	bne	a5,s2,8000404e <namex+0x156>
    path++;
    80004004:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004006:	0004c783          	lbu	a5,0(s1)
    8000400a:	ff278de3          	beq	a5,s2,80004004 <namex+0x10c>
  if(*path == 0)
    8000400e:	c79d                	beqz	a5,8000403c <namex+0x144>
    path++;
    80004010:	85a6                	mv	a1,s1
  len = path - s;
    80004012:	8a5e                	mv	s4,s7
    80004014:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004016:	01278963          	beq	a5,s2,80004028 <namex+0x130>
    8000401a:	dfbd                	beqz	a5,80003f98 <namex+0xa0>
    path++;
    8000401c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000401e:	0004c783          	lbu	a5,0(s1)
    80004022:	ff279ce3          	bne	a5,s2,8000401a <namex+0x122>
    80004026:	bf8d                	j	80003f98 <namex+0xa0>
    memmove(name, s, len);
    80004028:	2601                	sext.w	a2,a2
    8000402a:	8556                	mv	a0,s5
    8000402c:	ffffd097          	auipc	ra,0xffffd
    80004030:	d40080e7          	jalr	-704(ra) # 80000d6c <memmove>
    name[len] = 0;
    80004034:	9a56                	add	s4,s4,s5
    80004036:	000a0023          	sb	zero,0(s4)
    8000403a:	bf9d                	j	80003fb0 <namex+0xb8>
  if(nameiparent){
    8000403c:	f20b03e3          	beqz	s6,80003f62 <namex+0x6a>
    iput(ip);
    80004040:	854e                	mv	a0,s3
    80004042:	00000097          	auipc	ra,0x0
    80004046:	ae2080e7          	jalr	-1310(ra) # 80003b24 <iput>
    return 0;
    8000404a:	4981                	li	s3,0
    8000404c:	bf19                	j	80003f62 <namex+0x6a>
  if(*path == 0)
    8000404e:	d7fd                	beqz	a5,8000403c <namex+0x144>
  while(*path != '/' && *path != 0)
    80004050:	0004c783          	lbu	a5,0(s1)
    80004054:	85a6                	mv	a1,s1
    80004056:	b7d1                	j	8000401a <namex+0x122>

0000000080004058 <dirlink>:
{
    80004058:	7139                	addi	sp,sp,-64
    8000405a:	fc06                	sd	ra,56(sp)
    8000405c:	f822                	sd	s0,48(sp)
    8000405e:	f426                	sd	s1,40(sp)
    80004060:	f04a                	sd	s2,32(sp)
    80004062:	ec4e                	sd	s3,24(sp)
    80004064:	e852                	sd	s4,16(sp)
    80004066:	0080                	addi	s0,sp,64
    80004068:	892a                	mv	s2,a0
    8000406a:	8a2e                	mv	s4,a1
    8000406c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000406e:	4601                	li	a2,0
    80004070:	00000097          	auipc	ra,0x0
    80004074:	dd8080e7          	jalr	-552(ra) # 80003e48 <dirlookup>
    80004078:	e93d                	bnez	a0,800040ee <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000407a:	04c92483          	lw	s1,76(s2)
    8000407e:	c49d                	beqz	s1,800040ac <dirlink+0x54>
    80004080:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004082:	4741                	li	a4,16
    80004084:	86a6                	mv	a3,s1
    80004086:	fc040613          	addi	a2,s0,-64
    8000408a:	4581                	li	a1,0
    8000408c:	854a                	mv	a0,s2
    8000408e:	00000097          	auipc	ra,0x0
    80004092:	b90080e7          	jalr	-1136(ra) # 80003c1e <readi>
    80004096:	47c1                	li	a5,16
    80004098:	06f51163          	bne	a0,a5,800040fa <dirlink+0xa2>
    if(de.inum == 0)
    8000409c:	fc045783          	lhu	a5,-64(s0)
    800040a0:	c791                	beqz	a5,800040ac <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a2:	24c1                	addiw	s1,s1,16
    800040a4:	04c92783          	lw	a5,76(s2)
    800040a8:	fcf4ede3          	bltu	s1,a5,80004082 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040ac:	4639                	li	a2,14
    800040ae:	85d2                	mv	a1,s4
    800040b0:	fc240513          	addi	a0,s0,-62
    800040b4:	ffffd097          	auipc	ra,0xffffd
    800040b8:	d70080e7          	jalr	-656(ra) # 80000e24 <strncpy>
  de.inum = inum;
    800040bc:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040c0:	4741                	li	a4,16
    800040c2:	86a6                	mv	a3,s1
    800040c4:	fc040613          	addi	a2,s0,-64
    800040c8:	4581                	li	a1,0
    800040ca:	854a                	mv	a0,s2
    800040cc:	00000097          	auipc	ra,0x0
    800040d0:	c48080e7          	jalr	-952(ra) # 80003d14 <writei>
    800040d4:	872a                	mv	a4,a0
    800040d6:	47c1                	li	a5,16
  return 0;
    800040d8:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040da:	02f71863          	bne	a4,a5,8000410a <dirlink+0xb2>
}
    800040de:	70e2                	ld	ra,56(sp)
    800040e0:	7442                	ld	s0,48(sp)
    800040e2:	74a2                	ld	s1,40(sp)
    800040e4:	7902                	ld	s2,32(sp)
    800040e6:	69e2                	ld	s3,24(sp)
    800040e8:	6a42                	ld	s4,16(sp)
    800040ea:	6121                	addi	sp,sp,64
    800040ec:	8082                	ret
    iput(ip);
    800040ee:	00000097          	auipc	ra,0x0
    800040f2:	a36080e7          	jalr	-1482(ra) # 80003b24 <iput>
    return -1;
    800040f6:	557d                	li	a0,-1
    800040f8:	b7dd                	j	800040de <dirlink+0x86>
      panic("dirlink read");
    800040fa:	00004517          	auipc	a0,0x4
    800040fe:	55650513          	addi	a0,a0,1366 # 80008650 <syscalls+0x1c8>
    80004102:	ffffc097          	auipc	ra,0xffffc
    80004106:	446080e7          	jalr	1094(ra) # 80000548 <panic>
    panic("dirlink");
    8000410a:	00004517          	auipc	a0,0x4
    8000410e:	65e50513          	addi	a0,a0,1630 # 80008768 <syscalls+0x2e0>
    80004112:	ffffc097          	auipc	ra,0xffffc
    80004116:	436080e7          	jalr	1078(ra) # 80000548 <panic>

000000008000411a <namei>:

struct inode*
namei(char *path)
{
    8000411a:	1101                	addi	sp,sp,-32
    8000411c:	ec06                	sd	ra,24(sp)
    8000411e:	e822                	sd	s0,16(sp)
    80004120:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004122:	fe040613          	addi	a2,s0,-32
    80004126:	4581                	li	a1,0
    80004128:	00000097          	auipc	ra,0x0
    8000412c:	dd0080e7          	jalr	-560(ra) # 80003ef8 <namex>
}
    80004130:	60e2                	ld	ra,24(sp)
    80004132:	6442                	ld	s0,16(sp)
    80004134:	6105                	addi	sp,sp,32
    80004136:	8082                	ret

0000000080004138 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004138:	1141                	addi	sp,sp,-16
    8000413a:	e406                	sd	ra,8(sp)
    8000413c:	e022                	sd	s0,0(sp)
    8000413e:	0800                	addi	s0,sp,16
    80004140:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004142:	4585                	li	a1,1
    80004144:	00000097          	auipc	ra,0x0
    80004148:	db4080e7          	jalr	-588(ra) # 80003ef8 <namex>
}
    8000414c:	60a2                	ld	ra,8(sp)
    8000414e:	6402                	ld	s0,0(sp)
    80004150:	0141                	addi	sp,sp,16
    80004152:	8082                	ret

0000000080004154 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004154:	1101                	addi	sp,sp,-32
    80004156:	ec06                	sd	ra,24(sp)
    80004158:	e822                	sd	s0,16(sp)
    8000415a:	e426                	sd	s1,8(sp)
    8000415c:	e04a                	sd	s2,0(sp)
    8000415e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004160:	0001e917          	auipc	s2,0x1e
    80004164:	9a890913          	addi	s2,s2,-1624 # 80021b08 <log>
    80004168:	01892583          	lw	a1,24(s2)
    8000416c:	02892503          	lw	a0,40(s2)
    80004170:	fffff097          	auipc	ra,0xfffff
    80004174:	ff8080e7          	jalr	-8(ra) # 80003168 <bread>
    80004178:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000417a:	02c92683          	lw	a3,44(s2)
    8000417e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004180:	02d05763          	blez	a3,800041ae <write_head+0x5a>
    80004184:	0001e797          	auipc	a5,0x1e
    80004188:	9b478793          	addi	a5,a5,-1612 # 80021b38 <log+0x30>
    8000418c:	05c50713          	addi	a4,a0,92
    80004190:	36fd                	addiw	a3,a3,-1
    80004192:	1682                	slli	a3,a3,0x20
    80004194:	9281                	srli	a3,a3,0x20
    80004196:	068a                	slli	a3,a3,0x2
    80004198:	0001e617          	auipc	a2,0x1e
    8000419c:	9a460613          	addi	a2,a2,-1628 # 80021b3c <log+0x34>
    800041a0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041a2:	4390                	lw	a2,0(a5)
    800041a4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041a6:	0791                	addi	a5,a5,4
    800041a8:	0711                	addi	a4,a4,4
    800041aa:	fed79ce3          	bne	a5,a3,800041a2 <write_head+0x4e>
  }
  bwrite(buf);
    800041ae:	8526                	mv	a0,s1
    800041b0:	fffff097          	auipc	ra,0xfffff
    800041b4:	0aa080e7          	jalr	170(ra) # 8000325a <bwrite>
  brelse(buf);
    800041b8:	8526                	mv	a0,s1
    800041ba:	fffff097          	auipc	ra,0xfffff
    800041be:	0de080e7          	jalr	222(ra) # 80003298 <brelse>
}
    800041c2:	60e2                	ld	ra,24(sp)
    800041c4:	6442                	ld	s0,16(sp)
    800041c6:	64a2                	ld	s1,8(sp)
    800041c8:	6902                	ld	s2,0(sp)
    800041ca:	6105                	addi	sp,sp,32
    800041cc:	8082                	ret

00000000800041ce <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ce:	0001e797          	auipc	a5,0x1e
    800041d2:	9667a783          	lw	a5,-1690(a5) # 80021b34 <log+0x2c>
    800041d6:	0af05663          	blez	a5,80004282 <install_trans+0xb4>
{
    800041da:	7139                	addi	sp,sp,-64
    800041dc:	fc06                	sd	ra,56(sp)
    800041de:	f822                	sd	s0,48(sp)
    800041e0:	f426                	sd	s1,40(sp)
    800041e2:	f04a                	sd	s2,32(sp)
    800041e4:	ec4e                	sd	s3,24(sp)
    800041e6:	e852                	sd	s4,16(sp)
    800041e8:	e456                	sd	s5,8(sp)
    800041ea:	0080                	addi	s0,sp,64
    800041ec:	0001ea97          	auipc	s5,0x1e
    800041f0:	94ca8a93          	addi	s5,s5,-1716 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041f4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041f6:	0001e997          	auipc	s3,0x1e
    800041fa:	91298993          	addi	s3,s3,-1774 # 80021b08 <log>
    800041fe:	0189a583          	lw	a1,24(s3)
    80004202:	014585bb          	addw	a1,a1,s4
    80004206:	2585                	addiw	a1,a1,1
    80004208:	0289a503          	lw	a0,40(s3)
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	f5c080e7          	jalr	-164(ra) # 80003168 <bread>
    80004214:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004216:	000aa583          	lw	a1,0(s5)
    8000421a:	0289a503          	lw	a0,40(s3)
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	f4a080e7          	jalr	-182(ra) # 80003168 <bread>
    80004226:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004228:	40000613          	li	a2,1024
    8000422c:	05890593          	addi	a1,s2,88
    80004230:	05850513          	addi	a0,a0,88
    80004234:	ffffd097          	auipc	ra,0xffffd
    80004238:	b38080e7          	jalr	-1224(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    8000423c:	8526                	mv	a0,s1
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	01c080e7          	jalr	28(ra) # 8000325a <bwrite>
    bunpin(dbuf);
    80004246:	8526                	mv	a0,s1
    80004248:	fffff097          	auipc	ra,0xfffff
    8000424c:	12a080e7          	jalr	298(ra) # 80003372 <bunpin>
    brelse(lbuf);
    80004250:	854a                	mv	a0,s2
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	046080e7          	jalr	70(ra) # 80003298 <brelse>
    brelse(dbuf);
    8000425a:	8526                	mv	a0,s1
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	03c080e7          	jalr	60(ra) # 80003298 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004264:	2a05                	addiw	s4,s4,1
    80004266:	0a91                	addi	s5,s5,4
    80004268:	02c9a783          	lw	a5,44(s3)
    8000426c:	f8fa49e3          	blt	s4,a5,800041fe <install_trans+0x30>
}
    80004270:	70e2                	ld	ra,56(sp)
    80004272:	7442                	ld	s0,48(sp)
    80004274:	74a2                	ld	s1,40(sp)
    80004276:	7902                	ld	s2,32(sp)
    80004278:	69e2                	ld	s3,24(sp)
    8000427a:	6a42                	ld	s4,16(sp)
    8000427c:	6aa2                	ld	s5,8(sp)
    8000427e:	6121                	addi	sp,sp,64
    80004280:	8082                	ret
    80004282:	8082                	ret

0000000080004284 <initlog>:
{
    80004284:	7179                	addi	sp,sp,-48
    80004286:	f406                	sd	ra,40(sp)
    80004288:	f022                	sd	s0,32(sp)
    8000428a:	ec26                	sd	s1,24(sp)
    8000428c:	e84a                	sd	s2,16(sp)
    8000428e:	e44e                	sd	s3,8(sp)
    80004290:	1800                	addi	s0,sp,48
    80004292:	892a                	mv	s2,a0
    80004294:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004296:	0001e497          	auipc	s1,0x1e
    8000429a:	87248493          	addi	s1,s1,-1934 # 80021b08 <log>
    8000429e:	00004597          	auipc	a1,0x4
    800042a2:	3c258593          	addi	a1,a1,962 # 80008660 <syscalls+0x1d8>
    800042a6:	8526                	mv	a0,s1
    800042a8:	ffffd097          	auipc	ra,0xffffd
    800042ac:	8d8080e7          	jalr	-1832(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    800042b0:	0149a583          	lw	a1,20(s3)
    800042b4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042b6:	0109a783          	lw	a5,16(s3)
    800042ba:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042bc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042c0:	854a                	mv	a0,s2
    800042c2:	fffff097          	auipc	ra,0xfffff
    800042c6:	ea6080e7          	jalr	-346(ra) # 80003168 <bread>
  log.lh.n = lh->n;
    800042ca:	4d3c                	lw	a5,88(a0)
    800042cc:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042ce:	02f05563          	blez	a5,800042f8 <initlog+0x74>
    800042d2:	05c50713          	addi	a4,a0,92
    800042d6:	0001e697          	auipc	a3,0x1e
    800042da:	86268693          	addi	a3,a3,-1950 # 80021b38 <log+0x30>
    800042de:	37fd                	addiw	a5,a5,-1
    800042e0:	1782                	slli	a5,a5,0x20
    800042e2:	9381                	srli	a5,a5,0x20
    800042e4:	078a                	slli	a5,a5,0x2
    800042e6:	06050613          	addi	a2,a0,96
    800042ea:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800042ec:	4310                	lw	a2,0(a4)
    800042ee:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800042f0:	0711                	addi	a4,a4,4
    800042f2:	0691                	addi	a3,a3,4
    800042f4:	fef71ce3          	bne	a4,a5,800042ec <initlog+0x68>
  brelse(buf);
    800042f8:	fffff097          	auipc	ra,0xfffff
    800042fc:	fa0080e7          	jalr	-96(ra) # 80003298 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004300:	00000097          	auipc	ra,0x0
    80004304:	ece080e7          	jalr	-306(ra) # 800041ce <install_trans>
  log.lh.n = 0;
    80004308:	0001e797          	auipc	a5,0x1e
    8000430c:	8207a623          	sw	zero,-2004(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    80004310:	00000097          	auipc	ra,0x0
    80004314:	e44080e7          	jalr	-444(ra) # 80004154 <write_head>
}
    80004318:	70a2                	ld	ra,40(sp)
    8000431a:	7402                	ld	s0,32(sp)
    8000431c:	64e2                	ld	s1,24(sp)
    8000431e:	6942                	ld	s2,16(sp)
    80004320:	69a2                	ld	s3,8(sp)
    80004322:	6145                	addi	sp,sp,48
    80004324:	8082                	ret

0000000080004326 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004326:	1101                	addi	sp,sp,-32
    80004328:	ec06                	sd	ra,24(sp)
    8000432a:	e822                	sd	s0,16(sp)
    8000432c:	e426                	sd	s1,8(sp)
    8000432e:	e04a                	sd	s2,0(sp)
    80004330:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004332:	0001d517          	auipc	a0,0x1d
    80004336:	7d650513          	addi	a0,a0,2006 # 80021b08 <log>
    8000433a:	ffffd097          	auipc	ra,0xffffd
    8000433e:	8d6080e7          	jalr	-1834(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    80004342:	0001d497          	auipc	s1,0x1d
    80004346:	7c648493          	addi	s1,s1,1990 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000434a:	4979                	li	s2,30
    8000434c:	a039                	j	8000435a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000434e:	85a6                	mv	a1,s1
    80004350:	8526                	mv	a0,s1
    80004352:	ffffe097          	auipc	ra,0xffffe
    80004356:	d9a080e7          	jalr	-614(ra) # 800020ec <sleep>
    if(log.committing){
    8000435a:	50dc                	lw	a5,36(s1)
    8000435c:	fbed                	bnez	a5,8000434e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000435e:	509c                	lw	a5,32(s1)
    80004360:	0017871b          	addiw	a4,a5,1
    80004364:	0007069b          	sext.w	a3,a4
    80004368:	0027179b          	slliw	a5,a4,0x2
    8000436c:	9fb9                	addw	a5,a5,a4
    8000436e:	0017979b          	slliw	a5,a5,0x1
    80004372:	54d8                	lw	a4,44(s1)
    80004374:	9fb9                	addw	a5,a5,a4
    80004376:	00f95963          	bge	s2,a5,80004388 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000437a:	85a6                	mv	a1,s1
    8000437c:	8526                	mv	a0,s1
    8000437e:	ffffe097          	auipc	ra,0xffffe
    80004382:	d6e080e7          	jalr	-658(ra) # 800020ec <sleep>
    80004386:	bfd1                	j	8000435a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004388:	0001d517          	auipc	a0,0x1d
    8000438c:	78050513          	addi	a0,a0,1920 # 80021b08 <log>
    80004390:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004392:	ffffd097          	auipc	ra,0xffffd
    80004396:	932080e7          	jalr	-1742(ra) # 80000cc4 <release>
      break;
    }
  }
}
    8000439a:	60e2                	ld	ra,24(sp)
    8000439c:	6442                	ld	s0,16(sp)
    8000439e:	64a2                	ld	s1,8(sp)
    800043a0:	6902                	ld	s2,0(sp)
    800043a2:	6105                	addi	sp,sp,32
    800043a4:	8082                	ret

00000000800043a6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043a6:	7139                	addi	sp,sp,-64
    800043a8:	fc06                	sd	ra,56(sp)
    800043aa:	f822                	sd	s0,48(sp)
    800043ac:	f426                	sd	s1,40(sp)
    800043ae:	f04a                	sd	s2,32(sp)
    800043b0:	ec4e                	sd	s3,24(sp)
    800043b2:	e852                	sd	s4,16(sp)
    800043b4:	e456                	sd	s5,8(sp)
    800043b6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043b8:	0001d497          	auipc	s1,0x1d
    800043bc:	75048493          	addi	s1,s1,1872 # 80021b08 <log>
    800043c0:	8526                	mv	a0,s1
    800043c2:	ffffd097          	auipc	ra,0xffffd
    800043c6:	84e080e7          	jalr	-1970(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    800043ca:	509c                	lw	a5,32(s1)
    800043cc:	37fd                	addiw	a5,a5,-1
    800043ce:	0007891b          	sext.w	s2,a5
    800043d2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043d4:	50dc                	lw	a5,36(s1)
    800043d6:	efb9                	bnez	a5,80004434 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043d8:	06091663          	bnez	s2,80004444 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043dc:	0001d497          	auipc	s1,0x1d
    800043e0:	72c48493          	addi	s1,s1,1836 # 80021b08 <log>
    800043e4:	4785                	li	a5,1
    800043e6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043e8:	8526                	mv	a0,s1
    800043ea:	ffffd097          	auipc	ra,0xffffd
    800043ee:	8da080e7          	jalr	-1830(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043f2:	54dc                	lw	a5,44(s1)
    800043f4:	06f04763          	bgtz	a5,80004462 <end_op+0xbc>
    acquire(&log.lock);
    800043f8:	0001d497          	auipc	s1,0x1d
    800043fc:	71048493          	addi	s1,s1,1808 # 80021b08 <log>
    80004400:	8526                	mv	a0,s1
    80004402:	ffffd097          	auipc	ra,0xffffd
    80004406:	80e080e7          	jalr	-2034(ra) # 80000c10 <acquire>
    log.committing = 0;
    8000440a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000440e:	8526                	mv	a0,s1
    80004410:	ffffe097          	auipc	ra,0xffffe
    80004414:	d5a080e7          	jalr	-678(ra) # 8000216a <wakeup>
    release(&log.lock);
    80004418:	8526                	mv	a0,s1
    8000441a:	ffffd097          	auipc	ra,0xffffd
    8000441e:	8aa080e7          	jalr	-1878(ra) # 80000cc4 <release>
}
    80004422:	70e2                	ld	ra,56(sp)
    80004424:	7442                	ld	s0,48(sp)
    80004426:	74a2                	ld	s1,40(sp)
    80004428:	7902                	ld	s2,32(sp)
    8000442a:	69e2                	ld	s3,24(sp)
    8000442c:	6a42                	ld	s4,16(sp)
    8000442e:	6aa2                	ld	s5,8(sp)
    80004430:	6121                	addi	sp,sp,64
    80004432:	8082                	ret
    panic("log.committing");
    80004434:	00004517          	auipc	a0,0x4
    80004438:	23450513          	addi	a0,a0,564 # 80008668 <syscalls+0x1e0>
    8000443c:	ffffc097          	auipc	ra,0xffffc
    80004440:	10c080e7          	jalr	268(ra) # 80000548 <panic>
    wakeup(&log);
    80004444:	0001d497          	auipc	s1,0x1d
    80004448:	6c448493          	addi	s1,s1,1732 # 80021b08 <log>
    8000444c:	8526                	mv	a0,s1
    8000444e:	ffffe097          	auipc	ra,0xffffe
    80004452:	d1c080e7          	jalr	-740(ra) # 8000216a <wakeup>
  release(&log.lock);
    80004456:	8526                	mv	a0,s1
    80004458:	ffffd097          	auipc	ra,0xffffd
    8000445c:	86c080e7          	jalr	-1940(ra) # 80000cc4 <release>
  if(do_commit){
    80004460:	b7c9                	j	80004422 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004462:	0001da97          	auipc	s5,0x1d
    80004466:	6d6a8a93          	addi	s5,s5,1750 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000446a:	0001da17          	auipc	s4,0x1d
    8000446e:	69ea0a13          	addi	s4,s4,1694 # 80021b08 <log>
    80004472:	018a2583          	lw	a1,24(s4)
    80004476:	012585bb          	addw	a1,a1,s2
    8000447a:	2585                	addiw	a1,a1,1
    8000447c:	028a2503          	lw	a0,40(s4)
    80004480:	fffff097          	auipc	ra,0xfffff
    80004484:	ce8080e7          	jalr	-792(ra) # 80003168 <bread>
    80004488:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000448a:	000aa583          	lw	a1,0(s5)
    8000448e:	028a2503          	lw	a0,40(s4)
    80004492:	fffff097          	auipc	ra,0xfffff
    80004496:	cd6080e7          	jalr	-810(ra) # 80003168 <bread>
    8000449a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000449c:	40000613          	li	a2,1024
    800044a0:	05850593          	addi	a1,a0,88
    800044a4:	05848513          	addi	a0,s1,88
    800044a8:	ffffd097          	auipc	ra,0xffffd
    800044ac:	8c4080e7          	jalr	-1852(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    800044b0:	8526                	mv	a0,s1
    800044b2:	fffff097          	auipc	ra,0xfffff
    800044b6:	da8080e7          	jalr	-600(ra) # 8000325a <bwrite>
    brelse(from);
    800044ba:	854e                	mv	a0,s3
    800044bc:	fffff097          	auipc	ra,0xfffff
    800044c0:	ddc080e7          	jalr	-548(ra) # 80003298 <brelse>
    brelse(to);
    800044c4:	8526                	mv	a0,s1
    800044c6:	fffff097          	auipc	ra,0xfffff
    800044ca:	dd2080e7          	jalr	-558(ra) # 80003298 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ce:	2905                	addiw	s2,s2,1
    800044d0:	0a91                	addi	s5,s5,4
    800044d2:	02ca2783          	lw	a5,44(s4)
    800044d6:	f8f94ee3          	blt	s2,a5,80004472 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044da:	00000097          	auipc	ra,0x0
    800044de:	c7a080e7          	jalr	-902(ra) # 80004154 <write_head>
    install_trans(); // Now install writes to home locations
    800044e2:	00000097          	auipc	ra,0x0
    800044e6:	cec080e7          	jalr	-788(ra) # 800041ce <install_trans>
    log.lh.n = 0;
    800044ea:	0001d797          	auipc	a5,0x1d
    800044ee:	6407a523          	sw	zero,1610(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044f2:	00000097          	auipc	ra,0x0
    800044f6:	c62080e7          	jalr	-926(ra) # 80004154 <write_head>
    800044fa:	bdfd                	j	800043f8 <end_op+0x52>

00000000800044fc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044fc:	1101                	addi	sp,sp,-32
    800044fe:	ec06                	sd	ra,24(sp)
    80004500:	e822                	sd	s0,16(sp)
    80004502:	e426                	sd	s1,8(sp)
    80004504:	e04a                	sd	s2,0(sp)
    80004506:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004508:	0001d717          	auipc	a4,0x1d
    8000450c:	62c72703          	lw	a4,1580(a4) # 80021b34 <log+0x2c>
    80004510:	47f5                	li	a5,29
    80004512:	08e7c063          	blt	a5,a4,80004592 <log_write+0x96>
    80004516:	84aa                	mv	s1,a0
    80004518:	0001d797          	auipc	a5,0x1d
    8000451c:	60c7a783          	lw	a5,1548(a5) # 80021b24 <log+0x1c>
    80004520:	37fd                	addiw	a5,a5,-1
    80004522:	06f75863          	bge	a4,a5,80004592 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004526:	0001d797          	auipc	a5,0x1d
    8000452a:	6027a783          	lw	a5,1538(a5) # 80021b28 <log+0x20>
    8000452e:	06f05a63          	blez	a5,800045a2 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004532:	0001d917          	auipc	s2,0x1d
    80004536:	5d690913          	addi	s2,s2,1494 # 80021b08 <log>
    8000453a:	854a                	mv	a0,s2
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	6d4080e7          	jalr	1748(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004544:	02c92603          	lw	a2,44(s2)
    80004548:	06c05563          	blez	a2,800045b2 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000454c:	44cc                	lw	a1,12(s1)
    8000454e:	0001d717          	auipc	a4,0x1d
    80004552:	5ea70713          	addi	a4,a4,1514 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004556:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004558:	4314                	lw	a3,0(a4)
    8000455a:	04b68d63          	beq	a3,a1,800045b4 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000455e:	2785                	addiw	a5,a5,1
    80004560:	0711                	addi	a4,a4,4
    80004562:	fec79be3          	bne	a5,a2,80004558 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004566:	0621                	addi	a2,a2,8
    80004568:	060a                	slli	a2,a2,0x2
    8000456a:	0001d797          	auipc	a5,0x1d
    8000456e:	59e78793          	addi	a5,a5,1438 # 80021b08 <log>
    80004572:	963e                	add	a2,a2,a5
    80004574:	44dc                	lw	a5,12(s1)
    80004576:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004578:	8526                	mv	a0,s1
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	dbc080e7          	jalr	-580(ra) # 80003336 <bpin>
    log.lh.n++;
    80004582:	0001d717          	auipc	a4,0x1d
    80004586:	58670713          	addi	a4,a4,1414 # 80021b08 <log>
    8000458a:	575c                	lw	a5,44(a4)
    8000458c:	2785                	addiw	a5,a5,1
    8000458e:	d75c                	sw	a5,44(a4)
    80004590:	a83d                	j	800045ce <log_write+0xd2>
    panic("too big a transaction");
    80004592:	00004517          	auipc	a0,0x4
    80004596:	0e650513          	addi	a0,a0,230 # 80008678 <syscalls+0x1f0>
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	fae080e7          	jalr	-82(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800045a2:	00004517          	auipc	a0,0x4
    800045a6:	0ee50513          	addi	a0,a0,238 # 80008690 <syscalls+0x208>
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	f9e080e7          	jalr	-98(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045b2:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045b4:	00878713          	addi	a4,a5,8
    800045b8:	00271693          	slli	a3,a4,0x2
    800045bc:	0001d717          	auipc	a4,0x1d
    800045c0:	54c70713          	addi	a4,a4,1356 # 80021b08 <log>
    800045c4:	9736                	add	a4,a4,a3
    800045c6:	44d4                	lw	a3,12(s1)
    800045c8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045ca:	faf607e3          	beq	a2,a5,80004578 <log_write+0x7c>
  }
  release(&log.lock);
    800045ce:	0001d517          	auipc	a0,0x1d
    800045d2:	53a50513          	addi	a0,a0,1338 # 80021b08 <log>
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	6ee080e7          	jalr	1774(ra) # 80000cc4 <release>
}
    800045de:	60e2                	ld	ra,24(sp)
    800045e0:	6442                	ld	s0,16(sp)
    800045e2:	64a2                	ld	s1,8(sp)
    800045e4:	6902                	ld	s2,0(sp)
    800045e6:	6105                	addi	sp,sp,32
    800045e8:	8082                	ret

00000000800045ea <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045ea:	1101                	addi	sp,sp,-32
    800045ec:	ec06                	sd	ra,24(sp)
    800045ee:	e822                	sd	s0,16(sp)
    800045f0:	e426                	sd	s1,8(sp)
    800045f2:	e04a                	sd	s2,0(sp)
    800045f4:	1000                	addi	s0,sp,32
    800045f6:	84aa                	mv	s1,a0
    800045f8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045fa:	00004597          	auipc	a1,0x4
    800045fe:	0b658593          	addi	a1,a1,182 # 800086b0 <syscalls+0x228>
    80004602:	0521                	addi	a0,a0,8
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	57c080e7          	jalr	1404(ra) # 80000b80 <initlock>
  lk->name = name;
    8000460c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004610:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004614:	0204a423          	sw	zero,40(s1)
}
    80004618:	60e2                	ld	ra,24(sp)
    8000461a:	6442                	ld	s0,16(sp)
    8000461c:	64a2                	ld	s1,8(sp)
    8000461e:	6902                	ld	s2,0(sp)
    80004620:	6105                	addi	sp,sp,32
    80004622:	8082                	ret

0000000080004624 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004624:	1101                	addi	sp,sp,-32
    80004626:	ec06                	sd	ra,24(sp)
    80004628:	e822                	sd	s0,16(sp)
    8000462a:	e426                	sd	s1,8(sp)
    8000462c:	e04a                	sd	s2,0(sp)
    8000462e:	1000                	addi	s0,sp,32
    80004630:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004632:	00850913          	addi	s2,a0,8
    80004636:	854a                	mv	a0,s2
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	5d8080e7          	jalr	1496(ra) # 80000c10 <acquire>
  while (lk->locked) {
    80004640:	409c                	lw	a5,0(s1)
    80004642:	cb89                	beqz	a5,80004654 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004644:	85ca                	mv	a1,s2
    80004646:	8526                	mv	a0,s1
    80004648:	ffffe097          	auipc	ra,0xffffe
    8000464c:	aa4080e7          	jalr	-1372(ra) # 800020ec <sleep>
  while (lk->locked) {
    80004650:	409c                	lw	a5,0(s1)
    80004652:	fbed                	bnez	a5,80004644 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004654:	4785                	li	a5,1
    80004656:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004658:	ffffd097          	auipc	ra,0xffffd
    8000465c:	510080e7          	jalr	1296(ra) # 80001b68 <myproc>
    80004660:	5d1c                	lw	a5,56(a0)
    80004662:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004664:	854a                	mv	a0,s2
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	65e080e7          	jalr	1630(ra) # 80000cc4 <release>
}
    8000466e:	60e2                	ld	ra,24(sp)
    80004670:	6442                	ld	s0,16(sp)
    80004672:	64a2                	ld	s1,8(sp)
    80004674:	6902                	ld	s2,0(sp)
    80004676:	6105                	addi	sp,sp,32
    80004678:	8082                	ret

000000008000467a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000467a:	1101                	addi	sp,sp,-32
    8000467c:	ec06                	sd	ra,24(sp)
    8000467e:	e822                	sd	s0,16(sp)
    80004680:	e426                	sd	s1,8(sp)
    80004682:	e04a                	sd	s2,0(sp)
    80004684:	1000                	addi	s0,sp,32
    80004686:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004688:	00850913          	addi	s2,a0,8
    8000468c:	854a                	mv	a0,s2
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	582080e7          	jalr	1410(ra) # 80000c10 <acquire>
  lk->locked = 0;
    80004696:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000469a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000469e:	8526                	mv	a0,s1
    800046a0:	ffffe097          	auipc	ra,0xffffe
    800046a4:	aca080e7          	jalr	-1334(ra) # 8000216a <wakeup>
  release(&lk->lk);
    800046a8:	854a                	mv	a0,s2
    800046aa:	ffffc097          	auipc	ra,0xffffc
    800046ae:	61a080e7          	jalr	1562(ra) # 80000cc4 <release>
}
    800046b2:	60e2                	ld	ra,24(sp)
    800046b4:	6442                	ld	s0,16(sp)
    800046b6:	64a2                	ld	s1,8(sp)
    800046b8:	6902                	ld	s2,0(sp)
    800046ba:	6105                	addi	sp,sp,32
    800046bc:	8082                	ret

00000000800046be <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046be:	7179                	addi	sp,sp,-48
    800046c0:	f406                	sd	ra,40(sp)
    800046c2:	f022                	sd	s0,32(sp)
    800046c4:	ec26                	sd	s1,24(sp)
    800046c6:	e84a                	sd	s2,16(sp)
    800046c8:	e44e                	sd	s3,8(sp)
    800046ca:	1800                	addi	s0,sp,48
    800046cc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046ce:	00850913          	addi	s2,a0,8
    800046d2:	854a                	mv	a0,s2
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	53c080e7          	jalr	1340(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046dc:	409c                	lw	a5,0(s1)
    800046de:	ef99                	bnez	a5,800046fc <holdingsleep+0x3e>
    800046e0:	4481                	li	s1,0
  release(&lk->lk);
    800046e2:	854a                	mv	a0,s2
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	5e0080e7          	jalr	1504(ra) # 80000cc4 <release>
  return r;
}
    800046ec:	8526                	mv	a0,s1
    800046ee:	70a2                	ld	ra,40(sp)
    800046f0:	7402                	ld	s0,32(sp)
    800046f2:	64e2                	ld	s1,24(sp)
    800046f4:	6942                	ld	s2,16(sp)
    800046f6:	69a2                	ld	s3,8(sp)
    800046f8:	6145                	addi	sp,sp,48
    800046fa:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046fc:	0284a983          	lw	s3,40(s1)
    80004700:	ffffd097          	auipc	ra,0xffffd
    80004704:	468080e7          	jalr	1128(ra) # 80001b68 <myproc>
    80004708:	5d04                	lw	s1,56(a0)
    8000470a:	413484b3          	sub	s1,s1,s3
    8000470e:	0014b493          	seqz	s1,s1
    80004712:	bfc1                	j	800046e2 <holdingsleep+0x24>

0000000080004714 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004714:	1141                	addi	sp,sp,-16
    80004716:	e406                	sd	ra,8(sp)
    80004718:	e022                	sd	s0,0(sp)
    8000471a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000471c:	00004597          	auipc	a1,0x4
    80004720:	fa458593          	addi	a1,a1,-92 # 800086c0 <syscalls+0x238>
    80004724:	0001d517          	auipc	a0,0x1d
    80004728:	52c50513          	addi	a0,a0,1324 # 80021c50 <ftable>
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	454080e7          	jalr	1108(ra) # 80000b80 <initlock>
}
    80004734:	60a2                	ld	ra,8(sp)
    80004736:	6402                	ld	s0,0(sp)
    80004738:	0141                	addi	sp,sp,16
    8000473a:	8082                	ret

000000008000473c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000473c:	1101                	addi	sp,sp,-32
    8000473e:	ec06                	sd	ra,24(sp)
    80004740:	e822                	sd	s0,16(sp)
    80004742:	e426                	sd	s1,8(sp)
    80004744:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004746:	0001d517          	auipc	a0,0x1d
    8000474a:	50a50513          	addi	a0,a0,1290 # 80021c50 <ftable>
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	4c2080e7          	jalr	1218(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004756:	0001d497          	auipc	s1,0x1d
    8000475a:	51248493          	addi	s1,s1,1298 # 80021c68 <ftable+0x18>
    8000475e:	0001e717          	auipc	a4,0x1e
    80004762:	4aa70713          	addi	a4,a4,1194 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    80004766:	40dc                	lw	a5,4(s1)
    80004768:	cf99                	beqz	a5,80004786 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000476a:	02848493          	addi	s1,s1,40
    8000476e:	fee49ce3          	bne	s1,a4,80004766 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004772:	0001d517          	auipc	a0,0x1d
    80004776:	4de50513          	addi	a0,a0,1246 # 80021c50 <ftable>
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	54a080e7          	jalr	1354(ra) # 80000cc4 <release>
  return 0;
    80004782:	4481                	li	s1,0
    80004784:	a819                	j	8000479a <filealloc+0x5e>
      f->ref = 1;
    80004786:	4785                	li	a5,1
    80004788:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000478a:	0001d517          	auipc	a0,0x1d
    8000478e:	4c650513          	addi	a0,a0,1222 # 80021c50 <ftable>
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	532080e7          	jalr	1330(ra) # 80000cc4 <release>
}
    8000479a:	8526                	mv	a0,s1
    8000479c:	60e2                	ld	ra,24(sp)
    8000479e:	6442                	ld	s0,16(sp)
    800047a0:	64a2                	ld	s1,8(sp)
    800047a2:	6105                	addi	sp,sp,32
    800047a4:	8082                	ret

00000000800047a6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047a6:	1101                	addi	sp,sp,-32
    800047a8:	ec06                	sd	ra,24(sp)
    800047aa:	e822                	sd	s0,16(sp)
    800047ac:	e426                	sd	s1,8(sp)
    800047ae:	1000                	addi	s0,sp,32
    800047b0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047b2:	0001d517          	auipc	a0,0x1d
    800047b6:	49e50513          	addi	a0,a0,1182 # 80021c50 <ftable>
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	456080e7          	jalr	1110(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800047c2:	40dc                	lw	a5,4(s1)
    800047c4:	02f05263          	blez	a5,800047e8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047c8:	2785                	addiw	a5,a5,1
    800047ca:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047cc:	0001d517          	auipc	a0,0x1d
    800047d0:	48450513          	addi	a0,a0,1156 # 80021c50 <ftable>
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	4f0080e7          	jalr	1264(ra) # 80000cc4 <release>
  return f;
}
    800047dc:	8526                	mv	a0,s1
    800047de:	60e2                	ld	ra,24(sp)
    800047e0:	6442                	ld	s0,16(sp)
    800047e2:	64a2                	ld	s1,8(sp)
    800047e4:	6105                	addi	sp,sp,32
    800047e6:	8082                	ret
    panic("filedup");
    800047e8:	00004517          	auipc	a0,0x4
    800047ec:	ee050513          	addi	a0,a0,-288 # 800086c8 <syscalls+0x240>
    800047f0:	ffffc097          	auipc	ra,0xffffc
    800047f4:	d58080e7          	jalr	-680(ra) # 80000548 <panic>

00000000800047f8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047f8:	7139                	addi	sp,sp,-64
    800047fa:	fc06                	sd	ra,56(sp)
    800047fc:	f822                	sd	s0,48(sp)
    800047fe:	f426                	sd	s1,40(sp)
    80004800:	f04a                	sd	s2,32(sp)
    80004802:	ec4e                	sd	s3,24(sp)
    80004804:	e852                	sd	s4,16(sp)
    80004806:	e456                	sd	s5,8(sp)
    80004808:	0080                	addi	s0,sp,64
    8000480a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000480c:	0001d517          	auipc	a0,0x1d
    80004810:	44450513          	addi	a0,a0,1092 # 80021c50 <ftable>
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	3fc080e7          	jalr	1020(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    8000481c:	40dc                	lw	a5,4(s1)
    8000481e:	06f05163          	blez	a5,80004880 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004822:	37fd                	addiw	a5,a5,-1
    80004824:	0007871b          	sext.w	a4,a5
    80004828:	c0dc                	sw	a5,4(s1)
    8000482a:	06e04363          	bgtz	a4,80004890 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000482e:	0004a903          	lw	s2,0(s1)
    80004832:	0094ca83          	lbu	s5,9(s1)
    80004836:	0104ba03          	ld	s4,16(s1)
    8000483a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000483e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004842:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004846:	0001d517          	auipc	a0,0x1d
    8000484a:	40a50513          	addi	a0,a0,1034 # 80021c50 <ftable>
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	476080e7          	jalr	1142(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    80004856:	4785                	li	a5,1
    80004858:	04f90d63          	beq	s2,a5,800048b2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000485c:	3979                	addiw	s2,s2,-2
    8000485e:	4785                	li	a5,1
    80004860:	0527e063          	bltu	a5,s2,800048a0 <fileclose+0xa8>
    begin_op();
    80004864:	00000097          	auipc	ra,0x0
    80004868:	ac2080e7          	jalr	-1342(ra) # 80004326 <begin_op>
    iput(ff.ip);
    8000486c:	854e                	mv	a0,s3
    8000486e:	fffff097          	auipc	ra,0xfffff
    80004872:	2b6080e7          	jalr	694(ra) # 80003b24 <iput>
    end_op();
    80004876:	00000097          	auipc	ra,0x0
    8000487a:	b30080e7          	jalr	-1232(ra) # 800043a6 <end_op>
    8000487e:	a00d                	j	800048a0 <fileclose+0xa8>
    panic("fileclose");
    80004880:	00004517          	auipc	a0,0x4
    80004884:	e5050513          	addi	a0,a0,-432 # 800086d0 <syscalls+0x248>
    80004888:	ffffc097          	auipc	ra,0xffffc
    8000488c:	cc0080e7          	jalr	-832(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004890:	0001d517          	auipc	a0,0x1d
    80004894:	3c050513          	addi	a0,a0,960 # 80021c50 <ftable>
    80004898:	ffffc097          	auipc	ra,0xffffc
    8000489c:	42c080e7          	jalr	1068(ra) # 80000cc4 <release>
  }
}
    800048a0:	70e2                	ld	ra,56(sp)
    800048a2:	7442                	ld	s0,48(sp)
    800048a4:	74a2                	ld	s1,40(sp)
    800048a6:	7902                	ld	s2,32(sp)
    800048a8:	69e2                	ld	s3,24(sp)
    800048aa:	6a42                	ld	s4,16(sp)
    800048ac:	6aa2                	ld	s5,8(sp)
    800048ae:	6121                	addi	sp,sp,64
    800048b0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048b2:	85d6                	mv	a1,s5
    800048b4:	8552                	mv	a0,s4
    800048b6:	00000097          	auipc	ra,0x0
    800048ba:	372080e7          	jalr	882(ra) # 80004c28 <pipeclose>
    800048be:	b7cd                	j	800048a0 <fileclose+0xa8>

00000000800048c0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048c0:	715d                	addi	sp,sp,-80
    800048c2:	e486                	sd	ra,72(sp)
    800048c4:	e0a2                	sd	s0,64(sp)
    800048c6:	fc26                	sd	s1,56(sp)
    800048c8:	f84a                	sd	s2,48(sp)
    800048ca:	f44e                	sd	s3,40(sp)
    800048cc:	0880                	addi	s0,sp,80
    800048ce:	84aa                	mv	s1,a0
    800048d0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048d2:	ffffd097          	auipc	ra,0xffffd
    800048d6:	296080e7          	jalr	662(ra) # 80001b68 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048da:	409c                	lw	a5,0(s1)
    800048dc:	37f9                	addiw	a5,a5,-2
    800048de:	4705                	li	a4,1
    800048e0:	04f76763          	bltu	a4,a5,8000492e <filestat+0x6e>
    800048e4:	892a                	mv	s2,a0
    ilock(f->ip);
    800048e6:	6c88                	ld	a0,24(s1)
    800048e8:	fffff097          	auipc	ra,0xfffff
    800048ec:	082080e7          	jalr	130(ra) # 8000396a <ilock>
    stati(f->ip, &st);
    800048f0:	fb840593          	addi	a1,s0,-72
    800048f4:	6c88                	ld	a0,24(s1)
    800048f6:	fffff097          	auipc	ra,0xfffff
    800048fa:	2fe080e7          	jalr	766(ra) # 80003bf4 <stati>
    iunlock(f->ip);
    800048fe:	6c88                	ld	a0,24(s1)
    80004900:	fffff097          	auipc	ra,0xfffff
    80004904:	12c080e7          	jalr	300(ra) # 80003a2c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004908:	46e1                	li	a3,24
    8000490a:	fb840613          	addi	a2,s0,-72
    8000490e:	85ce                	mv	a1,s3
    80004910:	05093503          	ld	a0,80(s2)
    80004914:	ffffd097          	auipc	ra,0xffffd
    80004918:	dd0080e7          	jalr	-560(ra) # 800016e4 <copyout>
    8000491c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004920:	60a6                	ld	ra,72(sp)
    80004922:	6406                	ld	s0,64(sp)
    80004924:	74e2                	ld	s1,56(sp)
    80004926:	7942                	ld	s2,48(sp)
    80004928:	79a2                	ld	s3,40(sp)
    8000492a:	6161                	addi	sp,sp,80
    8000492c:	8082                	ret
  return -1;
    8000492e:	557d                	li	a0,-1
    80004930:	bfc5                	j	80004920 <filestat+0x60>

0000000080004932 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004932:	7179                	addi	sp,sp,-48
    80004934:	f406                	sd	ra,40(sp)
    80004936:	f022                	sd	s0,32(sp)
    80004938:	ec26                	sd	s1,24(sp)
    8000493a:	e84a                	sd	s2,16(sp)
    8000493c:	e44e                	sd	s3,8(sp)
    8000493e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004940:	00854783          	lbu	a5,8(a0)
    80004944:	c3d5                	beqz	a5,800049e8 <fileread+0xb6>
    80004946:	84aa                	mv	s1,a0
    80004948:	89ae                	mv	s3,a1
    8000494a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000494c:	411c                	lw	a5,0(a0)
    8000494e:	4705                	li	a4,1
    80004950:	04e78963          	beq	a5,a4,800049a2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004954:	470d                	li	a4,3
    80004956:	04e78d63          	beq	a5,a4,800049b0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000495a:	4709                	li	a4,2
    8000495c:	06e79e63          	bne	a5,a4,800049d8 <fileread+0xa6>
    ilock(f->ip);
    80004960:	6d08                	ld	a0,24(a0)
    80004962:	fffff097          	auipc	ra,0xfffff
    80004966:	008080e7          	jalr	8(ra) # 8000396a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000496a:	874a                	mv	a4,s2
    8000496c:	5094                	lw	a3,32(s1)
    8000496e:	864e                	mv	a2,s3
    80004970:	4585                	li	a1,1
    80004972:	6c88                	ld	a0,24(s1)
    80004974:	fffff097          	auipc	ra,0xfffff
    80004978:	2aa080e7          	jalr	682(ra) # 80003c1e <readi>
    8000497c:	892a                	mv	s2,a0
    8000497e:	00a05563          	blez	a0,80004988 <fileread+0x56>
      f->off += r;
    80004982:	509c                	lw	a5,32(s1)
    80004984:	9fa9                	addw	a5,a5,a0
    80004986:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004988:	6c88                	ld	a0,24(s1)
    8000498a:	fffff097          	auipc	ra,0xfffff
    8000498e:	0a2080e7          	jalr	162(ra) # 80003a2c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004992:	854a                	mv	a0,s2
    80004994:	70a2                	ld	ra,40(sp)
    80004996:	7402                	ld	s0,32(sp)
    80004998:	64e2                	ld	s1,24(sp)
    8000499a:	6942                	ld	s2,16(sp)
    8000499c:	69a2                	ld	s3,8(sp)
    8000499e:	6145                	addi	sp,sp,48
    800049a0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049a2:	6908                	ld	a0,16(a0)
    800049a4:	00000097          	auipc	ra,0x0
    800049a8:	418080e7          	jalr	1048(ra) # 80004dbc <piperead>
    800049ac:	892a                	mv	s2,a0
    800049ae:	b7d5                	j	80004992 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049b0:	02451783          	lh	a5,36(a0)
    800049b4:	03079693          	slli	a3,a5,0x30
    800049b8:	92c1                	srli	a3,a3,0x30
    800049ba:	4725                	li	a4,9
    800049bc:	02d76863          	bltu	a4,a3,800049ec <fileread+0xba>
    800049c0:	0792                	slli	a5,a5,0x4
    800049c2:	0001d717          	auipc	a4,0x1d
    800049c6:	1ee70713          	addi	a4,a4,494 # 80021bb0 <devsw>
    800049ca:	97ba                	add	a5,a5,a4
    800049cc:	639c                	ld	a5,0(a5)
    800049ce:	c38d                	beqz	a5,800049f0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049d0:	4505                	li	a0,1
    800049d2:	9782                	jalr	a5
    800049d4:	892a                	mv	s2,a0
    800049d6:	bf75                	j	80004992 <fileread+0x60>
    panic("fileread");
    800049d8:	00004517          	auipc	a0,0x4
    800049dc:	d0850513          	addi	a0,a0,-760 # 800086e0 <syscalls+0x258>
    800049e0:	ffffc097          	auipc	ra,0xffffc
    800049e4:	b68080e7          	jalr	-1176(ra) # 80000548 <panic>
    return -1;
    800049e8:	597d                	li	s2,-1
    800049ea:	b765                	j	80004992 <fileread+0x60>
      return -1;
    800049ec:	597d                	li	s2,-1
    800049ee:	b755                	j	80004992 <fileread+0x60>
    800049f0:	597d                	li	s2,-1
    800049f2:	b745                	j	80004992 <fileread+0x60>

00000000800049f4 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800049f4:	00954783          	lbu	a5,9(a0)
    800049f8:	14078563          	beqz	a5,80004b42 <filewrite+0x14e>
{
    800049fc:	715d                	addi	sp,sp,-80
    800049fe:	e486                	sd	ra,72(sp)
    80004a00:	e0a2                	sd	s0,64(sp)
    80004a02:	fc26                	sd	s1,56(sp)
    80004a04:	f84a                	sd	s2,48(sp)
    80004a06:	f44e                	sd	s3,40(sp)
    80004a08:	f052                	sd	s4,32(sp)
    80004a0a:	ec56                	sd	s5,24(sp)
    80004a0c:	e85a                	sd	s6,16(sp)
    80004a0e:	e45e                	sd	s7,8(sp)
    80004a10:	e062                	sd	s8,0(sp)
    80004a12:	0880                	addi	s0,sp,80
    80004a14:	892a                	mv	s2,a0
    80004a16:	8aae                	mv	s5,a1
    80004a18:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a1a:	411c                	lw	a5,0(a0)
    80004a1c:	4705                	li	a4,1
    80004a1e:	02e78263          	beq	a5,a4,80004a42 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a22:	470d                	li	a4,3
    80004a24:	02e78563          	beq	a5,a4,80004a4e <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a28:	4709                	li	a4,2
    80004a2a:	10e79463          	bne	a5,a4,80004b32 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a2e:	0ec05e63          	blez	a2,80004b2a <filewrite+0x136>
    int i = 0;
    80004a32:	4981                	li	s3,0
    80004a34:	6b05                	lui	s6,0x1
    80004a36:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a3a:	6b85                	lui	s7,0x1
    80004a3c:	c00b8b9b          	addiw	s7,s7,-1024
    80004a40:	a851                	j	80004ad4 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a42:	6908                	ld	a0,16(a0)
    80004a44:	00000097          	auipc	ra,0x0
    80004a48:	254080e7          	jalr	596(ra) # 80004c98 <pipewrite>
    80004a4c:	a85d                	j	80004b02 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a4e:	02451783          	lh	a5,36(a0)
    80004a52:	03079693          	slli	a3,a5,0x30
    80004a56:	92c1                	srli	a3,a3,0x30
    80004a58:	4725                	li	a4,9
    80004a5a:	0ed76663          	bltu	a4,a3,80004b46 <filewrite+0x152>
    80004a5e:	0792                	slli	a5,a5,0x4
    80004a60:	0001d717          	auipc	a4,0x1d
    80004a64:	15070713          	addi	a4,a4,336 # 80021bb0 <devsw>
    80004a68:	97ba                	add	a5,a5,a4
    80004a6a:	679c                	ld	a5,8(a5)
    80004a6c:	cff9                	beqz	a5,80004b4a <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a6e:	4505                	li	a0,1
    80004a70:	9782                	jalr	a5
    80004a72:	a841                	j	80004b02 <filewrite+0x10e>
    80004a74:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a78:	00000097          	auipc	ra,0x0
    80004a7c:	8ae080e7          	jalr	-1874(ra) # 80004326 <begin_op>
      ilock(f->ip);
    80004a80:	01893503          	ld	a0,24(s2)
    80004a84:	fffff097          	auipc	ra,0xfffff
    80004a88:	ee6080e7          	jalr	-282(ra) # 8000396a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a8c:	8762                	mv	a4,s8
    80004a8e:	02092683          	lw	a3,32(s2)
    80004a92:	01598633          	add	a2,s3,s5
    80004a96:	4585                	li	a1,1
    80004a98:	01893503          	ld	a0,24(s2)
    80004a9c:	fffff097          	auipc	ra,0xfffff
    80004aa0:	278080e7          	jalr	632(ra) # 80003d14 <writei>
    80004aa4:	84aa                	mv	s1,a0
    80004aa6:	02a05f63          	blez	a0,80004ae4 <filewrite+0xf0>
        f->off += r;
    80004aaa:	02092783          	lw	a5,32(s2)
    80004aae:	9fa9                	addw	a5,a5,a0
    80004ab0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ab4:	01893503          	ld	a0,24(s2)
    80004ab8:	fffff097          	auipc	ra,0xfffff
    80004abc:	f74080e7          	jalr	-140(ra) # 80003a2c <iunlock>
      end_op();
    80004ac0:	00000097          	auipc	ra,0x0
    80004ac4:	8e6080e7          	jalr	-1818(ra) # 800043a6 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004ac8:	049c1963          	bne	s8,s1,80004b1a <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004acc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ad0:	0349d663          	bge	s3,s4,80004afc <filewrite+0x108>
      int n1 = n - i;
    80004ad4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ad8:	84be                	mv	s1,a5
    80004ada:	2781                	sext.w	a5,a5
    80004adc:	f8fb5ce3          	bge	s6,a5,80004a74 <filewrite+0x80>
    80004ae0:	84de                	mv	s1,s7
    80004ae2:	bf49                	j	80004a74 <filewrite+0x80>
      iunlock(f->ip);
    80004ae4:	01893503          	ld	a0,24(s2)
    80004ae8:	fffff097          	auipc	ra,0xfffff
    80004aec:	f44080e7          	jalr	-188(ra) # 80003a2c <iunlock>
      end_op();
    80004af0:	00000097          	auipc	ra,0x0
    80004af4:	8b6080e7          	jalr	-1866(ra) # 800043a6 <end_op>
      if(r < 0)
    80004af8:	fc04d8e3          	bgez	s1,80004ac8 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004afc:	8552                	mv	a0,s4
    80004afe:	033a1863          	bne	s4,s3,80004b2e <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b02:	60a6                	ld	ra,72(sp)
    80004b04:	6406                	ld	s0,64(sp)
    80004b06:	74e2                	ld	s1,56(sp)
    80004b08:	7942                	ld	s2,48(sp)
    80004b0a:	79a2                	ld	s3,40(sp)
    80004b0c:	7a02                	ld	s4,32(sp)
    80004b0e:	6ae2                	ld	s5,24(sp)
    80004b10:	6b42                	ld	s6,16(sp)
    80004b12:	6ba2                	ld	s7,8(sp)
    80004b14:	6c02                	ld	s8,0(sp)
    80004b16:	6161                	addi	sp,sp,80
    80004b18:	8082                	ret
        panic("short filewrite");
    80004b1a:	00004517          	auipc	a0,0x4
    80004b1e:	bd650513          	addi	a0,a0,-1066 # 800086f0 <syscalls+0x268>
    80004b22:	ffffc097          	auipc	ra,0xffffc
    80004b26:	a26080e7          	jalr	-1498(ra) # 80000548 <panic>
    int i = 0;
    80004b2a:	4981                	li	s3,0
    80004b2c:	bfc1                	j	80004afc <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b2e:	557d                	li	a0,-1
    80004b30:	bfc9                	j	80004b02 <filewrite+0x10e>
    panic("filewrite");
    80004b32:	00004517          	auipc	a0,0x4
    80004b36:	bce50513          	addi	a0,a0,-1074 # 80008700 <syscalls+0x278>
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	a0e080e7          	jalr	-1522(ra) # 80000548 <panic>
    return -1;
    80004b42:	557d                	li	a0,-1
}
    80004b44:	8082                	ret
      return -1;
    80004b46:	557d                	li	a0,-1
    80004b48:	bf6d                	j	80004b02 <filewrite+0x10e>
    80004b4a:	557d                	li	a0,-1
    80004b4c:	bf5d                	j	80004b02 <filewrite+0x10e>

0000000080004b4e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b4e:	7179                	addi	sp,sp,-48
    80004b50:	f406                	sd	ra,40(sp)
    80004b52:	f022                	sd	s0,32(sp)
    80004b54:	ec26                	sd	s1,24(sp)
    80004b56:	e84a                	sd	s2,16(sp)
    80004b58:	e44e                	sd	s3,8(sp)
    80004b5a:	e052                	sd	s4,0(sp)
    80004b5c:	1800                	addi	s0,sp,48
    80004b5e:	84aa                	mv	s1,a0
    80004b60:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b62:	0005b023          	sd	zero,0(a1)
    80004b66:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b6a:	00000097          	auipc	ra,0x0
    80004b6e:	bd2080e7          	jalr	-1070(ra) # 8000473c <filealloc>
    80004b72:	e088                	sd	a0,0(s1)
    80004b74:	c551                	beqz	a0,80004c00 <pipealloc+0xb2>
    80004b76:	00000097          	auipc	ra,0x0
    80004b7a:	bc6080e7          	jalr	-1082(ra) # 8000473c <filealloc>
    80004b7e:	00aa3023          	sd	a0,0(s4)
    80004b82:	c92d                	beqz	a0,80004bf4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	f9c080e7          	jalr	-100(ra) # 80000b20 <kalloc>
    80004b8c:	892a                	mv	s2,a0
    80004b8e:	c125                	beqz	a0,80004bee <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b90:	4985                	li	s3,1
    80004b92:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b96:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b9a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b9e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ba2:	00004597          	auipc	a1,0x4
    80004ba6:	b6e58593          	addi	a1,a1,-1170 # 80008710 <syscalls+0x288>
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	fd6080e7          	jalr	-42(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004bb2:	609c                	ld	a5,0(s1)
    80004bb4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bb8:	609c                	ld	a5,0(s1)
    80004bba:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bbe:	609c                	ld	a5,0(s1)
    80004bc0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bc4:	609c                	ld	a5,0(s1)
    80004bc6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bca:	000a3783          	ld	a5,0(s4)
    80004bce:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bd2:	000a3783          	ld	a5,0(s4)
    80004bd6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bda:	000a3783          	ld	a5,0(s4)
    80004bde:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004be2:	000a3783          	ld	a5,0(s4)
    80004be6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bea:	4501                	li	a0,0
    80004bec:	a025                	j	80004c14 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bee:	6088                	ld	a0,0(s1)
    80004bf0:	e501                	bnez	a0,80004bf8 <pipealloc+0xaa>
    80004bf2:	a039                	j	80004c00 <pipealloc+0xb2>
    80004bf4:	6088                	ld	a0,0(s1)
    80004bf6:	c51d                	beqz	a0,80004c24 <pipealloc+0xd6>
    fileclose(*f0);
    80004bf8:	00000097          	auipc	ra,0x0
    80004bfc:	c00080e7          	jalr	-1024(ra) # 800047f8 <fileclose>
  if(*f1)
    80004c00:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c04:	557d                	li	a0,-1
  if(*f1)
    80004c06:	c799                	beqz	a5,80004c14 <pipealloc+0xc6>
    fileclose(*f1);
    80004c08:	853e                	mv	a0,a5
    80004c0a:	00000097          	auipc	ra,0x0
    80004c0e:	bee080e7          	jalr	-1042(ra) # 800047f8 <fileclose>
  return -1;
    80004c12:	557d                	li	a0,-1
}
    80004c14:	70a2                	ld	ra,40(sp)
    80004c16:	7402                	ld	s0,32(sp)
    80004c18:	64e2                	ld	s1,24(sp)
    80004c1a:	6942                	ld	s2,16(sp)
    80004c1c:	69a2                	ld	s3,8(sp)
    80004c1e:	6a02                	ld	s4,0(sp)
    80004c20:	6145                	addi	sp,sp,48
    80004c22:	8082                	ret
  return -1;
    80004c24:	557d                	li	a0,-1
    80004c26:	b7fd                	j	80004c14 <pipealloc+0xc6>

0000000080004c28 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c28:	1101                	addi	sp,sp,-32
    80004c2a:	ec06                	sd	ra,24(sp)
    80004c2c:	e822                	sd	s0,16(sp)
    80004c2e:	e426                	sd	s1,8(sp)
    80004c30:	e04a                	sd	s2,0(sp)
    80004c32:	1000                	addi	s0,sp,32
    80004c34:	84aa                	mv	s1,a0
    80004c36:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	fd8080e7          	jalr	-40(ra) # 80000c10 <acquire>
  if(writable){
    80004c40:	02090d63          	beqz	s2,80004c7a <pipeclose+0x52>
    pi->writeopen = 0;
    80004c44:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c48:	21848513          	addi	a0,s1,536
    80004c4c:	ffffd097          	auipc	ra,0xffffd
    80004c50:	51e080e7          	jalr	1310(ra) # 8000216a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c54:	2204b783          	ld	a5,544(s1)
    80004c58:	eb95                	bnez	a5,80004c8c <pipeclose+0x64>
    release(&pi->lock);
    80004c5a:	8526                	mv	a0,s1
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	068080e7          	jalr	104(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004c64:	8526                	mv	a0,s1
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	dbe080e7          	jalr	-578(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004c6e:	60e2                	ld	ra,24(sp)
    80004c70:	6442                	ld	s0,16(sp)
    80004c72:	64a2                	ld	s1,8(sp)
    80004c74:	6902                	ld	s2,0(sp)
    80004c76:	6105                	addi	sp,sp,32
    80004c78:	8082                	ret
    pi->readopen = 0;
    80004c7a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c7e:	21c48513          	addi	a0,s1,540
    80004c82:	ffffd097          	auipc	ra,0xffffd
    80004c86:	4e8080e7          	jalr	1256(ra) # 8000216a <wakeup>
    80004c8a:	b7e9                	j	80004c54 <pipeclose+0x2c>
    release(&pi->lock);
    80004c8c:	8526                	mv	a0,s1
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	036080e7          	jalr	54(ra) # 80000cc4 <release>
}
    80004c96:	bfe1                	j	80004c6e <pipeclose+0x46>

0000000080004c98 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c98:	7119                	addi	sp,sp,-128
    80004c9a:	fc86                	sd	ra,120(sp)
    80004c9c:	f8a2                	sd	s0,112(sp)
    80004c9e:	f4a6                	sd	s1,104(sp)
    80004ca0:	f0ca                	sd	s2,96(sp)
    80004ca2:	ecce                	sd	s3,88(sp)
    80004ca4:	e8d2                	sd	s4,80(sp)
    80004ca6:	e4d6                	sd	s5,72(sp)
    80004ca8:	e0da                	sd	s6,64(sp)
    80004caa:	fc5e                	sd	s7,56(sp)
    80004cac:	f862                	sd	s8,48(sp)
    80004cae:	f466                	sd	s9,40(sp)
    80004cb0:	f06a                	sd	s10,32(sp)
    80004cb2:	ec6e                	sd	s11,24(sp)
    80004cb4:	0100                	addi	s0,sp,128
    80004cb6:	84aa                	mv	s1,a0
    80004cb8:	8cae                	mv	s9,a1
    80004cba:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004cbc:	ffffd097          	auipc	ra,0xffffd
    80004cc0:	eac080e7          	jalr	-340(ra) # 80001b68 <myproc>
    80004cc4:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004cc6:	8526                	mv	a0,s1
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	f48080e7          	jalr	-184(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004cd0:	0d605963          	blez	s6,80004da2 <pipewrite+0x10a>
    80004cd4:	89a6                	mv	s3,s1
    80004cd6:	3b7d                	addiw	s6,s6,-1
    80004cd8:	1b02                	slli	s6,s6,0x20
    80004cda:	020b5b13          	srli	s6,s6,0x20
    80004cde:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ce0:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ce4:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ce8:	5dfd                	li	s11,-1
    80004cea:	000b8d1b          	sext.w	s10,s7
    80004cee:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cf0:	2184a783          	lw	a5,536(s1)
    80004cf4:	21c4a703          	lw	a4,540(s1)
    80004cf8:	2007879b          	addiw	a5,a5,512
    80004cfc:	02f71b63          	bne	a4,a5,80004d32 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004d00:	2204a783          	lw	a5,544(s1)
    80004d04:	cbad                	beqz	a5,80004d76 <pipewrite+0xde>
    80004d06:	03092783          	lw	a5,48(s2)
    80004d0a:	e7b5                	bnez	a5,80004d76 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004d0c:	8556                	mv	a0,s5
    80004d0e:	ffffd097          	auipc	ra,0xffffd
    80004d12:	45c080e7          	jalr	1116(ra) # 8000216a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d16:	85ce                	mv	a1,s3
    80004d18:	8552                	mv	a0,s4
    80004d1a:	ffffd097          	auipc	ra,0xffffd
    80004d1e:	3d2080e7          	jalr	978(ra) # 800020ec <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d22:	2184a783          	lw	a5,536(s1)
    80004d26:	21c4a703          	lw	a4,540(s1)
    80004d2a:	2007879b          	addiw	a5,a5,512
    80004d2e:	fcf709e3          	beq	a4,a5,80004d00 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d32:	4685                	li	a3,1
    80004d34:	019b8633          	add	a2,s7,s9
    80004d38:	f8f40593          	addi	a1,s0,-113
    80004d3c:	05093503          	ld	a0,80(s2)
    80004d40:	ffffd097          	auipc	ra,0xffffd
    80004d44:	a30080e7          	jalr	-1488(ra) # 80001770 <copyin>
    80004d48:	05b50e63          	beq	a0,s11,80004da4 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d4c:	21c4a783          	lw	a5,540(s1)
    80004d50:	0017871b          	addiw	a4,a5,1
    80004d54:	20e4ae23          	sw	a4,540(s1)
    80004d58:	1ff7f793          	andi	a5,a5,511
    80004d5c:	97a6                	add	a5,a5,s1
    80004d5e:	f8f44703          	lbu	a4,-113(s0)
    80004d62:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d66:	001d0c1b          	addiw	s8,s10,1
    80004d6a:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004d6e:	036b8b63          	beq	s7,s6,80004da4 <pipewrite+0x10c>
    80004d72:	8bbe                	mv	s7,a5
    80004d74:	bf9d                	j	80004cea <pipewrite+0x52>
        release(&pi->lock);
    80004d76:	8526                	mv	a0,s1
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	f4c080e7          	jalr	-180(ra) # 80000cc4 <release>
        return -1;
    80004d80:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004d82:	8562                	mv	a0,s8
    80004d84:	70e6                	ld	ra,120(sp)
    80004d86:	7446                	ld	s0,112(sp)
    80004d88:	74a6                	ld	s1,104(sp)
    80004d8a:	7906                	ld	s2,96(sp)
    80004d8c:	69e6                	ld	s3,88(sp)
    80004d8e:	6a46                	ld	s4,80(sp)
    80004d90:	6aa6                	ld	s5,72(sp)
    80004d92:	6b06                	ld	s6,64(sp)
    80004d94:	7be2                	ld	s7,56(sp)
    80004d96:	7c42                	ld	s8,48(sp)
    80004d98:	7ca2                	ld	s9,40(sp)
    80004d9a:	7d02                	ld	s10,32(sp)
    80004d9c:	6de2                	ld	s11,24(sp)
    80004d9e:	6109                	addi	sp,sp,128
    80004da0:	8082                	ret
  for(i = 0; i < n; i++){
    80004da2:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004da4:	21848513          	addi	a0,s1,536
    80004da8:	ffffd097          	auipc	ra,0xffffd
    80004dac:	3c2080e7          	jalr	962(ra) # 8000216a <wakeup>
  release(&pi->lock);
    80004db0:	8526                	mv	a0,s1
    80004db2:	ffffc097          	auipc	ra,0xffffc
    80004db6:	f12080e7          	jalr	-238(ra) # 80000cc4 <release>
  return i;
    80004dba:	b7e1                	j	80004d82 <pipewrite+0xea>

0000000080004dbc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dbc:	715d                	addi	sp,sp,-80
    80004dbe:	e486                	sd	ra,72(sp)
    80004dc0:	e0a2                	sd	s0,64(sp)
    80004dc2:	fc26                	sd	s1,56(sp)
    80004dc4:	f84a                	sd	s2,48(sp)
    80004dc6:	f44e                	sd	s3,40(sp)
    80004dc8:	f052                	sd	s4,32(sp)
    80004dca:	ec56                	sd	s5,24(sp)
    80004dcc:	e85a                	sd	s6,16(sp)
    80004dce:	0880                	addi	s0,sp,80
    80004dd0:	84aa                	mv	s1,a0
    80004dd2:	892e                	mv	s2,a1
    80004dd4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dd6:	ffffd097          	auipc	ra,0xffffd
    80004dda:	d92080e7          	jalr	-622(ra) # 80001b68 <myproc>
    80004dde:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004de0:	8b26                	mv	s6,s1
    80004de2:	8526                	mv	a0,s1
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	e2c080e7          	jalr	-468(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dec:	2184a703          	lw	a4,536(s1)
    80004df0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004df4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004df8:	02f71463          	bne	a4,a5,80004e20 <piperead+0x64>
    80004dfc:	2244a783          	lw	a5,548(s1)
    80004e00:	c385                	beqz	a5,80004e20 <piperead+0x64>
    if(pr->killed){
    80004e02:	030a2783          	lw	a5,48(s4)
    80004e06:	ebc1                	bnez	a5,80004e96 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e08:	85da                	mv	a1,s6
    80004e0a:	854e                	mv	a0,s3
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	2e0080e7          	jalr	736(ra) # 800020ec <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e14:	2184a703          	lw	a4,536(s1)
    80004e18:	21c4a783          	lw	a5,540(s1)
    80004e1c:	fef700e3          	beq	a4,a5,80004dfc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e20:	09505263          	blez	s5,80004ea4 <piperead+0xe8>
    80004e24:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e26:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e28:	2184a783          	lw	a5,536(s1)
    80004e2c:	21c4a703          	lw	a4,540(s1)
    80004e30:	02f70d63          	beq	a4,a5,80004e6a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e34:	0017871b          	addiw	a4,a5,1
    80004e38:	20e4ac23          	sw	a4,536(s1)
    80004e3c:	1ff7f793          	andi	a5,a5,511
    80004e40:	97a6                	add	a5,a5,s1
    80004e42:	0187c783          	lbu	a5,24(a5)
    80004e46:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e4a:	4685                	li	a3,1
    80004e4c:	fbf40613          	addi	a2,s0,-65
    80004e50:	85ca                	mv	a1,s2
    80004e52:	050a3503          	ld	a0,80(s4)
    80004e56:	ffffd097          	auipc	ra,0xffffd
    80004e5a:	88e080e7          	jalr	-1906(ra) # 800016e4 <copyout>
    80004e5e:	01650663          	beq	a0,s6,80004e6a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e62:	2985                	addiw	s3,s3,1
    80004e64:	0905                	addi	s2,s2,1
    80004e66:	fd3a91e3          	bne	s5,s3,80004e28 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e6a:	21c48513          	addi	a0,s1,540
    80004e6e:	ffffd097          	auipc	ra,0xffffd
    80004e72:	2fc080e7          	jalr	764(ra) # 8000216a <wakeup>
  release(&pi->lock);
    80004e76:	8526                	mv	a0,s1
    80004e78:	ffffc097          	auipc	ra,0xffffc
    80004e7c:	e4c080e7          	jalr	-436(ra) # 80000cc4 <release>
  return i;
}
    80004e80:	854e                	mv	a0,s3
    80004e82:	60a6                	ld	ra,72(sp)
    80004e84:	6406                	ld	s0,64(sp)
    80004e86:	74e2                	ld	s1,56(sp)
    80004e88:	7942                	ld	s2,48(sp)
    80004e8a:	79a2                	ld	s3,40(sp)
    80004e8c:	7a02                	ld	s4,32(sp)
    80004e8e:	6ae2                	ld	s5,24(sp)
    80004e90:	6b42                	ld	s6,16(sp)
    80004e92:	6161                	addi	sp,sp,80
    80004e94:	8082                	ret
      release(&pi->lock);
    80004e96:	8526                	mv	a0,s1
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	e2c080e7          	jalr	-468(ra) # 80000cc4 <release>
      return -1;
    80004ea0:	59fd                	li	s3,-1
    80004ea2:	bff9                	j	80004e80 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ea4:	4981                	li	s3,0
    80004ea6:	b7d1                	j	80004e6a <piperead+0xae>

0000000080004ea8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ea8:	df010113          	addi	sp,sp,-528
    80004eac:	20113423          	sd	ra,520(sp)
    80004eb0:	20813023          	sd	s0,512(sp)
    80004eb4:	ffa6                	sd	s1,504(sp)
    80004eb6:	fbca                	sd	s2,496(sp)
    80004eb8:	f7ce                	sd	s3,488(sp)
    80004eba:	f3d2                	sd	s4,480(sp)
    80004ebc:	efd6                	sd	s5,472(sp)
    80004ebe:	ebda                	sd	s6,464(sp)
    80004ec0:	e7de                	sd	s7,456(sp)
    80004ec2:	e3e2                	sd	s8,448(sp)
    80004ec4:	ff66                	sd	s9,440(sp)
    80004ec6:	fb6a                	sd	s10,432(sp)
    80004ec8:	f76e                	sd	s11,424(sp)
    80004eca:	0c00                	addi	s0,sp,528
    80004ecc:	84aa                	mv	s1,a0
    80004ece:	dea43c23          	sd	a0,-520(s0)
    80004ed2:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ed6:	ffffd097          	auipc	ra,0xffffd
    80004eda:	c92080e7          	jalr	-878(ra) # 80001b68 <myproc>
    80004ede:	892a                	mv	s2,a0

  begin_op();
    80004ee0:	fffff097          	auipc	ra,0xfffff
    80004ee4:	446080e7          	jalr	1094(ra) # 80004326 <begin_op>

  if((ip = namei(path)) == 0){
    80004ee8:	8526                	mv	a0,s1
    80004eea:	fffff097          	auipc	ra,0xfffff
    80004eee:	230080e7          	jalr	560(ra) # 8000411a <namei>
    80004ef2:	c92d                	beqz	a0,80004f64 <exec+0xbc>
    80004ef4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ef6:	fffff097          	auipc	ra,0xfffff
    80004efa:	a74080e7          	jalr	-1420(ra) # 8000396a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004efe:	04000713          	li	a4,64
    80004f02:	4681                	li	a3,0
    80004f04:	e4840613          	addi	a2,s0,-440
    80004f08:	4581                	li	a1,0
    80004f0a:	8526                	mv	a0,s1
    80004f0c:	fffff097          	auipc	ra,0xfffff
    80004f10:	d12080e7          	jalr	-750(ra) # 80003c1e <readi>
    80004f14:	04000793          	li	a5,64
    80004f18:	00f51a63          	bne	a0,a5,80004f2c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f1c:	e4842703          	lw	a4,-440(s0)
    80004f20:	464c47b7          	lui	a5,0x464c4
    80004f24:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f28:	04f70463          	beq	a4,a5,80004f70 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f2c:	8526                	mv	a0,s1
    80004f2e:	fffff097          	auipc	ra,0xfffff
    80004f32:	c9e080e7          	jalr	-866(ra) # 80003bcc <iunlockput>
    end_op();
    80004f36:	fffff097          	auipc	ra,0xfffff
    80004f3a:	470080e7          	jalr	1136(ra) # 800043a6 <end_op>
  }
  return -1;
    80004f3e:	557d                	li	a0,-1
}
    80004f40:	20813083          	ld	ra,520(sp)
    80004f44:	20013403          	ld	s0,512(sp)
    80004f48:	74fe                	ld	s1,504(sp)
    80004f4a:	795e                	ld	s2,496(sp)
    80004f4c:	79be                	ld	s3,488(sp)
    80004f4e:	7a1e                	ld	s4,480(sp)
    80004f50:	6afe                	ld	s5,472(sp)
    80004f52:	6b5e                	ld	s6,464(sp)
    80004f54:	6bbe                	ld	s7,456(sp)
    80004f56:	6c1e                	ld	s8,448(sp)
    80004f58:	7cfa                	ld	s9,440(sp)
    80004f5a:	7d5a                	ld	s10,432(sp)
    80004f5c:	7dba                	ld	s11,424(sp)
    80004f5e:	21010113          	addi	sp,sp,528
    80004f62:	8082                	ret
    end_op();
    80004f64:	fffff097          	auipc	ra,0xfffff
    80004f68:	442080e7          	jalr	1090(ra) # 800043a6 <end_op>
    return -1;
    80004f6c:	557d                	li	a0,-1
    80004f6e:	bfc9                	j	80004f40 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f70:	854a                	mv	a0,s2
    80004f72:	ffffd097          	auipc	ra,0xffffd
    80004f76:	cba080e7          	jalr	-838(ra) # 80001c2c <proc_pagetable>
    80004f7a:	e0a43423          	sd	a0,-504(s0)
    80004f7e:	d55d                	beqz	a0,80004f2c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f80:	e6842983          	lw	s3,-408(s0)
    80004f84:	e8045783          	lhu	a5,-384(s0)
    80004f88:	c7b5                	beqz	a5,80004ff4 <exec+0x14c>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f8a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f8c:	4b81                	li	s7,0
    if(ph.vaddr % PGSIZE != 0)
    80004f8e:	6c05                	lui	s8,0x1
    80004f90:	fffc0793          	addi	a5,s8,-1 # fff <_entry-0x7ffff001>
    80004f94:	def43823          	sd	a5,-528(s0)
    80004f98:	a4b5                	j	80005204 <exec+0x35c>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f9a:	00003517          	auipc	a0,0x3
    80004f9e:	77e50513          	addi	a0,a0,1918 # 80008718 <syscalls+0x290>
    80004fa2:	ffffb097          	auipc	ra,0xffffb
    80004fa6:	5a6080e7          	jalr	1446(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004faa:	8756                	mv	a4,s5
    80004fac:	012d86bb          	addw	a3,s11,s2
    80004fb0:	4581                	li	a1,0
    80004fb2:	8526                	mv	a0,s1
    80004fb4:	fffff097          	auipc	ra,0xfffff
    80004fb8:	c6a080e7          	jalr	-918(ra) # 80003c1e <readi>
    80004fbc:	2501                	sext.w	a0,a0
    80004fbe:	1eaa9d63          	bne	s5,a0,800051b8 <exec+0x310>
  for(i = 0; i < sz; i += PGSIZE){
    80004fc2:	6785                	lui	a5,0x1
    80004fc4:	0127893b          	addw	s2,a5,s2
    80004fc8:	77fd                	lui	a5,0xfffff
    80004fca:	01478a3b          	addw	s4,a5,s4
    80004fce:	21997f63          	bgeu	s2,s9,800051ec <exec+0x344>
    pa = walkaddr(pagetable, va + i);
    80004fd2:	02091593          	slli	a1,s2,0x20
    80004fd6:	9181                	srli	a1,a1,0x20
    80004fd8:	95ea                	add	a1,a1,s10
    80004fda:	e0843503          	ld	a0,-504(s0)
    80004fde:	ffffc097          	auipc	ra,0xffffc
    80004fe2:	0c8080e7          	jalr	200(ra) # 800010a6 <walkaddr>
    80004fe6:	862a                	mv	a2,a0
    if(pa == 0)
    80004fe8:	d94d                	beqz	a0,80004f9a <exec+0xf2>
      n = PGSIZE;
    80004fea:	8ae2                	mv	s5,s8
    if(sz - i < PGSIZE)
    80004fec:	fb8a7fe3          	bgeu	s4,s8,80004faa <exec+0x102>
      n = sz - i;
    80004ff0:	8ad2                	mv	s5,s4
    80004ff2:	bf65                	j	80004faa <exec+0x102>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ff4:	4901                	li	s2,0
  iunlockput(ip);
    80004ff6:	8526                	mv	a0,s1
    80004ff8:	fffff097          	auipc	ra,0xfffff
    80004ffc:	bd4080e7          	jalr	-1068(ra) # 80003bcc <iunlockput>
  end_op();
    80005000:	fffff097          	auipc	ra,0xfffff
    80005004:	3a6080e7          	jalr	934(ra) # 800043a6 <end_op>
  p = myproc();
    80005008:	ffffd097          	auipc	ra,0xffffd
    8000500c:	b60080e7          	jalr	-1184(ra) # 80001b68 <myproc>
    80005010:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005012:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005016:	6b05                	lui	s6,0x1
    80005018:	1b7d                	addi	s6,s6,-1
    8000501a:	995a                	add	s2,s2,s6
    8000501c:	7b7d                	lui	s6,0xfffff
    8000501e:	01697b33          	and	s6,s2,s6
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005022:	6609                	lui	a2,0x2
    80005024:	965a                	add	a2,a2,s6
    80005026:	85da                	mv	a1,s6
    80005028:	e0843903          	ld	s2,-504(s0)
    8000502c:	854a                	mv	a0,s2
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	466080e7          	jalr	1126(ra) # 80001494 <uvmalloc>
    80005036:	8baa                	mv	s7,a0
  ip = 0;
    80005038:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000503a:	16050f63          	beqz	a0,800051b8 <exec+0x310>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000503e:	75f9                	lui	a1,0xffffe
    80005040:	95aa                	add	a1,a1,a0
    80005042:	854a                	mv	a0,s2
    80005044:	ffffc097          	auipc	ra,0xffffc
    80005048:	66e080e7          	jalr	1646(ra) # 800016b2 <uvmclear>
  stackbase = sp - PGSIZE;
    8000504c:	7b7d                	lui	s6,0xfffff
    8000504e:	9b5e                	add	s6,s6,s7
  for(argc = 0; argv[argc]; argc++) {
    80005050:	e0043783          	ld	a5,-512(s0)
    80005054:	6388                	ld	a0,0(a5)
    80005056:	c535                	beqz	a0,800050c2 <exec+0x21a>
    80005058:	e8840993          	addi	s3,s0,-376
    8000505c:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005060:	895e                	mv	s2,s7
    sp -= strlen(argv[argc]) + 1;
    80005062:	ffffc097          	auipc	ra,0xffffc
    80005066:	e32080e7          	jalr	-462(ra) # 80000e94 <strlen>
    8000506a:	2505                	addiw	a0,a0,1
    8000506c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005070:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005074:	17696363          	bltu	s2,s6,800051da <exec+0x332>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005078:	e0043c03          	ld	s8,-512(s0)
    8000507c:	000c3a03          	ld	s4,0(s8)
    80005080:	8552                	mv	a0,s4
    80005082:	ffffc097          	auipc	ra,0xffffc
    80005086:	e12080e7          	jalr	-494(ra) # 80000e94 <strlen>
    8000508a:	0015069b          	addiw	a3,a0,1
    8000508e:	8652                	mv	a2,s4
    80005090:	85ca                	mv	a1,s2
    80005092:	e0843503          	ld	a0,-504(s0)
    80005096:	ffffc097          	auipc	ra,0xffffc
    8000509a:	64e080e7          	jalr	1614(ra) # 800016e4 <copyout>
    8000509e:	14054163          	bltz	a0,800051e0 <exec+0x338>
    ustack[argc] = sp;
    800050a2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050a6:	0485                	addi	s1,s1,1
    800050a8:	008c0793          	addi	a5,s8,8
    800050ac:	e0f43023          	sd	a5,-512(s0)
    800050b0:	008c3503          	ld	a0,8(s8)
    800050b4:	c909                	beqz	a0,800050c6 <exec+0x21e>
    if(argc >= MAXARG)
    800050b6:	09a1                	addi	s3,s3,8
    800050b8:	fb3c95e3          	bne	s9,s3,80005062 <exec+0x1ba>
  sz = sz1;
    800050bc:	8b5e                	mv	s6,s7
  ip = 0;
    800050be:	4481                	li	s1,0
    800050c0:	a8e5                	j	800051b8 <exec+0x310>
  sp = sz;
    800050c2:	895e                	mv	s2,s7
  for(argc = 0; argv[argc]; argc++) {
    800050c4:	4481                	li	s1,0
  ustack[argc] = 0;
    800050c6:	00349793          	slli	a5,s1,0x3
    800050ca:	f9040713          	addi	a4,s0,-112
    800050ce:	97ba                	add	a5,a5,a4
    800050d0:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ed8>
  sp -= (argc+1) * sizeof(uint64);
    800050d4:	00148693          	addi	a3,s1,1
    800050d8:	068e                	slli	a3,a3,0x3
    800050da:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050de:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050e2:	01697563          	bgeu	s2,s6,800050ec <exec+0x244>
  sz = sz1;
    800050e6:	8b5e                	mv	s6,s7
  ip = 0;
    800050e8:	4481                	li	s1,0
    800050ea:	a0f9                	j	800051b8 <exec+0x310>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050ec:	e8840613          	addi	a2,s0,-376
    800050f0:	85ca                	mv	a1,s2
    800050f2:	e0843983          	ld	s3,-504(s0)
    800050f6:	854e                	mv	a0,s3
    800050f8:	ffffc097          	auipc	ra,0xffffc
    800050fc:	5ec080e7          	jalr	1516(ra) # 800016e4 <copyout>
    80005100:	0e054363          	bltz	a0,800051e6 <exec+0x33e>
  uvmunmap(p->kpagetable,0,PGROUNDUP(oldsz)/PGSIZE,0);
    80005104:	6605                	lui	a2,0x1
    80005106:	167d                	addi	a2,a2,-1
    80005108:	966a                	add	a2,a2,s10
    8000510a:	4681                	li	a3,0
    8000510c:	8231                	srli	a2,a2,0xc
    8000510e:	4581                	li	a1,0
    80005110:	168ab503          	ld	a0,360(s5)
    80005114:	ffffc097          	auipc	ra,0xffffc
    80005118:	1d4080e7          	jalr	468(ra) # 800012e8 <uvmunmap>
  vmcopypage(pagetable,p->kpagetable,0,sz);  
    8000511c:	86de                	mv	a3,s7
    8000511e:	4601                	li	a2,0
    80005120:	168ab583          	ld	a1,360(s5)
    80005124:	854e                	mv	a0,s3
    80005126:	ffffd097          	auipc	ra,0xffffd
    8000512a:	888080e7          	jalr	-1912(ra) # 800019ae <vmcopypage>
  p->trapframe->a1 = sp;
    8000512e:	058ab783          	ld	a5,88(s5)
    80005132:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005136:	df843783          	ld	a5,-520(s0)
    8000513a:	0007c703          	lbu	a4,0(a5)
    8000513e:	cf11                	beqz	a4,8000515a <exec+0x2b2>
    80005140:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005142:	02f00693          	li	a3,47
    80005146:	a039                	j	80005154 <exec+0x2ac>
      last = s+1;
    80005148:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000514c:	0785                	addi	a5,a5,1
    8000514e:	fff7c703          	lbu	a4,-1(a5)
    80005152:	c701                	beqz	a4,8000515a <exec+0x2b2>
    if(*s == '/')
    80005154:	fed71ce3          	bne	a4,a3,8000514c <exec+0x2a4>
    80005158:	bfc5                	j	80005148 <exec+0x2a0>
  safestrcpy(p->name, last, sizeof(p->name));
    8000515a:	4641                	li	a2,16
    8000515c:	df843583          	ld	a1,-520(s0)
    80005160:	158a8513          	addi	a0,s5,344
    80005164:	ffffc097          	auipc	ra,0xffffc
    80005168:	cfe080e7          	jalr	-770(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    8000516c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005170:	e0843783          	ld	a5,-504(s0)
    80005174:	04fab823          	sd	a5,80(s5)
  p->sz = sz;
    80005178:	057ab423          	sd	s7,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000517c:	058ab783          	ld	a5,88(s5)
    80005180:	e6043703          	ld	a4,-416(s0)
    80005184:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005186:	058ab783          	ld	a5,88(s5)
    8000518a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000518e:	85ea                	mv	a1,s10
    80005190:	ffffd097          	auipc	ra,0xffffd
    80005194:	b38080e7          	jalr	-1224(ra) # 80001cc8 <proc_freepagetable>
  if (p->pid == 1) 
    80005198:	038aa703          	lw	a4,56(s5)
    8000519c:	4785                	li	a5,1
    8000519e:	00f70563          	beq	a4,a5,800051a8 <exec+0x300>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051a2:	0004851b          	sext.w	a0,s1
    800051a6:	bb69                	j	80004f40 <exec+0x98>
     vmprint(p->pagetable); 
    800051a8:	050ab503          	ld	a0,80(s5)
    800051ac:	ffffc097          	auipc	ra,0xffffc
    800051b0:	6bc080e7          	jalr	1724(ra) # 80001868 <vmprint>
    800051b4:	b7fd                	j	800051a2 <exec+0x2fa>
    800051b6:	8b4a                	mv	s6,s2
    proc_freepagetable(pagetable, sz);
    800051b8:	85da                	mv	a1,s6
    800051ba:	e0843503          	ld	a0,-504(s0)
    800051be:	ffffd097          	auipc	ra,0xffffd
    800051c2:	b0a080e7          	jalr	-1270(ra) # 80001cc8 <proc_freepagetable>
  if(ip){
    800051c6:	d60493e3          	bnez	s1,80004f2c <exec+0x84>
  return -1;
    800051ca:	557d                	li	a0,-1
    800051cc:	bb95                	j	80004f40 <exec+0x98>
    800051ce:	8b4a                	mv	s6,s2
    800051d0:	b7e5                	j	800051b8 <exec+0x310>
    800051d2:	8b4a                	mv	s6,s2
    800051d4:	b7d5                	j	800051b8 <exec+0x310>
    800051d6:	8b4a                	mv	s6,s2
    800051d8:	b7c5                	j	800051b8 <exec+0x310>
  sz = sz1;
    800051da:	8b5e                	mv	s6,s7
  ip = 0;
    800051dc:	4481                	li	s1,0
    800051de:	bfe9                	j	800051b8 <exec+0x310>
  sz = sz1;
    800051e0:	8b5e                	mv	s6,s7
  ip = 0;
    800051e2:	4481                	li	s1,0
    800051e4:	bfd1                	j	800051b8 <exec+0x310>
  sz = sz1;
    800051e6:	8b5e                	mv	s6,s7
  ip = 0;
    800051e8:	4481                	li	s1,0
    800051ea:	b7f9                	j	800051b8 <exec+0x310>
    if (sz1 >= PLIC)
    800051ec:	0c0007b7          	lui	a5,0xc000
    800051f0:	fcfb74e3          	bgeu	s6,a5,800051b8 <exec+0x310>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051f4:	895a                	mv	s2,s6
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051f6:	2b85                	addiw	s7,s7,1
    800051f8:	0389899b          	addiw	s3,s3,56
    800051fc:	e8045783          	lhu	a5,-384(s0)
    80005200:	defbdbe3          	bge	s7,a5,80004ff6 <exec+0x14e>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005204:	2981                	sext.w	s3,s3
    80005206:	03800713          	li	a4,56
    8000520a:	86ce                	mv	a3,s3
    8000520c:	e1040613          	addi	a2,s0,-496
    80005210:	4581                	li	a1,0
    80005212:	8526                	mv	a0,s1
    80005214:	fffff097          	auipc	ra,0xfffff
    80005218:	a0a080e7          	jalr	-1526(ra) # 80003c1e <readi>
    8000521c:	03800793          	li	a5,56
    80005220:	f8f51be3          	bne	a0,a5,800051b6 <exec+0x30e>
    if(ph.type != ELF_PROG_LOAD)
    80005224:	e1042783          	lw	a5,-496(s0)
    80005228:	4705                	li	a4,1
    8000522a:	fce796e3          	bne	a5,a4,800051f6 <exec+0x34e>
    if(ph.memsz < ph.filesz)
    8000522e:	e3843603          	ld	a2,-456(s0)
    80005232:	e3043783          	ld	a5,-464(s0)
    80005236:	f8f66ce3          	bltu	a2,a5,800051ce <exec+0x326>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000523a:	e2043783          	ld	a5,-480(s0)
    8000523e:	963e                	add	a2,a2,a5
    80005240:	f8f669e3          	bltu	a2,a5,800051d2 <exec+0x32a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005244:	85ca                	mv	a1,s2
    80005246:	e0843503          	ld	a0,-504(s0)
    8000524a:	ffffc097          	auipc	ra,0xffffc
    8000524e:	24a080e7          	jalr	586(ra) # 80001494 <uvmalloc>
    80005252:	8b2a                	mv	s6,a0
    80005254:	d149                	beqz	a0,800051d6 <exec+0x32e>
    if(ph.vaddr % PGSIZE != 0)
    80005256:	e2043d03          	ld	s10,-480(s0)
    8000525a:	df043783          	ld	a5,-528(s0)
    8000525e:	00fd77b3          	and	a5,s10,a5
    80005262:	fbb9                	bnez	a5,800051b8 <exec+0x310>
    if (loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005264:	e1842d83          	lw	s11,-488(s0)
    80005268:	e3042c83          	lw	s9,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000526c:	f80c80e3          	beqz	s9,800051ec <exec+0x344>
    80005270:	8a66                	mv	s4,s9
    80005272:	4901                	li	s2,0
    80005274:	bbb9                	j	80004fd2 <exec+0x12a>

0000000080005276 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005276:	7179                	addi	sp,sp,-48
    80005278:	f406                	sd	ra,40(sp)
    8000527a:	f022                	sd	s0,32(sp)
    8000527c:	ec26                	sd	s1,24(sp)
    8000527e:	e84a                	sd	s2,16(sp)
    80005280:	1800                	addi	s0,sp,48
    80005282:	892e                	mv	s2,a1
    80005284:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005286:	fdc40593          	addi	a1,s0,-36
    8000528a:	ffffe097          	auipc	ra,0xffffe
    8000528e:	b06080e7          	jalr	-1274(ra) # 80002d90 <argint>
    80005292:	04054063          	bltz	a0,800052d2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005296:	fdc42703          	lw	a4,-36(s0)
    8000529a:	47bd                	li	a5,15
    8000529c:	02e7ed63          	bltu	a5,a4,800052d6 <argfd+0x60>
    800052a0:	ffffd097          	auipc	ra,0xffffd
    800052a4:	8c8080e7          	jalr	-1848(ra) # 80001b68 <myproc>
    800052a8:	fdc42703          	lw	a4,-36(s0)
    800052ac:	01a70793          	addi	a5,a4,26
    800052b0:	078e                	slli	a5,a5,0x3
    800052b2:	953e                	add	a0,a0,a5
    800052b4:	611c                	ld	a5,0(a0)
    800052b6:	c395                	beqz	a5,800052da <argfd+0x64>
    return -1;
  if(pfd)
    800052b8:	00090463          	beqz	s2,800052c0 <argfd+0x4a>
    *pfd = fd;
    800052bc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052c0:	4501                	li	a0,0
  if(pf)
    800052c2:	c091                	beqz	s1,800052c6 <argfd+0x50>
    *pf = f;
    800052c4:	e09c                	sd	a5,0(s1)
}
    800052c6:	70a2                	ld	ra,40(sp)
    800052c8:	7402                	ld	s0,32(sp)
    800052ca:	64e2                	ld	s1,24(sp)
    800052cc:	6942                	ld	s2,16(sp)
    800052ce:	6145                	addi	sp,sp,48
    800052d0:	8082                	ret
    return -1;
    800052d2:	557d                	li	a0,-1
    800052d4:	bfcd                	j	800052c6 <argfd+0x50>
    return -1;
    800052d6:	557d                	li	a0,-1
    800052d8:	b7fd                	j	800052c6 <argfd+0x50>
    800052da:	557d                	li	a0,-1
    800052dc:	b7ed                	j	800052c6 <argfd+0x50>

00000000800052de <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052de:	1101                	addi	sp,sp,-32
    800052e0:	ec06                	sd	ra,24(sp)
    800052e2:	e822                	sd	s0,16(sp)
    800052e4:	e426                	sd	s1,8(sp)
    800052e6:	1000                	addi	s0,sp,32
    800052e8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052ea:	ffffd097          	auipc	ra,0xffffd
    800052ee:	87e080e7          	jalr	-1922(ra) # 80001b68 <myproc>
    800052f2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052f4:	0d050793          	addi	a5,a0,208
    800052f8:	4501                	li	a0,0
    800052fa:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052fc:	6398                	ld	a4,0(a5)
    800052fe:	cb19                	beqz	a4,80005314 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005300:	2505                	addiw	a0,a0,1
    80005302:	07a1                	addi	a5,a5,8
    80005304:	fed51ce3          	bne	a0,a3,800052fc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005308:	557d                	li	a0,-1
}
    8000530a:	60e2                	ld	ra,24(sp)
    8000530c:	6442                	ld	s0,16(sp)
    8000530e:	64a2                	ld	s1,8(sp)
    80005310:	6105                	addi	sp,sp,32
    80005312:	8082                	ret
      p->ofile[fd] = f;
    80005314:	01a50793          	addi	a5,a0,26
    80005318:	078e                	slli	a5,a5,0x3
    8000531a:	963e                	add	a2,a2,a5
    8000531c:	e204                	sd	s1,0(a2)
      return fd;
    8000531e:	b7f5                	j	8000530a <fdalloc+0x2c>

0000000080005320 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005320:	715d                	addi	sp,sp,-80
    80005322:	e486                	sd	ra,72(sp)
    80005324:	e0a2                	sd	s0,64(sp)
    80005326:	fc26                	sd	s1,56(sp)
    80005328:	f84a                	sd	s2,48(sp)
    8000532a:	f44e                	sd	s3,40(sp)
    8000532c:	f052                	sd	s4,32(sp)
    8000532e:	ec56                	sd	s5,24(sp)
    80005330:	0880                	addi	s0,sp,80
    80005332:	89ae                	mv	s3,a1
    80005334:	8ab2                	mv	s5,a2
    80005336:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005338:	fb040593          	addi	a1,s0,-80
    8000533c:	fffff097          	auipc	ra,0xfffff
    80005340:	dfc080e7          	jalr	-516(ra) # 80004138 <nameiparent>
    80005344:	892a                	mv	s2,a0
    80005346:	12050f63          	beqz	a0,80005484 <create+0x164>
    return 0;

  ilock(dp);
    8000534a:	ffffe097          	auipc	ra,0xffffe
    8000534e:	620080e7          	jalr	1568(ra) # 8000396a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005352:	4601                	li	a2,0
    80005354:	fb040593          	addi	a1,s0,-80
    80005358:	854a                	mv	a0,s2
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	aee080e7          	jalr	-1298(ra) # 80003e48 <dirlookup>
    80005362:	84aa                	mv	s1,a0
    80005364:	c921                	beqz	a0,800053b4 <create+0x94>
    iunlockput(dp);
    80005366:	854a                	mv	a0,s2
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	864080e7          	jalr	-1948(ra) # 80003bcc <iunlockput>
    ilock(ip);
    80005370:	8526                	mv	a0,s1
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	5f8080e7          	jalr	1528(ra) # 8000396a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000537a:	2981                	sext.w	s3,s3
    8000537c:	4789                	li	a5,2
    8000537e:	02f99463          	bne	s3,a5,800053a6 <create+0x86>
    80005382:	0444d783          	lhu	a5,68(s1)
    80005386:	37f9                	addiw	a5,a5,-2
    80005388:	17c2                	slli	a5,a5,0x30
    8000538a:	93c1                	srli	a5,a5,0x30
    8000538c:	4705                	li	a4,1
    8000538e:	00f76c63          	bltu	a4,a5,800053a6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005392:	8526                	mv	a0,s1
    80005394:	60a6                	ld	ra,72(sp)
    80005396:	6406                	ld	s0,64(sp)
    80005398:	74e2                	ld	s1,56(sp)
    8000539a:	7942                	ld	s2,48(sp)
    8000539c:	79a2                	ld	s3,40(sp)
    8000539e:	7a02                	ld	s4,32(sp)
    800053a0:	6ae2                	ld	s5,24(sp)
    800053a2:	6161                	addi	sp,sp,80
    800053a4:	8082                	ret
    iunlockput(ip);
    800053a6:	8526                	mv	a0,s1
    800053a8:	fffff097          	auipc	ra,0xfffff
    800053ac:	824080e7          	jalr	-2012(ra) # 80003bcc <iunlockput>
    return 0;
    800053b0:	4481                	li	s1,0
    800053b2:	b7c5                	j	80005392 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800053b4:	85ce                	mv	a1,s3
    800053b6:	00092503          	lw	a0,0(s2)
    800053ba:	ffffe097          	auipc	ra,0xffffe
    800053be:	418080e7          	jalr	1048(ra) # 800037d2 <ialloc>
    800053c2:	84aa                	mv	s1,a0
    800053c4:	c529                	beqz	a0,8000540e <create+0xee>
  ilock(ip);
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	5a4080e7          	jalr	1444(ra) # 8000396a <ilock>
  ip->major = major;
    800053ce:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800053d2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800053d6:	4785                	li	a5,1
    800053d8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053dc:	8526                	mv	a0,s1
    800053de:	ffffe097          	auipc	ra,0xffffe
    800053e2:	4c2080e7          	jalr	1218(ra) # 800038a0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053e6:	2981                	sext.w	s3,s3
    800053e8:	4785                	li	a5,1
    800053ea:	02f98a63          	beq	s3,a5,8000541e <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800053ee:	40d0                	lw	a2,4(s1)
    800053f0:	fb040593          	addi	a1,s0,-80
    800053f4:	854a                	mv	a0,s2
    800053f6:	fffff097          	auipc	ra,0xfffff
    800053fa:	c62080e7          	jalr	-926(ra) # 80004058 <dirlink>
    800053fe:	06054b63          	bltz	a0,80005474 <create+0x154>
  iunlockput(dp);
    80005402:	854a                	mv	a0,s2
    80005404:	ffffe097          	auipc	ra,0xffffe
    80005408:	7c8080e7          	jalr	1992(ra) # 80003bcc <iunlockput>
  return ip;
    8000540c:	b759                	j	80005392 <create+0x72>
    panic("create: ialloc");
    8000540e:	00003517          	auipc	a0,0x3
    80005412:	32a50513          	addi	a0,a0,810 # 80008738 <syscalls+0x2b0>
    80005416:	ffffb097          	auipc	ra,0xffffb
    8000541a:	132080e7          	jalr	306(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    8000541e:	04a95783          	lhu	a5,74(s2)
    80005422:	2785                	addiw	a5,a5,1
    80005424:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005428:	854a                	mv	a0,s2
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	476080e7          	jalr	1142(ra) # 800038a0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005432:	40d0                	lw	a2,4(s1)
    80005434:	00003597          	auipc	a1,0x3
    80005438:	31458593          	addi	a1,a1,788 # 80008748 <syscalls+0x2c0>
    8000543c:	8526                	mv	a0,s1
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	c1a080e7          	jalr	-998(ra) # 80004058 <dirlink>
    80005446:	00054f63          	bltz	a0,80005464 <create+0x144>
    8000544a:	00492603          	lw	a2,4(s2)
    8000544e:	00003597          	auipc	a1,0x3
    80005452:	d8258593          	addi	a1,a1,-638 # 800081d0 <digits+0x190>
    80005456:	8526                	mv	a0,s1
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	c00080e7          	jalr	-1024(ra) # 80004058 <dirlink>
    80005460:	f80557e3          	bgez	a0,800053ee <create+0xce>
      panic("create dots");
    80005464:	00003517          	auipc	a0,0x3
    80005468:	2ec50513          	addi	a0,a0,748 # 80008750 <syscalls+0x2c8>
    8000546c:	ffffb097          	auipc	ra,0xffffb
    80005470:	0dc080e7          	jalr	220(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005474:	00003517          	auipc	a0,0x3
    80005478:	2ec50513          	addi	a0,a0,748 # 80008760 <syscalls+0x2d8>
    8000547c:	ffffb097          	auipc	ra,0xffffb
    80005480:	0cc080e7          	jalr	204(ra) # 80000548 <panic>
    return 0;
    80005484:	84aa                	mv	s1,a0
    80005486:	b731                	j	80005392 <create+0x72>

0000000080005488 <sys_dup>:
{
    80005488:	7179                	addi	sp,sp,-48
    8000548a:	f406                	sd	ra,40(sp)
    8000548c:	f022                	sd	s0,32(sp)
    8000548e:	ec26                	sd	s1,24(sp)
    80005490:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005492:	fd840613          	addi	a2,s0,-40
    80005496:	4581                	li	a1,0
    80005498:	4501                	li	a0,0
    8000549a:	00000097          	auipc	ra,0x0
    8000549e:	ddc080e7          	jalr	-548(ra) # 80005276 <argfd>
    return -1;
    800054a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054a4:	02054363          	bltz	a0,800054ca <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054a8:	fd843503          	ld	a0,-40(s0)
    800054ac:	00000097          	auipc	ra,0x0
    800054b0:	e32080e7          	jalr	-462(ra) # 800052de <fdalloc>
    800054b4:	84aa                	mv	s1,a0
    return -1;
    800054b6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054b8:	00054963          	bltz	a0,800054ca <sys_dup+0x42>
  filedup(f);
    800054bc:	fd843503          	ld	a0,-40(s0)
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	2e6080e7          	jalr	742(ra) # 800047a6 <filedup>
  return fd;
    800054c8:	87a6                	mv	a5,s1
}
    800054ca:	853e                	mv	a0,a5
    800054cc:	70a2                	ld	ra,40(sp)
    800054ce:	7402                	ld	s0,32(sp)
    800054d0:	64e2                	ld	s1,24(sp)
    800054d2:	6145                	addi	sp,sp,48
    800054d4:	8082                	ret

00000000800054d6 <sys_read>:
{
    800054d6:	7179                	addi	sp,sp,-48
    800054d8:	f406                	sd	ra,40(sp)
    800054da:	f022                	sd	s0,32(sp)
    800054dc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054de:	fe840613          	addi	a2,s0,-24
    800054e2:	4581                	li	a1,0
    800054e4:	4501                	li	a0,0
    800054e6:	00000097          	auipc	ra,0x0
    800054ea:	d90080e7          	jalr	-624(ra) # 80005276 <argfd>
    return -1;
    800054ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f0:	04054163          	bltz	a0,80005532 <sys_read+0x5c>
    800054f4:	fe440593          	addi	a1,s0,-28
    800054f8:	4509                	li	a0,2
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	896080e7          	jalr	-1898(ra) # 80002d90 <argint>
    return -1;
    80005502:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005504:	02054763          	bltz	a0,80005532 <sys_read+0x5c>
    80005508:	fd840593          	addi	a1,s0,-40
    8000550c:	4505                	li	a0,1
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	8a4080e7          	jalr	-1884(ra) # 80002db2 <argaddr>
    return -1;
    80005516:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005518:	00054d63          	bltz	a0,80005532 <sys_read+0x5c>
  return fileread(f, p, n);
    8000551c:	fe442603          	lw	a2,-28(s0)
    80005520:	fd843583          	ld	a1,-40(s0)
    80005524:	fe843503          	ld	a0,-24(s0)
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	40a080e7          	jalr	1034(ra) # 80004932 <fileread>
    80005530:	87aa                	mv	a5,a0
}
    80005532:	853e                	mv	a0,a5
    80005534:	70a2                	ld	ra,40(sp)
    80005536:	7402                	ld	s0,32(sp)
    80005538:	6145                	addi	sp,sp,48
    8000553a:	8082                	ret

000000008000553c <sys_write>:
{
    8000553c:	7179                	addi	sp,sp,-48
    8000553e:	f406                	sd	ra,40(sp)
    80005540:	f022                	sd	s0,32(sp)
    80005542:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005544:	fe840613          	addi	a2,s0,-24
    80005548:	4581                	li	a1,0
    8000554a:	4501                	li	a0,0
    8000554c:	00000097          	auipc	ra,0x0
    80005550:	d2a080e7          	jalr	-726(ra) # 80005276 <argfd>
    return -1;
    80005554:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005556:	04054163          	bltz	a0,80005598 <sys_write+0x5c>
    8000555a:	fe440593          	addi	a1,s0,-28
    8000555e:	4509                	li	a0,2
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	830080e7          	jalr	-2000(ra) # 80002d90 <argint>
    return -1;
    80005568:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000556a:	02054763          	bltz	a0,80005598 <sys_write+0x5c>
    8000556e:	fd840593          	addi	a1,s0,-40
    80005572:	4505                	li	a0,1
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	83e080e7          	jalr	-1986(ra) # 80002db2 <argaddr>
    return -1;
    8000557c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000557e:	00054d63          	bltz	a0,80005598 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005582:	fe442603          	lw	a2,-28(s0)
    80005586:	fd843583          	ld	a1,-40(s0)
    8000558a:	fe843503          	ld	a0,-24(s0)
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	466080e7          	jalr	1126(ra) # 800049f4 <filewrite>
    80005596:	87aa                	mv	a5,a0
}
    80005598:	853e                	mv	a0,a5
    8000559a:	70a2                	ld	ra,40(sp)
    8000559c:	7402                	ld	s0,32(sp)
    8000559e:	6145                	addi	sp,sp,48
    800055a0:	8082                	ret

00000000800055a2 <sys_close>:
{
    800055a2:	1101                	addi	sp,sp,-32
    800055a4:	ec06                	sd	ra,24(sp)
    800055a6:	e822                	sd	s0,16(sp)
    800055a8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055aa:	fe040613          	addi	a2,s0,-32
    800055ae:	fec40593          	addi	a1,s0,-20
    800055b2:	4501                	li	a0,0
    800055b4:	00000097          	auipc	ra,0x0
    800055b8:	cc2080e7          	jalr	-830(ra) # 80005276 <argfd>
    return -1;
    800055bc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055be:	02054463          	bltz	a0,800055e6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055c2:	ffffc097          	auipc	ra,0xffffc
    800055c6:	5a6080e7          	jalr	1446(ra) # 80001b68 <myproc>
    800055ca:	fec42783          	lw	a5,-20(s0)
    800055ce:	07e9                	addi	a5,a5,26
    800055d0:	078e                	slli	a5,a5,0x3
    800055d2:	97aa                	add	a5,a5,a0
    800055d4:	0007b023          	sd	zero,0(a5) # c000000 <_entry-0x74000000>
  fileclose(f);
    800055d8:	fe043503          	ld	a0,-32(s0)
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	21c080e7          	jalr	540(ra) # 800047f8 <fileclose>
  return 0;
    800055e4:	4781                	li	a5,0
}
    800055e6:	853e                	mv	a0,a5
    800055e8:	60e2                	ld	ra,24(sp)
    800055ea:	6442                	ld	s0,16(sp)
    800055ec:	6105                	addi	sp,sp,32
    800055ee:	8082                	ret

00000000800055f0 <sys_fstat>:
{
    800055f0:	1101                	addi	sp,sp,-32
    800055f2:	ec06                	sd	ra,24(sp)
    800055f4:	e822                	sd	s0,16(sp)
    800055f6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055f8:	fe840613          	addi	a2,s0,-24
    800055fc:	4581                	li	a1,0
    800055fe:	4501                	li	a0,0
    80005600:	00000097          	auipc	ra,0x0
    80005604:	c76080e7          	jalr	-906(ra) # 80005276 <argfd>
    return -1;
    80005608:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000560a:	02054563          	bltz	a0,80005634 <sys_fstat+0x44>
    8000560e:	fe040593          	addi	a1,s0,-32
    80005612:	4505                	li	a0,1
    80005614:	ffffd097          	auipc	ra,0xffffd
    80005618:	79e080e7          	jalr	1950(ra) # 80002db2 <argaddr>
    return -1;
    8000561c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000561e:	00054b63          	bltz	a0,80005634 <sys_fstat+0x44>
  return filestat(f, st);
    80005622:	fe043583          	ld	a1,-32(s0)
    80005626:	fe843503          	ld	a0,-24(s0)
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	296080e7          	jalr	662(ra) # 800048c0 <filestat>
    80005632:	87aa                	mv	a5,a0
}
    80005634:	853e                	mv	a0,a5
    80005636:	60e2                	ld	ra,24(sp)
    80005638:	6442                	ld	s0,16(sp)
    8000563a:	6105                	addi	sp,sp,32
    8000563c:	8082                	ret

000000008000563e <sys_link>:
{
    8000563e:	7169                	addi	sp,sp,-304
    80005640:	f606                	sd	ra,296(sp)
    80005642:	f222                	sd	s0,288(sp)
    80005644:	ee26                	sd	s1,280(sp)
    80005646:	ea4a                	sd	s2,272(sp)
    80005648:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000564a:	08000613          	li	a2,128
    8000564e:	ed040593          	addi	a1,s0,-304
    80005652:	4501                	li	a0,0
    80005654:	ffffd097          	auipc	ra,0xffffd
    80005658:	780080e7          	jalr	1920(ra) # 80002dd4 <argstr>
    return -1;
    8000565c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000565e:	10054e63          	bltz	a0,8000577a <sys_link+0x13c>
    80005662:	08000613          	li	a2,128
    80005666:	f5040593          	addi	a1,s0,-176
    8000566a:	4505                	li	a0,1
    8000566c:	ffffd097          	auipc	ra,0xffffd
    80005670:	768080e7          	jalr	1896(ra) # 80002dd4 <argstr>
    return -1;
    80005674:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005676:	10054263          	bltz	a0,8000577a <sys_link+0x13c>
  begin_op();
    8000567a:	fffff097          	auipc	ra,0xfffff
    8000567e:	cac080e7          	jalr	-852(ra) # 80004326 <begin_op>
  if((ip = namei(old)) == 0){
    80005682:	ed040513          	addi	a0,s0,-304
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	a94080e7          	jalr	-1388(ra) # 8000411a <namei>
    8000568e:	84aa                	mv	s1,a0
    80005690:	c551                	beqz	a0,8000571c <sys_link+0xde>
  ilock(ip);
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	2d8080e7          	jalr	728(ra) # 8000396a <ilock>
  if(ip->type == T_DIR){
    8000569a:	04449703          	lh	a4,68(s1)
    8000569e:	4785                	li	a5,1
    800056a0:	08f70463          	beq	a4,a5,80005728 <sys_link+0xea>
  ip->nlink++;
    800056a4:	04a4d783          	lhu	a5,74(s1)
    800056a8:	2785                	addiw	a5,a5,1
    800056aa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056ae:	8526                	mv	a0,s1
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	1f0080e7          	jalr	496(ra) # 800038a0 <iupdate>
  iunlock(ip);
    800056b8:	8526                	mv	a0,s1
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	372080e7          	jalr	882(ra) # 80003a2c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056c2:	fd040593          	addi	a1,s0,-48
    800056c6:	f5040513          	addi	a0,s0,-176
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	a6e080e7          	jalr	-1426(ra) # 80004138 <nameiparent>
    800056d2:	892a                	mv	s2,a0
    800056d4:	c935                	beqz	a0,80005748 <sys_link+0x10a>
  ilock(dp);
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	294080e7          	jalr	660(ra) # 8000396a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056de:	00092703          	lw	a4,0(s2)
    800056e2:	409c                	lw	a5,0(s1)
    800056e4:	04f71d63          	bne	a4,a5,8000573e <sys_link+0x100>
    800056e8:	40d0                	lw	a2,4(s1)
    800056ea:	fd040593          	addi	a1,s0,-48
    800056ee:	854a                	mv	a0,s2
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	968080e7          	jalr	-1688(ra) # 80004058 <dirlink>
    800056f8:	04054363          	bltz	a0,8000573e <sys_link+0x100>
  iunlockput(dp);
    800056fc:	854a                	mv	a0,s2
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	4ce080e7          	jalr	1230(ra) # 80003bcc <iunlockput>
  iput(ip);
    80005706:	8526                	mv	a0,s1
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	41c080e7          	jalr	1052(ra) # 80003b24 <iput>
  end_op();
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	c96080e7          	jalr	-874(ra) # 800043a6 <end_op>
  return 0;
    80005718:	4781                	li	a5,0
    8000571a:	a085                	j	8000577a <sys_link+0x13c>
    end_op();
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	c8a080e7          	jalr	-886(ra) # 800043a6 <end_op>
    return -1;
    80005724:	57fd                	li	a5,-1
    80005726:	a891                	j	8000577a <sys_link+0x13c>
    iunlockput(ip);
    80005728:	8526                	mv	a0,s1
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	4a2080e7          	jalr	1186(ra) # 80003bcc <iunlockput>
    end_op();
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	c74080e7          	jalr	-908(ra) # 800043a6 <end_op>
    return -1;
    8000573a:	57fd                	li	a5,-1
    8000573c:	a83d                	j	8000577a <sys_link+0x13c>
    iunlockput(dp);
    8000573e:	854a                	mv	a0,s2
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	48c080e7          	jalr	1164(ra) # 80003bcc <iunlockput>
  ilock(ip);
    80005748:	8526                	mv	a0,s1
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	220080e7          	jalr	544(ra) # 8000396a <ilock>
  ip->nlink--;
    80005752:	04a4d783          	lhu	a5,74(s1)
    80005756:	37fd                	addiw	a5,a5,-1
    80005758:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000575c:	8526                	mv	a0,s1
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	142080e7          	jalr	322(ra) # 800038a0 <iupdate>
  iunlockput(ip);
    80005766:	8526                	mv	a0,s1
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	464080e7          	jalr	1124(ra) # 80003bcc <iunlockput>
  end_op();
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	c36080e7          	jalr	-970(ra) # 800043a6 <end_op>
  return -1;
    80005778:	57fd                	li	a5,-1
}
    8000577a:	853e                	mv	a0,a5
    8000577c:	70b2                	ld	ra,296(sp)
    8000577e:	7412                	ld	s0,288(sp)
    80005780:	64f2                	ld	s1,280(sp)
    80005782:	6952                	ld	s2,272(sp)
    80005784:	6155                	addi	sp,sp,304
    80005786:	8082                	ret

0000000080005788 <sys_unlink>:
{
    80005788:	7151                	addi	sp,sp,-240
    8000578a:	f586                	sd	ra,232(sp)
    8000578c:	f1a2                	sd	s0,224(sp)
    8000578e:	eda6                	sd	s1,216(sp)
    80005790:	e9ca                	sd	s2,208(sp)
    80005792:	e5ce                	sd	s3,200(sp)
    80005794:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005796:	08000613          	li	a2,128
    8000579a:	f3040593          	addi	a1,s0,-208
    8000579e:	4501                	li	a0,0
    800057a0:	ffffd097          	auipc	ra,0xffffd
    800057a4:	634080e7          	jalr	1588(ra) # 80002dd4 <argstr>
    800057a8:	18054163          	bltz	a0,8000592a <sys_unlink+0x1a2>
  begin_op();
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	b7a080e7          	jalr	-1158(ra) # 80004326 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057b4:	fb040593          	addi	a1,s0,-80
    800057b8:	f3040513          	addi	a0,s0,-208
    800057bc:	fffff097          	auipc	ra,0xfffff
    800057c0:	97c080e7          	jalr	-1668(ra) # 80004138 <nameiparent>
    800057c4:	84aa                	mv	s1,a0
    800057c6:	c979                	beqz	a0,8000589c <sys_unlink+0x114>
  ilock(dp);
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	1a2080e7          	jalr	418(ra) # 8000396a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057d0:	00003597          	auipc	a1,0x3
    800057d4:	f7858593          	addi	a1,a1,-136 # 80008748 <syscalls+0x2c0>
    800057d8:	fb040513          	addi	a0,s0,-80
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	652080e7          	jalr	1618(ra) # 80003e2e <namecmp>
    800057e4:	14050a63          	beqz	a0,80005938 <sys_unlink+0x1b0>
    800057e8:	00003597          	auipc	a1,0x3
    800057ec:	9e858593          	addi	a1,a1,-1560 # 800081d0 <digits+0x190>
    800057f0:	fb040513          	addi	a0,s0,-80
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	63a080e7          	jalr	1594(ra) # 80003e2e <namecmp>
    800057fc:	12050e63          	beqz	a0,80005938 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005800:	f2c40613          	addi	a2,s0,-212
    80005804:	fb040593          	addi	a1,s0,-80
    80005808:	8526                	mv	a0,s1
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	63e080e7          	jalr	1598(ra) # 80003e48 <dirlookup>
    80005812:	892a                	mv	s2,a0
    80005814:	12050263          	beqz	a0,80005938 <sys_unlink+0x1b0>
  ilock(ip);
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	152080e7          	jalr	338(ra) # 8000396a <ilock>
  if(ip->nlink < 1)
    80005820:	04a91783          	lh	a5,74(s2)
    80005824:	08f05263          	blez	a5,800058a8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005828:	04491703          	lh	a4,68(s2)
    8000582c:	4785                	li	a5,1
    8000582e:	08f70563          	beq	a4,a5,800058b8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005832:	4641                	li	a2,16
    80005834:	4581                	li	a1,0
    80005836:	fc040513          	addi	a0,s0,-64
    8000583a:	ffffb097          	auipc	ra,0xffffb
    8000583e:	4d2080e7          	jalr	1234(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005842:	4741                	li	a4,16
    80005844:	f2c42683          	lw	a3,-212(s0)
    80005848:	fc040613          	addi	a2,s0,-64
    8000584c:	4581                	li	a1,0
    8000584e:	8526                	mv	a0,s1
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	4c4080e7          	jalr	1220(ra) # 80003d14 <writei>
    80005858:	47c1                	li	a5,16
    8000585a:	0af51563          	bne	a0,a5,80005904 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000585e:	04491703          	lh	a4,68(s2)
    80005862:	4785                	li	a5,1
    80005864:	0af70863          	beq	a4,a5,80005914 <sys_unlink+0x18c>
  iunlockput(dp);
    80005868:	8526                	mv	a0,s1
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	362080e7          	jalr	866(ra) # 80003bcc <iunlockput>
  ip->nlink--;
    80005872:	04a95783          	lhu	a5,74(s2)
    80005876:	37fd                	addiw	a5,a5,-1
    80005878:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000587c:	854a                	mv	a0,s2
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	022080e7          	jalr	34(ra) # 800038a0 <iupdate>
  iunlockput(ip);
    80005886:	854a                	mv	a0,s2
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	344080e7          	jalr	836(ra) # 80003bcc <iunlockput>
  end_op();
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	b16080e7          	jalr	-1258(ra) # 800043a6 <end_op>
  return 0;
    80005898:	4501                	li	a0,0
    8000589a:	a84d                	j	8000594c <sys_unlink+0x1c4>
    end_op();
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	b0a080e7          	jalr	-1270(ra) # 800043a6 <end_op>
    return -1;
    800058a4:	557d                	li	a0,-1
    800058a6:	a05d                	j	8000594c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058a8:	00003517          	auipc	a0,0x3
    800058ac:	ec850513          	addi	a0,a0,-312 # 80008770 <syscalls+0x2e8>
    800058b0:	ffffb097          	auipc	ra,0xffffb
    800058b4:	c98080e7          	jalr	-872(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058b8:	04c92703          	lw	a4,76(s2)
    800058bc:	02000793          	li	a5,32
    800058c0:	f6e7f9e3          	bgeu	a5,a4,80005832 <sys_unlink+0xaa>
    800058c4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058c8:	4741                	li	a4,16
    800058ca:	86ce                	mv	a3,s3
    800058cc:	f1840613          	addi	a2,s0,-232
    800058d0:	4581                	li	a1,0
    800058d2:	854a                	mv	a0,s2
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	34a080e7          	jalr	842(ra) # 80003c1e <readi>
    800058dc:	47c1                	li	a5,16
    800058de:	00f51b63          	bne	a0,a5,800058f4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058e2:	f1845783          	lhu	a5,-232(s0)
    800058e6:	e7a1                	bnez	a5,8000592e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058e8:	29c1                	addiw	s3,s3,16
    800058ea:	04c92783          	lw	a5,76(s2)
    800058ee:	fcf9ede3          	bltu	s3,a5,800058c8 <sys_unlink+0x140>
    800058f2:	b781                	j	80005832 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058f4:	00003517          	auipc	a0,0x3
    800058f8:	e9450513          	addi	a0,a0,-364 # 80008788 <syscalls+0x300>
    800058fc:	ffffb097          	auipc	ra,0xffffb
    80005900:	c4c080e7          	jalr	-948(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005904:	00003517          	auipc	a0,0x3
    80005908:	e9c50513          	addi	a0,a0,-356 # 800087a0 <syscalls+0x318>
    8000590c:	ffffb097          	auipc	ra,0xffffb
    80005910:	c3c080e7          	jalr	-964(ra) # 80000548 <panic>
    dp->nlink--;
    80005914:	04a4d783          	lhu	a5,74(s1)
    80005918:	37fd                	addiw	a5,a5,-1
    8000591a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000591e:	8526                	mv	a0,s1
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	f80080e7          	jalr	-128(ra) # 800038a0 <iupdate>
    80005928:	b781                	j	80005868 <sys_unlink+0xe0>
    return -1;
    8000592a:	557d                	li	a0,-1
    8000592c:	a005                	j	8000594c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000592e:	854a                	mv	a0,s2
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	29c080e7          	jalr	668(ra) # 80003bcc <iunlockput>
  iunlockput(dp);
    80005938:	8526                	mv	a0,s1
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	292080e7          	jalr	658(ra) # 80003bcc <iunlockput>
  end_op();
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	a64080e7          	jalr	-1436(ra) # 800043a6 <end_op>
  return -1;
    8000594a:	557d                	li	a0,-1
}
    8000594c:	70ae                	ld	ra,232(sp)
    8000594e:	740e                	ld	s0,224(sp)
    80005950:	64ee                	ld	s1,216(sp)
    80005952:	694e                	ld	s2,208(sp)
    80005954:	69ae                	ld	s3,200(sp)
    80005956:	616d                	addi	sp,sp,240
    80005958:	8082                	ret

000000008000595a <sys_open>:

uint64
sys_open(void)
{
    8000595a:	7131                	addi	sp,sp,-192
    8000595c:	fd06                	sd	ra,184(sp)
    8000595e:	f922                	sd	s0,176(sp)
    80005960:	f526                	sd	s1,168(sp)
    80005962:	f14a                	sd	s2,160(sp)
    80005964:	ed4e                	sd	s3,152(sp)
    80005966:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005968:	08000613          	li	a2,128
    8000596c:	f5040593          	addi	a1,s0,-176
    80005970:	4501                	li	a0,0
    80005972:	ffffd097          	auipc	ra,0xffffd
    80005976:	462080e7          	jalr	1122(ra) # 80002dd4 <argstr>
    return -1;
    8000597a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000597c:	0c054163          	bltz	a0,80005a3e <sys_open+0xe4>
    80005980:	f4c40593          	addi	a1,s0,-180
    80005984:	4505                	li	a0,1
    80005986:	ffffd097          	auipc	ra,0xffffd
    8000598a:	40a080e7          	jalr	1034(ra) # 80002d90 <argint>
    8000598e:	0a054863          	bltz	a0,80005a3e <sys_open+0xe4>

  begin_op();
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	994080e7          	jalr	-1644(ra) # 80004326 <begin_op>

  if(omode & O_CREATE){
    8000599a:	f4c42783          	lw	a5,-180(s0)
    8000599e:	2007f793          	andi	a5,a5,512
    800059a2:	cbdd                	beqz	a5,80005a58 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059a4:	4681                	li	a3,0
    800059a6:	4601                	li	a2,0
    800059a8:	4589                	li	a1,2
    800059aa:	f5040513          	addi	a0,s0,-176
    800059ae:	00000097          	auipc	ra,0x0
    800059b2:	972080e7          	jalr	-1678(ra) # 80005320 <create>
    800059b6:	892a                	mv	s2,a0
    if(ip == 0){
    800059b8:	c959                	beqz	a0,80005a4e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059ba:	04491703          	lh	a4,68(s2)
    800059be:	478d                	li	a5,3
    800059c0:	00f71763          	bne	a4,a5,800059ce <sys_open+0x74>
    800059c4:	04695703          	lhu	a4,70(s2)
    800059c8:	47a5                	li	a5,9
    800059ca:	0ce7ec63          	bltu	a5,a4,80005aa2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	d6e080e7          	jalr	-658(ra) # 8000473c <filealloc>
    800059d6:	89aa                	mv	s3,a0
    800059d8:	10050263          	beqz	a0,80005adc <sys_open+0x182>
    800059dc:	00000097          	auipc	ra,0x0
    800059e0:	902080e7          	jalr	-1790(ra) # 800052de <fdalloc>
    800059e4:	84aa                	mv	s1,a0
    800059e6:	0e054663          	bltz	a0,80005ad2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059ea:	04491703          	lh	a4,68(s2)
    800059ee:	478d                	li	a5,3
    800059f0:	0cf70463          	beq	a4,a5,80005ab8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059f4:	4789                	li	a5,2
    800059f6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059fa:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059fe:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a02:	f4c42783          	lw	a5,-180(s0)
    80005a06:	0017c713          	xori	a4,a5,1
    80005a0a:	8b05                	andi	a4,a4,1
    80005a0c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a10:	0037f713          	andi	a4,a5,3
    80005a14:	00e03733          	snez	a4,a4
    80005a18:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a1c:	4007f793          	andi	a5,a5,1024
    80005a20:	c791                	beqz	a5,80005a2c <sys_open+0xd2>
    80005a22:	04491703          	lh	a4,68(s2)
    80005a26:	4789                	li	a5,2
    80005a28:	08f70f63          	beq	a4,a5,80005ac6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a2c:	854a                	mv	a0,s2
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	ffe080e7          	jalr	-2(ra) # 80003a2c <iunlock>
  end_op();
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	970080e7          	jalr	-1680(ra) # 800043a6 <end_op>

  return fd;
}
    80005a3e:	8526                	mv	a0,s1
    80005a40:	70ea                	ld	ra,184(sp)
    80005a42:	744a                	ld	s0,176(sp)
    80005a44:	74aa                	ld	s1,168(sp)
    80005a46:	790a                	ld	s2,160(sp)
    80005a48:	69ea                	ld	s3,152(sp)
    80005a4a:	6129                	addi	sp,sp,192
    80005a4c:	8082                	ret
      end_op();
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	958080e7          	jalr	-1704(ra) # 800043a6 <end_op>
      return -1;
    80005a56:	b7e5                	j	80005a3e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a58:	f5040513          	addi	a0,s0,-176
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	6be080e7          	jalr	1726(ra) # 8000411a <namei>
    80005a64:	892a                	mv	s2,a0
    80005a66:	c905                	beqz	a0,80005a96 <sys_open+0x13c>
    ilock(ip);
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	f02080e7          	jalr	-254(ra) # 8000396a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a70:	04491703          	lh	a4,68(s2)
    80005a74:	4785                	li	a5,1
    80005a76:	f4f712e3          	bne	a4,a5,800059ba <sys_open+0x60>
    80005a7a:	f4c42783          	lw	a5,-180(s0)
    80005a7e:	dba1                	beqz	a5,800059ce <sys_open+0x74>
      iunlockput(ip);
    80005a80:	854a                	mv	a0,s2
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	14a080e7          	jalr	330(ra) # 80003bcc <iunlockput>
      end_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	91c080e7          	jalr	-1764(ra) # 800043a6 <end_op>
      return -1;
    80005a92:	54fd                	li	s1,-1
    80005a94:	b76d                	j	80005a3e <sys_open+0xe4>
      end_op();
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	910080e7          	jalr	-1776(ra) # 800043a6 <end_op>
      return -1;
    80005a9e:	54fd                	li	s1,-1
    80005aa0:	bf79                	j	80005a3e <sys_open+0xe4>
    iunlockput(ip);
    80005aa2:	854a                	mv	a0,s2
    80005aa4:	ffffe097          	auipc	ra,0xffffe
    80005aa8:	128080e7          	jalr	296(ra) # 80003bcc <iunlockput>
    end_op();
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	8fa080e7          	jalr	-1798(ra) # 800043a6 <end_op>
    return -1;
    80005ab4:	54fd                	li	s1,-1
    80005ab6:	b761                	j	80005a3e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ab8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005abc:	04691783          	lh	a5,70(s2)
    80005ac0:	02f99223          	sh	a5,36(s3)
    80005ac4:	bf2d                	j	800059fe <sys_open+0xa4>
    itrunc(ip);
    80005ac6:	854a                	mv	a0,s2
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	fb0080e7          	jalr	-80(ra) # 80003a78 <itrunc>
    80005ad0:	bfb1                	j	80005a2c <sys_open+0xd2>
      fileclose(f);
    80005ad2:	854e                	mv	a0,s3
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	d24080e7          	jalr	-732(ra) # 800047f8 <fileclose>
    iunlockput(ip);
    80005adc:	854a                	mv	a0,s2
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	0ee080e7          	jalr	238(ra) # 80003bcc <iunlockput>
    end_op();
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	8c0080e7          	jalr	-1856(ra) # 800043a6 <end_op>
    return -1;
    80005aee:	54fd                	li	s1,-1
    80005af0:	b7b9                	j	80005a3e <sys_open+0xe4>

0000000080005af2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005af2:	7175                	addi	sp,sp,-144
    80005af4:	e506                	sd	ra,136(sp)
    80005af6:	e122                	sd	s0,128(sp)
    80005af8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	82c080e7          	jalr	-2004(ra) # 80004326 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b02:	08000613          	li	a2,128
    80005b06:	f7040593          	addi	a1,s0,-144
    80005b0a:	4501                	li	a0,0
    80005b0c:	ffffd097          	auipc	ra,0xffffd
    80005b10:	2c8080e7          	jalr	712(ra) # 80002dd4 <argstr>
    80005b14:	02054963          	bltz	a0,80005b46 <sys_mkdir+0x54>
    80005b18:	4681                	li	a3,0
    80005b1a:	4601                	li	a2,0
    80005b1c:	4585                	li	a1,1
    80005b1e:	f7040513          	addi	a0,s0,-144
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	7fe080e7          	jalr	2046(ra) # 80005320 <create>
    80005b2a:	cd11                	beqz	a0,80005b46 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	0a0080e7          	jalr	160(ra) # 80003bcc <iunlockput>
  end_op();
    80005b34:	fffff097          	auipc	ra,0xfffff
    80005b38:	872080e7          	jalr	-1934(ra) # 800043a6 <end_op>
  return 0;
    80005b3c:	4501                	li	a0,0
}
    80005b3e:	60aa                	ld	ra,136(sp)
    80005b40:	640a                	ld	s0,128(sp)
    80005b42:	6149                	addi	sp,sp,144
    80005b44:	8082                	ret
    end_op();
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	860080e7          	jalr	-1952(ra) # 800043a6 <end_op>
    return -1;
    80005b4e:	557d                	li	a0,-1
    80005b50:	b7fd                	j	80005b3e <sys_mkdir+0x4c>

0000000080005b52 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b52:	7135                	addi	sp,sp,-160
    80005b54:	ed06                	sd	ra,152(sp)
    80005b56:	e922                	sd	s0,144(sp)
    80005b58:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	7cc080e7          	jalr	1996(ra) # 80004326 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b62:	08000613          	li	a2,128
    80005b66:	f7040593          	addi	a1,s0,-144
    80005b6a:	4501                	li	a0,0
    80005b6c:	ffffd097          	auipc	ra,0xffffd
    80005b70:	268080e7          	jalr	616(ra) # 80002dd4 <argstr>
    80005b74:	04054a63          	bltz	a0,80005bc8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b78:	f6c40593          	addi	a1,s0,-148
    80005b7c:	4505                	li	a0,1
    80005b7e:	ffffd097          	auipc	ra,0xffffd
    80005b82:	212080e7          	jalr	530(ra) # 80002d90 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b86:	04054163          	bltz	a0,80005bc8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b8a:	f6840593          	addi	a1,s0,-152
    80005b8e:	4509                	li	a0,2
    80005b90:	ffffd097          	auipc	ra,0xffffd
    80005b94:	200080e7          	jalr	512(ra) # 80002d90 <argint>
     argint(1, &major) < 0 ||
    80005b98:	02054863          	bltz	a0,80005bc8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b9c:	f6841683          	lh	a3,-152(s0)
    80005ba0:	f6c41603          	lh	a2,-148(s0)
    80005ba4:	458d                	li	a1,3
    80005ba6:	f7040513          	addi	a0,s0,-144
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	776080e7          	jalr	1910(ra) # 80005320 <create>
     argint(2, &minor) < 0 ||
    80005bb2:	c919                	beqz	a0,80005bc8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	018080e7          	jalr	24(ra) # 80003bcc <iunlockput>
  end_op();
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	7ea080e7          	jalr	2026(ra) # 800043a6 <end_op>
  return 0;
    80005bc4:	4501                	li	a0,0
    80005bc6:	a031                	j	80005bd2 <sys_mknod+0x80>
    end_op();
    80005bc8:	ffffe097          	auipc	ra,0xffffe
    80005bcc:	7de080e7          	jalr	2014(ra) # 800043a6 <end_op>
    return -1;
    80005bd0:	557d                	li	a0,-1
}
    80005bd2:	60ea                	ld	ra,152(sp)
    80005bd4:	644a                	ld	s0,144(sp)
    80005bd6:	610d                	addi	sp,sp,160
    80005bd8:	8082                	ret

0000000080005bda <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bda:	7135                	addi	sp,sp,-160
    80005bdc:	ed06                	sd	ra,152(sp)
    80005bde:	e922                	sd	s0,144(sp)
    80005be0:	e526                	sd	s1,136(sp)
    80005be2:	e14a                	sd	s2,128(sp)
    80005be4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005be6:	ffffc097          	auipc	ra,0xffffc
    80005bea:	f82080e7          	jalr	-126(ra) # 80001b68 <myproc>
    80005bee:	892a                	mv	s2,a0
  
  begin_op();
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	736080e7          	jalr	1846(ra) # 80004326 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bf8:	08000613          	li	a2,128
    80005bfc:	f6040593          	addi	a1,s0,-160
    80005c00:	4501                	li	a0,0
    80005c02:	ffffd097          	auipc	ra,0xffffd
    80005c06:	1d2080e7          	jalr	466(ra) # 80002dd4 <argstr>
    80005c0a:	04054b63          	bltz	a0,80005c60 <sys_chdir+0x86>
    80005c0e:	f6040513          	addi	a0,s0,-160
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	508080e7          	jalr	1288(ra) # 8000411a <namei>
    80005c1a:	84aa                	mv	s1,a0
    80005c1c:	c131                	beqz	a0,80005c60 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c1e:	ffffe097          	auipc	ra,0xffffe
    80005c22:	d4c080e7          	jalr	-692(ra) # 8000396a <ilock>
  if(ip->type != T_DIR){
    80005c26:	04449703          	lh	a4,68(s1)
    80005c2a:	4785                	li	a5,1
    80005c2c:	04f71063          	bne	a4,a5,80005c6c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c30:	8526                	mv	a0,s1
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	dfa080e7          	jalr	-518(ra) # 80003a2c <iunlock>
  iput(p->cwd);
    80005c3a:	15093503          	ld	a0,336(s2)
    80005c3e:	ffffe097          	auipc	ra,0xffffe
    80005c42:	ee6080e7          	jalr	-282(ra) # 80003b24 <iput>
  end_op();
    80005c46:	ffffe097          	auipc	ra,0xffffe
    80005c4a:	760080e7          	jalr	1888(ra) # 800043a6 <end_op>
  p->cwd = ip;
    80005c4e:	14993823          	sd	s1,336(s2)
  return 0;
    80005c52:	4501                	li	a0,0
}
    80005c54:	60ea                	ld	ra,152(sp)
    80005c56:	644a                	ld	s0,144(sp)
    80005c58:	64aa                	ld	s1,136(sp)
    80005c5a:	690a                	ld	s2,128(sp)
    80005c5c:	610d                	addi	sp,sp,160
    80005c5e:	8082                	ret
    end_op();
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	746080e7          	jalr	1862(ra) # 800043a6 <end_op>
    return -1;
    80005c68:	557d                	li	a0,-1
    80005c6a:	b7ed                	j	80005c54 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c6c:	8526                	mv	a0,s1
    80005c6e:	ffffe097          	auipc	ra,0xffffe
    80005c72:	f5e080e7          	jalr	-162(ra) # 80003bcc <iunlockput>
    end_op();
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	730080e7          	jalr	1840(ra) # 800043a6 <end_op>
    return -1;
    80005c7e:	557d                	li	a0,-1
    80005c80:	bfd1                	j	80005c54 <sys_chdir+0x7a>

0000000080005c82 <sys_exec>:

uint64
sys_exec(void)
{
    80005c82:	7145                	addi	sp,sp,-464
    80005c84:	e786                	sd	ra,456(sp)
    80005c86:	e3a2                	sd	s0,448(sp)
    80005c88:	ff26                	sd	s1,440(sp)
    80005c8a:	fb4a                	sd	s2,432(sp)
    80005c8c:	f74e                	sd	s3,424(sp)
    80005c8e:	f352                	sd	s4,416(sp)
    80005c90:	ef56                	sd	s5,408(sp)
    80005c92:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c94:	08000613          	li	a2,128
    80005c98:	f4040593          	addi	a1,s0,-192
    80005c9c:	4501                	li	a0,0
    80005c9e:	ffffd097          	auipc	ra,0xffffd
    80005ca2:	136080e7          	jalr	310(ra) # 80002dd4 <argstr>
    return -1;
    80005ca6:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ca8:	0c054a63          	bltz	a0,80005d7c <sys_exec+0xfa>
    80005cac:	e3840593          	addi	a1,s0,-456
    80005cb0:	4505                	li	a0,1
    80005cb2:	ffffd097          	auipc	ra,0xffffd
    80005cb6:	100080e7          	jalr	256(ra) # 80002db2 <argaddr>
    80005cba:	0c054163          	bltz	a0,80005d7c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005cbe:	10000613          	li	a2,256
    80005cc2:	4581                	li	a1,0
    80005cc4:	e4040513          	addi	a0,s0,-448
    80005cc8:	ffffb097          	auipc	ra,0xffffb
    80005ccc:	044080e7          	jalr	68(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cd0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cd4:	89a6                	mv	s3,s1
    80005cd6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cd8:	02000a13          	li	s4,32
    80005cdc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ce0:	00391513          	slli	a0,s2,0x3
    80005ce4:	e3040593          	addi	a1,s0,-464
    80005ce8:	e3843783          	ld	a5,-456(s0)
    80005cec:	953e                	add	a0,a0,a5
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	008080e7          	jalr	8(ra) # 80002cf6 <fetchaddr>
    80005cf6:	02054a63          	bltz	a0,80005d2a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cfa:	e3043783          	ld	a5,-464(s0)
    80005cfe:	c3b9                	beqz	a5,80005d44 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d00:	ffffb097          	auipc	ra,0xffffb
    80005d04:	e20080e7          	jalr	-480(ra) # 80000b20 <kalloc>
    80005d08:	85aa                	mv	a1,a0
    80005d0a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d0e:	cd11                	beqz	a0,80005d2a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d10:	6605                	lui	a2,0x1
    80005d12:	e3043503          	ld	a0,-464(s0)
    80005d16:	ffffd097          	auipc	ra,0xffffd
    80005d1a:	032080e7          	jalr	50(ra) # 80002d48 <fetchstr>
    80005d1e:	00054663          	bltz	a0,80005d2a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d22:	0905                	addi	s2,s2,1
    80005d24:	09a1                	addi	s3,s3,8
    80005d26:	fb491be3          	bne	s2,s4,80005cdc <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d2a:	10048913          	addi	s2,s1,256
    80005d2e:	6088                	ld	a0,0(s1)
    80005d30:	c529                	beqz	a0,80005d7a <sys_exec+0xf8>
    kfree(argv[i]);
    80005d32:	ffffb097          	auipc	ra,0xffffb
    80005d36:	cf2080e7          	jalr	-782(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d3a:	04a1                	addi	s1,s1,8
    80005d3c:	ff2499e3          	bne	s1,s2,80005d2e <sys_exec+0xac>
  return -1;
    80005d40:	597d                	li	s2,-1
    80005d42:	a82d                	j	80005d7c <sys_exec+0xfa>
      argv[i] = 0;
    80005d44:	0a8e                	slli	s5,s5,0x3
    80005d46:	fc040793          	addi	a5,s0,-64
    80005d4a:	9abe                	add	s5,s5,a5
    80005d4c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d50:	e4040593          	addi	a1,s0,-448
    80005d54:	f4040513          	addi	a0,s0,-192
    80005d58:	fffff097          	auipc	ra,0xfffff
    80005d5c:	150080e7          	jalr	336(ra) # 80004ea8 <exec>
    80005d60:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d62:	10048993          	addi	s3,s1,256
    80005d66:	6088                	ld	a0,0(s1)
    80005d68:	c911                	beqz	a0,80005d7c <sys_exec+0xfa>
    kfree(argv[i]);
    80005d6a:	ffffb097          	auipc	ra,0xffffb
    80005d6e:	cba080e7          	jalr	-838(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d72:	04a1                	addi	s1,s1,8
    80005d74:	ff3499e3          	bne	s1,s3,80005d66 <sys_exec+0xe4>
    80005d78:	a011                	j	80005d7c <sys_exec+0xfa>
  return -1;
    80005d7a:	597d                	li	s2,-1
}
    80005d7c:	854a                	mv	a0,s2
    80005d7e:	60be                	ld	ra,456(sp)
    80005d80:	641e                	ld	s0,448(sp)
    80005d82:	74fa                	ld	s1,440(sp)
    80005d84:	795a                	ld	s2,432(sp)
    80005d86:	79ba                	ld	s3,424(sp)
    80005d88:	7a1a                	ld	s4,416(sp)
    80005d8a:	6afa                	ld	s5,408(sp)
    80005d8c:	6179                	addi	sp,sp,464
    80005d8e:	8082                	ret

0000000080005d90 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d90:	7139                	addi	sp,sp,-64
    80005d92:	fc06                	sd	ra,56(sp)
    80005d94:	f822                	sd	s0,48(sp)
    80005d96:	f426                	sd	s1,40(sp)
    80005d98:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d9a:	ffffc097          	auipc	ra,0xffffc
    80005d9e:	dce080e7          	jalr	-562(ra) # 80001b68 <myproc>
    80005da2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005da4:	fd840593          	addi	a1,s0,-40
    80005da8:	4501                	li	a0,0
    80005daa:	ffffd097          	auipc	ra,0xffffd
    80005dae:	008080e7          	jalr	8(ra) # 80002db2 <argaddr>
    return -1;
    80005db2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005db4:	0e054063          	bltz	a0,80005e94 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005db8:	fc840593          	addi	a1,s0,-56
    80005dbc:	fd040513          	addi	a0,s0,-48
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	d8e080e7          	jalr	-626(ra) # 80004b4e <pipealloc>
    return -1;
    80005dc8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005dca:	0c054563          	bltz	a0,80005e94 <sys_pipe+0x104>
  fd0 = -1;
    80005dce:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005dd2:	fd043503          	ld	a0,-48(s0)
    80005dd6:	fffff097          	auipc	ra,0xfffff
    80005dda:	508080e7          	jalr	1288(ra) # 800052de <fdalloc>
    80005dde:	fca42223          	sw	a0,-60(s0)
    80005de2:	08054c63          	bltz	a0,80005e7a <sys_pipe+0xea>
    80005de6:	fc843503          	ld	a0,-56(s0)
    80005dea:	fffff097          	auipc	ra,0xfffff
    80005dee:	4f4080e7          	jalr	1268(ra) # 800052de <fdalloc>
    80005df2:	fca42023          	sw	a0,-64(s0)
    80005df6:	06054863          	bltz	a0,80005e66 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dfa:	4691                	li	a3,4
    80005dfc:	fc440613          	addi	a2,s0,-60
    80005e00:	fd843583          	ld	a1,-40(s0)
    80005e04:	68a8                	ld	a0,80(s1)
    80005e06:	ffffc097          	auipc	ra,0xffffc
    80005e0a:	8de080e7          	jalr	-1826(ra) # 800016e4 <copyout>
    80005e0e:	02054063          	bltz	a0,80005e2e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e12:	4691                	li	a3,4
    80005e14:	fc040613          	addi	a2,s0,-64
    80005e18:	fd843583          	ld	a1,-40(s0)
    80005e1c:	0591                	addi	a1,a1,4
    80005e1e:	68a8                	ld	a0,80(s1)
    80005e20:	ffffc097          	auipc	ra,0xffffc
    80005e24:	8c4080e7          	jalr	-1852(ra) # 800016e4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e28:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e2a:	06055563          	bgez	a0,80005e94 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e2e:	fc442783          	lw	a5,-60(s0)
    80005e32:	07e9                	addi	a5,a5,26
    80005e34:	078e                	slli	a5,a5,0x3
    80005e36:	97a6                	add	a5,a5,s1
    80005e38:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e3c:	fc042503          	lw	a0,-64(s0)
    80005e40:	0569                	addi	a0,a0,26
    80005e42:	050e                	slli	a0,a0,0x3
    80005e44:	9526                	add	a0,a0,s1
    80005e46:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e4a:	fd043503          	ld	a0,-48(s0)
    80005e4e:	fffff097          	auipc	ra,0xfffff
    80005e52:	9aa080e7          	jalr	-1622(ra) # 800047f8 <fileclose>
    fileclose(wf);
    80005e56:	fc843503          	ld	a0,-56(s0)
    80005e5a:	fffff097          	auipc	ra,0xfffff
    80005e5e:	99e080e7          	jalr	-1634(ra) # 800047f8 <fileclose>
    return -1;
    80005e62:	57fd                	li	a5,-1
    80005e64:	a805                	j	80005e94 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e66:	fc442783          	lw	a5,-60(s0)
    80005e6a:	0007c863          	bltz	a5,80005e7a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e6e:	01a78513          	addi	a0,a5,26
    80005e72:	050e                	slli	a0,a0,0x3
    80005e74:	9526                	add	a0,a0,s1
    80005e76:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e7a:	fd043503          	ld	a0,-48(s0)
    80005e7e:	fffff097          	auipc	ra,0xfffff
    80005e82:	97a080e7          	jalr	-1670(ra) # 800047f8 <fileclose>
    fileclose(wf);
    80005e86:	fc843503          	ld	a0,-56(s0)
    80005e8a:	fffff097          	auipc	ra,0xfffff
    80005e8e:	96e080e7          	jalr	-1682(ra) # 800047f8 <fileclose>
    return -1;
    80005e92:	57fd                	li	a5,-1
}
    80005e94:	853e                	mv	a0,a5
    80005e96:	70e2                	ld	ra,56(sp)
    80005e98:	7442                	ld	s0,48(sp)
    80005e9a:	74a2                	ld	s1,40(sp)
    80005e9c:	6121                	addi	sp,sp,64
    80005e9e:	8082                	ret

0000000080005ea0 <kernelvec>:
    80005ea0:	7111                	addi	sp,sp,-256
    80005ea2:	e006                	sd	ra,0(sp)
    80005ea4:	e40a                	sd	sp,8(sp)
    80005ea6:	e80e                	sd	gp,16(sp)
    80005ea8:	ec12                	sd	tp,24(sp)
    80005eaa:	f016                	sd	t0,32(sp)
    80005eac:	f41a                	sd	t1,40(sp)
    80005eae:	f81e                	sd	t2,48(sp)
    80005eb0:	fc22                	sd	s0,56(sp)
    80005eb2:	e0a6                	sd	s1,64(sp)
    80005eb4:	e4aa                	sd	a0,72(sp)
    80005eb6:	e8ae                	sd	a1,80(sp)
    80005eb8:	ecb2                	sd	a2,88(sp)
    80005eba:	f0b6                	sd	a3,96(sp)
    80005ebc:	f4ba                	sd	a4,104(sp)
    80005ebe:	f8be                	sd	a5,112(sp)
    80005ec0:	fcc2                	sd	a6,120(sp)
    80005ec2:	e146                	sd	a7,128(sp)
    80005ec4:	e54a                	sd	s2,136(sp)
    80005ec6:	e94e                	sd	s3,144(sp)
    80005ec8:	ed52                	sd	s4,152(sp)
    80005eca:	f156                	sd	s5,160(sp)
    80005ecc:	f55a                	sd	s6,168(sp)
    80005ece:	f95e                	sd	s7,176(sp)
    80005ed0:	fd62                	sd	s8,184(sp)
    80005ed2:	e1e6                	sd	s9,192(sp)
    80005ed4:	e5ea                	sd	s10,200(sp)
    80005ed6:	e9ee                	sd	s11,208(sp)
    80005ed8:	edf2                	sd	t3,216(sp)
    80005eda:	f1f6                	sd	t4,224(sp)
    80005edc:	f5fa                	sd	t5,232(sp)
    80005ede:	f9fe                	sd	t6,240(sp)
    80005ee0:	ce3fc0ef          	jal	ra,80002bc2 <kerneltrap>
    80005ee4:	6082                	ld	ra,0(sp)
    80005ee6:	6122                	ld	sp,8(sp)
    80005ee8:	61c2                	ld	gp,16(sp)
    80005eea:	7282                	ld	t0,32(sp)
    80005eec:	7322                	ld	t1,40(sp)
    80005eee:	73c2                	ld	t2,48(sp)
    80005ef0:	7462                	ld	s0,56(sp)
    80005ef2:	6486                	ld	s1,64(sp)
    80005ef4:	6526                	ld	a0,72(sp)
    80005ef6:	65c6                	ld	a1,80(sp)
    80005ef8:	6666                	ld	a2,88(sp)
    80005efa:	7686                	ld	a3,96(sp)
    80005efc:	7726                	ld	a4,104(sp)
    80005efe:	77c6                	ld	a5,112(sp)
    80005f00:	7866                	ld	a6,120(sp)
    80005f02:	688a                	ld	a7,128(sp)
    80005f04:	692a                	ld	s2,136(sp)
    80005f06:	69ca                	ld	s3,144(sp)
    80005f08:	6a6a                	ld	s4,152(sp)
    80005f0a:	7a8a                	ld	s5,160(sp)
    80005f0c:	7b2a                	ld	s6,168(sp)
    80005f0e:	7bca                	ld	s7,176(sp)
    80005f10:	7c6a                	ld	s8,184(sp)
    80005f12:	6c8e                	ld	s9,192(sp)
    80005f14:	6d2e                	ld	s10,200(sp)
    80005f16:	6dce                	ld	s11,208(sp)
    80005f18:	6e6e                	ld	t3,216(sp)
    80005f1a:	7e8e                	ld	t4,224(sp)
    80005f1c:	7f2e                	ld	t5,232(sp)
    80005f1e:	7fce                	ld	t6,240(sp)
    80005f20:	6111                	addi	sp,sp,256
    80005f22:	10200073          	sret
    80005f26:	00000013          	nop
    80005f2a:	00000013          	nop
    80005f2e:	0001                	nop

0000000080005f30 <timervec>:
    80005f30:	34051573          	csrrw	a0,mscratch,a0
    80005f34:	e10c                	sd	a1,0(a0)
    80005f36:	e510                	sd	a2,8(a0)
    80005f38:	e914                	sd	a3,16(a0)
    80005f3a:	710c                	ld	a1,32(a0)
    80005f3c:	7510                	ld	a2,40(a0)
    80005f3e:	6194                	ld	a3,0(a1)
    80005f40:	96b2                	add	a3,a3,a2
    80005f42:	e194                	sd	a3,0(a1)
    80005f44:	4589                	li	a1,2
    80005f46:	14459073          	csrw	sip,a1
    80005f4a:	6914                	ld	a3,16(a0)
    80005f4c:	6510                	ld	a2,8(a0)
    80005f4e:	610c                	ld	a1,0(a0)
    80005f50:	34051573          	csrrw	a0,mscratch,a0
    80005f54:	30200073          	mret
	...

0000000080005f5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f5a:	1141                	addi	sp,sp,-16
    80005f5c:	e422                	sd	s0,8(sp)
    80005f5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f60:	0c0007b7          	lui	a5,0xc000
    80005f64:	4705                	li	a4,1
    80005f66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f68:	c3d8                	sw	a4,4(a5)
}
    80005f6a:	6422                	ld	s0,8(sp)
    80005f6c:	0141                	addi	sp,sp,16
    80005f6e:	8082                	ret

0000000080005f70 <plicinithart>:

void
plicinithart(void)
{
    80005f70:	1141                	addi	sp,sp,-16
    80005f72:	e406                	sd	ra,8(sp)
    80005f74:	e022                	sd	s0,0(sp)
    80005f76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f78:	ffffc097          	auipc	ra,0xffffc
    80005f7c:	bc4080e7          	jalr	-1084(ra) # 80001b3c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f80:	0085171b          	slliw	a4,a0,0x8
    80005f84:	0c0027b7          	lui	a5,0xc002
    80005f88:	97ba                	add	a5,a5,a4
    80005f8a:	40200713          	li	a4,1026
    80005f8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f92:	00d5151b          	slliw	a0,a0,0xd
    80005f96:	0c2017b7          	lui	a5,0xc201
    80005f9a:	953e                	add	a0,a0,a5
    80005f9c:	00052023          	sw	zero,0(a0)
}
    80005fa0:	60a2                	ld	ra,8(sp)
    80005fa2:	6402                	ld	s0,0(sp)
    80005fa4:	0141                	addi	sp,sp,16
    80005fa6:	8082                	ret

0000000080005fa8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fa8:	1141                	addi	sp,sp,-16
    80005faa:	e406                	sd	ra,8(sp)
    80005fac:	e022                	sd	s0,0(sp)
    80005fae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fb0:	ffffc097          	auipc	ra,0xffffc
    80005fb4:	b8c080e7          	jalr	-1140(ra) # 80001b3c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fb8:	00d5179b          	slliw	a5,a0,0xd
    80005fbc:	0c201537          	lui	a0,0xc201
    80005fc0:	953e                	add	a0,a0,a5
  return irq;
}
    80005fc2:	4148                	lw	a0,4(a0)
    80005fc4:	60a2                	ld	ra,8(sp)
    80005fc6:	6402                	ld	s0,0(sp)
    80005fc8:	0141                	addi	sp,sp,16
    80005fca:	8082                	ret

0000000080005fcc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fcc:	1101                	addi	sp,sp,-32
    80005fce:	ec06                	sd	ra,24(sp)
    80005fd0:	e822                	sd	s0,16(sp)
    80005fd2:	e426                	sd	s1,8(sp)
    80005fd4:	1000                	addi	s0,sp,32
    80005fd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fd8:	ffffc097          	auipc	ra,0xffffc
    80005fdc:	b64080e7          	jalr	-1180(ra) # 80001b3c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fe0:	00d5151b          	slliw	a0,a0,0xd
    80005fe4:	0c2017b7          	lui	a5,0xc201
    80005fe8:	97aa                	add	a5,a5,a0
    80005fea:	c3c4                	sw	s1,4(a5)
}
    80005fec:	60e2                	ld	ra,24(sp)
    80005fee:	6442                	ld	s0,16(sp)
    80005ff0:	64a2                	ld	s1,8(sp)
    80005ff2:	6105                	addi	sp,sp,32
    80005ff4:	8082                	ret

0000000080005ff6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ff6:	1141                	addi	sp,sp,-16
    80005ff8:	e406                	sd	ra,8(sp)
    80005ffa:	e022                	sd	s0,0(sp)
    80005ffc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ffe:	479d                	li	a5,7
    80006000:	04a7cc63          	blt	a5,a0,80006058 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80006004:	0001d797          	auipc	a5,0x1d
    80006008:	ffc78793          	addi	a5,a5,-4 # 80023000 <disk>
    8000600c:	00a78733          	add	a4,a5,a0
    80006010:	6789                	lui	a5,0x2
    80006012:	97ba                	add	a5,a5,a4
    80006014:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006018:	eba1                	bnez	a5,80006068 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    8000601a:	00451713          	slli	a4,a0,0x4
    8000601e:	0001f797          	auipc	a5,0x1f
    80006022:	fe27b783          	ld	a5,-30(a5) # 80025000 <disk+0x2000>
    80006026:	97ba                	add	a5,a5,a4
    80006028:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    8000602c:	0001d797          	auipc	a5,0x1d
    80006030:	fd478793          	addi	a5,a5,-44 # 80023000 <disk>
    80006034:	97aa                	add	a5,a5,a0
    80006036:	6509                	lui	a0,0x2
    80006038:	953e                	add	a0,a0,a5
    8000603a:	4785                	li	a5,1
    8000603c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006040:	0001f517          	auipc	a0,0x1f
    80006044:	fd850513          	addi	a0,a0,-40 # 80025018 <disk+0x2018>
    80006048:	ffffc097          	auipc	ra,0xffffc
    8000604c:	122080e7          	jalr	290(ra) # 8000216a <wakeup>
}
    80006050:	60a2                	ld	ra,8(sp)
    80006052:	6402                	ld	s0,0(sp)
    80006054:	0141                	addi	sp,sp,16
    80006056:	8082                	ret
    panic("virtio_disk_intr 1");
    80006058:	00002517          	auipc	a0,0x2
    8000605c:	75850513          	addi	a0,a0,1880 # 800087b0 <syscalls+0x328>
    80006060:	ffffa097          	auipc	ra,0xffffa
    80006064:	4e8080e7          	jalr	1256(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80006068:	00002517          	auipc	a0,0x2
    8000606c:	76050513          	addi	a0,a0,1888 # 800087c8 <syscalls+0x340>
    80006070:	ffffa097          	auipc	ra,0xffffa
    80006074:	4d8080e7          	jalr	1240(ra) # 80000548 <panic>

0000000080006078 <virtio_disk_init>:
{
    80006078:	1101                	addi	sp,sp,-32
    8000607a:	ec06                	sd	ra,24(sp)
    8000607c:	e822                	sd	s0,16(sp)
    8000607e:	e426                	sd	s1,8(sp)
    80006080:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006082:	00002597          	auipc	a1,0x2
    80006086:	75e58593          	addi	a1,a1,1886 # 800087e0 <syscalls+0x358>
    8000608a:	0001f517          	auipc	a0,0x1f
    8000608e:	01e50513          	addi	a0,a0,30 # 800250a8 <disk+0x20a8>
    80006092:	ffffb097          	auipc	ra,0xffffb
    80006096:	aee080e7          	jalr	-1298(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000609a:	100017b7          	lui	a5,0x10001
    8000609e:	4398                	lw	a4,0(a5)
    800060a0:	2701                	sext.w	a4,a4
    800060a2:	747277b7          	lui	a5,0x74727
    800060a6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060aa:	0ef71163          	bne	a4,a5,8000618c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060ae:	100017b7          	lui	a5,0x10001
    800060b2:	43dc                	lw	a5,4(a5)
    800060b4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060b6:	4705                	li	a4,1
    800060b8:	0ce79a63          	bne	a5,a4,8000618c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060bc:	100017b7          	lui	a5,0x10001
    800060c0:	479c                	lw	a5,8(a5)
    800060c2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060c4:	4709                	li	a4,2
    800060c6:	0ce79363          	bne	a5,a4,8000618c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060ca:	100017b7          	lui	a5,0x10001
    800060ce:	47d8                	lw	a4,12(a5)
    800060d0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060d2:	554d47b7          	lui	a5,0x554d4
    800060d6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060da:	0af71963          	bne	a4,a5,8000618c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060de:	100017b7          	lui	a5,0x10001
    800060e2:	4705                	li	a4,1
    800060e4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060e6:	470d                	li	a4,3
    800060e8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060ea:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060ec:	c7ffe737          	lui	a4,0xc7ffe
    800060f0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    800060f4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060f6:	2701                	sext.w	a4,a4
    800060f8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060fa:	472d                	li	a4,11
    800060fc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060fe:	473d                	li	a4,15
    80006100:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006102:	6705                	lui	a4,0x1
    80006104:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006106:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000610a:	5bdc                	lw	a5,52(a5)
    8000610c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000610e:	c7d9                	beqz	a5,8000619c <virtio_disk_init+0x124>
  if(max < NUM)
    80006110:	471d                	li	a4,7
    80006112:	08f77d63          	bgeu	a4,a5,800061ac <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006116:	100014b7          	lui	s1,0x10001
    8000611a:	47a1                	li	a5,8
    8000611c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000611e:	6609                	lui	a2,0x2
    80006120:	4581                	li	a1,0
    80006122:	0001d517          	auipc	a0,0x1d
    80006126:	ede50513          	addi	a0,a0,-290 # 80023000 <disk>
    8000612a:	ffffb097          	auipc	ra,0xffffb
    8000612e:	be2080e7          	jalr	-1054(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006132:	0001d717          	auipc	a4,0x1d
    80006136:	ece70713          	addi	a4,a4,-306 # 80023000 <disk>
    8000613a:	00c75793          	srli	a5,a4,0xc
    8000613e:	2781                	sext.w	a5,a5
    80006140:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006142:	0001f797          	auipc	a5,0x1f
    80006146:	ebe78793          	addi	a5,a5,-322 # 80025000 <disk+0x2000>
    8000614a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000614c:	0001d717          	auipc	a4,0x1d
    80006150:	f3470713          	addi	a4,a4,-204 # 80023080 <disk+0x80>
    80006154:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006156:	0001e717          	auipc	a4,0x1e
    8000615a:	eaa70713          	addi	a4,a4,-342 # 80024000 <disk+0x1000>
    8000615e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006160:	4705                	li	a4,1
    80006162:	00e78c23          	sb	a4,24(a5)
    80006166:	00e78ca3          	sb	a4,25(a5)
    8000616a:	00e78d23          	sb	a4,26(a5)
    8000616e:	00e78da3          	sb	a4,27(a5)
    80006172:	00e78e23          	sb	a4,28(a5)
    80006176:	00e78ea3          	sb	a4,29(a5)
    8000617a:	00e78f23          	sb	a4,30(a5)
    8000617e:	00e78fa3          	sb	a4,31(a5)
}
    80006182:	60e2                	ld	ra,24(sp)
    80006184:	6442                	ld	s0,16(sp)
    80006186:	64a2                	ld	s1,8(sp)
    80006188:	6105                	addi	sp,sp,32
    8000618a:	8082                	ret
    panic("could not find virtio disk");
    8000618c:	00002517          	auipc	a0,0x2
    80006190:	66450513          	addi	a0,a0,1636 # 800087f0 <syscalls+0x368>
    80006194:	ffffa097          	auipc	ra,0xffffa
    80006198:	3b4080e7          	jalr	948(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    8000619c:	00002517          	auipc	a0,0x2
    800061a0:	67450513          	addi	a0,a0,1652 # 80008810 <syscalls+0x388>
    800061a4:	ffffa097          	auipc	ra,0xffffa
    800061a8:	3a4080e7          	jalr	932(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    800061ac:	00002517          	auipc	a0,0x2
    800061b0:	68450513          	addi	a0,a0,1668 # 80008830 <syscalls+0x3a8>
    800061b4:	ffffa097          	auipc	ra,0xffffa
    800061b8:	394080e7          	jalr	916(ra) # 80000548 <panic>

00000000800061bc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061bc:	7119                	addi	sp,sp,-128
    800061be:	fc86                	sd	ra,120(sp)
    800061c0:	f8a2                	sd	s0,112(sp)
    800061c2:	f4a6                	sd	s1,104(sp)
    800061c4:	f0ca                	sd	s2,96(sp)
    800061c6:	ecce                	sd	s3,88(sp)
    800061c8:	e8d2                	sd	s4,80(sp)
    800061ca:	e4d6                	sd	s5,72(sp)
    800061cc:	e0da                	sd	s6,64(sp)
    800061ce:	fc5e                	sd	s7,56(sp)
    800061d0:	f862                	sd	s8,48(sp)
    800061d2:	f466                	sd	s9,40(sp)
    800061d4:	f06a                	sd	s10,32(sp)
    800061d6:	0100                	addi	s0,sp,128
    800061d8:	892a                	mv	s2,a0
    800061da:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061dc:	00c52c83          	lw	s9,12(a0)
    800061e0:	001c9c9b          	slliw	s9,s9,0x1
    800061e4:	1c82                	slli	s9,s9,0x20
    800061e6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061ea:	0001f517          	auipc	a0,0x1f
    800061ee:	ebe50513          	addi	a0,a0,-322 # 800250a8 <disk+0x20a8>
    800061f2:	ffffb097          	auipc	ra,0xffffb
    800061f6:	a1e080e7          	jalr	-1506(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    800061fa:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061fc:	4c21                	li	s8,8
      disk.free[i] = 0;
    800061fe:	0001db97          	auipc	s7,0x1d
    80006202:	e02b8b93          	addi	s7,s7,-510 # 80023000 <disk>
    80006206:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006208:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000620a:	8a4e                	mv	s4,s3
    8000620c:	a051                	j	80006290 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000620e:	00fb86b3          	add	a3,s7,a5
    80006212:	96da                	add	a3,a3,s6
    80006214:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006218:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000621a:	0207c563          	bltz	a5,80006244 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000621e:	2485                	addiw	s1,s1,1
    80006220:	0711                	addi	a4,a4,4
    80006222:	23548d63          	beq	s1,s5,8000645c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006226:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006228:	0001f697          	auipc	a3,0x1f
    8000622c:	df068693          	addi	a3,a3,-528 # 80025018 <disk+0x2018>
    80006230:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006232:	0006c583          	lbu	a1,0(a3)
    80006236:	fde1                	bnez	a1,8000620e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006238:	2785                	addiw	a5,a5,1
    8000623a:	0685                	addi	a3,a3,1
    8000623c:	ff879be3          	bne	a5,s8,80006232 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006240:	57fd                	li	a5,-1
    80006242:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006244:	02905a63          	blez	s1,80006278 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006248:	f9042503          	lw	a0,-112(s0)
    8000624c:	00000097          	auipc	ra,0x0
    80006250:	daa080e7          	jalr	-598(ra) # 80005ff6 <free_desc>
      for(int j = 0; j < i; j++)
    80006254:	4785                	li	a5,1
    80006256:	0297d163          	bge	a5,s1,80006278 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000625a:	f9442503          	lw	a0,-108(s0)
    8000625e:	00000097          	auipc	ra,0x0
    80006262:	d98080e7          	jalr	-616(ra) # 80005ff6 <free_desc>
      for(int j = 0; j < i; j++)
    80006266:	4789                	li	a5,2
    80006268:	0097d863          	bge	a5,s1,80006278 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000626c:	f9842503          	lw	a0,-104(s0)
    80006270:	00000097          	auipc	ra,0x0
    80006274:	d86080e7          	jalr	-634(ra) # 80005ff6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006278:	0001f597          	auipc	a1,0x1f
    8000627c:	e3058593          	addi	a1,a1,-464 # 800250a8 <disk+0x20a8>
    80006280:	0001f517          	auipc	a0,0x1f
    80006284:	d9850513          	addi	a0,a0,-616 # 80025018 <disk+0x2018>
    80006288:	ffffc097          	auipc	ra,0xffffc
    8000628c:	e64080e7          	jalr	-412(ra) # 800020ec <sleep>
  for(int i = 0; i < 3; i++){
    80006290:	f9040713          	addi	a4,s0,-112
    80006294:	84ce                	mv	s1,s3
    80006296:	bf41                	j	80006226 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006298:	4785                	li	a5,1
    8000629a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000629e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800062a2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800062a6:	f9042983          	lw	s3,-112(s0)
    800062aa:	00499493          	slli	s1,s3,0x4
    800062ae:	0001fa17          	auipc	s4,0x1f
    800062b2:	d52a0a13          	addi	s4,s4,-686 # 80025000 <disk+0x2000>
    800062b6:	000a3a83          	ld	s5,0(s4)
    800062ba:	9aa6                	add	s5,s5,s1
    800062bc:	f8040513          	addi	a0,s0,-128
    800062c0:	ffffb097          	auipc	ra,0xffffb
    800062c4:	e28080e7          	jalr	-472(ra) # 800010e8 <kvmpa>
    800062c8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800062cc:	000a3783          	ld	a5,0(s4)
    800062d0:	97a6                	add	a5,a5,s1
    800062d2:	4741                	li	a4,16
    800062d4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062d6:	000a3783          	ld	a5,0(s4)
    800062da:	97a6                	add	a5,a5,s1
    800062dc:	4705                	li	a4,1
    800062de:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800062e2:	f9442703          	lw	a4,-108(s0)
    800062e6:	000a3783          	ld	a5,0(s4)
    800062ea:	97a6                	add	a5,a5,s1
    800062ec:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062f0:	0712                	slli	a4,a4,0x4
    800062f2:	000a3783          	ld	a5,0(s4)
    800062f6:	97ba                	add	a5,a5,a4
    800062f8:	05890693          	addi	a3,s2,88
    800062fc:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800062fe:	000a3783          	ld	a5,0(s4)
    80006302:	97ba                	add	a5,a5,a4
    80006304:	40000693          	li	a3,1024
    80006308:	c794                	sw	a3,8(a5)
  if(write)
    8000630a:	100d0a63          	beqz	s10,8000641e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000630e:	0001f797          	auipc	a5,0x1f
    80006312:	cf27b783          	ld	a5,-782(a5) # 80025000 <disk+0x2000>
    80006316:	97ba                	add	a5,a5,a4
    80006318:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000631c:	0001d517          	auipc	a0,0x1d
    80006320:	ce450513          	addi	a0,a0,-796 # 80023000 <disk>
    80006324:	0001f797          	auipc	a5,0x1f
    80006328:	cdc78793          	addi	a5,a5,-804 # 80025000 <disk+0x2000>
    8000632c:	6394                	ld	a3,0(a5)
    8000632e:	96ba                	add	a3,a3,a4
    80006330:	00c6d603          	lhu	a2,12(a3)
    80006334:	00166613          	ori	a2,a2,1
    80006338:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000633c:	f9842683          	lw	a3,-104(s0)
    80006340:	6390                	ld	a2,0(a5)
    80006342:	9732                	add	a4,a4,a2
    80006344:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006348:	20098613          	addi	a2,s3,512
    8000634c:	0612                	slli	a2,a2,0x4
    8000634e:	962a                	add	a2,a2,a0
    80006350:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006354:	00469713          	slli	a4,a3,0x4
    80006358:	6394                	ld	a3,0(a5)
    8000635a:	96ba                	add	a3,a3,a4
    8000635c:	6589                	lui	a1,0x2
    8000635e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006362:	94ae                	add	s1,s1,a1
    80006364:	94aa                	add	s1,s1,a0
    80006366:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006368:	6394                	ld	a3,0(a5)
    8000636a:	96ba                	add	a3,a3,a4
    8000636c:	4585                	li	a1,1
    8000636e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006370:	6394                	ld	a3,0(a5)
    80006372:	96ba                	add	a3,a3,a4
    80006374:	4509                	li	a0,2
    80006376:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000637a:	6394                	ld	a3,0(a5)
    8000637c:	9736                	add	a4,a4,a3
    8000637e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006382:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006386:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000638a:	6794                	ld	a3,8(a5)
    8000638c:	0026d703          	lhu	a4,2(a3)
    80006390:	8b1d                	andi	a4,a4,7
    80006392:	2709                	addiw	a4,a4,2
    80006394:	0706                	slli	a4,a4,0x1
    80006396:	9736                	add	a4,a4,a3
    80006398:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000639c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800063a0:	6798                	ld	a4,8(a5)
    800063a2:	00275783          	lhu	a5,2(a4)
    800063a6:	2785                	addiw	a5,a5,1
    800063a8:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800063ac:	100017b7          	lui	a5,0x10001
    800063b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063b4:	00492703          	lw	a4,4(s2)
    800063b8:	4785                	li	a5,1
    800063ba:	02f71163          	bne	a4,a5,800063dc <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800063be:	0001f997          	auipc	s3,0x1f
    800063c2:	cea98993          	addi	s3,s3,-790 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800063c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063c8:	85ce                	mv	a1,s3
    800063ca:	854a                	mv	a0,s2
    800063cc:	ffffc097          	auipc	ra,0xffffc
    800063d0:	d20080e7          	jalr	-736(ra) # 800020ec <sleep>
  while(b->disk == 1) {
    800063d4:	00492783          	lw	a5,4(s2)
    800063d8:	fe9788e3          	beq	a5,s1,800063c8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800063dc:	f9042483          	lw	s1,-112(s0)
    800063e0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800063e4:	00479713          	slli	a4,a5,0x4
    800063e8:	0001d797          	auipc	a5,0x1d
    800063ec:	c1878793          	addi	a5,a5,-1000 # 80023000 <disk>
    800063f0:	97ba                	add	a5,a5,a4
    800063f2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800063f6:	0001f917          	auipc	s2,0x1f
    800063fa:	c0a90913          	addi	s2,s2,-1014 # 80025000 <disk+0x2000>
    free_desc(i);
    800063fe:	8526                	mv	a0,s1
    80006400:	00000097          	auipc	ra,0x0
    80006404:	bf6080e7          	jalr	-1034(ra) # 80005ff6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006408:	0492                	slli	s1,s1,0x4
    8000640a:	00093783          	ld	a5,0(s2)
    8000640e:	94be                	add	s1,s1,a5
    80006410:	00c4d783          	lhu	a5,12(s1)
    80006414:	8b85                	andi	a5,a5,1
    80006416:	cf89                	beqz	a5,80006430 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006418:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000641c:	b7cd                	j	800063fe <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000641e:	0001f797          	auipc	a5,0x1f
    80006422:	be27b783          	ld	a5,-1054(a5) # 80025000 <disk+0x2000>
    80006426:	97ba                	add	a5,a5,a4
    80006428:	4689                	li	a3,2
    8000642a:	00d79623          	sh	a3,12(a5)
    8000642e:	b5fd                	j	8000631c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006430:	0001f517          	auipc	a0,0x1f
    80006434:	c7850513          	addi	a0,a0,-904 # 800250a8 <disk+0x20a8>
    80006438:	ffffb097          	auipc	ra,0xffffb
    8000643c:	88c080e7          	jalr	-1908(ra) # 80000cc4 <release>
}
    80006440:	70e6                	ld	ra,120(sp)
    80006442:	7446                	ld	s0,112(sp)
    80006444:	74a6                	ld	s1,104(sp)
    80006446:	7906                	ld	s2,96(sp)
    80006448:	69e6                	ld	s3,88(sp)
    8000644a:	6a46                	ld	s4,80(sp)
    8000644c:	6aa6                	ld	s5,72(sp)
    8000644e:	6b06                	ld	s6,64(sp)
    80006450:	7be2                	ld	s7,56(sp)
    80006452:	7c42                	ld	s8,48(sp)
    80006454:	7ca2                	ld	s9,40(sp)
    80006456:	7d02                	ld	s10,32(sp)
    80006458:	6109                	addi	sp,sp,128
    8000645a:	8082                	ret
  if(write)
    8000645c:	e20d1ee3          	bnez	s10,80006298 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006460:	f8042023          	sw	zero,-128(s0)
    80006464:	bd2d                	j	8000629e <virtio_disk_rw+0xe2>

0000000080006466 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006466:	1101                	addi	sp,sp,-32
    80006468:	ec06                	sd	ra,24(sp)
    8000646a:	e822                	sd	s0,16(sp)
    8000646c:	e426                	sd	s1,8(sp)
    8000646e:	e04a                	sd	s2,0(sp)
    80006470:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006472:	0001f517          	auipc	a0,0x1f
    80006476:	c3650513          	addi	a0,a0,-970 # 800250a8 <disk+0x20a8>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	796080e7          	jalr	1942(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006482:	0001f717          	auipc	a4,0x1f
    80006486:	b7e70713          	addi	a4,a4,-1154 # 80025000 <disk+0x2000>
    8000648a:	02075783          	lhu	a5,32(a4)
    8000648e:	6b18                	ld	a4,16(a4)
    80006490:	00275683          	lhu	a3,2(a4)
    80006494:	8ebd                	xor	a3,a3,a5
    80006496:	8a9d                	andi	a3,a3,7
    80006498:	cab9                	beqz	a3,800064ee <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000649a:	0001d917          	auipc	s2,0x1d
    8000649e:	b6690913          	addi	s2,s2,-1178 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800064a2:	0001f497          	auipc	s1,0x1f
    800064a6:	b5e48493          	addi	s1,s1,-1186 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800064aa:	078e                	slli	a5,a5,0x3
    800064ac:	97ba                	add	a5,a5,a4
    800064ae:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800064b0:	20078713          	addi	a4,a5,512
    800064b4:	0712                	slli	a4,a4,0x4
    800064b6:	974a                	add	a4,a4,s2
    800064b8:	03074703          	lbu	a4,48(a4)
    800064bc:	ef21                	bnez	a4,80006514 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800064be:	20078793          	addi	a5,a5,512
    800064c2:	0792                	slli	a5,a5,0x4
    800064c4:	97ca                	add	a5,a5,s2
    800064c6:	7798                	ld	a4,40(a5)
    800064c8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800064cc:	7788                	ld	a0,40(a5)
    800064ce:	ffffc097          	auipc	ra,0xffffc
    800064d2:	c9c080e7          	jalr	-868(ra) # 8000216a <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800064d6:	0204d783          	lhu	a5,32(s1)
    800064da:	2785                	addiw	a5,a5,1
    800064dc:	8b9d                	andi	a5,a5,7
    800064de:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800064e2:	6898                	ld	a4,16(s1)
    800064e4:	00275683          	lhu	a3,2(a4)
    800064e8:	8a9d                	andi	a3,a3,7
    800064ea:	fcf690e3          	bne	a3,a5,800064aa <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064ee:	10001737          	lui	a4,0x10001
    800064f2:	533c                	lw	a5,96(a4)
    800064f4:	8b8d                	andi	a5,a5,3
    800064f6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800064f8:	0001f517          	auipc	a0,0x1f
    800064fc:	bb050513          	addi	a0,a0,-1104 # 800250a8 <disk+0x20a8>
    80006500:	ffffa097          	auipc	ra,0xffffa
    80006504:	7c4080e7          	jalr	1988(ra) # 80000cc4 <release>
}
    80006508:	60e2                	ld	ra,24(sp)
    8000650a:	6442                	ld	s0,16(sp)
    8000650c:	64a2                	ld	s1,8(sp)
    8000650e:	6902                	ld	s2,0(sp)
    80006510:	6105                	addi	sp,sp,32
    80006512:	8082                	ret
      panic("virtio_disk_intr status");
    80006514:	00002517          	auipc	a0,0x2
    80006518:	33c50513          	addi	a0,a0,828 # 80008850 <syscalls+0x3c8>
    8000651c:	ffffa097          	auipc	ra,0xffffa
    80006520:	02c080e7          	jalr	44(ra) # 80000548 <panic>

0000000080006524 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    80006524:	7179                	addi	sp,sp,-48
    80006526:	f406                	sd	ra,40(sp)
    80006528:	f022                	sd	s0,32(sp)
    8000652a:	ec26                	sd	s1,24(sp)
    8000652c:	e84a                	sd	s2,16(sp)
    8000652e:	e44e                	sd	s3,8(sp)
    80006530:	e052                	sd	s4,0(sp)
    80006532:	1800                	addi	s0,sp,48
    80006534:	892a                	mv	s2,a0
    80006536:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006538:	00003a17          	auipc	s4,0x3
    8000653c:	af0a0a13          	addi	s4,s4,-1296 # 80009028 <stats>
    80006540:	000a2683          	lw	a3,0(s4)
    80006544:	00002617          	auipc	a2,0x2
    80006548:	32460613          	addi	a2,a2,804 # 80008868 <syscalls+0x3e0>
    8000654c:	00000097          	auipc	ra,0x0
    80006550:	2c2080e7          	jalr	706(ra) # 8000680e <snprintf>
    80006554:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    80006556:	004a2683          	lw	a3,4(s4)
    8000655a:	00002617          	auipc	a2,0x2
    8000655e:	31e60613          	addi	a2,a2,798 # 80008878 <syscalls+0x3f0>
    80006562:	85ce                	mv	a1,s3
    80006564:	954a                	add	a0,a0,s2
    80006566:	00000097          	auipc	ra,0x0
    8000656a:	2a8080e7          	jalr	680(ra) # 8000680e <snprintf>
  return n;
}
    8000656e:	9d25                	addw	a0,a0,s1
    80006570:	70a2                	ld	ra,40(sp)
    80006572:	7402                	ld	s0,32(sp)
    80006574:	64e2                	ld	s1,24(sp)
    80006576:	6942                	ld	s2,16(sp)
    80006578:	69a2                	ld	s3,8(sp)
    8000657a:	6a02                	ld	s4,0(sp)
    8000657c:	6145                	addi	sp,sp,48
    8000657e:	8082                	ret

0000000080006580 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80006580:	7179                	addi	sp,sp,-48
    80006582:	f406                	sd	ra,40(sp)
    80006584:	f022                	sd	s0,32(sp)
    80006586:	ec26                	sd	s1,24(sp)
    80006588:	e84a                	sd	s2,16(sp)
    8000658a:	e44e                	sd	s3,8(sp)
    8000658c:	1800                	addi	s0,sp,48
    8000658e:	89ae                	mv	s3,a1
    80006590:	84b2                	mv	s1,a2
    80006592:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006594:	ffffb097          	auipc	ra,0xffffb
    80006598:	5d4080e7          	jalr	1492(ra) # 80001b68 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    8000659c:	653c                	ld	a5,72(a0)
    8000659e:	02f4ff63          	bgeu	s1,a5,800065dc <copyin_new+0x5c>
    800065a2:	01248733          	add	a4,s1,s2
    800065a6:	02f77d63          	bgeu	a4,a5,800065e0 <copyin_new+0x60>
    800065aa:	02976d63          	bltu	a4,s1,800065e4 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    800065ae:	0009061b          	sext.w	a2,s2
    800065b2:	85a6                	mv	a1,s1
    800065b4:	854e                	mv	a0,s3
    800065b6:	ffffa097          	auipc	ra,0xffffa
    800065ba:	7b6080e7          	jalr	1974(ra) # 80000d6c <memmove>
  stats.ncopyin++;   // XXX lock
    800065be:	00003717          	auipc	a4,0x3
    800065c2:	a6a70713          	addi	a4,a4,-1430 # 80009028 <stats>
    800065c6:	431c                	lw	a5,0(a4)
    800065c8:	2785                	addiw	a5,a5,1
    800065ca:	c31c                	sw	a5,0(a4)
  return 0;
    800065cc:	4501                	li	a0,0
}
    800065ce:	70a2                	ld	ra,40(sp)
    800065d0:	7402                	ld	s0,32(sp)
    800065d2:	64e2                	ld	s1,24(sp)
    800065d4:	6942                	ld	s2,16(sp)
    800065d6:	69a2                	ld	s3,8(sp)
    800065d8:	6145                	addi	sp,sp,48
    800065da:	8082                	ret
    return -1;
    800065dc:	557d                	li	a0,-1
    800065de:	bfc5                	j	800065ce <copyin_new+0x4e>
    800065e0:	557d                	li	a0,-1
    800065e2:	b7f5                	j	800065ce <copyin_new+0x4e>
    800065e4:	557d                	li	a0,-1
    800065e6:	b7e5                	j	800065ce <copyin_new+0x4e>

00000000800065e8 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800065e8:	7179                	addi	sp,sp,-48
    800065ea:	f406                	sd	ra,40(sp)
    800065ec:	f022                	sd	s0,32(sp)
    800065ee:	ec26                	sd	s1,24(sp)
    800065f0:	e84a                	sd	s2,16(sp)
    800065f2:	e44e                	sd	s3,8(sp)
    800065f4:	1800                	addi	s0,sp,48
    800065f6:	89ae                	mv	s3,a1
    800065f8:	8932                	mv	s2,a2
    800065fa:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    800065fc:	ffffb097          	auipc	ra,0xffffb
    80006600:	56c080e7          	jalr	1388(ra) # 80001b68 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    80006604:	00003717          	auipc	a4,0x3
    80006608:	a2470713          	addi	a4,a4,-1500 # 80009028 <stats>
    8000660c:	435c                	lw	a5,4(a4)
    8000660e:	2785                	addiw	a5,a5,1
    80006610:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006612:	cc85                	beqz	s1,8000664a <copyinstr_new+0x62>
    80006614:	00990833          	add	a6,s2,s1
    80006618:	87ca                	mv	a5,s2
    8000661a:	6538                	ld	a4,72(a0)
    8000661c:	00e7ff63          	bgeu	a5,a4,8000663a <copyinstr_new+0x52>
    dst[i] = s[i];
    80006620:	0007c683          	lbu	a3,0(a5)
    80006624:	41278733          	sub	a4,a5,s2
    80006628:	974e                	add	a4,a4,s3
    8000662a:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    8000662e:	c285                	beqz	a3,8000664e <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006630:	0785                	addi	a5,a5,1
    80006632:	ff0794e3          	bne	a5,a6,8000661a <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    80006636:	557d                	li	a0,-1
    80006638:	a011                	j	8000663c <copyinstr_new+0x54>
    8000663a:	557d                	li	a0,-1
}
    8000663c:	70a2                	ld	ra,40(sp)
    8000663e:	7402                	ld	s0,32(sp)
    80006640:	64e2                	ld	s1,24(sp)
    80006642:	6942                	ld	s2,16(sp)
    80006644:	69a2                	ld	s3,8(sp)
    80006646:	6145                	addi	sp,sp,48
    80006648:	8082                	ret
  return -1;
    8000664a:	557d                	li	a0,-1
    8000664c:	bfc5                	j	8000663c <copyinstr_new+0x54>
      return 0;
    8000664e:	4501                	li	a0,0
    80006650:	b7f5                	j	8000663c <copyinstr_new+0x54>

0000000080006652 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006652:	1141                	addi	sp,sp,-16
    80006654:	e422                	sd	s0,8(sp)
    80006656:	0800                	addi	s0,sp,16
  return -1;
}
    80006658:	557d                	li	a0,-1
    8000665a:	6422                	ld	s0,8(sp)
    8000665c:	0141                	addi	sp,sp,16
    8000665e:	8082                	ret

0000000080006660 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006660:	7179                	addi	sp,sp,-48
    80006662:	f406                	sd	ra,40(sp)
    80006664:	f022                	sd	s0,32(sp)
    80006666:	ec26                	sd	s1,24(sp)
    80006668:	e84a                	sd	s2,16(sp)
    8000666a:	e44e                	sd	s3,8(sp)
    8000666c:	e052                	sd	s4,0(sp)
    8000666e:	1800                	addi	s0,sp,48
    80006670:	892a                	mv	s2,a0
    80006672:	89ae                	mv	s3,a1
    80006674:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    80006676:	00020517          	auipc	a0,0x20
    8000667a:	98a50513          	addi	a0,a0,-1654 # 80026000 <stats>
    8000667e:	ffffa097          	auipc	ra,0xffffa
    80006682:	592080e7          	jalr	1426(ra) # 80000c10 <acquire>

  if(stats.sz == 0) {
    80006686:	00021797          	auipc	a5,0x21
    8000668a:	9927a783          	lw	a5,-1646(a5) # 80027018 <stats+0x1018>
    8000668e:	cbb5                	beqz	a5,80006702 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006690:	00021797          	auipc	a5,0x21
    80006694:	97078793          	addi	a5,a5,-1680 # 80027000 <stats+0x1000>
    80006698:	4fd8                	lw	a4,28(a5)
    8000669a:	4f9c                	lw	a5,24(a5)
    8000669c:	9f99                	subw	a5,a5,a4
    8000669e:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800066a2:	06d05e63          	blez	a3,8000671e <statsread+0xbe>
    if(m > n)
    800066a6:	8a3e                	mv	s4,a5
    800066a8:	00d4d363          	bge	s1,a3,800066ae <statsread+0x4e>
    800066ac:	8a26                	mv	s4,s1
    800066ae:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800066b2:	86a6                	mv	a3,s1
    800066b4:	00020617          	auipc	a2,0x20
    800066b8:	96460613          	addi	a2,a2,-1692 # 80026018 <stats+0x18>
    800066bc:	963a                	add	a2,a2,a4
    800066be:	85ce                	mv	a1,s3
    800066c0:	854a                	mv	a0,s2
    800066c2:	ffffc097          	auipc	ra,0xffffc
    800066c6:	b84080e7          	jalr	-1148(ra) # 80002246 <either_copyout>
    800066ca:	57fd                	li	a5,-1
    800066cc:	00f50a63          	beq	a0,a5,800066e0 <statsread+0x80>
      stats.off += m;
    800066d0:	00021717          	auipc	a4,0x21
    800066d4:	93070713          	addi	a4,a4,-1744 # 80027000 <stats+0x1000>
    800066d8:	4f5c                	lw	a5,28(a4)
    800066da:	014787bb          	addw	a5,a5,s4
    800066de:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800066e0:	00020517          	auipc	a0,0x20
    800066e4:	92050513          	addi	a0,a0,-1760 # 80026000 <stats>
    800066e8:	ffffa097          	auipc	ra,0xffffa
    800066ec:	5dc080e7          	jalr	1500(ra) # 80000cc4 <release>
  return m;
}
    800066f0:	8526                	mv	a0,s1
    800066f2:	70a2                	ld	ra,40(sp)
    800066f4:	7402                	ld	s0,32(sp)
    800066f6:	64e2                	ld	s1,24(sp)
    800066f8:	6942                	ld	s2,16(sp)
    800066fa:	69a2                	ld	s3,8(sp)
    800066fc:	6a02                	ld	s4,0(sp)
    800066fe:	6145                	addi	sp,sp,48
    80006700:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    80006702:	6585                	lui	a1,0x1
    80006704:	00020517          	auipc	a0,0x20
    80006708:	91450513          	addi	a0,a0,-1772 # 80026018 <stats+0x18>
    8000670c:	00000097          	auipc	ra,0x0
    80006710:	e18080e7          	jalr	-488(ra) # 80006524 <statscopyin>
    80006714:	00021797          	auipc	a5,0x21
    80006718:	90a7a223          	sw	a0,-1788(a5) # 80027018 <stats+0x1018>
    8000671c:	bf95                	j	80006690 <statsread+0x30>
    stats.sz = 0;
    8000671e:	00021797          	auipc	a5,0x21
    80006722:	8e278793          	addi	a5,a5,-1822 # 80027000 <stats+0x1000>
    80006726:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    8000672a:	0007ae23          	sw	zero,28(a5)
    m = -1;
    8000672e:	54fd                	li	s1,-1
    80006730:	bf45                	j	800066e0 <statsread+0x80>

0000000080006732 <statsinit>:

void
statsinit(void)
{
    80006732:	1141                	addi	sp,sp,-16
    80006734:	e406                	sd	ra,8(sp)
    80006736:	e022                	sd	s0,0(sp)
    80006738:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000673a:	00002597          	auipc	a1,0x2
    8000673e:	14e58593          	addi	a1,a1,334 # 80008888 <syscalls+0x400>
    80006742:	00020517          	auipc	a0,0x20
    80006746:	8be50513          	addi	a0,a0,-1858 # 80026000 <stats>
    8000674a:	ffffa097          	auipc	ra,0xffffa
    8000674e:	436080e7          	jalr	1078(ra) # 80000b80 <initlock>

  devsw[STATS].read = statsread;
    80006752:	0001b797          	auipc	a5,0x1b
    80006756:	45e78793          	addi	a5,a5,1118 # 80021bb0 <devsw>
    8000675a:	00000717          	auipc	a4,0x0
    8000675e:	f0670713          	addi	a4,a4,-250 # 80006660 <statsread>
    80006762:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006764:	00000717          	auipc	a4,0x0
    80006768:	eee70713          	addi	a4,a4,-274 # 80006652 <statswrite>
    8000676c:	f798                	sd	a4,40(a5)
}
    8000676e:	60a2                	ld	ra,8(sp)
    80006770:	6402                	ld	s0,0(sp)
    80006772:	0141                	addi	sp,sp,16
    80006774:	8082                	ret

0000000080006776 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006776:	1101                	addi	sp,sp,-32
    80006778:	ec22                	sd	s0,24(sp)
    8000677a:	1000                	addi	s0,sp,32
    8000677c:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    8000677e:	c299                	beqz	a3,80006784 <sprintint+0xe>
    80006780:	0805c163          	bltz	a1,80006802 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006784:	2581                	sext.w	a1,a1
    80006786:	4301                	li	t1,0

  i = 0;
    80006788:	fe040713          	addi	a4,s0,-32
    8000678c:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    8000678e:	2601                	sext.w	a2,a2
    80006790:	00002697          	auipc	a3,0x2
    80006794:	10068693          	addi	a3,a3,256 # 80008890 <digits>
    80006798:	88aa                	mv	a7,a0
    8000679a:	2505                	addiw	a0,a0,1
    8000679c:	02c5f7bb          	remuw	a5,a1,a2
    800067a0:	1782                	slli	a5,a5,0x20
    800067a2:	9381                	srli	a5,a5,0x20
    800067a4:	97b6                	add	a5,a5,a3
    800067a6:	0007c783          	lbu	a5,0(a5)
    800067aa:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800067ae:	0005879b          	sext.w	a5,a1
    800067b2:	02c5d5bb          	divuw	a1,a1,a2
    800067b6:	0705                	addi	a4,a4,1
    800067b8:	fec7f0e3          	bgeu	a5,a2,80006798 <sprintint+0x22>

  if(sign)
    800067bc:	00030b63          	beqz	t1,800067d2 <sprintint+0x5c>
    buf[i++] = '-';
    800067c0:	ff040793          	addi	a5,s0,-16
    800067c4:	97aa                	add	a5,a5,a0
    800067c6:	02d00713          	li	a4,45
    800067ca:	fee78823          	sb	a4,-16(a5)
    800067ce:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800067d2:	02a05c63          	blez	a0,8000680a <sprintint+0x94>
    800067d6:	fe040793          	addi	a5,s0,-32
    800067da:	00a78733          	add	a4,a5,a0
    800067de:	87c2                	mv	a5,a6
    800067e0:	0805                	addi	a6,a6,1
    800067e2:	fff5061b          	addiw	a2,a0,-1
    800067e6:	1602                	slli	a2,a2,0x20
    800067e8:	9201                	srli	a2,a2,0x20
    800067ea:	9642                	add	a2,a2,a6
  *s = c;
    800067ec:	fff74683          	lbu	a3,-1(a4)
    800067f0:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    800067f4:	177d                	addi	a4,a4,-1
    800067f6:	0785                	addi	a5,a5,1
    800067f8:	fec79ae3          	bne	a5,a2,800067ec <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    800067fc:	6462                	ld	s0,24(sp)
    800067fe:	6105                	addi	sp,sp,32
    80006800:	8082                	ret
    x = -xx;
    80006802:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006806:	4305                	li	t1,1
    x = -xx;
    80006808:	b741                	j	80006788 <sprintint+0x12>
  while(--i >= 0)
    8000680a:	4501                	li	a0,0
    8000680c:	bfc5                	j	800067fc <sprintint+0x86>

000000008000680e <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    8000680e:	7171                	addi	sp,sp,-176
    80006810:	fc86                	sd	ra,120(sp)
    80006812:	f8a2                	sd	s0,112(sp)
    80006814:	f4a6                	sd	s1,104(sp)
    80006816:	f0ca                	sd	s2,96(sp)
    80006818:	ecce                	sd	s3,88(sp)
    8000681a:	e8d2                	sd	s4,80(sp)
    8000681c:	e4d6                	sd	s5,72(sp)
    8000681e:	e0da                	sd	s6,64(sp)
    80006820:	fc5e                	sd	s7,56(sp)
    80006822:	f862                	sd	s8,48(sp)
    80006824:	f466                	sd	s9,40(sp)
    80006826:	f06a                	sd	s10,32(sp)
    80006828:	ec6e                	sd	s11,24(sp)
    8000682a:	0100                	addi	s0,sp,128
    8000682c:	e414                	sd	a3,8(s0)
    8000682e:	e818                	sd	a4,16(s0)
    80006830:	ec1c                	sd	a5,24(s0)
    80006832:	03043023          	sd	a6,32(s0)
    80006836:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000683a:	ca0d                	beqz	a2,8000686c <snprintf+0x5e>
    8000683c:	8baa                	mv	s7,a0
    8000683e:	89ae                	mv	s3,a1
    80006840:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006842:	00840793          	addi	a5,s0,8
    80006846:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    8000684a:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000684c:	4901                	li	s2,0
    8000684e:	02b05763          	blez	a1,8000687c <snprintf+0x6e>
    if(c != '%'){
    80006852:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006856:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000685a:	02800d93          	li	s11,40
  *s = c;
    8000685e:	02500d13          	li	s10,37
    switch(c){
    80006862:	07800c93          	li	s9,120
    80006866:	06400c13          	li	s8,100
    8000686a:	a01d                	j	80006890 <snprintf+0x82>
    panic("null fmt");
    8000686c:	00001517          	auipc	a0,0x1
    80006870:	7bc50513          	addi	a0,a0,1980 # 80008028 <etext+0x28>
    80006874:	ffffa097          	auipc	ra,0xffffa
    80006878:	cd4080e7          	jalr	-812(ra) # 80000548 <panic>
  int off = 0;
    8000687c:	4481                	li	s1,0
    8000687e:	a86d                	j	80006938 <snprintf+0x12a>
  *s = c;
    80006880:	009b8733          	add	a4,s7,s1
    80006884:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006888:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000688a:	2905                	addiw	s2,s2,1
    8000688c:	0b34d663          	bge	s1,s3,80006938 <snprintf+0x12a>
    80006890:	012a07b3          	add	a5,s4,s2
    80006894:	0007c783          	lbu	a5,0(a5)
    80006898:	0007871b          	sext.w	a4,a5
    8000689c:	cfd1                	beqz	a5,80006938 <snprintf+0x12a>
    if(c != '%'){
    8000689e:	ff5711e3          	bne	a4,s5,80006880 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    800068a2:	2905                	addiw	s2,s2,1
    800068a4:	012a07b3          	add	a5,s4,s2
    800068a8:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800068ac:	c7d1                	beqz	a5,80006938 <snprintf+0x12a>
    switch(c){
    800068ae:	05678c63          	beq	a5,s6,80006906 <snprintf+0xf8>
    800068b2:	02fb6763          	bltu	s6,a5,800068e0 <snprintf+0xd2>
    800068b6:	0b578763          	beq	a5,s5,80006964 <snprintf+0x156>
    800068ba:	0b879b63          	bne	a5,s8,80006970 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800068be:	f8843783          	ld	a5,-120(s0)
    800068c2:	00878713          	addi	a4,a5,8
    800068c6:	f8e43423          	sd	a4,-120(s0)
    800068ca:	4685                	li	a3,1
    800068cc:	4629                	li	a2,10
    800068ce:	438c                	lw	a1,0(a5)
    800068d0:	009b8533          	add	a0,s7,s1
    800068d4:	00000097          	auipc	ra,0x0
    800068d8:	ea2080e7          	jalr	-350(ra) # 80006776 <sprintint>
    800068dc:	9ca9                	addw	s1,s1,a0
      break;
    800068de:	b775                	j	8000688a <snprintf+0x7c>
    switch(c){
    800068e0:	09979863          	bne	a5,s9,80006970 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    800068e4:	f8843783          	ld	a5,-120(s0)
    800068e8:	00878713          	addi	a4,a5,8
    800068ec:	f8e43423          	sd	a4,-120(s0)
    800068f0:	4685                	li	a3,1
    800068f2:	4641                	li	a2,16
    800068f4:	438c                	lw	a1,0(a5)
    800068f6:	009b8533          	add	a0,s7,s1
    800068fa:	00000097          	auipc	ra,0x0
    800068fe:	e7c080e7          	jalr	-388(ra) # 80006776 <sprintint>
    80006902:	9ca9                	addw	s1,s1,a0
      break;
    80006904:	b759                	j	8000688a <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006906:	f8843783          	ld	a5,-120(s0)
    8000690a:	00878713          	addi	a4,a5,8
    8000690e:	f8e43423          	sd	a4,-120(s0)
    80006912:	639c                	ld	a5,0(a5)
    80006914:	c3b1                	beqz	a5,80006958 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006916:	0007c703          	lbu	a4,0(a5)
    8000691a:	db25                	beqz	a4,8000688a <snprintf+0x7c>
    8000691c:	0134de63          	bge	s1,s3,80006938 <snprintf+0x12a>
    80006920:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006924:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006928:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    8000692a:	0785                	addi	a5,a5,1
    8000692c:	0007c703          	lbu	a4,0(a5)
    80006930:	df29                	beqz	a4,8000688a <snprintf+0x7c>
    80006932:	0685                	addi	a3,a3,1
    80006934:	fe9998e3          	bne	s3,s1,80006924 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006938:	8526                	mv	a0,s1
    8000693a:	70e6                	ld	ra,120(sp)
    8000693c:	7446                	ld	s0,112(sp)
    8000693e:	74a6                	ld	s1,104(sp)
    80006940:	7906                	ld	s2,96(sp)
    80006942:	69e6                	ld	s3,88(sp)
    80006944:	6a46                	ld	s4,80(sp)
    80006946:	6aa6                	ld	s5,72(sp)
    80006948:	6b06                	ld	s6,64(sp)
    8000694a:	7be2                	ld	s7,56(sp)
    8000694c:	7c42                	ld	s8,48(sp)
    8000694e:	7ca2                	ld	s9,40(sp)
    80006950:	7d02                	ld	s10,32(sp)
    80006952:	6de2                	ld	s11,24(sp)
    80006954:	614d                	addi	sp,sp,176
    80006956:	8082                	ret
        s = "(null)";
    80006958:	00001797          	auipc	a5,0x1
    8000695c:	6c878793          	addi	a5,a5,1736 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006960:	876e                	mv	a4,s11
    80006962:	bf6d                	j	8000691c <snprintf+0x10e>
  *s = c;
    80006964:	009b87b3          	add	a5,s7,s1
    80006968:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    8000696c:	2485                	addiw	s1,s1,1
      break;
    8000696e:	bf31                	j	8000688a <snprintf+0x7c>
  *s = c;
    80006970:	009b8733          	add	a4,s7,s1
    80006974:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006978:	0014871b          	addiw	a4,s1,1
  *s = c;
    8000697c:	975e                	add	a4,a4,s7
    8000697e:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006982:	2489                	addiw	s1,s1,2
      break;
    80006984:	b719                	j	8000688a <snprintf+0x7c>
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
