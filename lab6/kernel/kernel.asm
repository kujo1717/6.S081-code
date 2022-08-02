
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
    80000060:	c5478793          	addi	a5,a5,-940 # 80005cb0 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fed87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e4678793          	addi	a5,a5,-442 # 80000eec <main>
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
    80000110:	b32080e7          	jalr	-1230(ra) # 80000c3e <acquire>
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
    8000012a:	47a080e7          	jalr	1146(ra) # 800025a0 <either_copyin>
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
    80000152:	ba4080e7          	jalr	-1116(ra) # 80000cf2 <release>

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
    800001a2:	aa0080e7          	jalr	-1376(ra) # 80000c3e <acquire>
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
    800001d2:	90a080e7          	jalr	-1782(ra) # 80001ad8 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	10a080e7          	jalr	266(ra) # 800022e8 <sleep>
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
    8000021e:	330080e7          	jalr	816(ra) # 8000254a <either_copyout>
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
    8000023a:	abc080e7          	jalr	-1348(ra) # 80000cf2 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	aa6080e7          	jalr	-1370(ra) # 80000cf2 <release>
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
    800002e2:	960080e7          	jalr	-1696(ra) # 80000c3e <acquire>

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
    80000300:	2fa080e7          	jalr	762(ra) # 800025f6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9e6080e7          	jalr	-1562(ra) # 80000cf2 <release>
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
    80000454:	01e080e7          	jalr	30(ra) # 8000246e <wakeup>
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
    80000476:	73c080e7          	jalr	1852(ra) # 80000bae <initlock>

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
    8000060e:	634080e7          	jalr	1588(ra) # 80000c3e <acquire>
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
    80000772:	584080e7          	jalr	1412(ra) # 80000cf2 <release>
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
    80000798:	41a080e7          	jalr	1050(ra) # 80000bae <initlock>
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
    800007ee:	3c4080e7          	jalr	964(ra) # 80000bae <initlock>
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
    8000080a:	3ec080e7          	jalr	1004(ra) # 80000bf2 <push_off>

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
    8000083c:	45a080e7          	jalr	1114(ra) # 80000c92 <pop_off>
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
    800008ba:	bb8080e7          	jalr	-1096(ra) # 8000246e <wakeup>
    
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
    800008fe:	344080e7          	jalr	836(ra) # 80000c3e <acquire>
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
    80000954:	998080e7          	jalr	-1640(ra) # 800022e8 <sleep>
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
    80000998:	35e080e7          	jalr	862(ra) # 80000cf2 <release>
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
    80000a04:	23e080e7          	jalr	574(ra) # 80000c3e <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2e0080e7          	jalr	736(ra) # 80000cf2 <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
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
    80000a34:	e79d                	bnez	a5,80000a62 <kfree+0x3e>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00125797          	auipc	a5,0x125
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80126000 <end>
    80000a40:	02f56163          	bltu	a0,a5,80000a62 <kfree+0x3e>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	00f57d63          	bgeu	a0,a5,80000a62 <kfree+0x3e>
    panic("kfree");

  // 引用计数-1
  if (decrefcnt((uint64) pa)) {
    80000a4c:	00006097          	auipc	ra,0x6
    80000a50:	8ba080e7          	jalr	-1862(ra) # 80006306 <decrefcnt>
    80000a54:	cd19                	beqz	a0,80000a72 <kfree+0x4e>

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
    80000a56:	60e2                	ld	ra,24(sp)
    80000a58:	6442                	ld	s0,16(sp)
    80000a5a:	64a2                	ld	s1,8(sp)
    80000a5c:	6902                	ld	s2,0(sp)
    80000a5e:	6105                	addi	sp,sp,32
    80000a60:	8082                	ret
    panic("kfree");
    80000a62:	00007517          	auipc	a0,0x7
    80000a66:	5fe50513          	addi	a0,a0,1534 # 80008060 <digits+0x20>
    80000a6a:	00000097          	auipc	ra,0x0
    80000a6e:	ade080e7          	jalr	-1314(ra) # 80000548 <panic>
  memset(pa, 1, PGSIZE);
    80000a72:	6605                	lui	a2,0x1
    80000a74:	4585                	li	a1,1
    80000a76:	8526                	mv	a0,s1
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	2c2080e7          	jalr	706(ra) # 80000d3a <memset>
  acquire(&kmem.lock);
    80000a80:	00011917          	auipc	s2,0x11
    80000a84:	eb090913          	addi	s2,s2,-336 # 80011930 <kmem>
    80000a88:	854a                	mv	a0,s2
    80000a8a:	00000097          	auipc	ra,0x0
    80000a8e:	1b4080e7          	jalr	436(ra) # 80000c3e <acquire>
  r->next = kmem.freelist;
    80000a92:	01893783          	ld	a5,24(s2)
    80000a96:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a98:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a9c:	854a                	mv	a0,s2
    80000a9e:	00000097          	auipc	ra,0x0
    80000aa2:	254080e7          	jalr	596(ra) # 80000cf2 <release>
    80000aa6:	bf45                	j	80000a56 <kfree+0x32>

0000000080000aa8 <freerange>:
{
    80000aa8:	7179                	addi	sp,sp,-48
    80000aaa:	f406                	sd	ra,40(sp)
    80000aac:	f022                	sd	s0,32(sp)
    80000aae:	ec26                	sd	s1,24(sp)
    80000ab0:	e84a                	sd	s2,16(sp)
    80000ab2:	e44e                	sd	s3,8(sp)
    80000ab4:	e052                	sd	s4,0(sp)
    80000ab6:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ab8:	6785                	lui	a5,0x1
    80000aba:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000abe:	9526                	add	a0,a0,s1
    80000ac0:	74fd                	lui	s1,0xfffff
    80000ac2:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
    80000ac4:	97a6                	add	a5,a5,s1
    80000ac6:	02f5e463          	bltu	a1,a5,80000aee <freerange+0x46>
    80000aca:	892e                	mv	s2,a1
    80000acc:	6a05                	lui	s4,0x1
    80000ace:	6989                	lui	s3,0x2
      increfcnt((uint64)p); // +1
    80000ad0:	8526                	mv	a0,s1
    80000ad2:	00005097          	auipc	ra,0x5
    80000ad6:	7d2080e7          	jalr	2002(ra) # 800062a4 <increfcnt>
      kfree(p);
    80000ada:	8526                	mv	a0,s1
    80000adc:	00000097          	auipc	ra,0x0
    80000ae0:	f48080e7          	jalr	-184(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
    80000ae4:	87a6                	mv	a5,s1
    80000ae6:	94d2                	add	s1,s1,s4
    80000ae8:	97ce                	add	a5,a5,s3
    80000aea:	fef973e3          	bgeu	s2,a5,80000ad0 <freerange+0x28>
}
    80000aee:	70a2                	ld	ra,40(sp)
    80000af0:	7402                	ld	s0,32(sp)
    80000af2:	64e2                	ld	s1,24(sp)
    80000af4:	6942                	ld	s2,16(sp)
    80000af6:	69a2                	ld	s3,8(sp)
    80000af8:	6a02                	ld	s4,0(sp)
    80000afa:	6145                	addi	sp,sp,48
    80000afc:	8082                	ret

0000000080000afe <kinit>:
{
    80000afe:	1141                	addi	sp,sp,-16
    80000b00:	e406                	sd	ra,8(sp)
    80000b02:	e022                	sd	s0,0(sp)
    80000b04:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b06:	00007597          	auipc	a1,0x7
    80000b0a:	56258593          	addi	a1,a1,1378 # 80008068 <digits+0x28>
    80000b0e:	00011517          	auipc	a0,0x11
    80000b12:	e2250513          	addi	a0,a0,-478 # 80011930 <kmem>
    80000b16:	00000097          	auipc	ra,0x0
    80000b1a:	098080e7          	jalr	152(ra) # 80000bae <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b1e:	45c5                	li	a1,17
    80000b20:	05ee                	slli	a1,a1,0x1b
    80000b22:	00125517          	auipc	a0,0x125
    80000b26:	4de50513          	addi	a0,a0,1246 # 80126000 <end>
    80000b2a:	00000097          	auipc	ra,0x0
    80000b2e:	f7e080e7          	jalr	-130(ra) # 80000aa8 <freerange>
}
    80000b32:	60a2                	ld	ra,8(sp)
    80000b34:	6402                	ld	s0,0(sp)
    80000b36:	0141                	addi	sp,sp,16
    80000b38:	8082                	ret

0000000080000b3a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b3a:	1101                	addi	sp,sp,-32
    80000b3c:	ec06                	sd	ra,24(sp)
    80000b3e:	e822                	sd	s0,16(sp)
    80000b40:	e426                	sd	s1,8(sp)
    80000b42:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b44:	00011497          	auipc	s1,0x11
    80000b48:	dec48493          	addi	s1,s1,-532 # 80011930 <kmem>
    80000b4c:	8526                	mv	a0,s1
    80000b4e:	00000097          	auipc	ra,0x0
    80000b52:	0f0080e7          	jalr	240(ra) # 80000c3e <acquire>
  r = kmem.freelist;
    80000b56:	6c84                	ld	s1,24(s1)
  if(r)
    80000b58:	cc8d                	beqz	s1,80000b92 <kalloc+0x58>
    kmem.freelist = r->next;
    80000b5a:	609c                	ld	a5,0(s1)
    80000b5c:	00011517          	auipc	a0,0x11
    80000b60:	dd450513          	addi	a0,a0,-556 # 80011930 <kmem>
    80000b64:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b66:	00000097          	auipc	ra,0x0
    80000b6a:	18c080e7          	jalr	396(ra) # 80000cf2 <release>

  // 初始0+1=1
  increfcnt((uint64)r);
    80000b6e:	8526                	mv	a0,s1
    80000b70:	00005097          	auipc	ra,0x5
    80000b74:	734080e7          	jalr	1844(ra) # 800062a4 <increfcnt>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b78:	6605                	lui	a2,0x1
    80000b7a:	4595                	li	a1,5
    80000b7c:	8526                	mv	a0,s1
    80000b7e:	00000097          	auipc	ra,0x0
    80000b82:	1bc080e7          	jalr	444(ra) # 80000d3a <memset>
  return (void*)r;
}
    80000b86:	8526                	mv	a0,s1
    80000b88:	60e2                	ld	ra,24(sp)
    80000b8a:	6442                	ld	s0,16(sp)
    80000b8c:	64a2                	ld	s1,8(sp)
    80000b8e:	6105                	addi	sp,sp,32
    80000b90:	8082                	ret
  release(&kmem.lock);
    80000b92:	00011517          	auipc	a0,0x11
    80000b96:	d9e50513          	addi	a0,a0,-610 # 80011930 <kmem>
    80000b9a:	00000097          	auipc	ra,0x0
    80000b9e:	158080e7          	jalr	344(ra) # 80000cf2 <release>
  increfcnt((uint64)r);
    80000ba2:	4501                	li	a0,0
    80000ba4:	00005097          	auipc	ra,0x5
    80000ba8:	700080e7          	jalr	1792(ra) # 800062a4 <increfcnt>
  if(r)
    80000bac:	bfe9                	j	80000b86 <kalloc+0x4c>

0000000080000bae <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bae:	1141                	addi	sp,sp,-16
    80000bb0:	e422                	sd	s0,8(sp)
    80000bb2:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bb4:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bb6:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bba:	00053823          	sd	zero,16(a0)
}
    80000bbe:	6422                	ld	s0,8(sp)
    80000bc0:	0141                	addi	sp,sp,16
    80000bc2:	8082                	ret

0000000080000bc4 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bc4:	411c                	lw	a5,0(a0)
    80000bc6:	e399                	bnez	a5,80000bcc <holding+0x8>
    80000bc8:	4501                	li	a0,0
  return r;
}
    80000bca:	8082                	ret
{
    80000bcc:	1101                	addi	sp,sp,-32
    80000bce:	ec06                	sd	ra,24(sp)
    80000bd0:	e822                	sd	s0,16(sp)
    80000bd2:	e426                	sd	s1,8(sp)
    80000bd4:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bd6:	6904                	ld	s1,16(a0)
    80000bd8:	00001097          	auipc	ra,0x1
    80000bdc:	ee4080e7          	jalr	-284(ra) # 80001abc <mycpu>
    80000be0:	40a48533          	sub	a0,s1,a0
    80000be4:	00153513          	seqz	a0,a0
}
    80000be8:	60e2                	ld	ra,24(sp)
    80000bea:	6442                	ld	s0,16(sp)
    80000bec:	64a2                	ld	s1,8(sp)
    80000bee:	6105                	addi	sp,sp,32
    80000bf0:	8082                	ret

0000000080000bf2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bf2:	1101                	addi	sp,sp,-32
    80000bf4:	ec06                	sd	ra,24(sp)
    80000bf6:	e822                	sd	s0,16(sp)
    80000bf8:	e426                	sd	s1,8(sp)
    80000bfa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bfc:	100024f3          	csrr	s1,sstatus
    80000c00:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c04:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c06:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c0a:	00001097          	auipc	ra,0x1
    80000c0e:	eb2080e7          	jalr	-334(ra) # 80001abc <mycpu>
    80000c12:	5d3c                	lw	a5,120(a0)
    80000c14:	cf89                	beqz	a5,80000c2e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c16:	00001097          	auipc	ra,0x1
    80000c1a:	ea6080e7          	jalr	-346(ra) # 80001abc <mycpu>
    80000c1e:	5d3c                	lw	a5,120(a0)
    80000c20:	2785                	addiw	a5,a5,1
    80000c22:	dd3c                	sw	a5,120(a0)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    mycpu()->intena = old;
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	e8e080e7          	jalr	-370(ra) # 80001abc <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c36:	8085                	srli	s1,s1,0x1
    80000c38:	8885                	andi	s1,s1,1
    80000c3a:	dd64                	sw	s1,124(a0)
    80000c3c:	bfe9                	j	80000c16 <push_off+0x24>

0000000080000c3e <acquire>:
{
    80000c3e:	1101                	addi	sp,sp,-32
    80000c40:	ec06                	sd	ra,24(sp)
    80000c42:	e822                	sd	s0,16(sp)
    80000c44:	e426                	sd	s1,8(sp)
    80000c46:	1000                	addi	s0,sp,32
    80000c48:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	fa8080e7          	jalr	-88(ra) # 80000bf2 <push_off>
  if(holding(lk))
    80000c52:	8526                	mv	a0,s1
    80000c54:	00000097          	auipc	ra,0x0
    80000c58:	f70080e7          	jalr	-144(ra) # 80000bc4 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c5c:	4705                	li	a4,1
  if(holding(lk))
    80000c5e:	e115                	bnez	a0,80000c82 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c60:	87ba                	mv	a5,a4
    80000c62:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c66:	2781                	sext.w	a5,a5
    80000c68:	ffe5                	bnez	a5,80000c60 <acquire+0x22>
  __sync_synchronize();
    80000c6a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c6e:	00001097          	auipc	ra,0x1
    80000c72:	e4e080e7          	jalr	-434(ra) # 80001abc <mycpu>
    80000c76:	e888                	sd	a0,16(s1)
}
    80000c78:	60e2                	ld	ra,24(sp)
    80000c7a:	6442                	ld	s0,16(sp)
    80000c7c:	64a2                	ld	s1,8(sp)
    80000c7e:	6105                	addi	sp,sp,32
    80000c80:	8082                	ret
    panic("acquire");
    80000c82:	00007517          	auipc	a0,0x7
    80000c86:	3ee50513          	addi	a0,a0,1006 # 80008070 <digits+0x30>
    80000c8a:	00000097          	auipc	ra,0x0
    80000c8e:	8be080e7          	jalr	-1858(ra) # 80000548 <panic>

0000000080000c92 <pop_off>:

void
pop_off(void)
{
    80000c92:	1141                	addi	sp,sp,-16
    80000c94:	e406                	sd	ra,8(sp)
    80000c96:	e022                	sd	s0,0(sp)
    80000c98:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c9a:	00001097          	auipc	ra,0x1
    80000c9e:	e22080e7          	jalr	-478(ra) # 80001abc <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ca2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000ca6:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000ca8:	e78d                	bnez	a5,80000cd2 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000caa:	5d3c                	lw	a5,120(a0)
    80000cac:	02f05b63          	blez	a5,80000ce2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cb0:	37fd                	addiw	a5,a5,-1
    80000cb2:	0007871b          	sext.w	a4,a5
    80000cb6:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cb8:	eb09                	bnez	a4,80000cca <pop_off+0x38>
    80000cba:	5d7c                	lw	a5,124(a0)
    80000cbc:	c799                	beqz	a5,80000cca <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cbe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cc2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cc6:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cca:	60a2                	ld	ra,8(sp)
    80000ccc:	6402                	ld	s0,0(sp)
    80000cce:	0141                	addi	sp,sp,16
    80000cd0:	8082                	ret
    panic("pop_off - interruptible");
    80000cd2:	00007517          	auipc	a0,0x7
    80000cd6:	3a650513          	addi	a0,a0,934 # 80008078 <digits+0x38>
    80000cda:	00000097          	auipc	ra,0x0
    80000cde:	86e080e7          	jalr	-1938(ra) # 80000548 <panic>
    panic("pop_off");
    80000ce2:	00007517          	auipc	a0,0x7
    80000ce6:	3ae50513          	addi	a0,a0,942 # 80008090 <digits+0x50>
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	85e080e7          	jalr	-1954(ra) # 80000548 <panic>

0000000080000cf2 <release>:
{
    80000cf2:	1101                	addi	sp,sp,-32
    80000cf4:	ec06                	sd	ra,24(sp)
    80000cf6:	e822                	sd	s0,16(sp)
    80000cf8:	e426                	sd	s1,8(sp)
    80000cfa:	1000                	addi	s0,sp,32
    80000cfc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cfe:	00000097          	auipc	ra,0x0
    80000d02:	ec6080e7          	jalr	-314(ra) # 80000bc4 <holding>
    80000d06:	c115                	beqz	a0,80000d2a <release+0x38>
  lk->cpu = 0;
    80000d08:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d0c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d10:	0f50000f          	fence	iorw,ow
    80000d14:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d18:	00000097          	auipc	ra,0x0
    80000d1c:	f7a080e7          	jalr	-134(ra) # 80000c92 <pop_off>
}
    80000d20:	60e2                	ld	ra,24(sp)
    80000d22:	6442                	ld	s0,16(sp)
    80000d24:	64a2                	ld	s1,8(sp)
    80000d26:	6105                	addi	sp,sp,32
    80000d28:	8082                	ret
    panic("release");
    80000d2a:	00007517          	auipc	a0,0x7
    80000d2e:	36e50513          	addi	a0,a0,878 # 80008098 <digits+0x58>
    80000d32:	00000097          	auipc	ra,0x0
    80000d36:	816080e7          	jalr	-2026(ra) # 80000548 <panic>

0000000080000d3a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d3a:	1141                	addi	sp,sp,-16
    80000d3c:	e422                	sd	s0,8(sp)
    80000d3e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d40:	ce09                	beqz	a2,80000d5a <memset+0x20>
    80000d42:	87aa                	mv	a5,a0
    80000d44:	fff6071b          	addiw	a4,a2,-1
    80000d48:	1702                	slli	a4,a4,0x20
    80000d4a:	9301                	srli	a4,a4,0x20
    80000d4c:	0705                	addi	a4,a4,1
    80000d4e:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d50:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d54:	0785                	addi	a5,a5,1
    80000d56:	fee79de3          	bne	a5,a4,80000d50 <memset+0x16>
  }
  return dst;
}
    80000d5a:	6422                	ld	s0,8(sp)
    80000d5c:	0141                	addi	sp,sp,16
    80000d5e:	8082                	ret

0000000080000d60 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d60:	1141                	addi	sp,sp,-16
    80000d62:	e422                	sd	s0,8(sp)
    80000d64:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d66:	ca05                	beqz	a2,80000d96 <memcmp+0x36>
    80000d68:	fff6069b          	addiw	a3,a2,-1
    80000d6c:	1682                	slli	a3,a3,0x20
    80000d6e:	9281                	srli	a3,a3,0x20
    80000d70:	0685                	addi	a3,a3,1
    80000d72:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d74:	00054783          	lbu	a5,0(a0)
    80000d78:	0005c703          	lbu	a4,0(a1)
    80000d7c:	00e79863          	bne	a5,a4,80000d8c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d80:	0505                	addi	a0,a0,1
    80000d82:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d84:	fed518e3          	bne	a0,a3,80000d74 <memcmp+0x14>
  }

  return 0;
    80000d88:	4501                	li	a0,0
    80000d8a:	a019                	j	80000d90 <memcmp+0x30>
      return *s1 - *s2;
    80000d8c:	40e7853b          	subw	a0,a5,a4
}
    80000d90:	6422                	ld	s0,8(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret
  return 0;
    80000d96:	4501                	li	a0,0
    80000d98:	bfe5                	j	80000d90 <memcmp+0x30>

0000000080000d9a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d9a:	1141                	addi	sp,sp,-16
    80000d9c:	e422                	sd	s0,8(sp)
    80000d9e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000da0:	00a5f963          	bgeu	a1,a0,80000db2 <memmove+0x18>
    80000da4:	02061713          	slli	a4,a2,0x20
    80000da8:	9301                	srli	a4,a4,0x20
    80000daa:	00e587b3          	add	a5,a1,a4
    80000dae:	02f56563          	bltu	a0,a5,80000dd8 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000db2:	fff6069b          	addiw	a3,a2,-1
    80000db6:	ce11                	beqz	a2,80000dd2 <memmove+0x38>
    80000db8:	1682                	slli	a3,a3,0x20
    80000dba:	9281                	srli	a3,a3,0x20
    80000dbc:	0685                	addi	a3,a3,1
    80000dbe:	96ae                	add	a3,a3,a1
    80000dc0:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000dc2:	0585                	addi	a1,a1,1
    80000dc4:	0785                	addi	a5,a5,1
    80000dc6:	fff5c703          	lbu	a4,-1(a1)
    80000dca:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dce:	fed59ae3          	bne	a1,a3,80000dc2 <memmove+0x28>

  return dst;
}
    80000dd2:	6422                	ld	s0,8(sp)
    80000dd4:	0141                	addi	sp,sp,16
    80000dd6:	8082                	ret
    d += n;
    80000dd8:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dda:	fff6069b          	addiw	a3,a2,-1
    80000dde:	da75                	beqz	a2,80000dd2 <memmove+0x38>
    80000de0:	02069613          	slli	a2,a3,0x20
    80000de4:	9201                	srli	a2,a2,0x20
    80000de6:	fff64613          	not	a2,a2
    80000dea:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dec:	17fd                	addi	a5,a5,-1
    80000dee:	177d                	addi	a4,a4,-1
    80000df0:	0007c683          	lbu	a3,0(a5)
    80000df4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000df8:	fec79ae3          	bne	a5,a2,80000dec <memmove+0x52>
    80000dfc:	bfd9                	j	80000dd2 <memmove+0x38>

0000000080000dfe <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dfe:	1141                	addi	sp,sp,-16
    80000e00:	e406                	sd	ra,8(sp)
    80000e02:	e022                	sd	s0,0(sp)
    80000e04:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e06:	00000097          	auipc	ra,0x0
    80000e0a:	f94080e7          	jalr	-108(ra) # 80000d9a <memmove>
}
    80000e0e:	60a2                	ld	ra,8(sp)
    80000e10:	6402                	ld	s0,0(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e1c:	ce11                	beqz	a2,80000e38 <strncmp+0x22>
    80000e1e:	00054783          	lbu	a5,0(a0)
    80000e22:	cf89                	beqz	a5,80000e3c <strncmp+0x26>
    80000e24:	0005c703          	lbu	a4,0(a1)
    80000e28:	00f71a63          	bne	a4,a5,80000e3c <strncmp+0x26>
    n--, p++, q++;
    80000e2c:	367d                	addiw	a2,a2,-1
    80000e2e:	0505                	addi	a0,a0,1
    80000e30:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e32:	f675                	bnez	a2,80000e1e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e34:	4501                	li	a0,0
    80000e36:	a809                	j	80000e48 <strncmp+0x32>
    80000e38:	4501                	li	a0,0
    80000e3a:	a039                	j	80000e48 <strncmp+0x32>
  if(n == 0)
    80000e3c:	ca09                	beqz	a2,80000e4e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e3e:	00054503          	lbu	a0,0(a0)
    80000e42:	0005c783          	lbu	a5,0(a1)
    80000e46:	9d1d                	subw	a0,a0,a5
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret
    return 0;
    80000e4e:	4501                	li	a0,0
    80000e50:	bfe5                	j	80000e48 <strncmp+0x32>

0000000080000e52 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e52:	1141                	addi	sp,sp,-16
    80000e54:	e422                	sd	s0,8(sp)
    80000e56:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e58:	872a                	mv	a4,a0
    80000e5a:	8832                	mv	a6,a2
    80000e5c:	367d                	addiw	a2,a2,-1
    80000e5e:	01005963          	blez	a6,80000e70 <strncpy+0x1e>
    80000e62:	0705                	addi	a4,a4,1
    80000e64:	0005c783          	lbu	a5,0(a1)
    80000e68:	fef70fa3          	sb	a5,-1(a4)
    80000e6c:	0585                	addi	a1,a1,1
    80000e6e:	f7f5                	bnez	a5,80000e5a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e70:	00c05d63          	blez	a2,80000e8a <strncpy+0x38>
    80000e74:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e76:	0685                	addi	a3,a3,1
    80000e78:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e7c:	fff6c793          	not	a5,a3
    80000e80:	9fb9                	addw	a5,a5,a4
    80000e82:	010787bb          	addw	a5,a5,a6
    80000e86:	fef048e3          	bgtz	a5,80000e76 <strncpy+0x24>
  return os;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret

0000000080000e90 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e90:	1141                	addi	sp,sp,-16
    80000e92:	e422                	sd	s0,8(sp)
    80000e94:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e96:	02c05363          	blez	a2,80000ebc <safestrcpy+0x2c>
    80000e9a:	fff6069b          	addiw	a3,a2,-1
    80000e9e:	1682                	slli	a3,a3,0x20
    80000ea0:	9281                	srli	a3,a3,0x20
    80000ea2:	96ae                	add	a3,a3,a1
    80000ea4:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ea6:	00d58963          	beq	a1,a3,80000eb8 <safestrcpy+0x28>
    80000eaa:	0585                	addi	a1,a1,1
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff5c703          	lbu	a4,-1(a1)
    80000eb2:	fee78fa3          	sb	a4,-1(a5)
    80000eb6:	fb65                	bnez	a4,80000ea6 <safestrcpy+0x16>
    ;
  *s = 0;
    80000eb8:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ebc:	6422                	ld	s0,8(sp)
    80000ebe:	0141                	addi	sp,sp,16
    80000ec0:	8082                	ret

0000000080000ec2 <strlen>:

int
strlen(const char *s)
{
    80000ec2:	1141                	addi	sp,sp,-16
    80000ec4:	e422                	sd	s0,8(sp)
    80000ec6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ec8:	00054783          	lbu	a5,0(a0)
    80000ecc:	cf91                	beqz	a5,80000ee8 <strlen+0x26>
    80000ece:	0505                	addi	a0,a0,1
    80000ed0:	87aa                	mv	a5,a0
    80000ed2:	4685                	li	a3,1
    80000ed4:	9e89                	subw	a3,a3,a0
    80000ed6:	00f6853b          	addw	a0,a3,a5
    80000eda:	0785                	addi	a5,a5,1
    80000edc:	fff7c703          	lbu	a4,-1(a5)
    80000ee0:	fb7d                	bnez	a4,80000ed6 <strlen+0x14>
    ;
  return n;
}
    80000ee2:	6422                	ld	s0,8(sp)
    80000ee4:	0141                	addi	sp,sp,16
    80000ee6:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ee8:	4501                	li	a0,0
    80000eea:	bfe5                	j	80000ee2 <strlen+0x20>

0000000080000eec <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000eec:	1141                	addi	sp,sp,-16
    80000eee:	e406                	sd	ra,8(sp)
    80000ef0:	e022                	sd	s0,0(sp)
    80000ef2:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ef4:	00001097          	auipc	ra,0x1
    80000ef8:	bb8080e7          	jalr	-1096(ra) # 80001aac <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000efc:	00008717          	auipc	a4,0x8
    80000f00:	11070713          	addi	a4,a4,272 # 8000900c <started>
  if(cpuid() == 0){
    80000f04:	c139                	beqz	a0,80000f4a <main+0x5e>
    while(started == 0)
    80000f06:	431c                	lw	a5,0(a4)
    80000f08:	2781                	sext.w	a5,a5
    80000f0a:	dff5                	beqz	a5,80000f06 <main+0x1a>
      ;
    __sync_synchronize();
    80000f0c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f10:	00001097          	auipc	ra,0x1
    80000f14:	b9c080e7          	jalr	-1124(ra) # 80001aac <cpuid>
    80000f18:	85aa                	mv	a1,a0
    80000f1a:	00007517          	auipc	a0,0x7
    80000f1e:	19e50513          	addi	a0,a0,414 # 800080b8 <digits+0x78>
    80000f22:	fffff097          	auipc	ra,0xfffff
    80000f26:	670080e7          	jalr	1648(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	0d8080e7          	jalr	216(ra) # 80001002 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	804080e7          	jalr	-2044(ra) # 80002736 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	db6080e7          	jalr	-586(ra) # 80005cf0 <plicinithart>
  }

  scheduler();        
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	0c6080e7          	jalr	198(ra) # 80002008 <scheduler>
    consoleinit();
    80000f4a:	fffff097          	auipc	ra,0xfffff
    80000f4e:	510080e7          	jalr	1296(ra) # 8000045a <consoleinit>
    printfinit();
    80000f52:	00000097          	auipc	ra,0x0
    80000f56:	826080e7          	jalr	-2010(ra) # 80000778 <printfinit>
    printf("\n");
    80000f5a:	00007517          	auipc	a0,0x7
    80000f5e:	16e50513          	addi	a0,a0,366 # 800080c8 <digits+0x88>
    80000f62:	fffff097          	auipc	ra,0xfffff
    80000f66:	630080e7          	jalr	1584(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f6a:	00007517          	auipc	a0,0x7
    80000f6e:	13650513          	addi	a0,a0,310 # 800080a0 <digits+0x60>
    80000f72:	fffff097          	auipc	ra,0xfffff
    80000f76:	620080e7          	jalr	1568(ra) # 80000592 <printf>
    printf("\n");
    80000f7a:	00007517          	auipc	a0,0x7
    80000f7e:	14e50513          	addi	a0,a0,334 # 800080c8 <digits+0x88>
    80000f82:	fffff097          	auipc	ra,0xfffff
    80000f86:	610080e7          	jalr	1552(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f8a:	00000097          	auipc	ra,0x0
    80000f8e:	b74080e7          	jalr	-1164(ra) # 80000afe <kinit>
    kvminit();       // create kernel page table
    80000f92:	00000097          	auipc	ra,0x0
    80000f96:	2a0080e7          	jalr	672(ra) # 80001232 <kvminit>
    kvminithart();   // turn on paging
    80000f9a:	00000097          	auipc	ra,0x0
    80000f9e:	068080e7          	jalr	104(ra) # 80001002 <kvminithart>
    procinit();      // process table
    80000fa2:	00001097          	auipc	ra,0x1
    80000fa6:	a3a080e7          	jalr	-1478(ra) # 800019dc <procinit>
    trapinit();      // trap vectors
    80000faa:	00001097          	auipc	ra,0x1
    80000fae:	764080e7          	jalr	1892(ra) # 8000270e <trapinit>
    trapinithart();  // install kernel trap vector
    80000fb2:	00001097          	auipc	ra,0x1
    80000fb6:	784080e7          	jalr	1924(ra) # 80002736 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fba:	00005097          	auipc	ra,0x5
    80000fbe:	d20080e7          	jalr	-736(ra) # 80005cda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fc2:	00005097          	auipc	ra,0x5
    80000fc6:	d2e080e7          	jalr	-722(ra) # 80005cf0 <plicinithart>
    binit();         // buffer cache
    80000fca:	00002097          	auipc	ra,0x2
    80000fce:	ecc080e7          	jalr	-308(ra) # 80002e96 <binit>
    iinit();         // inode cache
    80000fd2:	00002097          	auipc	ra,0x2
    80000fd6:	55c080e7          	jalr	1372(ra) # 8000352e <iinit>
    fileinit();      // file table
    80000fda:	00003097          	auipc	ra,0x3
    80000fde:	4fa080e7          	jalr	1274(ra) # 800044d4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fe2:	00005097          	auipc	ra,0x5
    80000fe6:	e16080e7          	jalr	-490(ra) # 80005df8 <virtio_disk_init>
    userinit();      // first user process
    80000fea:	00001097          	auipc	ra,0x1
    80000fee:	db8080e7          	jalr	-584(ra) # 80001da2 <userinit>
    __sync_synchronize();
    80000ff2:	0ff0000f          	fence
    started = 1;
    80000ff6:	4785                	li	a5,1
    80000ff8:	00008717          	auipc	a4,0x8
    80000ffc:	00f72a23          	sw	a5,20(a4) # 8000900c <started>
    80001000:	b789                	j	80000f42 <main+0x56>

0000000080001002 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001002:	1141                	addi	sp,sp,-16
    80001004:	e422                	sd	s0,8(sp)
    80001006:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001008:	00008797          	auipc	a5,0x8
    8000100c:	0087b783          	ld	a5,8(a5) # 80009010 <kernel_pagetable>
    80001010:	83b1                	srli	a5,a5,0xc
    80001012:	577d                	li	a4,-1
    80001014:	177e                	slli	a4,a4,0x3f
    80001016:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001018:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000101c:	12000073          	sfence.vma
  sfence_vma();
}
    80001020:	6422                	ld	s0,8(sp)
    80001022:	0141                	addi	sp,sp,16
    80001024:	8082                	ret

0000000080001026 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001026:	7139                	addi	sp,sp,-64
    80001028:	fc06                	sd	ra,56(sp)
    8000102a:	f822                	sd	s0,48(sp)
    8000102c:	f426                	sd	s1,40(sp)
    8000102e:	f04a                	sd	s2,32(sp)
    80001030:	ec4e                	sd	s3,24(sp)
    80001032:	e852                	sd	s4,16(sp)
    80001034:	e456                	sd	s5,8(sp)
    80001036:	e05a                	sd	s6,0(sp)
    80001038:	0080                	addi	s0,sp,64
    8000103a:	84aa                	mv	s1,a0
    8000103c:	89ae                	mv	s3,a1
    8000103e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001040:	57fd                	li	a5,-1
    80001042:	83e9                	srli	a5,a5,0x1a
    80001044:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001046:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001048:	04b7f263          	bgeu	a5,a1,8000108c <walk+0x66>
    panic("walk");
    8000104c:	00007517          	auipc	a0,0x7
    80001050:	08450513          	addi	a0,a0,132 # 800080d0 <digits+0x90>
    80001054:	fffff097          	auipc	ra,0xfffff
    80001058:	4f4080e7          	jalr	1268(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000105c:	060a8663          	beqz	s5,800010c8 <walk+0xa2>
    80001060:	00000097          	auipc	ra,0x0
    80001064:	ada080e7          	jalr	-1318(ra) # 80000b3a <kalloc>
    80001068:	84aa                	mv	s1,a0
    8000106a:	c529                	beqz	a0,800010b4 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000106c:	6605                	lui	a2,0x1
    8000106e:	4581                	li	a1,0
    80001070:	00000097          	auipc	ra,0x0
    80001074:	cca080e7          	jalr	-822(ra) # 80000d3a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001078:	00c4d793          	srli	a5,s1,0xc
    8000107c:	07aa                	slli	a5,a5,0xa
    8000107e:	0017e793          	ori	a5,a5,1
    80001082:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001086:	3a5d                	addiw	s4,s4,-9
    80001088:	036a0063          	beq	s4,s6,800010a8 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000108c:	0149d933          	srl	s2,s3,s4
    80001090:	1ff97913          	andi	s2,s2,511
    80001094:	090e                	slli	s2,s2,0x3
    80001096:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001098:	00093483          	ld	s1,0(s2)
    8000109c:	0014f793          	andi	a5,s1,1
    800010a0:	dfd5                	beqz	a5,8000105c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010a2:	80a9                	srli	s1,s1,0xa
    800010a4:	04b2                	slli	s1,s1,0xc
    800010a6:	b7c5                	j	80001086 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010a8:	00c9d513          	srli	a0,s3,0xc
    800010ac:	1ff57513          	andi	a0,a0,511
    800010b0:	050e                	slli	a0,a0,0x3
    800010b2:	9526                	add	a0,a0,s1
}
    800010b4:	70e2                	ld	ra,56(sp)
    800010b6:	7442                	ld	s0,48(sp)
    800010b8:	74a2                	ld	s1,40(sp)
    800010ba:	7902                	ld	s2,32(sp)
    800010bc:	69e2                	ld	s3,24(sp)
    800010be:	6a42                	ld	s4,16(sp)
    800010c0:	6aa2                	ld	s5,8(sp)
    800010c2:	6b02                	ld	s6,0(sp)
    800010c4:	6121                	addi	sp,sp,64
    800010c6:	8082                	ret
        return 0;
    800010c8:	4501                	li	a0,0
    800010ca:	b7ed                	j	800010b4 <walk+0x8e>

00000000800010cc <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010cc:	57fd                	li	a5,-1
    800010ce:	83e9                	srli	a5,a5,0x1a
    800010d0:	00b7f463          	bgeu	a5,a1,800010d8 <walkaddr+0xc>
    return 0;
    800010d4:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010d6:	8082                	ret
{
    800010d8:	1141                	addi	sp,sp,-16
    800010da:	e406                	sd	ra,8(sp)
    800010dc:	e022                	sd	s0,0(sp)
    800010de:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010e0:	4601                	li	a2,0
    800010e2:	00000097          	auipc	ra,0x0
    800010e6:	f44080e7          	jalr	-188(ra) # 80001026 <walk>
  if(pte == 0)
    800010ea:	c105                	beqz	a0,8000110a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010ec:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010ee:	0117f693          	andi	a3,a5,17
    800010f2:	4745                	li	a4,17
    return 0;
    800010f4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010f6:	00e68663          	beq	a3,a4,80001102 <walkaddr+0x36>
}
    800010fa:	60a2                	ld	ra,8(sp)
    800010fc:	6402                	ld	s0,0(sp)
    800010fe:	0141                	addi	sp,sp,16
    80001100:	8082                	ret
  pa = PTE2PA(*pte);
    80001102:	00a7d513          	srli	a0,a5,0xa
    80001106:	0532                	slli	a0,a0,0xc
  return pa;
    80001108:	bfcd                	j	800010fa <walkaddr+0x2e>
    return 0;
    8000110a:	4501                	li	a0,0
    8000110c:	b7fd                	j	800010fa <walkaddr+0x2e>

000000008000110e <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000110e:	1101                	addi	sp,sp,-32
    80001110:	ec06                	sd	ra,24(sp)
    80001112:	e822                	sd	s0,16(sp)
    80001114:	e426                	sd	s1,8(sp)
    80001116:	1000                	addi	s0,sp,32
    80001118:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    8000111a:	1552                	slli	a0,a0,0x34
    8000111c:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001120:	4601                	li	a2,0
    80001122:	00008517          	auipc	a0,0x8
    80001126:	eee53503          	ld	a0,-274(a0) # 80009010 <kernel_pagetable>
    8000112a:	00000097          	auipc	ra,0x0
    8000112e:	efc080e7          	jalr	-260(ra) # 80001026 <walk>
  if(pte == 0)
    80001132:	cd09                	beqz	a0,8000114c <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001134:	6108                	ld	a0,0(a0)
    80001136:	00157793          	andi	a5,a0,1
    8000113a:	c38d                	beqz	a5,8000115c <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000113c:	8129                	srli	a0,a0,0xa
    8000113e:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001140:	9526                	add	a0,a0,s1
    80001142:	60e2                	ld	ra,24(sp)
    80001144:	6442                	ld	s0,16(sp)
    80001146:	64a2                	ld	s1,8(sp)
    80001148:	6105                	addi	sp,sp,32
    8000114a:	8082                	ret
    panic("kvmpa");
    8000114c:	00007517          	auipc	a0,0x7
    80001150:	f8c50513          	addi	a0,a0,-116 # 800080d8 <digits+0x98>
    80001154:	fffff097          	auipc	ra,0xfffff
    80001158:	3f4080e7          	jalr	1012(ra) # 80000548 <panic>
    panic("kvmpa");
    8000115c:	00007517          	auipc	a0,0x7
    80001160:	f7c50513          	addi	a0,a0,-132 # 800080d8 <digits+0x98>
    80001164:	fffff097          	auipc	ra,0xfffff
    80001168:	3e4080e7          	jalr	996(ra) # 80000548 <panic>

000000008000116c <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000116c:	715d                	addi	sp,sp,-80
    8000116e:	e486                	sd	ra,72(sp)
    80001170:	e0a2                	sd	s0,64(sp)
    80001172:	fc26                	sd	s1,56(sp)
    80001174:	f84a                	sd	s2,48(sp)
    80001176:	f44e                	sd	s3,40(sp)
    80001178:	f052                	sd	s4,32(sp)
    8000117a:	ec56                	sd	s5,24(sp)
    8000117c:	e85a                	sd	s6,16(sp)
    8000117e:	e45e                	sd	s7,8(sp)
    80001180:	0880                	addi	s0,sp,80
    80001182:	8aaa                	mv	s5,a0
    80001184:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001186:	777d                	lui	a4,0xfffff
    80001188:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000118c:	167d                	addi	a2,a2,-1
    8000118e:	00b609b3          	add	s3,a2,a1
    80001192:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001196:	893e                	mv	s2,a5
    80001198:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000119c:	6b85                	lui	s7,0x1
    8000119e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011a2:	4605                	li	a2,1
    800011a4:	85ca                	mv	a1,s2
    800011a6:	8556                	mv	a0,s5
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	e7e080e7          	jalr	-386(ra) # 80001026 <walk>
    800011b0:	c51d                	beqz	a0,800011de <mappages+0x72>
    if(*pte & PTE_V)
    800011b2:	611c                	ld	a5,0(a0)
    800011b4:	8b85                	andi	a5,a5,1
    800011b6:	ef81                	bnez	a5,800011ce <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011b8:	80b1                	srli	s1,s1,0xc
    800011ba:	04aa                	slli	s1,s1,0xa
    800011bc:	0164e4b3          	or	s1,s1,s6
    800011c0:	0014e493          	ori	s1,s1,1
    800011c4:	e104                	sd	s1,0(a0)
    if(a == last)
    800011c6:	03390863          	beq	s2,s3,800011f6 <mappages+0x8a>
    a += PGSIZE;
    800011ca:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011cc:	bfc9                	j	8000119e <mappages+0x32>
      panic("remap");
    800011ce:	00007517          	auipc	a0,0x7
    800011d2:	f1250513          	addi	a0,a0,-238 # 800080e0 <digits+0xa0>
    800011d6:	fffff097          	auipc	ra,0xfffff
    800011da:	372080e7          	jalr	882(ra) # 80000548 <panic>
      return -1;
    800011de:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011e0:	60a6                	ld	ra,72(sp)
    800011e2:	6406                	ld	s0,64(sp)
    800011e4:	74e2                	ld	s1,56(sp)
    800011e6:	7942                	ld	s2,48(sp)
    800011e8:	79a2                	ld	s3,40(sp)
    800011ea:	7a02                	ld	s4,32(sp)
    800011ec:	6ae2                	ld	s5,24(sp)
    800011ee:	6b42                	ld	s6,16(sp)
    800011f0:	6ba2                	ld	s7,8(sp)
    800011f2:	6161                	addi	sp,sp,80
    800011f4:	8082                	ret
  return 0;
    800011f6:	4501                	li	a0,0
    800011f8:	b7e5                	j	800011e0 <mappages+0x74>

00000000800011fa <kvmmap>:
{
    800011fa:	1141                	addi	sp,sp,-16
    800011fc:	e406                	sd	ra,8(sp)
    800011fe:	e022                	sd	s0,0(sp)
    80001200:	0800                	addi	s0,sp,16
    80001202:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001204:	86ae                	mv	a3,a1
    80001206:	85aa                	mv	a1,a0
    80001208:	00008517          	auipc	a0,0x8
    8000120c:	e0853503          	ld	a0,-504(a0) # 80009010 <kernel_pagetable>
    80001210:	00000097          	auipc	ra,0x0
    80001214:	f5c080e7          	jalr	-164(ra) # 8000116c <mappages>
    80001218:	e509                	bnez	a0,80001222 <kvmmap+0x28>
}
    8000121a:	60a2                	ld	ra,8(sp)
    8000121c:	6402                	ld	s0,0(sp)
    8000121e:	0141                	addi	sp,sp,16
    80001220:	8082                	ret
    panic("kvmmap");
    80001222:	00007517          	auipc	a0,0x7
    80001226:	ec650513          	addi	a0,a0,-314 # 800080e8 <digits+0xa8>
    8000122a:	fffff097          	auipc	ra,0xfffff
    8000122e:	31e080e7          	jalr	798(ra) # 80000548 <panic>

0000000080001232 <kvminit>:
{
    80001232:	1101                	addi	sp,sp,-32
    80001234:	ec06                	sd	ra,24(sp)
    80001236:	e822                	sd	s0,16(sp)
    80001238:	e426                	sd	s1,8(sp)
    8000123a:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000123c:	00000097          	auipc	ra,0x0
    80001240:	8fe080e7          	jalr	-1794(ra) # 80000b3a <kalloc>
    80001244:	00008797          	auipc	a5,0x8
    80001248:	dca7b623          	sd	a0,-564(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000124c:	6605                	lui	a2,0x1
    8000124e:	4581                	li	a1,0
    80001250:	00000097          	auipc	ra,0x0
    80001254:	aea080e7          	jalr	-1302(ra) # 80000d3a <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001258:	4699                	li	a3,6
    8000125a:	6605                	lui	a2,0x1
    8000125c:	100005b7          	lui	a1,0x10000
    80001260:	10000537          	lui	a0,0x10000
    80001264:	00000097          	auipc	ra,0x0
    80001268:	f96080e7          	jalr	-106(ra) # 800011fa <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000126c:	4699                	li	a3,6
    8000126e:	6605                	lui	a2,0x1
    80001270:	100015b7          	lui	a1,0x10001
    80001274:	10001537          	lui	a0,0x10001
    80001278:	00000097          	auipc	ra,0x0
    8000127c:	f82080e7          	jalr	-126(ra) # 800011fa <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001280:	4699                	li	a3,6
    80001282:	6641                	lui	a2,0x10
    80001284:	020005b7          	lui	a1,0x2000
    80001288:	02000537          	lui	a0,0x2000
    8000128c:	00000097          	auipc	ra,0x0
    80001290:	f6e080e7          	jalr	-146(ra) # 800011fa <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001294:	4699                	li	a3,6
    80001296:	00400637          	lui	a2,0x400
    8000129a:	0c0005b7          	lui	a1,0xc000
    8000129e:	0c000537          	lui	a0,0xc000
    800012a2:	00000097          	auipc	ra,0x0
    800012a6:	f58080e7          	jalr	-168(ra) # 800011fa <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012aa:	00007497          	auipc	s1,0x7
    800012ae:	d5648493          	addi	s1,s1,-682 # 80008000 <etext>
    800012b2:	46a9                	li	a3,10
    800012b4:	80007617          	auipc	a2,0x80007
    800012b8:	d4c60613          	addi	a2,a2,-692 # 8000 <_entry-0x7fff8000>
    800012bc:	4585                	li	a1,1
    800012be:	05fe                	slli	a1,a1,0x1f
    800012c0:	852e                	mv	a0,a1
    800012c2:	00000097          	auipc	ra,0x0
    800012c6:	f38080e7          	jalr	-200(ra) # 800011fa <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012ca:	4699                	li	a3,6
    800012cc:	4645                	li	a2,17
    800012ce:	066e                	slli	a2,a2,0x1b
    800012d0:	8e05                	sub	a2,a2,s1
    800012d2:	85a6                	mv	a1,s1
    800012d4:	8526                	mv	a0,s1
    800012d6:	00000097          	auipc	ra,0x0
    800012da:	f24080e7          	jalr	-220(ra) # 800011fa <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012de:	46a9                	li	a3,10
    800012e0:	6605                	lui	a2,0x1
    800012e2:	00006597          	auipc	a1,0x6
    800012e6:	d1e58593          	addi	a1,a1,-738 # 80007000 <_trampoline>
    800012ea:	04000537          	lui	a0,0x4000
    800012ee:	157d                	addi	a0,a0,-1
    800012f0:	0532                	slli	a0,a0,0xc
    800012f2:	00000097          	auipc	ra,0x0
    800012f6:	f08080e7          	jalr	-248(ra) # 800011fa <kvmmap>
}
    800012fa:	60e2                	ld	ra,24(sp)
    800012fc:	6442                	ld	s0,16(sp)
    800012fe:	64a2                	ld	s1,8(sp)
    80001300:	6105                	addi	sp,sp,32
    80001302:	8082                	ret

0000000080001304 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001304:	715d                	addi	sp,sp,-80
    80001306:	e486                	sd	ra,72(sp)
    80001308:	e0a2                	sd	s0,64(sp)
    8000130a:	fc26                	sd	s1,56(sp)
    8000130c:	f84a                	sd	s2,48(sp)
    8000130e:	f44e                	sd	s3,40(sp)
    80001310:	f052                	sd	s4,32(sp)
    80001312:	ec56                	sd	s5,24(sp)
    80001314:	e85a                	sd	s6,16(sp)
    80001316:	e45e                	sd	s7,8(sp)
    80001318:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000131a:	03459793          	slli	a5,a1,0x34
    8000131e:	e795                	bnez	a5,8000134a <uvmunmap+0x46>
    80001320:	8a2a                	mv	s4,a0
    80001322:	892e                	mv	s2,a1
    80001324:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001326:	0632                	slli	a2,a2,0xc
    80001328:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000132e:	6b05                	lui	s6,0x1
    80001330:	0735e863          	bltu	a1,s3,800013a0 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001334:	60a6                	ld	ra,72(sp)
    80001336:	6406                	ld	s0,64(sp)
    80001338:	74e2                	ld	s1,56(sp)
    8000133a:	7942                	ld	s2,48(sp)
    8000133c:	79a2                	ld	s3,40(sp)
    8000133e:	7a02                	ld	s4,32(sp)
    80001340:	6ae2                	ld	s5,24(sp)
    80001342:	6b42                	ld	s6,16(sp)
    80001344:	6ba2                	ld	s7,8(sp)
    80001346:	6161                	addi	sp,sp,80
    80001348:	8082                	ret
    panic("uvmunmap: not aligned");
    8000134a:	00007517          	auipc	a0,0x7
    8000134e:	da650513          	addi	a0,a0,-602 # 800080f0 <digits+0xb0>
    80001352:	fffff097          	auipc	ra,0xfffff
    80001356:	1f6080e7          	jalr	502(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    8000135a:	00007517          	auipc	a0,0x7
    8000135e:	dae50513          	addi	a0,a0,-594 # 80008108 <digits+0xc8>
    80001362:	fffff097          	auipc	ra,0xfffff
    80001366:	1e6080e7          	jalr	486(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    8000136a:	00007517          	auipc	a0,0x7
    8000136e:	dae50513          	addi	a0,a0,-594 # 80008118 <digits+0xd8>
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	1d6080e7          	jalr	470(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    8000137a:	00007517          	auipc	a0,0x7
    8000137e:	db650513          	addi	a0,a0,-586 # 80008130 <digits+0xf0>
    80001382:	fffff097          	auipc	ra,0xfffff
    80001386:	1c6080e7          	jalr	454(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    8000138a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000138c:	0532                	slli	a0,a0,0xc
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	696080e7          	jalr	1686(ra) # 80000a24 <kfree>
    *pte = 0;
    80001396:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000139a:	995a                	add	s2,s2,s6
    8000139c:	f9397ce3          	bgeu	s2,s3,80001334 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013a0:	4601                	li	a2,0
    800013a2:	85ca                	mv	a1,s2
    800013a4:	8552                	mv	a0,s4
    800013a6:	00000097          	auipc	ra,0x0
    800013aa:	c80080e7          	jalr	-896(ra) # 80001026 <walk>
    800013ae:	84aa                	mv	s1,a0
    800013b0:	d54d                	beqz	a0,8000135a <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013b2:	6108                	ld	a0,0(a0)
    800013b4:	00157793          	andi	a5,a0,1
    800013b8:	dbcd                	beqz	a5,8000136a <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013ba:	3ff57793          	andi	a5,a0,1023
    800013be:	fb778ee3          	beq	a5,s7,8000137a <uvmunmap+0x76>
    if(do_free){
    800013c2:	fc0a8ae3          	beqz	s5,80001396 <uvmunmap+0x92>
    800013c6:	b7d1                	j	8000138a <uvmunmap+0x86>

00000000800013c8 <walkcowaddr>:
uint64 walkcowaddr(pagetable_t pagetable, uint64 va) {
    800013c8:	7139                	addi	sp,sp,-64
    800013ca:	fc06                	sd	ra,56(sp)
    800013cc:	f822                	sd	s0,48(sp)
    800013ce:	f426                	sd	s1,40(sp)
    800013d0:	f04a                	sd	s2,32(sp)
    800013d2:	ec4e                	sd	s3,24(sp)
    800013d4:	e852                	sd	s4,16(sp)
    800013d6:	e456                	sd	s5,8(sp)
    800013d8:	e05a                	sd	s6,0(sp)
    800013da:	0080                	addi	s0,sp,64
  if (va >= MAXVA)
    800013dc:	57fd                	li	a5,-1
    800013de:	83e9                	srli	a5,a5,0x1a
    return 0;
    800013e0:	4901                	li	s2,0
  if (va >= MAXVA)
    800013e2:	00b7fd63          	bgeu	a5,a1,800013fc <walkcowaddr+0x34>
}
    800013e6:	854a                	mv	a0,s2
    800013e8:	70e2                	ld	ra,56(sp)
    800013ea:	7442                	ld	s0,48(sp)
    800013ec:	74a2                	ld	s1,40(sp)
    800013ee:	7902                	ld	s2,32(sp)
    800013f0:	69e2                	ld	s3,24(sp)
    800013f2:	6a42                	ld	s4,16(sp)
    800013f4:	6aa2                	ld	s5,8(sp)
    800013f6:	6b02                	ld	s6,0(sp)
    800013f8:	6121                	addi	sp,sp,64
    800013fa:	8082                	ret
    800013fc:	8a2a                	mv	s4,a0
    800013fe:	84ae                	mv	s1,a1
  pte = walk(pagetable, va, 0);
    80001400:	4601                	li	a2,0
    80001402:	00000097          	auipc	ra,0x0
    80001406:	c24080e7          	jalr	-988(ra) # 80001026 <walk>
    8000140a:	89aa                	mv	s3,a0
  if (pte == 0)
    8000140c:	c151                	beqz	a0,80001490 <walkcowaddr+0xc8>
  if ((*pte & PTE_V) == 0)
    8000140e:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    80001410:	0117f693          	andi	a3,a5,17
    80001414:	4745                	li	a4,17
    return 0;
    80001416:	4901                	li	s2,0
  if ((*pte & PTE_U) == 0)
    80001418:	fce697e3          	bne	a3,a4,800013e6 <walkcowaddr+0x1e>
  pa = PTE2PA(*pte);
    8000141c:	00a7d913          	srli	s2,a5,0xa
    80001420:	0932                	slli	s2,s2,0xc
  if ((*pte & PTE_W) == 0) {
    80001422:	0047fa93          	andi	s5,a5,4
    80001426:	fc0a90e3          	bnez	s5,800013e6 <walkcowaddr+0x1e>
    if ((*pte & PTE_COW) == 0) {
    8000142a:	1007f793          	andi	a5,a5,256
    8000142e:	e399                	bnez	a5,80001434 <walkcowaddr+0x6c>
        return 0;
    80001430:	893e                	mv	s2,a5
    80001432:	bf55                	j	800013e6 <walkcowaddr+0x1e>
    if ((mem = kalloc()) == 0) {
    80001434:	fffff097          	auipc	ra,0xfffff
    80001438:	706080e7          	jalr	1798(ra) # 80000b3a <kalloc>
    8000143c:	8b2a                	mv	s6,a0
    8000143e:	c939                	beqz	a0,80001494 <walkcowaddr+0xcc>
    memmove(mem, (void*)pa, PGSIZE);
    80001440:	6605                	lui	a2,0x1
    80001442:	85ca                	mv	a1,s2
    80001444:	00000097          	auipc	ra,0x0
    80001448:	956080e7          	jalr	-1706(ra) # 80000d9a <memmove>
    flags = (PTE_FLAGS(*pte) & (~PTE_COW)) | PTE_W;
    8000144c:	0009b983          	ld	s3,0(s3) # 2000 <_entry-0x7fffe000>
    80001450:	2fb9f993          	andi	s3,s3,763
    80001454:	0049e993          	ori	s3,s3,4
    uvmunmap(pagetable, PGROUNDDOWN(va), 1, 1);
    80001458:	77fd                	lui	a5,0xfffff
    8000145a:	8cfd                	and	s1,s1,a5
    8000145c:	4685                	li	a3,1
    8000145e:	4605                	li	a2,1
    80001460:	85a6                	mv	a1,s1
    80001462:	8552                	mv	a0,s4
    80001464:	00000097          	auipc	ra,0x0
    80001468:	ea0080e7          	jalr	-352(ra) # 80001304 <uvmunmap>
    if (mappages(pagetable, PGROUNDDOWN(va), PGSIZE, (uint64)mem, flags) != 0) {
    8000146c:	895a                	mv	s2,s6
    8000146e:	874e                	mv	a4,s3
    80001470:	86da                	mv	a3,s6
    80001472:	6605                	lui	a2,0x1
    80001474:	85a6                	mv	a1,s1
    80001476:	8552                	mv	a0,s4
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	cf4080e7          	jalr	-780(ra) # 8000116c <mappages>
    80001480:	d13d                	beqz	a0,800013e6 <walkcowaddr+0x1e>
      kfree(mem);
    80001482:	855a                	mv	a0,s6
    80001484:	fffff097          	auipc	ra,0xfffff
    80001488:	5a0080e7          	jalr	1440(ra) # 80000a24 <kfree>
      return 0;
    8000148c:	8956                	mv	s2,s5
    8000148e:	bfa1                	j	800013e6 <walkcowaddr+0x1e>
      return 0;
    80001490:	4901                	li	s2,0
    80001492:	bf91                	j	800013e6 <walkcowaddr+0x1e>
      return 0;
    80001494:	8956                	mv	s2,s5
    80001496:	bf81                	j	800013e6 <walkcowaddr+0x1e>

0000000080001498 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001498:	1101                	addi	sp,sp,-32
    8000149a:	ec06                	sd	ra,24(sp)
    8000149c:	e822                	sd	s0,16(sp)
    8000149e:	e426                	sd	s1,8(sp)
    800014a0:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014a2:	fffff097          	auipc	ra,0xfffff
    800014a6:	698080e7          	jalr	1688(ra) # 80000b3a <kalloc>
    800014aa:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014ac:	c519                	beqz	a0,800014ba <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014ae:	6605                	lui	a2,0x1
    800014b0:	4581                	li	a1,0
    800014b2:	00000097          	auipc	ra,0x0
    800014b6:	888080e7          	jalr	-1912(ra) # 80000d3a <memset>
  return pagetable;
}
    800014ba:	8526                	mv	a0,s1
    800014bc:	60e2                	ld	ra,24(sp)
    800014be:	6442                	ld	s0,16(sp)
    800014c0:	64a2                	ld	s1,8(sp)
    800014c2:	6105                	addi	sp,sp,32
    800014c4:	8082                	ret

00000000800014c6 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800014c6:	7179                	addi	sp,sp,-48
    800014c8:	f406                	sd	ra,40(sp)
    800014ca:	f022                	sd	s0,32(sp)
    800014cc:	ec26                	sd	s1,24(sp)
    800014ce:	e84a                	sd	s2,16(sp)
    800014d0:	e44e                	sd	s3,8(sp)
    800014d2:	e052                	sd	s4,0(sp)
    800014d4:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014d6:	6785                	lui	a5,0x1
    800014d8:	04f67863          	bgeu	a2,a5,80001528 <uvminit+0x62>
    800014dc:	8a2a                	mv	s4,a0
    800014de:	89ae                	mv	s3,a1
    800014e0:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800014e2:	fffff097          	auipc	ra,0xfffff
    800014e6:	658080e7          	jalr	1624(ra) # 80000b3a <kalloc>
    800014ea:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014ec:	6605                	lui	a2,0x1
    800014ee:	4581                	li	a1,0
    800014f0:	00000097          	auipc	ra,0x0
    800014f4:	84a080e7          	jalr	-1974(ra) # 80000d3a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014f8:	4779                	li	a4,30
    800014fa:	86ca                	mv	a3,s2
    800014fc:	6605                	lui	a2,0x1
    800014fe:	4581                	li	a1,0
    80001500:	8552                	mv	a0,s4
    80001502:	00000097          	auipc	ra,0x0
    80001506:	c6a080e7          	jalr	-918(ra) # 8000116c <mappages>
  memmove(mem, src, sz);
    8000150a:	8626                	mv	a2,s1
    8000150c:	85ce                	mv	a1,s3
    8000150e:	854a                	mv	a0,s2
    80001510:	00000097          	auipc	ra,0x0
    80001514:	88a080e7          	jalr	-1910(ra) # 80000d9a <memmove>
}
    80001518:	70a2                	ld	ra,40(sp)
    8000151a:	7402                	ld	s0,32(sp)
    8000151c:	64e2                	ld	s1,24(sp)
    8000151e:	6942                	ld	s2,16(sp)
    80001520:	69a2                	ld	s3,8(sp)
    80001522:	6a02                	ld	s4,0(sp)
    80001524:	6145                	addi	sp,sp,48
    80001526:	8082                	ret
    panic("inituvm: more than a page");
    80001528:	00007517          	auipc	a0,0x7
    8000152c:	c2050513          	addi	a0,a0,-992 # 80008148 <digits+0x108>
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	018080e7          	jalr	24(ra) # 80000548 <panic>

0000000080001538 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001538:	1101                	addi	sp,sp,-32
    8000153a:	ec06                	sd	ra,24(sp)
    8000153c:	e822                	sd	s0,16(sp)
    8000153e:	e426                	sd	s1,8(sp)
    80001540:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001542:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001544:	00b67d63          	bgeu	a2,a1,8000155e <uvmdealloc+0x26>
    80001548:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000154a:	6785                	lui	a5,0x1
    8000154c:	17fd                	addi	a5,a5,-1
    8000154e:	00f60733          	add	a4,a2,a5
    80001552:	767d                	lui	a2,0xfffff
    80001554:	8f71                	and	a4,a4,a2
    80001556:	97ae                	add	a5,a5,a1
    80001558:	8ff1                	and	a5,a5,a2
    8000155a:	00f76863          	bltu	a4,a5,8000156a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000155e:	8526                	mv	a0,s1
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000156a:	8f99                	sub	a5,a5,a4
    8000156c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000156e:	4685                	li	a3,1
    80001570:	0007861b          	sext.w	a2,a5
    80001574:	85ba                	mv	a1,a4
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d8e080e7          	jalr	-626(ra) # 80001304 <uvmunmap>
    8000157e:	b7c5                	j	8000155e <uvmdealloc+0x26>

0000000080001580 <uvmalloc>:
  if(newsz < oldsz)
    80001580:	0ab66163          	bltu	a2,a1,80001622 <uvmalloc+0xa2>
{
    80001584:	7139                	addi	sp,sp,-64
    80001586:	fc06                	sd	ra,56(sp)
    80001588:	f822                	sd	s0,48(sp)
    8000158a:	f426                	sd	s1,40(sp)
    8000158c:	f04a                	sd	s2,32(sp)
    8000158e:	ec4e                	sd	s3,24(sp)
    80001590:	e852                	sd	s4,16(sp)
    80001592:	e456                	sd	s5,8(sp)
    80001594:	0080                	addi	s0,sp,64
    80001596:	8aaa                	mv	s5,a0
    80001598:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000159a:	6985                	lui	s3,0x1
    8000159c:	19fd                	addi	s3,s3,-1
    8000159e:	95ce                	add	a1,a1,s3
    800015a0:	79fd                	lui	s3,0xfffff
    800015a2:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015a6:	08c9f063          	bgeu	s3,a2,80001626 <uvmalloc+0xa6>
    800015aa:	894e                	mv	s2,s3
    mem = kalloc();
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	58e080e7          	jalr	1422(ra) # 80000b3a <kalloc>
    800015b4:	84aa                	mv	s1,a0
    if(mem == 0){
    800015b6:	c51d                	beqz	a0,800015e4 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	4581                	li	a1,0
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	77e080e7          	jalr	1918(ra) # 80000d3a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800015c4:	4779                	li	a4,30
    800015c6:	86a6                	mv	a3,s1
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ca                	mv	a1,s2
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	b9e080e7          	jalr	-1122(ra) # 8000116c <mappages>
    800015d6:	e905                	bnez	a0,80001606 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	993e                	add	s2,s2,a5
    800015dc:	fd4968e3          	bltu	s2,s4,800015ac <uvmalloc+0x2c>
  return newsz;
    800015e0:	8552                	mv	a0,s4
    800015e2:	a809                	j	800015f4 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800015e4:	864e                	mv	a2,s3
    800015e6:	85ca                	mv	a1,s2
    800015e8:	8556                	mv	a0,s5
    800015ea:	00000097          	auipc	ra,0x0
    800015ee:	f4e080e7          	jalr	-178(ra) # 80001538 <uvmdealloc>
      return 0;
    800015f2:	4501                	li	a0,0
}
    800015f4:	70e2                	ld	ra,56(sp)
    800015f6:	7442                	ld	s0,48(sp)
    800015f8:	74a2                	ld	s1,40(sp)
    800015fa:	7902                	ld	s2,32(sp)
    800015fc:	69e2                	ld	s3,24(sp)
    800015fe:	6a42                	ld	s4,16(sp)
    80001600:	6aa2                	ld	s5,8(sp)
    80001602:	6121                	addi	sp,sp,64
    80001604:	8082                	ret
      kfree(mem);
    80001606:	8526                	mv	a0,s1
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	41c080e7          	jalr	1052(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001610:	864e                	mv	a2,s3
    80001612:	85ca                	mv	a1,s2
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	f22080e7          	jalr	-222(ra) # 80001538 <uvmdealloc>
      return 0;
    8000161e:	4501                	li	a0,0
    80001620:	bfd1                	j	800015f4 <uvmalloc+0x74>
    return oldsz;
    80001622:	852e                	mv	a0,a1
}
    80001624:	8082                	ret
  return newsz;
    80001626:	8532                	mv	a0,a2
    80001628:	b7f1                	j	800015f4 <uvmalloc+0x74>

000000008000162a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000162a:	7179                	addi	sp,sp,-48
    8000162c:	f406                	sd	ra,40(sp)
    8000162e:	f022                	sd	s0,32(sp)
    80001630:	ec26                	sd	s1,24(sp)
    80001632:	e84a                	sd	s2,16(sp)
    80001634:	e44e                	sd	s3,8(sp)
    80001636:	e052                	sd	s4,0(sp)
    80001638:	1800                	addi	s0,sp,48
    8000163a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000163c:	84aa                	mv	s1,a0
    8000163e:	6905                	lui	s2,0x1
    80001640:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001642:	4985                	li	s3,1
    80001644:	a821                	j	8000165c <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001646:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001648:	0532                	slli	a0,a0,0xc
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	fe0080e7          	jalr	-32(ra) # 8000162a <freewalk>
      pagetable[i] = 0;
    80001652:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001656:	04a1                	addi	s1,s1,8
    80001658:	03248163          	beq	s1,s2,8000167a <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000165c:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000165e:	00f57793          	andi	a5,a0,15
    80001662:	ff3782e3          	beq	a5,s3,80001646 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001666:	8905                	andi	a0,a0,1
    80001668:	d57d                	beqz	a0,80001656 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	afe50513          	addi	a0,a0,-1282 # 80008168 <digits+0x128>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ed6080e7          	jalr	-298(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    8000167a:	8552                	mv	a0,s4
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	3a8080e7          	jalr	936(ra) # 80000a24 <kfree>
}
    80001684:	70a2                	ld	ra,40(sp)
    80001686:	7402                	ld	s0,32(sp)
    80001688:	64e2                	ld	s1,24(sp)
    8000168a:	6942                	ld	s2,16(sp)
    8000168c:	69a2                	ld	s3,8(sp)
    8000168e:	6a02                	ld	s4,0(sp)
    80001690:	6145                	addi	sp,sp,48
    80001692:	8082                	ret

0000000080001694 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001694:	1101                	addi	sp,sp,-32
    80001696:	ec06                	sd	ra,24(sp)
    80001698:	e822                	sd	s0,16(sp)
    8000169a:	e426                	sd	s1,8(sp)
    8000169c:	1000                	addi	s0,sp,32
    8000169e:	84aa                	mv	s1,a0
  if(sz > 0)
    800016a0:	e999                	bnez	a1,800016b6 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016a2:	8526                	mv	a0,s1
    800016a4:	00000097          	auipc	ra,0x0
    800016a8:	f86080e7          	jalr	-122(ra) # 8000162a <freewalk>
}
    800016ac:	60e2                	ld	ra,24(sp)
    800016ae:	6442                	ld	s0,16(sp)
    800016b0:	64a2                	ld	s1,8(sp)
    800016b2:	6105                	addi	sp,sp,32
    800016b4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016b6:	6605                	lui	a2,0x1
    800016b8:	167d                	addi	a2,a2,-1
    800016ba:	962e                	add	a2,a2,a1
    800016bc:	4685                	li	a3,1
    800016be:	8231                	srli	a2,a2,0xc
    800016c0:	4581                	li	a1,0
    800016c2:	00000097          	auipc	ra,0x0
    800016c6:	c42080e7          	jalr	-958(ra) # 80001304 <uvmunmap>
    800016ca:	bfe1                	j	800016a2 <uvmfree+0xe>

00000000800016cc <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    800016cc:	715d                	addi	sp,sp,-80
    800016ce:	e486                	sd	ra,72(sp)
    800016d0:	e0a2                	sd	s0,64(sp)
    800016d2:	fc26                	sd	s1,56(sp)
    800016d4:	f84a                	sd	s2,48(sp)
    800016d6:	f44e                	sd	s3,40(sp)
    800016d8:	f052                	sd	s4,32(sp)
    800016da:	ec56                	sd	s5,24(sp)
    800016dc:	e85a                	sd	s6,16(sp)
    800016de:	e45e                	sd	s7,8(sp)
    800016e0:	0880                	addi	s0,sp,80
  pte_t *pte;
  uint64 pa, i;
  uint flags;
//  char *mem;  

  for(i = 0; i < sz; i += PGSIZE){
    800016e2:	ca55                	beqz	a2,80001796 <uvmcopy+0xca>
    800016e4:	8aaa                	mv	s5,a0
    800016e6:	8a2e                	mv	s4,a1
    800016e8:	89b2                	mv	s3,a2
    800016ea:	4481                	li	s1,0
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
      
    // 清除 PTE_W 标志，增加 COW标志
    flags = (PTE_FLAGS(*pte) & (~PTE_W)) | PTE_COW;
    *pte = PA2PTE(pa) | flags;  
    800016ec:	7b7d                	lui	s6,0xfffff
    800016ee:	002b5b13          	srli	s6,s6,0x2
    if((pte = walk(old, i, 0)) == 0)
    800016f2:	4601                	li	a2,0
    800016f4:	85a6                	mv	a1,s1
    800016f6:	8556                	mv	a0,s5
    800016f8:	00000097          	auipc	ra,0x0
    800016fc:	92e080e7          	jalr	-1746(ra) # 80001026 <walk>
    80001700:	c529                	beqz	a0,8000174a <uvmcopy+0x7e>
    if((*pte & PTE_V) == 0)
    80001702:	611c                	ld	a5,0(a0)
    80001704:	0017f713          	andi	a4,a5,1
    80001708:	cb29                	beqz	a4,8000175a <uvmcopy+0x8e>
    pa = PTE2PA(*pte);
    8000170a:	00a7d913          	srli	s2,a5,0xa
    8000170e:	0932                	slli	s2,s2,0xc
    flags = (PTE_FLAGS(*pte) & (~PTE_W)) | PTE_COW;
    80001710:	2fb7f713          	andi	a4,a5,763
    *pte = PA2PTE(pa) | flags;  
    80001714:	0167f7b3          	and	a5,a5,s6
    80001718:	10076693          	ori	a3,a4,256
    8000171c:	8fd5                	or	a5,a5,a3
    8000171e:	e11c                	sd	a5,0(a0)
      
// COW不需要分配实际的物理页面
//    if((mem = kalloc()) == 0)
//      goto err;
//    memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, pa, flags) != 0){   
    80001720:	8736                	mv	a4,a3
    80001722:	86ca                	mv	a3,s2
    80001724:	6605                	lui	a2,0x1
    80001726:	85a6                	mv	a1,s1
    80001728:	8552                	mv	a0,s4
    8000172a:	00000097          	auipc	ra,0x0
    8000172e:	a42080e7          	jalr	-1470(ra) # 8000116c <mappages>
    80001732:	8baa                	mv	s7,a0
    80001734:	e91d                	bnez	a0,8000176a <uvmcopy+0x9e>
//      kfree(mem);    
      goto err;
    }
    increfcnt(pa);   // 引用数+1
    80001736:	854a                	mv	a0,s2
    80001738:	00005097          	auipc	ra,0x5
    8000173c:	b6c080e7          	jalr	-1172(ra) # 800062a4 <increfcnt>
  for(i = 0; i < sz; i += PGSIZE){
    80001740:	6785                	lui	a5,0x1
    80001742:	94be                	add	s1,s1,a5
    80001744:	fb34e7e3          	bltu	s1,s3,800016f2 <uvmcopy+0x26>
    80001748:	a81d                	j	8000177e <uvmcopy+0xb2>
      panic("uvmcopy: pte should exist");
    8000174a:	00007517          	auipc	a0,0x7
    8000174e:	a2e50513          	addi	a0,a0,-1490 # 80008178 <digits+0x138>
    80001752:	fffff097          	auipc	ra,0xfffff
    80001756:	df6080e7          	jalr	-522(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    8000175a:	00007517          	auipc	a0,0x7
    8000175e:	a3e50513          	addi	a0,a0,-1474 # 80008198 <digits+0x158>
    80001762:	fffff097          	auipc	ra,0xfffff
    80001766:	de6080e7          	jalr	-538(ra) # 80000548 <panic>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000176a:	4685                	li	a3,1
    8000176c:	00c4d613          	srli	a2,s1,0xc
    80001770:	4581                	li	a1,0
    80001772:	8552                	mv	a0,s4
    80001774:	00000097          	auipc	ra,0x0
    80001778:	b90080e7          	jalr	-1136(ra) # 80001304 <uvmunmap>
  return -1;
    8000177c:	5bfd                	li	s7,-1
}
    8000177e:	855e                	mv	a0,s7
    80001780:	60a6                	ld	ra,72(sp)
    80001782:	6406                	ld	s0,64(sp)
    80001784:	74e2                	ld	s1,56(sp)
    80001786:	7942                	ld	s2,48(sp)
    80001788:	79a2                	ld	s3,40(sp)
    8000178a:	7a02                	ld	s4,32(sp)
    8000178c:	6ae2                	ld	s5,24(sp)
    8000178e:	6b42                	ld	s6,16(sp)
    80001790:	6ba2                	ld	s7,8(sp)
    80001792:	6161                	addi	sp,sp,80
    80001794:	8082                	ret
  return 0;
    80001796:	4b81                	li	s7,0
    80001798:	b7dd                	j	8000177e <uvmcopy+0xb2>

000000008000179a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000179a:	1141                	addi	sp,sp,-16
    8000179c:	e406                	sd	ra,8(sp)
    8000179e:	e022                	sd	s0,0(sp)
    800017a0:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800017a2:	4601                	li	a2,0
    800017a4:	00000097          	auipc	ra,0x0
    800017a8:	882080e7          	jalr	-1918(ra) # 80001026 <walk>
  if(pte == 0)
    800017ac:	c901                	beqz	a0,800017bc <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017ae:	611c                	ld	a5,0(a0)
    800017b0:	9bbd                	andi	a5,a5,-17
    800017b2:	e11c                	sd	a5,0(a0)
}
    800017b4:	60a2                	ld	ra,8(sp)
    800017b6:	6402                	ld	s0,0(sp)
    800017b8:	0141                	addi	sp,sp,16
    800017ba:	8082                	ret
    panic("uvmclear");
    800017bc:	00007517          	auipc	a0,0x7
    800017c0:	9fc50513          	addi	a0,a0,-1540 # 800081b8 <digits+0x178>
    800017c4:	fffff097          	auipc	ra,0xfffff
    800017c8:	d84080e7          	jalr	-636(ra) # 80000548 <panic>

00000000800017cc <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017cc:	c6bd                	beqz	a3,8000183a <copyout+0x6e>
{
    800017ce:	715d                	addi	sp,sp,-80
    800017d0:	e486                	sd	ra,72(sp)
    800017d2:	e0a2                	sd	s0,64(sp)
    800017d4:	fc26                	sd	s1,56(sp)
    800017d6:	f84a                	sd	s2,48(sp)
    800017d8:	f44e                	sd	s3,40(sp)
    800017da:	f052                	sd	s4,32(sp)
    800017dc:	ec56                	sd	s5,24(sp)
    800017de:	e85a                	sd	s6,16(sp)
    800017e0:	e45e                	sd	s7,8(sp)
    800017e2:	e062                	sd	s8,0(sp)
    800017e4:	0880                	addi	s0,sp,80
    800017e6:	8b2a                	mv	s6,a0
    800017e8:	8c2e                	mv	s8,a1
    800017ea:	8a32                	mv	s4,a2
    800017ec:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017ee:	7bfd                	lui	s7,0xfffff
    pa0 = walkcowaddr(pagetable, va0);  // with COW - lab6
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017f0:	6a85                	lui	s5,0x1
    800017f2:	a015                	j	80001816 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017f4:	9562                	add	a0,a0,s8
    800017f6:	0004861b          	sext.w	a2,s1
    800017fa:	85d2                	mv	a1,s4
    800017fc:	41250533          	sub	a0,a0,s2
    80001800:	fffff097          	auipc	ra,0xfffff
    80001804:	59a080e7          	jalr	1434(ra) # 80000d9a <memmove>

    len -= n;
    80001808:	409989b3          	sub	s3,s3,s1
    src += n;
    8000180c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000180e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001812:	02098263          	beqz	s3,80001836 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001816:	017c7933          	and	s2,s8,s7
    pa0 = walkcowaddr(pagetable, va0);  // with COW - lab6
    8000181a:	85ca                	mv	a1,s2
    8000181c:	855a                	mv	a0,s6
    8000181e:	00000097          	auipc	ra,0x0
    80001822:	baa080e7          	jalr	-1110(ra) # 800013c8 <walkcowaddr>
    if(pa0 == 0)
    80001826:	cd01                	beqz	a0,8000183e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001828:	418904b3          	sub	s1,s2,s8
    8000182c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000182e:	fc99f3e3          	bgeu	s3,s1,800017f4 <copyout+0x28>
    80001832:	84ce                	mv	s1,s3
    80001834:	b7c1                	j	800017f4 <copyout+0x28>
  }
  return 0;
    80001836:	4501                	li	a0,0
    80001838:	a021                	j	80001840 <copyout+0x74>
    8000183a:	4501                	li	a0,0
}
    8000183c:	8082                	ret
      return -1;
    8000183e:	557d                	li	a0,-1
}
    80001840:	60a6                	ld	ra,72(sp)
    80001842:	6406                	ld	s0,64(sp)
    80001844:	74e2                	ld	s1,56(sp)
    80001846:	7942                	ld	s2,48(sp)
    80001848:	79a2                	ld	s3,40(sp)
    8000184a:	7a02                	ld	s4,32(sp)
    8000184c:	6ae2                	ld	s5,24(sp)
    8000184e:	6b42                	ld	s6,16(sp)
    80001850:	6ba2                	ld	s7,8(sp)
    80001852:	6c02                	ld	s8,0(sp)
    80001854:	6161                	addi	sp,sp,80
    80001856:	8082                	ret

0000000080001858 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001858:	c6bd                	beqz	a3,800018c6 <copyin+0x6e>
{
    8000185a:	715d                	addi	sp,sp,-80
    8000185c:	e486                	sd	ra,72(sp)
    8000185e:	e0a2                	sd	s0,64(sp)
    80001860:	fc26                	sd	s1,56(sp)
    80001862:	f84a                	sd	s2,48(sp)
    80001864:	f44e                	sd	s3,40(sp)
    80001866:	f052                	sd	s4,32(sp)
    80001868:	ec56                	sd	s5,24(sp)
    8000186a:	e85a                	sd	s6,16(sp)
    8000186c:	e45e                	sd	s7,8(sp)
    8000186e:	e062                	sd	s8,0(sp)
    80001870:	0880                	addi	s0,sp,80
    80001872:	8b2a                	mv	s6,a0
    80001874:	8a2e                	mv	s4,a1
    80001876:	8c32                	mv	s8,a2
    80001878:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000187a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000187c:	6a85                	lui	s5,0x1
    8000187e:	a015                	j	800018a2 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001880:	9562                	add	a0,a0,s8
    80001882:	0004861b          	sext.w	a2,s1
    80001886:	412505b3          	sub	a1,a0,s2
    8000188a:	8552                	mv	a0,s4
    8000188c:	fffff097          	auipc	ra,0xfffff
    80001890:	50e080e7          	jalr	1294(ra) # 80000d9a <memmove>

    len -= n;
    80001894:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001898:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000189a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000189e:	02098263          	beqz	s3,800018c2 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800018a2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018a6:	85ca                	mv	a1,s2
    800018a8:	855a                	mv	a0,s6
    800018aa:	00000097          	auipc	ra,0x0
    800018ae:	822080e7          	jalr	-2014(ra) # 800010cc <walkaddr>
    if(pa0 == 0)
    800018b2:	cd01                	beqz	a0,800018ca <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800018b4:	418904b3          	sub	s1,s2,s8
    800018b8:	94d6                	add	s1,s1,s5
    if(n > len)
    800018ba:	fc99f3e3          	bgeu	s3,s1,80001880 <copyin+0x28>
    800018be:	84ce                	mv	s1,s3
    800018c0:	b7c1                	j	80001880 <copyin+0x28>
  }
  return 0;
    800018c2:	4501                	li	a0,0
    800018c4:	a021                	j	800018cc <copyin+0x74>
    800018c6:	4501                	li	a0,0
}
    800018c8:	8082                	ret
      return -1;
    800018ca:	557d                	li	a0,-1
}
    800018cc:	60a6                	ld	ra,72(sp)
    800018ce:	6406                	ld	s0,64(sp)
    800018d0:	74e2                	ld	s1,56(sp)
    800018d2:	7942                	ld	s2,48(sp)
    800018d4:	79a2                	ld	s3,40(sp)
    800018d6:	7a02                	ld	s4,32(sp)
    800018d8:	6ae2                	ld	s5,24(sp)
    800018da:	6b42                	ld	s6,16(sp)
    800018dc:	6ba2                	ld	s7,8(sp)
    800018de:	6c02                	ld	s8,0(sp)
    800018e0:	6161                	addi	sp,sp,80
    800018e2:	8082                	ret

00000000800018e4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018e4:	c6c5                	beqz	a3,8000198c <copyinstr+0xa8>
{
    800018e6:	715d                	addi	sp,sp,-80
    800018e8:	e486                	sd	ra,72(sp)
    800018ea:	e0a2                	sd	s0,64(sp)
    800018ec:	fc26                	sd	s1,56(sp)
    800018ee:	f84a                	sd	s2,48(sp)
    800018f0:	f44e                	sd	s3,40(sp)
    800018f2:	f052                	sd	s4,32(sp)
    800018f4:	ec56                	sd	s5,24(sp)
    800018f6:	e85a                	sd	s6,16(sp)
    800018f8:	e45e                	sd	s7,8(sp)
    800018fa:	0880                	addi	s0,sp,80
    800018fc:	8a2a                	mv	s4,a0
    800018fe:	8b2e                	mv	s6,a1
    80001900:	8bb2                	mv	s7,a2
    80001902:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001904:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001906:	6985                	lui	s3,0x1
    80001908:	a035                	j	80001934 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000190a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000190e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001910:	0017b793          	seqz	a5,a5
    80001914:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001918:	60a6                	ld	ra,72(sp)
    8000191a:	6406                	ld	s0,64(sp)
    8000191c:	74e2                	ld	s1,56(sp)
    8000191e:	7942                	ld	s2,48(sp)
    80001920:	79a2                	ld	s3,40(sp)
    80001922:	7a02                	ld	s4,32(sp)
    80001924:	6ae2                	ld	s5,24(sp)
    80001926:	6b42                	ld	s6,16(sp)
    80001928:	6ba2                	ld	s7,8(sp)
    8000192a:	6161                	addi	sp,sp,80
    8000192c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000192e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001932:	c8a9                	beqz	s1,80001984 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001934:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001938:	85ca                	mv	a1,s2
    8000193a:	8552                	mv	a0,s4
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	790080e7          	jalr	1936(ra) # 800010cc <walkaddr>
    if(pa0 == 0)
    80001944:	c131                	beqz	a0,80001988 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001946:	41790833          	sub	a6,s2,s7
    8000194a:	984e                	add	a6,a6,s3
    if(n > max)
    8000194c:	0104f363          	bgeu	s1,a6,80001952 <copyinstr+0x6e>
    80001950:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001952:	955e                	add	a0,a0,s7
    80001954:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001958:	fc080be3          	beqz	a6,8000192e <copyinstr+0x4a>
    8000195c:	985a                	add	a6,a6,s6
    8000195e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001960:	41650633          	sub	a2,a0,s6
    80001964:	14fd                	addi	s1,s1,-1
    80001966:	9b26                	add	s6,s6,s1
    80001968:	00f60733          	add	a4,a2,a5
    8000196c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fed9000>
    80001970:	df49                	beqz	a4,8000190a <copyinstr+0x26>
        *dst = *p;
    80001972:	00e78023          	sb	a4,0(a5)
      --max;
    80001976:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000197a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000197c:	ff0796e3          	bne	a5,a6,80001968 <copyinstr+0x84>
      dst++;
    80001980:	8b42                	mv	s6,a6
    80001982:	b775                	j	8000192e <copyinstr+0x4a>
    80001984:	4781                	li	a5,0
    80001986:	b769                	j	80001910 <copyinstr+0x2c>
      return -1;
    80001988:	557d                	li	a0,-1
    8000198a:	b779                	j	80001918 <copyinstr+0x34>
  int got_null = 0;
    8000198c:	4781                	li	a5,0
  if(got_null){
    8000198e:	0017b793          	seqz	a5,a5
    80001992:	40f00533          	neg	a0,a5
}
    80001996:	8082                	ret

0000000080001998 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001998:	1101                	addi	sp,sp,-32
    8000199a:	ec06                	sd	ra,24(sp)
    8000199c:	e822                	sd	s0,16(sp)
    8000199e:	e426                	sd	s1,8(sp)
    800019a0:	1000                	addi	s0,sp,32
    800019a2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800019a4:	fffff097          	auipc	ra,0xfffff
    800019a8:	220080e7          	jalr	544(ra) # 80000bc4 <holding>
    800019ac:	c909                	beqz	a0,800019be <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800019ae:	749c                	ld	a5,40(s1)
    800019b0:	00978f63          	beq	a5,s1,800019ce <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800019b4:	60e2                	ld	ra,24(sp)
    800019b6:	6442                	ld	s0,16(sp)
    800019b8:	64a2                	ld	s1,8(sp)
    800019ba:	6105                	addi	sp,sp,32
    800019bc:	8082                	ret
    panic("wakeup1");
    800019be:	00007517          	auipc	a0,0x7
    800019c2:	80a50513          	addi	a0,a0,-2038 # 800081c8 <digits+0x188>
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	b82080e7          	jalr	-1150(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800019ce:	4c98                	lw	a4,24(s1)
    800019d0:	4785                	li	a5,1
    800019d2:	fef711e3          	bne	a4,a5,800019b4 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800019d6:	4789                	li	a5,2
    800019d8:	cc9c                	sw	a5,24(s1)
}
    800019da:	bfe9                	j	800019b4 <wakeup1+0x1c>

00000000800019dc <procinit>:
{
    800019dc:	715d                	addi	sp,sp,-80
    800019de:	e486                	sd	ra,72(sp)
    800019e0:	e0a2                	sd	s0,64(sp)
    800019e2:	fc26                	sd	s1,56(sp)
    800019e4:	f84a                	sd	s2,48(sp)
    800019e6:	f44e                	sd	s3,40(sp)
    800019e8:	f052                	sd	s4,32(sp)
    800019ea:	ec56                	sd	s5,24(sp)
    800019ec:	e85a                	sd	s6,16(sp)
    800019ee:	e45e                	sd	s7,8(sp)
    800019f0:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800019f2:	00006597          	auipc	a1,0x6
    800019f6:	7de58593          	addi	a1,a1,2014 # 800081d0 <digits+0x190>
    800019fa:	00010517          	auipc	a0,0x10
    800019fe:	f5650513          	addi	a0,a0,-170 # 80011950 <pid_lock>
    80001a02:	fffff097          	auipc	ra,0xfffff
    80001a06:	1ac080e7          	jalr	428(ra) # 80000bae <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a0a:	00010917          	auipc	s2,0x10
    80001a0e:	35e90913          	addi	s2,s2,862 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001a12:	00006b97          	auipc	s7,0x6
    80001a16:	7c6b8b93          	addi	s7,s7,1990 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001a1a:	8b4a                	mv	s6,s2
    80001a1c:	00006a97          	auipc	s5,0x6
    80001a20:	5e4a8a93          	addi	s5,s5,1508 # 80008000 <etext>
    80001a24:	040009b7          	lui	s3,0x4000
    80001a28:	19fd                	addi	s3,s3,-1
    80001a2a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a2c:	00016a17          	auipc	s4,0x16
    80001a30:	d3ca0a13          	addi	s4,s4,-708 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001a34:	85de                	mv	a1,s7
    80001a36:	854a                	mv	a0,s2
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	176080e7          	jalr	374(ra) # 80000bae <initlock>
      char *pa = kalloc();
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	0fa080e7          	jalr	250(ra) # 80000b3a <kalloc>
    80001a48:	85aa                	mv	a1,a0
      if(pa == 0)
    80001a4a:	c929                	beqz	a0,80001a9c <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001a4c:	416904b3          	sub	s1,s2,s6
    80001a50:	848d                	srai	s1,s1,0x3
    80001a52:	000ab783          	ld	a5,0(s5)
    80001a56:	02f484b3          	mul	s1,s1,a5
    80001a5a:	2485                	addiw	s1,s1,1
    80001a5c:	00d4949b          	slliw	s1,s1,0xd
    80001a60:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a64:	4699                	li	a3,6
    80001a66:	6605                	lui	a2,0x1
    80001a68:	8526                	mv	a0,s1
    80001a6a:	fffff097          	auipc	ra,0xfffff
    80001a6e:	790080e7          	jalr	1936(ra) # 800011fa <kvmmap>
      p->kstack = va;
    80001a72:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a76:	16890913          	addi	s2,s2,360
    80001a7a:	fb491de3          	bne	s2,s4,80001a34 <procinit+0x58>
  kvminithart();
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	584080e7          	jalr	1412(ra) # 80001002 <kvminithart>
}
    80001a86:	60a6                	ld	ra,72(sp)
    80001a88:	6406                	ld	s0,64(sp)
    80001a8a:	74e2                	ld	s1,56(sp)
    80001a8c:	7942                	ld	s2,48(sp)
    80001a8e:	79a2                	ld	s3,40(sp)
    80001a90:	7a02                	ld	s4,32(sp)
    80001a92:	6ae2                	ld	s5,24(sp)
    80001a94:	6b42                	ld	s6,16(sp)
    80001a96:	6ba2                	ld	s7,8(sp)
    80001a98:	6161                	addi	sp,sp,80
    80001a9a:	8082                	ret
        panic("kalloc");
    80001a9c:	00006517          	auipc	a0,0x6
    80001aa0:	74450513          	addi	a0,a0,1860 # 800081e0 <digits+0x1a0>
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	aa4080e7          	jalr	-1372(ra) # 80000548 <panic>

0000000080001aac <cpuid>:
{
    80001aac:	1141                	addi	sp,sp,-16
    80001aae:	e422                	sd	s0,8(sp)
    80001ab0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ab2:	8512                	mv	a0,tp
}
    80001ab4:	2501                	sext.w	a0,a0
    80001ab6:	6422                	ld	s0,8(sp)
    80001ab8:	0141                	addi	sp,sp,16
    80001aba:	8082                	ret

0000000080001abc <mycpu>:
mycpu(void) {
    80001abc:	1141                	addi	sp,sp,-16
    80001abe:	e422                	sd	s0,8(sp)
    80001ac0:	0800                	addi	s0,sp,16
    80001ac2:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ac4:	2781                	sext.w	a5,a5
    80001ac6:	079e                	slli	a5,a5,0x7
}
    80001ac8:	00010517          	auipc	a0,0x10
    80001acc:	ea050513          	addi	a0,a0,-352 # 80011968 <cpus>
    80001ad0:	953e                	add	a0,a0,a5
    80001ad2:	6422                	ld	s0,8(sp)
    80001ad4:	0141                	addi	sp,sp,16
    80001ad6:	8082                	ret

0000000080001ad8 <myproc>:
myproc(void) {
    80001ad8:	1101                	addi	sp,sp,-32
    80001ada:	ec06                	sd	ra,24(sp)
    80001adc:	e822                	sd	s0,16(sp)
    80001ade:	e426                	sd	s1,8(sp)
    80001ae0:	1000                	addi	s0,sp,32
  push_off();
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	110080e7          	jalr	272(ra) # 80000bf2 <push_off>
    80001aea:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001aec:	2781                	sext.w	a5,a5
    80001aee:	079e                	slli	a5,a5,0x7
    80001af0:	00010717          	auipc	a4,0x10
    80001af4:	e6070713          	addi	a4,a4,-416 # 80011950 <pid_lock>
    80001af8:	97ba                	add	a5,a5,a4
    80001afa:	6f84                	ld	s1,24(a5)
  pop_off();
    80001afc:	fffff097          	auipc	ra,0xfffff
    80001b00:	196080e7          	jalr	406(ra) # 80000c92 <pop_off>
}
    80001b04:	8526                	mv	a0,s1
    80001b06:	60e2                	ld	ra,24(sp)
    80001b08:	6442                	ld	s0,16(sp)
    80001b0a:	64a2                	ld	s1,8(sp)
    80001b0c:	6105                	addi	sp,sp,32
    80001b0e:	8082                	ret

0000000080001b10 <forkret>:
{
    80001b10:	1141                	addi	sp,sp,-16
    80001b12:	e406                	sd	ra,8(sp)
    80001b14:	e022                	sd	s0,0(sp)
    80001b16:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b18:	00000097          	auipc	ra,0x0
    80001b1c:	fc0080e7          	jalr	-64(ra) # 80001ad8 <myproc>
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	1d2080e7          	jalr	466(ra) # 80000cf2 <release>
  if (first) {
    80001b28:	00007797          	auipc	a5,0x7
    80001b2c:	ce87a783          	lw	a5,-792(a5) # 80008810 <first.1669>
    80001b30:	eb89                	bnez	a5,80001b42 <forkret+0x32>
  usertrapret();
    80001b32:	00001097          	auipc	ra,0x1
    80001b36:	c1c080e7          	jalr	-996(ra) # 8000274e <usertrapret>
}
    80001b3a:	60a2                	ld	ra,8(sp)
    80001b3c:	6402                	ld	s0,0(sp)
    80001b3e:	0141                	addi	sp,sp,16
    80001b40:	8082                	ret
    first = 0;
    80001b42:	00007797          	auipc	a5,0x7
    80001b46:	cc07a723          	sw	zero,-818(a5) # 80008810 <first.1669>
    fsinit(ROOTDEV);
    80001b4a:	4505                	li	a0,1
    80001b4c:	00002097          	auipc	ra,0x2
    80001b50:	962080e7          	jalr	-1694(ra) # 800034ae <fsinit>
    80001b54:	bff9                	j	80001b32 <forkret+0x22>

0000000080001b56 <allocpid>:
allocpid() {
    80001b56:	1101                	addi	sp,sp,-32
    80001b58:	ec06                	sd	ra,24(sp)
    80001b5a:	e822                	sd	s0,16(sp)
    80001b5c:	e426                	sd	s1,8(sp)
    80001b5e:	e04a                	sd	s2,0(sp)
    80001b60:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b62:	00010917          	auipc	s2,0x10
    80001b66:	dee90913          	addi	s2,s2,-530 # 80011950 <pid_lock>
    80001b6a:	854a                	mv	a0,s2
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	0d2080e7          	jalr	210(ra) # 80000c3e <acquire>
  pid = nextpid;
    80001b74:	00007797          	auipc	a5,0x7
    80001b78:	ca078793          	addi	a5,a5,-864 # 80008814 <nextpid>
    80001b7c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b7e:	0014871b          	addiw	a4,s1,1
    80001b82:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b84:	854a                	mv	a0,s2
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	16c080e7          	jalr	364(ra) # 80000cf2 <release>
}
    80001b8e:	8526                	mv	a0,s1
    80001b90:	60e2                	ld	ra,24(sp)
    80001b92:	6442                	ld	s0,16(sp)
    80001b94:	64a2                	ld	s1,8(sp)
    80001b96:	6902                	ld	s2,0(sp)
    80001b98:	6105                	addi	sp,sp,32
    80001b9a:	8082                	ret

0000000080001b9c <proc_pagetable>:
{
    80001b9c:	1101                	addi	sp,sp,-32
    80001b9e:	ec06                	sd	ra,24(sp)
    80001ba0:	e822                	sd	s0,16(sp)
    80001ba2:	e426                	sd	s1,8(sp)
    80001ba4:	e04a                	sd	s2,0(sp)
    80001ba6:	1000                	addi	s0,sp,32
    80001ba8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001baa:	00000097          	auipc	ra,0x0
    80001bae:	8ee080e7          	jalr	-1810(ra) # 80001498 <uvmcreate>
    80001bb2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bb4:	c121                	beqz	a0,80001bf4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bb6:	4729                	li	a4,10
    80001bb8:	00005697          	auipc	a3,0x5
    80001bbc:	44868693          	addi	a3,a3,1096 # 80007000 <_trampoline>
    80001bc0:	6605                	lui	a2,0x1
    80001bc2:	040005b7          	lui	a1,0x4000
    80001bc6:	15fd                	addi	a1,a1,-1
    80001bc8:	05b2                	slli	a1,a1,0xc
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	5a2080e7          	jalr	1442(ra) # 8000116c <mappages>
    80001bd2:	02054863          	bltz	a0,80001c02 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bd6:	4719                	li	a4,6
    80001bd8:	05893683          	ld	a3,88(s2)
    80001bdc:	6605                	lui	a2,0x1
    80001bde:	020005b7          	lui	a1,0x2000
    80001be2:	15fd                	addi	a1,a1,-1
    80001be4:	05b6                	slli	a1,a1,0xd
    80001be6:	8526                	mv	a0,s1
    80001be8:	fffff097          	auipc	ra,0xfffff
    80001bec:	584080e7          	jalr	1412(ra) # 8000116c <mappages>
    80001bf0:	02054163          	bltz	a0,80001c12 <proc_pagetable+0x76>
}
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	60e2                	ld	ra,24(sp)
    80001bf8:	6442                	ld	s0,16(sp)
    80001bfa:	64a2                	ld	s1,8(sp)
    80001bfc:	6902                	ld	s2,0(sp)
    80001bfe:	6105                	addi	sp,sp,32
    80001c00:	8082                	ret
    uvmfree(pagetable, 0);
    80001c02:	4581                	li	a1,0
    80001c04:	8526                	mv	a0,s1
    80001c06:	00000097          	auipc	ra,0x0
    80001c0a:	a8e080e7          	jalr	-1394(ra) # 80001694 <uvmfree>
    return 0;
    80001c0e:	4481                	li	s1,0
    80001c10:	b7d5                	j	80001bf4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c12:	4681                	li	a3,0
    80001c14:	4605                	li	a2,1
    80001c16:	040005b7          	lui	a1,0x4000
    80001c1a:	15fd                	addi	a1,a1,-1
    80001c1c:	05b2                	slli	a1,a1,0xc
    80001c1e:	8526                	mv	a0,s1
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	6e4080e7          	jalr	1764(ra) # 80001304 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c28:	4581                	li	a1,0
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	a68080e7          	jalr	-1432(ra) # 80001694 <uvmfree>
    return 0;
    80001c34:	4481                	li	s1,0
    80001c36:	bf7d                	j	80001bf4 <proc_pagetable+0x58>

0000000080001c38 <proc_freepagetable>:
{
    80001c38:	1101                	addi	sp,sp,-32
    80001c3a:	ec06                	sd	ra,24(sp)
    80001c3c:	e822                	sd	s0,16(sp)
    80001c3e:	e426                	sd	s1,8(sp)
    80001c40:	e04a                	sd	s2,0(sp)
    80001c42:	1000                	addi	s0,sp,32
    80001c44:	84aa                	mv	s1,a0
    80001c46:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c48:	4681                	li	a3,0
    80001c4a:	4605                	li	a2,1
    80001c4c:	040005b7          	lui	a1,0x4000
    80001c50:	15fd                	addi	a1,a1,-1
    80001c52:	05b2                	slli	a1,a1,0xc
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	6b0080e7          	jalr	1712(ra) # 80001304 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c5c:	4681                	li	a3,0
    80001c5e:	4605                	li	a2,1
    80001c60:	020005b7          	lui	a1,0x2000
    80001c64:	15fd                	addi	a1,a1,-1
    80001c66:	05b6                	slli	a1,a1,0xd
    80001c68:	8526                	mv	a0,s1
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	69a080e7          	jalr	1690(ra) # 80001304 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c72:	85ca                	mv	a1,s2
    80001c74:	8526                	mv	a0,s1
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	a1e080e7          	jalr	-1506(ra) # 80001694 <uvmfree>
}
    80001c7e:	60e2                	ld	ra,24(sp)
    80001c80:	6442                	ld	s0,16(sp)
    80001c82:	64a2                	ld	s1,8(sp)
    80001c84:	6902                	ld	s2,0(sp)
    80001c86:	6105                	addi	sp,sp,32
    80001c88:	8082                	ret

0000000080001c8a <freeproc>:
{
    80001c8a:	1101                	addi	sp,sp,-32
    80001c8c:	ec06                	sd	ra,24(sp)
    80001c8e:	e822                	sd	s0,16(sp)
    80001c90:	e426                	sd	s1,8(sp)
    80001c92:	1000                	addi	s0,sp,32
    80001c94:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c96:	6d28                	ld	a0,88(a0)
    80001c98:	c509                	beqz	a0,80001ca2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	d8a080e7          	jalr	-630(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001ca2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ca6:	68a8                	ld	a0,80(s1)
    80001ca8:	c511                	beqz	a0,80001cb4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001caa:	64ac                	ld	a1,72(s1)
    80001cac:	00000097          	auipc	ra,0x0
    80001cb0:	f8c080e7          	jalr	-116(ra) # 80001c38 <proc_freepagetable>
  p->pagetable = 0;
    80001cb4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cb8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cbc:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001cc0:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001cc4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cc8:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001ccc:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001cd0:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001cd4:	0004ac23          	sw	zero,24(s1)
}
    80001cd8:	60e2                	ld	ra,24(sp)
    80001cda:	6442                	ld	s0,16(sp)
    80001cdc:	64a2                	ld	s1,8(sp)
    80001cde:	6105                	addi	sp,sp,32
    80001ce0:	8082                	ret

0000000080001ce2 <allocproc>:
{
    80001ce2:	1101                	addi	sp,sp,-32
    80001ce4:	ec06                	sd	ra,24(sp)
    80001ce6:	e822                	sd	s0,16(sp)
    80001ce8:	e426                	sd	s1,8(sp)
    80001cea:	e04a                	sd	s2,0(sp)
    80001cec:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cee:	00010497          	auipc	s1,0x10
    80001cf2:	07a48493          	addi	s1,s1,122 # 80011d68 <proc>
    80001cf6:	00016917          	auipc	s2,0x16
    80001cfa:	a7290913          	addi	s2,s2,-1422 # 80017768 <tickslock>
    acquire(&p->lock);
    80001cfe:	8526                	mv	a0,s1
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	f3e080e7          	jalr	-194(ra) # 80000c3e <acquire>
    if(p->state == UNUSED) {
    80001d08:	4c9c                	lw	a5,24(s1)
    80001d0a:	cf81                	beqz	a5,80001d22 <allocproc+0x40>
      release(&p->lock);
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	fe4080e7          	jalr	-28(ra) # 80000cf2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d16:	16848493          	addi	s1,s1,360
    80001d1a:	ff2492e3          	bne	s1,s2,80001cfe <allocproc+0x1c>
  return 0;
    80001d1e:	4481                	li	s1,0
    80001d20:	a0b9                	j	80001d6e <allocproc+0x8c>
  p->pid = allocpid();
    80001d22:	00000097          	auipc	ra,0x0
    80001d26:	e34080e7          	jalr	-460(ra) # 80001b56 <allocpid>
    80001d2a:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	e0e080e7          	jalr	-498(ra) # 80000b3a <kalloc>
    80001d34:	892a                	mv	s2,a0
    80001d36:	eca8                	sd	a0,88(s1)
    80001d38:	c131                	beqz	a0,80001d7c <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001d3a:	8526                	mv	a0,s1
    80001d3c:	00000097          	auipc	ra,0x0
    80001d40:	e60080e7          	jalr	-416(ra) # 80001b9c <proc_pagetable>
    80001d44:	892a                	mv	s2,a0
    80001d46:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d48:	c129                	beqz	a0,80001d8a <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001d4a:	07000613          	li	a2,112
    80001d4e:	4581                	li	a1,0
    80001d50:	06048513          	addi	a0,s1,96
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	fe6080e7          	jalr	-26(ra) # 80000d3a <memset>
  p->context.ra = (uint64)forkret;
    80001d5c:	00000797          	auipc	a5,0x0
    80001d60:	db478793          	addi	a5,a5,-588 # 80001b10 <forkret>
    80001d64:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d66:	60bc                	ld	a5,64(s1)
    80001d68:	6705                	lui	a4,0x1
    80001d6a:	97ba                	add	a5,a5,a4
    80001d6c:	f4bc                	sd	a5,104(s1)
}
    80001d6e:	8526                	mv	a0,s1
    80001d70:	60e2                	ld	ra,24(sp)
    80001d72:	6442                	ld	s0,16(sp)
    80001d74:	64a2                	ld	s1,8(sp)
    80001d76:	6902                	ld	s2,0(sp)
    80001d78:	6105                	addi	sp,sp,32
    80001d7a:	8082                	ret
    release(&p->lock);
    80001d7c:	8526                	mv	a0,s1
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	f74080e7          	jalr	-140(ra) # 80000cf2 <release>
    return 0;
    80001d86:	84ca                	mv	s1,s2
    80001d88:	b7dd                	j	80001d6e <allocproc+0x8c>
    freeproc(p);
    80001d8a:	8526                	mv	a0,s1
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	efe080e7          	jalr	-258(ra) # 80001c8a <freeproc>
    release(&p->lock);
    80001d94:	8526                	mv	a0,s1
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	f5c080e7          	jalr	-164(ra) # 80000cf2 <release>
    return 0;
    80001d9e:	84ca                	mv	s1,s2
    80001da0:	b7f9                	j	80001d6e <allocproc+0x8c>

0000000080001da2 <userinit>:
{
    80001da2:	1101                	addi	sp,sp,-32
    80001da4:	ec06                	sd	ra,24(sp)
    80001da6:	e822                	sd	s0,16(sp)
    80001da8:	e426                	sd	s1,8(sp)
    80001daa:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	f36080e7          	jalr	-202(ra) # 80001ce2 <allocproc>
    80001db4:	84aa                	mv	s1,a0
  initproc = p;
    80001db6:	00007797          	auipc	a5,0x7
    80001dba:	26a7b123          	sd	a0,610(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001dbe:	03400613          	li	a2,52
    80001dc2:	00007597          	auipc	a1,0x7
    80001dc6:	a5e58593          	addi	a1,a1,-1442 # 80008820 <initcode>
    80001dca:	6928                	ld	a0,80(a0)
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	6fa080e7          	jalr	1786(ra) # 800014c6 <uvminit>
  p->sz = PGSIZE;
    80001dd4:	6785                	lui	a5,0x1
    80001dd6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dd8:	6cb8                	ld	a4,88(s1)
    80001dda:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dde:	6cb8                	ld	a4,88(s1)
    80001de0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001de2:	4641                	li	a2,16
    80001de4:	00006597          	auipc	a1,0x6
    80001de8:	40458593          	addi	a1,a1,1028 # 800081e8 <digits+0x1a8>
    80001dec:	15848513          	addi	a0,s1,344
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	0a0080e7          	jalr	160(ra) # 80000e90 <safestrcpy>
  p->cwd = namei("/");
    80001df8:	00006517          	auipc	a0,0x6
    80001dfc:	40050513          	addi	a0,a0,1024 # 800081f8 <digits+0x1b8>
    80001e00:	00002097          	auipc	ra,0x2
    80001e04:	0da080e7          	jalr	218(ra) # 80003eda <namei>
    80001e08:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e0c:	4789                	li	a5,2
    80001e0e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e10:	8526                	mv	a0,s1
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	ee0080e7          	jalr	-288(ra) # 80000cf2 <release>
}
    80001e1a:	60e2                	ld	ra,24(sp)
    80001e1c:	6442                	ld	s0,16(sp)
    80001e1e:	64a2                	ld	s1,8(sp)
    80001e20:	6105                	addi	sp,sp,32
    80001e22:	8082                	ret

0000000080001e24 <growproc>:
{
    80001e24:	1101                	addi	sp,sp,-32
    80001e26:	ec06                	sd	ra,24(sp)
    80001e28:	e822                	sd	s0,16(sp)
    80001e2a:	e426                	sd	s1,8(sp)
    80001e2c:	e04a                	sd	s2,0(sp)
    80001e2e:	1000                	addi	s0,sp,32
    80001e30:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	ca6080e7          	jalr	-858(ra) # 80001ad8 <myproc>
    80001e3a:	892a                	mv	s2,a0
  sz = p->sz;
    80001e3c:	652c                	ld	a1,72(a0)
    80001e3e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e42:	00904f63          	bgtz	s1,80001e60 <growproc+0x3c>
  } else if(n < 0){
    80001e46:	0204cc63          	bltz	s1,80001e7e <growproc+0x5a>
  p->sz = sz;
    80001e4a:	1602                	slli	a2,a2,0x20
    80001e4c:	9201                	srli	a2,a2,0x20
    80001e4e:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e52:	4501                	li	a0,0
}
    80001e54:	60e2                	ld	ra,24(sp)
    80001e56:	6442                	ld	s0,16(sp)
    80001e58:	64a2                	ld	s1,8(sp)
    80001e5a:	6902                	ld	s2,0(sp)
    80001e5c:	6105                	addi	sp,sp,32
    80001e5e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e60:	9e25                	addw	a2,a2,s1
    80001e62:	1602                	slli	a2,a2,0x20
    80001e64:	9201                	srli	a2,a2,0x20
    80001e66:	1582                	slli	a1,a1,0x20
    80001e68:	9181                	srli	a1,a1,0x20
    80001e6a:	6928                	ld	a0,80(a0)
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	714080e7          	jalr	1812(ra) # 80001580 <uvmalloc>
    80001e74:	0005061b          	sext.w	a2,a0
    80001e78:	fa69                	bnez	a2,80001e4a <growproc+0x26>
      return -1;
    80001e7a:	557d                	li	a0,-1
    80001e7c:	bfe1                	j	80001e54 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e7e:	9e25                	addw	a2,a2,s1
    80001e80:	1602                	slli	a2,a2,0x20
    80001e82:	9201                	srli	a2,a2,0x20
    80001e84:	1582                	slli	a1,a1,0x20
    80001e86:	9181                	srli	a1,a1,0x20
    80001e88:	6928                	ld	a0,80(a0)
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	6ae080e7          	jalr	1710(ra) # 80001538 <uvmdealloc>
    80001e92:	0005061b          	sext.w	a2,a0
    80001e96:	bf55                	j	80001e4a <growproc+0x26>

0000000080001e98 <fork>:
{
    80001e98:	7179                	addi	sp,sp,-48
    80001e9a:	f406                	sd	ra,40(sp)
    80001e9c:	f022                	sd	s0,32(sp)
    80001e9e:	ec26                	sd	s1,24(sp)
    80001ea0:	e84a                	sd	s2,16(sp)
    80001ea2:	e44e                	sd	s3,8(sp)
    80001ea4:	e052                	sd	s4,0(sp)
    80001ea6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	c30080e7          	jalr	-976(ra) # 80001ad8 <myproc>
    80001eb0:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001eb2:	00000097          	auipc	ra,0x0
    80001eb6:	e30080e7          	jalr	-464(ra) # 80001ce2 <allocproc>
    80001eba:	c175                	beqz	a0,80001f9e <fork+0x106>
    80001ebc:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ebe:	04893603          	ld	a2,72(s2)
    80001ec2:	692c                	ld	a1,80(a0)
    80001ec4:	05093503          	ld	a0,80(s2)
    80001ec8:	00000097          	auipc	ra,0x0
    80001ecc:	804080e7          	jalr	-2044(ra) # 800016cc <uvmcopy>
    80001ed0:	04054863          	bltz	a0,80001f20 <fork+0x88>
  np->sz = p->sz;
    80001ed4:	04893783          	ld	a5,72(s2)
    80001ed8:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001edc:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ee0:	05893683          	ld	a3,88(s2)
    80001ee4:	87b6                	mv	a5,a3
    80001ee6:	0589b703          	ld	a4,88(s3)
    80001eea:	12068693          	addi	a3,a3,288
    80001eee:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ef2:	6788                	ld	a0,8(a5)
    80001ef4:	6b8c                	ld	a1,16(a5)
    80001ef6:	6f90                	ld	a2,24(a5)
    80001ef8:	01073023          	sd	a6,0(a4)
    80001efc:	e708                	sd	a0,8(a4)
    80001efe:	eb0c                	sd	a1,16(a4)
    80001f00:	ef10                	sd	a2,24(a4)
    80001f02:	02078793          	addi	a5,a5,32
    80001f06:	02070713          	addi	a4,a4,32
    80001f0a:	fed792e3          	bne	a5,a3,80001eee <fork+0x56>
  np->trapframe->a0 = 0;
    80001f0e:	0589b783          	ld	a5,88(s3)
    80001f12:	0607b823          	sd	zero,112(a5)
    80001f16:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f1a:	15000a13          	li	s4,336
    80001f1e:	a03d                	j	80001f4c <fork+0xb4>
    freeproc(np);
    80001f20:	854e                	mv	a0,s3
    80001f22:	00000097          	auipc	ra,0x0
    80001f26:	d68080e7          	jalr	-664(ra) # 80001c8a <freeproc>
    release(&np->lock);
    80001f2a:	854e                	mv	a0,s3
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	dc6080e7          	jalr	-570(ra) # 80000cf2 <release>
    return -1;
    80001f34:	54fd                	li	s1,-1
    80001f36:	a899                	j	80001f8c <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f38:	00002097          	auipc	ra,0x2
    80001f3c:	62e080e7          	jalr	1582(ra) # 80004566 <filedup>
    80001f40:	009987b3          	add	a5,s3,s1
    80001f44:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f46:	04a1                	addi	s1,s1,8
    80001f48:	01448763          	beq	s1,s4,80001f56 <fork+0xbe>
    if(p->ofile[i])
    80001f4c:	009907b3          	add	a5,s2,s1
    80001f50:	6388                	ld	a0,0(a5)
    80001f52:	f17d                	bnez	a0,80001f38 <fork+0xa0>
    80001f54:	bfcd                	j	80001f46 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001f56:	15093503          	ld	a0,336(s2)
    80001f5a:	00001097          	auipc	ra,0x1
    80001f5e:	78e080e7          	jalr	1934(ra) # 800036e8 <idup>
    80001f62:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f66:	4641                	li	a2,16
    80001f68:	15890593          	addi	a1,s2,344
    80001f6c:	15898513          	addi	a0,s3,344
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	f20080e7          	jalr	-224(ra) # 80000e90 <safestrcpy>
  pid = np->pid;
    80001f78:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001f7c:	4789                	li	a5,2
    80001f7e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f82:	854e                	mv	a0,s3
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	d6e080e7          	jalr	-658(ra) # 80000cf2 <release>
}
    80001f8c:	8526                	mv	a0,s1
    80001f8e:	70a2                	ld	ra,40(sp)
    80001f90:	7402                	ld	s0,32(sp)
    80001f92:	64e2                	ld	s1,24(sp)
    80001f94:	6942                	ld	s2,16(sp)
    80001f96:	69a2                	ld	s3,8(sp)
    80001f98:	6a02                	ld	s4,0(sp)
    80001f9a:	6145                	addi	sp,sp,48
    80001f9c:	8082                	ret
    return -1;
    80001f9e:	54fd                	li	s1,-1
    80001fa0:	b7f5                	j	80001f8c <fork+0xf4>

0000000080001fa2 <reparent>:
{
    80001fa2:	7179                	addi	sp,sp,-48
    80001fa4:	f406                	sd	ra,40(sp)
    80001fa6:	f022                	sd	s0,32(sp)
    80001fa8:	ec26                	sd	s1,24(sp)
    80001faa:	e84a                	sd	s2,16(sp)
    80001fac:	e44e                	sd	s3,8(sp)
    80001fae:	e052                	sd	s4,0(sp)
    80001fb0:	1800                	addi	s0,sp,48
    80001fb2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fb4:	00010497          	auipc	s1,0x10
    80001fb8:	db448493          	addi	s1,s1,-588 # 80011d68 <proc>
      pp->parent = initproc;
    80001fbc:	00007a17          	auipc	s4,0x7
    80001fc0:	05ca0a13          	addi	s4,s4,92 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fc4:	00015997          	auipc	s3,0x15
    80001fc8:	7a498993          	addi	s3,s3,1956 # 80017768 <tickslock>
    80001fcc:	a029                	j	80001fd6 <reparent+0x34>
    80001fce:	16848493          	addi	s1,s1,360
    80001fd2:	03348363          	beq	s1,s3,80001ff8 <reparent+0x56>
    if(pp->parent == p){
    80001fd6:	709c                	ld	a5,32(s1)
    80001fd8:	ff279be3          	bne	a5,s2,80001fce <reparent+0x2c>
      acquire(&pp->lock);
    80001fdc:	8526                	mv	a0,s1
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	c60080e7          	jalr	-928(ra) # 80000c3e <acquire>
      pp->parent = initproc;
    80001fe6:	000a3783          	ld	a5,0(s4)
    80001fea:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001fec:	8526                	mv	a0,s1
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	d04080e7          	jalr	-764(ra) # 80000cf2 <release>
    80001ff6:	bfe1                	j	80001fce <reparent+0x2c>
}
    80001ff8:	70a2                	ld	ra,40(sp)
    80001ffa:	7402                	ld	s0,32(sp)
    80001ffc:	64e2                	ld	s1,24(sp)
    80001ffe:	6942                	ld	s2,16(sp)
    80002000:	69a2                	ld	s3,8(sp)
    80002002:	6a02                	ld	s4,0(sp)
    80002004:	6145                	addi	sp,sp,48
    80002006:	8082                	ret

0000000080002008 <scheduler>:
{
    80002008:	711d                	addi	sp,sp,-96
    8000200a:	ec86                	sd	ra,88(sp)
    8000200c:	e8a2                	sd	s0,80(sp)
    8000200e:	e4a6                	sd	s1,72(sp)
    80002010:	e0ca                	sd	s2,64(sp)
    80002012:	fc4e                	sd	s3,56(sp)
    80002014:	f852                	sd	s4,48(sp)
    80002016:	f456                	sd	s5,40(sp)
    80002018:	f05a                	sd	s6,32(sp)
    8000201a:	ec5e                	sd	s7,24(sp)
    8000201c:	e862                	sd	s8,16(sp)
    8000201e:	e466                	sd	s9,8(sp)
    80002020:	1080                	addi	s0,sp,96
    80002022:	8792                	mv	a5,tp
  int id = r_tp();
    80002024:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002026:	00779c13          	slli	s8,a5,0x7
    8000202a:	00010717          	auipc	a4,0x10
    8000202e:	92670713          	addi	a4,a4,-1754 # 80011950 <pid_lock>
    80002032:	9762                	add	a4,a4,s8
    80002034:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002038:	00010717          	auipc	a4,0x10
    8000203c:	93870713          	addi	a4,a4,-1736 # 80011970 <cpus+0x8>
    80002040:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80002042:	4a89                	li	s5,2
        c->proc = p;
    80002044:	079e                	slli	a5,a5,0x7
    80002046:	00010b17          	auipc	s6,0x10
    8000204a:	90ab0b13          	addi	s6,s6,-1782 # 80011950 <pid_lock>
    8000204e:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002050:	00015a17          	auipc	s4,0x15
    80002054:	718a0a13          	addi	s4,s4,1816 # 80017768 <tickslock>
    int nproc = 0;
    80002058:	4c81                	li	s9,0
    8000205a:	a8a1                	j	800020b2 <scheduler+0xaa>
        p->state = RUNNING;
    8000205c:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80002060:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80002064:	06048593          	addi	a1,s1,96
    80002068:	8562                	mv	a0,s8
    8000206a:	00000097          	auipc	ra,0x0
    8000206e:	63a080e7          	jalr	1594(ra) # 800026a4 <swtch>
        c->proc = 0;
    80002072:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80002076:	8526                	mv	a0,s1
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	c7a080e7          	jalr	-902(ra) # 80000cf2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002080:	16848493          	addi	s1,s1,360
    80002084:	01448d63          	beq	s1,s4,8000209e <scheduler+0x96>
      acquire(&p->lock);
    80002088:	8526                	mv	a0,s1
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	bb4080e7          	jalr	-1100(ra) # 80000c3e <acquire>
      if(p->state != UNUSED) {
    80002092:	4c9c                	lw	a5,24(s1)
    80002094:	d3ed                	beqz	a5,80002076 <scheduler+0x6e>
        nproc++;
    80002096:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80002098:	fd579fe3          	bne	a5,s5,80002076 <scheduler+0x6e>
    8000209c:	b7c1                	j	8000205c <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    8000209e:	013aca63          	blt	s5,s3,800020b2 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020a2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020a6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020aa:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800020ae:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020b2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020b6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020ba:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    800020be:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    800020c0:	00010497          	auipc	s1,0x10
    800020c4:	ca848493          	addi	s1,s1,-856 # 80011d68 <proc>
        p->state = RUNNING;
    800020c8:	4b8d                	li	s7,3
    800020ca:	bf7d                	j	80002088 <scheduler+0x80>

00000000800020cc <sched>:
{
    800020cc:	7179                	addi	sp,sp,-48
    800020ce:	f406                	sd	ra,40(sp)
    800020d0:	f022                	sd	s0,32(sp)
    800020d2:	ec26                	sd	s1,24(sp)
    800020d4:	e84a                	sd	s2,16(sp)
    800020d6:	e44e                	sd	s3,8(sp)
    800020d8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020da:	00000097          	auipc	ra,0x0
    800020de:	9fe080e7          	jalr	-1538(ra) # 80001ad8 <myproc>
    800020e2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ae0080e7          	jalr	-1312(ra) # 80000bc4 <holding>
    800020ec:	c93d                	beqz	a0,80002162 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ee:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020f0:	2781                	sext.w	a5,a5
    800020f2:	079e                	slli	a5,a5,0x7
    800020f4:	00010717          	auipc	a4,0x10
    800020f8:	85c70713          	addi	a4,a4,-1956 # 80011950 <pid_lock>
    800020fc:	97ba                	add	a5,a5,a4
    800020fe:	0907a703          	lw	a4,144(a5)
    80002102:	4785                	li	a5,1
    80002104:	06f71763          	bne	a4,a5,80002172 <sched+0xa6>
  if(p->state == RUNNING)
    80002108:	4c98                	lw	a4,24(s1)
    8000210a:	478d                	li	a5,3
    8000210c:	06f70b63          	beq	a4,a5,80002182 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002110:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002114:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002116:	efb5                	bnez	a5,80002192 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002118:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000211a:	00010917          	auipc	s2,0x10
    8000211e:	83690913          	addi	s2,s2,-1994 # 80011950 <pid_lock>
    80002122:	2781                	sext.w	a5,a5
    80002124:	079e                	slli	a5,a5,0x7
    80002126:	97ca                	add	a5,a5,s2
    80002128:	0947a983          	lw	s3,148(a5)
    8000212c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000212e:	2781                	sext.w	a5,a5
    80002130:	079e                	slli	a5,a5,0x7
    80002132:	00010597          	auipc	a1,0x10
    80002136:	83e58593          	addi	a1,a1,-1986 # 80011970 <cpus+0x8>
    8000213a:	95be                	add	a1,a1,a5
    8000213c:	06048513          	addi	a0,s1,96
    80002140:	00000097          	auipc	ra,0x0
    80002144:	564080e7          	jalr	1380(ra) # 800026a4 <swtch>
    80002148:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000214a:	2781                	sext.w	a5,a5
    8000214c:	079e                	slli	a5,a5,0x7
    8000214e:	97ca                	add	a5,a5,s2
    80002150:	0937aa23          	sw	s3,148(a5)
}
    80002154:	70a2                	ld	ra,40(sp)
    80002156:	7402                	ld	s0,32(sp)
    80002158:	64e2                	ld	s1,24(sp)
    8000215a:	6942                	ld	s2,16(sp)
    8000215c:	69a2                	ld	s3,8(sp)
    8000215e:	6145                	addi	sp,sp,48
    80002160:	8082                	ret
    panic("sched p->lock");
    80002162:	00006517          	auipc	a0,0x6
    80002166:	09e50513          	addi	a0,a0,158 # 80008200 <digits+0x1c0>
    8000216a:	ffffe097          	auipc	ra,0xffffe
    8000216e:	3de080e7          	jalr	990(ra) # 80000548 <panic>
    panic("sched locks");
    80002172:	00006517          	auipc	a0,0x6
    80002176:	09e50513          	addi	a0,a0,158 # 80008210 <digits+0x1d0>
    8000217a:	ffffe097          	auipc	ra,0xffffe
    8000217e:	3ce080e7          	jalr	974(ra) # 80000548 <panic>
    panic("sched running");
    80002182:	00006517          	auipc	a0,0x6
    80002186:	09e50513          	addi	a0,a0,158 # 80008220 <digits+0x1e0>
    8000218a:	ffffe097          	auipc	ra,0xffffe
    8000218e:	3be080e7          	jalr	958(ra) # 80000548 <panic>
    panic("sched interruptible");
    80002192:	00006517          	auipc	a0,0x6
    80002196:	09e50513          	addi	a0,a0,158 # 80008230 <digits+0x1f0>
    8000219a:	ffffe097          	auipc	ra,0xffffe
    8000219e:	3ae080e7          	jalr	942(ra) # 80000548 <panic>

00000000800021a2 <exit>:
{
    800021a2:	7179                	addi	sp,sp,-48
    800021a4:	f406                	sd	ra,40(sp)
    800021a6:	f022                	sd	s0,32(sp)
    800021a8:	ec26                	sd	s1,24(sp)
    800021aa:	e84a                	sd	s2,16(sp)
    800021ac:	e44e                	sd	s3,8(sp)
    800021ae:	e052                	sd	s4,0(sp)
    800021b0:	1800                	addi	s0,sp,48
    800021b2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021b4:	00000097          	auipc	ra,0x0
    800021b8:	924080e7          	jalr	-1756(ra) # 80001ad8 <myproc>
    800021bc:	89aa                	mv	s3,a0
  if(p == initproc)
    800021be:	00007797          	auipc	a5,0x7
    800021c2:	e5a7b783          	ld	a5,-422(a5) # 80009018 <initproc>
    800021c6:	0d050493          	addi	s1,a0,208
    800021ca:	15050913          	addi	s2,a0,336
    800021ce:	02a79363          	bne	a5,a0,800021f4 <exit+0x52>
    panic("init exiting");
    800021d2:	00006517          	auipc	a0,0x6
    800021d6:	07650513          	addi	a0,a0,118 # 80008248 <digits+0x208>
    800021da:	ffffe097          	auipc	ra,0xffffe
    800021de:	36e080e7          	jalr	878(ra) # 80000548 <panic>
      fileclose(f);
    800021e2:	00002097          	auipc	ra,0x2
    800021e6:	3d6080e7          	jalr	982(ra) # 800045b8 <fileclose>
      p->ofile[fd] = 0;
    800021ea:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021ee:	04a1                	addi	s1,s1,8
    800021f0:	01248563          	beq	s1,s2,800021fa <exit+0x58>
    if(p->ofile[fd]){
    800021f4:	6088                	ld	a0,0(s1)
    800021f6:	f575                	bnez	a0,800021e2 <exit+0x40>
    800021f8:	bfdd                	j	800021ee <exit+0x4c>
  begin_op();
    800021fa:	00002097          	auipc	ra,0x2
    800021fe:	eec080e7          	jalr	-276(ra) # 800040e6 <begin_op>
  iput(p->cwd);
    80002202:	1509b503          	ld	a0,336(s3)
    80002206:	00001097          	auipc	ra,0x1
    8000220a:	6da080e7          	jalr	1754(ra) # 800038e0 <iput>
  end_op();
    8000220e:	00002097          	auipc	ra,0x2
    80002212:	f58080e7          	jalr	-168(ra) # 80004166 <end_op>
  p->cwd = 0;
    80002216:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000221a:	00007497          	auipc	s1,0x7
    8000221e:	dfe48493          	addi	s1,s1,-514 # 80009018 <initproc>
    80002222:	6088                	ld	a0,0(s1)
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	a1a080e7          	jalr	-1510(ra) # 80000c3e <acquire>
  wakeup1(initproc);
    8000222c:	6088                	ld	a0,0(s1)
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	76a080e7          	jalr	1898(ra) # 80001998 <wakeup1>
  release(&initproc->lock);
    80002236:	6088                	ld	a0,0(s1)
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	aba080e7          	jalr	-1350(ra) # 80000cf2 <release>
  acquire(&p->lock);
    80002240:	854e                	mv	a0,s3
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	9fc080e7          	jalr	-1540(ra) # 80000c3e <acquire>
  struct proc *original_parent = p->parent;
    8000224a:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000224e:	854e                	mv	a0,s3
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	aa2080e7          	jalr	-1374(ra) # 80000cf2 <release>
  acquire(&original_parent->lock);
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	9e4080e7          	jalr	-1564(ra) # 80000c3e <acquire>
  acquire(&p->lock);
    80002262:	854e                	mv	a0,s3
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	9da080e7          	jalr	-1574(ra) # 80000c3e <acquire>
  reparent(p);
    8000226c:	854e                	mv	a0,s3
    8000226e:	00000097          	auipc	ra,0x0
    80002272:	d34080e7          	jalr	-716(ra) # 80001fa2 <reparent>
  wakeup1(original_parent);
    80002276:	8526                	mv	a0,s1
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	720080e7          	jalr	1824(ra) # 80001998 <wakeup1>
  p->xstate = status;
    80002280:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002284:	4791                	li	a5,4
    80002286:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000228a:	8526                	mv	a0,s1
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	a66080e7          	jalr	-1434(ra) # 80000cf2 <release>
  sched();
    80002294:	00000097          	auipc	ra,0x0
    80002298:	e38080e7          	jalr	-456(ra) # 800020cc <sched>
  panic("zombie exit");
    8000229c:	00006517          	auipc	a0,0x6
    800022a0:	fbc50513          	addi	a0,a0,-68 # 80008258 <digits+0x218>
    800022a4:	ffffe097          	auipc	ra,0xffffe
    800022a8:	2a4080e7          	jalr	676(ra) # 80000548 <panic>

00000000800022ac <yield>:
{
    800022ac:	1101                	addi	sp,sp,-32
    800022ae:	ec06                	sd	ra,24(sp)
    800022b0:	e822                	sd	s0,16(sp)
    800022b2:	e426                	sd	s1,8(sp)
    800022b4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022b6:	00000097          	auipc	ra,0x0
    800022ba:	822080e7          	jalr	-2014(ra) # 80001ad8 <myproc>
    800022be:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	97e080e7          	jalr	-1666(ra) # 80000c3e <acquire>
  p->state = RUNNABLE;
    800022c8:	4789                	li	a5,2
    800022ca:	cc9c                	sw	a5,24(s1)
  sched();
    800022cc:	00000097          	auipc	ra,0x0
    800022d0:	e00080e7          	jalr	-512(ra) # 800020cc <sched>
  release(&p->lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	a1c080e7          	jalr	-1508(ra) # 80000cf2 <release>
}
    800022de:	60e2                	ld	ra,24(sp)
    800022e0:	6442                	ld	s0,16(sp)
    800022e2:	64a2                	ld	s1,8(sp)
    800022e4:	6105                	addi	sp,sp,32
    800022e6:	8082                	ret

00000000800022e8 <sleep>:
{
    800022e8:	7179                	addi	sp,sp,-48
    800022ea:	f406                	sd	ra,40(sp)
    800022ec:	f022                	sd	s0,32(sp)
    800022ee:	ec26                	sd	s1,24(sp)
    800022f0:	e84a                	sd	s2,16(sp)
    800022f2:	e44e                	sd	s3,8(sp)
    800022f4:	1800                	addi	s0,sp,48
    800022f6:	89aa                	mv	s3,a0
    800022f8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	7de080e7          	jalr	2014(ra) # 80001ad8 <myproc>
    80002302:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002304:	05250663          	beq	a0,s2,80002350 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	936080e7          	jalr	-1738(ra) # 80000c3e <acquire>
    release(lk);
    80002310:	854a                	mv	a0,s2
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	9e0080e7          	jalr	-1568(ra) # 80000cf2 <release>
  p->chan = chan;
    8000231a:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000231e:	4785                	li	a5,1
    80002320:	cc9c                	sw	a5,24(s1)
  sched();
    80002322:	00000097          	auipc	ra,0x0
    80002326:	daa080e7          	jalr	-598(ra) # 800020cc <sched>
  p->chan = 0;
    8000232a:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000232e:	8526                	mv	a0,s1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	9c2080e7          	jalr	-1598(ra) # 80000cf2 <release>
    acquire(lk);
    80002338:	854a                	mv	a0,s2
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	904080e7          	jalr	-1788(ra) # 80000c3e <acquire>
}
    80002342:	70a2                	ld	ra,40(sp)
    80002344:	7402                	ld	s0,32(sp)
    80002346:	64e2                	ld	s1,24(sp)
    80002348:	6942                	ld	s2,16(sp)
    8000234a:	69a2                	ld	s3,8(sp)
    8000234c:	6145                	addi	sp,sp,48
    8000234e:	8082                	ret
  p->chan = chan;
    80002350:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002354:	4785                	li	a5,1
    80002356:	cd1c                	sw	a5,24(a0)
  sched();
    80002358:	00000097          	auipc	ra,0x0
    8000235c:	d74080e7          	jalr	-652(ra) # 800020cc <sched>
  p->chan = 0;
    80002360:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002364:	bff9                	j	80002342 <sleep+0x5a>

0000000080002366 <wait>:
{
    80002366:	715d                	addi	sp,sp,-80
    80002368:	e486                	sd	ra,72(sp)
    8000236a:	e0a2                	sd	s0,64(sp)
    8000236c:	fc26                	sd	s1,56(sp)
    8000236e:	f84a                	sd	s2,48(sp)
    80002370:	f44e                	sd	s3,40(sp)
    80002372:	f052                	sd	s4,32(sp)
    80002374:	ec56                	sd	s5,24(sp)
    80002376:	e85a                	sd	s6,16(sp)
    80002378:	e45e                	sd	s7,8(sp)
    8000237a:	e062                	sd	s8,0(sp)
    8000237c:	0880                	addi	s0,sp,80
    8000237e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	758080e7          	jalr	1880(ra) # 80001ad8 <myproc>
    80002388:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000238a:	8c2a                	mv	s8,a0
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	8b2080e7          	jalr	-1870(ra) # 80000c3e <acquire>
    havekids = 0;
    80002394:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002396:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002398:	00015997          	auipc	s3,0x15
    8000239c:	3d098993          	addi	s3,s3,976 # 80017768 <tickslock>
        havekids = 1;
    800023a0:	4a85                	li	s5,1
    havekids = 0;
    800023a2:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023a4:	00010497          	auipc	s1,0x10
    800023a8:	9c448493          	addi	s1,s1,-1596 # 80011d68 <proc>
    800023ac:	a08d                	j	8000240e <wait+0xa8>
          pid = np->pid;
    800023ae:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023b2:	000b0e63          	beqz	s6,800023ce <wait+0x68>
    800023b6:	4691                	li	a3,4
    800023b8:	03448613          	addi	a2,s1,52
    800023bc:	85da                	mv	a1,s6
    800023be:	05093503          	ld	a0,80(s2)
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	40a080e7          	jalr	1034(ra) # 800017cc <copyout>
    800023ca:	02054263          	bltz	a0,800023ee <wait+0x88>
          freeproc(np);
    800023ce:	8526                	mv	a0,s1
    800023d0:	00000097          	auipc	ra,0x0
    800023d4:	8ba080e7          	jalr	-1862(ra) # 80001c8a <freeproc>
          release(&np->lock);
    800023d8:	8526                	mv	a0,s1
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	918080e7          	jalr	-1768(ra) # 80000cf2 <release>
          release(&p->lock);
    800023e2:	854a                	mv	a0,s2
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	90e080e7          	jalr	-1778(ra) # 80000cf2 <release>
          return pid;
    800023ec:	a8a9                	j	80002446 <wait+0xe0>
            release(&np->lock);
    800023ee:	8526                	mv	a0,s1
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	902080e7          	jalr	-1790(ra) # 80000cf2 <release>
            release(&p->lock);
    800023f8:	854a                	mv	a0,s2
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	8f8080e7          	jalr	-1800(ra) # 80000cf2 <release>
            return -1;
    80002402:	59fd                	li	s3,-1
    80002404:	a089                	j	80002446 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002406:	16848493          	addi	s1,s1,360
    8000240a:	03348463          	beq	s1,s3,80002432 <wait+0xcc>
      if(np->parent == p){
    8000240e:	709c                	ld	a5,32(s1)
    80002410:	ff279be3          	bne	a5,s2,80002406 <wait+0xa0>
        acquire(&np->lock);
    80002414:	8526                	mv	a0,s1
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	828080e7          	jalr	-2008(ra) # 80000c3e <acquire>
        if(np->state == ZOMBIE){
    8000241e:	4c9c                	lw	a5,24(s1)
    80002420:	f94787e3          	beq	a5,s4,800023ae <wait+0x48>
        release(&np->lock);
    80002424:	8526                	mv	a0,s1
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	8cc080e7          	jalr	-1844(ra) # 80000cf2 <release>
        havekids = 1;
    8000242e:	8756                	mv	a4,s5
    80002430:	bfd9                	j	80002406 <wait+0xa0>
    if(!havekids || p->killed){
    80002432:	c701                	beqz	a4,8000243a <wait+0xd4>
    80002434:	03092783          	lw	a5,48(s2)
    80002438:	c785                	beqz	a5,80002460 <wait+0xfa>
      release(&p->lock);
    8000243a:	854a                	mv	a0,s2
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	8b6080e7          	jalr	-1866(ra) # 80000cf2 <release>
      return -1;
    80002444:	59fd                	li	s3,-1
}
    80002446:	854e                	mv	a0,s3
    80002448:	60a6                	ld	ra,72(sp)
    8000244a:	6406                	ld	s0,64(sp)
    8000244c:	74e2                	ld	s1,56(sp)
    8000244e:	7942                	ld	s2,48(sp)
    80002450:	79a2                	ld	s3,40(sp)
    80002452:	7a02                	ld	s4,32(sp)
    80002454:	6ae2                	ld	s5,24(sp)
    80002456:	6b42                	ld	s6,16(sp)
    80002458:	6ba2                	ld	s7,8(sp)
    8000245a:	6c02                	ld	s8,0(sp)
    8000245c:	6161                	addi	sp,sp,80
    8000245e:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002460:	85e2                	mv	a1,s8
    80002462:	854a                	mv	a0,s2
    80002464:	00000097          	auipc	ra,0x0
    80002468:	e84080e7          	jalr	-380(ra) # 800022e8 <sleep>
    havekids = 0;
    8000246c:	bf1d                	j	800023a2 <wait+0x3c>

000000008000246e <wakeup>:
{
    8000246e:	7139                	addi	sp,sp,-64
    80002470:	fc06                	sd	ra,56(sp)
    80002472:	f822                	sd	s0,48(sp)
    80002474:	f426                	sd	s1,40(sp)
    80002476:	f04a                	sd	s2,32(sp)
    80002478:	ec4e                	sd	s3,24(sp)
    8000247a:	e852                	sd	s4,16(sp)
    8000247c:	e456                	sd	s5,8(sp)
    8000247e:	0080                	addi	s0,sp,64
    80002480:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002482:	00010497          	auipc	s1,0x10
    80002486:	8e648493          	addi	s1,s1,-1818 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000248a:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000248c:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000248e:	00015917          	auipc	s2,0x15
    80002492:	2da90913          	addi	s2,s2,730 # 80017768 <tickslock>
    80002496:	a821                	j	800024ae <wakeup+0x40>
      p->state = RUNNABLE;
    80002498:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    8000249c:	8526                	mv	a0,s1
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	854080e7          	jalr	-1964(ra) # 80000cf2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024a6:	16848493          	addi	s1,s1,360
    800024aa:	01248e63          	beq	s1,s2,800024c6 <wakeup+0x58>
    acquire(&p->lock);
    800024ae:	8526                	mv	a0,s1
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	78e080e7          	jalr	1934(ra) # 80000c3e <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800024b8:	4c9c                	lw	a5,24(s1)
    800024ba:	ff3791e3          	bne	a5,s3,8000249c <wakeup+0x2e>
    800024be:	749c                	ld	a5,40(s1)
    800024c0:	fd479ee3          	bne	a5,s4,8000249c <wakeup+0x2e>
    800024c4:	bfd1                	j	80002498 <wakeup+0x2a>
}
    800024c6:	70e2                	ld	ra,56(sp)
    800024c8:	7442                	ld	s0,48(sp)
    800024ca:	74a2                	ld	s1,40(sp)
    800024cc:	7902                	ld	s2,32(sp)
    800024ce:	69e2                	ld	s3,24(sp)
    800024d0:	6a42                	ld	s4,16(sp)
    800024d2:	6aa2                	ld	s5,8(sp)
    800024d4:	6121                	addi	sp,sp,64
    800024d6:	8082                	ret

00000000800024d8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024d8:	7179                	addi	sp,sp,-48
    800024da:	f406                	sd	ra,40(sp)
    800024dc:	f022                	sd	s0,32(sp)
    800024de:	ec26                	sd	s1,24(sp)
    800024e0:	e84a                	sd	s2,16(sp)
    800024e2:	e44e                	sd	s3,8(sp)
    800024e4:	1800                	addi	s0,sp,48
    800024e6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024e8:	00010497          	auipc	s1,0x10
    800024ec:	88048493          	addi	s1,s1,-1920 # 80011d68 <proc>
    800024f0:	00015997          	auipc	s3,0x15
    800024f4:	27898993          	addi	s3,s3,632 # 80017768 <tickslock>
    acquire(&p->lock);
    800024f8:	8526                	mv	a0,s1
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	744080e7          	jalr	1860(ra) # 80000c3e <acquire>
    if(p->pid == pid){
    80002502:	5c9c                	lw	a5,56(s1)
    80002504:	01278d63          	beq	a5,s2,8000251e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002508:	8526                	mv	a0,s1
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	7e8080e7          	jalr	2024(ra) # 80000cf2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002512:	16848493          	addi	s1,s1,360
    80002516:	ff3491e3          	bne	s1,s3,800024f8 <kill+0x20>
  }
  return -1;
    8000251a:	557d                	li	a0,-1
    8000251c:	a829                	j	80002536 <kill+0x5e>
      p->killed = 1;
    8000251e:	4785                	li	a5,1
    80002520:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002522:	4c98                	lw	a4,24(s1)
    80002524:	4785                	li	a5,1
    80002526:	00f70f63          	beq	a4,a5,80002544 <kill+0x6c>
      release(&p->lock);
    8000252a:	8526                	mv	a0,s1
    8000252c:	ffffe097          	auipc	ra,0xffffe
    80002530:	7c6080e7          	jalr	1990(ra) # 80000cf2 <release>
      return 0;
    80002534:	4501                	li	a0,0
}
    80002536:	70a2                	ld	ra,40(sp)
    80002538:	7402                	ld	s0,32(sp)
    8000253a:	64e2                	ld	s1,24(sp)
    8000253c:	6942                	ld	s2,16(sp)
    8000253e:	69a2                	ld	s3,8(sp)
    80002540:	6145                	addi	sp,sp,48
    80002542:	8082                	ret
        p->state = RUNNABLE;
    80002544:	4789                	li	a5,2
    80002546:	cc9c                	sw	a5,24(s1)
    80002548:	b7cd                	j	8000252a <kill+0x52>

000000008000254a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000254a:	7179                	addi	sp,sp,-48
    8000254c:	f406                	sd	ra,40(sp)
    8000254e:	f022                	sd	s0,32(sp)
    80002550:	ec26                	sd	s1,24(sp)
    80002552:	e84a                	sd	s2,16(sp)
    80002554:	e44e                	sd	s3,8(sp)
    80002556:	e052                	sd	s4,0(sp)
    80002558:	1800                	addi	s0,sp,48
    8000255a:	84aa                	mv	s1,a0
    8000255c:	892e                	mv	s2,a1
    8000255e:	89b2                	mv	s3,a2
    80002560:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	576080e7          	jalr	1398(ra) # 80001ad8 <myproc>
  if(user_dst){
    8000256a:	c08d                	beqz	s1,8000258c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000256c:	86d2                	mv	a3,s4
    8000256e:	864e                	mv	a2,s3
    80002570:	85ca                	mv	a1,s2
    80002572:	6928                	ld	a0,80(a0)
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	258080e7          	jalr	600(ra) # 800017cc <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000257c:	70a2                	ld	ra,40(sp)
    8000257e:	7402                	ld	s0,32(sp)
    80002580:	64e2                	ld	s1,24(sp)
    80002582:	6942                	ld	s2,16(sp)
    80002584:	69a2                	ld	s3,8(sp)
    80002586:	6a02                	ld	s4,0(sp)
    80002588:	6145                	addi	sp,sp,48
    8000258a:	8082                	ret
    memmove((char *)dst, src, len);
    8000258c:	000a061b          	sext.w	a2,s4
    80002590:	85ce                	mv	a1,s3
    80002592:	854a                	mv	a0,s2
    80002594:	fffff097          	auipc	ra,0xfffff
    80002598:	806080e7          	jalr	-2042(ra) # 80000d9a <memmove>
    return 0;
    8000259c:	8526                	mv	a0,s1
    8000259e:	bff9                	j	8000257c <either_copyout+0x32>

00000000800025a0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025a0:	7179                	addi	sp,sp,-48
    800025a2:	f406                	sd	ra,40(sp)
    800025a4:	f022                	sd	s0,32(sp)
    800025a6:	ec26                	sd	s1,24(sp)
    800025a8:	e84a                	sd	s2,16(sp)
    800025aa:	e44e                	sd	s3,8(sp)
    800025ac:	e052                	sd	s4,0(sp)
    800025ae:	1800                	addi	s0,sp,48
    800025b0:	892a                	mv	s2,a0
    800025b2:	84ae                	mv	s1,a1
    800025b4:	89b2                	mv	s3,a2
    800025b6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025b8:	fffff097          	auipc	ra,0xfffff
    800025bc:	520080e7          	jalr	1312(ra) # 80001ad8 <myproc>
  if(user_src){
    800025c0:	c08d                	beqz	s1,800025e2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025c2:	86d2                	mv	a3,s4
    800025c4:	864e                	mv	a2,s3
    800025c6:	85ca                	mv	a1,s2
    800025c8:	6928                	ld	a0,80(a0)
    800025ca:	fffff097          	auipc	ra,0xfffff
    800025ce:	28e080e7          	jalr	654(ra) # 80001858 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025d2:	70a2                	ld	ra,40(sp)
    800025d4:	7402                	ld	s0,32(sp)
    800025d6:	64e2                	ld	s1,24(sp)
    800025d8:	6942                	ld	s2,16(sp)
    800025da:	69a2                	ld	s3,8(sp)
    800025dc:	6a02                	ld	s4,0(sp)
    800025de:	6145                	addi	sp,sp,48
    800025e0:	8082                	ret
    memmove(dst, (char*)src, len);
    800025e2:	000a061b          	sext.w	a2,s4
    800025e6:	85ce                	mv	a1,s3
    800025e8:	854a                	mv	a0,s2
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	7b0080e7          	jalr	1968(ra) # 80000d9a <memmove>
    return 0;
    800025f2:	8526                	mv	a0,s1
    800025f4:	bff9                	j	800025d2 <either_copyin+0x32>

00000000800025f6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025f6:	715d                	addi	sp,sp,-80
    800025f8:	e486                	sd	ra,72(sp)
    800025fa:	e0a2                	sd	s0,64(sp)
    800025fc:	fc26                	sd	s1,56(sp)
    800025fe:	f84a                	sd	s2,48(sp)
    80002600:	f44e                	sd	s3,40(sp)
    80002602:	f052                	sd	s4,32(sp)
    80002604:	ec56                	sd	s5,24(sp)
    80002606:	e85a                	sd	s6,16(sp)
    80002608:	e45e                	sd	s7,8(sp)
    8000260a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000260c:	00006517          	auipc	a0,0x6
    80002610:	abc50513          	addi	a0,a0,-1348 # 800080c8 <digits+0x88>
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	f7e080e7          	jalr	-130(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000261c:	00010497          	auipc	s1,0x10
    80002620:	8a448493          	addi	s1,s1,-1884 # 80011ec0 <proc+0x158>
    80002624:	00015917          	auipc	s2,0x15
    80002628:	29c90913          	addi	s2,s2,668 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000262c:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000262e:	00006997          	auipc	s3,0x6
    80002632:	c3a98993          	addi	s3,s3,-966 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002636:	00006a97          	auipc	s5,0x6
    8000263a:	c3aa8a93          	addi	s5,s5,-966 # 80008270 <digits+0x230>
    printf("\n");
    8000263e:	00006a17          	auipc	s4,0x6
    80002642:	a8aa0a13          	addi	s4,s4,-1398 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002646:	00006b97          	auipc	s7,0x6
    8000264a:	c62b8b93          	addi	s7,s7,-926 # 800082a8 <states.1709>
    8000264e:	a00d                	j	80002670 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002650:	ee06a583          	lw	a1,-288(a3)
    80002654:	8556                	mv	a0,s5
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	f3c080e7          	jalr	-196(ra) # 80000592 <printf>
    printf("\n");
    8000265e:	8552                	mv	a0,s4
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	f32080e7          	jalr	-206(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002668:	16848493          	addi	s1,s1,360
    8000266c:	03248163          	beq	s1,s2,8000268e <procdump+0x98>
    if(p->state == UNUSED)
    80002670:	86a6                	mv	a3,s1
    80002672:	ec04a783          	lw	a5,-320(s1)
    80002676:	dbed                	beqz	a5,80002668 <procdump+0x72>
      state = "???";
    80002678:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000267a:	fcfb6be3          	bltu	s6,a5,80002650 <procdump+0x5a>
    8000267e:	1782                	slli	a5,a5,0x20
    80002680:	9381                	srli	a5,a5,0x20
    80002682:	078e                	slli	a5,a5,0x3
    80002684:	97de                	add	a5,a5,s7
    80002686:	6390                	ld	a2,0(a5)
    80002688:	f661                	bnez	a2,80002650 <procdump+0x5a>
      state = "???";
    8000268a:	864e                	mv	a2,s3
    8000268c:	b7d1                	j	80002650 <procdump+0x5a>
  }
}
    8000268e:	60a6                	ld	ra,72(sp)
    80002690:	6406                	ld	s0,64(sp)
    80002692:	74e2                	ld	s1,56(sp)
    80002694:	7942                	ld	s2,48(sp)
    80002696:	79a2                	ld	s3,40(sp)
    80002698:	7a02                	ld	s4,32(sp)
    8000269a:	6ae2                	ld	s5,24(sp)
    8000269c:	6b42                	ld	s6,16(sp)
    8000269e:	6ba2                	ld	s7,8(sp)
    800026a0:	6161                	addi	sp,sp,80
    800026a2:	8082                	ret

00000000800026a4 <swtch>:
    800026a4:	00153023          	sd	ra,0(a0)
    800026a8:	00253423          	sd	sp,8(a0)
    800026ac:	e900                	sd	s0,16(a0)
    800026ae:	ed04                	sd	s1,24(a0)
    800026b0:	03253023          	sd	s2,32(a0)
    800026b4:	03353423          	sd	s3,40(a0)
    800026b8:	03453823          	sd	s4,48(a0)
    800026bc:	03553c23          	sd	s5,56(a0)
    800026c0:	05653023          	sd	s6,64(a0)
    800026c4:	05753423          	sd	s7,72(a0)
    800026c8:	05853823          	sd	s8,80(a0)
    800026cc:	05953c23          	sd	s9,88(a0)
    800026d0:	07a53023          	sd	s10,96(a0)
    800026d4:	07b53423          	sd	s11,104(a0)
    800026d8:	0005b083          	ld	ra,0(a1)
    800026dc:	0085b103          	ld	sp,8(a1)
    800026e0:	6980                	ld	s0,16(a1)
    800026e2:	6d84                	ld	s1,24(a1)
    800026e4:	0205b903          	ld	s2,32(a1)
    800026e8:	0285b983          	ld	s3,40(a1)
    800026ec:	0305ba03          	ld	s4,48(a1)
    800026f0:	0385ba83          	ld	s5,56(a1)
    800026f4:	0405bb03          	ld	s6,64(a1)
    800026f8:	0485bb83          	ld	s7,72(a1)
    800026fc:	0505bc03          	ld	s8,80(a1)
    80002700:	0585bc83          	ld	s9,88(a1)
    80002704:	0605bd03          	ld	s10,96(a1)
    80002708:	0685bd83          	ld	s11,104(a1)
    8000270c:	8082                	ret

000000008000270e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000270e:	1141                	addi	sp,sp,-16
    80002710:	e406                	sd	ra,8(sp)
    80002712:	e022                	sd	s0,0(sp)
    80002714:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002716:	00006597          	auipc	a1,0x6
    8000271a:	bba58593          	addi	a1,a1,-1094 # 800082d0 <states.1709+0x28>
    8000271e:	00015517          	auipc	a0,0x15
    80002722:	04a50513          	addi	a0,a0,74 # 80017768 <tickslock>
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	488080e7          	jalr	1160(ra) # 80000bae <initlock>
}
    8000272e:	60a2                	ld	ra,8(sp)
    80002730:	6402                	ld	s0,0(sp)
    80002732:	0141                	addi	sp,sp,16
    80002734:	8082                	ret

0000000080002736 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002736:	1141                	addi	sp,sp,-16
    80002738:	e422                	sd	s0,8(sp)
    8000273a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000273c:	00003797          	auipc	a5,0x3
    80002740:	4e478793          	addi	a5,a5,1252 # 80005c20 <kernelvec>
    80002744:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002748:	6422                	ld	s0,8(sp)
    8000274a:	0141                	addi	sp,sp,16
    8000274c:	8082                	ret

000000008000274e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000274e:	1141                	addi	sp,sp,-16
    80002750:	e406                	sd	ra,8(sp)
    80002752:	e022                	sd	s0,0(sp)
    80002754:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002756:	fffff097          	auipc	ra,0xfffff
    8000275a:	382080e7          	jalr	898(ra) # 80001ad8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000275e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002762:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002764:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002768:	00005617          	auipc	a2,0x5
    8000276c:	89860613          	addi	a2,a2,-1896 # 80007000 <_trampoline>
    80002770:	00005697          	auipc	a3,0x5
    80002774:	89068693          	addi	a3,a3,-1904 # 80007000 <_trampoline>
    80002778:	8e91                	sub	a3,a3,a2
    8000277a:	040007b7          	lui	a5,0x4000
    8000277e:	17fd                	addi	a5,a5,-1
    80002780:	07b2                	slli	a5,a5,0xc
    80002782:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002784:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002788:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000278a:	180026f3          	csrr	a3,satp
    8000278e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002790:	6d38                	ld	a4,88(a0)
    80002792:	6134                	ld	a3,64(a0)
    80002794:	6585                	lui	a1,0x1
    80002796:	96ae                	add	a3,a3,a1
    80002798:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000279a:	6d38                	ld	a4,88(a0)
    8000279c:	00000697          	auipc	a3,0x0
    800027a0:	13868693          	addi	a3,a3,312 # 800028d4 <usertrap>
    800027a4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027a6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027a8:	8692                	mv	a3,tp
    800027aa:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ac:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027b0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027b4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027b8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027bc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027be:	6f18                	ld	a4,24(a4)
    800027c0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027c4:	692c                	ld	a1,80(a0)
    800027c6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027c8:	00005717          	auipc	a4,0x5
    800027cc:	8c870713          	addi	a4,a4,-1848 # 80007090 <userret>
    800027d0:	8f11                	sub	a4,a4,a2
    800027d2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027d4:	577d                	li	a4,-1
    800027d6:	177e                	slli	a4,a4,0x3f
    800027d8:	8dd9                	or	a1,a1,a4
    800027da:	02000537          	lui	a0,0x2000
    800027de:	157d                	addi	a0,a0,-1
    800027e0:	0536                	slli	a0,a0,0xd
    800027e2:	9782                	jalr	a5
}
    800027e4:	60a2                	ld	ra,8(sp)
    800027e6:	6402                	ld	s0,0(sp)
    800027e8:	0141                	addi	sp,sp,16
    800027ea:	8082                	ret

00000000800027ec <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027ec:	1101                	addi	sp,sp,-32
    800027ee:	ec06                	sd	ra,24(sp)
    800027f0:	e822                	sd	s0,16(sp)
    800027f2:	e426                	sd	s1,8(sp)
    800027f4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027f6:	00015497          	auipc	s1,0x15
    800027fa:	f7248493          	addi	s1,s1,-142 # 80017768 <tickslock>
    800027fe:	8526                	mv	a0,s1
    80002800:	ffffe097          	auipc	ra,0xffffe
    80002804:	43e080e7          	jalr	1086(ra) # 80000c3e <acquire>
  ticks++;
    80002808:	00007517          	auipc	a0,0x7
    8000280c:	81850513          	addi	a0,a0,-2024 # 80009020 <ticks>
    80002810:	411c                	lw	a5,0(a0)
    80002812:	2785                	addiw	a5,a5,1
    80002814:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002816:	00000097          	auipc	ra,0x0
    8000281a:	c58080e7          	jalr	-936(ra) # 8000246e <wakeup>
  release(&tickslock);
    8000281e:	8526                	mv	a0,s1
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	4d2080e7          	jalr	1234(ra) # 80000cf2 <release>
}
    80002828:	60e2                	ld	ra,24(sp)
    8000282a:	6442                	ld	s0,16(sp)
    8000282c:	64a2                	ld	s1,8(sp)
    8000282e:	6105                	addi	sp,sp,32
    80002830:	8082                	ret

0000000080002832 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002832:	1101                	addi	sp,sp,-32
    80002834:	ec06                	sd	ra,24(sp)
    80002836:	e822                	sd	s0,16(sp)
    80002838:	e426                	sd	s1,8(sp)
    8000283a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000283c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002840:	00074d63          	bltz	a4,8000285a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002844:	57fd                	li	a5,-1
    80002846:	17fe                	slli	a5,a5,0x3f
    80002848:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000284a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000284c:	06f70363          	beq	a4,a5,800028b2 <devintr+0x80>
  }
}
    80002850:	60e2                	ld	ra,24(sp)
    80002852:	6442                	ld	s0,16(sp)
    80002854:	64a2                	ld	s1,8(sp)
    80002856:	6105                	addi	sp,sp,32
    80002858:	8082                	ret
     (scause & 0xff) == 9){
    8000285a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000285e:	46a5                	li	a3,9
    80002860:	fed792e3          	bne	a5,a3,80002844 <devintr+0x12>
    int irq = plic_claim();
    80002864:	00003097          	auipc	ra,0x3
    80002868:	4c4080e7          	jalr	1220(ra) # 80005d28 <plic_claim>
    8000286c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000286e:	47a9                	li	a5,10
    80002870:	02f50763          	beq	a0,a5,8000289e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002874:	4785                	li	a5,1
    80002876:	02f50963          	beq	a0,a5,800028a8 <devintr+0x76>
    return 1;
    8000287a:	4505                	li	a0,1
    } else if(irq){
    8000287c:	d8f1                	beqz	s1,80002850 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000287e:	85a6                	mv	a1,s1
    80002880:	00006517          	auipc	a0,0x6
    80002884:	a5850513          	addi	a0,a0,-1448 # 800082d8 <states.1709+0x30>
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	d0a080e7          	jalr	-758(ra) # 80000592 <printf>
      plic_complete(irq);
    80002890:	8526                	mv	a0,s1
    80002892:	00003097          	auipc	ra,0x3
    80002896:	4ba080e7          	jalr	1210(ra) # 80005d4c <plic_complete>
    return 1;
    8000289a:	4505                	li	a0,1
    8000289c:	bf55                	j	80002850 <devintr+0x1e>
      uartintr();
    8000289e:	ffffe097          	auipc	ra,0xffffe
    800028a2:	136080e7          	jalr	310(ra) # 800009d4 <uartintr>
    800028a6:	b7ed                	j	80002890 <devintr+0x5e>
      virtio_disk_intr();
    800028a8:	00004097          	auipc	ra,0x4
    800028ac:	93e080e7          	jalr	-1730(ra) # 800061e6 <virtio_disk_intr>
    800028b0:	b7c5                	j	80002890 <devintr+0x5e>
    if(cpuid() == 0){
    800028b2:	fffff097          	auipc	ra,0xfffff
    800028b6:	1fa080e7          	jalr	506(ra) # 80001aac <cpuid>
    800028ba:	c901                	beqz	a0,800028ca <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028bc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028c0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028c2:	14479073          	csrw	sip,a5
    return 2;
    800028c6:	4509                	li	a0,2
    800028c8:	b761                	j	80002850 <devintr+0x1e>
      clockintr();
    800028ca:	00000097          	auipc	ra,0x0
    800028ce:	f22080e7          	jalr	-222(ra) # 800027ec <clockintr>
    800028d2:	b7ed                	j	800028bc <devintr+0x8a>

00000000800028d4 <usertrap>:
{
    800028d4:	1101                	addi	sp,sp,-32
    800028d6:	ec06                	sd	ra,24(sp)
    800028d8:	e822                	sd	s0,16(sp)
    800028da:	e426                	sd	s1,8(sp)
    800028dc:	e04a                	sd	s2,0(sp)
    800028de:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028e4:	1007f793          	andi	a5,a5,256
    800028e8:	e7d9                	bnez	a5,80002976 <usertrap+0xa2>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ea:	00003797          	auipc	a5,0x3
    800028ee:	33678793          	addi	a5,a5,822 # 80005c20 <kernelvec>
    800028f2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028f6:	fffff097          	auipc	ra,0xfffff
    800028fa:	1e2080e7          	jalr	482(ra) # 80001ad8 <myproc>
    800028fe:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002900:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002902:	14102773          	csrr	a4,sepc
    80002906:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002908:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000290c:	47a1                	li	a5,8
    8000290e:	06f70c63          	beq	a4,a5,80002986 <usertrap+0xb2>
    80002912:	14202773          	csrr	a4,scause
  } else if(r_scause() == 15) { // COW 
    80002916:	47bd                	li	a5,15
    80002918:	0af70963          	beq	a4,a5,800029ca <usertrap+0xf6>
  } else if((which_dev = devintr()) != 0){
    8000291c:	00000097          	auipc	ra,0x0
    80002920:	f16080e7          	jalr	-234(ra) # 80002832 <devintr>
    80002924:	892a                	mv	s2,a0
    80002926:	e95d                	bnez	a0,800029dc <usertrap+0x108>
    80002928:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000292c:	5c90                	lw	a2,56(s1)
    8000292e:	00006517          	auipc	a0,0x6
    80002932:	9ea50513          	addi	a0,a0,-1558 # 80008318 <states.1709+0x70>
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	c5c080e7          	jalr	-932(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000293e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002942:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002946:	00006517          	auipc	a0,0x6
    8000294a:	a0250513          	addi	a0,a0,-1534 # 80008348 <states.1709+0xa0>
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	c44080e7          	jalr	-956(ra) # 80000592 <printf>
    p->killed = 1;
    80002956:	4785                	li	a5,1
    80002958:	d89c                	sw	a5,48(s1)
    8000295a:	4901                	li	s2,0
    exit(-1);
    8000295c:	557d                	li	a0,-1
    8000295e:	00000097          	auipc	ra,0x0
    80002962:	844080e7          	jalr	-1980(ra) # 800021a2 <exit>
  if(which_dev == 2)
    80002966:	4789                	li	a5,2
    80002968:	04f91163          	bne	s2,a5,800029aa <usertrap+0xd6>
    yield();
    8000296c:	00000097          	auipc	ra,0x0
    80002970:	940080e7          	jalr	-1728(ra) # 800022ac <yield>
    80002974:	a81d                	j	800029aa <usertrap+0xd6>
    panic("usertrap: not from user mode");
    80002976:	00006517          	auipc	a0,0x6
    8000297a:	98250513          	addi	a0,a0,-1662 # 800082f8 <states.1709+0x50>
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	bca080e7          	jalr	-1078(ra) # 80000548 <panic>
    if(p->killed)
    80002986:	591c                	lw	a5,48(a0)
    80002988:	eb9d                	bnez	a5,800029be <usertrap+0xea>
    p->trapframe->epc += 4;
    8000298a:	6cb8                	ld	a4,88(s1)
    8000298c:	6f1c                	ld	a5,24(a4)
    8000298e:	0791                	addi	a5,a5,4
    80002990:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002992:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002996:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000299a:	10079073          	csrw	sstatus,a5
    syscall();
    8000299e:	00000097          	auipc	ra,0x0
    800029a2:	28a080e7          	jalr	650(ra) # 80002c28 <syscall>
  if(p->killed)
    800029a6:	589c                	lw	a5,48(s1)
    800029a8:	ef8d                	bnez	a5,800029e2 <usertrap+0x10e>
  usertrapret();
    800029aa:	00000097          	auipc	ra,0x0
    800029ae:	da4080e7          	jalr	-604(ra) # 8000274e <usertrapret>
}
    800029b2:	60e2                	ld	ra,24(sp)
    800029b4:	6442                	ld	s0,16(sp)
    800029b6:	64a2                	ld	s1,8(sp)
    800029b8:	6902                	ld	s2,0(sp)
    800029ba:	6105                	addi	sp,sp,32
    800029bc:	8082                	ret
      exit(-1);
    800029be:	557d                	li	a0,-1
    800029c0:	fffff097          	auipc	ra,0xfffff
    800029c4:	7e2080e7          	jalr	2018(ra) # 800021a2 <exit>
    800029c8:	b7c9                	j	8000298a <usertrap+0xb6>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029ca:	143025f3          	csrr	a1,stval
    if (walkcowaddr(p->pagetable, r_stval()) == 0) {
    800029ce:	6928                	ld	a0,80(a0)
    800029d0:	fffff097          	auipc	ra,0xfffff
    800029d4:	9f8080e7          	jalr	-1544(ra) # 800013c8 <walkcowaddr>
    800029d8:	f579                	bnez	a0,800029a6 <usertrap+0xd2>
    800029da:	b7b9                	j	80002928 <usertrap+0x54>
  if(p->killed)
    800029dc:	589c                	lw	a5,48(s1)
    800029de:	d7c1                	beqz	a5,80002966 <usertrap+0x92>
    800029e0:	bfb5                	j	8000295c <usertrap+0x88>
    800029e2:	4901                	li	s2,0
    800029e4:	bfa5                	j	8000295c <usertrap+0x88>

00000000800029e6 <kerneltrap>:
{
    800029e6:	7179                	addi	sp,sp,-48
    800029e8:	f406                	sd	ra,40(sp)
    800029ea:	f022                	sd	s0,32(sp)
    800029ec:	ec26                	sd	s1,24(sp)
    800029ee:	e84a                	sd	s2,16(sp)
    800029f0:	e44e                	sd	s3,8(sp)
    800029f2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029fc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a00:	1004f793          	andi	a5,s1,256
    80002a04:	cb85                	beqz	a5,80002a34 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a06:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a0a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a0c:	ef85                	bnez	a5,80002a44 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a0e:	00000097          	auipc	ra,0x0
    80002a12:	e24080e7          	jalr	-476(ra) # 80002832 <devintr>
    80002a16:	cd1d                	beqz	a0,80002a54 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a18:	4789                	li	a5,2
    80002a1a:	06f50a63          	beq	a0,a5,80002a8e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a1e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a22:	10049073          	csrw	sstatus,s1
}
    80002a26:	70a2                	ld	ra,40(sp)
    80002a28:	7402                	ld	s0,32(sp)
    80002a2a:	64e2                	ld	s1,24(sp)
    80002a2c:	6942                	ld	s2,16(sp)
    80002a2e:	69a2                	ld	s3,8(sp)
    80002a30:	6145                	addi	sp,sp,48
    80002a32:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a34:	00006517          	auipc	a0,0x6
    80002a38:	93450513          	addi	a0,a0,-1740 # 80008368 <states.1709+0xc0>
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	b0c080e7          	jalr	-1268(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a44:	00006517          	auipc	a0,0x6
    80002a48:	94c50513          	addi	a0,a0,-1716 # 80008390 <states.1709+0xe8>
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	afc080e7          	jalr	-1284(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002a54:	85ce                	mv	a1,s3
    80002a56:	00006517          	auipc	a0,0x6
    80002a5a:	95a50513          	addi	a0,a0,-1702 # 800083b0 <states.1709+0x108>
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	b34080e7          	jalr	-1228(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a66:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a6a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a6e:	00006517          	auipc	a0,0x6
    80002a72:	95250513          	addi	a0,a0,-1710 # 800083c0 <states.1709+0x118>
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	b1c080e7          	jalr	-1252(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002a7e:	00006517          	auipc	a0,0x6
    80002a82:	95a50513          	addi	a0,a0,-1702 # 800083d8 <states.1709+0x130>
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	ac2080e7          	jalr	-1342(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a8e:	fffff097          	auipc	ra,0xfffff
    80002a92:	04a080e7          	jalr	74(ra) # 80001ad8 <myproc>
    80002a96:	d541                	beqz	a0,80002a1e <kerneltrap+0x38>
    80002a98:	fffff097          	auipc	ra,0xfffff
    80002a9c:	040080e7          	jalr	64(ra) # 80001ad8 <myproc>
    80002aa0:	4d18                	lw	a4,24(a0)
    80002aa2:	478d                	li	a5,3
    80002aa4:	f6f71de3          	bne	a4,a5,80002a1e <kerneltrap+0x38>
    yield();
    80002aa8:	00000097          	auipc	ra,0x0
    80002aac:	804080e7          	jalr	-2044(ra) # 800022ac <yield>
    80002ab0:	b7bd                	j	80002a1e <kerneltrap+0x38>

0000000080002ab2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ab2:	1101                	addi	sp,sp,-32
    80002ab4:	ec06                	sd	ra,24(sp)
    80002ab6:	e822                	sd	s0,16(sp)
    80002ab8:	e426                	sd	s1,8(sp)
    80002aba:	1000                	addi	s0,sp,32
    80002abc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002abe:	fffff097          	auipc	ra,0xfffff
    80002ac2:	01a080e7          	jalr	26(ra) # 80001ad8 <myproc>
  switch (n) {
    80002ac6:	4795                	li	a5,5
    80002ac8:	0497e163          	bltu	a5,s1,80002b0a <argraw+0x58>
    80002acc:	048a                	slli	s1,s1,0x2
    80002ace:	00006717          	auipc	a4,0x6
    80002ad2:	94270713          	addi	a4,a4,-1726 # 80008410 <states.1709+0x168>
    80002ad6:	94ba                	add	s1,s1,a4
    80002ad8:	409c                	lw	a5,0(s1)
    80002ada:	97ba                	add	a5,a5,a4
    80002adc:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ade:	6d3c                	ld	a5,88(a0)
    80002ae0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ae2:	60e2                	ld	ra,24(sp)
    80002ae4:	6442                	ld	s0,16(sp)
    80002ae6:	64a2                	ld	s1,8(sp)
    80002ae8:	6105                	addi	sp,sp,32
    80002aea:	8082                	ret
    return p->trapframe->a1;
    80002aec:	6d3c                	ld	a5,88(a0)
    80002aee:	7fa8                	ld	a0,120(a5)
    80002af0:	bfcd                	j	80002ae2 <argraw+0x30>
    return p->trapframe->a2;
    80002af2:	6d3c                	ld	a5,88(a0)
    80002af4:	63c8                	ld	a0,128(a5)
    80002af6:	b7f5                	j	80002ae2 <argraw+0x30>
    return p->trapframe->a3;
    80002af8:	6d3c                	ld	a5,88(a0)
    80002afa:	67c8                	ld	a0,136(a5)
    80002afc:	b7dd                	j	80002ae2 <argraw+0x30>
    return p->trapframe->a4;
    80002afe:	6d3c                	ld	a5,88(a0)
    80002b00:	6bc8                	ld	a0,144(a5)
    80002b02:	b7c5                	j	80002ae2 <argraw+0x30>
    return p->trapframe->a5;
    80002b04:	6d3c                	ld	a5,88(a0)
    80002b06:	6fc8                	ld	a0,152(a5)
    80002b08:	bfe9                	j	80002ae2 <argraw+0x30>
  panic("argraw");
    80002b0a:	00006517          	auipc	a0,0x6
    80002b0e:	8de50513          	addi	a0,a0,-1826 # 800083e8 <states.1709+0x140>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a36080e7          	jalr	-1482(ra) # 80000548 <panic>

0000000080002b1a <fetchaddr>:
{
    80002b1a:	1101                	addi	sp,sp,-32
    80002b1c:	ec06                	sd	ra,24(sp)
    80002b1e:	e822                	sd	s0,16(sp)
    80002b20:	e426                	sd	s1,8(sp)
    80002b22:	e04a                	sd	s2,0(sp)
    80002b24:	1000                	addi	s0,sp,32
    80002b26:	84aa                	mv	s1,a0
    80002b28:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	fae080e7          	jalr	-82(ra) # 80001ad8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b32:	653c                	ld	a5,72(a0)
    80002b34:	02f4f863          	bgeu	s1,a5,80002b64 <fetchaddr+0x4a>
    80002b38:	00848713          	addi	a4,s1,8
    80002b3c:	02e7e663          	bltu	a5,a4,80002b68 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b40:	46a1                	li	a3,8
    80002b42:	8626                	mv	a2,s1
    80002b44:	85ca                	mv	a1,s2
    80002b46:	6928                	ld	a0,80(a0)
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	d10080e7          	jalr	-752(ra) # 80001858 <copyin>
    80002b50:	00a03533          	snez	a0,a0
    80002b54:	40a00533          	neg	a0,a0
}
    80002b58:	60e2                	ld	ra,24(sp)
    80002b5a:	6442                	ld	s0,16(sp)
    80002b5c:	64a2                	ld	s1,8(sp)
    80002b5e:	6902                	ld	s2,0(sp)
    80002b60:	6105                	addi	sp,sp,32
    80002b62:	8082                	ret
    return -1;
    80002b64:	557d                	li	a0,-1
    80002b66:	bfcd                	j	80002b58 <fetchaddr+0x3e>
    80002b68:	557d                	li	a0,-1
    80002b6a:	b7fd                	j	80002b58 <fetchaddr+0x3e>

0000000080002b6c <fetchstr>:
{
    80002b6c:	7179                	addi	sp,sp,-48
    80002b6e:	f406                	sd	ra,40(sp)
    80002b70:	f022                	sd	s0,32(sp)
    80002b72:	ec26                	sd	s1,24(sp)
    80002b74:	e84a                	sd	s2,16(sp)
    80002b76:	e44e                	sd	s3,8(sp)
    80002b78:	1800                	addi	s0,sp,48
    80002b7a:	892a                	mv	s2,a0
    80002b7c:	84ae                	mv	s1,a1
    80002b7e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b80:	fffff097          	auipc	ra,0xfffff
    80002b84:	f58080e7          	jalr	-168(ra) # 80001ad8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b88:	86ce                	mv	a3,s3
    80002b8a:	864a                	mv	a2,s2
    80002b8c:	85a6                	mv	a1,s1
    80002b8e:	6928                	ld	a0,80(a0)
    80002b90:	fffff097          	auipc	ra,0xfffff
    80002b94:	d54080e7          	jalr	-684(ra) # 800018e4 <copyinstr>
  if(err < 0)
    80002b98:	00054763          	bltz	a0,80002ba6 <fetchstr+0x3a>
  return strlen(buf);
    80002b9c:	8526                	mv	a0,s1
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	324080e7          	jalr	804(ra) # 80000ec2 <strlen>
}
    80002ba6:	70a2                	ld	ra,40(sp)
    80002ba8:	7402                	ld	s0,32(sp)
    80002baa:	64e2                	ld	s1,24(sp)
    80002bac:	6942                	ld	s2,16(sp)
    80002bae:	69a2                	ld	s3,8(sp)
    80002bb0:	6145                	addi	sp,sp,48
    80002bb2:	8082                	ret

0000000080002bb4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bb4:	1101                	addi	sp,sp,-32
    80002bb6:	ec06                	sd	ra,24(sp)
    80002bb8:	e822                	sd	s0,16(sp)
    80002bba:	e426                	sd	s1,8(sp)
    80002bbc:	1000                	addi	s0,sp,32
    80002bbe:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bc0:	00000097          	auipc	ra,0x0
    80002bc4:	ef2080e7          	jalr	-270(ra) # 80002ab2 <argraw>
    80002bc8:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bca:	4501                	li	a0,0
    80002bcc:	60e2                	ld	ra,24(sp)
    80002bce:	6442                	ld	s0,16(sp)
    80002bd0:	64a2                	ld	s1,8(sp)
    80002bd2:	6105                	addi	sp,sp,32
    80002bd4:	8082                	ret

0000000080002bd6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bd6:	1101                	addi	sp,sp,-32
    80002bd8:	ec06                	sd	ra,24(sp)
    80002bda:	e822                	sd	s0,16(sp)
    80002bdc:	e426                	sd	s1,8(sp)
    80002bde:	1000                	addi	s0,sp,32
    80002be0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002be2:	00000097          	auipc	ra,0x0
    80002be6:	ed0080e7          	jalr	-304(ra) # 80002ab2 <argraw>
    80002bea:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bec:	4501                	li	a0,0
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6105                	addi	sp,sp,32
    80002bf6:	8082                	ret

0000000080002bf8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bf8:	1101                	addi	sp,sp,-32
    80002bfa:	ec06                	sd	ra,24(sp)
    80002bfc:	e822                	sd	s0,16(sp)
    80002bfe:	e426                	sd	s1,8(sp)
    80002c00:	e04a                	sd	s2,0(sp)
    80002c02:	1000                	addi	s0,sp,32
    80002c04:	84ae                	mv	s1,a1
    80002c06:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c08:	00000097          	auipc	ra,0x0
    80002c0c:	eaa080e7          	jalr	-342(ra) # 80002ab2 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c10:	864a                	mv	a2,s2
    80002c12:	85a6                	mv	a1,s1
    80002c14:	00000097          	auipc	ra,0x0
    80002c18:	f58080e7          	jalr	-168(ra) # 80002b6c <fetchstr>
}
    80002c1c:	60e2                	ld	ra,24(sp)
    80002c1e:	6442                	ld	s0,16(sp)
    80002c20:	64a2                	ld	s1,8(sp)
    80002c22:	6902                	ld	s2,0(sp)
    80002c24:	6105                	addi	sp,sp,32
    80002c26:	8082                	ret

0000000080002c28 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c28:	1101                	addi	sp,sp,-32
    80002c2a:	ec06                	sd	ra,24(sp)
    80002c2c:	e822                	sd	s0,16(sp)
    80002c2e:	e426                	sd	s1,8(sp)
    80002c30:	e04a                	sd	s2,0(sp)
    80002c32:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	ea4080e7          	jalr	-348(ra) # 80001ad8 <myproc>
    80002c3c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c3e:	05853903          	ld	s2,88(a0)
    80002c42:	0a893783          	ld	a5,168(s2)
    80002c46:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c4a:	37fd                	addiw	a5,a5,-1
    80002c4c:	4751                	li	a4,20
    80002c4e:	00f76f63          	bltu	a4,a5,80002c6c <syscall+0x44>
    80002c52:	00369713          	slli	a4,a3,0x3
    80002c56:	00005797          	auipc	a5,0x5
    80002c5a:	7d278793          	addi	a5,a5,2002 # 80008428 <syscalls>
    80002c5e:	97ba                	add	a5,a5,a4
    80002c60:	639c                	ld	a5,0(a5)
    80002c62:	c789                	beqz	a5,80002c6c <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c64:	9782                	jalr	a5
    80002c66:	06a93823          	sd	a0,112(s2)
    80002c6a:	a839                	j	80002c88 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c6c:	15848613          	addi	a2,s1,344
    80002c70:	5c8c                	lw	a1,56(s1)
    80002c72:	00005517          	auipc	a0,0x5
    80002c76:	77e50513          	addi	a0,a0,1918 # 800083f0 <states.1709+0x148>
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	918080e7          	jalr	-1768(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c82:	6cbc                	ld	a5,88(s1)
    80002c84:	577d                	li	a4,-1
    80002c86:	fbb8                	sd	a4,112(a5)
  }
}
    80002c88:	60e2                	ld	ra,24(sp)
    80002c8a:	6442                	ld	s0,16(sp)
    80002c8c:	64a2                	ld	s1,8(sp)
    80002c8e:	6902                	ld	s2,0(sp)
    80002c90:	6105                	addi	sp,sp,32
    80002c92:	8082                	ret

0000000080002c94 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c94:	1101                	addi	sp,sp,-32
    80002c96:	ec06                	sd	ra,24(sp)
    80002c98:	e822                	sd	s0,16(sp)
    80002c9a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c9c:	fec40593          	addi	a1,s0,-20
    80002ca0:	4501                	li	a0,0
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	f12080e7          	jalr	-238(ra) # 80002bb4 <argint>
    return -1;
    80002caa:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cac:	00054963          	bltz	a0,80002cbe <sys_exit+0x2a>
  exit(n);
    80002cb0:	fec42503          	lw	a0,-20(s0)
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	4ee080e7          	jalr	1262(ra) # 800021a2 <exit>
  return 0;  // not reached
    80002cbc:	4781                	li	a5,0
}
    80002cbe:	853e                	mv	a0,a5
    80002cc0:	60e2                	ld	ra,24(sp)
    80002cc2:	6442                	ld	s0,16(sp)
    80002cc4:	6105                	addi	sp,sp,32
    80002cc6:	8082                	ret

0000000080002cc8 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cc8:	1141                	addi	sp,sp,-16
    80002cca:	e406                	sd	ra,8(sp)
    80002ccc:	e022                	sd	s0,0(sp)
    80002cce:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	e08080e7          	jalr	-504(ra) # 80001ad8 <myproc>
}
    80002cd8:	5d08                	lw	a0,56(a0)
    80002cda:	60a2                	ld	ra,8(sp)
    80002cdc:	6402                	ld	s0,0(sp)
    80002cde:	0141                	addi	sp,sp,16
    80002ce0:	8082                	ret

0000000080002ce2 <sys_fork>:

uint64
sys_fork(void)
{
    80002ce2:	1141                	addi	sp,sp,-16
    80002ce4:	e406                	sd	ra,8(sp)
    80002ce6:	e022                	sd	s0,0(sp)
    80002ce8:	0800                	addi	s0,sp,16
  return fork();
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	1ae080e7          	jalr	430(ra) # 80001e98 <fork>
}
    80002cf2:	60a2                	ld	ra,8(sp)
    80002cf4:	6402                	ld	s0,0(sp)
    80002cf6:	0141                	addi	sp,sp,16
    80002cf8:	8082                	ret

0000000080002cfa <sys_wait>:

uint64
sys_wait(void)
{
    80002cfa:	1101                	addi	sp,sp,-32
    80002cfc:	ec06                	sd	ra,24(sp)
    80002cfe:	e822                	sd	s0,16(sp)
    80002d00:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d02:	fe840593          	addi	a1,s0,-24
    80002d06:	4501                	li	a0,0
    80002d08:	00000097          	auipc	ra,0x0
    80002d0c:	ece080e7          	jalr	-306(ra) # 80002bd6 <argaddr>
    80002d10:	87aa                	mv	a5,a0
    return -1;
    80002d12:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d14:	0007c863          	bltz	a5,80002d24 <sys_wait+0x2a>
  return wait(p);
    80002d18:	fe843503          	ld	a0,-24(s0)
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	64a080e7          	jalr	1610(ra) # 80002366 <wait>
}
    80002d24:	60e2                	ld	ra,24(sp)
    80002d26:	6442                	ld	s0,16(sp)
    80002d28:	6105                	addi	sp,sp,32
    80002d2a:	8082                	ret

0000000080002d2c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d2c:	7179                	addi	sp,sp,-48
    80002d2e:	f406                	sd	ra,40(sp)
    80002d30:	f022                	sd	s0,32(sp)
    80002d32:	ec26                	sd	s1,24(sp)
    80002d34:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d36:	fdc40593          	addi	a1,s0,-36
    80002d3a:	4501                	li	a0,0
    80002d3c:	00000097          	auipc	ra,0x0
    80002d40:	e78080e7          	jalr	-392(ra) # 80002bb4 <argint>
    80002d44:	87aa                	mv	a5,a0
    return -1;
    80002d46:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d48:	0207c063          	bltz	a5,80002d68 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d4c:	fffff097          	auipc	ra,0xfffff
    80002d50:	d8c080e7          	jalr	-628(ra) # 80001ad8 <myproc>
    80002d54:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d56:	fdc42503          	lw	a0,-36(s0)
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	0ca080e7          	jalr	202(ra) # 80001e24 <growproc>
    80002d62:	00054863          	bltz	a0,80002d72 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d66:	8526                	mv	a0,s1
}
    80002d68:	70a2                	ld	ra,40(sp)
    80002d6a:	7402                	ld	s0,32(sp)
    80002d6c:	64e2                	ld	s1,24(sp)
    80002d6e:	6145                	addi	sp,sp,48
    80002d70:	8082                	ret
    return -1;
    80002d72:	557d                	li	a0,-1
    80002d74:	bfd5                	j	80002d68 <sys_sbrk+0x3c>

0000000080002d76 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d76:	7139                	addi	sp,sp,-64
    80002d78:	fc06                	sd	ra,56(sp)
    80002d7a:	f822                	sd	s0,48(sp)
    80002d7c:	f426                	sd	s1,40(sp)
    80002d7e:	f04a                	sd	s2,32(sp)
    80002d80:	ec4e                	sd	s3,24(sp)
    80002d82:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d84:	fcc40593          	addi	a1,s0,-52
    80002d88:	4501                	li	a0,0
    80002d8a:	00000097          	auipc	ra,0x0
    80002d8e:	e2a080e7          	jalr	-470(ra) # 80002bb4 <argint>
    return -1;
    80002d92:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d94:	06054563          	bltz	a0,80002dfe <sys_sleep+0x88>
  acquire(&tickslock);
    80002d98:	00015517          	auipc	a0,0x15
    80002d9c:	9d050513          	addi	a0,a0,-1584 # 80017768 <tickslock>
    80002da0:	ffffe097          	auipc	ra,0xffffe
    80002da4:	e9e080e7          	jalr	-354(ra) # 80000c3e <acquire>
  ticks0 = ticks;
    80002da8:	00006917          	auipc	s2,0x6
    80002dac:	27892903          	lw	s2,632(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002db0:	fcc42783          	lw	a5,-52(s0)
    80002db4:	cf85                	beqz	a5,80002dec <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002db6:	00015997          	auipc	s3,0x15
    80002dba:	9b298993          	addi	s3,s3,-1614 # 80017768 <tickslock>
    80002dbe:	00006497          	auipc	s1,0x6
    80002dc2:	26248493          	addi	s1,s1,610 # 80009020 <ticks>
    if(myproc()->killed){
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	d12080e7          	jalr	-750(ra) # 80001ad8 <myproc>
    80002dce:	591c                	lw	a5,48(a0)
    80002dd0:	ef9d                	bnez	a5,80002e0e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002dd2:	85ce                	mv	a1,s3
    80002dd4:	8526                	mv	a0,s1
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	512080e7          	jalr	1298(ra) # 800022e8 <sleep>
  while(ticks - ticks0 < n){
    80002dde:	409c                	lw	a5,0(s1)
    80002de0:	412787bb          	subw	a5,a5,s2
    80002de4:	fcc42703          	lw	a4,-52(s0)
    80002de8:	fce7efe3          	bltu	a5,a4,80002dc6 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002dec:	00015517          	auipc	a0,0x15
    80002df0:	97c50513          	addi	a0,a0,-1668 # 80017768 <tickslock>
    80002df4:	ffffe097          	auipc	ra,0xffffe
    80002df8:	efe080e7          	jalr	-258(ra) # 80000cf2 <release>
  return 0;
    80002dfc:	4781                	li	a5,0
}
    80002dfe:	853e                	mv	a0,a5
    80002e00:	70e2                	ld	ra,56(sp)
    80002e02:	7442                	ld	s0,48(sp)
    80002e04:	74a2                	ld	s1,40(sp)
    80002e06:	7902                	ld	s2,32(sp)
    80002e08:	69e2                	ld	s3,24(sp)
    80002e0a:	6121                	addi	sp,sp,64
    80002e0c:	8082                	ret
      release(&tickslock);
    80002e0e:	00015517          	auipc	a0,0x15
    80002e12:	95a50513          	addi	a0,a0,-1702 # 80017768 <tickslock>
    80002e16:	ffffe097          	auipc	ra,0xffffe
    80002e1a:	edc080e7          	jalr	-292(ra) # 80000cf2 <release>
      return -1;
    80002e1e:	57fd                	li	a5,-1
    80002e20:	bff9                	j	80002dfe <sys_sleep+0x88>

0000000080002e22 <sys_kill>:

uint64
sys_kill(void)
{
    80002e22:	1101                	addi	sp,sp,-32
    80002e24:	ec06                	sd	ra,24(sp)
    80002e26:	e822                	sd	s0,16(sp)
    80002e28:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e2a:	fec40593          	addi	a1,s0,-20
    80002e2e:	4501                	li	a0,0
    80002e30:	00000097          	auipc	ra,0x0
    80002e34:	d84080e7          	jalr	-636(ra) # 80002bb4 <argint>
    80002e38:	87aa                	mv	a5,a0
    return -1;
    80002e3a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e3c:	0007c863          	bltz	a5,80002e4c <sys_kill+0x2a>
  return kill(pid);
    80002e40:	fec42503          	lw	a0,-20(s0)
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	694080e7          	jalr	1684(ra) # 800024d8 <kill>
}
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	6105                	addi	sp,sp,32
    80002e52:	8082                	ret

0000000080002e54 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e54:	1101                	addi	sp,sp,-32
    80002e56:	ec06                	sd	ra,24(sp)
    80002e58:	e822                	sd	s0,16(sp)
    80002e5a:	e426                	sd	s1,8(sp)
    80002e5c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e5e:	00015517          	auipc	a0,0x15
    80002e62:	90a50513          	addi	a0,a0,-1782 # 80017768 <tickslock>
    80002e66:	ffffe097          	auipc	ra,0xffffe
    80002e6a:	dd8080e7          	jalr	-552(ra) # 80000c3e <acquire>
  xticks = ticks;
    80002e6e:	00006497          	auipc	s1,0x6
    80002e72:	1b24a483          	lw	s1,434(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e76:	00015517          	auipc	a0,0x15
    80002e7a:	8f250513          	addi	a0,a0,-1806 # 80017768 <tickslock>
    80002e7e:	ffffe097          	auipc	ra,0xffffe
    80002e82:	e74080e7          	jalr	-396(ra) # 80000cf2 <release>
  return xticks;
}
    80002e86:	02049513          	slli	a0,s1,0x20
    80002e8a:	9101                	srli	a0,a0,0x20
    80002e8c:	60e2                	ld	ra,24(sp)
    80002e8e:	6442                	ld	s0,16(sp)
    80002e90:	64a2                	ld	s1,8(sp)
    80002e92:	6105                	addi	sp,sp,32
    80002e94:	8082                	ret

0000000080002e96 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e96:	7179                	addi	sp,sp,-48
    80002e98:	f406                	sd	ra,40(sp)
    80002e9a:	f022                	sd	s0,32(sp)
    80002e9c:	ec26                	sd	s1,24(sp)
    80002e9e:	e84a                	sd	s2,16(sp)
    80002ea0:	e44e                	sd	s3,8(sp)
    80002ea2:	e052                	sd	s4,0(sp)
    80002ea4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ea6:	00005597          	auipc	a1,0x5
    80002eaa:	63258593          	addi	a1,a1,1586 # 800084d8 <syscalls+0xb0>
    80002eae:	00015517          	auipc	a0,0x15
    80002eb2:	8d250513          	addi	a0,a0,-1838 # 80017780 <bcache>
    80002eb6:	ffffe097          	auipc	ra,0xffffe
    80002eba:	cf8080e7          	jalr	-776(ra) # 80000bae <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ebe:	0001d797          	auipc	a5,0x1d
    80002ec2:	8c278793          	addi	a5,a5,-1854 # 8001f780 <bcache+0x8000>
    80002ec6:	0001d717          	auipc	a4,0x1d
    80002eca:	b2270713          	addi	a4,a4,-1246 # 8001f9e8 <bcache+0x8268>
    80002ece:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ed2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ed6:	00015497          	auipc	s1,0x15
    80002eda:	8c248493          	addi	s1,s1,-1854 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002ede:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ee0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ee2:	00005a17          	auipc	s4,0x5
    80002ee6:	5fea0a13          	addi	s4,s4,1534 # 800084e0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002eea:	2b893783          	ld	a5,696(s2)
    80002eee:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ef0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ef4:	85d2                	mv	a1,s4
    80002ef6:	01048513          	addi	a0,s1,16
    80002efa:	00001097          	auipc	ra,0x1
    80002efe:	4b0080e7          	jalr	1200(ra) # 800043aa <initsleeplock>
    bcache.head.next->prev = b;
    80002f02:	2b893783          	ld	a5,696(s2)
    80002f06:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f08:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f0c:	45848493          	addi	s1,s1,1112
    80002f10:	fd349de3          	bne	s1,s3,80002eea <binit+0x54>
  }
}
    80002f14:	70a2                	ld	ra,40(sp)
    80002f16:	7402                	ld	s0,32(sp)
    80002f18:	64e2                	ld	s1,24(sp)
    80002f1a:	6942                	ld	s2,16(sp)
    80002f1c:	69a2                	ld	s3,8(sp)
    80002f1e:	6a02                	ld	s4,0(sp)
    80002f20:	6145                	addi	sp,sp,48
    80002f22:	8082                	ret

0000000080002f24 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f24:	7179                	addi	sp,sp,-48
    80002f26:	f406                	sd	ra,40(sp)
    80002f28:	f022                	sd	s0,32(sp)
    80002f2a:	ec26                	sd	s1,24(sp)
    80002f2c:	e84a                	sd	s2,16(sp)
    80002f2e:	e44e                	sd	s3,8(sp)
    80002f30:	1800                	addi	s0,sp,48
    80002f32:	89aa                	mv	s3,a0
    80002f34:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f36:	00015517          	auipc	a0,0x15
    80002f3a:	84a50513          	addi	a0,a0,-1974 # 80017780 <bcache>
    80002f3e:	ffffe097          	auipc	ra,0xffffe
    80002f42:	d00080e7          	jalr	-768(ra) # 80000c3e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f46:	0001d497          	auipc	s1,0x1d
    80002f4a:	af24b483          	ld	s1,-1294(s1) # 8001fa38 <bcache+0x82b8>
    80002f4e:	0001d797          	auipc	a5,0x1d
    80002f52:	a9a78793          	addi	a5,a5,-1382 # 8001f9e8 <bcache+0x8268>
    80002f56:	02f48f63          	beq	s1,a5,80002f94 <bread+0x70>
    80002f5a:	873e                	mv	a4,a5
    80002f5c:	a021                	j	80002f64 <bread+0x40>
    80002f5e:	68a4                	ld	s1,80(s1)
    80002f60:	02e48a63          	beq	s1,a4,80002f94 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f64:	449c                	lw	a5,8(s1)
    80002f66:	ff379ce3          	bne	a5,s3,80002f5e <bread+0x3a>
    80002f6a:	44dc                	lw	a5,12(s1)
    80002f6c:	ff2799e3          	bne	a5,s2,80002f5e <bread+0x3a>
      b->refcnt++;
    80002f70:	40bc                	lw	a5,64(s1)
    80002f72:	2785                	addiw	a5,a5,1
    80002f74:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f76:	00015517          	auipc	a0,0x15
    80002f7a:	80a50513          	addi	a0,a0,-2038 # 80017780 <bcache>
    80002f7e:	ffffe097          	auipc	ra,0xffffe
    80002f82:	d74080e7          	jalr	-652(ra) # 80000cf2 <release>
      acquiresleep(&b->lock);
    80002f86:	01048513          	addi	a0,s1,16
    80002f8a:	00001097          	auipc	ra,0x1
    80002f8e:	45a080e7          	jalr	1114(ra) # 800043e4 <acquiresleep>
      return b;
    80002f92:	a8b9                	j	80002ff0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f94:	0001d497          	auipc	s1,0x1d
    80002f98:	a9c4b483          	ld	s1,-1380(s1) # 8001fa30 <bcache+0x82b0>
    80002f9c:	0001d797          	auipc	a5,0x1d
    80002fa0:	a4c78793          	addi	a5,a5,-1460 # 8001f9e8 <bcache+0x8268>
    80002fa4:	00f48863          	beq	s1,a5,80002fb4 <bread+0x90>
    80002fa8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002faa:	40bc                	lw	a5,64(s1)
    80002fac:	cf81                	beqz	a5,80002fc4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fae:	64a4                	ld	s1,72(s1)
    80002fb0:	fee49de3          	bne	s1,a4,80002faa <bread+0x86>
  panic("bget: no buffers");
    80002fb4:	00005517          	auipc	a0,0x5
    80002fb8:	53450513          	addi	a0,a0,1332 # 800084e8 <syscalls+0xc0>
    80002fbc:	ffffd097          	auipc	ra,0xffffd
    80002fc0:	58c080e7          	jalr	1420(ra) # 80000548 <panic>
      b->dev = dev;
    80002fc4:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fc8:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fcc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fd0:	4785                	li	a5,1
    80002fd2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fd4:	00014517          	auipc	a0,0x14
    80002fd8:	7ac50513          	addi	a0,a0,1964 # 80017780 <bcache>
    80002fdc:	ffffe097          	auipc	ra,0xffffe
    80002fe0:	d16080e7          	jalr	-746(ra) # 80000cf2 <release>
      acquiresleep(&b->lock);
    80002fe4:	01048513          	addi	a0,s1,16
    80002fe8:	00001097          	auipc	ra,0x1
    80002fec:	3fc080e7          	jalr	1020(ra) # 800043e4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ff0:	409c                	lw	a5,0(s1)
    80002ff2:	cb89                	beqz	a5,80003004 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ff4:	8526                	mv	a0,s1
    80002ff6:	70a2                	ld	ra,40(sp)
    80002ff8:	7402                	ld	s0,32(sp)
    80002ffa:	64e2                	ld	s1,24(sp)
    80002ffc:	6942                	ld	s2,16(sp)
    80002ffe:	69a2                	ld	s3,8(sp)
    80003000:	6145                	addi	sp,sp,48
    80003002:	8082                	ret
    virtio_disk_rw(b, 0);
    80003004:	4581                	li	a1,0
    80003006:	8526                	mv	a0,s1
    80003008:	00003097          	auipc	ra,0x3
    8000300c:	f34080e7          	jalr	-204(ra) # 80005f3c <virtio_disk_rw>
    b->valid = 1;
    80003010:	4785                	li	a5,1
    80003012:	c09c                	sw	a5,0(s1)
  return b;
    80003014:	b7c5                	j	80002ff4 <bread+0xd0>

0000000080003016 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003016:	1101                	addi	sp,sp,-32
    80003018:	ec06                	sd	ra,24(sp)
    8000301a:	e822                	sd	s0,16(sp)
    8000301c:	e426                	sd	s1,8(sp)
    8000301e:	1000                	addi	s0,sp,32
    80003020:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003022:	0541                	addi	a0,a0,16
    80003024:	00001097          	auipc	ra,0x1
    80003028:	45a080e7          	jalr	1114(ra) # 8000447e <holdingsleep>
    8000302c:	cd01                	beqz	a0,80003044 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000302e:	4585                	li	a1,1
    80003030:	8526                	mv	a0,s1
    80003032:	00003097          	auipc	ra,0x3
    80003036:	f0a080e7          	jalr	-246(ra) # 80005f3c <virtio_disk_rw>
}
    8000303a:	60e2                	ld	ra,24(sp)
    8000303c:	6442                	ld	s0,16(sp)
    8000303e:	64a2                	ld	s1,8(sp)
    80003040:	6105                	addi	sp,sp,32
    80003042:	8082                	ret
    panic("bwrite");
    80003044:	00005517          	auipc	a0,0x5
    80003048:	4bc50513          	addi	a0,a0,1212 # 80008500 <syscalls+0xd8>
    8000304c:	ffffd097          	auipc	ra,0xffffd
    80003050:	4fc080e7          	jalr	1276(ra) # 80000548 <panic>

0000000080003054 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003054:	1101                	addi	sp,sp,-32
    80003056:	ec06                	sd	ra,24(sp)
    80003058:	e822                	sd	s0,16(sp)
    8000305a:	e426                	sd	s1,8(sp)
    8000305c:	e04a                	sd	s2,0(sp)
    8000305e:	1000                	addi	s0,sp,32
    80003060:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003062:	01050913          	addi	s2,a0,16
    80003066:	854a                	mv	a0,s2
    80003068:	00001097          	auipc	ra,0x1
    8000306c:	416080e7          	jalr	1046(ra) # 8000447e <holdingsleep>
    80003070:	c92d                	beqz	a0,800030e2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003072:	854a                	mv	a0,s2
    80003074:	00001097          	auipc	ra,0x1
    80003078:	3c6080e7          	jalr	966(ra) # 8000443a <releasesleep>

  acquire(&bcache.lock);
    8000307c:	00014517          	auipc	a0,0x14
    80003080:	70450513          	addi	a0,a0,1796 # 80017780 <bcache>
    80003084:	ffffe097          	auipc	ra,0xffffe
    80003088:	bba080e7          	jalr	-1094(ra) # 80000c3e <acquire>
  b->refcnt--;
    8000308c:	40bc                	lw	a5,64(s1)
    8000308e:	37fd                	addiw	a5,a5,-1
    80003090:	0007871b          	sext.w	a4,a5
    80003094:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003096:	eb05                	bnez	a4,800030c6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003098:	68bc                	ld	a5,80(s1)
    8000309a:	64b8                	ld	a4,72(s1)
    8000309c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000309e:	64bc                	ld	a5,72(s1)
    800030a0:	68b8                	ld	a4,80(s1)
    800030a2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030a4:	0001c797          	auipc	a5,0x1c
    800030a8:	6dc78793          	addi	a5,a5,1756 # 8001f780 <bcache+0x8000>
    800030ac:	2b87b703          	ld	a4,696(a5)
    800030b0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030b2:	0001d717          	auipc	a4,0x1d
    800030b6:	93670713          	addi	a4,a4,-1738 # 8001f9e8 <bcache+0x8268>
    800030ba:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030bc:	2b87b703          	ld	a4,696(a5)
    800030c0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030c2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030c6:	00014517          	auipc	a0,0x14
    800030ca:	6ba50513          	addi	a0,a0,1722 # 80017780 <bcache>
    800030ce:	ffffe097          	auipc	ra,0xffffe
    800030d2:	c24080e7          	jalr	-988(ra) # 80000cf2 <release>
}
    800030d6:	60e2                	ld	ra,24(sp)
    800030d8:	6442                	ld	s0,16(sp)
    800030da:	64a2                	ld	s1,8(sp)
    800030dc:	6902                	ld	s2,0(sp)
    800030de:	6105                	addi	sp,sp,32
    800030e0:	8082                	ret
    panic("brelse");
    800030e2:	00005517          	auipc	a0,0x5
    800030e6:	42650513          	addi	a0,a0,1062 # 80008508 <syscalls+0xe0>
    800030ea:	ffffd097          	auipc	ra,0xffffd
    800030ee:	45e080e7          	jalr	1118(ra) # 80000548 <panic>

00000000800030f2 <bpin>:

void
bpin(struct buf *b) {
    800030f2:	1101                	addi	sp,sp,-32
    800030f4:	ec06                	sd	ra,24(sp)
    800030f6:	e822                	sd	s0,16(sp)
    800030f8:	e426                	sd	s1,8(sp)
    800030fa:	1000                	addi	s0,sp,32
    800030fc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030fe:	00014517          	auipc	a0,0x14
    80003102:	68250513          	addi	a0,a0,1666 # 80017780 <bcache>
    80003106:	ffffe097          	auipc	ra,0xffffe
    8000310a:	b38080e7          	jalr	-1224(ra) # 80000c3e <acquire>
  b->refcnt++;
    8000310e:	40bc                	lw	a5,64(s1)
    80003110:	2785                	addiw	a5,a5,1
    80003112:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003114:	00014517          	auipc	a0,0x14
    80003118:	66c50513          	addi	a0,a0,1644 # 80017780 <bcache>
    8000311c:	ffffe097          	auipc	ra,0xffffe
    80003120:	bd6080e7          	jalr	-1066(ra) # 80000cf2 <release>
}
    80003124:	60e2                	ld	ra,24(sp)
    80003126:	6442                	ld	s0,16(sp)
    80003128:	64a2                	ld	s1,8(sp)
    8000312a:	6105                	addi	sp,sp,32
    8000312c:	8082                	ret

000000008000312e <bunpin>:

void
bunpin(struct buf *b) {
    8000312e:	1101                	addi	sp,sp,-32
    80003130:	ec06                	sd	ra,24(sp)
    80003132:	e822                	sd	s0,16(sp)
    80003134:	e426                	sd	s1,8(sp)
    80003136:	1000                	addi	s0,sp,32
    80003138:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000313a:	00014517          	auipc	a0,0x14
    8000313e:	64650513          	addi	a0,a0,1606 # 80017780 <bcache>
    80003142:	ffffe097          	auipc	ra,0xffffe
    80003146:	afc080e7          	jalr	-1284(ra) # 80000c3e <acquire>
  b->refcnt--;
    8000314a:	40bc                	lw	a5,64(s1)
    8000314c:	37fd                	addiw	a5,a5,-1
    8000314e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003150:	00014517          	auipc	a0,0x14
    80003154:	63050513          	addi	a0,a0,1584 # 80017780 <bcache>
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	b9a080e7          	jalr	-1126(ra) # 80000cf2 <release>
}
    80003160:	60e2                	ld	ra,24(sp)
    80003162:	6442                	ld	s0,16(sp)
    80003164:	64a2                	ld	s1,8(sp)
    80003166:	6105                	addi	sp,sp,32
    80003168:	8082                	ret

000000008000316a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000316a:	1101                	addi	sp,sp,-32
    8000316c:	ec06                	sd	ra,24(sp)
    8000316e:	e822                	sd	s0,16(sp)
    80003170:	e426                	sd	s1,8(sp)
    80003172:	e04a                	sd	s2,0(sp)
    80003174:	1000                	addi	s0,sp,32
    80003176:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003178:	00d5d59b          	srliw	a1,a1,0xd
    8000317c:	0001d797          	auipc	a5,0x1d
    80003180:	ce07a783          	lw	a5,-800(a5) # 8001fe5c <sb+0x1c>
    80003184:	9dbd                	addw	a1,a1,a5
    80003186:	00000097          	auipc	ra,0x0
    8000318a:	d9e080e7          	jalr	-610(ra) # 80002f24 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000318e:	0074f713          	andi	a4,s1,7
    80003192:	4785                	li	a5,1
    80003194:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003198:	14ce                	slli	s1,s1,0x33
    8000319a:	90d9                	srli	s1,s1,0x36
    8000319c:	00950733          	add	a4,a0,s1
    800031a0:	05874703          	lbu	a4,88(a4)
    800031a4:	00e7f6b3          	and	a3,a5,a4
    800031a8:	c69d                	beqz	a3,800031d6 <bfree+0x6c>
    800031aa:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031ac:	94aa                	add	s1,s1,a0
    800031ae:	fff7c793          	not	a5,a5
    800031b2:	8ff9                	and	a5,a5,a4
    800031b4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031b8:	00001097          	auipc	ra,0x1
    800031bc:	104080e7          	jalr	260(ra) # 800042bc <log_write>
  brelse(bp);
    800031c0:	854a                	mv	a0,s2
    800031c2:	00000097          	auipc	ra,0x0
    800031c6:	e92080e7          	jalr	-366(ra) # 80003054 <brelse>
}
    800031ca:	60e2                	ld	ra,24(sp)
    800031cc:	6442                	ld	s0,16(sp)
    800031ce:	64a2                	ld	s1,8(sp)
    800031d0:	6902                	ld	s2,0(sp)
    800031d2:	6105                	addi	sp,sp,32
    800031d4:	8082                	ret
    panic("freeing free block");
    800031d6:	00005517          	auipc	a0,0x5
    800031da:	33a50513          	addi	a0,a0,826 # 80008510 <syscalls+0xe8>
    800031de:	ffffd097          	auipc	ra,0xffffd
    800031e2:	36a080e7          	jalr	874(ra) # 80000548 <panic>

00000000800031e6 <balloc>:
{
    800031e6:	711d                	addi	sp,sp,-96
    800031e8:	ec86                	sd	ra,88(sp)
    800031ea:	e8a2                	sd	s0,80(sp)
    800031ec:	e4a6                	sd	s1,72(sp)
    800031ee:	e0ca                	sd	s2,64(sp)
    800031f0:	fc4e                	sd	s3,56(sp)
    800031f2:	f852                	sd	s4,48(sp)
    800031f4:	f456                	sd	s5,40(sp)
    800031f6:	f05a                	sd	s6,32(sp)
    800031f8:	ec5e                	sd	s7,24(sp)
    800031fa:	e862                	sd	s8,16(sp)
    800031fc:	e466                	sd	s9,8(sp)
    800031fe:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003200:	0001d797          	auipc	a5,0x1d
    80003204:	c447a783          	lw	a5,-956(a5) # 8001fe44 <sb+0x4>
    80003208:	cbd1                	beqz	a5,8000329c <balloc+0xb6>
    8000320a:	8baa                	mv	s7,a0
    8000320c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000320e:	0001db17          	auipc	s6,0x1d
    80003212:	c32b0b13          	addi	s6,s6,-974 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003216:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003218:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000321a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000321c:	6c89                	lui	s9,0x2
    8000321e:	a831                	j	8000323a <balloc+0x54>
    brelse(bp);
    80003220:	854a                	mv	a0,s2
    80003222:	00000097          	auipc	ra,0x0
    80003226:	e32080e7          	jalr	-462(ra) # 80003054 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000322a:	015c87bb          	addw	a5,s9,s5
    8000322e:	00078a9b          	sext.w	s5,a5
    80003232:	004b2703          	lw	a4,4(s6)
    80003236:	06eaf363          	bgeu	s5,a4,8000329c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000323a:	41fad79b          	sraiw	a5,s5,0x1f
    8000323e:	0137d79b          	srliw	a5,a5,0x13
    80003242:	015787bb          	addw	a5,a5,s5
    80003246:	40d7d79b          	sraiw	a5,a5,0xd
    8000324a:	01cb2583          	lw	a1,28(s6)
    8000324e:	9dbd                	addw	a1,a1,a5
    80003250:	855e                	mv	a0,s7
    80003252:	00000097          	auipc	ra,0x0
    80003256:	cd2080e7          	jalr	-814(ra) # 80002f24 <bread>
    8000325a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000325c:	004b2503          	lw	a0,4(s6)
    80003260:	000a849b          	sext.w	s1,s5
    80003264:	8662                	mv	a2,s8
    80003266:	faa4fde3          	bgeu	s1,a0,80003220 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000326a:	41f6579b          	sraiw	a5,a2,0x1f
    8000326e:	01d7d69b          	srliw	a3,a5,0x1d
    80003272:	00c6873b          	addw	a4,a3,a2
    80003276:	00777793          	andi	a5,a4,7
    8000327a:	9f95                	subw	a5,a5,a3
    8000327c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003280:	4037571b          	sraiw	a4,a4,0x3
    80003284:	00e906b3          	add	a3,s2,a4
    80003288:	0586c683          	lbu	a3,88(a3)
    8000328c:	00d7f5b3          	and	a1,a5,a3
    80003290:	cd91                	beqz	a1,800032ac <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003292:	2605                	addiw	a2,a2,1
    80003294:	2485                	addiw	s1,s1,1
    80003296:	fd4618e3          	bne	a2,s4,80003266 <balloc+0x80>
    8000329a:	b759                	j	80003220 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000329c:	00005517          	auipc	a0,0x5
    800032a0:	28c50513          	addi	a0,a0,652 # 80008528 <syscalls+0x100>
    800032a4:	ffffd097          	auipc	ra,0xffffd
    800032a8:	2a4080e7          	jalr	676(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032ac:	974a                	add	a4,a4,s2
    800032ae:	8fd5                	or	a5,a5,a3
    800032b0:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032b4:	854a                	mv	a0,s2
    800032b6:	00001097          	auipc	ra,0x1
    800032ba:	006080e7          	jalr	6(ra) # 800042bc <log_write>
        brelse(bp);
    800032be:	854a                	mv	a0,s2
    800032c0:	00000097          	auipc	ra,0x0
    800032c4:	d94080e7          	jalr	-620(ra) # 80003054 <brelse>
  bp = bread(dev, bno);
    800032c8:	85a6                	mv	a1,s1
    800032ca:	855e                	mv	a0,s7
    800032cc:	00000097          	auipc	ra,0x0
    800032d0:	c58080e7          	jalr	-936(ra) # 80002f24 <bread>
    800032d4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032d6:	40000613          	li	a2,1024
    800032da:	4581                	li	a1,0
    800032dc:	05850513          	addi	a0,a0,88
    800032e0:	ffffe097          	auipc	ra,0xffffe
    800032e4:	a5a080e7          	jalr	-1446(ra) # 80000d3a <memset>
  log_write(bp);
    800032e8:	854a                	mv	a0,s2
    800032ea:	00001097          	auipc	ra,0x1
    800032ee:	fd2080e7          	jalr	-46(ra) # 800042bc <log_write>
  brelse(bp);
    800032f2:	854a                	mv	a0,s2
    800032f4:	00000097          	auipc	ra,0x0
    800032f8:	d60080e7          	jalr	-672(ra) # 80003054 <brelse>
}
    800032fc:	8526                	mv	a0,s1
    800032fe:	60e6                	ld	ra,88(sp)
    80003300:	6446                	ld	s0,80(sp)
    80003302:	64a6                	ld	s1,72(sp)
    80003304:	6906                	ld	s2,64(sp)
    80003306:	79e2                	ld	s3,56(sp)
    80003308:	7a42                	ld	s4,48(sp)
    8000330a:	7aa2                	ld	s5,40(sp)
    8000330c:	7b02                	ld	s6,32(sp)
    8000330e:	6be2                	ld	s7,24(sp)
    80003310:	6c42                	ld	s8,16(sp)
    80003312:	6ca2                	ld	s9,8(sp)
    80003314:	6125                	addi	sp,sp,96
    80003316:	8082                	ret

0000000080003318 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003318:	7179                	addi	sp,sp,-48
    8000331a:	f406                	sd	ra,40(sp)
    8000331c:	f022                	sd	s0,32(sp)
    8000331e:	ec26                	sd	s1,24(sp)
    80003320:	e84a                	sd	s2,16(sp)
    80003322:	e44e                	sd	s3,8(sp)
    80003324:	e052                	sd	s4,0(sp)
    80003326:	1800                	addi	s0,sp,48
    80003328:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000332a:	47ad                	li	a5,11
    8000332c:	04b7fe63          	bgeu	a5,a1,80003388 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003330:	ff45849b          	addiw	s1,a1,-12
    80003334:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003338:	0ff00793          	li	a5,255
    8000333c:	0ae7e363          	bltu	a5,a4,800033e2 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003340:	08052583          	lw	a1,128(a0)
    80003344:	c5ad                	beqz	a1,800033ae <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003346:	00092503          	lw	a0,0(s2)
    8000334a:	00000097          	auipc	ra,0x0
    8000334e:	bda080e7          	jalr	-1062(ra) # 80002f24 <bread>
    80003352:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003354:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003358:	02049593          	slli	a1,s1,0x20
    8000335c:	9181                	srli	a1,a1,0x20
    8000335e:	058a                	slli	a1,a1,0x2
    80003360:	00b784b3          	add	s1,a5,a1
    80003364:	0004a983          	lw	s3,0(s1)
    80003368:	04098d63          	beqz	s3,800033c2 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000336c:	8552                	mv	a0,s4
    8000336e:	00000097          	auipc	ra,0x0
    80003372:	ce6080e7          	jalr	-794(ra) # 80003054 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003376:	854e                	mv	a0,s3
    80003378:	70a2                	ld	ra,40(sp)
    8000337a:	7402                	ld	s0,32(sp)
    8000337c:	64e2                	ld	s1,24(sp)
    8000337e:	6942                	ld	s2,16(sp)
    80003380:	69a2                	ld	s3,8(sp)
    80003382:	6a02                	ld	s4,0(sp)
    80003384:	6145                	addi	sp,sp,48
    80003386:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003388:	02059493          	slli	s1,a1,0x20
    8000338c:	9081                	srli	s1,s1,0x20
    8000338e:	048a                	slli	s1,s1,0x2
    80003390:	94aa                	add	s1,s1,a0
    80003392:	0504a983          	lw	s3,80(s1)
    80003396:	fe0990e3          	bnez	s3,80003376 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000339a:	4108                	lw	a0,0(a0)
    8000339c:	00000097          	auipc	ra,0x0
    800033a0:	e4a080e7          	jalr	-438(ra) # 800031e6 <balloc>
    800033a4:	0005099b          	sext.w	s3,a0
    800033a8:	0534a823          	sw	s3,80(s1)
    800033ac:	b7e9                	j	80003376 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033ae:	4108                	lw	a0,0(a0)
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	e36080e7          	jalr	-458(ra) # 800031e6 <balloc>
    800033b8:	0005059b          	sext.w	a1,a0
    800033bc:	08b92023          	sw	a1,128(s2)
    800033c0:	b759                	j	80003346 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033c2:	00092503          	lw	a0,0(s2)
    800033c6:	00000097          	auipc	ra,0x0
    800033ca:	e20080e7          	jalr	-480(ra) # 800031e6 <balloc>
    800033ce:	0005099b          	sext.w	s3,a0
    800033d2:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033d6:	8552                	mv	a0,s4
    800033d8:	00001097          	auipc	ra,0x1
    800033dc:	ee4080e7          	jalr	-284(ra) # 800042bc <log_write>
    800033e0:	b771                	j	8000336c <bmap+0x54>
  panic("bmap: out of range");
    800033e2:	00005517          	auipc	a0,0x5
    800033e6:	15e50513          	addi	a0,a0,350 # 80008540 <syscalls+0x118>
    800033ea:	ffffd097          	auipc	ra,0xffffd
    800033ee:	15e080e7          	jalr	350(ra) # 80000548 <panic>

00000000800033f2 <iget>:
{
    800033f2:	7179                	addi	sp,sp,-48
    800033f4:	f406                	sd	ra,40(sp)
    800033f6:	f022                	sd	s0,32(sp)
    800033f8:	ec26                	sd	s1,24(sp)
    800033fa:	e84a                	sd	s2,16(sp)
    800033fc:	e44e                	sd	s3,8(sp)
    800033fe:	e052                	sd	s4,0(sp)
    80003400:	1800                	addi	s0,sp,48
    80003402:	89aa                	mv	s3,a0
    80003404:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003406:	0001d517          	auipc	a0,0x1d
    8000340a:	a5a50513          	addi	a0,a0,-1446 # 8001fe60 <icache>
    8000340e:	ffffe097          	auipc	ra,0xffffe
    80003412:	830080e7          	jalr	-2000(ra) # 80000c3e <acquire>
  empty = 0;
    80003416:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003418:	0001d497          	auipc	s1,0x1d
    8000341c:	a6048493          	addi	s1,s1,-1440 # 8001fe78 <icache+0x18>
    80003420:	0001e697          	auipc	a3,0x1e
    80003424:	4e868693          	addi	a3,a3,1256 # 80021908 <log>
    80003428:	a039                	j	80003436 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000342a:	02090b63          	beqz	s2,80003460 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000342e:	08848493          	addi	s1,s1,136
    80003432:	02d48a63          	beq	s1,a3,80003466 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003436:	449c                	lw	a5,8(s1)
    80003438:	fef059e3          	blez	a5,8000342a <iget+0x38>
    8000343c:	4098                	lw	a4,0(s1)
    8000343e:	ff3716e3          	bne	a4,s3,8000342a <iget+0x38>
    80003442:	40d8                	lw	a4,4(s1)
    80003444:	ff4713e3          	bne	a4,s4,8000342a <iget+0x38>
      ip->ref++;
    80003448:	2785                	addiw	a5,a5,1
    8000344a:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000344c:	0001d517          	auipc	a0,0x1d
    80003450:	a1450513          	addi	a0,a0,-1516 # 8001fe60 <icache>
    80003454:	ffffe097          	auipc	ra,0xffffe
    80003458:	89e080e7          	jalr	-1890(ra) # 80000cf2 <release>
      return ip;
    8000345c:	8926                	mv	s2,s1
    8000345e:	a03d                	j	8000348c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003460:	f7f9                	bnez	a5,8000342e <iget+0x3c>
    80003462:	8926                	mv	s2,s1
    80003464:	b7e9                	j	8000342e <iget+0x3c>
  if(empty == 0)
    80003466:	02090c63          	beqz	s2,8000349e <iget+0xac>
  ip->dev = dev;
    8000346a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000346e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003472:	4785                	li	a5,1
    80003474:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003478:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000347c:	0001d517          	auipc	a0,0x1d
    80003480:	9e450513          	addi	a0,a0,-1564 # 8001fe60 <icache>
    80003484:	ffffe097          	auipc	ra,0xffffe
    80003488:	86e080e7          	jalr	-1938(ra) # 80000cf2 <release>
}
    8000348c:	854a                	mv	a0,s2
    8000348e:	70a2                	ld	ra,40(sp)
    80003490:	7402                	ld	s0,32(sp)
    80003492:	64e2                	ld	s1,24(sp)
    80003494:	6942                	ld	s2,16(sp)
    80003496:	69a2                	ld	s3,8(sp)
    80003498:	6a02                	ld	s4,0(sp)
    8000349a:	6145                	addi	sp,sp,48
    8000349c:	8082                	ret
    panic("iget: no inodes");
    8000349e:	00005517          	auipc	a0,0x5
    800034a2:	0ba50513          	addi	a0,a0,186 # 80008558 <syscalls+0x130>
    800034a6:	ffffd097          	auipc	ra,0xffffd
    800034aa:	0a2080e7          	jalr	162(ra) # 80000548 <panic>

00000000800034ae <fsinit>:
fsinit(int dev) {
    800034ae:	7179                	addi	sp,sp,-48
    800034b0:	f406                	sd	ra,40(sp)
    800034b2:	f022                	sd	s0,32(sp)
    800034b4:	ec26                	sd	s1,24(sp)
    800034b6:	e84a                	sd	s2,16(sp)
    800034b8:	e44e                	sd	s3,8(sp)
    800034ba:	1800                	addi	s0,sp,48
    800034bc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034be:	4585                	li	a1,1
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	a64080e7          	jalr	-1436(ra) # 80002f24 <bread>
    800034c8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034ca:	0001d997          	auipc	s3,0x1d
    800034ce:	97698993          	addi	s3,s3,-1674 # 8001fe40 <sb>
    800034d2:	02000613          	li	a2,32
    800034d6:	05850593          	addi	a1,a0,88
    800034da:	854e                	mv	a0,s3
    800034dc:	ffffe097          	auipc	ra,0xffffe
    800034e0:	8be080e7          	jalr	-1858(ra) # 80000d9a <memmove>
  brelse(bp);
    800034e4:	8526                	mv	a0,s1
    800034e6:	00000097          	auipc	ra,0x0
    800034ea:	b6e080e7          	jalr	-1170(ra) # 80003054 <brelse>
  if(sb.magic != FSMAGIC)
    800034ee:	0009a703          	lw	a4,0(s3)
    800034f2:	102037b7          	lui	a5,0x10203
    800034f6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034fa:	02f71263          	bne	a4,a5,8000351e <fsinit+0x70>
  initlog(dev, &sb);
    800034fe:	0001d597          	auipc	a1,0x1d
    80003502:	94258593          	addi	a1,a1,-1726 # 8001fe40 <sb>
    80003506:	854a                	mv	a0,s2
    80003508:	00001097          	auipc	ra,0x1
    8000350c:	b3c080e7          	jalr	-1220(ra) # 80004044 <initlog>
}
    80003510:	70a2                	ld	ra,40(sp)
    80003512:	7402                	ld	s0,32(sp)
    80003514:	64e2                	ld	s1,24(sp)
    80003516:	6942                	ld	s2,16(sp)
    80003518:	69a2                	ld	s3,8(sp)
    8000351a:	6145                	addi	sp,sp,48
    8000351c:	8082                	ret
    panic("invalid file system");
    8000351e:	00005517          	auipc	a0,0x5
    80003522:	04a50513          	addi	a0,a0,74 # 80008568 <syscalls+0x140>
    80003526:	ffffd097          	auipc	ra,0xffffd
    8000352a:	022080e7          	jalr	34(ra) # 80000548 <panic>

000000008000352e <iinit>:
{
    8000352e:	7179                	addi	sp,sp,-48
    80003530:	f406                	sd	ra,40(sp)
    80003532:	f022                	sd	s0,32(sp)
    80003534:	ec26                	sd	s1,24(sp)
    80003536:	e84a                	sd	s2,16(sp)
    80003538:	e44e                	sd	s3,8(sp)
    8000353a:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000353c:	00005597          	auipc	a1,0x5
    80003540:	04458593          	addi	a1,a1,68 # 80008580 <syscalls+0x158>
    80003544:	0001d517          	auipc	a0,0x1d
    80003548:	91c50513          	addi	a0,a0,-1764 # 8001fe60 <icache>
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	662080e7          	jalr	1634(ra) # 80000bae <initlock>
  for(i = 0; i < NINODE; i++) {
    80003554:	0001d497          	auipc	s1,0x1d
    80003558:	93448493          	addi	s1,s1,-1740 # 8001fe88 <icache+0x28>
    8000355c:	0001e997          	auipc	s3,0x1e
    80003560:	3bc98993          	addi	s3,s3,956 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003564:	00005917          	auipc	s2,0x5
    80003568:	02490913          	addi	s2,s2,36 # 80008588 <syscalls+0x160>
    8000356c:	85ca                	mv	a1,s2
    8000356e:	8526                	mv	a0,s1
    80003570:	00001097          	auipc	ra,0x1
    80003574:	e3a080e7          	jalr	-454(ra) # 800043aa <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003578:	08848493          	addi	s1,s1,136
    8000357c:	ff3498e3          	bne	s1,s3,8000356c <iinit+0x3e>
}
    80003580:	70a2                	ld	ra,40(sp)
    80003582:	7402                	ld	s0,32(sp)
    80003584:	64e2                	ld	s1,24(sp)
    80003586:	6942                	ld	s2,16(sp)
    80003588:	69a2                	ld	s3,8(sp)
    8000358a:	6145                	addi	sp,sp,48
    8000358c:	8082                	ret

000000008000358e <ialloc>:
{
    8000358e:	715d                	addi	sp,sp,-80
    80003590:	e486                	sd	ra,72(sp)
    80003592:	e0a2                	sd	s0,64(sp)
    80003594:	fc26                	sd	s1,56(sp)
    80003596:	f84a                	sd	s2,48(sp)
    80003598:	f44e                	sd	s3,40(sp)
    8000359a:	f052                	sd	s4,32(sp)
    8000359c:	ec56                	sd	s5,24(sp)
    8000359e:	e85a                	sd	s6,16(sp)
    800035a0:	e45e                	sd	s7,8(sp)
    800035a2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035a4:	0001d717          	auipc	a4,0x1d
    800035a8:	8a872703          	lw	a4,-1880(a4) # 8001fe4c <sb+0xc>
    800035ac:	4785                	li	a5,1
    800035ae:	04e7fa63          	bgeu	a5,a4,80003602 <ialloc+0x74>
    800035b2:	8aaa                	mv	s5,a0
    800035b4:	8bae                	mv	s7,a1
    800035b6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035b8:	0001da17          	auipc	s4,0x1d
    800035bc:	888a0a13          	addi	s4,s4,-1912 # 8001fe40 <sb>
    800035c0:	00048b1b          	sext.w	s6,s1
    800035c4:	0044d593          	srli	a1,s1,0x4
    800035c8:	018a2783          	lw	a5,24(s4)
    800035cc:	9dbd                	addw	a1,a1,a5
    800035ce:	8556                	mv	a0,s5
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	954080e7          	jalr	-1708(ra) # 80002f24 <bread>
    800035d8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035da:	05850993          	addi	s3,a0,88
    800035de:	00f4f793          	andi	a5,s1,15
    800035e2:	079a                	slli	a5,a5,0x6
    800035e4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035e6:	00099783          	lh	a5,0(s3)
    800035ea:	c785                	beqz	a5,80003612 <ialloc+0x84>
    brelse(bp);
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	a68080e7          	jalr	-1432(ra) # 80003054 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035f4:	0485                	addi	s1,s1,1
    800035f6:	00ca2703          	lw	a4,12(s4)
    800035fa:	0004879b          	sext.w	a5,s1
    800035fe:	fce7e1e3          	bltu	a5,a4,800035c0 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003602:	00005517          	auipc	a0,0x5
    80003606:	f8e50513          	addi	a0,a0,-114 # 80008590 <syscalls+0x168>
    8000360a:	ffffd097          	auipc	ra,0xffffd
    8000360e:	f3e080e7          	jalr	-194(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003612:	04000613          	li	a2,64
    80003616:	4581                	li	a1,0
    80003618:	854e                	mv	a0,s3
    8000361a:	ffffd097          	auipc	ra,0xffffd
    8000361e:	720080e7          	jalr	1824(ra) # 80000d3a <memset>
      dip->type = type;
    80003622:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003626:	854a                	mv	a0,s2
    80003628:	00001097          	auipc	ra,0x1
    8000362c:	c94080e7          	jalr	-876(ra) # 800042bc <log_write>
      brelse(bp);
    80003630:	854a                	mv	a0,s2
    80003632:	00000097          	auipc	ra,0x0
    80003636:	a22080e7          	jalr	-1502(ra) # 80003054 <brelse>
      return iget(dev, inum);
    8000363a:	85da                	mv	a1,s6
    8000363c:	8556                	mv	a0,s5
    8000363e:	00000097          	auipc	ra,0x0
    80003642:	db4080e7          	jalr	-588(ra) # 800033f2 <iget>
}
    80003646:	60a6                	ld	ra,72(sp)
    80003648:	6406                	ld	s0,64(sp)
    8000364a:	74e2                	ld	s1,56(sp)
    8000364c:	7942                	ld	s2,48(sp)
    8000364e:	79a2                	ld	s3,40(sp)
    80003650:	7a02                	ld	s4,32(sp)
    80003652:	6ae2                	ld	s5,24(sp)
    80003654:	6b42                	ld	s6,16(sp)
    80003656:	6ba2                	ld	s7,8(sp)
    80003658:	6161                	addi	sp,sp,80
    8000365a:	8082                	ret

000000008000365c <iupdate>:
{
    8000365c:	1101                	addi	sp,sp,-32
    8000365e:	ec06                	sd	ra,24(sp)
    80003660:	e822                	sd	s0,16(sp)
    80003662:	e426                	sd	s1,8(sp)
    80003664:	e04a                	sd	s2,0(sp)
    80003666:	1000                	addi	s0,sp,32
    80003668:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000366a:	415c                	lw	a5,4(a0)
    8000366c:	0047d79b          	srliw	a5,a5,0x4
    80003670:	0001c597          	auipc	a1,0x1c
    80003674:	7e85a583          	lw	a1,2024(a1) # 8001fe58 <sb+0x18>
    80003678:	9dbd                	addw	a1,a1,a5
    8000367a:	4108                	lw	a0,0(a0)
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	8a8080e7          	jalr	-1880(ra) # 80002f24 <bread>
    80003684:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003686:	05850793          	addi	a5,a0,88
    8000368a:	40c8                	lw	a0,4(s1)
    8000368c:	893d                	andi	a0,a0,15
    8000368e:	051a                	slli	a0,a0,0x6
    80003690:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003692:	04449703          	lh	a4,68(s1)
    80003696:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000369a:	04649703          	lh	a4,70(s1)
    8000369e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036a2:	04849703          	lh	a4,72(s1)
    800036a6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036aa:	04a49703          	lh	a4,74(s1)
    800036ae:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036b2:	44f8                	lw	a4,76(s1)
    800036b4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036b6:	03400613          	li	a2,52
    800036ba:	05048593          	addi	a1,s1,80
    800036be:	0531                	addi	a0,a0,12
    800036c0:	ffffd097          	auipc	ra,0xffffd
    800036c4:	6da080e7          	jalr	1754(ra) # 80000d9a <memmove>
  log_write(bp);
    800036c8:	854a                	mv	a0,s2
    800036ca:	00001097          	auipc	ra,0x1
    800036ce:	bf2080e7          	jalr	-1038(ra) # 800042bc <log_write>
  brelse(bp);
    800036d2:	854a                	mv	a0,s2
    800036d4:	00000097          	auipc	ra,0x0
    800036d8:	980080e7          	jalr	-1664(ra) # 80003054 <brelse>
}
    800036dc:	60e2                	ld	ra,24(sp)
    800036de:	6442                	ld	s0,16(sp)
    800036e0:	64a2                	ld	s1,8(sp)
    800036e2:	6902                	ld	s2,0(sp)
    800036e4:	6105                	addi	sp,sp,32
    800036e6:	8082                	ret

00000000800036e8 <idup>:
{
    800036e8:	1101                	addi	sp,sp,-32
    800036ea:	ec06                	sd	ra,24(sp)
    800036ec:	e822                	sd	s0,16(sp)
    800036ee:	e426                	sd	s1,8(sp)
    800036f0:	1000                	addi	s0,sp,32
    800036f2:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800036f4:	0001c517          	auipc	a0,0x1c
    800036f8:	76c50513          	addi	a0,a0,1900 # 8001fe60 <icache>
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	542080e7          	jalr	1346(ra) # 80000c3e <acquire>
  ip->ref++;
    80003704:	449c                	lw	a5,8(s1)
    80003706:	2785                	addiw	a5,a5,1
    80003708:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000370a:	0001c517          	auipc	a0,0x1c
    8000370e:	75650513          	addi	a0,a0,1878 # 8001fe60 <icache>
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	5e0080e7          	jalr	1504(ra) # 80000cf2 <release>
}
    8000371a:	8526                	mv	a0,s1
    8000371c:	60e2                	ld	ra,24(sp)
    8000371e:	6442                	ld	s0,16(sp)
    80003720:	64a2                	ld	s1,8(sp)
    80003722:	6105                	addi	sp,sp,32
    80003724:	8082                	ret

0000000080003726 <ilock>:
{
    80003726:	1101                	addi	sp,sp,-32
    80003728:	ec06                	sd	ra,24(sp)
    8000372a:	e822                	sd	s0,16(sp)
    8000372c:	e426                	sd	s1,8(sp)
    8000372e:	e04a                	sd	s2,0(sp)
    80003730:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003732:	c115                	beqz	a0,80003756 <ilock+0x30>
    80003734:	84aa                	mv	s1,a0
    80003736:	451c                	lw	a5,8(a0)
    80003738:	00f05f63          	blez	a5,80003756 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000373c:	0541                	addi	a0,a0,16
    8000373e:	00001097          	auipc	ra,0x1
    80003742:	ca6080e7          	jalr	-858(ra) # 800043e4 <acquiresleep>
  if(ip->valid == 0){
    80003746:	40bc                	lw	a5,64(s1)
    80003748:	cf99                	beqz	a5,80003766 <ilock+0x40>
}
    8000374a:	60e2                	ld	ra,24(sp)
    8000374c:	6442                	ld	s0,16(sp)
    8000374e:	64a2                	ld	s1,8(sp)
    80003750:	6902                	ld	s2,0(sp)
    80003752:	6105                	addi	sp,sp,32
    80003754:	8082                	ret
    panic("ilock");
    80003756:	00005517          	auipc	a0,0x5
    8000375a:	e5250513          	addi	a0,a0,-430 # 800085a8 <syscalls+0x180>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	dea080e7          	jalr	-534(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003766:	40dc                	lw	a5,4(s1)
    80003768:	0047d79b          	srliw	a5,a5,0x4
    8000376c:	0001c597          	auipc	a1,0x1c
    80003770:	6ec5a583          	lw	a1,1772(a1) # 8001fe58 <sb+0x18>
    80003774:	9dbd                	addw	a1,a1,a5
    80003776:	4088                	lw	a0,0(s1)
    80003778:	fffff097          	auipc	ra,0xfffff
    8000377c:	7ac080e7          	jalr	1964(ra) # 80002f24 <bread>
    80003780:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003782:	05850593          	addi	a1,a0,88
    80003786:	40dc                	lw	a5,4(s1)
    80003788:	8bbd                	andi	a5,a5,15
    8000378a:	079a                	slli	a5,a5,0x6
    8000378c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000378e:	00059783          	lh	a5,0(a1)
    80003792:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003796:	00259783          	lh	a5,2(a1)
    8000379a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000379e:	00459783          	lh	a5,4(a1)
    800037a2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037a6:	00659783          	lh	a5,6(a1)
    800037aa:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037ae:	459c                	lw	a5,8(a1)
    800037b0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037b2:	03400613          	li	a2,52
    800037b6:	05b1                	addi	a1,a1,12
    800037b8:	05048513          	addi	a0,s1,80
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	5de080e7          	jalr	1502(ra) # 80000d9a <memmove>
    brelse(bp);
    800037c4:	854a                	mv	a0,s2
    800037c6:	00000097          	auipc	ra,0x0
    800037ca:	88e080e7          	jalr	-1906(ra) # 80003054 <brelse>
    ip->valid = 1;
    800037ce:	4785                	li	a5,1
    800037d0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037d2:	04449783          	lh	a5,68(s1)
    800037d6:	fbb5                	bnez	a5,8000374a <ilock+0x24>
      panic("ilock: no type");
    800037d8:	00005517          	auipc	a0,0x5
    800037dc:	dd850513          	addi	a0,a0,-552 # 800085b0 <syscalls+0x188>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	d68080e7          	jalr	-664(ra) # 80000548 <panic>

00000000800037e8 <iunlock>:
{
    800037e8:	1101                	addi	sp,sp,-32
    800037ea:	ec06                	sd	ra,24(sp)
    800037ec:	e822                	sd	s0,16(sp)
    800037ee:	e426                	sd	s1,8(sp)
    800037f0:	e04a                	sd	s2,0(sp)
    800037f2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037f4:	c905                	beqz	a0,80003824 <iunlock+0x3c>
    800037f6:	84aa                	mv	s1,a0
    800037f8:	01050913          	addi	s2,a0,16
    800037fc:	854a                	mv	a0,s2
    800037fe:	00001097          	auipc	ra,0x1
    80003802:	c80080e7          	jalr	-896(ra) # 8000447e <holdingsleep>
    80003806:	cd19                	beqz	a0,80003824 <iunlock+0x3c>
    80003808:	449c                	lw	a5,8(s1)
    8000380a:	00f05d63          	blez	a5,80003824 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000380e:	854a                	mv	a0,s2
    80003810:	00001097          	auipc	ra,0x1
    80003814:	c2a080e7          	jalr	-982(ra) # 8000443a <releasesleep>
}
    80003818:	60e2                	ld	ra,24(sp)
    8000381a:	6442                	ld	s0,16(sp)
    8000381c:	64a2                	ld	s1,8(sp)
    8000381e:	6902                	ld	s2,0(sp)
    80003820:	6105                	addi	sp,sp,32
    80003822:	8082                	ret
    panic("iunlock");
    80003824:	00005517          	auipc	a0,0x5
    80003828:	d9c50513          	addi	a0,a0,-612 # 800085c0 <syscalls+0x198>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	d1c080e7          	jalr	-740(ra) # 80000548 <panic>

0000000080003834 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003834:	7179                	addi	sp,sp,-48
    80003836:	f406                	sd	ra,40(sp)
    80003838:	f022                	sd	s0,32(sp)
    8000383a:	ec26                	sd	s1,24(sp)
    8000383c:	e84a                	sd	s2,16(sp)
    8000383e:	e44e                	sd	s3,8(sp)
    80003840:	e052                	sd	s4,0(sp)
    80003842:	1800                	addi	s0,sp,48
    80003844:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003846:	05050493          	addi	s1,a0,80
    8000384a:	08050913          	addi	s2,a0,128
    8000384e:	a021                	j	80003856 <itrunc+0x22>
    80003850:	0491                	addi	s1,s1,4
    80003852:	01248d63          	beq	s1,s2,8000386c <itrunc+0x38>
    if(ip->addrs[i]){
    80003856:	408c                	lw	a1,0(s1)
    80003858:	dde5                	beqz	a1,80003850 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000385a:	0009a503          	lw	a0,0(s3)
    8000385e:	00000097          	auipc	ra,0x0
    80003862:	90c080e7          	jalr	-1780(ra) # 8000316a <bfree>
      ip->addrs[i] = 0;
    80003866:	0004a023          	sw	zero,0(s1)
    8000386a:	b7dd                	j	80003850 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000386c:	0809a583          	lw	a1,128(s3)
    80003870:	e185                	bnez	a1,80003890 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003872:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003876:	854e                	mv	a0,s3
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	de4080e7          	jalr	-540(ra) # 8000365c <iupdate>
}
    80003880:	70a2                	ld	ra,40(sp)
    80003882:	7402                	ld	s0,32(sp)
    80003884:	64e2                	ld	s1,24(sp)
    80003886:	6942                	ld	s2,16(sp)
    80003888:	69a2                	ld	s3,8(sp)
    8000388a:	6a02                	ld	s4,0(sp)
    8000388c:	6145                	addi	sp,sp,48
    8000388e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003890:	0009a503          	lw	a0,0(s3)
    80003894:	fffff097          	auipc	ra,0xfffff
    80003898:	690080e7          	jalr	1680(ra) # 80002f24 <bread>
    8000389c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000389e:	05850493          	addi	s1,a0,88
    800038a2:	45850913          	addi	s2,a0,1112
    800038a6:	a811                	j	800038ba <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038a8:	0009a503          	lw	a0,0(s3)
    800038ac:	00000097          	auipc	ra,0x0
    800038b0:	8be080e7          	jalr	-1858(ra) # 8000316a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038b4:	0491                	addi	s1,s1,4
    800038b6:	01248563          	beq	s1,s2,800038c0 <itrunc+0x8c>
      if(a[j])
    800038ba:	408c                	lw	a1,0(s1)
    800038bc:	dde5                	beqz	a1,800038b4 <itrunc+0x80>
    800038be:	b7ed                	j	800038a8 <itrunc+0x74>
    brelse(bp);
    800038c0:	8552                	mv	a0,s4
    800038c2:	fffff097          	auipc	ra,0xfffff
    800038c6:	792080e7          	jalr	1938(ra) # 80003054 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038ca:	0809a583          	lw	a1,128(s3)
    800038ce:	0009a503          	lw	a0,0(s3)
    800038d2:	00000097          	auipc	ra,0x0
    800038d6:	898080e7          	jalr	-1896(ra) # 8000316a <bfree>
    ip->addrs[NDIRECT] = 0;
    800038da:	0809a023          	sw	zero,128(s3)
    800038de:	bf51                	j	80003872 <itrunc+0x3e>

00000000800038e0 <iput>:
{
    800038e0:	1101                	addi	sp,sp,-32
    800038e2:	ec06                	sd	ra,24(sp)
    800038e4:	e822                	sd	s0,16(sp)
    800038e6:	e426                	sd	s1,8(sp)
    800038e8:	e04a                	sd	s2,0(sp)
    800038ea:	1000                	addi	s0,sp,32
    800038ec:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038ee:	0001c517          	auipc	a0,0x1c
    800038f2:	57250513          	addi	a0,a0,1394 # 8001fe60 <icache>
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	348080e7          	jalr	840(ra) # 80000c3e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038fe:	4498                	lw	a4,8(s1)
    80003900:	4785                	li	a5,1
    80003902:	02f70363          	beq	a4,a5,80003928 <iput+0x48>
  ip->ref--;
    80003906:	449c                	lw	a5,8(s1)
    80003908:	37fd                	addiw	a5,a5,-1
    8000390a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000390c:	0001c517          	auipc	a0,0x1c
    80003910:	55450513          	addi	a0,a0,1364 # 8001fe60 <icache>
    80003914:	ffffd097          	auipc	ra,0xffffd
    80003918:	3de080e7          	jalr	990(ra) # 80000cf2 <release>
}
    8000391c:	60e2                	ld	ra,24(sp)
    8000391e:	6442                	ld	s0,16(sp)
    80003920:	64a2                	ld	s1,8(sp)
    80003922:	6902                	ld	s2,0(sp)
    80003924:	6105                	addi	sp,sp,32
    80003926:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003928:	40bc                	lw	a5,64(s1)
    8000392a:	dff1                	beqz	a5,80003906 <iput+0x26>
    8000392c:	04a49783          	lh	a5,74(s1)
    80003930:	fbf9                	bnez	a5,80003906 <iput+0x26>
    acquiresleep(&ip->lock);
    80003932:	01048913          	addi	s2,s1,16
    80003936:	854a                	mv	a0,s2
    80003938:	00001097          	auipc	ra,0x1
    8000393c:	aac080e7          	jalr	-1364(ra) # 800043e4 <acquiresleep>
    release(&icache.lock);
    80003940:	0001c517          	auipc	a0,0x1c
    80003944:	52050513          	addi	a0,a0,1312 # 8001fe60 <icache>
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	3aa080e7          	jalr	938(ra) # 80000cf2 <release>
    itrunc(ip);
    80003950:	8526                	mv	a0,s1
    80003952:	00000097          	auipc	ra,0x0
    80003956:	ee2080e7          	jalr	-286(ra) # 80003834 <itrunc>
    ip->type = 0;
    8000395a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000395e:	8526                	mv	a0,s1
    80003960:	00000097          	auipc	ra,0x0
    80003964:	cfc080e7          	jalr	-772(ra) # 8000365c <iupdate>
    ip->valid = 0;
    80003968:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000396c:	854a                	mv	a0,s2
    8000396e:	00001097          	auipc	ra,0x1
    80003972:	acc080e7          	jalr	-1332(ra) # 8000443a <releasesleep>
    acquire(&icache.lock);
    80003976:	0001c517          	auipc	a0,0x1c
    8000397a:	4ea50513          	addi	a0,a0,1258 # 8001fe60 <icache>
    8000397e:	ffffd097          	auipc	ra,0xffffd
    80003982:	2c0080e7          	jalr	704(ra) # 80000c3e <acquire>
    80003986:	b741                	j	80003906 <iput+0x26>

0000000080003988 <iunlockput>:
{
    80003988:	1101                	addi	sp,sp,-32
    8000398a:	ec06                	sd	ra,24(sp)
    8000398c:	e822                	sd	s0,16(sp)
    8000398e:	e426                	sd	s1,8(sp)
    80003990:	1000                	addi	s0,sp,32
    80003992:	84aa                	mv	s1,a0
  iunlock(ip);
    80003994:	00000097          	auipc	ra,0x0
    80003998:	e54080e7          	jalr	-428(ra) # 800037e8 <iunlock>
  iput(ip);
    8000399c:	8526                	mv	a0,s1
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	f42080e7          	jalr	-190(ra) # 800038e0 <iput>
}
    800039a6:	60e2                	ld	ra,24(sp)
    800039a8:	6442                	ld	s0,16(sp)
    800039aa:	64a2                	ld	s1,8(sp)
    800039ac:	6105                	addi	sp,sp,32
    800039ae:	8082                	ret

00000000800039b0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039b0:	1141                	addi	sp,sp,-16
    800039b2:	e422                	sd	s0,8(sp)
    800039b4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039b6:	411c                	lw	a5,0(a0)
    800039b8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039ba:	415c                	lw	a5,4(a0)
    800039bc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039be:	04451783          	lh	a5,68(a0)
    800039c2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039c6:	04a51783          	lh	a5,74(a0)
    800039ca:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039ce:	04c56783          	lwu	a5,76(a0)
    800039d2:	e99c                	sd	a5,16(a1)
}
    800039d4:	6422                	ld	s0,8(sp)
    800039d6:	0141                	addi	sp,sp,16
    800039d8:	8082                	ret

00000000800039da <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039da:	457c                	lw	a5,76(a0)
    800039dc:	0ed7e963          	bltu	a5,a3,80003ace <readi+0xf4>
{
    800039e0:	7159                	addi	sp,sp,-112
    800039e2:	f486                	sd	ra,104(sp)
    800039e4:	f0a2                	sd	s0,96(sp)
    800039e6:	eca6                	sd	s1,88(sp)
    800039e8:	e8ca                	sd	s2,80(sp)
    800039ea:	e4ce                	sd	s3,72(sp)
    800039ec:	e0d2                	sd	s4,64(sp)
    800039ee:	fc56                	sd	s5,56(sp)
    800039f0:	f85a                	sd	s6,48(sp)
    800039f2:	f45e                	sd	s7,40(sp)
    800039f4:	f062                	sd	s8,32(sp)
    800039f6:	ec66                	sd	s9,24(sp)
    800039f8:	e86a                	sd	s10,16(sp)
    800039fa:	e46e                	sd	s11,8(sp)
    800039fc:	1880                	addi	s0,sp,112
    800039fe:	8baa                	mv	s7,a0
    80003a00:	8c2e                	mv	s8,a1
    80003a02:	8ab2                	mv	s5,a2
    80003a04:	84b6                	mv	s1,a3
    80003a06:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a08:	9f35                	addw	a4,a4,a3
    return 0;
    80003a0a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a0c:	0ad76063          	bltu	a4,a3,80003aac <readi+0xd2>
  if(off + n > ip->size)
    80003a10:	00e7f463          	bgeu	a5,a4,80003a18 <readi+0x3e>
    n = ip->size - off;
    80003a14:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a18:	0a0b0963          	beqz	s6,80003aca <readi+0xf0>
    80003a1c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a1e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a22:	5cfd                	li	s9,-1
    80003a24:	a82d                	j	80003a5e <readi+0x84>
    80003a26:	020a1d93          	slli	s11,s4,0x20
    80003a2a:	020ddd93          	srli	s11,s11,0x20
    80003a2e:	05890613          	addi	a2,s2,88
    80003a32:	86ee                	mv	a3,s11
    80003a34:	963a                	add	a2,a2,a4
    80003a36:	85d6                	mv	a1,s5
    80003a38:	8562                	mv	a0,s8
    80003a3a:	fffff097          	auipc	ra,0xfffff
    80003a3e:	b10080e7          	jalr	-1264(ra) # 8000254a <either_copyout>
    80003a42:	05950d63          	beq	a0,s9,80003a9c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a46:	854a                	mv	a0,s2
    80003a48:	fffff097          	auipc	ra,0xfffff
    80003a4c:	60c080e7          	jalr	1548(ra) # 80003054 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a50:	013a09bb          	addw	s3,s4,s3
    80003a54:	009a04bb          	addw	s1,s4,s1
    80003a58:	9aee                	add	s5,s5,s11
    80003a5a:	0569f763          	bgeu	s3,s6,80003aa8 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a5e:	000ba903          	lw	s2,0(s7)
    80003a62:	00a4d59b          	srliw	a1,s1,0xa
    80003a66:	855e                	mv	a0,s7
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	8b0080e7          	jalr	-1872(ra) # 80003318 <bmap>
    80003a70:	0005059b          	sext.w	a1,a0
    80003a74:	854a                	mv	a0,s2
    80003a76:	fffff097          	auipc	ra,0xfffff
    80003a7a:	4ae080e7          	jalr	1198(ra) # 80002f24 <bread>
    80003a7e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a80:	3ff4f713          	andi	a4,s1,1023
    80003a84:	40ed07bb          	subw	a5,s10,a4
    80003a88:	413b06bb          	subw	a3,s6,s3
    80003a8c:	8a3e                	mv	s4,a5
    80003a8e:	2781                	sext.w	a5,a5
    80003a90:	0006861b          	sext.w	a2,a3
    80003a94:	f8f679e3          	bgeu	a2,a5,80003a26 <readi+0x4c>
    80003a98:	8a36                	mv	s4,a3
    80003a9a:	b771                	j	80003a26 <readi+0x4c>
      brelse(bp);
    80003a9c:	854a                	mv	a0,s2
    80003a9e:	fffff097          	auipc	ra,0xfffff
    80003aa2:	5b6080e7          	jalr	1462(ra) # 80003054 <brelse>
      tot = -1;
    80003aa6:	59fd                	li	s3,-1
  }
  return tot;
    80003aa8:	0009851b          	sext.w	a0,s3
}
    80003aac:	70a6                	ld	ra,104(sp)
    80003aae:	7406                	ld	s0,96(sp)
    80003ab0:	64e6                	ld	s1,88(sp)
    80003ab2:	6946                	ld	s2,80(sp)
    80003ab4:	69a6                	ld	s3,72(sp)
    80003ab6:	6a06                	ld	s4,64(sp)
    80003ab8:	7ae2                	ld	s5,56(sp)
    80003aba:	7b42                	ld	s6,48(sp)
    80003abc:	7ba2                	ld	s7,40(sp)
    80003abe:	7c02                	ld	s8,32(sp)
    80003ac0:	6ce2                	ld	s9,24(sp)
    80003ac2:	6d42                	ld	s10,16(sp)
    80003ac4:	6da2                	ld	s11,8(sp)
    80003ac6:	6165                	addi	sp,sp,112
    80003ac8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aca:	89da                	mv	s3,s6
    80003acc:	bff1                	j	80003aa8 <readi+0xce>
    return 0;
    80003ace:	4501                	li	a0,0
}
    80003ad0:	8082                	ret

0000000080003ad2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ad2:	457c                	lw	a5,76(a0)
    80003ad4:	10d7e763          	bltu	a5,a3,80003be2 <writei+0x110>
{
    80003ad8:	7159                	addi	sp,sp,-112
    80003ada:	f486                	sd	ra,104(sp)
    80003adc:	f0a2                	sd	s0,96(sp)
    80003ade:	eca6                	sd	s1,88(sp)
    80003ae0:	e8ca                	sd	s2,80(sp)
    80003ae2:	e4ce                	sd	s3,72(sp)
    80003ae4:	e0d2                	sd	s4,64(sp)
    80003ae6:	fc56                	sd	s5,56(sp)
    80003ae8:	f85a                	sd	s6,48(sp)
    80003aea:	f45e                	sd	s7,40(sp)
    80003aec:	f062                	sd	s8,32(sp)
    80003aee:	ec66                	sd	s9,24(sp)
    80003af0:	e86a                	sd	s10,16(sp)
    80003af2:	e46e                	sd	s11,8(sp)
    80003af4:	1880                	addi	s0,sp,112
    80003af6:	8baa                	mv	s7,a0
    80003af8:	8c2e                	mv	s8,a1
    80003afa:	8ab2                	mv	s5,a2
    80003afc:	8936                	mv	s2,a3
    80003afe:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b00:	00e687bb          	addw	a5,a3,a4
    80003b04:	0ed7e163          	bltu	a5,a3,80003be6 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b08:	00043737          	lui	a4,0x43
    80003b0c:	0cf76f63          	bltu	a4,a5,80003bea <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b10:	0a0b0863          	beqz	s6,80003bc0 <writei+0xee>
    80003b14:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b16:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b1a:	5cfd                	li	s9,-1
    80003b1c:	a091                	j	80003b60 <writei+0x8e>
    80003b1e:	02099d93          	slli	s11,s3,0x20
    80003b22:	020ddd93          	srli	s11,s11,0x20
    80003b26:	05848513          	addi	a0,s1,88
    80003b2a:	86ee                	mv	a3,s11
    80003b2c:	8656                	mv	a2,s5
    80003b2e:	85e2                	mv	a1,s8
    80003b30:	953a                	add	a0,a0,a4
    80003b32:	fffff097          	auipc	ra,0xfffff
    80003b36:	a6e080e7          	jalr	-1426(ra) # 800025a0 <either_copyin>
    80003b3a:	07950263          	beq	a0,s9,80003b9e <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003b3e:	8526                	mv	a0,s1
    80003b40:	00000097          	auipc	ra,0x0
    80003b44:	77c080e7          	jalr	1916(ra) # 800042bc <log_write>
    brelse(bp);
    80003b48:	8526                	mv	a0,s1
    80003b4a:	fffff097          	auipc	ra,0xfffff
    80003b4e:	50a080e7          	jalr	1290(ra) # 80003054 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b52:	01498a3b          	addw	s4,s3,s4
    80003b56:	0129893b          	addw	s2,s3,s2
    80003b5a:	9aee                	add	s5,s5,s11
    80003b5c:	056a7763          	bgeu	s4,s6,80003baa <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b60:	000ba483          	lw	s1,0(s7)
    80003b64:	00a9559b          	srliw	a1,s2,0xa
    80003b68:	855e                	mv	a0,s7
    80003b6a:	fffff097          	auipc	ra,0xfffff
    80003b6e:	7ae080e7          	jalr	1966(ra) # 80003318 <bmap>
    80003b72:	0005059b          	sext.w	a1,a0
    80003b76:	8526                	mv	a0,s1
    80003b78:	fffff097          	auipc	ra,0xfffff
    80003b7c:	3ac080e7          	jalr	940(ra) # 80002f24 <bread>
    80003b80:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b82:	3ff97713          	andi	a4,s2,1023
    80003b86:	40ed07bb          	subw	a5,s10,a4
    80003b8a:	414b06bb          	subw	a3,s6,s4
    80003b8e:	89be                	mv	s3,a5
    80003b90:	2781                	sext.w	a5,a5
    80003b92:	0006861b          	sext.w	a2,a3
    80003b96:	f8f674e3          	bgeu	a2,a5,80003b1e <writei+0x4c>
    80003b9a:	89b6                	mv	s3,a3
    80003b9c:	b749                	j	80003b1e <writei+0x4c>
      brelse(bp);
    80003b9e:	8526                	mv	a0,s1
    80003ba0:	fffff097          	auipc	ra,0xfffff
    80003ba4:	4b4080e7          	jalr	1204(ra) # 80003054 <brelse>
      n = -1;
    80003ba8:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003baa:	04cba783          	lw	a5,76(s7)
    80003bae:	0127f463          	bgeu	a5,s2,80003bb6 <writei+0xe4>
      ip->size = off;
    80003bb2:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003bb6:	855e                	mv	a0,s7
    80003bb8:	00000097          	auipc	ra,0x0
    80003bbc:	aa4080e7          	jalr	-1372(ra) # 8000365c <iupdate>
  }

  return n;
    80003bc0:	000b051b          	sext.w	a0,s6
}
    80003bc4:	70a6                	ld	ra,104(sp)
    80003bc6:	7406                	ld	s0,96(sp)
    80003bc8:	64e6                	ld	s1,88(sp)
    80003bca:	6946                	ld	s2,80(sp)
    80003bcc:	69a6                	ld	s3,72(sp)
    80003bce:	6a06                	ld	s4,64(sp)
    80003bd0:	7ae2                	ld	s5,56(sp)
    80003bd2:	7b42                	ld	s6,48(sp)
    80003bd4:	7ba2                	ld	s7,40(sp)
    80003bd6:	7c02                	ld	s8,32(sp)
    80003bd8:	6ce2                	ld	s9,24(sp)
    80003bda:	6d42                	ld	s10,16(sp)
    80003bdc:	6da2                	ld	s11,8(sp)
    80003bde:	6165                	addi	sp,sp,112
    80003be0:	8082                	ret
    return -1;
    80003be2:	557d                	li	a0,-1
}
    80003be4:	8082                	ret
    return -1;
    80003be6:	557d                	li	a0,-1
    80003be8:	bff1                	j	80003bc4 <writei+0xf2>
    return -1;
    80003bea:	557d                	li	a0,-1
    80003bec:	bfe1                	j	80003bc4 <writei+0xf2>

0000000080003bee <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bee:	1141                	addi	sp,sp,-16
    80003bf0:	e406                	sd	ra,8(sp)
    80003bf2:	e022                	sd	s0,0(sp)
    80003bf4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bf6:	4639                	li	a2,14
    80003bf8:	ffffd097          	auipc	ra,0xffffd
    80003bfc:	21e080e7          	jalr	542(ra) # 80000e16 <strncmp>
}
    80003c00:	60a2                	ld	ra,8(sp)
    80003c02:	6402                	ld	s0,0(sp)
    80003c04:	0141                	addi	sp,sp,16
    80003c06:	8082                	ret

0000000080003c08 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c08:	7139                	addi	sp,sp,-64
    80003c0a:	fc06                	sd	ra,56(sp)
    80003c0c:	f822                	sd	s0,48(sp)
    80003c0e:	f426                	sd	s1,40(sp)
    80003c10:	f04a                	sd	s2,32(sp)
    80003c12:	ec4e                	sd	s3,24(sp)
    80003c14:	e852                	sd	s4,16(sp)
    80003c16:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c18:	04451703          	lh	a4,68(a0)
    80003c1c:	4785                	li	a5,1
    80003c1e:	00f71a63          	bne	a4,a5,80003c32 <dirlookup+0x2a>
    80003c22:	892a                	mv	s2,a0
    80003c24:	89ae                	mv	s3,a1
    80003c26:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c28:	457c                	lw	a5,76(a0)
    80003c2a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c2c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c2e:	e79d                	bnez	a5,80003c5c <dirlookup+0x54>
    80003c30:	a8a5                	j	80003ca8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c32:	00005517          	auipc	a0,0x5
    80003c36:	99650513          	addi	a0,a0,-1642 # 800085c8 <syscalls+0x1a0>
    80003c3a:	ffffd097          	auipc	ra,0xffffd
    80003c3e:	90e080e7          	jalr	-1778(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c42:	00005517          	auipc	a0,0x5
    80003c46:	99e50513          	addi	a0,a0,-1634 # 800085e0 <syscalls+0x1b8>
    80003c4a:	ffffd097          	auipc	ra,0xffffd
    80003c4e:	8fe080e7          	jalr	-1794(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c52:	24c1                	addiw	s1,s1,16
    80003c54:	04c92783          	lw	a5,76(s2)
    80003c58:	04f4f763          	bgeu	s1,a5,80003ca6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c5c:	4741                	li	a4,16
    80003c5e:	86a6                	mv	a3,s1
    80003c60:	fc040613          	addi	a2,s0,-64
    80003c64:	4581                	li	a1,0
    80003c66:	854a                	mv	a0,s2
    80003c68:	00000097          	auipc	ra,0x0
    80003c6c:	d72080e7          	jalr	-654(ra) # 800039da <readi>
    80003c70:	47c1                	li	a5,16
    80003c72:	fcf518e3          	bne	a0,a5,80003c42 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c76:	fc045783          	lhu	a5,-64(s0)
    80003c7a:	dfe1                	beqz	a5,80003c52 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c7c:	fc240593          	addi	a1,s0,-62
    80003c80:	854e                	mv	a0,s3
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	f6c080e7          	jalr	-148(ra) # 80003bee <namecmp>
    80003c8a:	f561                	bnez	a0,80003c52 <dirlookup+0x4a>
      if(poff)
    80003c8c:	000a0463          	beqz	s4,80003c94 <dirlookup+0x8c>
        *poff = off;
    80003c90:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c94:	fc045583          	lhu	a1,-64(s0)
    80003c98:	00092503          	lw	a0,0(s2)
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	756080e7          	jalr	1878(ra) # 800033f2 <iget>
    80003ca4:	a011                	j	80003ca8 <dirlookup+0xa0>
  return 0;
    80003ca6:	4501                	li	a0,0
}
    80003ca8:	70e2                	ld	ra,56(sp)
    80003caa:	7442                	ld	s0,48(sp)
    80003cac:	74a2                	ld	s1,40(sp)
    80003cae:	7902                	ld	s2,32(sp)
    80003cb0:	69e2                	ld	s3,24(sp)
    80003cb2:	6a42                	ld	s4,16(sp)
    80003cb4:	6121                	addi	sp,sp,64
    80003cb6:	8082                	ret

0000000080003cb8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cb8:	711d                	addi	sp,sp,-96
    80003cba:	ec86                	sd	ra,88(sp)
    80003cbc:	e8a2                	sd	s0,80(sp)
    80003cbe:	e4a6                	sd	s1,72(sp)
    80003cc0:	e0ca                	sd	s2,64(sp)
    80003cc2:	fc4e                	sd	s3,56(sp)
    80003cc4:	f852                	sd	s4,48(sp)
    80003cc6:	f456                	sd	s5,40(sp)
    80003cc8:	f05a                	sd	s6,32(sp)
    80003cca:	ec5e                	sd	s7,24(sp)
    80003ccc:	e862                	sd	s8,16(sp)
    80003cce:	e466                	sd	s9,8(sp)
    80003cd0:	1080                	addi	s0,sp,96
    80003cd2:	84aa                	mv	s1,a0
    80003cd4:	8b2e                	mv	s6,a1
    80003cd6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cd8:	00054703          	lbu	a4,0(a0)
    80003cdc:	02f00793          	li	a5,47
    80003ce0:	02f70363          	beq	a4,a5,80003d06 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ce4:	ffffe097          	auipc	ra,0xffffe
    80003ce8:	df4080e7          	jalr	-524(ra) # 80001ad8 <myproc>
    80003cec:	15053503          	ld	a0,336(a0)
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	9f8080e7          	jalr	-1544(ra) # 800036e8 <idup>
    80003cf8:	89aa                	mv	s3,a0
  while(*path == '/')
    80003cfa:	02f00913          	li	s2,47
  len = path - s;
    80003cfe:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d00:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d02:	4c05                	li	s8,1
    80003d04:	a865                	j	80003dbc <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d06:	4585                	li	a1,1
    80003d08:	4505                	li	a0,1
    80003d0a:	fffff097          	auipc	ra,0xfffff
    80003d0e:	6e8080e7          	jalr	1768(ra) # 800033f2 <iget>
    80003d12:	89aa                	mv	s3,a0
    80003d14:	b7dd                	j	80003cfa <namex+0x42>
      iunlockput(ip);
    80003d16:	854e                	mv	a0,s3
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	c70080e7          	jalr	-912(ra) # 80003988 <iunlockput>
      return 0;
    80003d20:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d22:	854e                	mv	a0,s3
    80003d24:	60e6                	ld	ra,88(sp)
    80003d26:	6446                	ld	s0,80(sp)
    80003d28:	64a6                	ld	s1,72(sp)
    80003d2a:	6906                	ld	s2,64(sp)
    80003d2c:	79e2                	ld	s3,56(sp)
    80003d2e:	7a42                	ld	s4,48(sp)
    80003d30:	7aa2                	ld	s5,40(sp)
    80003d32:	7b02                	ld	s6,32(sp)
    80003d34:	6be2                	ld	s7,24(sp)
    80003d36:	6c42                	ld	s8,16(sp)
    80003d38:	6ca2                	ld	s9,8(sp)
    80003d3a:	6125                	addi	sp,sp,96
    80003d3c:	8082                	ret
      iunlock(ip);
    80003d3e:	854e                	mv	a0,s3
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	aa8080e7          	jalr	-1368(ra) # 800037e8 <iunlock>
      return ip;
    80003d48:	bfe9                	j	80003d22 <namex+0x6a>
      iunlockput(ip);
    80003d4a:	854e                	mv	a0,s3
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	c3c080e7          	jalr	-964(ra) # 80003988 <iunlockput>
      return 0;
    80003d54:	89d2                	mv	s3,s4
    80003d56:	b7f1                	j	80003d22 <namex+0x6a>
  len = path - s;
    80003d58:	40b48633          	sub	a2,s1,a1
    80003d5c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d60:	094cd463          	bge	s9,s4,80003de8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d64:	4639                	li	a2,14
    80003d66:	8556                	mv	a0,s5
    80003d68:	ffffd097          	auipc	ra,0xffffd
    80003d6c:	032080e7          	jalr	50(ra) # 80000d9a <memmove>
  while(*path == '/')
    80003d70:	0004c783          	lbu	a5,0(s1)
    80003d74:	01279763          	bne	a5,s2,80003d82 <namex+0xca>
    path++;
    80003d78:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d7a:	0004c783          	lbu	a5,0(s1)
    80003d7e:	ff278de3          	beq	a5,s2,80003d78 <namex+0xc0>
    ilock(ip);
    80003d82:	854e                	mv	a0,s3
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	9a2080e7          	jalr	-1630(ra) # 80003726 <ilock>
    if(ip->type != T_DIR){
    80003d8c:	04499783          	lh	a5,68(s3)
    80003d90:	f98793e3          	bne	a5,s8,80003d16 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d94:	000b0563          	beqz	s6,80003d9e <namex+0xe6>
    80003d98:	0004c783          	lbu	a5,0(s1)
    80003d9c:	d3cd                	beqz	a5,80003d3e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d9e:	865e                	mv	a2,s7
    80003da0:	85d6                	mv	a1,s5
    80003da2:	854e                	mv	a0,s3
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	e64080e7          	jalr	-412(ra) # 80003c08 <dirlookup>
    80003dac:	8a2a                	mv	s4,a0
    80003dae:	dd51                	beqz	a0,80003d4a <namex+0x92>
    iunlockput(ip);
    80003db0:	854e                	mv	a0,s3
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	bd6080e7          	jalr	-1066(ra) # 80003988 <iunlockput>
    ip = next;
    80003dba:	89d2                	mv	s3,s4
  while(*path == '/')
    80003dbc:	0004c783          	lbu	a5,0(s1)
    80003dc0:	05279763          	bne	a5,s2,80003e0e <namex+0x156>
    path++;
    80003dc4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dc6:	0004c783          	lbu	a5,0(s1)
    80003dca:	ff278de3          	beq	a5,s2,80003dc4 <namex+0x10c>
  if(*path == 0)
    80003dce:	c79d                	beqz	a5,80003dfc <namex+0x144>
    path++;
    80003dd0:	85a6                	mv	a1,s1
  len = path - s;
    80003dd2:	8a5e                	mv	s4,s7
    80003dd4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dd6:	01278963          	beq	a5,s2,80003de8 <namex+0x130>
    80003dda:	dfbd                	beqz	a5,80003d58 <namex+0xa0>
    path++;
    80003ddc:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003dde:	0004c783          	lbu	a5,0(s1)
    80003de2:	ff279ce3          	bne	a5,s2,80003dda <namex+0x122>
    80003de6:	bf8d                	j	80003d58 <namex+0xa0>
    memmove(name, s, len);
    80003de8:	2601                	sext.w	a2,a2
    80003dea:	8556                	mv	a0,s5
    80003dec:	ffffd097          	auipc	ra,0xffffd
    80003df0:	fae080e7          	jalr	-82(ra) # 80000d9a <memmove>
    name[len] = 0;
    80003df4:	9a56                	add	s4,s4,s5
    80003df6:	000a0023          	sb	zero,0(s4)
    80003dfa:	bf9d                	j	80003d70 <namex+0xb8>
  if(nameiparent){
    80003dfc:	f20b03e3          	beqz	s6,80003d22 <namex+0x6a>
    iput(ip);
    80003e00:	854e                	mv	a0,s3
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	ade080e7          	jalr	-1314(ra) # 800038e0 <iput>
    return 0;
    80003e0a:	4981                	li	s3,0
    80003e0c:	bf19                	j	80003d22 <namex+0x6a>
  if(*path == 0)
    80003e0e:	d7fd                	beqz	a5,80003dfc <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e10:	0004c783          	lbu	a5,0(s1)
    80003e14:	85a6                	mv	a1,s1
    80003e16:	b7d1                	j	80003dda <namex+0x122>

0000000080003e18 <dirlink>:
{
    80003e18:	7139                	addi	sp,sp,-64
    80003e1a:	fc06                	sd	ra,56(sp)
    80003e1c:	f822                	sd	s0,48(sp)
    80003e1e:	f426                	sd	s1,40(sp)
    80003e20:	f04a                	sd	s2,32(sp)
    80003e22:	ec4e                	sd	s3,24(sp)
    80003e24:	e852                	sd	s4,16(sp)
    80003e26:	0080                	addi	s0,sp,64
    80003e28:	892a                	mv	s2,a0
    80003e2a:	8a2e                	mv	s4,a1
    80003e2c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e2e:	4601                	li	a2,0
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	dd8080e7          	jalr	-552(ra) # 80003c08 <dirlookup>
    80003e38:	e93d                	bnez	a0,80003eae <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e3a:	04c92483          	lw	s1,76(s2)
    80003e3e:	c49d                	beqz	s1,80003e6c <dirlink+0x54>
    80003e40:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e42:	4741                	li	a4,16
    80003e44:	86a6                	mv	a3,s1
    80003e46:	fc040613          	addi	a2,s0,-64
    80003e4a:	4581                	li	a1,0
    80003e4c:	854a                	mv	a0,s2
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	b8c080e7          	jalr	-1140(ra) # 800039da <readi>
    80003e56:	47c1                	li	a5,16
    80003e58:	06f51163          	bne	a0,a5,80003eba <dirlink+0xa2>
    if(de.inum == 0)
    80003e5c:	fc045783          	lhu	a5,-64(s0)
    80003e60:	c791                	beqz	a5,80003e6c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e62:	24c1                	addiw	s1,s1,16
    80003e64:	04c92783          	lw	a5,76(s2)
    80003e68:	fcf4ede3          	bltu	s1,a5,80003e42 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e6c:	4639                	li	a2,14
    80003e6e:	85d2                	mv	a1,s4
    80003e70:	fc240513          	addi	a0,s0,-62
    80003e74:	ffffd097          	auipc	ra,0xffffd
    80003e78:	fde080e7          	jalr	-34(ra) # 80000e52 <strncpy>
  de.inum = inum;
    80003e7c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e80:	4741                	li	a4,16
    80003e82:	86a6                	mv	a3,s1
    80003e84:	fc040613          	addi	a2,s0,-64
    80003e88:	4581                	li	a1,0
    80003e8a:	854a                	mv	a0,s2
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	c46080e7          	jalr	-954(ra) # 80003ad2 <writei>
    80003e94:	872a                	mv	a4,a0
    80003e96:	47c1                	li	a5,16
  return 0;
    80003e98:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e9a:	02f71863          	bne	a4,a5,80003eca <dirlink+0xb2>
}
    80003e9e:	70e2                	ld	ra,56(sp)
    80003ea0:	7442                	ld	s0,48(sp)
    80003ea2:	74a2                	ld	s1,40(sp)
    80003ea4:	7902                	ld	s2,32(sp)
    80003ea6:	69e2                	ld	s3,24(sp)
    80003ea8:	6a42                	ld	s4,16(sp)
    80003eaa:	6121                	addi	sp,sp,64
    80003eac:	8082                	ret
    iput(ip);
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	a32080e7          	jalr	-1486(ra) # 800038e0 <iput>
    return -1;
    80003eb6:	557d                	li	a0,-1
    80003eb8:	b7dd                	j	80003e9e <dirlink+0x86>
      panic("dirlink read");
    80003eba:	00004517          	auipc	a0,0x4
    80003ebe:	73650513          	addi	a0,a0,1846 # 800085f0 <syscalls+0x1c8>
    80003ec2:	ffffc097          	auipc	ra,0xffffc
    80003ec6:	686080e7          	jalr	1670(ra) # 80000548 <panic>
    panic("dirlink");
    80003eca:	00005517          	auipc	a0,0x5
    80003ece:	84650513          	addi	a0,a0,-1978 # 80008710 <syscalls+0x2e8>
    80003ed2:	ffffc097          	auipc	ra,0xffffc
    80003ed6:	676080e7          	jalr	1654(ra) # 80000548 <panic>

0000000080003eda <namei>:

struct inode*
namei(char *path)
{
    80003eda:	1101                	addi	sp,sp,-32
    80003edc:	ec06                	sd	ra,24(sp)
    80003ede:	e822                	sd	s0,16(sp)
    80003ee0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ee2:	fe040613          	addi	a2,s0,-32
    80003ee6:	4581                	li	a1,0
    80003ee8:	00000097          	auipc	ra,0x0
    80003eec:	dd0080e7          	jalr	-560(ra) # 80003cb8 <namex>
}
    80003ef0:	60e2                	ld	ra,24(sp)
    80003ef2:	6442                	ld	s0,16(sp)
    80003ef4:	6105                	addi	sp,sp,32
    80003ef6:	8082                	ret

0000000080003ef8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ef8:	1141                	addi	sp,sp,-16
    80003efa:	e406                	sd	ra,8(sp)
    80003efc:	e022                	sd	s0,0(sp)
    80003efe:	0800                	addi	s0,sp,16
    80003f00:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f02:	4585                	li	a1,1
    80003f04:	00000097          	auipc	ra,0x0
    80003f08:	db4080e7          	jalr	-588(ra) # 80003cb8 <namex>
}
    80003f0c:	60a2                	ld	ra,8(sp)
    80003f0e:	6402                	ld	s0,0(sp)
    80003f10:	0141                	addi	sp,sp,16
    80003f12:	8082                	ret

0000000080003f14 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f14:	1101                	addi	sp,sp,-32
    80003f16:	ec06                	sd	ra,24(sp)
    80003f18:	e822                	sd	s0,16(sp)
    80003f1a:	e426                	sd	s1,8(sp)
    80003f1c:	e04a                	sd	s2,0(sp)
    80003f1e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f20:	0001e917          	auipc	s2,0x1e
    80003f24:	9e890913          	addi	s2,s2,-1560 # 80021908 <log>
    80003f28:	01892583          	lw	a1,24(s2)
    80003f2c:	02892503          	lw	a0,40(s2)
    80003f30:	fffff097          	auipc	ra,0xfffff
    80003f34:	ff4080e7          	jalr	-12(ra) # 80002f24 <bread>
    80003f38:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f3a:	02c92683          	lw	a3,44(s2)
    80003f3e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f40:	02d05763          	blez	a3,80003f6e <write_head+0x5a>
    80003f44:	0001e797          	auipc	a5,0x1e
    80003f48:	9f478793          	addi	a5,a5,-1548 # 80021938 <log+0x30>
    80003f4c:	05c50713          	addi	a4,a0,92
    80003f50:	36fd                	addiw	a3,a3,-1
    80003f52:	1682                	slli	a3,a3,0x20
    80003f54:	9281                	srli	a3,a3,0x20
    80003f56:	068a                	slli	a3,a3,0x2
    80003f58:	0001e617          	auipc	a2,0x1e
    80003f5c:	9e460613          	addi	a2,a2,-1564 # 8002193c <log+0x34>
    80003f60:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f62:	4390                	lw	a2,0(a5)
    80003f64:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f66:	0791                	addi	a5,a5,4
    80003f68:	0711                	addi	a4,a4,4
    80003f6a:	fed79ce3          	bne	a5,a3,80003f62 <write_head+0x4e>
  }
  bwrite(buf);
    80003f6e:	8526                	mv	a0,s1
    80003f70:	fffff097          	auipc	ra,0xfffff
    80003f74:	0a6080e7          	jalr	166(ra) # 80003016 <bwrite>
  brelse(buf);
    80003f78:	8526                	mv	a0,s1
    80003f7a:	fffff097          	auipc	ra,0xfffff
    80003f7e:	0da080e7          	jalr	218(ra) # 80003054 <brelse>
}
    80003f82:	60e2                	ld	ra,24(sp)
    80003f84:	6442                	ld	s0,16(sp)
    80003f86:	64a2                	ld	s1,8(sp)
    80003f88:	6902                	ld	s2,0(sp)
    80003f8a:	6105                	addi	sp,sp,32
    80003f8c:	8082                	ret

0000000080003f8e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f8e:	0001e797          	auipc	a5,0x1e
    80003f92:	9a67a783          	lw	a5,-1626(a5) # 80021934 <log+0x2c>
    80003f96:	0af05663          	blez	a5,80004042 <install_trans+0xb4>
{
    80003f9a:	7139                	addi	sp,sp,-64
    80003f9c:	fc06                	sd	ra,56(sp)
    80003f9e:	f822                	sd	s0,48(sp)
    80003fa0:	f426                	sd	s1,40(sp)
    80003fa2:	f04a                	sd	s2,32(sp)
    80003fa4:	ec4e                	sd	s3,24(sp)
    80003fa6:	e852                	sd	s4,16(sp)
    80003fa8:	e456                	sd	s5,8(sp)
    80003faa:	0080                	addi	s0,sp,64
    80003fac:	0001ea97          	auipc	s5,0x1e
    80003fb0:	98ca8a93          	addi	s5,s5,-1652 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fb6:	0001e997          	auipc	s3,0x1e
    80003fba:	95298993          	addi	s3,s3,-1710 # 80021908 <log>
    80003fbe:	0189a583          	lw	a1,24(s3)
    80003fc2:	014585bb          	addw	a1,a1,s4
    80003fc6:	2585                	addiw	a1,a1,1
    80003fc8:	0289a503          	lw	a0,40(s3)
    80003fcc:	fffff097          	auipc	ra,0xfffff
    80003fd0:	f58080e7          	jalr	-168(ra) # 80002f24 <bread>
    80003fd4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fd6:	000aa583          	lw	a1,0(s5)
    80003fda:	0289a503          	lw	a0,40(s3)
    80003fde:	fffff097          	auipc	ra,0xfffff
    80003fe2:	f46080e7          	jalr	-186(ra) # 80002f24 <bread>
    80003fe6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fe8:	40000613          	li	a2,1024
    80003fec:	05890593          	addi	a1,s2,88
    80003ff0:	05850513          	addi	a0,a0,88
    80003ff4:	ffffd097          	auipc	ra,0xffffd
    80003ff8:	da6080e7          	jalr	-602(ra) # 80000d9a <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ffc:	8526                	mv	a0,s1
    80003ffe:	fffff097          	auipc	ra,0xfffff
    80004002:	018080e7          	jalr	24(ra) # 80003016 <bwrite>
    bunpin(dbuf);
    80004006:	8526                	mv	a0,s1
    80004008:	fffff097          	auipc	ra,0xfffff
    8000400c:	126080e7          	jalr	294(ra) # 8000312e <bunpin>
    brelse(lbuf);
    80004010:	854a                	mv	a0,s2
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	042080e7          	jalr	66(ra) # 80003054 <brelse>
    brelse(dbuf);
    8000401a:	8526                	mv	a0,s1
    8000401c:	fffff097          	auipc	ra,0xfffff
    80004020:	038080e7          	jalr	56(ra) # 80003054 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004024:	2a05                	addiw	s4,s4,1
    80004026:	0a91                	addi	s5,s5,4
    80004028:	02c9a783          	lw	a5,44(s3)
    8000402c:	f8fa49e3          	blt	s4,a5,80003fbe <install_trans+0x30>
}
    80004030:	70e2                	ld	ra,56(sp)
    80004032:	7442                	ld	s0,48(sp)
    80004034:	74a2                	ld	s1,40(sp)
    80004036:	7902                	ld	s2,32(sp)
    80004038:	69e2                	ld	s3,24(sp)
    8000403a:	6a42                	ld	s4,16(sp)
    8000403c:	6aa2                	ld	s5,8(sp)
    8000403e:	6121                	addi	sp,sp,64
    80004040:	8082                	ret
    80004042:	8082                	ret

0000000080004044 <initlog>:
{
    80004044:	7179                	addi	sp,sp,-48
    80004046:	f406                	sd	ra,40(sp)
    80004048:	f022                	sd	s0,32(sp)
    8000404a:	ec26                	sd	s1,24(sp)
    8000404c:	e84a                	sd	s2,16(sp)
    8000404e:	e44e                	sd	s3,8(sp)
    80004050:	1800                	addi	s0,sp,48
    80004052:	892a                	mv	s2,a0
    80004054:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004056:	0001e497          	auipc	s1,0x1e
    8000405a:	8b248493          	addi	s1,s1,-1870 # 80021908 <log>
    8000405e:	00004597          	auipc	a1,0x4
    80004062:	5a258593          	addi	a1,a1,1442 # 80008600 <syscalls+0x1d8>
    80004066:	8526                	mv	a0,s1
    80004068:	ffffd097          	auipc	ra,0xffffd
    8000406c:	b46080e7          	jalr	-1210(ra) # 80000bae <initlock>
  log.start = sb->logstart;
    80004070:	0149a583          	lw	a1,20(s3)
    80004074:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004076:	0109a783          	lw	a5,16(s3)
    8000407a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000407c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004080:	854a                	mv	a0,s2
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	ea2080e7          	jalr	-350(ra) # 80002f24 <bread>
  log.lh.n = lh->n;
    8000408a:	4d3c                	lw	a5,88(a0)
    8000408c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000408e:	02f05563          	blez	a5,800040b8 <initlog+0x74>
    80004092:	05c50713          	addi	a4,a0,92
    80004096:	0001e697          	auipc	a3,0x1e
    8000409a:	8a268693          	addi	a3,a3,-1886 # 80021938 <log+0x30>
    8000409e:	37fd                	addiw	a5,a5,-1
    800040a0:	1782                	slli	a5,a5,0x20
    800040a2:	9381                	srli	a5,a5,0x20
    800040a4:	078a                	slli	a5,a5,0x2
    800040a6:	06050613          	addi	a2,a0,96
    800040aa:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040ac:	4310                	lw	a2,0(a4)
    800040ae:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040b0:	0711                	addi	a4,a4,4
    800040b2:	0691                	addi	a3,a3,4
    800040b4:	fef71ce3          	bne	a4,a5,800040ac <initlog+0x68>
  brelse(buf);
    800040b8:	fffff097          	auipc	ra,0xfffff
    800040bc:	f9c080e7          	jalr	-100(ra) # 80003054 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800040c0:	00000097          	auipc	ra,0x0
    800040c4:	ece080e7          	jalr	-306(ra) # 80003f8e <install_trans>
  log.lh.n = 0;
    800040c8:	0001e797          	auipc	a5,0x1e
    800040cc:	8607a623          	sw	zero,-1940(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	e44080e7          	jalr	-444(ra) # 80003f14 <write_head>
}
    800040d8:	70a2                	ld	ra,40(sp)
    800040da:	7402                	ld	s0,32(sp)
    800040dc:	64e2                	ld	s1,24(sp)
    800040de:	6942                	ld	s2,16(sp)
    800040e0:	69a2                	ld	s3,8(sp)
    800040e2:	6145                	addi	sp,sp,48
    800040e4:	8082                	ret

00000000800040e6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040e6:	1101                	addi	sp,sp,-32
    800040e8:	ec06                	sd	ra,24(sp)
    800040ea:	e822                	sd	s0,16(sp)
    800040ec:	e426                	sd	s1,8(sp)
    800040ee:	e04a                	sd	s2,0(sp)
    800040f0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040f2:	0001e517          	auipc	a0,0x1e
    800040f6:	81650513          	addi	a0,a0,-2026 # 80021908 <log>
    800040fa:	ffffd097          	auipc	ra,0xffffd
    800040fe:	b44080e7          	jalr	-1212(ra) # 80000c3e <acquire>
  while(1){
    if(log.committing){
    80004102:	0001e497          	auipc	s1,0x1e
    80004106:	80648493          	addi	s1,s1,-2042 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000410a:	4979                	li	s2,30
    8000410c:	a039                	j	8000411a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000410e:	85a6                	mv	a1,s1
    80004110:	8526                	mv	a0,s1
    80004112:	ffffe097          	auipc	ra,0xffffe
    80004116:	1d6080e7          	jalr	470(ra) # 800022e8 <sleep>
    if(log.committing){
    8000411a:	50dc                	lw	a5,36(s1)
    8000411c:	fbed                	bnez	a5,8000410e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000411e:	509c                	lw	a5,32(s1)
    80004120:	0017871b          	addiw	a4,a5,1
    80004124:	0007069b          	sext.w	a3,a4
    80004128:	0027179b          	slliw	a5,a4,0x2
    8000412c:	9fb9                	addw	a5,a5,a4
    8000412e:	0017979b          	slliw	a5,a5,0x1
    80004132:	54d8                	lw	a4,44(s1)
    80004134:	9fb9                	addw	a5,a5,a4
    80004136:	00f95963          	bge	s2,a5,80004148 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000413a:	85a6                	mv	a1,s1
    8000413c:	8526                	mv	a0,s1
    8000413e:	ffffe097          	auipc	ra,0xffffe
    80004142:	1aa080e7          	jalr	426(ra) # 800022e8 <sleep>
    80004146:	bfd1                	j	8000411a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004148:	0001d517          	auipc	a0,0x1d
    8000414c:	7c050513          	addi	a0,a0,1984 # 80021908 <log>
    80004150:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004152:	ffffd097          	auipc	ra,0xffffd
    80004156:	ba0080e7          	jalr	-1120(ra) # 80000cf2 <release>
      break;
    }
  }
}
    8000415a:	60e2                	ld	ra,24(sp)
    8000415c:	6442                	ld	s0,16(sp)
    8000415e:	64a2                	ld	s1,8(sp)
    80004160:	6902                	ld	s2,0(sp)
    80004162:	6105                	addi	sp,sp,32
    80004164:	8082                	ret

0000000080004166 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004166:	7139                	addi	sp,sp,-64
    80004168:	fc06                	sd	ra,56(sp)
    8000416a:	f822                	sd	s0,48(sp)
    8000416c:	f426                	sd	s1,40(sp)
    8000416e:	f04a                	sd	s2,32(sp)
    80004170:	ec4e                	sd	s3,24(sp)
    80004172:	e852                	sd	s4,16(sp)
    80004174:	e456                	sd	s5,8(sp)
    80004176:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004178:	0001d497          	auipc	s1,0x1d
    8000417c:	79048493          	addi	s1,s1,1936 # 80021908 <log>
    80004180:	8526                	mv	a0,s1
    80004182:	ffffd097          	auipc	ra,0xffffd
    80004186:	abc080e7          	jalr	-1348(ra) # 80000c3e <acquire>
  log.outstanding -= 1;
    8000418a:	509c                	lw	a5,32(s1)
    8000418c:	37fd                	addiw	a5,a5,-1
    8000418e:	0007891b          	sext.w	s2,a5
    80004192:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004194:	50dc                	lw	a5,36(s1)
    80004196:	efb9                	bnez	a5,800041f4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004198:	06091663          	bnez	s2,80004204 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000419c:	0001d497          	auipc	s1,0x1d
    800041a0:	76c48493          	addi	s1,s1,1900 # 80021908 <log>
    800041a4:	4785                	li	a5,1
    800041a6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041a8:	8526                	mv	a0,s1
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	b48080e7          	jalr	-1208(ra) # 80000cf2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041b2:	54dc                	lw	a5,44(s1)
    800041b4:	06f04763          	bgtz	a5,80004222 <end_op+0xbc>
    acquire(&log.lock);
    800041b8:	0001d497          	auipc	s1,0x1d
    800041bc:	75048493          	addi	s1,s1,1872 # 80021908 <log>
    800041c0:	8526                	mv	a0,s1
    800041c2:	ffffd097          	auipc	ra,0xffffd
    800041c6:	a7c080e7          	jalr	-1412(ra) # 80000c3e <acquire>
    log.committing = 0;
    800041ca:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041ce:	8526                	mv	a0,s1
    800041d0:	ffffe097          	auipc	ra,0xffffe
    800041d4:	29e080e7          	jalr	670(ra) # 8000246e <wakeup>
    release(&log.lock);
    800041d8:	8526                	mv	a0,s1
    800041da:	ffffd097          	auipc	ra,0xffffd
    800041de:	b18080e7          	jalr	-1256(ra) # 80000cf2 <release>
}
    800041e2:	70e2                	ld	ra,56(sp)
    800041e4:	7442                	ld	s0,48(sp)
    800041e6:	74a2                	ld	s1,40(sp)
    800041e8:	7902                	ld	s2,32(sp)
    800041ea:	69e2                	ld	s3,24(sp)
    800041ec:	6a42                	ld	s4,16(sp)
    800041ee:	6aa2                	ld	s5,8(sp)
    800041f0:	6121                	addi	sp,sp,64
    800041f2:	8082                	ret
    panic("log.committing");
    800041f4:	00004517          	auipc	a0,0x4
    800041f8:	41450513          	addi	a0,a0,1044 # 80008608 <syscalls+0x1e0>
    800041fc:	ffffc097          	auipc	ra,0xffffc
    80004200:	34c080e7          	jalr	844(ra) # 80000548 <panic>
    wakeup(&log);
    80004204:	0001d497          	auipc	s1,0x1d
    80004208:	70448493          	addi	s1,s1,1796 # 80021908 <log>
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffe097          	auipc	ra,0xffffe
    80004212:	260080e7          	jalr	608(ra) # 8000246e <wakeup>
  release(&log.lock);
    80004216:	8526                	mv	a0,s1
    80004218:	ffffd097          	auipc	ra,0xffffd
    8000421c:	ada080e7          	jalr	-1318(ra) # 80000cf2 <release>
  if(do_commit){
    80004220:	b7c9                	j	800041e2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004222:	0001da97          	auipc	s5,0x1d
    80004226:	716a8a93          	addi	s5,s5,1814 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000422a:	0001da17          	auipc	s4,0x1d
    8000422e:	6dea0a13          	addi	s4,s4,1758 # 80021908 <log>
    80004232:	018a2583          	lw	a1,24(s4)
    80004236:	012585bb          	addw	a1,a1,s2
    8000423a:	2585                	addiw	a1,a1,1
    8000423c:	028a2503          	lw	a0,40(s4)
    80004240:	fffff097          	auipc	ra,0xfffff
    80004244:	ce4080e7          	jalr	-796(ra) # 80002f24 <bread>
    80004248:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000424a:	000aa583          	lw	a1,0(s5)
    8000424e:	028a2503          	lw	a0,40(s4)
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	cd2080e7          	jalr	-814(ra) # 80002f24 <bread>
    8000425a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000425c:	40000613          	li	a2,1024
    80004260:	05850593          	addi	a1,a0,88
    80004264:	05848513          	addi	a0,s1,88
    80004268:	ffffd097          	auipc	ra,0xffffd
    8000426c:	b32080e7          	jalr	-1230(ra) # 80000d9a <memmove>
    bwrite(to);  // write the log
    80004270:	8526                	mv	a0,s1
    80004272:	fffff097          	auipc	ra,0xfffff
    80004276:	da4080e7          	jalr	-604(ra) # 80003016 <bwrite>
    brelse(from);
    8000427a:	854e                	mv	a0,s3
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	dd8080e7          	jalr	-552(ra) # 80003054 <brelse>
    brelse(to);
    80004284:	8526                	mv	a0,s1
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	dce080e7          	jalr	-562(ra) # 80003054 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000428e:	2905                	addiw	s2,s2,1
    80004290:	0a91                	addi	s5,s5,4
    80004292:	02ca2783          	lw	a5,44(s4)
    80004296:	f8f94ee3          	blt	s2,a5,80004232 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	c7a080e7          	jalr	-902(ra) # 80003f14 <write_head>
    install_trans(); // Now install writes to home locations
    800042a2:	00000097          	auipc	ra,0x0
    800042a6:	cec080e7          	jalr	-788(ra) # 80003f8e <install_trans>
    log.lh.n = 0;
    800042aa:	0001d797          	auipc	a5,0x1d
    800042ae:	6807a523          	sw	zero,1674(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042b2:	00000097          	auipc	ra,0x0
    800042b6:	c62080e7          	jalr	-926(ra) # 80003f14 <write_head>
    800042ba:	bdfd                	j	800041b8 <end_op+0x52>

00000000800042bc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042bc:	1101                	addi	sp,sp,-32
    800042be:	ec06                	sd	ra,24(sp)
    800042c0:	e822                	sd	s0,16(sp)
    800042c2:	e426                	sd	s1,8(sp)
    800042c4:	e04a                	sd	s2,0(sp)
    800042c6:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042c8:	0001d717          	auipc	a4,0x1d
    800042cc:	66c72703          	lw	a4,1644(a4) # 80021934 <log+0x2c>
    800042d0:	47f5                	li	a5,29
    800042d2:	08e7c063          	blt	a5,a4,80004352 <log_write+0x96>
    800042d6:	84aa                	mv	s1,a0
    800042d8:	0001d797          	auipc	a5,0x1d
    800042dc:	64c7a783          	lw	a5,1612(a5) # 80021924 <log+0x1c>
    800042e0:	37fd                	addiw	a5,a5,-1
    800042e2:	06f75863          	bge	a4,a5,80004352 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042e6:	0001d797          	auipc	a5,0x1d
    800042ea:	6427a783          	lw	a5,1602(a5) # 80021928 <log+0x20>
    800042ee:	06f05a63          	blez	a5,80004362 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800042f2:	0001d917          	auipc	s2,0x1d
    800042f6:	61690913          	addi	s2,s2,1558 # 80021908 <log>
    800042fa:	854a                	mv	a0,s2
    800042fc:	ffffd097          	auipc	ra,0xffffd
    80004300:	942080e7          	jalr	-1726(ra) # 80000c3e <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004304:	02c92603          	lw	a2,44(s2)
    80004308:	06c05563          	blez	a2,80004372 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000430c:	44cc                	lw	a1,12(s1)
    8000430e:	0001d717          	auipc	a4,0x1d
    80004312:	62a70713          	addi	a4,a4,1578 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004316:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004318:	4314                	lw	a3,0(a4)
    8000431a:	04b68d63          	beq	a3,a1,80004374 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000431e:	2785                	addiw	a5,a5,1
    80004320:	0711                	addi	a4,a4,4
    80004322:	fec79be3          	bne	a5,a2,80004318 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004326:	0621                	addi	a2,a2,8
    80004328:	060a                	slli	a2,a2,0x2
    8000432a:	0001d797          	auipc	a5,0x1d
    8000432e:	5de78793          	addi	a5,a5,1502 # 80021908 <log>
    80004332:	963e                	add	a2,a2,a5
    80004334:	44dc                	lw	a5,12(s1)
    80004336:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004338:	8526                	mv	a0,s1
    8000433a:	fffff097          	auipc	ra,0xfffff
    8000433e:	db8080e7          	jalr	-584(ra) # 800030f2 <bpin>
    log.lh.n++;
    80004342:	0001d717          	auipc	a4,0x1d
    80004346:	5c670713          	addi	a4,a4,1478 # 80021908 <log>
    8000434a:	575c                	lw	a5,44(a4)
    8000434c:	2785                	addiw	a5,a5,1
    8000434e:	d75c                	sw	a5,44(a4)
    80004350:	a83d                	j	8000438e <log_write+0xd2>
    panic("too big a transaction");
    80004352:	00004517          	auipc	a0,0x4
    80004356:	2c650513          	addi	a0,a0,710 # 80008618 <syscalls+0x1f0>
    8000435a:	ffffc097          	auipc	ra,0xffffc
    8000435e:	1ee080e7          	jalr	494(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004362:	00004517          	auipc	a0,0x4
    80004366:	2ce50513          	addi	a0,a0,718 # 80008630 <syscalls+0x208>
    8000436a:	ffffc097          	auipc	ra,0xffffc
    8000436e:	1de080e7          	jalr	478(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004372:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004374:	00878713          	addi	a4,a5,8
    80004378:	00271693          	slli	a3,a4,0x2
    8000437c:	0001d717          	auipc	a4,0x1d
    80004380:	58c70713          	addi	a4,a4,1420 # 80021908 <log>
    80004384:	9736                	add	a4,a4,a3
    80004386:	44d4                	lw	a3,12(s1)
    80004388:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000438a:	faf607e3          	beq	a2,a5,80004338 <log_write+0x7c>
  }
  release(&log.lock);
    8000438e:	0001d517          	auipc	a0,0x1d
    80004392:	57a50513          	addi	a0,a0,1402 # 80021908 <log>
    80004396:	ffffd097          	auipc	ra,0xffffd
    8000439a:	95c080e7          	jalr	-1700(ra) # 80000cf2 <release>
}
    8000439e:	60e2                	ld	ra,24(sp)
    800043a0:	6442                	ld	s0,16(sp)
    800043a2:	64a2                	ld	s1,8(sp)
    800043a4:	6902                	ld	s2,0(sp)
    800043a6:	6105                	addi	sp,sp,32
    800043a8:	8082                	ret

00000000800043aa <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043aa:	1101                	addi	sp,sp,-32
    800043ac:	ec06                	sd	ra,24(sp)
    800043ae:	e822                	sd	s0,16(sp)
    800043b0:	e426                	sd	s1,8(sp)
    800043b2:	e04a                	sd	s2,0(sp)
    800043b4:	1000                	addi	s0,sp,32
    800043b6:	84aa                	mv	s1,a0
    800043b8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043ba:	00004597          	auipc	a1,0x4
    800043be:	29658593          	addi	a1,a1,662 # 80008650 <syscalls+0x228>
    800043c2:	0521                	addi	a0,a0,8
    800043c4:	ffffc097          	auipc	ra,0xffffc
    800043c8:	7ea080e7          	jalr	2026(ra) # 80000bae <initlock>
  lk->name = name;
    800043cc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043d0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043d4:	0204a423          	sw	zero,40(s1)
}
    800043d8:	60e2                	ld	ra,24(sp)
    800043da:	6442                	ld	s0,16(sp)
    800043dc:	64a2                	ld	s1,8(sp)
    800043de:	6902                	ld	s2,0(sp)
    800043e0:	6105                	addi	sp,sp,32
    800043e2:	8082                	ret

00000000800043e4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043e4:	1101                	addi	sp,sp,-32
    800043e6:	ec06                	sd	ra,24(sp)
    800043e8:	e822                	sd	s0,16(sp)
    800043ea:	e426                	sd	s1,8(sp)
    800043ec:	e04a                	sd	s2,0(sp)
    800043ee:	1000                	addi	s0,sp,32
    800043f0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043f2:	00850913          	addi	s2,a0,8
    800043f6:	854a                	mv	a0,s2
    800043f8:	ffffd097          	auipc	ra,0xffffd
    800043fc:	846080e7          	jalr	-1978(ra) # 80000c3e <acquire>
  while (lk->locked) {
    80004400:	409c                	lw	a5,0(s1)
    80004402:	cb89                	beqz	a5,80004414 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004404:	85ca                	mv	a1,s2
    80004406:	8526                	mv	a0,s1
    80004408:	ffffe097          	auipc	ra,0xffffe
    8000440c:	ee0080e7          	jalr	-288(ra) # 800022e8 <sleep>
  while (lk->locked) {
    80004410:	409c                	lw	a5,0(s1)
    80004412:	fbed                	bnez	a5,80004404 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004414:	4785                	li	a5,1
    80004416:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004418:	ffffd097          	auipc	ra,0xffffd
    8000441c:	6c0080e7          	jalr	1728(ra) # 80001ad8 <myproc>
    80004420:	5d1c                	lw	a5,56(a0)
    80004422:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004424:	854a                	mv	a0,s2
    80004426:	ffffd097          	auipc	ra,0xffffd
    8000442a:	8cc080e7          	jalr	-1844(ra) # 80000cf2 <release>
}
    8000442e:	60e2                	ld	ra,24(sp)
    80004430:	6442                	ld	s0,16(sp)
    80004432:	64a2                	ld	s1,8(sp)
    80004434:	6902                	ld	s2,0(sp)
    80004436:	6105                	addi	sp,sp,32
    80004438:	8082                	ret

000000008000443a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000443a:	1101                	addi	sp,sp,-32
    8000443c:	ec06                	sd	ra,24(sp)
    8000443e:	e822                	sd	s0,16(sp)
    80004440:	e426                	sd	s1,8(sp)
    80004442:	e04a                	sd	s2,0(sp)
    80004444:	1000                	addi	s0,sp,32
    80004446:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004448:	00850913          	addi	s2,a0,8
    8000444c:	854a                	mv	a0,s2
    8000444e:	ffffc097          	auipc	ra,0xffffc
    80004452:	7f0080e7          	jalr	2032(ra) # 80000c3e <acquire>
  lk->locked = 0;
    80004456:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000445a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000445e:	8526                	mv	a0,s1
    80004460:	ffffe097          	auipc	ra,0xffffe
    80004464:	00e080e7          	jalr	14(ra) # 8000246e <wakeup>
  release(&lk->lk);
    80004468:	854a                	mv	a0,s2
    8000446a:	ffffd097          	auipc	ra,0xffffd
    8000446e:	888080e7          	jalr	-1912(ra) # 80000cf2 <release>
}
    80004472:	60e2                	ld	ra,24(sp)
    80004474:	6442                	ld	s0,16(sp)
    80004476:	64a2                	ld	s1,8(sp)
    80004478:	6902                	ld	s2,0(sp)
    8000447a:	6105                	addi	sp,sp,32
    8000447c:	8082                	ret

000000008000447e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000447e:	7179                	addi	sp,sp,-48
    80004480:	f406                	sd	ra,40(sp)
    80004482:	f022                	sd	s0,32(sp)
    80004484:	ec26                	sd	s1,24(sp)
    80004486:	e84a                	sd	s2,16(sp)
    80004488:	e44e                	sd	s3,8(sp)
    8000448a:	1800                	addi	s0,sp,48
    8000448c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000448e:	00850913          	addi	s2,a0,8
    80004492:	854a                	mv	a0,s2
    80004494:	ffffc097          	auipc	ra,0xffffc
    80004498:	7aa080e7          	jalr	1962(ra) # 80000c3e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000449c:	409c                	lw	a5,0(s1)
    8000449e:	ef99                	bnez	a5,800044bc <holdingsleep+0x3e>
    800044a0:	4481                	li	s1,0
  release(&lk->lk);
    800044a2:	854a                	mv	a0,s2
    800044a4:	ffffd097          	auipc	ra,0xffffd
    800044a8:	84e080e7          	jalr	-1970(ra) # 80000cf2 <release>
  return r;
}
    800044ac:	8526                	mv	a0,s1
    800044ae:	70a2                	ld	ra,40(sp)
    800044b0:	7402                	ld	s0,32(sp)
    800044b2:	64e2                	ld	s1,24(sp)
    800044b4:	6942                	ld	s2,16(sp)
    800044b6:	69a2                	ld	s3,8(sp)
    800044b8:	6145                	addi	sp,sp,48
    800044ba:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044bc:	0284a983          	lw	s3,40(s1)
    800044c0:	ffffd097          	auipc	ra,0xffffd
    800044c4:	618080e7          	jalr	1560(ra) # 80001ad8 <myproc>
    800044c8:	5d04                	lw	s1,56(a0)
    800044ca:	413484b3          	sub	s1,s1,s3
    800044ce:	0014b493          	seqz	s1,s1
    800044d2:	bfc1                	j	800044a2 <holdingsleep+0x24>

00000000800044d4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044d4:	1141                	addi	sp,sp,-16
    800044d6:	e406                	sd	ra,8(sp)
    800044d8:	e022                	sd	s0,0(sp)
    800044da:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044dc:	00004597          	auipc	a1,0x4
    800044e0:	18458593          	addi	a1,a1,388 # 80008660 <syscalls+0x238>
    800044e4:	0001d517          	auipc	a0,0x1d
    800044e8:	56c50513          	addi	a0,a0,1388 # 80021a50 <ftable>
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	6c2080e7          	jalr	1730(ra) # 80000bae <initlock>
}
    800044f4:	60a2                	ld	ra,8(sp)
    800044f6:	6402                	ld	s0,0(sp)
    800044f8:	0141                	addi	sp,sp,16
    800044fa:	8082                	ret

00000000800044fc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044fc:	1101                	addi	sp,sp,-32
    800044fe:	ec06                	sd	ra,24(sp)
    80004500:	e822                	sd	s0,16(sp)
    80004502:	e426                	sd	s1,8(sp)
    80004504:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004506:	0001d517          	auipc	a0,0x1d
    8000450a:	54a50513          	addi	a0,a0,1354 # 80021a50 <ftable>
    8000450e:	ffffc097          	auipc	ra,0xffffc
    80004512:	730080e7          	jalr	1840(ra) # 80000c3e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004516:	0001d497          	auipc	s1,0x1d
    8000451a:	55248493          	addi	s1,s1,1362 # 80021a68 <ftable+0x18>
    8000451e:	0001e717          	auipc	a4,0x1e
    80004522:	4ea70713          	addi	a4,a4,1258 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    80004526:	40dc                	lw	a5,4(s1)
    80004528:	cf99                	beqz	a5,80004546 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000452a:	02848493          	addi	s1,s1,40
    8000452e:	fee49ce3          	bne	s1,a4,80004526 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004532:	0001d517          	auipc	a0,0x1d
    80004536:	51e50513          	addi	a0,a0,1310 # 80021a50 <ftable>
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	7b8080e7          	jalr	1976(ra) # 80000cf2 <release>
  return 0;
    80004542:	4481                	li	s1,0
    80004544:	a819                	j	8000455a <filealloc+0x5e>
      f->ref = 1;
    80004546:	4785                	li	a5,1
    80004548:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000454a:	0001d517          	auipc	a0,0x1d
    8000454e:	50650513          	addi	a0,a0,1286 # 80021a50 <ftable>
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	7a0080e7          	jalr	1952(ra) # 80000cf2 <release>
}
    8000455a:	8526                	mv	a0,s1
    8000455c:	60e2                	ld	ra,24(sp)
    8000455e:	6442                	ld	s0,16(sp)
    80004560:	64a2                	ld	s1,8(sp)
    80004562:	6105                	addi	sp,sp,32
    80004564:	8082                	ret

0000000080004566 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004566:	1101                	addi	sp,sp,-32
    80004568:	ec06                	sd	ra,24(sp)
    8000456a:	e822                	sd	s0,16(sp)
    8000456c:	e426                	sd	s1,8(sp)
    8000456e:	1000                	addi	s0,sp,32
    80004570:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004572:	0001d517          	auipc	a0,0x1d
    80004576:	4de50513          	addi	a0,a0,1246 # 80021a50 <ftable>
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	6c4080e7          	jalr	1732(ra) # 80000c3e <acquire>
  if(f->ref < 1)
    80004582:	40dc                	lw	a5,4(s1)
    80004584:	02f05263          	blez	a5,800045a8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004588:	2785                	addiw	a5,a5,1
    8000458a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000458c:	0001d517          	auipc	a0,0x1d
    80004590:	4c450513          	addi	a0,a0,1220 # 80021a50 <ftable>
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	75e080e7          	jalr	1886(ra) # 80000cf2 <release>
  return f;
}
    8000459c:	8526                	mv	a0,s1
    8000459e:	60e2                	ld	ra,24(sp)
    800045a0:	6442                	ld	s0,16(sp)
    800045a2:	64a2                	ld	s1,8(sp)
    800045a4:	6105                	addi	sp,sp,32
    800045a6:	8082                	ret
    panic("filedup");
    800045a8:	00004517          	auipc	a0,0x4
    800045ac:	0c050513          	addi	a0,a0,192 # 80008668 <syscalls+0x240>
    800045b0:	ffffc097          	auipc	ra,0xffffc
    800045b4:	f98080e7          	jalr	-104(ra) # 80000548 <panic>

00000000800045b8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045b8:	7139                	addi	sp,sp,-64
    800045ba:	fc06                	sd	ra,56(sp)
    800045bc:	f822                	sd	s0,48(sp)
    800045be:	f426                	sd	s1,40(sp)
    800045c0:	f04a                	sd	s2,32(sp)
    800045c2:	ec4e                	sd	s3,24(sp)
    800045c4:	e852                	sd	s4,16(sp)
    800045c6:	e456                	sd	s5,8(sp)
    800045c8:	0080                	addi	s0,sp,64
    800045ca:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045cc:	0001d517          	auipc	a0,0x1d
    800045d0:	48450513          	addi	a0,a0,1156 # 80021a50 <ftable>
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	66a080e7          	jalr	1642(ra) # 80000c3e <acquire>
  if(f->ref < 1)
    800045dc:	40dc                	lw	a5,4(s1)
    800045de:	06f05163          	blez	a5,80004640 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045e2:	37fd                	addiw	a5,a5,-1
    800045e4:	0007871b          	sext.w	a4,a5
    800045e8:	c0dc                	sw	a5,4(s1)
    800045ea:	06e04363          	bgtz	a4,80004650 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045ee:	0004a903          	lw	s2,0(s1)
    800045f2:	0094ca83          	lbu	s5,9(s1)
    800045f6:	0104ba03          	ld	s4,16(s1)
    800045fa:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045fe:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004602:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004606:	0001d517          	auipc	a0,0x1d
    8000460a:	44a50513          	addi	a0,a0,1098 # 80021a50 <ftable>
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	6e4080e7          	jalr	1764(ra) # 80000cf2 <release>

  if(ff.type == FD_PIPE){
    80004616:	4785                	li	a5,1
    80004618:	04f90d63          	beq	s2,a5,80004672 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000461c:	3979                	addiw	s2,s2,-2
    8000461e:	4785                	li	a5,1
    80004620:	0527e063          	bltu	a5,s2,80004660 <fileclose+0xa8>
    begin_op();
    80004624:	00000097          	auipc	ra,0x0
    80004628:	ac2080e7          	jalr	-1342(ra) # 800040e6 <begin_op>
    iput(ff.ip);
    8000462c:	854e                	mv	a0,s3
    8000462e:	fffff097          	auipc	ra,0xfffff
    80004632:	2b2080e7          	jalr	690(ra) # 800038e0 <iput>
    end_op();
    80004636:	00000097          	auipc	ra,0x0
    8000463a:	b30080e7          	jalr	-1232(ra) # 80004166 <end_op>
    8000463e:	a00d                	j	80004660 <fileclose+0xa8>
    panic("fileclose");
    80004640:	00004517          	auipc	a0,0x4
    80004644:	03050513          	addi	a0,a0,48 # 80008670 <syscalls+0x248>
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	f00080e7          	jalr	-256(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004650:	0001d517          	auipc	a0,0x1d
    80004654:	40050513          	addi	a0,a0,1024 # 80021a50 <ftable>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	69a080e7          	jalr	1690(ra) # 80000cf2 <release>
  }
}
    80004660:	70e2                	ld	ra,56(sp)
    80004662:	7442                	ld	s0,48(sp)
    80004664:	74a2                	ld	s1,40(sp)
    80004666:	7902                	ld	s2,32(sp)
    80004668:	69e2                	ld	s3,24(sp)
    8000466a:	6a42                	ld	s4,16(sp)
    8000466c:	6aa2                	ld	s5,8(sp)
    8000466e:	6121                	addi	sp,sp,64
    80004670:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004672:	85d6                	mv	a1,s5
    80004674:	8552                	mv	a0,s4
    80004676:	00000097          	auipc	ra,0x0
    8000467a:	372080e7          	jalr	882(ra) # 800049e8 <pipeclose>
    8000467e:	b7cd                	j	80004660 <fileclose+0xa8>

0000000080004680 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004680:	715d                	addi	sp,sp,-80
    80004682:	e486                	sd	ra,72(sp)
    80004684:	e0a2                	sd	s0,64(sp)
    80004686:	fc26                	sd	s1,56(sp)
    80004688:	f84a                	sd	s2,48(sp)
    8000468a:	f44e                	sd	s3,40(sp)
    8000468c:	0880                	addi	s0,sp,80
    8000468e:	84aa                	mv	s1,a0
    80004690:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004692:	ffffd097          	auipc	ra,0xffffd
    80004696:	446080e7          	jalr	1094(ra) # 80001ad8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000469a:	409c                	lw	a5,0(s1)
    8000469c:	37f9                	addiw	a5,a5,-2
    8000469e:	4705                	li	a4,1
    800046a0:	04f76763          	bltu	a4,a5,800046ee <filestat+0x6e>
    800046a4:	892a                	mv	s2,a0
    ilock(f->ip);
    800046a6:	6c88                	ld	a0,24(s1)
    800046a8:	fffff097          	auipc	ra,0xfffff
    800046ac:	07e080e7          	jalr	126(ra) # 80003726 <ilock>
    stati(f->ip, &st);
    800046b0:	fb840593          	addi	a1,s0,-72
    800046b4:	6c88                	ld	a0,24(s1)
    800046b6:	fffff097          	auipc	ra,0xfffff
    800046ba:	2fa080e7          	jalr	762(ra) # 800039b0 <stati>
    iunlock(f->ip);
    800046be:	6c88                	ld	a0,24(s1)
    800046c0:	fffff097          	auipc	ra,0xfffff
    800046c4:	128080e7          	jalr	296(ra) # 800037e8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046c8:	46e1                	li	a3,24
    800046ca:	fb840613          	addi	a2,s0,-72
    800046ce:	85ce                	mv	a1,s3
    800046d0:	05093503          	ld	a0,80(s2)
    800046d4:	ffffd097          	auipc	ra,0xffffd
    800046d8:	0f8080e7          	jalr	248(ra) # 800017cc <copyout>
    800046dc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046e0:	60a6                	ld	ra,72(sp)
    800046e2:	6406                	ld	s0,64(sp)
    800046e4:	74e2                	ld	s1,56(sp)
    800046e6:	7942                	ld	s2,48(sp)
    800046e8:	79a2                	ld	s3,40(sp)
    800046ea:	6161                	addi	sp,sp,80
    800046ec:	8082                	ret
  return -1;
    800046ee:	557d                	li	a0,-1
    800046f0:	bfc5                	j	800046e0 <filestat+0x60>

00000000800046f2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046f2:	7179                	addi	sp,sp,-48
    800046f4:	f406                	sd	ra,40(sp)
    800046f6:	f022                	sd	s0,32(sp)
    800046f8:	ec26                	sd	s1,24(sp)
    800046fa:	e84a                	sd	s2,16(sp)
    800046fc:	e44e                	sd	s3,8(sp)
    800046fe:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004700:	00854783          	lbu	a5,8(a0)
    80004704:	c3d5                	beqz	a5,800047a8 <fileread+0xb6>
    80004706:	84aa                	mv	s1,a0
    80004708:	89ae                	mv	s3,a1
    8000470a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000470c:	411c                	lw	a5,0(a0)
    8000470e:	4705                	li	a4,1
    80004710:	04e78963          	beq	a5,a4,80004762 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004714:	470d                	li	a4,3
    80004716:	04e78d63          	beq	a5,a4,80004770 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000471a:	4709                	li	a4,2
    8000471c:	06e79e63          	bne	a5,a4,80004798 <fileread+0xa6>
    ilock(f->ip);
    80004720:	6d08                	ld	a0,24(a0)
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	004080e7          	jalr	4(ra) # 80003726 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000472a:	874a                	mv	a4,s2
    8000472c:	5094                	lw	a3,32(s1)
    8000472e:	864e                	mv	a2,s3
    80004730:	4585                	li	a1,1
    80004732:	6c88                	ld	a0,24(s1)
    80004734:	fffff097          	auipc	ra,0xfffff
    80004738:	2a6080e7          	jalr	678(ra) # 800039da <readi>
    8000473c:	892a                	mv	s2,a0
    8000473e:	00a05563          	blez	a0,80004748 <fileread+0x56>
      f->off += r;
    80004742:	509c                	lw	a5,32(s1)
    80004744:	9fa9                	addw	a5,a5,a0
    80004746:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004748:	6c88                	ld	a0,24(s1)
    8000474a:	fffff097          	auipc	ra,0xfffff
    8000474e:	09e080e7          	jalr	158(ra) # 800037e8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004752:	854a                	mv	a0,s2
    80004754:	70a2                	ld	ra,40(sp)
    80004756:	7402                	ld	s0,32(sp)
    80004758:	64e2                	ld	s1,24(sp)
    8000475a:	6942                	ld	s2,16(sp)
    8000475c:	69a2                	ld	s3,8(sp)
    8000475e:	6145                	addi	sp,sp,48
    80004760:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004762:	6908                	ld	a0,16(a0)
    80004764:	00000097          	auipc	ra,0x0
    80004768:	418080e7          	jalr	1048(ra) # 80004b7c <piperead>
    8000476c:	892a                	mv	s2,a0
    8000476e:	b7d5                	j	80004752 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004770:	02451783          	lh	a5,36(a0)
    80004774:	03079693          	slli	a3,a5,0x30
    80004778:	92c1                	srli	a3,a3,0x30
    8000477a:	4725                	li	a4,9
    8000477c:	02d76863          	bltu	a4,a3,800047ac <fileread+0xba>
    80004780:	0792                	slli	a5,a5,0x4
    80004782:	0001d717          	auipc	a4,0x1d
    80004786:	22e70713          	addi	a4,a4,558 # 800219b0 <devsw>
    8000478a:	97ba                	add	a5,a5,a4
    8000478c:	639c                	ld	a5,0(a5)
    8000478e:	c38d                	beqz	a5,800047b0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004790:	4505                	li	a0,1
    80004792:	9782                	jalr	a5
    80004794:	892a                	mv	s2,a0
    80004796:	bf75                	j	80004752 <fileread+0x60>
    panic("fileread");
    80004798:	00004517          	auipc	a0,0x4
    8000479c:	ee850513          	addi	a0,a0,-280 # 80008680 <syscalls+0x258>
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	da8080e7          	jalr	-600(ra) # 80000548 <panic>
    return -1;
    800047a8:	597d                	li	s2,-1
    800047aa:	b765                	j	80004752 <fileread+0x60>
      return -1;
    800047ac:	597d                	li	s2,-1
    800047ae:	b755                	j	80004752 <fileread+0x60>
    800047b0:	597d                	li	s2,-1
    800047b2:	b745                	j	80004752 <fileread+0x60>

00000000800047b4 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047b4:	00954783          	lbu	a5,9(a0)
    800047b8:	14078563          	beqz	a5,80004902 <filewrite+0x14e>
{
    800047bc:	715d                	addi	sp,sp,-80
    800047be:	e486                	sd	ra,72(sp)
    800047c0:	e0a2                	sd	s0,64(sp)
    800047c2:	fc26                	sd	s1,56(sp)
    800047c4:	f84a                	sd	s2,48(sp)
    800047c6:	f44e                	sd	s3,40(sp)
    800047c8:	f052                	sd	s4,32(sp)
    800047ca:	ec56                	sd	s5,24(sp)
    800047cc:	e85a                	sd	s6,16(sp)
    800047ce:	e45e                	sd	s7,8(sp)
    800047d0:	e062                	sd	s8,0(sp)
    800047d2:	0880                	addi	s0,sp,80
    800047d4:	892a                	mv	s2,a0
    800047d6:	8aae                	mv	s5,a1
    800047d8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047da:	411c                	lw	a5,0(a0)
    800047dc:	4705                	li	a4,1
    800047de:	02e78263          	beq	a5,a4,80004802 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047e2:	470d                	li	a4,3
    800047e4:	02e78563          	beq	a5,a4,8000480e <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047e8:	4709                	li	a4,2
    800047ea:	10e79463          	bne	a5,a4,800048f2 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047ee:	0ec05e63          	blez	a2,800048ea <filewrite+0x136>
    int i = 0;
    800047f2:	4981                	li	s3,0
    800047f4:	6b05                	lui	s6,0x1
    800047f6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047fa:	6b85                	lui	s7,0x1
    800047fc:	c00b8b9b          	addiw	s7,s7,-1024
    80004800:	a851                	j	80004894 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004802:	6908                	ld	a0,16(a0)
    80004804:	00000097          	auipc	ra,0x0
    80004808:	254080e7          	jalr	596(ra) # 80004a58 <pipewrite>
    8000480c:	a85d                	j	800048c2 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000480e:	02451783          	lh	a5,36(a0)
    80004812:	03079693          	slli	a3,a5,0x30
    80004816:	92c1                	srli	a3,a3,0x30
    80004818:	4725                	li	a4,9
    8000481a:	0ed76663          	bltu	a4,a3,80004906 <filewrite+0x152>
    8000481e:	0792                	slli	a5,a5,0x4
    80004820:	0001d717          	auipc	a4,0x1d
    80004824:	19070713          	addi	a4,a4,400 # 800219b0 <devsw>
    80004828:	97ba                	add	a5,a5,a4
    8000482a:	679c                	ld	a5,8(a5)
    8000482c:	cff9                	beqz	a5,8000490a <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    8000482e:	4505                	li	a0,1
    80004830:	9782                	jalr	a5
    80004832:	a841                	j	800048c2 <filewrite+0x10e>
    80004834:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004838:	00000097          	auipc	ra,0x0
    8000483c:	8ae080e7          	jalr	-1874(ra) # 800040e6 <begin_op>
      ilock(f->ip);
    80004840:	01893503          	ld	a0,24(s2)
    80004844:	fffff097          	auipc	ra,0xfffff
    80004848:	ee2080e7          	jalr	-286(ra) # 80003726 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000484c:	8762                	mv	a4,s8
    8000484e:	02092683          	lw	a3,32(s2)
    80004852:	01598633          	add	a2,s3,s5
    80004856:	4585                	li	a1,1
    80004858:	01893503          	ld	a0,24(s2)
    8000485c:	fffff097          	auipc	ra,0xfffff
    80004860:	276080e7          	jalr	630(ra) # 80003ad2 <writei>
    80004864:	84aa                	mv	s1,a0
    80004866:	02a05f63          	blez	a0,800048a4 <filewrite+0xf0>
        f->off += r;
    8000486a:	02092783          	lw	a5,32(s2)
    8000486e:	9fa9                	addw	a5,a5,a0
    80004870:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004874:	01893503          	ld	a0,24(s2)
    80004878:	fffff097          	auipc	ra,0xfffff
    8000487c:	f70080e7          	jalr	-144(ra) # 800037e8 <iunlock>
      end_op();
    80004880:	00000097          	auipc	ra,0x0
    80004884:	8e6080e7          	jalr	-1818(ra) # 80004166 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004888:	049c1963          	bne	s8,s1,800048da <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000488c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004890:	0349d663          	bge	s3,s4,800048bc <filewrite+0x108>
      int n1 = n - i;
    80004894:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004898:	84be                	mv	s1,a5
    8000489a:	2781                	sext.w	a5,a5
    8000489c:	f8fb5ce3          	bge	s6,a5,80004834 <filewrite+0x80>
    800048a0:	84de                	mv	s1,s7
    800048a2:	bf49                	j	80004834 <filewrite+0x80>
      iunlock(f->ip);
    800048a4:	01893503          	ld	a0,24(s2)
    800048a8:	fffff097          	auipc	ra,0xfffff
    800048ac:	f40080e7          	jalr	-192(ra) # 800037e8 <iunlock>
      end_op();
    800048b0:	00000097          	auipc	ra,0x0
    800048b4:	8b6080e7          	jalr	-1866(ra) # 80004166 <end_op>
      if(r < 0)
    800048b8:	fc04d8e3          	bgez	s1,80004888 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800048bc:	8552                	mv	a0,s4
    800048be:	033a1863          	bne	s4,s3,800048ee <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048c2:	60a6                	ld	ra,72(sp)
    800048c4:	6406                	ld	s0,64(sp)
    800048c6:	74e2                	ld	s1,56(sp)
    800048c8:	7942                	ld	s2,48(sp)
    800048ca:	79a2                	ld	s3,40(sp)
    800048cc:	7a02                	ld	s4,32(sp)
    800048ce:	6ae2                	ld	s5,24(sp)
    800048d0:	6b42                	ld	s6,16(sp)
    800048d2:	6ba2                	ld	s7,8(sp)
    800048d4:	6c02                	ld	s8,0(sp)
    800048d6:	6161                	addi	sp,sp,80
    800048d8:	8082                	ret
        panic("short filewrite");
    800048da:	00004517          	auipc	a0,0x4
    800048de:	db650513          	addi	a0,a0,-586 # 80008690 <syscalls+0x268>
    800048e2:	ffffc097          	auipc	ra,0xffffc
    800048e6:	c66080e7          	jalr	-922(ra) # 80000548 <panic>
    int i = 0;
    800048ea:	4981                	li	s3,0
    800048ec:	bfc1                	j	800048bc <filewrite+0x108>
    ret = (i == n ? n : -1);
    800048ee:	557d                	li	a0,-1
    800048f0:	bfc9                	j	800048c2 <filewrite+0x10e>
    panic("filewrite");
    800048f2:	00004517          	auipc	a0,0x4
    800048f6:	dae50513          	addi	a0,a0,-594 # 800086a0 <syscalls+0x278>
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	c4e080e7          	jalr	-946(ra) # 80000548 <panic>
    return -1;
    80004902:	557d                	li	a0,-1
}
    80004904:	8082                	ret
      return -1;
    80004906:	557d                	li	a0,-1
    80004908:	bf6d                	j	800048c2 <filewrite+0x10e>
    8000490a:	557d                	li	a0,-1
    8000490c:	bf5d                	j	800048c2 <filewrite+0x10e>

000000008000490e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000490e:	7179                	addi	sp,sp,-48
    80004910:	f406                	sd	ra,40(sp)
    80004912:	f022                	sd	s0,32(sp)
    80004914:	ec26                	sd	s1,24(sp)
    80004916:	e84a                	sd	s2,16(sp)
    80004918:	e44e                	sd	s3,8(sp)
    8000491a:	e052                	sd	s4,0(sp)
    8000491c:	1800                	addi	s0,sp,48
    8000491e:	84aa                	mv	s1,a0
    80004920:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004922:	0005b023          	sd	zero,0(a1)
    80004926:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000492a:	00000097          	auipc	ra,0x0
    8000492e:	bd2080e7          	jalr	-1070(ra) # 800044fc <filealloc>
    80004932:	e088                	sd	a0,0(s1)
    80004934:	c551                	beqz	a0,800049c0 <pipealloc+0xb2>
    80004936:	00000097          	auipc	ra,0x0
    8000493a:	bc6080e7          	jalr	-1082(ra) # 800044fc <filealloc>
    8000493e:	00aa3023          	sd	a0,0(s4)
    80004942:	c92d                	beqz	a0,800049b4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	1f6080e7          	jalr	502(ra) # 80000b3a <kalloc>
    8000494c:	892a                	mv	s2,a0
    8000494e:	c125                	beqz	a0,800049ae <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004950:	4985                	li	s3,1
    80004952:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004956:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000495a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000495e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004962:	00004597          	auipc	a1,0x4
    80004966:	d4e58593          	addi	a1,a1,-690 # 800086b0 <syscalls+0x288>
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	244080e7          	jalr	580(ra) # 80000bae <initlock>
  (*f0)->type = FD_PIPE;
    80004972:	609c                	ld	a5,0(s1)
    80004974:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004978:	609c                	ld	a5,0(s1)
    8000497a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000497e:	609c                	ld	a5,0(s1)
    80004980:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004984:	609c                	ld	a5,0(s1)
    80004986:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000498a:	000a3783          	ld	a5,0(s4)
    8000498e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004992:	000a3783          	ld	a5,0(s4)
    80004996:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000499a:	000a3783          	ld	a5,0(s4)
    8000499e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049a2:	000a3783          	ld	a5,0(s4)
    800049a6:	0127b823          	sd	s2,16(a5)
  return 0;
    800049aa:	4501                	li	a0,0
    800049ac:	a025                	j	800049d4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049ae:	6088                	ld	a0,0(s1)
    800049b0:	e501                	bnez	a0,800049b8 <pipealloc+0xaa>
    800049b2:	a039                	j	800049c0 <pipealloc+0xb2>
    800049b4:	6088                	ld	a0,0(s1)
    800049b6:	c51d                	beqz	a0,800049e4 <pipealloc+0xd6>
    fileclose(*f0);
    800049b8:	00000097          	auipc	ra,0x0
    800049bc:	c00080e7          	jalr	-1024(ra) # 800045b8 <fileclose>
  if(*f1)
    800049c0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049c4:	557d                	li	a0,-1
  if(*f1)
    800049c6:	c799                	beqz	a5,800049d4 <pipealloc+0xc6>
    fileclose(*f1);
    800049c8:	853e                	mv	a0,a5
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	bee080e7          	jalr	-1042(ra) # 800045b8 <fileclose>
  return -1;
    800049d2:	557d                	li	a0,-1
}
    800049d4:	70a2                	ld	ra,40(sp)
    800049d6:	7402                	ld	s0,32(sp)
    800049d8:	64e2                	ld	s1,24(sp)
    800049da:	6942                	ld	s2,16(sp)
    800049dc:	69a2                	ld	s3,8(sp)
    800049de:	6a02                	ld	s4,0(sp)
    800049e0:	6145                	addi	sp,sp,48
    800049e2:	8082                	ret
  return -1;
    800049e4:	557d                	li	a0,-1
    800049e6:	b7fd                	j	800049d4 <pipealloc+0xc6>

00000000800049e8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049e8:	1101                	addi	sp,sp,-32
    800049ea:	ec06                	sd	ra,24(sp)
    800049ec:	e822                	sd	s0,16(sp)
    800049ee:	e426                	sd	s1,8(sp)
    800049f0:	e04a                	sd	s2,0(sp)
    800049f2:	1000                	addi	s0,sp,32
    800049f4:	84aa                	mv	s1,a0
    800049f6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	246080e7          	jalr	582(ra) # 80000c3e <acquire>
  if(writable){
    80004a00:	02090d63          	beqz	s2,80004a3a <pipeclose+0x52>
    pi->writeopen = 0;
    80004a04:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a08:	21848513          	addi	a0,s1,536
    80004a0c:	ffffe097          	auipc	ra,0xffffe
    80004a10:	a62080e7          	jalr	-1438(ra) # 8000246e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a14:	2204b783          	ld	a5,544(s1)
    80004a18:	eb95                	bnez	a5,80004a4c <pipeclose+0x64>
    release(&pi->lock);
    80004a1a:	8526                	mv	a0,s1
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	2d6080e7          	jalr	726(ra) # 80000cf2 <release>
    kfree((char*)pi);
    80004a24:	8526                	mv	a0,s1
    80004a26:	ffffc097          	auipc	ra,0xffffc
    80004a2a:	ffe080e7          	jalr	-2(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004a2e:	60e2                	ld	ra,24(sp)
    80004a30:	6442                	ld	s0,16(sp)
    80004a32:	64a2                	ld	s1,8(sp)
    80004a34:	6902                	ld	s2,0(sp)
    80004a36:	6105                	addi	sp,sp,32
    80004a38:	8082                	ret
    pi->readopen = 0;
    80004a3a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a3e:	21c48513          	addi	a0,s1,540
    80004a42:	ffffe097          	auipc	ra,0xffffe
    80004a46:	a2c080e7          	jalr	-1492(ra) # 8000246e <wakeup>
    80004a4a:	b7e9                	j	80004a14 <pipeclose+0x2c>
    release(&pi->lock);
    80004a4c:	8526                	mv	a0,s1
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	2a4080e7          	jalr	676(ra) # 80000cf2 <release>
}
    80004a56:	bfe1                	j	80004a2e <pipeclose+0x46>

0000000080004a58 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a58:	7119                	addi	sp,sp,-128
    80004a5a:	fc86                	sd	ra,120(sp)
    80004a5c:	f8a2                	sd	s0,112(sp)
    80004a5e:	f4a6                	sd	s1,104(sp)
    80004a60:	f0ca                	sd	s2,96(sp)
    80004a62:	ecce                	sd	s3,88(sp)
    80004a64:	e8d2                	sd	s4,80(sp)
    80004a66:	e4d6                	sd	s5,72(sp)
    80004a68:	e0da                	sd	s6,64(sp)
    80004a6a:	fc5e                	sd	s7,56(sp)
    80004a6c:	f862                	sd	s8,48(sp)
    80004a6e:	f466                	sd	s9,40(sp)
    80004a70:	f06a                	sd	s10,32(sp)
    80004a72:	ec6e                	sd	s11,24(sp)
    80004a74:	0100                	addi	s0,sp,128
    80004a76:	84aa                	mv	s1,a0
    80004a78:	8cae                	mv	s9,a1
    80004a7a:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004a7c:	ffffd097          	auipc	ra,0xffffd
    80004a80:	05c080e7          	jalr	92(ra) # 80001ad8 <myproc>
    80004a84:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004a86:	8526                	mv	a0,s1
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	1b6080e7          	jalr	438(ra) # 80000c3e <acquire>
  for(i = 0; i < n; i++){
    80004a90:	0d605963          	blez	s6,80004b62 <pipewrite+0x10a>
    80004a94:	89a6                	mv	s3,s1
    80004a96:	3b7d                	addiw	s6,s6,-1
    80004a98:	1b02                	slli	s6,s6,0x20
    80004a9a:	020b5b13          	srli	s6,s6,0x20
    80004a9e:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004aa0:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004aa4:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aa8:	5dfd                	li	s11,-1
    80004aaa:	000b8d1b          	sext.w	s10,s7
    80004aae:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ab0:	2184a783          	lw	a5,536(s1)
    80004ab4:	21c4a703          	lw	a4,540(s1)
    80004ab8:	2007879b          	addiw	a5,a5,512
    80004abc:	02f71b63          	bne	a4,a5,80004af2 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004ac0:	2204a783          	lw	a5,544(s1)
    80004ac4:	cbad                	beqz	a5,80004b36 <pipewrite+0xde>
    80004ac6:	03092783          	lw	a5,48(s2)
    80004aca:	e7b5                	bnez	a5,80004b36 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004acc:	8556                	mv	a0,s5
    80004ace:	ffffe097          	auipc	ra,0xffffe
    80004ad2:	9a0080e7          	jalr	-1632(ra) # 8000246e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ad6:	85ce                	mv	a1,s3
    80004ad8:	8552                	mv	a0,s4
    80004ada:	ffffe097          	auipc	ra,0xffffe
    80004ade:	80e080e7          	jalr	-2034(ra) # 800022e8 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ae2:	2184a783          	lw	a5,536(s1)
    80004ae6:	21c4a703          	lw	a4,540(s1)
    80004aea:	2007879b          	addiw	a5,a5,512
    80004aee:	fcf709e3          	beq	a4,a5,80004ac0 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004af2:	4685                	li	a3,1
    80004af4:	019b8633          	add	a2,s7,s9
    80004af8:	f8f40593          	addi	a1,s0,-113
    80004afc:	05093503          	ld	a0,80(s2)
    80004b00:	ffffd097          	auipc	ra,0xffffd
    80004b04:	d58080e7          	jalr	-680(ra) # 80001858 <copyin>
    80004b08:	05b50e63          	beq	a0,s11,80004b64 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b0c:	21c4a783          	lw	a5,540(s1)
    80004b10:	0017871b          	addiw	a4,a5,1
    80004b14:	20e4ae23          	sw	a4,540(s1)
    80004b18:	1ff7f793          	andi	a5,a5,511
    80004b1c:	97a6                	add	a5,a5,s1
    80004b1e:	f8f44703          	lbu	a4,-113(s0)
    80004b22:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b26:	001d0c1b          	addiw	s8,s10,1
    80004b2a:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b2e:	036b8b63          	beq	s7,s6,80004b64 <pipewrite+0x10c>
    80004b32:	8bbe                	mv	s7,a5
    80004b34:	bf9d                	j	80004aaa <pipewrite+0x52>
        release(&pi->lock);
    80004b36:	8526                	mv	a0,s1
    80004b38:	ffffc097          	auipc	ra,0xffffc
    80004b3c:	1ba080e7          	jalr	442(ra) # 80000cf2 <release>
        return -1;
    80004b40:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b42:	8562                	mv	a0,s8
    80004b44:	70e6                	ld	ra,120(sp)
    80004b46:	7446                	ld	s0,112(sp)
    80004b48:	74a6                	ld	s1,104(sp)
    80004b4a:	7906                	ld	s2,96(sp)
    80004b4c:	69e6                	ld	s3,88(sp)
    80004b4e:	6a46                	ld	s4,80(sp)
    80004b50:	6aa6                	ld	s5,72(sp)
    80004b52:	6b06                	ld	s6,64(sp)
    80004b54:	7be2                	ld	s7,56(sp)
    80004b56:	7c42                	ld	s8,48(sp)
    80004b58:	7ca2                	ld	s9,40(sp)
    80004b5a:	7d02                	ld	s10,32(sp)
    80004b5c:	6de2                	ld	s11,24(sp)
    80004b5e:	6109                	addi	sp,sp,128
    80004b60:	8082                	ret
  for(i = 0; i < n; i++){
    80004b62:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004b64:	21848513          	addi	a0,s1,536
    80004b68:	ffffe097          	auipc	ra,0xffffe
    80004b6c:	906080e7          	jalr	-1786(ra) # 8000246e <wakeup>
  release(&pi->lock);
    80004b70:	8526                	mv	a0,s1
    80004b72:	ffffc097          	auipc	ra,0xffffc
    80004b76:	180080e7          	jalr	384(ra) # 80000cf2 <release>
  return i;
    80004b7a:	b7e1                	j	80004b42 <pipewrite+0xea>

0000000080004b7c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b7c:	715d                	addi	sp,sp,-80
    80004b7e:	e486                	sd	ra,72(sp)
    80004b80:	e0a2                	sd	s0,64(sp)
    80004b82:	fc26                	sd	s1,56(sp)
    80004b84:	f84a                	sd	s2,48(sp)
    80004b86:	f44e                	sd	s3,40(sp)
    80004b88:	f052                	sd	s4,32(sp)
    80004b8a:	ec56                	sd	s5,24(sp)
    80004b8c:	e85a                	sd	s6,16(sp)
    80004b8e:	0880                	addi	s0,sp,80
    80004b90:	84aa                	mv	s1,a0
    80004b92:	892e                	mv	s2,a1
    80004b94:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b96:	ffffd097          	auipc	ra,0xffffd
    80004b9a:	f42080e7          	jalr	-190(ra) # 80001ad8 <myproc>
    80004b9e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ba0:	8b26                	mv	s6,s1
    80004ba2:	8526                	mv	a0,s1
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	09a080e7          	jalr	154(ra) # 80000c3e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bac:	2184a703          	lw	a4,536(s1)
    80004bb0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bb4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bb8:	02f71463          	bne	a4,a5,80004be0 <piperead+0x64>
    80004bbc:	2244a783          	lw	a5,548(s1)
    80004bc0:	c385                	beqz	a5,80004be0 <piperead+0x64>
    if(pr->killed){
    80004bc2:	030a2783          	lw	a5,48(s4)
    80004bc6:	ebc1                	bnez	a5,80004c56 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bc8:	85da                	mv	a1,s6
    80004bca:	854e                	mv	a0,s3
    80004bcc:	ffffd097          	auipc	ra,0xffffd
    80004bd0:	71c080e7          	jalr	1820(ra) # 800022e8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bd4:	2184a703          	lw	a4,536(s1)
    80004bd8:	21c4a783          	lw	a5,540(s1)
    80004bdc:	fef700e3          	beq	a4,a5,80004bbc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004be0:	09505263          	blez	s5,80004c64 <piperead+0xe8>
    80004be4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004be6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004be8:	2184a783          	lw	a5,536(s1)
    80004bec:	21c4a703          	lw	a4,540(s1)
    80004bf0:	02f70d63          	beq	a4,a5,80004c2a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bf4:	0017871b          	addiw	a4,a5,1
    80004bf8:	20e4ac23          	sw	a4,536(s1)
    80004bfc:	1ff7f793          	andi	a5,a5,511
    80004c00:	97a6                	add	a5,a5,s1
    80004c02:	0187c783          	lbu	a5,24(a5)
    80004c06:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c0a:	4685                	li	a3,1
    80004c0c:	fbf40613          	addi	a2,s0,-65
    80004c10:	85ca                	mv	a1,s2
    80004c12:	050a3503          	ld	a0,80(s4)
    80004c16:	ffffd097          	auipc	ra,0xffffd
    80004c1a:	bb6080e7          	jalr	-1098(ra) # 800017cc <copyout>
    80004c1e:	01650663          	beq	a0,s6,80004c2a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c22:	2985                	addiw	s3,s3,1
    80004c24:	0905                	addi	s2,s2,1
    80004c26:	fd3a91e3          	bne	s5,s3,80004be8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c2a:	21c48513          	addi	a0,s1,540
    80004c2e:	ffffe097          	auipc	ra,0xffffe
    80004c32:	840080e7          	jalr	-1984(ra) # 8000246e <wakeup>
  release(&pi->lock);
    80004c36:	8526                	mv	a0,s1
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	0ba080e7          	jalr	186(ra) # 80000cf2 <release>
  return i;
}
    80004c40:	854e                	mv	a0,s3
    80004c42:	60a6                	ld	ra,72(sp)
    80004c44:	6406                	ld	s0,64(sp)
    80004c46:	74e2                	ld	s1,56(sp)
    80004c48:	7942                	ld	s2,48(sp)
    80004c4a:	79a2                	ld	s3,40(sp)
    80004c4c:	7a02                	ld	s4,32(sp)
    80004c4e:	6ae2                	ld	s5,24(sp)
    80004c50:	6b42                	ld	s6,16(sp)
    80004c52:	6161                	addi	sp,sp,80
    80004c54:	8082                	ret
      release(&pi->lock);
    80004c56:	8526                	mv	a0,s1
    80004c58:	ffffc097          	auipc	ra,0xffffc
    80004c5c:	09a080e7          	jalr	154(ra) # 80000cf2 <release>
      return -1;
    80004c60:	59fd                	li	s3,-1
    80004c62:	bff9                	j	80004c40 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c64:	4981                	li	s3,0
    80004c66:	b7d1                	j	80004c2a <piperead+0xae>

0000000080004c68 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c68:	df010113          	addi	sp,sp,-528
    80004c6c:	20113423          	sd	ra,520(sp)
    80004c70:	20813023          	sd	s0,512(sp)
    80004c74:	ffa6                	sd	s1,504(sp)
    80004c76:	fbca                	sd	s2,496(sp)
    80004c78:	f7ce                	sd	s3,488(sp)
    80004c7a:	f3d2                	sd	s4,480(sp)
    80004c7c:	efd6                	sd	s5,472(sp)
    80004c7e:	ebda                	sd	s6,464(sp)
    80004c80:	e7de                	sd	s7,456(sp)
    80004c82:	e3e2                	sd	s8,448(sp)
    80004c84:	ff66                	sd	s9,440(sp)
    80004c86:	fb6a                	sd	s10,432(sp)
    80004c88:	f76e                	sd	s11,424(sp)
    80004c8a:	0c00                	addi	s0,sp,528
    80004c8c:	84aa                	mv	s1,a0
    80004c8e:	dea43c23          	sd	a0,-520(s0)
    80004c92:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c96:	ffffd097          	auipc	ra,0xffffd
    80004c9a:	e42080e7          	jalr	-446(ra) # 80001ad8 <myproc>
    80004c9e:	892a                	mv	s2,a0

  begin_op();
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	446080e7          	jalr	1094(ra) # 800040e6 <begin_op>

  if((ip = namei(path)) == 0){
    80004ca8:	8526                	mv	a0,s1
    80004caa:	fffff097          	auipc	ra,0xfffff
    80004cae:	230080e7          	jalr	560(ra) # 80003eda <namei>
    80004cb2:	c92d                	beqz	a0,80004d24 <exec+0xbc>
    80004cb4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cb6:	fffff097          	auipc	ra,0xfffff
    80004cba:	a70080e7          	jalr	-1424(ra) # 80003726 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cbe:	04000713          	li	a4,64
    80004cc2:	4681                	li	a3,0
    80004cc4:	e4840613          	addi	a2,s0,-440
    80004cc8:	4581                	li	a1,0
    80004cca:	8526                	mv	a0,s1
    80004ccc:	fffff097          	auipc	ra,0xfffff
    80004cd0:	d0e080e7          	jalr	-754(ra) # 800039da <readi>
    80004cd4:	04000793          	li	a5,64
    80004cd8:	00f51a63          	bne	a0,a5,80004cec <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cdc:	e4842703          	lw	a4,-440(s0)
    80004ce0:	464c47b7          	lui	a5,0x464c4
    80004ce4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ce8:	04f70463          	beq	a4,a5,80004d30 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cec:	8526                	mv	a0,s1
    80004cee:	fffff097          	auipc	ra,0xfffff
    80004cf2:	c9a080e7          	jalr	-870(ra) # 80003988 <iunlockput>
    end_op();
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	470080e7          	jalr	1136(ra) # 80004166 <end_op>
  }
  return -1;
    80004cfe:	557d                	li	a0,-1
}
    80004d00:	20813083          	ld	ra,520(sp)
    80004d04:	20013403          	ld	s0,512(sp)
    80004d08:	74fe                	ld	s1,504(sp)
    80004d0a:	795e                	ld	s2,496(sp)
    80004d0c:	79be                	ld	s3,488(sp)
    80004d0e:	7a1e                	ld	s4,480(sp)
    80004d10:	6afe                	ld	s5,472(sp)
    80004d12:	6b5e                	ld	s6,464(sp)
    80004d14:	6bbe                	ld	s7,456(sp)
    80004d16:	6c1e                	ld	s8,448(sp)
    80004d18:	7cfa                	ld	s9,440(sp)
    80004d1a:	7d5a                	ld	s10,432(sp)
    80004d1c:	7dba                	ld	s11,424(sp)
    80004d1e:	21010113          	addi	sp,sp,528
    80004d22:	8082                	ret
    end_op();
    80004d24:	fffff097          	auipc	ra,0xfffff
    80004d28:	442080e7          	jalr	1090(ra) # 80004166 <end_op>
    return -1;
    80004d2c:	557d                	li	a0,-1
    80004d2e:	bfc9                	j	80004d00 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d30:	854a                	mv	a0,s2
    80004d32:	ffffd097          	auipc	ra,0xffffd
    80004d36:	e6a080e7          	jalr	-406(ra) # 80001b9c <proc_pagetable>
    80004d3a:	8baa                	mv	s7,a0
    80004d3c:	d945                	beqz	a0,80004cec <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d3e:	e6842983          	lw	s3,-408(s0)
    80004d42:	e8045783          	lhu	a5,-384(s0)
    80004d46:	c7ad                	beqz	a5,80004db0 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d48:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d4a:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d4c:	6c85                	lui	s9,0x1
    80004d4e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d52:	def43823          	sd	a5,-528(s0)
    80004d56:	a42d                	j	80004f80 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d58:	00004517          	auipc	a0,0x4
    80004d5c:	96050513          	addi	a0,a0,-1696 # 800086b8 <syscalls+0x290>
    80004d60:	ffffb097          	auipc	ra,0xffffb
    80004d64:	7e8080e7          	jalr	2024(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d68:	8756                	mv	a4,s5
    80004d6a:	012d86bb          	addw	a3,s11,s2
    80004d6e:	4581                	li	a1,0
    80004d70:	8526                	mv	a0,s1
    80004d72:	fffff097          	auipc	ra,0xfffff
    80004d76:	c68080e7          	jalr	-920(ra) # 800039da <readi>
    80004d7a:	2501                	sext.w	a0,a0
    80004d7c:	1aaa9963          	bne	s5,a0,80004f2e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d80:	6785                	lui	a5,0x1
    80004d82:	0127893b          	addw	s2,a5,s2
    80004d86:	77fd                	lui	a5,0xfffff
    80004d88:	01478a3b          	addw	s4,a5,s4
    80004d8c:	1f897163          	bgeu	s2,s8,80004f6e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004d90:	02091593          	slli	a1,s2,0x20
    80004d94:	9181                	srli	a1,a1,0x20
    80004d96:	95ea                	add	a1,a1,s10
    80004d98:	855e                	mv	a0,s7
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	332080e7          	jalr	818(ra) # 800010cc <walkaddr>
    80004da2:	862a                	mv	a2,a0
    if(pa == 0)
    80004da4:	d955                	beqz	a0,80004d58 <exec+0xf0>
      n = PGSIZE;
    80004da6:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004da8:	fd9a70e3          	bgeu	s4,s9,80004d68 <exec+0x100>
      n = sz - i;
    80004dac:	8ad2                	mv	s5,s4
    80004dae:	bf6d                	j	80004d68 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004db0:	4901                	li	s2,0
  iunlockput(ip);
    80004db2:	8526                	mv	a0,s1
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	bd4080e7          	jalr	-1068(ra) # 80003988 <iunlockput>
  end_op();
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	3aa080e7          	jalr	938(ra) # 80004166 <end_op>
  p = myproc();
    80004dc4:	ffffd097          	auipc	ra,0xffffd
    80004dc8:	d14080e7          	jalr	-748(ra) # 80001ad8 <myproc>
    80004dcc:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004dce:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004dd2:	6785                	lui	a5,0x1
    80004dd4:	17fd                	addi	a5,a5,-1
    80004dd6:	993e                	add	s2,s2,a5
    80004dd8:	757d                	lui	a0,0xfffff
    80004dda:	00a977b3          	and	a5,s2,a0
    80004dde:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004de2:	6609                	lui	a2,0x2
    80004de4:	963e                	add	a2,a2,a5
    80004de6:	85be                	mv	a1,a5
    80004de8:	855e                	mv	a0,s7
    80004dea:	ffffc097          	auipc	ra,0xffffc
    80004dee:	796080e7          	jalr	1942(ra) # 80001580 <uvmalloc>
    80004df2:	8b2a                	mv	s6,a0
  ip = 0;
    80004df4:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004df6:	12050c63          	beqz	a0,80004f2e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004dfa:	75f9                	lui	a1,0xffffe
    80004dfc:	95aa                	add	a1,a1,a0
    80004dfe:	855e                	mv	a0,s7
    80004e00:	ffffd097          	auipc	ra,0xffffd
    80004e04:	99a080e7          	jalr	-1638(ra) # 8000179a <uvmclear>
  stackbase = sp - PGSIZE;
    80004e08:	7c7d                	lui	s8,0xfffff
    80004e0a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e0c:	e0043783          	ld	a5,-512(s0)
    80004e10:	6388                	ld	a0,0(a5)
    80004e12:	c535                	beqz	a0,80004e7e <exec+0x216>
    80004e14:	e8840993          	addi	s3,s0,-376
    80004e18:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e1c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	0a4080e7          	jalr	164(ra) # 80000ec2 <strlen>
    80004e26:	2505                	addiw	a0,a0,1
    80004e28:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e2c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e30:	13896363          	bltu	s2,s8,80004f56 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e34:	e0043d83          	ld	s11,-512(s0)
    80004e38:	000dba03          	ld	s4,0(s11)
    80004e3c:	8552                	mv	a0,s4
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	084080e7          	jalr	132(ra) # 80000ec2 <strlen>
    80004e46:	0015069b          	addiw	a3,a0,1
    80004e4a:	8652                	mv	a2,s4
    80004e4c:	85ca                	mv	a1,s2
    80004e4e:	855e                	mv	a0,s7
    80004e50:	ffffd097          	auipc	ra,0xffffd
    80004e54:	97c080e7          	jalr	-1668(ra) # 800017cc <copyout>
    80004e58:	10054363          	bltz	a0,80004f5e <exec+0x2f6>
    ustack[argc] = sp;
    80004e5c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e60:	0485                	addi	s1,s1,1
    80004e62:	008d8793          	addi	a5,s11,8
    80004e66:	e0f43023          	sd	a5,-512(s0)
    80004e6a:	008db503          	ld	a0,8(s11)
    80004e6e:	c911                	beqz	a0,80004e82 <exec+0x21a>
    if(argc >= MAXARG)
    80004e70:	09a1                	addi	s3,s3,8
    80004e72:	fb3c96e3          	bne	s9,s3,80004e1e <exec+0x1b6>
  sz = sz1;
    80004e76:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e7a:	4481                	li	s1,0
    80004e7c:	a84d                	j	80004f2e <exec+0x2c6>
  sp = sz;
    80004e7e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e80:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e82:	00349793          	slli	a5,s1,0x3
    80004e86:	f9040713          	addi	a4,s0,-112
    80004e8a:	97ba                	add	a5,a5,a4
    80004e8c:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004e90:	00148693          	addi	a3,s1,1
    80004e94:	068e                	slli	a3,a3,0x3
    80004e96:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e9a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e9e:	01897663          	bgeu	s2,s8,80004eaa <exec+0x242>
  sz = sz1;
    80004ea2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ea6:	4481                	li	s1,0
    80004ea8:	a059                	j	80004f2e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004eaa:	e8840613          	addi	a2,s0,-376
    80004eae:	85ca                	mv	a1,s2
    80004eb0:	855e                	mv	a0,s7
    80004eb2:	ffffd097          	auipc	ra,0xffffd
    80004eb6:	91a080e7          	jalr	-1766(ra) # 800017cc <copyout>
    80004eba:	0a054663          	bltz	a0,80004f66 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004ebe:	058ab783          	ld	a5,88(s5)
    80004ec2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ec6:	df843783          	ld	a5,-520(s0)
    80004eca:	0007c703          	lbu	a4,0(a5)
    80004ece:	cf11                	beqz	a4,80004eea <exec+0x282>
    80004ed0:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ed2:	02f00693          	li	a3,47
    80004ed6:	a029                	j	80004ee0 <exec+0x278>
  for(last=s=path; *s; s++)
    80004ed8:	0785                	addi	a5,a5,1
    80004eda:	fff7c703          	lbu	a4,-1(a5)
    80004ede:	c711                	beqz	a4,80004eea <exec+0x282>
    if(*s == '/')
    80004ee0:	fed71ce3          	bne	a4,a3,80004ed8 <exec+0x270>
      last = s+1;
    80004ee4:	def43c23          	sd	a5,-520(s0)
    80004ee8:	bfc5                	j	80004ed8 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004eea:	4641                	li	a2,16
    80004eec:	df843583          	ld	a1,-520(s0)
    80004ef0:	158a8513          	addi	a0,s5,344
    80004ef4:	ffffc097          	auipc	ra,0xffffc
    80004ef8:	f9c080e7          	jalr	-100(ra) # 80000e90 <safestrcpy>
  oldpagetable = p->pagetable;
    80004efc:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f00:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f04:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f08:	058ab783          	ld	a5,88(s5)
    80004f0c:	e6043703          	ld	a4,-416(s0)
    80004f10:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f12:	058ab783          	ld	a5,88(s5)
    80004f16:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f1a:	85ea                	mv	a1,s10
    80004f1c:	ffffd097          	auipc	ra,0xffffd
    80004f20:	d1c080e7          	jalr	-740(ra) # 80001c38 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f24:	0004851b          	sext.w	a0,s1
    80004f28:	bbe1                	j	80004d00 <exec+0x98>
    80004f2a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f2e:	e0843583          	ld	a1,-504(s0)
    80004f32:	855e                	mv	a0,s7
    80004f34:	ffffd097          	auipc	ra,0xffffd
    80004f38:	d04080e7          	jalr	-764(ra) # 80001c38 <proc_freepagetable>
  if(ip){
    80004f3c:	da0498e3          	bnez	s1,80004cec <exec+0x84>
  return -1;
    80004f40:	557d                	li	a0,-1
    80004f42:	bb7d                	j	80004d00 <exec+0x98>
    80004f44:	e1243423          	sd	s2,-504(s0)
    80004f48:	b7dd                	j	80004f2e <exec+0x2c6>
    80004f4a:	e1243423          	sd	s2,-504(s0)
    80004f4e:	b7c5                	j	80004f2e <exec+0x2c6>
    80004f50:	e1243423          	sd	s2,-504(s0)
    80004f54:	bfe9                	j	80004f2e <exec+0x2c6>
  sz = sz1;
    80004f56:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f5a:	4481                	li	s1,0
    80004f5c:	bfc9                	j	80004f2e <exec+0x2c6>
  sz = sz1;
    80004f5e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f62:	4481                	li	s1,0
    80004f64:	b7e9                	j	80004f2e <exec+0x2c6>
  sz = sz1;
    80004f66:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f6a:	4481                	li	s1,0
    80004f6c:	b7c9                	j	80004f2e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f6e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f72:	2b05                	addiw	s6,s6,1
    80004f74:	0389899b          	addiw	s3,s3,56
    80004f78:	e8045783          	lhu	a5,-384(s0)
    80004f7c:	e2fb5be3          	bge	s6,a5,80004db2 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f80:	2981                	sext.w	s3,s3
    80004f82:	03800713          	li	a4,56
    80004f86:	86ce                	mv	a3,s3
    80004f88:	e1040613          	addi	a2,s0,-496
    80004f8c:	4581                	li	a1,0
    80004f8e:	8526                	mv	a0,s1
    80004f90:	fffff097          	auipc	ra,0xfffff
    80004f94:	a4a080e7          	jalr	-1462(ra) # 800039da <readi>
    80004f98:	03800793          	li	a5,56
    80004f9c:	f8f517e3          	bne	a0,a5,80004f2a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fa0:	e1042783          	lw	a5,-496(s0)
    80004fa4:	4705                	li	a4,1
    80004fa6:	fce796e3          	bne	a5,a4,80004f72 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004faa:	e3843603          	ld	a2,-456(s0)
    80004fae:	e3043783          	ld	a5,-464(s0)
    80004fb2:	f8f669e3          	bltu	a2,a5,80004f44 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fb6:	e2043783          	ld	a5,-480(s0)
    80004fba:	963e                	add	a2,a2,a5
    80004fbc:	f8f667e3          	bltu	a2,a5,80004f4a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fc0:	85ca                	mv	a1,s2
    80004fc2:	855e                	mv	a0,s7
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	5bc080e7          	jalr	1468(ra) # 80001580 <uvmalloc>
    80004fcc:	e0a43423          	sd	a0,-504(s0)
    80004fd0:	d141                	beqz	a0,80004f50 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004fd2:	e2043d03          	ld	s10,-480(s0)
    80004fd6:	df043783          	ld	a5,-528(s0)
    80004fda:	00fd77b3          	and	a5,s10,a5
    80004fde:	fba1                	bnez	a5,80004f2e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fe0:	e1842d83          	lw	s11,-488(s0)
    80004fe4:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fe8:	f80c03e3          	beqz	s8,80004f6e <exec+0x306>
    80004fec:	8a62                	mv	s4,s8
    80004fee:	4901                	li	s2,0
    80004ff0:	b345                	j	80004d90 <exec+0x128>

0000000080004ff2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ff2:	7179                	addi	sp,sp,-48
    80004ff4:	f406                	sd	ra,40(sp)
    80004ff6:	f022                	sd	s0,32(sp)
    80004ff8:	ec26                	sd	s1,24(sp)
    80004ffa:	e84a                	sd	s2,16(sp)
    80004ffc:	1800                	addi	s0,sp,48
    80004ffe:	892e                	mv	s2,a1
    80005000:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005002:	fdc40593          	addi	a1,s0,-36
    80005006:	ffffe097          	auipc	ra,0xffffe
    8000500a:	bae080e7          	jalr	-1106(ra) # 80002bb4 <argint>
    8000500e:	04054063          	bltz	a0,8000504e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005012:	fdc42703          	lw	a4,-36(s0)
    80005016:	47bd                	li	a5,15
    80005018:	02e7ed63          	bltu	a5,a4,80005052 <argfd+0x60>
    8000501c:	ffffd097          	auipc	ra,0xffffd
    80005020:	abc080e7          	jalr	-1348(ra) # 80001ad8 <myproc>
    80005024:	fdc42703          	lw	a4,-36(s0)
    80005028:	01a70793          	addi	a5,a4,26
    8000502c:	078e                	slli	a5,a5,0x3
    8000502e:	953e                	add	a0,a0,a5
    80005030:	611c                	ld	a5,0(a0)
    80005032:	c395                	beqz	a5,80005056 <argfd+0x64>
    return -1;
  if(pfd)
    80005034:	00090463          	beqz	s2,8000503c <argfd+0x4a>
    *pfd = fd;
    80005038:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000503c:	4501                	li	a0,0
  if(pf)
    8000503e:	c091                	beqz	s1,80005042 <argfd+0x50>
    *pf = f;
    80005040:	e09c                	sd	a5,0(s1)
}
    80005042:	70a2                	ld	ra,40(sp)
    80005044:	7402                	ld	s0,32(sp)
    80005046:	64e2                	ld	s1,24(sp)
    80005048:	6942                	ld	s2,16(sp)
    8000504a:	6145                	addi	sp,sp,48
    8000504c:	8082                	ret
    return -1;
    8000504e:	557d                	li	a0,-1
    80005050:	bfcd                	j	80005042 <argfd+0x50>
    return -1;
    80005052:	557d                	li	a0,-1
    80005054:	b7fd                	j	80005042 <argfd+0x50>
    80005056:	557d                	li	a0,-1
    80005058:	b7ed                	j	80005042 <argfd+0x50>

000000008000505a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000505a:	1101                	addi	sp,sp,-32
    8000505c:	ec06                	sd	ra,24(sp)
    8000505e:	e822                	sd	s0,16(sp)
    80005060:	e426                	sd	s1,8(sp)
    80005062:	1000                	addi	s0,sp,32
    80005064:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005066:	ffffd097          	auipc	ra,0xffffd
    8000506a:	a72080e7          	jalr	-1422(ra) # 80001ad8 <myproc>
    8000506e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005070:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7fed90d0>
    80005074:	4501                	li	a0,0
    80005076:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005078:	6398                	ld	a4,0(a5)
    8000507a:	cb19                	beqz	a4,80005090 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000507c:	2505                	addiw	a0,a0,1
    8000507e:	07a1                	addi	a5,a5,8
    80005080:	fed51ce3          	bne	a0,a3,80005078 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005084:	557d                	li	a0,-1
}
    80005086:	60e2                	ld	ra,24(sp)
    80005088:	6442                	ld	s0,16(sp)
    8000508a:	64a2                	ld	s1,8(sp)
    8000508c:	6105                	addi	sp,sp,32
    8000508e:	8082                	ret
      p->ofile[fd] = f;
    80005090:	01a50793          	addi	a5,a0,26
    80005094:	078e                	slli	a5,a5,0x3
    80005096:	963e                	add	a2,a2,a5
    80005098:	e204                	sd	s1,0(a2)
      return fd;
    8000509a:	b7f5                	j	80005086 <fdalloc+0x2c>

000000008000509c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000509c:	715d                	addi	sp,sp,-80
    8000509e:	e486                	sd	ra,72(sp)
    800050a0:	e0a2                	sd	s0,64(sp)
    800050a2:	fc26                	sd	s1,56(sp)
    800050a4:	f84a                	sd	s2,48(sp)
    800050a6:	f44e                	sd	s3,40(sp)
    800050a8:	f052                	sd	s4,32(sp)
    800050aa:	ec56                	sd	s5,24(sp)
    800050ac:	0880                	addi	s0,sp,80
    800050ae:	89ae                	mv	s3,a1
    800050b0:	8ab2                	mv	s5,a2
    800050b2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050b4:	fb040593          	addi	a1,s0,-80
    800050b8:	fffff097          	auipc	ra,0xfffff
    800050bc:	e40080e7          	jalr	-448(ra) # 80003ef8 <nameiparent>
    800050c0:	892a                	mv	s2,a0
    800050c2:	12050f63          	beqz	a0,80005200 <create+0x164>
    return 0;

  ilock(dp);
    800050c6:	ffffe097          	auipc	ra,0xffffe
    800050ca:	660080e7          	jalr	1632(ra) # 80003726 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050ce:	4601                	li	a2,0
    800050d0:	fb040593          	addi	a1,s0,-80
    800050d4:	854a                	mv	a0,s2
    800050d6:	fffff097          	auipc	ra,0xfffff
    800050da:	b32080e7          	jalr	-1230(ra) # 80003c08 <dirlookup>
    800050de:	84aa                	mv	s1,a0
    800050e0:	c921                	beqz	a0,80005130 <create+0x94>
    iunlockput(dp);
    800050e2:	854a                	mv	a0,s2
    800050e4:	fffff097          	auipc	ra,0xfffff
    800050e8:	8a4080e7          	jalr	-1884(ra) # 80003988 <iunlockput>
    ilock(ip);
    800050ec:	8526                	mv	a0,s1
    800050ee:	ffffe097          	auipc	ra,0xffffe
    800050f2:	638080e7          	jalr	1592(ra) # 80003726 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050f6:	2981                	sext.w	s3,s3
    800050f8:	4789                	li	a5,2
    800050fa:	02f99463          	bne	s3,a5,80005122 <create+0x86>
    800050fe:	0444d783          	lhu	a5,68(s1)
    80005102:	37f9                	addiw	a5,a5,-2
    80005104:	17c2                	slli	a5,a5,0x30
    80005106:	93c1                	srli	a5,a5,0x30
    80005108:	4705                	li	a4,1
    8000510a:	00f76c63          	bltu	a4,a5,80005122 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000510e:	8526                	mv	a0,s1
    80005110:	60a6                	ld	ra,72(sp)
    80005112:	6406                	ld	s0,64(sp)
    80005114:	74e2                	ld	s1,56(sp)
    80005116:	7942                	ld	s2,48(sp)
    80005118:	79a2                	ld	s3,40(sp)
    8000511a:	7a02                	ld	s4,32(sp)
    8000511c:	6ae2                	ld	s5,24(sp)
    8000511e:	6161                	addi	sp,sp,80
    80005120:	8082                	ret
    iunlockput(ip);
    80005122:	8526                	mv	a0,s1
    80005124:	fffff097          	auipc	ra,0xfffff
    80005128:	864080e7          	jalr	-1948(ra) # 80003988 <iunlockput>
    return 0;
    8000512c:	4481                	li	s1,0
    8000512e:	b7c5                	j	8000510e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005130:	85ce                	mv	a1,s3
    80005132:	00092503          	lw	a0,0(s2)
    80005136:	ffffe097          	auipc	ra,0xffffe
    8000513a:	458080e7          	jalr	1112(ra) # 8000358e <ialloc>
    8000513e:	84aa                	mv	s1,a0
    80005140:	c529                	beqz	a0,8000518a <create+0xee>
  ilock(ip);
    80005142:	ffffe097          	auipc	ra,0xffffe
    80005146:	5e4080e7          	jalr	1508(ra) # 80003726 <ilock>
  ip->major = major;
    8000514a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000514e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005152:	4785                	li	a5,1
    80005154:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005158:	8526                	mv	a0,s1
    8000515a:	ffffe097          	auipc	ra,0xffffe
    8000515e:	502080e7          	jalr	1282(ra) # 8000365c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005162:	2981                	sext.w	s3,s3
    80005164:	4785                	li	a5,1
    80005166:	02f98a63          	beq	s3,a5,8000519a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000516a:	40d0                	lw	a2,4(s1)
    8000516c:	fb040593          	addi	a1,s0,-80
    80005170:	854a                	mv	a0,s2
    80005172:	fffff097          	auipc	ra,0xfffff
    80005176:	ca6080e7          	jalr	-858(ra) # 80003e18 <dirlink>
    8000517a:	06054b63          	bltz	a0,800051f0 <create+0x154>
  iunlockput(dp);
    8000517e:	854a                	mv	a0,s2
    80005180:	fffff097          	auipc	ra,0xfffff
    80005184:	808080e7          	jalr	-2040(ra) # 80003988 <iunlockput>
  return ip;
    80005188:	b759                	j	8000510e <create+0x72>
    panic("create: ialloc");
    8000518a:	00003517          	auipc	a0,0x3
    8000518e:	54e50513          	addi	a0,a0,1358 # 800086d8 <syscalls+0x2b0>
    80005192:	ffffb097          	auipc	ra,0xffffb
    80005196:	3b6080e7          	jalr	950(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    8000519a:	04a95783          	lhu	a5,74(s2)
    8000519e:	2785                	addiw	a5,a5,1
    800051a0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051a4:	854a                	mv	a0,s2
    800051a6:	ffffe097          	auipc	ra,0xffffe
    800051aa:	4b6080e7          	jalr	1206(ra) # 8000365c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051ae:	40d0                	lw	a2,4(s1)
    800051b0:	00003597          	auipc	a1,0x3
    800051b4:	53858593          	addi	a1,a1,1336 # 800086e8 <syscalls+0x2c0>
    800051b8:	8526                	mv	a0,s1
    800051ba:	fffff097          	auipc	ra,0xfffff
    800051be:	c5e080e7          	jalr	-930(ra) # 80003e18 <dirlink>
    800051c2:	00054f63          	bltz	a0,800051e0 <create+0x144>
    800051c6:	00492603          	lw	a2,4(s2)
    800051ca:	00003597          	auipc	a1,0x3
    800051ce:	52658593          	addi	a1,a1,1318 # 800086f0 <syscalls+0x2c8>
    800051d2:	8526                	mv	a0,s1
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	c44080e7          	jalr	-956(ra) # 80003e18 <dirlink>
    800051dc:	f80557e3          	bgez	a0,8000516a <create+0xce>
      panic("create dots");
    800051e0:	00003517          	auipc	a0,0x3
    800051e4:	51850513          	addi	a0,a0,1304 # 800086f8 <syscalls+0x2d0>
    800051e8:	ffffb097          	auipc	ra,0xffffb
    800051ec:	360080e7          	jalr	864(ra) # 80000548 <panic>
    panic("create: dirlink");
    800051f0:	00003517          	auipc	a0,0x3
    800051f4:	51850513          	addi	a0,a0,1304 # 80008708 <syscalls+0x2e0>
    800051f8:	ffffb097          	auipc	ra,0xffffb
    800051fc:	350080e7          	jalr	848(ra) # 80000548 <panic>
    return 0;
    80005200:	84aa                	mv	s1,a0
    80005202:	b731                	j	8000510e <create+0x72>

0000000080005204 <sys_dup>:
{
    80005204:	7179                	addi	sp,sp,-48
    80005206:	f406                	sd	ra,40(sp)
    80005208:	f022                	sd	s0,32(sp)
    8000520a:	ec26                	sd	s1,24(sp)
    8000520c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000520e:	fd840613          	addi	a2,s0,-40
    80005212:	4581                	li	a1,0
    80005214:	4501                	li	a0,0
    80005216:	00000097          	auipc	ra,0x0
    8000521a:	ddc080e7          	jalr	-548(ra) # 80004ff2 <argfd>
    return -1;
    8000521e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005220:	02054363          	bltz	a0,80005246 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005224:	fd843503          	ld	a0,-40(s0)
    80005228:	00000097          	auipc	ra,0x0
    8000522c:	e32080e7          	jalr	-462(ra) # 8000505a <fdalloc>
    80005230:	84aa                	mv	s1,a0
    return -1;
    80005232:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005234:	00054963          	bltz	a0,80005246 <sys_dup+0x42>
  filedup(f);
    80005238:	fd843503          	ld	a0,-40(s0)
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	32a080e7          	jalr	810(ra) # 80004566 <filedup>
  return fd;
    80005244:	87a6                	mv	a5,s1
}
    80005246:	853e                	mv	a0,a5
    80005248:	70a2                	ld	ra,40(sp)
    8000524a:	7402                	ld	s0,32(sp)
    8000524c:	64e2                	ld	s1,24(sp)
    8000524e:	6145                	addi	sp,sp,48
    80005250:	8082                	ret

0000000080005252 <sys_read>:
{
    80005252:	7179                	addi	sp,sp,-48
    80005254:	f406                	sd	ra,40(sp)
    80005256:	f022                	sd	s0,32(sp)
    80005258:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000525a:	fe840613          	addi	a2,s0,-24
    8000525e:	4581                	li	a1,0
    80005260:	4501                	li	a0,0
    80005262:	00000097          	auipc	ra,0x0
    80005266:	d90080e7          	jalr	-624(ra) # 80004ff2 <argfd>
    return -1;
    8000526a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000526c:	04054163          	bltz	a0,800052ae <sys_read+0x5c>
    80005270:	fe440593          	addi	a1,s0,-28
    80005274:	4509                	li	a0,2
    80005276:	ffffe097          	auipc	ra,0xffffe
    8000527a:	93e080e7          	jalr	-1730(ra) # 80002bb4 <argint>
    return -1;
    8000527e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005280:	02054763          	bltz	a0,800052ae <sys_read+0x5c>
    80005284:	fd840593          	addi	a1,s0,-40
    80005288:	4505                	li	a0,1
    8000528a:	ffffe097          	auipc	ra,0xffffe
    8000528e:	94c080e7          	jalr	-1716(ra) # 80002bd6 <argaddr>
    return -1;
    80005292:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005294:	00054d63          	bltz	a0,800052ae <sys_read+0x5c>
  return fileread(f, p, n);
    80005298:	fe442603          	lw	a2,-28(s0)
    8000529c:	fd843583          	ld	a1,-40(s0)
    800052a0:	fe843503          	ld	a0,-24(s0)
    800052a4:	fffff097          	auipc	ra,0xfffff
    800052a8:	44e080e7          	jalr	1102(ra) # 800046f2 <fileread>
    800052ac:	87aa                	mv	a5,a0
}
    800052ae:	853e                	mv	a0,a5
    800052b0:	70a2                	ld	ra,40(sp)
    800052b2:	7402                	ld	s0,32(sp)
    800052b4:	6145                	addi	sp,sp,48
    800052b6:	8082                	ret

00000000800052b8 <sys_write>:
{
    800052b8:	7179                	addi	sp,sp,-48
    800052ba:	f406                	sd	ra,40(sp)
    800052bc:	f022                	sd	s0,32(sp)
    800052be:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c0:	fe840613          	addi	a2,s0,-24
    800052c4:	4581                	li	a1,0
    800052c6:	4501                	li	a0,0
    800052c8:	00000097          	auipc	ra,0x0
    800052cc:	d2a080e7          	jalr	-726(ra) # 80004ff2 <argfd>
    return -1;
    800052d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d2:	04054163          	bltz	a0,80005314 <sys_write+0x5c>
    800052d6:	fe440593          	addi	a1,s0,-28
    800052da:	4509                	li	a0,2
    800052dc:	ffffe097          	auipc	ra,0xffffe
    800052e0:	8d8080e7          	jalr	-1832(ra) # 80002bb4 <argint>
    return -1;
    800052e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e6:	02054763          	bltz	a0,80005314 <sys_write+0x5c>
    800052ea:	fd840593          	addi	a1,s0,-40
    800052ee:	4505                	li	a0,1
    800052f0:	ffffe097          	auipc	ra,0xffffe
    800052f4:	8e6080e7          	jalr	-1818(ra) # 80002bd6 <argaddr>
    return -1;
    800052f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fa:	00054d63          	bltz	a0,80005314 <sys_write+0x5c>
  return filewrite(f, p, n);
    800052fe:	fe442603          	lw	a2,-28(s0)
    80005302:	fd843583          	ld	a1,-40(s0)
    80005306:	fe843503          	ld	a0,-24(s0)
    8000530a:	fffff097          	auipc	ra,0xfffff
    8000530e:	4aa080e7          	jalr	1194(ra) # 800047b4 <filewrite>
    80005312:	87aa                	mv	a5,a0
}
    80005314:	853e                	mv	a0,a5
    80005316:	70a2                	ld	ra,40(sp)
    80005318:	7402                	ld	s0,32(sp)
    8000531a:	6145                	addi	sp,sp,48
    8000531c:	8082                	ret

000000008000531e <sys_close>:
{
    8000531e:	1101                	addi	sp,sp,-32
    80005320:	ec06                	sd	ra,24(sp)
    80005322:	e822                	sd	s0,16(sp)
    80005324:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005326:	fe040613          	addi	a2,s0,-32
    8000532a:	fec40593          	addi	a1,s0,-20
    8000532e:	4501                	li	a0,0
    80005330:	00000097          	auipc	ra,0x0
    80005334:	cc2080e7          	jalr	-830(ra) # 80004ff2 <argfd>
    return -1;
    80005338:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000533a:	02054463          	bltz	a0,80005362 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000533e:	ffffc097          	auipc	ra,0xffffc
    80005342:	79a080e7          	jalr	1946(ra) # 80001ad8 <myproc>
    80005346:	fec42783          	lw	a5,-20(s0)
    8000534a:	07e9                	addi	a5,a5,26
    8000534c:	078e                	slli	a5,a5,0x3
    8000534e:	97aa                	add	a5,a5,a0
    80005350:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005354:	fe043503          	ld	a0,-32(s0)
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	260080e7          	jalr	608(ra) # 800045b8 <fileclose>
  return 0;
    80005360:	4781                	li	a5,0
}
    80005362:	853e                	mv	a0,a5
    80005364:	60e2                	ld	ra,24(sp)
    80005366:	6442                	ld	s0,16(sp)
    80005368:	6105                	addi	sp,sp,32
    8000536a:	8082                	ret

000000008000536c <sys_fstat>:
{
    8000536c:	1101                	addi	sp,sp,-32
    8000536e:	ec06                	sd	ra,24(sp)
    80005370:	e822                	sd	s0,16(sp)
    80005372:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005374:	fe840613          	addi	a2,s0,-24
    80005378:	4581                	li	a1,0
    8000537a:	4501                	li	a0,0
    8000537c:	00000097          	auipc	ra,0x0
    80005380:	c76080e7          	jalr	-906(ra) # 80004ff2 <argfd>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005386:	02054563          	bltz	a0,800053b0 <sys_fstat+0x44>
    8000538a:	fe040593          	addi	a1,s0,-32
    8000538e:	4505                	li	a0,1
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	846080e7          	jalr	-1978(ra) # 80002bd6 <argaddr>
    return -1;
    80005398:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000539a:	00054b63          	bltz	a0,800053b0 <sys_fstat+0x44>
  return filestat(f, st);
    8000539e:	fe043583          	ld	a1,-32(s0)
    800053a2:	fe843503          	ld	a0,-24(s0)
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	2da080e7          	jalr	730(ra) # 80004680 <filestat>
    800053ae:	87aa                	mv	a5,a0
}
    800053b0:	853e                	mv	a0,a5
    800053b2:	60e2                	ld	ra,24(sp)
    800053b4:	6442                	ld	s0,16(sp)
    800053b6:	6105                	addi	sp,sp,32
    800053b8:	8082                	ret

00000000800053ba <sys_link>:
{
    800053ba:	7169                	addi	sp,sp,-304
    800053bc:	f606                	sd	ra,296(sp)
    800053be:	f222                	sd	s0,288(sp)
    800053c0:	ee26                	sd	s1,280(sp)
    800053c2:	ea4a                	sd	s2,272(sp)
    800053c4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053c6:	08000613          	li	a2,128
    800053ca:	ed040593          	addi	a1,s0,-304
    800053ce:	4501                	li	a0,0
    800053d0:	ffffe097          	auipc	ra,0xffffe
    800053d4:	828080e7          	jalr	-2008(ra) # 80002bf8 <argstr>
    return -1;
    800053d8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053da:	10054e63          	bltz	a0,800054f6 <sys_link+0x13c>
    800053de:	08000613          	li	a2,128
    800053e2:	f5040593          	addi	a1,s0,-176
    800053e6:	4505                	li	a0,1
    800053e8:	ffffe097          	auipc	ra,0xffffe
    800053ec:	810080e7          	jalr	-2032(ra) # 80002bf8 <argstr>
    return -1;
    800053f0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053f2:	10054263          	bltz	a0,800054f6 <sys_link+0x13c>
  begin_op();
    800053f6:	fffff097          	auipc	ra,0xfffff
    800053fa:	cf0080e7          	jalr	-784(ra) # 800040e6 <begin_op>
  if((ip = namei(old)) == 0){
    800053fe:	ed040513          	addi	a0,s0,-304
    80005402:	fffff097          	auipc	ra,0xfffff
    80005406:	ad8080e7          	jalr	-1320(ra) # 80003eda <namei>
    8000540a:	84aa                	mv	s1,a0
    8000540c:	c551                	beqz	a0,80005498 <sys_link+0xde>
  ilock(ip);
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	318080e7          	jalr	792(ra) # 80003726 <ilock>
  if(ip->type == T_DIR){
    80005416:	04449703          	lh	a4,68(s1)
    8000541a:	4785                	li	a5,1
    8000541c:	08f70463          	beq	a4,a5,800054a4 <sys_link+0xea>
  ip->nlink++;
    80005420:	04a4d783          	lhu	a5,74(s1)
    80005424:	2785                	addiw	a5,a5,1
    80005426:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000542a:	8526                	mv	a0,s1
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	230080e7          	jalr	560(ra) # 8000365c <iupdate>
  iunlock(ip);
    80005434:	8526                	mv	a0,s1
    80005436:	ffffe097          	auipc	ra,0xffffe
    8000543a:	3b2080e7          	jalr	946(ra) # 800037e8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000543e:	fd040593          	addi	a1,s0,-48
    80005442:	f5040513          	addi	a0,s0,-176
    80005446:	fffff097          	auipc	ra,0xfffff
    8000544a:	ab2080e7          	jalr	-1358(ra) # 80003ef8 <nameiparent>
    8000544e:	892a                	mv	s2,a0
    80005450:	c935                	beqz	a0,800054c4 <sys_link+0x10a>
  ilock(dp);
    80005452:	ffffe097          	auipc	ra,0xffffe
    80005456:	2d4080e7          	jalr	724(ra) # 80003726 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000545a:	00092703          	lw	a4,0(s2)
    8000545e:	409c                	lw	a5,0(s1)
    80005460:	04f71d63          	bne	a4,a5,800054ba <sys_link+0x100>
    80005464:	40d0                	lw	a2,4(s1)
    80005466:	fd040593          	addi	a1,s0,-48
    8000546a:	854a                	mv	a0,s2
    8000546c:	fffff097          	auipc	ra,0xfffff
    80005470:	9ac080e7          	jalr	-1620(ra) # 80003e18 <dirlink>
    80005474:	04054363          	bltz	a0,800054ba <sys_link+0x100>
  iunlockput(dp);
    80005478:	854a                	mv	a0,s2
    8000547a:	ffffe097          	auipc	ra,0xffffe
    8000547e:	50e080e7          	jalr	1294(ra) # 80003988 <iunlockput>
  iput(ip);
    80005482:	8526                	mv	a0,s1
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	45c080e7          	jalr	1116(ra) # 800038e0 <iput>
  end_op();
    8000548c:	fffff097          	auipc	ra,0xfffff
    80005490:	cda080e7          	jalr	-806(ra) # 80004166 <end_op>
  return 0;
    80005494:	4781                	li	a5,0
    80005496:	a085                	j	800054f6 <sys_link+0x13c>
    end_op();
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	cce080e7          	jalr	-818(ra) # 80004166 <end_op>
    return -1;
    800054a0:	57fd                	li	a5,-1
    800054a2:	a891                	j	800054f6 <sys_link+0x13c>
    iunlockput(ip);
    800054a4:	8526                	mv	a0,s1
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	4e2080e7          	jalr	1250(ra) # 80003988 <iunlockput>
    end_op();
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	cb8080e7          	jalr	-840(ra) # 80004166 <end_op>
    return -1;
    800054b6:	57fd                	li	a5,-1
    800054b8:	a83d                	j	800054f6 <sys_link+0x13c>
    iunlockput(dp);
    800054ba:	854a                	mv	a0,s2
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	4cc080e7          	jalr	1228(ra) # 80003988 <iunlockput>
  ilock(ip);
    800054c4:	8526                	mv	a0,s1
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	260080e7          	jalr	608(ra) # 80003726 <ilock>
  ip->nlink--;
    800054ce:	04a4d783          	lhu	a5,74(s1)
    800054d2:	37fd                	addiw	a5,a5,-1
    800054d4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054d8:	8526                	mv	a0,s1
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	182080e7          	jalr	386(ra) # 8000365c <iupdate>
  iunlockput(ip);
    800054e2:	8526                	mv	a0,s1
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	4a4080e7          	jalr	1188(ra) # 80003988 <iunlockput>
  end_op();
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	c7a080e7          	jalr	-902(ra) # 80004166 <end_op>
  return -1;
    800054f4:	57fd                	li	a5,-1
}
    800054f6:	853e                	mv	a0,a5
    800054f8:	70b2                	ld	ra,296(sp)
    800054fa:	7412                	ld	s0,288(sp)
    800054fc:	64f2                	ld	s1,280(sp)
    800054fe:	6952                	ld	s2,272(sp)
    80005500:	6155                	addi	sp,sp,304
    80005502:	8082                	ret

0000000080005504 <sys_unlink>:
{
    80005504:	7151                	addi	sp,sp,-240
    80005506:	f586                	sd	ra,232(sp)
    80005508:	f1a2                	sd	s0,224(sp)
    8000550a:	eda6                	sd	s1,216(sp)
    8000550c:	e9ca                	sd	s2,208(sp)
    8000550e:	e5ce                	sd	s3,200(sp)
    80005510:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005512:	08000613          	li	a2,128
    80005516:	f3040593          	addi	a1,s0,-208
    8000551a:	4501                	li	a0,0
    8000551c:	ffffd097          	auipc	ra,0xffffd
    80005520:	6dc080e7          	jalr	1756(ra) # 80002bf8 <argstr>
    80005524:	18054163          	bltz	a0,800056a6 <sys_unlink+0x1a2>
  begin_op();
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	bbe080e7          	jalr	-1090(ra) # 800040e6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005530:	fb040593          	addi	a1,s0,-80
    80005534:	f3040513          	addi	a0,s0,-208
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	9c0080e7          	jalr	-1600(ra) # 80003ef8 <nameiparent>
    80005540:	84aa                	mv	s1,a0
    80005542:	c979                	beqz	a0,80005618 <sys_unlink+0x114>
  ilock(dp);
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	1e2080e7          	jalr	482(ra) # 80003726 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000554c:	00003597          	auipc	a1,0x3
    80005550:	19c58593          	addi	a1,a1,412 # 800086e8 <syscalls+0x2c0>
    80005554:	fb040513          	addi	a0,s0,-80
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	696080e7          	jalr	1686(ra) # 80003bee <namecmp>
    80005560:	14050a63          	beqz	a0,800056b4 <sys_unlink+0x1b0>
    80005564:	00003597          	auipc	a1,0x3
    80005568:	18c58593          	addi	a1,a1,396 # 800086f0 <syscalls+0x2c8>
    8000556c:	fb040513          	addi	a0,s0,-80
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	67e080e7          	jalr	1662(ra) # 80003bee <namecmp>
    80005578:	12050e63          	beqz	a0,800056b4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000557c:	f2c40613          	addi	a2,s0,-212
    80005580:	fb040593          	addi	a1,s0,-80
    80005584:	8526                	mv	a0,s1
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	682080e7          	jalr	1666(ra) # 80003c08 <dirlookup>
    8000558e:	892a                	mv	s2,a0
    80005590:	12050263          	beqz	a0,800056b4 <sys_unlink+0x1b0>
  ilock(ip);
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	192080e7          	jalr	402(ra) # 80003726 <ilock>
  if(ip->nlink < 1)
    8000559c:	04a91783          	lh	a5,74(s2)
    800055a0:	08f05263          	blez	a5,80005624 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055a4:	04491703          	lh	a4,68(s2)
    800055a8:	4785                	li	a5,1
    800055aa:	08f70563          	beq	a4,a5,80005634 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055ae:	4641                	li	a2,16
    800055b0:	4581                	li	a1,0
    800055b2:	fc040513          	addi	a0,s0,-64
    800055b6:	ffffb097          	auipc	ra,0xffffb
    800055ba:	784080e7          	jalr	1924(ra) # 80000d3a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055be:	4741                	li	a4,16
    800055c0:	f2c42683          	lw	a3,-212(s0)
    800055c4:	fc040613          	addi	a2,s0,-64
    800055c8:	4581                	li	a1,0
    800055ca:	8526                	mv	a0,s1
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	506080e7          	jalr	1286(ra) # 80003ad2 <writei>
    800055d4:	47c1                	li	a5,16
    800055d6:	0af51563          	bne	a0,a5,80005680 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055da:	04491703          	lh	a4,68(s2)
    800055de:	4785                	li	a5,1
    800055e0:	0af70863          	beq	a4,a5,80005690 <sys_unlink+0x18c>
  iunlockput(dp);
    800055e4:	8526                	mv	a0,s1
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	3a2080e7          	jalr	930(ra) # 80003988 <iunlockput>
  ip->nlink--;
    800055ee:	04a95783          	lhu	a5,74(s2)
    800055f2:	37fd                	addiw	a5,a5,-1
    800055f4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055f8:	854a                	mv	a0,s2
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	062080e7          	jalr	98(ra) # 8000365c <iupdate>
  iunlockput(ip);
    80005602:	854a                	mv	a0,s2
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	384080e7          	jalr	900(ra) # 80003988 <iunlockput>
  end_op();
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	b5a080e7          	jalr	-1190(ra) # 80004166 <end_op>
  return 0;
    80005614:	4501                	li	a0,0
    80005616:	a84d                	j	800056c8 <sys_unlink+0x1c4>
    end_op();
    80005618:	fffff097          	auipc	ra,0xfffff
    8000561c:	b4e080e7          	jalr	-1202(ra) # 80004166 <end_op>
    return -1;
    80005620:	557d                	li	a0,-1
    80005622:	a05d                	j	800056c8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005624:	00003517          	auipc	a0,0x3
    80005628:	0f450513          	addi	a0,a0,244 # 80008718 <syscalls+0x2f0>
    8000562c:	ffffb097          	auipc	ra,0xffffb
    80005630:	f1c080e7          	jalr	-228(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005634:	04c92703          	lw	a4,76(s2)
    80005638:	02000793          	li	a5,32
    8000563c:	f6e7f9e3          	bgeu	a5,a4,800055ae <sys_unlink+0xaa>
    80005640:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005644:	4741                	li	a4,16
    80005646:	86ce                	mv	a3,s3
    80005648:	f1840613          	addi	a2,s0,-232
    8000564c:	4581                	li	a1,0
    8000564e:	854a                	mv	a0,s2
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	38a080e7          	jalr	906(ra) # 800039da <readi>
    80005658:	47c1                	li	a5,16
    8000565a:	00f51b63          	bne	a0,a5,80005670 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000565e:	f1845783          	lhu	a5,-232(s0)
    80005662:	e7a1                	bnez	a5,800056aa <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005664:	29c1                	addiw	s3,s3,16
    80005666:	04c92783          	lw	a5,76(s2)
    8000566a:	fcf9ede3          	bltu	s3,a5,80005644 <sys_unlink+0x140>
    8000566e:	b781                	j	800055ae <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005670:	00003517          	auipc	a0,0x3
    80005674:	0c050513          	addi	a0,a0,192 # 80008730 <syscalls+0x308>
    80005678:	ffffb097          	auipc	ra,0xffffb
    8000567c:	ed0080e7          	jalr	-304(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005680:	00003517          	auipc	a0,0x3
    80005684:	0c850513          	addi	a0,a0,200 # 80008748 <syscalls+0x320>
    80005688:	ffffb097          	auipc	ra,0xffffb
    8000568c:	ec0080e7          	jalr	-320(ra) # 80000548 <panic>
    dp->nlink--;
    80005690:	04a4d783          	lhu	a5,74(s1)
    80005694:	37fd                	addiw	a5,a5,-1
    80005696:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000569a:	8526                	mv	a0,s1
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	fc0080e7          	jalr	-64(ra) # 8000365c <iupdate>
    800056a4:	b781                	j	800055e4 <sys_unlink+0xe0>
    return -1;
    800056a6:	557d                	li	a0,-1
    800056a8:	a005                	j	800056c8 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056aa:	854a                	mv	a0,s2
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	2dc080e7          	jalr	732(ra) # 80003988 <iunlockput>
  iunlockput(dp);
    800056b4:	8526                	mv	a0,s1
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	2d2080e7          	jalr	722(ra) # 80003988 <iunlockput>
  end_op();
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	aa8080e7          	jalr	-1368(ra) # 80004166 <end_op>
  return -1;
    800056c6:	557d                	li	a0,-1
}
    800056c8:	70ae                	ld	ra,232(sp)
    800056ca:	740e                	ld	s0,224(sp)
    800056cc:	64ee                	ld	s1,216(sp)
    800056ce:	694e                	ld	s2,208(sp)
    800056d0:	69ae                	ld	s3,200(sp)
    800056d2:	616d                	addi	sp,sp,240
    800056d4:	8082                	ret

00000000800056d6 <sys_open>:

uint64
sys_open(void)
{
    800056d6:	7131                	addi	sp,sp,-192
    800056d8:	fd06                	sd	ra,184(sp)
    800056da:	f922                	sd	s0,176(sp)
    800056dc:	f526                	sd	s1,168(sp)
    800056de:	f14a                	sd	s2,160(sp)
    800056e0:	ed4e                	sd	s3,152(sp)
    800056e2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056e4:	08000613          	li	a2,128
    800056e8:	f5040593          	addi	a1,s0,-176
    800056ec:	4501                	li	a0,0
    800056ee:	ffffd097          	auipc	ra,0xffffd
    800056f2:	50a080e7          	jalr	1290(ra) # 80002bf8 <argstr>
    return -1;
    800056f6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056f8:	0c054163          	bltz	a0,800057ba <sys_open+0xe4>
    800056fc:	f4c40593          	addi	a1,s0,-180
    80005700:	4505                	li	a0,1
    80005702:	ffffd097          	auipc	ra,0xffffd
    80005706:	4b2080e7          	jalr	1202(ra) # 80002bb4 <argint>
    8000570a:	0a054863          	bltz	a0,800057ba <sys_open+0xe4>

  begin_op();
    8000570e:	fffff097          	auipc	ra,0xfffff
    80005712:	9d8080e7          	jalr	-1576(ra) # 800040e6 <begin_op>

  if(omode & O_CREATE){
    80005716:	f4c42783          	lw	a5,-180(s0)
    8000571a:	2007f793          	andi	a5,a5,512
    8000571e:	cbdd                	beqz	a5,800057d4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005720:	4681                	li	a3,0
    80005722:	4601                	li	a2,0
    80005724:	4589                	li	a1,2
    80005726:	f5040513          	addi	a0,s0,-176
    8000572a:	00000097          	auipc	ra,0x0
    8000572e:	972080e7          	jalr	-1678(ra) # 8000509c <create>
    80005732:	892a                	mv	s2,a0
    if(ip == 0){
    80005734:	c959                	beqz	a0,800057ca <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005736:	04491703          	lh	a4,68(s2)
    8000573a:	478d                	li	a5,3
    8000573c:	00f71763          	bne	a4,a5,8000574a <sys_open+0x74>
    80005740:	04695703          	lhu	a4,70(s2)
    80005744:	47a5                	li	a5,9
    80005746:	0ce7ec63          	bltu	a5,a4,8000581e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	db2080e7          	jalr	-590(ra) # 800044fc <filealloc>
    80005752:	89aa                	mv	s3,a0
    80005754:	10050263          	beqz	a0,80005858 <sys_open+0x182>
    80005758:	00000097          	auipc	ra,0x0
    8000575c:	902080e7          	jalr	-1790(ra) # 8000505a <fdalloc>
    80005760:	84aa                	mv	s1,a0
    80005762:	0e054663          	bltz	a0,8000584e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005766:	04491703          	lh	a4,68(s2)
    8000576a:	478d                	li	a5,3
    8000576c:	0cf70463          	beq	a4,a5,80005834 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005770:	4789                	li	a5,2
    80005772:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005776:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000577a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000577e:	f4c42783          	lw	a5,-180(s0)
    80005782:	0017c713          	xori	a4,a5,1
    80005786:	8b05                	andi	a4,a4,1
    80005788:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000578c:	0037f713          	andi	a4,a5,3
    80005790:	00e03733          	snez	a4,a4
    80005794:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005798:	4007f793          	andi	a5,a5,1024
    8000579c:	c791                	beqz	a5,800057a8 <sys_open+0xd2>
    8000579e:	04491703          	lh	a4,68(s2)
    800057a2:	4789                	li	a5,2
    800057a4:	08f70f63          	beq	a4,a5,80005842 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057a8:	854a                	mv	a0,s2
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	03e080e7          	jalr	62(ra) # 800037e8 <iunlock>
  end_op();
    800057b2:	fffff097          	auipc	ra,0xfffff
    800057b6:	9b4080e7          	jalr	-1612(ra) # 80004166 <end_op>

  return fd;
}
    800057ba:	8526                	mv	a0,s1
    800057bc:	70ea                	ld	ra,184(sp)
    800057be:	744a                	ld	s0,176(sp)
    800057c0:	74aa                	ld	s1,168(sp)
    800057c2:	790a                	ld	s2,160(sp)
    800057c4:	69ea                	ld	s3,152(sp)
    800057c6:	6129                	addi	sp,sp,192
    800057c8:	8082                	ret
      end_op();
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	99c080e7          	jalr	-1636(ra) # 80004166 <end_op>
      return -1;
    800057d2:	b7e5                	j	800057ba <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057d4:	f5040513          	addi	a0,s0,-176
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	702080e7          	jalr	1794(ra) # 80003eda <namei>
    800057e0:	892a                	mv	s2,a0
    800057e2:	c905                	beqz	a0,80005812 <sys_open+0x13c>
    ilock(ip);
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	f42080e7          	jalr	-190(ra) # 80003726 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057ec:	04491703          	lh	a4,68(s2)
    800057f0:	4785                	li	a5,1
    800057f2:	f4f712e3          	bne	a4,a5,80005736 <sys_open+0x60>
    800057f6:	f4c42783          	lw	a5,-180(s0)
    800057fa:	dba1                	beqz	a5,8000574a <sys_open+0x74>
      iunlockput(ip);
    800057fc:	854a                	mv	a0,s2
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	18a080e7          	jalr	394(ra) # 80003988 <iunlockput>
      end_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	960080e7          	jalr	-1696(ra) # 80004166 <end_op>
      return -1;
    8000580e:	54fd                	li	s1,-1
    80005810:	b76d                	j	800057ba <sys_open+0xe4>
      end_op();
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	954080e7          	jalr	-1708(ra) # 80004166 <end_op>
      return -1;
    8000581a:	54fd                	li	s1,-1
    8000581c:	bf79                	j	800057ba <sys_open+0xe4>
    iunlockput(ip);
    8000581e:	854a                	mv	a0,s2
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	168080e7          	jalr	360(ra) # 80003988 <iunlockput>
    end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	93e080e7          	jalr	-1730(ra) # 80004166 <end_op>
    return -1;
    80005830:	54fd                	li	s1,-1
    80005832:	b761                	j	800057ba <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005834:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005838:	04691783          	lh	a5,70(s2)
    8000583c:	02f99223          	sh	a5,36(s3)
    80005840:	bf2d                	j	8000577a <sys_open+0xa4>
    itrunc(ip);
    80005842:	854a                	mv	a0,s2
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	ff0080e7          	jalr	-16(ra) # 80003834 <itrunc>
    8000584c:	bfb1                	j	800057a8 <sys_open+0xd2>
      fileclose(f);
    8000584e:	854e                	mv	a0,s3
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	d68080e7          	jalr	-664(ra) # 800045b8 <fileclose>
    iunlockput(ip);
    80005858:	854a                	mv	a0,s2
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	12e080e7          	jalr	302(ra) # 80003988 <iunlockput>
    end_op();
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	904080e7          	jalr	-1788(ra) # 80004166 <end_op>
    return -1;
    8000586a:	54fd                	li	s1,-1
    8000586c:	b7b9                	j	800057ba <sys_open+0xe4>

000000008000586e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000586e:	7175                	addi	sp,sp,-144
    80005870:	e506                	sd	ra,136(sp)
    80005872:	e122                	sd	s0,128(sp)
    80005874:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	870080e7          	jalr	-1936(ra) # 800040e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000587e:	08000613          	li	a2,128
    80005882:	f7040593          	addi	a1,s0,-144
    80005886:	4501                	li	a0,0
    80005888:	ffffd097          	auipc	ra,0xffffd
    8000588c:	370080e7          	jalr	880(ra) # 80002bf8 <argstr>
    80005890:	02054963          	bltz	a0,800058c2 <sys_mkdir+0x54>
    80005894:	4681                	li	a3,0
    80005896:	4601                	li	a2,0
    80005898:	4585                	li	a1,1
    8000589a:	f7040513          	addi	a0,s0,-144
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	7fe080e7          	jalr	2046(ra) # 8000509c <create>
    800058a6:	cd11                	beqz	a0,800058c2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	0e0080e7          	jalr	224(ra) # 80003988 <iunlockput>
  end_op();
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	8b6080e7          	jalr	-1866(ra) # 80004166 <end_op>
  return 0;
    800058b8:	4501                	li	a0,0
}
    800058ba:	60aa                	ld	ra,136(sp)
    800058bc:	640a                	ld	s0,128(sp)
    800058be:	6149                	addi	sp,sp,144
    800058c0:	8082                	ret
    end_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	8a4080e7          	jalr	-1884(ra) # 80004166 <end_op>
    return -1;
    800058ca:	557d                	li	a0,-1
    800058cc:	b7fd                	j	800058ba <sys_mkdir+0x4c>

00000000800058ce <sys_mknod>:

uint64
sys_mknod(void)
{
    800058ce:	7135                	addi	sp,sp,-160
    800058d0:	ed06                	sd	ra,152(sp)
    800058d2:	e922                	sd	s0,144(sp)
    800058d4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	810080e7          	jalr	-2032(ra) # 800040e6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058de:	08000613          	li	a2,128
    800058e2:	f7040593          	addi	a1,s0,-144
    800058e6:	4501                	li	a0,0
    800058e8:	ffffd097          	auipc	ra,0xffffd
    800058ec:	310080e7          	jalr	784(ra) # 80002bf8 <argstr>
    800058f0:	04054a63          	bltz	a0,80005944 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058f4:	f6c40593          	addi	a1,s0,-148
    800058f8:	4505                	li	a0,1
    800058fa:	ffffd097          	auipc	ra,0xffffd
    800058fe:	2ba080e7          	jalr	698(ra) # 80002bb4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005902:	04054163          	bltz	a0,80005944 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005906:	f6840593          	addi	a1,s0,-152
    8000590a:	4509                	li	a0,2
    8000590c:	ffffd097          	auipc	ra,0xffffd
    80005910:	2a8080e7          	jalr	680(ra) # 80002bb4 <argint>
     argint(1, &major) < 0 ||
    80005914:	02054863          	bltz	a0,80005944 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005918:	f6841683          	lh	a3,-152(s0)
    8000591c:	f6c41603          	lh	a2,-148(s0)
    80005920:	458d                	li	a1,3
    80005922:	f7040513          	addi	a0,s0,-144
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	776080e7          	jalr	1910(ra) # 8000509c <create>
     argint(2, &minor) < 0 ||
    8000592e:	c919                	beqz	a0,80005944 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	058080e7          	jalr	88(ra) # 80003988 <iunlockput>
  end_op();
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	82e080e7          	jalr	-2002(ra) # 80004166 <end_op>
  return 0;
    80005940:	4501                	li	a0,0
    80005942:	a031                	j	8000594e <sys_mknod+0x80>
    end_op();
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	822080e7          	jalr	-2014(ra) # 80004166 <end_op>
    return -1;
    8000594c:	557d                	li	a0,-1
}
    8000594e:	60ea                	ld	ra,152(sp)
    80005950:	644a                	ld	s0,144(sp)
    80005952:	610d                	addi	sp,sp,160
    80005954:	8082                	ret

0000000080005956 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005956:	7135                	addi	sp,sp,-160
    80005958:	ed06                	sd	ra,152(sp)
    8000595a:	e922                	sd	s0,144(sp)
    8000595c:	e526                	sd	s1,136(sp)
    8000595e:	e14a                	sd	s2,128(sp)
    80005960:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005962:	ffffc097          	auipc	ra,0xffffc
    80005966:	176080e7          	jalr	374(ra) # 80001ad8 <myproc>
    8000596a:	892a                	mv	s2,a0
  
  begin_op();
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	77a080e7          	jalr	1914(ra) # 800040e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005974:	08000613          	li	a2,128
    80005978:	f6040593          	addi	a1,s0,-160
    8000597c:	4501                	li	a0,0
    8000597e:	ffffd097          	auipc	ra,0xffffd
    80005982:	27a080e7          	jalr	634(ra) # 80002bf8 <argstr>
    80005986:	04054b63          	bltz	a0,800059dc <sys_chdir+0x86>
    8000598a:	f6040513          	addi	a0,s0,-160
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	54c080e7          	jalr	1356(ra) # 80003eda <namei>
    80005996:	84aa                	mv	s1,a0
    80005998:	c131                	beqz	a0,800059dc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	d8c080e7          	jalr	-628(ra) # 80003726 <ilock>
  if(ip->type != T_DIR){
    800059a2:	04449703          	lh	a4,68(s1)
    800059a6:	4785                	li	a5,1
    800059a8:	04f71063          	bne	a4,a5,800059e8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059ac:	8526                	mv	a0,s1
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	e3a080e7          	jalr	-454(ra) # 800037e8 <iunlock>
  iput(p->cwd);
    800059b6:	15093503          	ld	a0,336(s2)
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	f26080e7          	jalr	-218(ra) # 800038e0 <iput>
  end_op();
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	7a4080e7          	jalr	1956(ra) # 80004166 <end_op>
  p->cwd = ip;
    800059ca:	14993823          	sd	s1,336(s2)
  return 0;
    800059ce:	4501                	li	a0,0
}
    800059d0:	60ea                	ld	ra,152(sp)
    800059d2:	644a                	ld	s0,144(sp)
    800059d4:	64aa                	ld	s1,136(sp)
    800059d6:	690a                	ld	s2,128(sp)
    800059d8:	610d                	addi	sp,sp,160
    800059da:	8082                	ret
    end_op();
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	78a080e7          	jalr	1930(ra) # 80004166 <end_op>
    return -1;
    800059e4:	557d                	li	a0,-1
    800059e6:	b7ed                	j	800059d0 <sys_chdir+0x7a>
    iunlockput(ip);
    800059e8:	8526                	mv	a0,s1
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	f9e080e7          	jalr	-98(ra) # 80003988 <iunlockput>
    end_op();
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	774080e7          	jalr	1908(ra) # 80004166 <end_op>
    return -1;
    800059fa:	557d                	li	a0,-1
    800059fc:	bfd1                	j	800059d0 <sys_chdir+0x7a>

00000000800059fe <sys_exec>:

uint64
sys_exec(void)
{
    800059fe:	7145                	addi	sp,sp,-464
    80005a00:	e786                	sd	ra,456(sp)
    80005a02:	e3a2                	sd	s0,448(sp)
    80005a04:	ff26                	sd	s1,440(sp)
    80005a06:	fb4a                	sd	s2,432(sp)
    80005a08:	f74e                	sd	s3,424(sp)
    80005a0a:	f352                	sd	s4,416(sp)
    80005a0c:	ef56                	sd	s5,408(sp)
    80005a0e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a10:	08000613          	li	a2,128
    80005a14:	f4040593          	addi	a1,s0,-192
    80005a18:	4501                	li	a0,0
    80005a1a:	ffffd097          	auipc	ra,0xffffd
    80005a1e:	1de080e7          	jalr	478(ra) # 80002bf8 <argstr>
    return -1;
    80005a22:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a24:	0c054a63          	bltz	a0,80005af8 <sys_exec+0xfa>
    80005a28:	e3840593          	addi	a1,s0,-456
    80005a2c:	4505                	li	a0,1
    80005a2e:	ffffd097          	auipc	ra,0xffffd
    80005a32:	1a8080e7          	jalr	424(ra) # 80002bd6 <argaddr>
    80005a36:	0c054163          	bltz	a0,80005af8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a3a:	10000613          	li	a2,256
    80005a3e:	4581                	li	a1,0
    80005a40:	e4040513          	addi	a0,s0,-448
    80005a44:	ffffb097          	auipc	ra,0xffffb
    80005a48:	2f6080e7          	jalr	758(ra) # 80000d3a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a4c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a50:	89a6                	mv	s3,s1
    80005a52:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a54:	02000a13          	li	s4,32
    80005a58:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a5c:	00391513          	slli	a0,s2,0x3
    80005a60:	e3040593          	addi	a1,s0,-464
    80005a64:	e3843783          	ld	a5,-456(s0)
    80005a68:	953e                	add	a0,a0,a5
    80005a6a:	ffffd097          	auipc	ra,0xffffd
    80005a6e:	0b0080e7          	jalr	176(ra) # 80002b1a <fetchaddr>
    80005a72:	02054a63          	bltz	a0,80005aa6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a76:	e3043783          	ld	a5,-464(s0)
    80005a7a:	c3b9                	beqz	a5,80005ac0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a7c:	ffffb097          	auipc	ra,0xffffb
    80005a80:	0be080e7          	jalr	190(ra) # 80000b3a <kalloc>
    80005a84:	85aa                	mv	a1,a0
    80005a86:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a8a:	cd11                	beqz	a0,80005aa6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a8c:	6605                	lui	a2,0x1
    80005a8e:	e3043503          	ld	a0,-464(s0)
    80005a92:	ffffd097          	auipc	ra,0xffffd
    80005a96:	0da080e7          	jalr	218(ra) # 80002b6c <fetchstr>
    80005a9a:	00054663          	bltz	a0,80005aa6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a9e:	0905                	addi	s2,s2,1
    80005aa0:	09a1                	addi	s3,s3,8
    80005aa2:	fb491be3          	bne	s2,s4,80005a58 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa6:	10048913          	addi	s2,s1,256
    80005aaa:	6088                	ld	a0,0(s1)
    80005aac:	c529                	beqz	a0,80005af6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005aae:	ffffb097          	auipc	ra,0xffffb
    80005ab2:	f76080e7          	jalr	-138(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ab6:	04a1                	addi	s1,s1,8
    80005ab8:	ff2499e3          	bne	s1,s2,80005aaa <sys_exec+0xac>
  return -1;
    80005abc:	597d                	li	s2,-1
    80005abe:	a82d                	j	80005af8 <sys_exec+0xfa>
      argv[i] = 0;
    80005ac0:	0a8e                	slli	s5,s5,0x3
    80005ac2:	fc040793          	addi	a5,s0,-64
    80005ac6:	9abe                	add	s5,s5,a5
    80005ac8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005acc:	e4040593          	addi	a1,s0,-448
    80005ad0:	f4040513          	addi	a0,s0,-192
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	194080e7          	jalr	404(ra) # 80004c68 <exec>
    80005adc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ade:	10048993          	addi	s3,s1,256
    80005ae2:	6088                	ld	a0,0(s1)
    80005ae4:	c911                	beqz	a0,80005af8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ae6:	ffffb097          	auipc	ra,0xffffb
    80005aea:	f3e080e7          	jalr	-194(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aee:	04a1                	addi	s1,s1,8
    80005af0:	ff3499e3          	bne	s1,s3,80005ae2 <sys_exec+0xe4>
    80005af4:	a011                	j	80005af8 <sys_exec+0xfa>
  return -1;
    80005af6:	597d                	li	s2,-1
}
    80005af8:	854a                	mv	a0,s2
    80005afa:	60be                	ld	ra,456(sp)
    80005afc:	641e                	ld	s0,448(sp)
    80005afe:	74fa                	ld	s1,440(sp)
    80005b00:	795a                	ld	s2,432(sp)
    80005b02:	79ba                	ld	s3,424(sp)
    80005b04:	7a1a                	ld	s4,416(sp)
    80005b06:	6afa                	ld	s5,408(sp)
    80005b08:	6179                	addi	sp,sp,464
    80005b0a:	8082                	ret

0000000080005b0c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b0c:	7139                	addi	sp,sp,-64
    80005b0e:	fc06                	sd	ra,56(sp)
    80005b10:	f822                	sd	s0,48(sp)
    80005b12:	f426                	sd	s1,40(sp)
    80005b14:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b16:	ffffc097          	auipc	ra,0xffffc
    80005b1a:	fc2080e7          	jalr	-62(ra) # 80001ad8 <myproc>
    80005b1e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b20:	fd840593          	addi	a1,s0,-40
    80005b24:	4501                	li	a0,0
    80005b26:	ffffd097          	auipc	ra,0xffffd
    80005b2a:	0b0080e7          	jalr	176(ra) # 80002bd6 <argaddr>
    return -1;
    80005b2e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b30:	0e054063          	bltz	a0,80005c10 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b34:	fc840593          	addi	a1,s0,-56
    80005b38:	fd040513          	addi	a0,s0,-48
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	dd2080e7          	jalr	-558(ra) # 8000490e <pipealloc>
    return -1;
    80005b44:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b46:	0c054563          	bltz	a0,80005c10 <sys_pipe+0x104>
  fd0 = -1;
    80005b4a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b4e:	fd043503          	ld	a0,-48(s0)
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	508080e7          	jalr	1288(ra) # 8000505a <fdalloc>
    80005b5a:	fca42223          	sw	a0,-60(s0)
    80005b5e:	08054c63          	bltz	a0,80005bf6 <sys_pipe+0xea>
    80005b62:	fc843503          	ld	a0,-56(s0)
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	4f4080e7          	jalr	1268(ra) # 8000505a <fdalloc>
    80005b6e:	fca42023          	sw	a0,-64(s0)
    80005b72:	06054863          	bltz	a0,80005be2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b76:	4691                	li	a3,4
    80005b78:	fc440613          	addi	a2,s0,-60
    80005b7c:	fd843583          	ld	a1,-40(s0)
    80005b80:	68a8                	ld	a0,80(s1)
    80005b82:	ffffc097          	auipc	ra,0xffffc
    80005b86:	c4a080e7          	jalr	-950(ra) # 800017cc <copyout>
    80005b8a:	02054063          	bltz	a0,80005baa <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b8e:	4691                	li	a3,4
    80005b90:	fc040613          	addi	a2,s0,-64
    80005b94:	fd843583          	ld	a1,-40(s0)
    80005b98:	0591                	addi	a1,a1,4
    80005b9a:	68a8                	ld	a0,80(s1)
    80005b9c:	ffffc097          	auipc	ra,0xffffc
    80005ba0:	c30080e7          	jalr	-976(ra) # 800017cc <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ba4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ba6:	06055563          	bgez	a0,80005c10 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005baa:	fc442783          	lw	a5,-60(s0)
    80005bae:	07e9                	addi	a5,a5,26
    80005bb0:	078e                	slli	a5,a5,0x3
    80005bb2:	97a6                	add	a5,a5,s1
    80005bb4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bb8:	fc042503          	lw	a0,-64(s0)
    80005bbc:	0569                	addi	a0,a0,26
    80005bbe:	050e                	slli	a0,a0,0x3
    80005bc0:	9526                	add	a0,a0,s1
    80005bc2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bc6:	fd043503          	ld	a0,-48(s0)
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	9ee080e7          	jalr	-1554(ra) # 800045b8 <fileclose>
    fileclose(wf);
    80005bd2:	fc843503          	ld	a0,-56(s0)
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	9e2080e7          	jalr	-1566(ra) # 800045b8 <fileclose>
    return -1;
    80005bde:	57fd                	li	a5,-1
    80005be0:	a805                	j	80005c10 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005be2:	fc442783          	lw	a5,-60(s0)
    80005be6:	0007c863          	bltz	a5,80005bf6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bea:	01a78513          	addi	a0,a5,26
    80005bee:	050e                	slli	a0,a0,0x3
    80005bf0:	9526                	add	a0,a0,s1
    80005bf2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bf6:	fd043503          	ld	a0,-48(s0)
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	9be080e7          	jalr	-1602(ra) # 800045b8 <fileclose>
    fileclose(wf);
    80005c02:	fc843503          	ld	a0,-56(s0)
    80005c06:	fffff097          	auipc	ra,0xfffff
    80005c0a:	9b2080e7          	jalr	-1614(ra) # 800045b8 <fileclose>
    return -1;
    80005c0e:	57fd                	li	a5,-1
}
    80005c10:	853e                	mv	a0,a5
    80005c12:	70e2                	ld	ra,56(sp)
    80005c14:	7442                	ld	s0,48(sp)
    80005c16:	74a2                	ld	s1,40(sp)
    80005c18:	6121                	addi	sp,sp,64
    80005c1a:	8082                	ret
    80005c1c:	0000                	unimp
	...

0000000080005c20 <kernelvec>:
    80005c20:	7111                	addi	sp,sp,-256
    80005c22:	e006                	sd	ra,0(sp)
    80005c24:	e40a                	sd	sp,8(sp)
    80005c26:	e80e                	sd	gp,16(sp)
    80005c28:	ec12                	sd	tp,24(sp)
    80005c2a:	f016                	sd	t0,32(sp)
    80005c2c:	f41a                	sd	t1,40(sp)
    80005c2e:	f81e                	sd	t2,48(sp)
    80005c30:	fc22                	sd	s0,56(sp)
    80005c32:	e0a6                	sd	s1,64(sp)
    80005c34:	e4aa                	sd	a0,72(sp)
    80005c36:	e8ae                	sd	a1,80(sp)
    80005c38:	ecb2                	sd	a2,88(sp)
    80005c3a:	f0b6                	sd	a3,96(sp)
    80005c3c:	f4ba                	sd	a4,104(sp)
    80005c3e:	f8be                	sd	a5,112(sp)
    80005c40:	fcc2                	sd	a6,120(sp)
    80005c42:	e146                	sd	a7,128(sp)
    80005c44:	e54a                	sd	s2,136(sp)
    80005c46:	e94e                	sd	s3,144(sp)
    80005c48:	ed52                	sd	s4,152(sp)
    80005c4a:	f156                	sd	s5,160(sp)
    80005c4c:	f55a                	sd	s6,168(sp)
    80005c4e:	f95e                	sd	s7,176(sp)
    80005c50:	fd62                	sd	s8,184(sp)
    80005c52:	e1e6                	sd	s9,192(sp)
    80005c54:	e5ea                	sd	s10,200(sp)
    80005c56:	e9ee                	sd	s11,208(sp)
    80005c58:	edf2                	sd	t3,216(sp)
    80005c5a:	f1f6                	sd	t4,224(sp)
    80005c5c:	f5fa                	sd	t5,232(sp)
    80005c5e:	f9fe                	sd	t6,240(sp)
    80005c60:	d87fc0ef          	jal	ra,800029e6 <kerneltrap>
    80005c64:	6082                	ld	ra,0(sp)
    80005c66:	6122                	ld	sp,8(sp)
    80005c68:	61c2                	ld	gp,16(sp)
    80005c6a:	7282                	ld	t0,32(sp)
    80005c6c:	7322                	ld	t1,40(sp)
    80005c6e:	73c2                	ld	t2,48(sp)
    80005c70:	7462                	ld	s0,56(sp)
    80005c72:	6486                	ld	s1,64(sp)
    80005c74:	6526                	ld	a0,72(sp)
    80005c76:	65c6                	ld	a1,80(sp)
    80005c78:	6666                	ld	a2,88(sp)
    80005c7a:	7686                	ld	a3,96(sp)
    80005c7c:	7726                	ld	a4,104(sp)
    80005c7e:	77c6                	ld	a5,112(sp)
    80005c80:	7866                	ld	a6,120(sp)
    80005c82:	688a                	ld	a7,128(sp)
    80005c84:	692a                	ld	s2,136(sp)
    80005c86:	69ca                	ld	s3,144(sp)
    80005c88:	6a6a                	ld	s4,152(sp)
    80005c8a:	7a8a                	ld	s5,160(sp)
    80005c8c:	7b2a                	ld	s6,168(sp)
    80005c8e:	7bca                	ld	s7,176(sp)
    80005c90:	7c6a                	ld	s8,184(sp)
    80005c92:	6c8e                	ld	s9,192(sp)
    80005c94:	6d2e                	ld	s10,200(sp)
    80005c96:	6dce                	ld	s11,208(sp)
    80005c98:	6e6e                	ld	t3,216(sp)
    80005c9a:	7e8e                	ld	t4,224(sp)
    80005c9c:	7f2e                	ld	t5,232(sp)
    80005c9e:	7fce                	ld	t6,240(sp)
    80005ca0:	6111                	addi	sp,sp,256
    80005ca2:	10200073          	sret
    80005ca6:	00000013          	nop
    80005caa:	00000013          	nop
    80005cae:	0001                	nop

0000000080005cb0 <timervec>:
    80005cb0:	34051573          	csrrw	a0,mscratch,a0
    80005cb4:	e10c                	sd	a1,0(a0)
    80005cb6:	e510                	sd	a2,8(a0)
    80005cb8:	e914                	sd	a3,16(a0)
    80005cba:	710c                	ld	a1,32(a0)
    80005cbc:	7510                	ld	a2,40(a0)
    80005cbe:	6194                	ld	a3,0(a1)
    80005cc0:	96b2                	add	a3,a3,a2
    80005cc2:	e194                	sd	a3,0(a1)
    80005cc4:	4589                	li	a1,2
    80005cc6:	14459073          	csrw	sip,a1
    80005cca:	6914                	ld	a3,16(a0)
    80005ccc:	6510                	ld	a2,8(a0)
    80005cce:	610c                	ld	a1,0(a0)
    80005cd0:	34051573          	csrrw	a0,mscratch,a0
    80005cd4:	30200073          	mret
	...

0000000080005cda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cda:	1141                	addi	sp,sp,-16
    80005cdc:	e422                	sd	s0,8(sp)
    80005cde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ce0:	0c0007b7          	lui	a5,0xc000
    80005ce4:	4705                	li	a4,1
    80005ce6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ce8:	c3d8                	sw	a4,4(a5)
}
    80005cea:	6422                	ld	s0,8(sp)
    80005cec:	0141                	addi	sp,sp,16
    80005cee:	8082                	ret

0000000080005cf0 <plicinithart>:

void
plicinithart(void)
{
    80005cf0:	1141                	addi	sp,sp,-16
    80005cf2:	e406                	sd	ra,8(sp)
    80005cf4:	e022                	sd	s0,0(sp)
    80005cf6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cf8:	ffffc097          	auipc	ra,0xffffc
    80005cfc:	db4080e7          	jalr	-588(ra) # 80001aac <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d00:	0085171b          	slliw	a4,a0,0x8
    80005d04:	0c0027b7          	lui	a5,0xc002
    80005d08:	97ba                	add	a5,a5,a4
    80005d0a:	40200713          	li	a4,1026
    80005d0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d12:	00d5151b          	slliw	a0,a0,0xd
    80005d16:	0c2017b7          	lui	a5,0xc201
    80005d1a:	953e                	add	a0,a0,a5
    80005d1c:	00052023          	sw	zero,0(a0)
}
    80005d20:	60a2                	ld	ra,8(sp)
    80005d22:	6402                	ld	s0,0(sp)
    80005d24:	0141                	addi	sp,sp,16
    80005d26:	8082                	ret

0000000080005d28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d28:	1141                	addi	sp,sp,-16
    80005d2a:	e406                	sd	ra,8(sp)
    80005d2c:	e022                	sd	s0,0(sp)
    80005d2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d30:	ffffc097          	auipc	ra,0xffffc
    80005d34:	d7c080e7          	jalr	-644(ra) # 80001aac <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d38:	00d5179b          	slliw	a5,a0,0xd
    80005d3c:	0c201537          	lui	a0,0xc201
    80005d40:	953e                	add	a0,a0,a5
  return irq;
}
    80005d42:	4148                	lw	a0,4(a0)
    80005d44:	60a2                	ld	ra,8(sp)
    80005d46:	6402                	ld	s0,0(sp)
    80005d48:	0141                	addi	sp,sp,16
    80005d4a:	8082                	ret

0000000080005d4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d4c:	1101                	addi	sp,sp,-32
    80005d4e:	ec06                	sd	ra,24(sp)
    80005d50:	e822                	sd	s0,16(sp)
    80005d52:	e426                	sd	s1,8(sp)
    80005d54:	1000                	addi	s0,sp,32
    80005d56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	d54080e7          	jalr	-684(ra) # 80001aac <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d60:	00d5151b          	slliw	a0,a0,0xd
    80005d64:	0c2017b7          	lui	a5,0xc201
    80005d68:	97aa                	add	a5,a5,a0
    80005d6a:	c3c4                	sw	s1,4(a5)
}
    80005d6c:	60e2                	ld	ra,24(sp)
    80005d6e:	6442                	ld	s0,16(sp)
    80005d70:	64a2                	ld	s1,8(sp)
    80005d72:	6105                	addi	sp,sp,32
    80005d74:	8082                	ret

0000000080005d76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d76:	1141                	addi	sp,sp,-16
    80005d78:	e406                	sd	ra,8(sp)
    80005d7a:	e022                	sd	s0,0(sp)
    80005d7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d7e:	479d                	li	a5,7
    80005d80:	04a7cc63          	blt	a5,a0,80005dd8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005d84:	0001d797          	auipc	a5,0x1d
    80005d88:	27c78793          	addi	a5,a5,636 # 80023000 <disk>
    80005d8c:	00a78733          	add	a4,a5,a0
    80005d90:	6789                	lui	a5,0x2
    80005d92:	97ba                	add	a5,a5,a4
    80005d94:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d98:	eba1                	bnez	a5,80005de8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005d9a:	00451713          	slli	a4,a0,0x4
    80005d9e:	0001f797          	auipc	a5,0x1f
    80005da2:	2627b783          	ld	a5,610(a5) # 80025000 <disk+0x2000>
    80005da6:	97ba                	add	a5,a5,a4
    80005da8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005dac:	0001d797          	auipc	a5,0x1d
    80005db0:	25478793          	addi	a5,a5,596 # 80023000 <disk>
    80005db4:	97aa                	add	a5,a5,a0
    80005db6:	6509                	lui	a0,0x2
    80005db8:	953e                	add	a0,a0,a5
    80005dba:	4785                	li	a5,1
    80005dbc:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005dc0:	0001f517          	auipc	a0,0x1f
    80005dc4:	25850513          	addi	a0,a0,600 # 80025018 <disk+0x2018>
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	6a6080e7          	jalr	1702(ra) # 8000246e <wakeup>
}
    80005dd0:	60a2                	ld	ra,8(sp)
    80005dd2:	6402                	ld	s0,0(sp)
    80005dd4:	0141                	addi	sp,sp,16
    80005dd6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005dd8:	00003517          	auipc	a0,0x3
    80005ddc:	98050513          	addi	a0,a0,-1664 # 80008758 <syscalls+0x330>
    80005de0:	ffffa097          	auipc	ra,0xffffa
    80005de4:	768080e7          	jalr	1896(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005de8:	00003517          	auipc	a0,0x3
    80005dec:	98850513          	addi	a0,a0,-1656 # 80008770 <syscalls+0x348>
    80005df0:	ffffa097          	auipc	ra,0xffffa
    80005df4:	758080e7          	jalr	1880(ra) # 80000548 <panic>

0000000080005df8 <virtio_disk_init>:
{
    80005df8:	1101                	addi	sp,sp,-32
    80005dfa:	ec06                	sd	ra,24(sp)
    80005dfc:	e822                	sd	s0,16(sp)
    80005dfe:	e426                	sd	s1,8(sp)
    80005e00:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e02:	00003597          	auipc	a1,0x3
    80005e06:	98658593          	addi	a1,a1,-1658 # 80008788 <syscalls+0x360>
    80005e0a:	0001f517          	auipc	a0,0x1f
    80005e0e:	29e50513          	addi	a0,a0,670 # 800250a8 <disk+0x20a8>
    80005e12:	ffffb097          	auipc	ra,0xffffb
    80005e16:	d9c080e7          	jalr	-612(ra) # 80000bae <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e1a:	100017b7          	lui	a5,0x10001
    80005e1e:	4398                	lw	a4,0(a5)
    80005e20:	2701                	sext.w	a4,a4
    80005e22:	747277b7          	lui	a5,0x74727
    80005e26:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e2a:	0ef71163          	bne	a4,a5,80005f0c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e2e:	100017b7          	lui	a5,0x10001
    80005e32:	43dc                	lw	a5,4(a5)
    80005e34:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e36:	4705                	li	a4,1
    80005e38:	0ce79a63          	bne	a5,a4,80005f0c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e3c:	100017b7          	lui	a5,0x10001
    80005e40:	479c                	lw	a5,8(a5)
    80005e42:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e44:	4709                	li	a4,2
    80005e46:	0ce79363          	bne	a5,a4,80005f0c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e4a:	100017b7          	lui	a5,0x10001
    80005e4e:	47d8                	lw	a4,12(a5)
    80005e50:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e52:	554d47b7          	lui	a5,0x554d4
    80005e56:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e5a:	0af71963          	bne	a4,a5,80005f0c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e5e:	100017b7          	lui	a5,0x10001
    80005e62:	4705                	li	a4,1
    80005e64:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e66:	470d                	li	a4,3
    80005e68:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e6a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e6c:	c7ffe737          	lui	a4,0xc7ffe
    80005e70:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47ed875f>
    80005e74:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e76:	2701                	sext.w	a4,a4
    80005e78:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e7a:	472d                	li	a4,11
    80005e7c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e7e:	473d                	li	a4,15
    80005e80:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e82:	6705                	lui	a4,0x1
    80005e84:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e86:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e8a:	5bdc                	lw	a5,52(a5)
    80005e8c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e8e:	c7d9                	beqz	a5,80005f1c <virtio_disk_init+0x124>
  if(max < NUM)
    80005e90:	471d                	li	a4,7
    80005e92:	08f77d63          	bgeu	a4,a5,80005f2c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e96:	100014b7          	lui	s1,0x10001
    80005e9a:	47a1                	li	a5,8
    80005e9c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e9e:	6609                	lui	a2,0x2
    80005ea0:	4581                	li	a1,0
    80005ea2:	0001d517          	auipc	a0,0x1d
    80005ea6:	15e50513          	addi	a0,a0,350 # 80023000 <disk>
    80005eaa:	ffffb097          	auipc	ra,0xffffb
    80005eae:	e90080e7          	jalr	-368(ra) # 80000d3a <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005eb2:	0001d717          	auipc	a4,0x1d
    80005eb6:	14e70713          	addi	a4,a4,334 # 80023000 <disk>
    80005eba:	00c75793          	srli	a5,a4,0xc
    80005ebe:	2781                	sext.w	a5,a5
    80005ec0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005ec2:	0001f797          	auipc	a5,0x1f
    80005ec6:	13e78793          	addi	a5,a5,318 # 80025000 <disk+0x2000>
    80005eca:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005ecc:	0001d717          	auipc	a4,0x1d
    80005ed0:	1b470713          	addi	a4,a4,436 # 80023080 <disk+0x80>
    80005ed4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005ed6:	0001e717          	auipc	a4,0x1e
    80005eda:	12a70713          	addi	a4,a4,298 # 80024000 <disk+0x1000>
    80005ede:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005ee0:	4705                	li	a4,1
    80005ee2:	00e78c23          	sb	a4,24(a5)
    80005ee6:	00e78ca3          	sb	a4,25(a5)
    80005eea:	00e78d23          	sb	a4,26(a5)
    80005eee:	00e78da3          	sb	a4,27(a5)
    80005ef2:	00e78e23          	sb	a4,28(a5)
    80005ef6:	00e78ea3          	sb	a4,29(a5)
    80005efa:	00e78f23          	sb	a4,30(a5)
    80005efe:	00e78fa3          	sb	a4,31(a5)
}
    80005f02:	60e2                	ld	ra,24(sp)
    80005f04:	6442                	ld	s0,16(sp)
    80005f06:	64a2                	ld	s1,8(sp)
    80005f08:	6105                	addi	sp,sp,32
    80005f0a:	8082                	ret
    panic("could not find virtio disk");
    80005f0c:	00003517          	auipc	a0,0x3
    80005f10:	88c50513          	addi	a0,a0,-1908 # 80008798 <syscalls+0x370>
    80005f14:	ffffa097          	auipc	ra,0xffffa
    80005f18:	634080e7          	jalr	1588(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f1c:	00003517          	auipc	a0,0x3
    80005f20:	89c50513          	addi	a0,a0,-1892 # 800087b8 <syscalls+0x390>
    80005f24:	ffffa097          	auipc	ra,0xffffa
    80005f28:	624080e7          	jalr	1572(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f2c:	00003517          	auipc	a0,0x3
    80005f30:	8ac50513          	addi	a0,a0,-1876 # 800087d8 <syscalls+0x3b0>
    80005f34:	ffffa097          	auipc	ra,0xffffa
    80005f38:	614080e7          	jalr	1556(ra) # 80000548 <panic>

0000000080005f3c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f3c:	7119                	addi	sp,sp,-128
    80005f3e:	fc86                	sd	ra,120(sp)
    80005f40:	f8a2                	sd	s0,112(sp)
    80005f42:	f4a6                	sd	s1,104(sp)
    80005f44:	f0ca                	sd	s2,96(sp)
    80005f46:	ecce                	sd	s3,88(sp)
    80005f48:	e8d2                	sd	s4,80(sp)
    80005f4a:	e4d6                	sd	s5,72(sp)
    80005f4c:	e0da                	sd	s6,64(sp)
    80005f4e:	fc5e                	sd	s7,56(sp)
    80005f50:	f862                	sd	s8,48(sp)
    80005f52:	f466                	sd	s9,40(sp)
    80005f54:	f06a                	sd	s10,32(sp)
    80005f56:	0100                	addi	s0,sp,128
    80005f58:	892a                	mv	s2,a0
    80005f5a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f5c:	00c52c83          	lw	s9,12(a0)
    80005f60:	001c9c9b          	slliw	s9,s9,0x1
    80005f64:	1c82                	slli	s9,s9,0x20
    80005f66:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f6a:	0001f517          	auipc	a0,0x1f
    80005f6e:	13e50513          	addi	a0,a0,318 # 800250a8 <disk+0x20a8>
    80005f72:	ffffb097          	auipc	ra,0xffffb
    80005f76:	ccc080e7          	jalr	-820(ra) # 80000c3e <acquire>
  for(int i = 0; i < 3; i++){
    80005f7a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f7c:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f7e:	0001db97          	auipc	s7,0x1d
    80005f82:	082b8b93          	addi	s7,s7,130 # 80023000 <disk>
    80005f86:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f88:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f8a:	8a4e                	mv	s4,s3
    80005f8c:	a051                	j	80006010 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f8e:	00fb86b3          	add	a3,s7,a5
    80005f92:	96da                	add	a3,a3,s6
    80005f94:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f98:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f9a:	0207c563          	bltz	a5,80005fc4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f9e:	2485                	addiw	s1,s1,1
    80005fa0:	0711                	addi	a4,a4,4
    80005fa2:	23548d63          	beq	s1,s5,800061dc <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005fa6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fa8:	0001f697          	auipc	a3,0x1f
    80005fac:	07068693          	addi	a3,a3,112 # 80025018 <disk+0x2018>
    80005fb0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fb2:	0006c583          	lbu	a1,0(a3)
    80005fb6:	fde1                	bnez	a1,80005f8e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fb8:	2785                	addiw	a5,a5,1
    80005fba:	0685                	addi	a3,a3,1
    80005fbc:	ff879be3          	bne	a5,s8,80005fb2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fc0:	57fd                	li	a5,-1
    80005fc2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005fc4:	02905a63          	blez	s1,80005ff8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fc8:	f9042503          	lw	a0,-112(s0)
    80005fcc:	00000097          	auipc	ra,0x0
    80005fd0:	daa080e7          	jalr	-598(ra) # 80005d76 <free_desc>
      for(int j = 0; j < i; j++)
    80005fd4:	4785                	li	a5,1
    80005fd6:	0297d163          	bge	a5,s1,80005ff8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fda:	f9442503          	lw	a0,-108(s0)
    80005fde:	00000097          	auipc	ra,0x0
    80005fe2:	d98080e7          	jalr	-616(ra) # 80005d76 <free_desc>
      for(int j = 0; j < i; j++)
    80005fe6:	4789                	li	a5,2
    80005fe8:	0097d863          	bge	a5,s1,80005ff8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fec:	f9842503          	lw	a0,-104(s0)
    80005ff0:	00000097          	auipc	ra,0x0
    80005ff4:	d86080e7          	jalr	-634(ra) # 80005d76 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ff8:	0001f597          	auipc	a1,0x1f
    80005ffc:	0b058593          	addi	a1,a1,176 # 800250a8 <disk+0x20a8>
    80006000:	0001f517          	auipc	a0,0x1f
    80006004:	01850513          	addi	a0,a0,24 # 80025018 <disk+0x2018>
    80006008:	ffffc097          	auipc	ra,0xffffc
    8000600c:	2e0080e7          	jalr	736(ra) # 800022e8 <sleep>
  for(int i = 0; i < 3; i++){
    80006010:	f9040713          	addi	a4,s0,-112
    80006014:	84ce                	mv	s1,s3
    80006016:	bf41                	j	80005fa6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006018:	4785                	li	a5,1
    8000601a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000601e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006022:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006026:	f9042983          	lw	s3,-112(s0)
    8000602a:	00499493          	slli	s1,s3,0x4
    8000602e:	0001fa17          	auipc	s4,0x1f
    80006032:	fd2a0a13          	addi	s4,s4,-46 # 80025000 <disk+0x2000>
    80006036:	000a3a83          	ld	s5,0(s4)
    8000603a:	9aa6                	add	s5,s5,s1
    8000603c:	f8040513          	addi	a0,s0,-128
    80006040:	ffffb097          	auipc	ra,0xffffb
    80006044:	0ce080e7          	jalr	206(ra) # 8000110e <kvmpa>
    80006048:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000604c:	000a3783          	ld	a5,0(s4)
    80006050:	97a6                	add	a5,a5,s1
    80006052:	4741                	li	a4,16
    80006054:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006056:	000a3783          	ld	a5,0(s4)
    8000605a:	97a6                	add	a5,a5,s1
    8000605c:	4705                	li	a4,1
    8000605e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006062:	f9442703          	lw	a4,-108(s0)
    80006066:	000a3783          	ld	a5,0(s4)
    8000606a:	97a6                	add	a5,a5,s1
    8000606c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006070:	0712                	slli	a4,a4,0x4
    80006072:	000a3783          	ld	a5,0(s4)
    80006076:	97ba                	add	a5,a5,a4
    80006078:	05890693          	addi	a3,s2,88
    8000607c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000607e:	000a3783          	ld	a5,0(s4)
    80006082:	97ba                	add	a5,a5,a4
    80006084:	40000693          	li	a3,1024
    80006088:	c794                	sw	a3,8(a5)
  if(write)
    8000608a:	100d0a63          	beqz	s10,8000619e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000608e:	0001f797          	auipc	a5,0x1f
    80006092:	f727b783          	ld	a5,-142(a5) # 80025000 <disk+0x2000>
    80006096:	97ba                	add	a5,a5,a4
    80006098:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000609c:	0001d517          	auipc	a0,0x1d
    800060a0:	f6450513          	addi	a0,a0,-156 # 80023000 <disk>
    800060a4:	0001f797          	auipc	a5,0x1f
    800060a8:	f5c78793          	addi	a5,a5,-164 # 80025000 <disk+0x2000>
    800060ac:	6394                	ld	a3,0(a5)
    800060ae:	96ba                	add	a3,a3,a4
    800060b0:	00c6d603          	lhu	a2,12(a3)
    800060b4:	00166613          	ori	a2,a2,1
    800060b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060bc:	f9842683          	lw	a3,-104(s0)
    800060c0:	6390                	ld	a2,0(a5)
    800060c2:	9732                	add	a4,a4,a2
    800060c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800060c8:	20098613          	addi	a2,s3,512
    800060cc:	0612                	slli	a2,a2,0x4
    800060ce:	962a                	add	a2,a2,a0
    800060d0:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060d4:	00469713          	slli	a4,a3,0x4
    800060d8:	6394                	ld	a3,0(a5)
    800060da:	96ba                	add	a3,a3,a4
    800060dc:	6589                	lui	a1,0x2
    800060de:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800060e2:	94ae                	add	s1,s1,a1
    800060e4:	94aa                	add	s1,s1,a0
    800060e6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800060e8:	6394                	ld	a3,0(a5)
    800060ea:	96ba                	add	a3,a3,a4
    800060ec:	4585                	li	a1,1
    800060ee:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060f0:	6394                	ld	a3,0(a5)
    800060f2:	96ba                	add	a3,a3,a4
    800060f4:	4509                	li	a0,2
    800060f6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800060fa:	6394                	ld	a3,0(a5)
    800060fc:	9736                	add	a4,a4,a3
    800060fe:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006102:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006106:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000610a:	6794                	ld	a3,8(a5)
    8000610c:	0026d703          	lhu	a4,2(a3)
    80006110:	8b1d                	andi	a4,a4,7
    80006112:	2709                	addiw	a4,a4,2
    80006114:	0706                	slli	a4,a4,0x1
    80006116:	9736                	add	a4,a4,a3
    80006118:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000611c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006120:	6798                	ld	a4,8(a5)
    80006122:	00275783          	lhu	a5,2(a4)
    80006126:	2785                	addiw	a5,a5,1
    80006128:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000612c:	100017b7          	lui	a5,0x10001
    80006130:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006134:	00492703          	lw	a4,4(s2)
    80006138:	4785                	li	a5,1
    8000613a:	02f71163          	bne	a4,a5,8000615c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000613e:	0001f997          	auipc	s3,0x1f
    80006142:	f6a98993          	addi	s3,s3,-150 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006146:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006148:	85ce                	mv	a1,s3
    8000614a:	854a                	mv	a0,s2
    8000614c:	ffffc097          	auipc	ra,0xffffc
    80006150:	19c080e7          	jalr	412(ra) # 800022e8 <sleep>
  while(b->disk == 1) {
    80006154:	00492783          	lw	a5,4(s2)
    80006158:	fe9788e3          	beq	a5,s1,80006148 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000615c:	f9042483          	lw	s1,-112(s0)
    80006160:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006164:	00479713          	slli	a4,a5,0x4
    80006168:	0001d797          	auipc	a5,0x1d
    8000616c:	e9878793          	addi	a5,a5,-360 # 80023000 <disk>
    80006170:	97ba                	add	a5,a5,a4
    80006172:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006176:	0001f917          	auipc	s2,0x1f
    8000617a:	e8a90913          	addi	s2,s2,-374 # 80025000 <disk+0x2000>
    free_desc(i);
    8000617e:	8526                	mv	a0,s1
    80006180:	00000097          	auipc	ra,0x0
    80006184:	bf6080e7          	jalr	-1034(ra) # 80005d76 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006188:	0492                	slli	s1,s1,0x4
    8000618a:	00093783          	ld	a5,0(s2)
    8000618e:	94be                	add	s1,s1,a5
    80006190:	00c4d783          	lhu	a5,12(s1)
    80006194:	8b85                	andi	a5,a5,1
    80006196:	cf89                	beqz	a5,800061b0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006198:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000619c:	b7cd                	j	8000617e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000619e:	0001f797          	auipc	a5,0x1f
    800061a2:	e627b783          	ld	a5,-414(a5) # 80025000 <disk+0x2000>
    800061a6:	97ba                	add	a5,a5,a4
    800061a8:	4689                	li	a3,2
    800061aa:	00d79623          	sh	a3,12(a5)
    800061ae:	b5fd                	j	8000609c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061b0:	0001f517          	auipc	a0,0x1f
    800061b4:	ef850513          	addi	a0,a0,-264 # 800250a8 <disk+0x20a8>
    800061b8:	ffffb097          	auipc	ra,0xffffb
    800061bc:	b3a080e7          	jalr	-1222(ra) # 80000cf2 <release>
}
    800061c0:	70e6                	ld	ra,120(sp)
    800061c2:	7446                	ld	s0,112(sp)
    800061c4:	74a6                	ld	s1,104(sp)
    800061c6:	7906                	ld	s2,96(sp)
    800061c8:	69e6                	ld	s3,88(sp)
    800061ca:	6a46                	ld	s4,80(sp)
    800061cc:	6aa6                	ld	s5,72(sp)
    800061ce:	6b06                	ld	s6,64(sp)
    800061d0:	7be2                	ld	s7,56(sp)
    800061d2:	7c42                	ld	s8,48(sp)
    800061d4:	7ca2                	ld	s9,40(sp)
    800061d6:	7d02                	ld	s10,32(sp)
    800061d8:	6109                	addi	sp,sp,128
    800061da:	8082                	ret
  if(write)
    800061dc:	e20d1ee3          	bnez	s10,80006018 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800061e0:	f8042023          	sw	zero,-128(s0)
    800061e4:	bd2d                	j	8000601e <virtio_disk_rw+0xe2>

00000000800061e6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061e6:	1101                	addi	sp,sp,-32
    800061e8:	ec06                	sd	ra,24(sp)
    800061ea:	e822                	sd	s0,16(sp)
    800061ec:	e426                	sd	s1,8(sp)
    800061ee:	e04a                	sd	s2,0(sp)
    800061f0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061f2:	0001f517          	auipc	a0,0x1f
    800061f6:	eb650513          	addi	a0,a0,-330 # 800250a8 <disk+0x20a8>
    800061fa:	ffffb097          	auipc	ra,0xffffb
    800061fe:	a44080e7          	jalr	-1468(ra) # 80000c3e <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006202:	0001f717          	auipc	a4,0x1f
    80006206:	dfe70713          	addi	a4,a4,-514 # 80025000 <disk+0x2000>
    8000620a:	02075783          	lhu	a5,32(a4)
    8000620e:	6b18                	ld	a4,16(a4)
    80006210:	00275683          	lhu	a3,2(a4)
    80006214:	8ebd                	xor	a3,a3,a5
    80006216:	8a9d                	andi	a3,a3,7
    80006218:	cab9                	beqz	a3,8000626e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000621a:	0001d917          	auipc	s2,0x1d
    8000621e:	de690913          	addi	s2,s2,-538 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006222:	0001f497          	auipc	s1,0x1f
    80006226:	dde48493          	addi	s1,s1,-546 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000622a:	078e                	slli	a5,a5,0x3
    8000622c:	97ba                	add	a5,a5,a4
    8000622e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006230:	20078713          	addi	a4,a5,512
    80006234:	0712                	slli	a4,a4,0x4
    80006236:	974a                	add	a4,a4,s2
    80006238:	03074703          	lbu	a4,48(a4)
    8000623c:	ef21                	bnez	a4,80006294 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000623e:	20078793          	addi	a5,a5,512
    80006242:	0792                	slli	a5,a5,0x4
    80006244:	97ca                	add	a5,a5,s2
    80006246:	7798                	ld	a4,40(a5)
    80006248:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000624c:	7788                	ld	a0,40(a5)
    8000624e:	ffffc097          	auipc	ra,0xffffc
    80006252:	220080e7          	jalr	544(ra) # 8000246e <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006256:	0204d783          	lhu	a5,32(s1)
    8000625a:	2785                	addiw	a5,a5,1
    8000625c:	8b9d                	andi	a5,a5,7
    8000625e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006262:	6898                	ld	a4,16(s1)
    80006264:	00275683          	lhu	a3,2(a4)
    80006268:	8a9d                	andi	a3,a3,7
    8000626a:	fcf690e3          	bne	a3,a5,8000622a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000626e:	10001737          	lui	a4,0x10001
    80006272:	533c                	lw	a5,96(a4)
    80006274:	8b8d                	andi	a5,a5,3
    80006276:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006278:	0001f517          	auipc	a0,0x1f
    8000627c:	e3050513          	addi	a0,a0,-464 # 800250a8 <disk+0x20a8>
    80006280:	ffffb097          	auipc	ra,0xffffb
    80006284:	a72080e7          	jalr	-1422(ra) # 80000cf2 <release>
}
    80006288:	60e2                	ld	ra,24(sp)
    8000628a:	6442                	ld	s0,16(sp)
    8000628c:	64a2                	ld	s1,8(sp)
    8000628e:	6902                	ld	s2,0(sp)
    80006290:	6105                	addi	sp,sp,32
    80006292:	8082                	ret
      panic("virtio_disk_intr status");
    80006294:	00002517          	auipc	a0,0x2
    80006298:	56450513          	addi	a0,a0,1380 # 800087f8 <syscalls+0x3d0>
    8000629c:	ffffa097          	auipc	ra,0xffffa
    800062a0:	2ac080e7          	jalr	684(ra) # 80000548 <panic>

00000000800062a4 <increfcnt>:
  struct spinlock lock;	//自旋锁
} cows[(PHYSTOP - KERNBASE) >> 12];//压缩的页引用数

// 引用计数+1
void increfcnt(uint64 pa) {
  if (pa < KERNBASE) {
    800062a4:	800007b7          	lui	a5,0x80000
    800062a8:	fff7c793          	not	a5,a5
    800062ac:	00a7e363          	bltu	a5,a0,800062b2 <increfcnt+0xe>
    800062b0:	8082                	ret
void increfcnt(uint64 pa) {
    800062b2:	7179                	addi	sp,sp,-48
    800062b4:	f406                	sd	ra,40(sp)
    800062b6:	f022                	sd	s0,32(sp)
    800062b8:	ec26                	sd	s1,24(sp)
    800062ba:	e84a                	sd	s2,16(sp)
    800062bc:	e44e                	sd	s3,8(sp)
    800062be:	1800                	addi	s0,sp,48
    return;
  }
    //物理地址所在物理页的引用计数元素
  pa = (pa - KERNBASE) >> 12;
    800062c0:	800004b7          	lui	s1,0x80000
    800062c4:	94aa                	add	s1,s1,a0
    800062c6:	80b1                	srli	s1,s1,0xc
  acquire(&cows[pa].lock);
    800062c8:	0496                	slli	s1,s1,0x5
    800062ca:	00848993          	addi	s3,s1,8 # ffffffff80000008 <end+0xfffffffeffeda008>
    800062ce:	00020917          	auipc	s2,0x20
    800062d2:	d3290913          	addi	s2,s2,-718 # 80026000 <cows>
    800062d6:	99ca                	add	s3,s3,s2
    800062d8:	854e                	mv	a0,s3
    800062da:	ffffb097          	auipc	ra,0xffffb
    800062de:	964080e7          	jalr	-1692(ra) # 80000c3e <acquire>
  ++cows[pa].ref_cnt;
    800062e2:	94ca                	add	s1,s1,s2
    800062e4:	0004c783          	lbu	a5,0(s1)
    800062e8:	2785                	addiw	a5,a5,1
    800062ea:	00f48023          	sb	a5,0(s1)
  release(&cows[pa].lock);
    800062ee:	854e                	mv	a0,s3
    800062f0:	ffffb097          	auipc	ra,0xffffb
    800062f4:	a02080e7          	jalr	-1534(ra) # 80000cf2 <release>
}
    800062f8:	70a2                	ld	ra,40(sp)
    800062fa:	7402                	ld	s0,32(sp)
    800062fc:	64e2                	ld	s1,24(sp)
    800062fe:	6942                	ld	s2,16(sp)
    80006300:	69a2                	ld	s3,8(sp)
    80006302:	6145                	addi	sp,sp,48
    80006304:	8082                	ret

0000000080006306 <decrefcnt>:

// 引用计数减一
uint8 decrefcnt(uint64 pa) {
    80006306:	7179                	addi	sp,sp,-48
    80006308:	f406                	sd	ra,40(sp)
    8000630a:	f022                	sd	s0,32(sp)
    8000630c:	ec26                	sd	s1,24(sp)
    8000630e:	e84a                	sd	s2,16(sp)
    80006310:	e44e                	sd	s3,8(sp)
    80006312:	1800                	addi	s0,sp,48
  uint8 ret;
  if (pa < KERNBASE) {
    80006314:	800007b7          	lui	a5,0x80000
    80006318:	fff7c793          	not	a5,a5
    return 0;
    8000631c:	4901                	li	s2,0
  if (pa < KERNBASE) {
    8000631e:	00a7ea63          	bltu	a5,a0,80006332 <decrefcnt+0x2c>
  pa = (pa - KERNBASE) >> 12;
  acquire(&cows[pa].lock);
  ret = --cows[pa].ref_cnt;
  release(&cows[pa].lock);
  return ret;
    80006322:	854a                	mv	a0,s2
    80006324:	70a2                	ld	ra,40(sp)
    80006326:	7402                	ld	s0,32(sp)
    80006328:	64e2                	ld	s1,24(sp)
    8000632a:	6942                	ld	s2,16(sp)
    8000632c:	69a2                	ld	s3,8(sp)
    8000632e:	6145                	addi	sp,sp,48
    80006330:	8082                	ret
  pa = (pa - KERNBASE) >> 12;
    80006332:	800004b7          	lui	s1,0x80000
    80006336:	94aa                	add	s1,s1,a0
    80006338:	80b1                	srli	s1,s1,0xc
  acquire(&cows[pa].lock);
    8000633a:	0496                	slli	s1,s1,0x5
    8000633c:	00848993          	addi	s3,s1,8 # ffffffff80000008 <end+0xfffffffeffeda008>
    80006340:	00020917          	auipc	s2,0x20
    80006344:	cc090913          	addi	s2,s2,-832 # 80026000 <cows>
    80006348:	99ca                	add	s3,s3,s2
    8000634a:	854e                	mv	a0,s3
    8000634c:	ffffb097          	auipc	ra,0xffffb
    80006350:	8f2080e7          	jalr	-1806(ra) # 80000c3e <acquire>
  ret = --cows[pa].ref_cnt;
    80006354:	94ca                	add	s1,s1,s2
    80006356:	0004c903          	lbu	s2,0(s1)
    8000635a:	397d                	addiw	s2,s2,-1
    8000635c:	0ff97913          	andi	s2,s2,255
    80006360:	01248023          	sb	s2,0(s1)
  release(&cows[pa].lock);
    80006364:	854e                	mv	a0,s3
    80006366:	ffffb097          	auipc	ra,0xffffb
    8000636a:	98c080e7          	jalr	-1652(ra) # 80000cf2 <release>
  return ret;
    8000636e:	bf55                	j	80006322 <decrefcnt+0x1c>
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
