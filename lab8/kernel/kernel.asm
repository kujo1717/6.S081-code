
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	17010113          	addi	sp,sp,368 # 80009170 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fde70713          	addi	a4,a4,-34 # 80009030 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	0fc78793          	addi	a5,a5,252 # 80006160 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd27d7>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	1d678793          	addi	a5,a5,470 # 80001284 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
    80000106:	8a2a                	mv	s4,a0
    80000108:	84ae                	mv	s1,a1
    8000010a:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    8000010c:	00011517          	auipc	a0,0x11
    80000110:	06450513          	addi	a0,a0,100 # 80011170 <cons>
    80000114:	00001097          	auipc	ra,0x1
    80000118:	bde080e7          	jalr	-1058(ra) # 80000cf2 <acquire>
  for(i = 0; i < n; i++){
    8000011c:	05305b63          	blez	s3,80000172 <consolewrite+0x7e>
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	6d4080e7          	jalr	1748(ra) # 80002802 <either_copyin>
    80000136:	01550c63          	beq	a0,s5,8000014e <consolewrite+0x5a>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7aa080e7          	jalr	1962(ra) # 800008e8 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x30>
  }
  release(&cons.lock);
    8000014e:	00011517          	auipc	a0,0x11
    80000152:	02250513          	addi	a0,a0,34 # 80011170 <cons>
    80000156:	00001097          	auipc	ra,0x1
    8000015a:	c6c080e7          	jalr	-916(ra) # 80000dc2 <release>

  return i;
}
    8000015e:	854a                	mv	a0,s2
    80000160:	60a6                	ld	ra,72(sp)
    80000162:	6406                	ld	s0,64(sp)
    80000164:	74e2                	ld	s1,56(sp)
    80000166:	7942                	ld	s2,48(sp)
    80000168:	79a2                	ld	s3,40(sp)
    8000016a:	7a02                	ld	s4,32(sp)
    8000016c:	6ae2                	ld	s5,24(sp)
    8000016e:	6161                	addi	sp,sp,80
    80000170:	8082                	ret
  for(i = 0; i < n; i++){
    80000172:	4901                	li	s2,0
    80000174:	bfe9                	j	8000014e <consolewrite+0x5a>

0000000080000176 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000176:	7119                	addi	sp,sp,-128
    80000178:	fc86                	sd	ra,120(sp)
    8000017a:	f8a2                	sd	s0,112(sp)
    8000017c:	f4a6                	sd	s1,104(sp)
    8000017e:	f0ca                	sd	s2,96(sp)
    80000180:	ecce                	sd	s3,88(sp)
    80000182:	e8d2                	sd	s4,80(sp)
    80000184:	e4d6                	sd	s5,72(sp)
    80000186:	e0da                	sd	s6,64(sp)
    80000188:	fc5e                	sd	s7,56(sp)
    8000018a:	f862                	sd	s8,48(sp)
    8000018c:	f466                	sd	s9,40(sp)
    8000018e:	f06a                	sd	s10,32(sp)
    80000190:	ec6e                	sd	s11,24(sp)
    80000192:	0100                	addi	s0,sp,128
    80000194:	8b2a                	mv	s6,a0
    80000196:	8aae                	mv	s5,a1
    80000198:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000019a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000019e:	00011517          	auipc	a0,0x11
    800001a2:	fd250513          	addi	a0,a0,-46 # 80011170 <cons>
    800001a6:	00001097          	auipc	ra,0x1
    800001aa:	b4c080e7          	jalr	-1204(ra) # 80000cf2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001ae:	00011497          	auipc	s1,0x11
    800001b2:	fc248493          	addi	s1,s1,-62 # 80011170 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b6:	89a6                	mv	s3,s1
    800001b8:	00011917          	auipc	s2,0x11
    800001bc:	05890913          	addi	s2,s2,88 # 80011210 <cons+0xa0>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001c0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001c2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001c4:	4da9                	li	s11,10
  while(n > 0){
    800001c6:	07405863          	blez	s4,80000236 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001ca:	0a04a783          	lw	a5,160(s1)
    800001ce:	0a44a703          	lw	a4,164(s1)
    800001d2:	02f71463          	bne	a4,a5,800001fa <consoleread+0x84>
      if(myproc()->killed){
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	b64080e7          	jalr	-1180(ra) # 80001d3a <myproc>
    800001de:	5d1c                	lw	a5,56(a0)
    800001e0:	e7b5                	bnez	a5,8000024c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001e2:	85ce                	mv	a1,s3
    800001e4:	854a                	mv	a0,s2
    800001e6:	00002097          	auipc	ra,0x2
    800001ea:	364080e7          	jalr	868(ra) # 8000254a <sleep>
    while(cons.r == cons.w){
    800001ee:	0a04a783          	lw	a5,160(s1)
    800001f2:	0a44a703          	lw	a4,164(s1)
    800001f6:	fef700e3          	beq	a4,a5,800001d6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001fa:	0017871b          	addiw	a4,a5,1
    800001fe:	0ae4a023          	sw	a4,160(s1)
    80000202:	07f7f713          	andi	a4,a5,127
    80000206:	9726                	add	a4,a4,s1
    80000208:	02074703          	lbu	a4,32(a4)
    8000020c:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000210:	079c0663          	beq	s8,s9,8000027c <consoleread+0x106>
    cbuf = c;
    80000214:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000218:	4685                	li	a3,1
    8000021a:	f8f40613          	addi	a2,s0,-113
    8000021e:	85d6                	mv	a1,s5
    80000220:	855a                	mv	a0,s6
    80000222:	00002097          	auipc	ra,0x2
    80000226:	58a080e7          	jalr	1418(ra) # 800027ac <either_copyout>
    8000022a:	01a50663          	beq	a0,s10,80000236 <consoleread+0xc0>
    dst++;
    8000022e:	0a85                	addi	s5,s5,1
    --n;
    80000230:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000232:	f9bc1ae3          	bne	s8,s11,800001c6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f3a50513          	addi	a0,a0,-198 # 80011170 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	b84080e7          	jalr	-1148(ra) # 80000dc2 <release>

  return target - n;
    80000246:	414b853b          	subw	a0,s7,s4
    8000024a:	a811                	j	8000025e <consoleread+0xe8>
        release(&cons.lock);
    8000024c:	00011517          	auipc	a0,0x11
    80000250:	f2450513          	addi	a0,a0,-220 # 80011170 <cons>
    80000254:	00001097          	auipc	ra,0x1
    80000258:	b6e080e7          	jalr	-1170(ra) # 80000dc2 <release>
        return -1;
    8000025c:	557d                	li	a0,-1
}
    8000025e:	70e6                	ld	ra,120(sp)
    80000260:	7446                	ld	s0,112(sp)
    80000262:	74a6                	ld	s1,104(sp)
    80000264:	7906                	ld	s2,96(sp)
    80000266:	69e6                	ld	s3,88(sp)
    80000268:	6a46                	ld	s4,80(sp)
    8000026a:	6aa6                	ld	s5,72(sp)
    8000026c:	6b06                	ld	s6,64(sp)
    8000026e:	7be2                	ld	s7,56(sp)
    80000270:	7c42                	ld	s8,48(sp)
    80000272:	7ca2                	ld	s9,40(sp)
    80000274:	7d02                	ld	s10,32(sp)
    80000276:	6de2                	ld	s11,24(sp)
    80000278:	6109                	addi	sp,sp,128
    8000027a:	8082                	ret
      if(n < target){
    8000027c:	000a071b          	sext.w	a4,s4
    80000280:	fb777be3          	bgeu	a4,s7,80000236 <consoleread+0xc0>
        cons.r--;
    80000284:	00011717          	auipc	a4,0x11
    80000288:	f8f72623          	sw	a5,-116(a4) # 80011210 <cons+0xa0>
    8000028c:	b76d                	j	80000236 <consoleread+0xc0>

000000008000028e <consputc>:
{
    8000028e:	1141                	addi	sp,sp,-16
    80000290:	e406                	sd	ra,8(sp)
    80000292:	e022                	sd	s0,0(sp)
    80000294:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000296:	10000793          	li	a5,256
    8000029a:	00f50a63          	beq	a0,a5,800002ae <consputc+0x20>
    uartputc_sync(c);
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	564080e7          	jalr	1380(ra) # 80000802 <uartputc_sync>
}
    800002a6:	60a2                	ld	ra,8(sp)
    800002a8:	6402                	ld	s0,0(sp)
    800002aa:	0141                	addi	sp,sp,16
    800002ac:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	552080e7          	jalr	1362(ra) # 80000802 <uartputc_sync>
    800002b8:	02000513          	li	a0,32
    800002bc:	00000097          	auipc	ra,0x0
    800002c0:	546080e7          	jalr	1350(ra) # 80000802 <uartputc_sync>
    800002c4:	4521                	li	a0,8
    800002c6:	00000097          	auipc	ra,0x0
    800002ca:	53c080e7          	jalr	1340(ra) # 80000802 <uartputc_sync>
    800002ce:	bfe1                	j	800002a6 <consputc+0x18>

00000000800002d0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d0:	1101                	addi	sp,sp,-32
    800002d2:	ec06                	sd	ra,24(sp)
    800002d4:	e822                	sd	s0,16(sp)
    800002d6:	e426                	sd	s1,8(sp)
    800002d8:	e04a                	sd	s2,0(sp)
    800002da:	1000                	addi	s0,sp,32
    800002dc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002de:	00011517          	auipc	a0,0x11
    800002e2:	e9250513          	addi	a0,a0,-366 # 80011170 <cons>
    800002e6:	00001097          	auipc	ra,0x1
    800002ea:	a0c080e7          	jalr	-1524(ra) # 80000cf2 <acquire>

  switch(c){
    800002ee:	47d5                	li	a5,21
    800002f0:	0af48663          	beq	s1,a5,8000039c <consoleintr+0xcc>
    800002f4:	0297ca63          	blt	a5,s1,80000328 <consoleintr+0x58>
    800002f8:	47a1                	li	a5,8
    800002fa:	0ef48763          	beq	s1,a5,800003e8 <consoleintr+0x118>
    800002fe:	47c1                	li	a5,16
    80000300:	10f49a63          	bne	s1,a5,80000414 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    80000304:	00002097          	auipc	ra,0x2
    80000308:	554080e7          	jalr	1364(ra) # 80002858 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000030c:	00011517          	auipc	a0,0x11
    80000310:	e6450513          	addi	a0,a0,-412 # 80011170 <cons>
    80000314:	00001097          	auipc	ra,0x1
    80000318:	aae080e7          	jalr	-1362(ra) # 80000dc2 <release>
}
    8000031c:	60e2                	ld	ra,24(sp)
    8000031e:	6442                	ld	s0,16(sp)
    80000320:	64a2                	ld	s1,8(sp)
    80000322:	6902                	ld	s2,0(sp)
    80000324:	6105                	addi	sp,sp,32
    80000326:	8082                	ret
  switch(c){
    80000328:	07f00793          	li	a5,127
    8000032c:	0af48e63          	beq	s1,a5,800003e8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000330:	00011717          	auipc	a4,0x11
    80000334:	e4070713          	addi	a4,a4,-448 # 80011170 <cons>
    80000338:	0a872783          	lw	a5,168(a4)
    8000033c:	0a072703          	lw	a4,160(a4)
    80000340:	9f99                	subw	a5,a5,a4
    80000342:	07f00713          	li	a4,127
    80000346:	fcf763e3          	bltu	a4,a5,8000030c <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000034a:	47b5                	li	a5,13
    8000034c:	0cf48763          	beq	s1,a5,8000041a <consoleintr+0x14a>
      consputc(c);
    80000350:	8526                	mv	a0,s1
    80000352:	00000097          	auipc	ra,0x0
    80000356:	f3c080e7          	jalr	-196(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000035a:	00011797          	auipc	a5,0x11
    8000035e:	e1678793          	addi	a5,a5,-490 # 80011170 <cons>
    80000362:	0a87a703          	lw	a4,168(a5)
    80000366:	0017069b          	addiw	a3,a4,1
    8000036a:	0006861b          	sext.w	a2,a3
    8000036e:	0ad7a423          	sw	a3,168(a5)
    80000372:	07f77713          	andi	a4,a4,127
    80000376:	97ba                	add	a5,a5,a4
    80000378:	02978023          	sb	s1,32(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000037c:	47a9                	li	a5,10
    8000037e:	0cf48563          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000382:	4791                	li	a5,4
    80000384:	0cf48263          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000388:	00011797          	auipc	a5,0x11
    8000038c:	e887a783          	lw	a5,-376(a5) # 80011210 <cons+0xa0>
    80000390:	0807879b          	addiw	a5,a5,128
    80000394:	f6f61ce3          	bne	a2,a5,8000030c <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000398:	863e                	mv	a2,a5
    8000039a:	a07d                	j	80000448 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000039c:	00011717          	auipc	a4,0x11
    800003a0:	dd470713          	addi	a4,a4,-556 # 80011170 <cons>
    800003a4:	0a872783          	lw	a5,168(a4)
    800003a8:	0a472703          	lw	a4,164(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	00011497          	auipc	s1,0x11
    800003b0:	dc448493          	addi	s1,s1,-572 # 80011170 <cons>
    while(cons.e != cons.w &&
    800003b4:	4929                	li	s2,10
    800003b6:	f4f70be3          	beq	a4,a5,8000030c <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ba:	37fd                	addiw	a5,a5,-1
    800003bc:	07f7f713          	andi	a4,a5,127
    800003c0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c2:	02074703          	lbu	a4,32(a4)
    800003c6:	f52703e3          	beq	a4,s2,8000030c <consoleintr+0x3c>
      cons.e--;
    800003ca:	0af4a423          	sw	a5,168(s1)
      consputc(BACKSPACE);
    800003ce:	10000513          	li	a0,256
    800003d2:	00000097          	auipc	ra,0x0
    800003d6:	ebc080e7          	jalr	-324(ra) # 8000028e <consputc>
    while(cons.e != cons.w &&
    800003da:	0a84a783          	lw	a5,168(s1)
    800003de:	0a44a703          	lw	a4,164(s1)
    800003e2:	fcf71ce3          	bne	a4,a5,800003ba <consoleintr+0xea>
    800003e6:	b71d                	j	8000030c <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	d8870713          	addi	a4,a4,-632 # 80011170 <cons>
    800003f0:	0a872783          	lw	a5,168(a4)
    800003f4:	0a472703          	lw	a4,164(a4)
    800003f8:	f0f70ae3          	beq	a4,a5,8000030c <consoleintr+0x3c>
      cons.e--;
    800003fc:	37fd                	addiw	a5,a5,-1
    800003fe:	00011717          	auipc	a4,0x11
    80000402:	e0f72d23          	sw	a5,-486(a4) # 80011218 <cons+0xa8>
      consputc(BACKSPACE);
    80000406:	10000513          	li	a0,256
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e84080e7          	jalr	-380(ra) # 8000028e <consputc>
    80000412:	bded                	j	8000030c <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000414:	ee048ce3          	beqz	s1,8000030c <consoleintr+0x3c>
    80000418:	bf21                	j	80000330 <consoleintr+0x60>
      consputc(c);
    8000041a:	4529                	li	a0,10
    8000041c:	00000097          	auipc	ra,0x0
    80000420:	e72080e7          	jalr	-398(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000424:	00011797          	auipc	a5,0x11
    80000428:	d4c78793          	addi	a5,a5,-692 # 80011170 <cons>
    8000042c:	0a87a703          	lw	a4,168(a5)
    80000430:	0017069b          	addiw	a3,a4,1
    80000434:	0006861b          	sext.w	a2,a3
    80000438:	0ad7a423          	sw	a3,168(a5)
    8000043c:	07f77713          	andi	a4,a4,127
    80000440:	97ba                	add	a5,a5,a4
    80000442:	4729                	li	a4,10
    80000444:	02e78023          	sb	a4,32(a5)
        cons.w = cons.e;
    80000448:	00011797          	auipc	a5,0x11
    8000044c:	dcc7a623          	sw	a2,-564(a5) # 80011214 <cons+0xa4>
        wakeup(&cons.r);
    80000450:	00011517          	auipc	a0,0x11
    80000454:	dc050513          	addi	a0,a0,-576 # 80011210 <cons+0xa0>
    80000458:	00002097          	auipc	ra,0x2
    8000045c:	278080e7          	jalr	632(ra) # 800026d0 <wakeup>
    80000460:	b575                	j	8000030c <consoleintr+0x3c>

0000000080000462 <consoleinit>:

void
consoleinit(void)
{
    80000462:	1141                	addi	sp,sp,-16
    80000464:	e406                	sd	ra,8(sp)
    80000466:	e022                	sd	s0,0(sp)
    80000468:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000046a:	00008597          	auipc	a1,0x8
    8000046e:	ba658593          	addi	a1,a1,-1114 # 80008010 <etext+0x10>
    80000472:	00011517          	auipc	a0,0x11
    80000476:	cfe50513          	addi	a0,a0,-770 # 80011170 <cons>
    8000047a:	00001097          	auipc	ra,0x1
    8000047e:	9f4080e7          	jalr	-1548(ra) # 80000e6e <initlock>

  uartinit();
    80000482:	00000097          	auipc	ra,0x0
    80000486:	330080e7          	jalr	816(ra) # 800007b2 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000048a:	00026797          	auipc	a5,0x26
    8000048e:	b8678793          	addi	a5,a5,-1146 # 80026010 <devsw>
    80000492:	00000717          	auipc	a4,0x0
    80000496:	ce470713          	addi	a4,a4,-796 # 80000176 <consoleread>
    8000049a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000049c:	00000717          	auipc	a4,0x0
    800004a0:	c5870713          	addi	a4,a4,-936 # 800000f4 <consolewrite>
    800004a4:	ef98                	sd	a4,24(a5)
}
    800004a6:	60a2                	ld	ra,8(sp)
    800004a8:	6402                	ld	s0,0(sp)
    800004aa:	0141                	addi	sp,sp,16
    800004ac:	8082                	ret

00000000800004ae <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004ae:	7179                	addi	sp,sp,-48
    800004b0:	f406                	sd	ra,40(sp)
    800004b2:	f022                	sd	s0,32(sp)
    800004b4:	ec26                	sd	s1,24(sp)
    800004b6:	e84a                	sd	s2,16(sp)
    800004b8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ba:	c219                	beqz	a2,800004c0 <printint+0x12>
    800004bc:	08054663          	bltz	a0,80000548 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004c0:	2501                	sext.w	a0,a0
    800004c2:	4881                	li	a7,0
    800004c4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004ca:	2581                	sext.w	a1,a1
    800004cc:	00008617          	auipc	a2,0x8
    800004d0:	b7460613          	addi	a2,a2,-1164 # 80008040 <digits>
    800004d4:	883a                	mv	a6,a4
    800004d6:	2705                	addiw	a4,a4,1
    800004d8:	02b577bb          	remuw	a5,a0,a1
    800004dc:	1782                	slli	a5,a5,0x20
    800004de:	9381                	srli	a5,a5,0x20
    800004e0:	97b2                	add	a5,a5,a2
    800004e2:	0007c783          	lbu	a5,0(a5)
    800004e6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ea:	0005079b          	sext.w	a5,a0
    800004ee:	02b5553b          	divuw	a0,a0,a1
    800004f2:	0685                	addi	a3,a3,1
    800004f4:	feb7f0e3          	bgeu	a5,a1,800004d4 <printint+0x26>

  if(sign)
    800004f8:	00088b63          	beqz	a7,8000050e <printint+0x60>
    buf[i++] = '-';
    800004fc:	fe040793          	addi	a5,s0,-32
    80000500:	973e                	add	a4,a4,a5
    80000502:	02d00793          	li	a5,45
    80000506:	fef70823          	sb	a5,-16(a4)
    8000050a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000050e:	02e05763          	blez	a4,8000053c <printint+0x8e>
    80000512:	fd040793          	addi	a5,s0,-48
    80000516:	00e784b3          	add	s1,a5,a4
    8000051a:	fff78913          	addi	s2,a5,-1
    8000051e:	993a                	add	s2,s2,a4
    80000520:	377d                	addiw	a4,a4,-1
    80000522:	1702                	slli	a4,a4,0x20
    80000524:	9301                	srli	a4,a4,0x20
    80000526:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000052a:	fff4c503          	lbu	a0,-1(s1)
    8000052e:	00000097          	auipc	ra,0x0
    80000532:	d60080e7          	jalr	-672(ra) # 8000028e <consputc>
  while(--i >= 0)
    80000536:	14fd                	addi	s1,s1,-1
    80000538:	ff2499e3          	bne	s1,s2,8000052a <printint+0x7c>
}
    8000053c:	70a2                	ld	ra,40(sp)
    8000053e:	7402                	ld	s0,32(sp)
    80000540:	64e2                	ld	s1,24(sp)
    80000542:	6942                	ld	s2,16(sp)
    80000544:	6145                	addi	sp,sp,48
    80000546:	8082                	ret
    x = -xx;
    80000548:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000054c:	4885                	li	a7,1
    x = -xx;
    8000054e:	bf9d                	j	800004c4 <printint+0x16>

0000000080000550 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000550:	1101                	addi	sp,sp,-32
    80000552:	ec06                	sd	ra,24(sp)
    80000554:	e822                	sd	s0,16(sp)
    80000556:	e426                	sd	s1,8(sp)
    80000558:	1000                	addi	s0,sp,32
    8000055a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000055c:	00011797          	auipc	a5,0x11
    80000560:	ce07a223          	sw	zero,-796(a5) # 80011240 <pr+0x20>
  printf("panic: ");
    80000564:	00008517          	auipc	a0,0x8
    80000568:	ab450513          	addi	a0,a0,-1356 # 80008018 <etext+0x18>
    8000056c:	00000097          	auipc	ra,0x0
    80000570:	02e080e7          	jalr	46(ra) # 8000059a <printf>
  printf(s);
    80000574:	8526                	mv	a0,s1
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	024080e7          	jalr	36(ra) # 8000059a <printf>
  printf("\n");
    8000057e:	00008517          	auipc	a0,0x8
    80000582:	be250513          	addi	a0,a0,-1054 # 80008160 <digits+0x120>
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	014080e7          	jalr	20(ra) # 8000059a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000058e:	4785                	li	a5,1
    80000590:	00009717          	auipc	a4,0x9
    80000594:	a6f72823          	sw	a5,-1424(a4) # 80009000 <panicked>
  for(;;)
    80000598:	a001                	j	80000598 <panic+0x48>

000000008000059a <printf>:
{
    8000059a:	7131                	addi	sp,sp,-192
    8000059c:	fc86                	sd	ra,120(sp)
    8000059e:	f8a2                	sd	s0,112(sp)
    800005a0:	f4a6                	sd	s1,104(sp)
    800005a2:	f0ca                	sd	s2,96(sp)
    800005a4:	ecce                	sd	s3,88(sp)
    800005a6:	e8d2                	sd	s4,80(sp)
    800005a8:	e4d6                	sd	s5,72(sp)
    800005aa:	e0da                	sd	s6,64(sp)
    800005ac:	fc5e                	sd	s7,56(sp)
    800005ae:	f862                	sd	s8,48(sp)
    800005b0:	f466                	sd	s9,40(sp)
    800005b2:	f06a                	sd	s10,32(sp)
    800005b4:	ec6e                	sd	s11,24(sp)
    800005b6:	0100                	addi	s0,sp,128
    800005b8:	8a2a                	mv	s4,a0
    800005ba:	e40c                	sd	a1,8(s0)
    800005bc:	e810                	sd	a2,16(s0)
    800005be:	ec14                	sd	a3,24(s0)
    800005c0:	f018                	sd	a4,32(s0)
    800005c2:	f41c                	sd	a5,40(s0)
    800005c4:	03043823          	sd	a6,48(s0)
    800005c8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005cc:	00011d97          	auipc	s11,0x11
    800005d0:	c74dad83          	lw	s11,-908(s11) # 80011240 <pr+0x20>
  if(locking)
    800005d4:	020d9b63          	bnez	s11,8000060a <printf+0x70>
  if (fmt == 0)
    800005d8:	040a0263          	beqz	s4,8000061c <printf+0x82>
  va_start(ap, fmt);
    800005dc:	00840793          	addi	a5,s0,8
    800005e0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e4:	000a4503          	lbu	a0,0(s4)
    800005e8:	16050263          	beqz	a0,8000074c <printf+0x1b2>
    800005ec:	4481                	li	s1,0
    if(c != '%'){
    800005ee:	02500a93          	li	s5,37
    switch(c){
    800005f2:	07000b13          	li	s6,112
  consputc('x');
    800005f6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f8:	00008b97          	auipc	s7,0x8
    800005fc:	a48b8b93          	addi	s7,s7,-1464 # 80008040 <digits>
    switch(c){
    80000600:	07300c93          	li	s9,115
    80000604:	06400c13          	li	s8,100
    80000608:	a82d                	j	80000642 <printf+0xa8>
    acquire(&pr.lock);
    8000060a:	00011517          	auipc	a0,0x11
    8000060e:	c1650513          	addi	a0,a0,-1002 # 80011220 <pr>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	6e0080e7          	jalr	1760(ra) # 80000cf2 <acquire>
    8000061a:	bf7d                	j	800005d8 <printf+0x3e>
    panic("null fmt");
    8000061c:	00008517          	auipc	a0,0x8
    80000620:	a0c50513          	addi	a0,a0,-1524 # 80008028 <etext+0x28>
    80000624:	00000097          	auipc	ra,0x0
    80000628:	f2c080e7          	jalr	-212(ra) # 80000550 <panic>
      consputc(c);
    8000062c:	00000097          	auipc	ra,0x0
    80000630:	c62080e7          	jalr	-926(ra) # 8000028e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c503          	lbu	a0,0(a5)
    8000063e:	10050763          	beqz	a0,8000074c <printf+0x1b2>
    if(c != '%'){
    80000642:	ff5515e3          	bne	a0,s5,8000062c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000646:	2485                	addiw	s1,s1,1
    80000648:	009a07b3          	add	a5,s4,s1
    8000064c:	0007c783          	lbu	a5,0(a5)
    80000650:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000654:	cfe5                	beqz	a5,8000074c <printf+0x1b2>
    switch(c){
    80000656:	05678a63          	beq	a5,s6,800006aa <printf+0x110>
    8000065a:	02fb7663          	bgeu	s6,a5,80000686 <printf+0xec>
    8000065e:	09978963          	beq	a5,s9,800006f0 <printf+0x156>
    80000662:	07800713          	li	a4,120
    80000666:	0ce79863          	bne	a5,a4,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000066a:	f8843783          	ld	a5,-120(s0)
    8000066e:	00878713          	addi	a4,a5,8
    80000672:	f8e43423          	sd	a4,-120(s0)
    80000676:	4605                	li	a2,1
    80000678:	85ea                	mv	a1,s10
    8000067a:	4388                	lw	a0,0(a5)
    8000067c:	00000097          	auipc	ra,0x0
    80000680:	e32080e7          	jalr	-462(ra) # 800004ae <printint>
      break;
    80000684:	bf45                	j	80000634 <printf+0x9a>
    switch(c){
    80000686:	0b578263          	beq	a5,s5,8000072a <printf+0x190>
    8000068a:	0b879663          	bne	a5,s8,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	45a9                	li	a1,10
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e0e080e7          	jalr	-498(ra) # 800004ae <printint>
      break;
    800006a8:	b771                	j	80000634 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006aa:	f8843783          	ld	a5,-120(s0)
    800006ae:	00878713          	addi	a4,a5,8
    800006b2:	f8e43423          	sd	a4,-120(s0)
    800006b6:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ba:	03000513          	li	a0,48
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bd0080e7          	jalr	-1072(ra) # 8000028e <consputc>
  consputc('x');
    800006c6:	07800513          	li	a0,120
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bc4080e7          	jalr	-1084(ra) # 8000028e <consputc>
    800006d2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d4:	03c9d793          	srli	a5,s3,0x3c
    800006d8:	97de                	add	a5,a5,s7
    800006da:	0007c503          	lbu	a0,0(a5)
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	bb0080e7          	jalr	-1104(ra) # 8000028e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e6:	0992                	slli	s3,s3,0x4
    800006e8:	397d                	addiw	s2,s2,-1
    800006ea:	fe0915e3          	bnez	s2,800006d4 <printf+0x13a>
    800006ee:	b799                	j	80000634 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006f0:	f8843783          	ld	a5,-120(s0)
    800006f4:	00878713          	addi	a4,a5,8
    800006f8:	f8e43423          	sd	a4,-120(s0)
    800006fc:	0007b903          	ld	s2,0(a5)
    80000700:	00090e63          	beqz	s2,8000071c <printf+0x182>
      for(; *s; s++)
    80000704:	00094503          	lbu	a0,0(s2)
    80000708:	d515                	beqz	a0,80000634 <printf+0x9a>
        consputc(*s);
    8000070a:	00000097          	auipc	ra,0x0
    8000070e:	b84080e7          	jalr	-1148(ra) # 8000028e <consputc>
      for(; *s; s++)
    80000712:	0905                	addi	s2,s2,1
    80000714:	00094503          	lbu	a0,0(s2)
    80000718:	f96d                	bnez	a0,8000070a <printf+0x170>
    8000071a:	bf29                	j	80000634 <printf+0x9a>
        s = "(null)";
    8000071c:	00008917          	auipc	s2,0x8
    80000720:	90490913          	addi	s2,s2,-1788 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000724:	02800513          	li	a0,40
    80000728:	b7cd                	j	8000070a <printf+0x170>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b62080e7          	jalr	-1182(ra) # 8000028e <consputc>
      break;
    80000734:	b701                	j	80000634 <printf+0x9a>
      consputc('%');
    80000736:	8556                	mv	a0,s5
    80000738:	00000097          	auipc	ra,0x0
    8000073c:	b56080e7          	jalr	-1194(ra) # 8000028e <consputc>
      consputc(c);
    80000740:	854a                	mv	a0,s2
    80000742:	00000097          	auipc	ra,0x0
    80000746:	b4c080e7          	jalr	-1204(ra) # 8000028e <consputc>
      break;
    8000074a:	b5ed                	j	80000634 <printf+0x9a>
  if(locking)
    8000074c:	020d9163          	bnez	s11,8000076e <printf+0x1d4>
}
    80000750:	70e6                	ld	ra,120(sp)
    80000752:	7446                	ld	s0,112(sp)
    80000754:	74a6                	ld	s1,104(sp)
    80000756:	7906                	ld	s2,96(sp)
    80000758:	69e6                	ld	s3,88(sp)
    8000075a:	6a46                	ld	s4,80(sp)
    8000075c:	6aa6                	ld	s5,72(sp)
    8000075e:	6b06                	ld	s6,64(sp)
    80000760:	7be2                	ld	s7,56(sp)
    80000762:	7c42                	ld	s8,48(sp)
    80000764:	7ca2                	ld	s9,40(sp)
    80000766:	7d02                	ld	s10,32(sp)
    80000768:	6de2                	ld	s11,24(sp)
    8000076a:	6129                	addi	sp,sp,192
    8000076c:	8082                	ret
    release(&pr.lock);
    8000076e:	00011517          	auipc	a0,0x11
    80000772:	ab250513          	addi	a0,a0,-1358 # 80011220 <pr>
    80000776:	00000097          	auipc	ra,0x0
    8000077a:	64c080e7          	jalr	1612(ra) # 80000dc2 <release>
}
    8000077e:	bfc9                	j	80000750 <printf+0x1b6>

0000000080000780 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000780:	1101                	addi	sp,sp,-32
    80000782:	ec06                	sd	ra,24(sp)
    80000784:	e822                	sd	s0,16(sp)
    80000786:	e426                	sd	s1,8(sp)
    80000788:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000078a:	00011497          	auipc	s1,0x11
    8000078e:	a9648493          	addi	s1,s1,-1386 # 80011220 <pr>
    80000792:	00008597          	auipc	a1,0x8
    80000796:	8a658593          	addi	a1,a1,-1882 # 80008038 <etext+0x38>
    8000079a:	8526                	mv	a0,s1
    8000079c:	00000097          	auipc	ra,0x0
    800007a0:	6d2080e7          	jalr	1746(ra) # 80000e6e <initlock>
  pr.locking = 1;
    800007a4:	4785                	li	a5,1
    800007a6:	d09c                	sw	a5,32(s1)
}
    800007a8:	60e2                	ld	ra,24(sp)
    800007aa:	6442                	ld	s0,16(sp)
    800007ac:	64a2                	ld	s1,8(sp)
    800007ae:	6105                	addi	sp,sp,32
    800007b0:	8082                	ret

00000000800007b2 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007b2:	1141                	addi	sp,sp,-16
    800007b4:	e406                	sd	ra,8(sp)
    800007b6:	e022                	sd	s0,0(sp)
    800007b8:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ba:	100007b7          	lui	a5,0x10000
    800007be:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007c2:	f8000713          	li	a4,-128
    800007c6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ca:	470d                	li	a4,3
    800007cc:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007d0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007d4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d8:	469d                	li	a3,7
    800007da:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007de:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007e2:	00008597          	auipc	a1,0x8
    800007e6:	87658593          	addi	a1,a1,-1930 # 80008058 <digits+0x18>
    800007ea:	00011517          	auipc	a0,0x11
    800007ee:	a5e50513          	addi	a0,a0,-1442 # 80011248 <uart_tx_lock>
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	67c080e7          	jalr	1660(ra) # 80000e6e <initlock>
}
    800007fa:	60a2                	ld	ra,8(sp)
    800007fc:	6402                	ld	s0,0(sp)
    800007fe:	0141                	addi	sp,sp,16
    80000800:	8082                	ret

0000000080000802 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000802:	1101                	addi	sp,sp,-32
    80000804:	ec06                	sd	ra,24(sp)
    80000806:	e822                	sd	s0,16(sp)
    80000808:	e426                	sd	s1,8(sp)
    8000080a:	1000                	addi	s0,sp,32
    8000080c:	84aa                	mv	s1,a0
  push_off();
    8000080e:	00000097          	auipc	ra,0x0
    80000812:	498080e7          	jalr	1176(ra) # 80000ca6 <push_off>

  if(panicked){
    80000816:	00008797          	auipc	a5,0x8
    8000081a:	7ea7a783          	lw	a5,2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000822:	c391                	beqz	a5,80000826 <uartputc_sync+0x24>
    for(;;)
    80000824:	a001                	j	80000824 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000826:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000082a:	0ff7f793          	andi	a5,a5,255
    8000082e:	0207f793          	andi	a5,a5,32
    80000832:	dbf5                	beqz	a5,80000826 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000834:	0ff4f793          	andi	a5,s1,255
    80000838:	10000737          	lui	a4,0x10000
    8000083c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000840:	00000097          	auipc	ra,0x0
    80000844:	522080e7          	jalr	1314(ra) # 80000d62 <pop_off>
}
    80000848:	60e2                	ld	ra,24(sp)
    8000084a:	6442                	ld	s0,16(sp)
    8000084c:	64a2                	ld	s1,8(sp)
    8000084e:	6105                	addi	sp,sp,32
    80000850:	8082                	ret

0000000080000852 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000852:	00008797          	auipc	a5,0x8
    80000856:	7b27a783          	lw	a5,1970(a5) # 80009004 <uart_tx_r>
    8000085a:	00008717          	auipc	a4,0x8
    8000085e:	7ae72703          	lw	a4,1966(a4) # 80009008 <uart_tx_w>
    80000862:	08f70263          	beq	a4,a5,800008e6 <uartstart+0x94>
{
    80000866:	7139                	addi	sp,sp,-64
    80000868:	fc06                	sd	ra,56(sp)
    8000086a:	f822                	sd	s0,48(sp)
    8000086c:	f426                	sd	s1,40(sp)
    8000086e:	f04a                	sd	s2,32(sp)
    80000870:	ec4e                	sd	s3,24(sp)
    80000872:	e852                	sd	s4,16(sp)
    80000874:	e456                	sd	s5,8(sp)
    80000876:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    8000087c:	00011a17          	auipc	s4,0x11
    80000880:	9cca0a13          	addi	s4,s4,-1588 # 80011248 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000884:	00008497          	auipc	s1,0x8
    80000888:	78048493          	addi	s1,s1,1920 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000088c:	00008997          	auipc	s3,0x8
    80000890:	77c98993          	addi	s3,s3,1916 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000894:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000898:	0ff77713          	andi	a4,a4,255
    8000089c:	02077713          	andi	a4,a4,32
    800008a0:	cb15                	beqz	a4,800008d4 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008a2:	00fa0733          	add	a4,s4,a5
    800008a6:	02074a83          	lbu	s5,32(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008aa:	2785                	addiw	a5,a5,1
    800008ac:	41f7d71b          	sraiw	a4,a5,0x1f
    800008b0:	01b7571b          	srliw	a4,a4,0x1b
    800008b4:	9fb9                	addw	a5,a5,a4
    800008b6:	8bfd                	andi	a5,a5,31
    800008b8:	9f99                	subw	a5,a5,a4
    800008ba:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008bc:	8526                	mv	a0,s1
    800008be:	00002097          	auipc	ra,0x2
    800008c2:	e12080e7          	jalr	-494(ra) # 800026d0 <wakeup>
    
    WriteReg(THR, c);
    800008c6:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ca:	409c                	lw	a5,0(s1)
    800008cc:	0009a703          	lw	a4,0(s3)
    800008d0:	fcf712e3          	bne	a4,a5,80000894 <uartstart+0x42>
  }
}
    800008d4:	70e2                	ld	ra,56(sp)
    800008d6:	7442                	ld	s0,48(sp)
    800008d8:	74a2                	ld	s1,40(sp)
    800008da:	7902                	ld	s2,32(sp)
    800008dc:	69e2                	ld	s3,24(sp)
    800008de:	6a42                	ld	s4,16(sp)
    800008e0:	6aa2                	ld	s5,8(sp)
    800008e2:	6121                	addi	sp,sp,64
    800008e4:	8082                	ret
    800008e6:	8082                	ret

00000000800008e8 <uartputc>:
{
    800008e8:	7179                	addi	sp,sp,-48
    800008ea:	f406                	sd	ra,40(sp)
    800008ec:	f022                	sd	s0,32(sp)
    800008ee:	ec26                	sd	s1,24(sp)
    800008f0:	e84a                	sd	s2,16(sp)
    800008f2:	e44e                	sd	s3,8(sp)
    800008f4:	e052                	sd	s4,0(sp)
    800008f6:	1800                	addi	s0,sp,48
    800008f8:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008fa:	00011517          	auipc	a0,0x11
    800008fe:	94e50513          	addi	a0,a0,-1714 # 80011248 <uart_tx_lock>
    80000902:	00000097          	auipc	ra,0x0
    80000906:	3f0080e7          	jalr	1008(ra) # 80000cf2 <acquire>
  if(panicked){
    8000090a:	00008797          	auipc	a5,0x8
    8000090e:	6f67a783          	lw	a5,1782(a5) # 80009000 <panicked>
    80000912:	c391                	beqz	a5,80000916 <uartputc+0x2e>
    for(;;)
    80000914:	a001                	j	80000914 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000916:	00008717          	auipc	a4,0x8
    8000091a:	6f272703          	lw	a4,1778(a4) # 80009008 <uart_tx_w>
    8000091e:	0017079b          	addiw	a5,a4,1
    80000922:	41f7d69b          	sraiw	a3,a5,0x1f
    80000926:	01b6d69b          	srliw	a3,a3,0x1b
    8000092a:	9fb5                	addw	a5,a5,a3
    8000092c:	8bfd                	andi	a5,a5,31
    8000092e:	9f95                	subw	a5,a5,a3
    80000930:	00008697          	auipc	a3,0x8
    80000934:	6d46a683          	lw	a3,1748(a3) # 80009004 <uart_tx_r>
    80000938:	04f69263          	bne	a3,a5,8000097c <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000093c:	00011a17          	auipc	s4,0x11
    80000940:	90ca0a13          	addi	s4,s4,-1780 # 80011248 <uart_tx_lock>
    80000944:	00008497          	auipc	s1,0x8
    80000948:	6c048493          	addi	s1,s1,1728 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000094c:	00008917          	auipc	s2,0x8
    80000950:	6bc90913          	addi	s2,s2,1724 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000954:	85d2                	mv	a1,s4
    80000956:	8526                	mv	a0,s1
    80000958:	00002097          	auipc	ra,0x2
    8000095c:	bf2080e7          	jalr	-1038(ra) # 8000254a <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000960:	00092703          	lw	a4,0(s2)
    80000964:	0017079b          	addiw	a5,a4,1
    80000968:	41f7d69b          	sraiw	a3,a5,0x1f
    8000096c:	01b6d69b          	srliw	a3,a3,0x1b
    80000970:	9fb5                	addw	a5,a5,a3
    80000972:	8bfd                	andi	a5,a5,31
    80000974:	9f95                	subw	a5,a5,a3
    80000976:	4094                	lw	a3,0(s1)
    80000978:	fcf68ee3          	beq	a3,a5,80000954 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    8000097c:	00011497          	auipc	s1,0x11
    80000980:	8cc48493          	addi	s1,s1,-1844 # 80011248 <uart_tx_lock>
    80000984:	9726                	add	a4,a4,s1
    80000986:	03370023          	sb	s3,32(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    8000098a:	00008717          	auipc	a4,0x8
    8000098e:	66f72f23          	sw	a5,1662(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000992:	00000097          	auipc	ra,0x0
    80000996:	ec0080e7          	jalr	-320(ra) # 80000852 <uartstart>
      release(&uart_tx_lock);
    8000099a:	8526                	mv	a0,s1
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	426080e7          	jalr	1062(ra) # 80000dc2 <release>
}
    800009a4:	70a2                	ld	ra,40(sp)
    800009a6:	7402                	ld	s0,32(sp)
    800009a8:	64e2                	ld	s1,24(sp)
    800009aa:	6942                	ld	s2,16(sp)
    800009ac:	69a2                	ld	s3,8(sp)
    800009ae:	6a02                	ld	s4,0(sp)
    800009b0:	6145                	addi	sp,sp,48
    800009b2:	8082                	ret

00000000800009b4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009b4:	1141                	addi	sp,sp,-16
    800009b6:	e422                	sd	s0,8(sp)
    800009b8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009c2:	8b85                	andi	a5,a5,1
    800009c4:	cb91                	beqz	a5,800009d8 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009c6:	100007b7          	lui	a5,0x10000
    800009ca:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009ce:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009d2:	6422                	ld	s0,8(sp)
    800009d4:	0141                	addi	sp,sp,16
    800009d6:	8082                	ret
    return -1;
    800009d8:	557d                	li	a0,-1
    800009da:	bfe5                	j	800009d2 <uartgetc+0x1e>

00000000800009dc <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009dc:	1101                	addi	sp,sp,-32
    800009de:	ec06                	sd	ra,24(sp)
    800009e0:	e822                	sd	s0,16(sp)
    800009e2:	e426                	sd	s1,8(sp)
    800009e4:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009e6:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	fcc080e7          	jalr	-52(ra) # 800009b4 <uartgetc>
    if(c == -1)
    800009f0:	00950763          	beq	a0,s1,800009fe <uartintr+0x22>
      break;
    consoleintr(c);
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	8dc080e7          	jalr	-1828(ra) # 800002d0 <consoleintr>
  while(1){
    800009fc:	b7f5                	j	800009e8 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009fe:	00011497          	auipc	s1,0x11
    80000a02:	84a48493          	addi	s1,s1,-1974 # 80011248 <uart_tx_lock>
    80000a06:	8526                	mv	a0,s1
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	2ea080e7          	jalr	746(ra) # 80000cf2 <acquire>
  uartstart();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	e42080e7          	jalr	-446(ra) # 80000852 <uartstart>
  release(&uart_tx_lock);
    80000a18:	8526                	mv	a0,s1
    80000a1a:	00000097          	auipc	ra,0x0
    80000a1e:	3a8080e7          	jalr	936(ra) # 80000dc2 <release>
}
    80000a22:	60e2                	ld	ra,24(sp)
    80000a24:	6442                	ld	s0,16(sp)
    80000a26:	64a2                	ld	s1,8(sp)
    80000a28:	6105                	addi	sp,sp,32
    80000a2a:	8082                	ret

0000000080000a2c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a2c:	7139                	addi	sp,sp,-64
    80000a2e:	fc06                	sd	ra,56(sp)
    80000a30:	f822                	sd	s0,48(sp)
    80000a32:	f426                	sd	s1,40(sp)
    80000a34:	f04a                	sd	s2,32(sp)
    80000a36:	ec4e                	sd	s3,24(sp)
    80000a38:	e852                	sd	s4,16(sp)
    80000a3a:	e456                	sd	s5,8(sp)
    80000a3c:	0080                	addi	s0,sp,64
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a3e:	03451793          	slli	a5,a0,0x34
    80000a42:	e3c9                	bnez	a5,80000ac4 <kfree+0x98>
    80000a44:	84aa                	mv	s1,a0
    80000a46:	0002b797          	auipc	a5,0x2b
    80000a4a:	5e278793          	addi	a5,a5,1506 # 8002c028 <end>
    80000a4e:	06f56b63          	bltu	a0,a5,80000ac4 <kfree+0x98>
    80000a52:	47c5                	li	a5,17
    80000a54:	07ee                	slli	a5,a5,0x1b
    80000a56:	06f57763          	bgeu	a0,a5,80000ac4 <kfree+0x98>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a5a:	6605                	lui	a2,0x1
    80000a5c:	4585                	li	a1,1
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	674080e7          	jalr	1652(ra) # 800010d2 <memset>

  r = (struct run*)pa;
  //关闭中断再获取cpuid
  push_off();
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	240080e7          	jalr	576(ra) # 80000ca6 <push_off>
  int id = cpuid();
    80000a6e:	00001097          	auipc	ra,0x1
    80000a72:	2a0080e7          	jalr	672(ra) # 80001d0e <cpuid>
    80000a76:	8a2a                	mv	s4,a0
  pop_off();
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	2ea080e7          	jalr	746(ra) # 80000d62 <pop_off>

  acquire(&kmem[id].lock);
    80000a80:	00011a97          	auipc	s5,0x11
    80000a84:	808a8a93          	addi	s5,s5,-2040 # 80011288 <kmem>
    80000a88:	002a1993          	slli	s3,s4,0x2
    80000a8c:	01498933          	add	s2,s3,s4
    80000a90:	090e                	slli	s2,s2,0x3
    80000a92:	9956                	add	s2,s2,s5
    80000a94:	854a                	mv	a0,s2
    80000a96:	00000097          	auipc	ra,0x0
    80000a9a:	25c080e7          	jalr	604(ra) # 80000cf2 <acquire>
  r->next = kmem[id].freelist;
    80000a9e:	02093783          	ld	a5,32(s2)
    80000aa2:	e09c                	sd	a5,0(s1)
  kmem[id].freelist = r;
    80000aa4:	02993023          	sd	s1,32(s2)
  release(&kmem[id].lock);
    80000aa8:	854a                	mv	a0,s2
    80000aaa:	00000097          	auipc	ra,0x0
    80000aae:	318080e7          	jalr	792(ra) # 80000dc2 <release>
}
    80000ab2:	70e2                	ld	ra,56(sp)
    80000ab4:	7442                	ld	s0,48(sp)
    80000ab6:	74a2                	ld	s1,40(sp)
    80000ab8:	7902                	ld	s2,32(sp)
    80000aba:	69e2                	ld	s3,24(sp)
    80000abc:	6a42                	ld	s4,16(sp)
    80000abe:	6aa2                	ld	s5,8(sp)
    80000ac0:	6121                	addi	sp,sp,64
    80000ac2:	8082                	ret
    panic("kfree");
    80000ac4:	00007517          	auipc	a0,0x7
    80000ac8:	59c50513          	addi	a0,a0,1436 # 80008060 <digits+0x20>
    80000acc:	00000097          	auipc	ra,0x0
    80000ad0:	a84080e7          	jalr	-1404(ra) # 80000550 <panic>

0000000080000ad4 <freerange>:
{
    80000ad4:	7179                	addi	sp,sp,-48
    80000ad6:	f406                	sd	ra,40(sp)
    80000ad8:	f022                	sd	s0,32(sp)
    80000ada:	ec26                	sd	s1,24(sp)
    80000adc:	e84a                	sd	s2,16(sp)
    80000ade:	e44e                	sd	s3,8(sp)
    80000ae0:	e052                	sd	s4,0(sp)
    80000ae2:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae4:	6785                	lui	a5,0x1
    80000ae6:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000aea:	94aa                	add	s1,s1,a0
    80000aec:	757d                	lui	a0,0xfffff
    80000aee:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af0:	94be                	add	s1,s1,a5
    80000af2:	0095ee63          	bltu	a1,s1,80000b0e <freerange+0x3a>
    80000af6:	892e                	mv	s2,a1
    kfree(p);
    80000af8:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000afa:	6985                	lui	s3,0x1
    kfree(p);
    80000afc:	01448533          	add	a0,s1,s4
    80000b00:	00000097          	auipc	ra,0x0
    80000b04:	f2c080e7          	jalr	-212(ra) # 80000a2c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b08:	94ce                	add	s1,s1,s3
    80000b0a:	fe9979e3          	bgeu	s2,s1,80000afc <freerange+0x28>
}
    80000b0e:	70a2                	ld	ra,40(sp)
    80000b10:	7402                	ld	s0,32(sp)
    80000b12:	64e2                	ld	s1,24(sp)
    80000b14:	6942                	ld	s2,16(sp)
    80000b16:	69a2                	ld	s3,8(sp)
    80000b18:	6a02                	ld	s4,0(sp)
    80000b1a:	6145                	addi	sp,sp,48
    80000b1c:	8082                	ret

0000000080000b1e <kinit>:
{
    80000b1e:	7179                	addi	sp,sp,-48
    80000b20:	f406                	sd	ra,40(sp)
    80000b22:	f022                	sd	s0,32(sp)
    80000b24:	ec26                	sd	s1,24(sp)
    80000b26:	e84a                	sd	s2,16(sp)
    80000b28:	e44e                	sd	s3,8(sp)
    80000b2a:	1800                	addi	s0,sp,48
  for (int i = 0; i < NCPU; i++)
    80000b2c:	00010497          	auipc	s1,0x10
    80000b30:	75c48493          	addi	s1,s1,1884 # 80011288 <kmem>
    80000b34:	00011997          	auipc	s3,0x11
    80000b38:	89498993          	addi	s3,s3,-1900 # 800113c8 <lock_locks>
    initlock(&kmem[i].lock, "kmem");
    80000b3c:	00007917          	auipc	s2,0x7
    80000b40:	52c90913          	addi	s2,s2,1324 # 80008068 <digits+0x28>
    80000b44:	85ca                	mv	a1,s2
    80000b46:	8526                	mv	a0,s1
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	326080e7          	jalr	806(ra) # 80000e6e <initlock>
  for (int i = 0; i < NCPU; i++)
    80000b50:	02848493          	addi	s1,s1,40
    80000b54:	ff3498e3          	bne	s1,s3,80000b44 <kinit+0x26>
  freerange(end, (void*)PHYSTOP);
    80000b58:	45c5                	li	a1,17
    80000b5a:	05ee                	slli	a1,a1,0x1b
    80000b5c:	0002b517          	auipc	a0,0x2b
    80000b60:	4cc50513          	addi	a0,a0,1228 # 8002c028 <end>
    80000b64:	00000097          	auipc	ra,0x0
    80000b68:	f70080e7          	jalr	-144(ra) # 80000ad4 <freerange>
}
    80000b6c:	70a2                	ld	ra,40(sp)
    80000b6e:	7402                	ld	s0,32(sp)
    80000b70:	64e2                	ld	s1,24(sp)
    80000b72:	6942                	ld	s2,16(sp)
    80000b74:	69a2                	ld	s3,8(sp)
    80000b76:	6145                	addi	sp,sp,48
    80000b78:	8082                	ret

0000000080000b7a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b7a:	715d                	addi	sp,sp,-80
    80000b7c:	e486                	sd	ra,72(sp)
    80000b7e:	e0a2                	sd	s0,64(sp)
    80000b80:	fc26                	sd	s1,56(sp)
    80000b82:	f84a                	sd	s2,48(sp)
    80000b84:	f44e                	sd	s3,40(sp)
    80000b86:	f052                	sd	s4,32(sp)
    80000b88:	ec56                	sd	s5,24(sp)
    80000b8a:	e85a                	sd	s6,16(sp)
    80000b8c:	e45e                	sd	s7,8(sp)
    80000b8e:	e062                	sd	s8,0(sp)
    80000b90:	0880                	addi	s0,sp,80
  struct run *r;

  //关闭中断再获取cpuid
  push_off();
    80000b92:	00000097          	auipc	ra,0x0
    80000b96:	114080e7          	jalr	276(ra) # 80000ca6 <push_off>
  int id = cpuid();
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	174080e7          	jalr	372(ra) # 80001d0e <cpuid>
    80000ba2:	892a                	mv	s2,a0
  pop_off();
    80000ba4:	00000097          	auipc	ra,0x0
    80000ba8:	1be080e7          	jalr	446(ra) # 80000d62 <pop_off>

  acquire(&kmem[id].lock);
    80000bac:	00291a93          	slli	s5,s2,0x2
    80000bb0:	9aca                	add	s5,s5,s2
    80000bb2:	003a9793          	slli	a5,s5,0x3
    80000bb6:	00010a97          	auipc	s5,0x10
    80000bba:	6d2a8a93          	addi	s5,s5,1746 # 80011288 <kmem>
    80000bbe:	9abe                	add	s5,s5,a5
    80000bc0:	8556                	mv	a0,s5
    80000bc2:	00000097          	auipc	ra,0x0
    80000bc6:	130080e7          	jalr	304(ra) # 80000cf2 <acquire>
  r = kmem[id].freelist;
    80000bca:	020abb03          	ld	s6,32(s5)
   //有空闲内存块
  if(r)
    80000bce:	000b0863          	beqz	s6,80000bde <kalloc+0x64>
    kmem[id].freelist = r->next;
    80000bd2:	000b3703          	ld	a4,0(s6)
    80000bd6:	02eab023          	sd	a4,32(s5)
  r = kmem[id].freelist;
    80000bda:	8a5a                	mv	s4,s6
    80000bdc:	a0ad                	j	80000c46 <kalloc+0xcc>
    80000bde:	00010997          	auipc	s3,0x10
    80000be2:	6aa98993          	addi	s3,s3,1706 # 80011288 <kmem>
  else {//无空闲内存块
    for (int i = 0; i < NCPU; i++) {
    80000be6:	4481                	li	s1,0
    80000be8:	4c21                	li	s8,8
    80000bea:	a015                	j	80000c0e <kalloc+0x94>
      release(&kmem[i].lock);
      if(r) 
          break;
    }
  }
  release(&kmem[id].lock);
    80000bec:	8556                	mv	a0,s5
    80000bee:	00000097          	auipc	ra,0x0
    80000bf2:	1d4080e7          	jalr	468(ra) # 80000dc2 <release>

  if(r)
    80000bf6:	8a5a                	mv	s4,s6
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
    80000bf8:	a09d                	j	80000c5e <kalloc+0xe4>
      release(&kmem[i].lock);
    80000bfa:	854e                	mv	a0,s3
    80000bfc:	00000097          	auipc	ra,0x0
    80000c00:	1c6080e7          	jalr	454(ra) # 80000dc2 <release>
    for (int i = 0; i < NCPU; i++) {
    80000c04:	2485                	addiw	s1,s1,1
    80000c06:	02898993          	addi	s3,s3,40
    80000c0a:	ff8481e3          	beq	s1,s8,80000bec <kalloc+0x72>
      if (i == id) 
    80000c0e:	fe990be3          	beq	s2,s1,80000c04 <kalloc+0x8a>
      acquire(&kmem[i].lock);
    80000c12:	854e                	mv	a0,s3
    80000c14:	00000097          	auipc	ra,0x0
    80000c18:	0de080e7          	jalr	222(ra) # 80000cf2 <acquire>
      r = kmem[i].freelist;
    80000c1c:	0209ba03          	ld	s4,32(s3)
      if(r)
    80000c20:	fc0a0de3          	beqz	s4,80000bfa <kalloc+0x80>
        kmem[i].freelist = r->next;
    80000c24:	000a3703          	ld	a4,0(s4) # fffffffffffff000 <end+0xffffffff7ffd2fd8>
    80000c28:	00249793          	slli	a5,s1,0x2
    80000c2c:	94be                	add	s1,s1,a5
    80000c2e:	048e                	slli	s1,s1,0x3
    80000c30:	00010797          	auipc	a5,0x10
    80000c34:	65878793          	addi	a5,a5,1624 # 80011288 <kmem>
    80000c38:	94be                	add	s1,s1,a5
    80000c3a:	f098                	sd	a4,32(s1)
      release(&kmem[i].lock);
    80000c3c:	854e                	mv	a0,s3
    80000c3e:	00000097          	auipc	ra,0x0
    80000c42:	184080e7          	jalr	388(ra) # 80000dc2 <release>
  release(&kmem[id].lock);
    80000c46:	8556                	mv	a0,s5
    80000c48:	00000097          	auipc	ra,0x0
    80000c4c:	17a080e7          	jalr	378(ra) # 80000dc2 <release>
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c50:	6605                	lui	a2,0x1
    80000c52:	4595                	li	a1,5
    80000c54:	8552                	mv	a0,s4
    80000c56:	00000097          	auipc	ra,0x0
    80000c5a:	47c080e7          	jalr	1148(ra) # 800010d2 <memset>
}
    80000c5e:	8552                	mv	a0,s4
    80000c60:	60a6                	ld	ra,72(sp)
    80000c62:	6406                	ld	s0,64(sp)
    80000c64:	74e2                	ld	s1,56(sp)
    80000c66:	7942                	ld	s2,48(sp)
    80000c68:	79a2                	ld	s3,40(sp)
    80000c6a:	7a02                	ld	s4,32(sp)
    80000c6c:	6ae2                	ld	s5,24(sp)
    80000c6e:	6b42                	ld	s6,16(sp)
    80000c70:	6ba2                	ld	s7,8(sp)
    80000c72:	6c02                	ld	s8,0(sp)
    80000c74:	6161                	addi	sp,sp,80
    80000c76:	8082                	ret

0000000080000c78 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c78:	411c                	lw	a5,0(a0)
    80000c7a:	e399                	bnez	a5,80000c80 <holding+0x8>
    80000c7c:	4501                	li	a0,0
  return r;
}
    80000c7e:	8082                	ret
{
    80000c80:	1101                	addi	sp,sp,-32
    80000c82:	ec06                	sd	ra,24(sp)
    80000c84:	e822                	sd	s0,16(sp)
    80000c86:	e426                	sd	s1,8(sp)
    80000c88:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c8a:	6904                	ld	s1,16(a0)
    80000c8c:	00001097          	auipc	ra,0x1
    80000c90:	092080e7          	jalr	146(ra) # 80001d1e <mycpu>
    80000c94:	40a48533          	sub	a0,s1,a0
    80000c98:	00153513          	seqz	a0,a0
}
    80000c9c:	60e2                	ld	ra,24(sp)
    80000c9e:	6442                	ld	s0,16(sp)
    80000ca0:	64a2                	ld	s1,8(sp)
    80000ca2:	6105                	addi	sp,sp,32
    80000ca4:	8082                	ret

0000000080000ca6 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000ca6:	1101                	addi	sp,sp,-32
    80000ca8:	ec06                	sd	ra,24(sp)
    80000caa:	e822                	sd	s0,16(sp)
    80000cac:	e426                	sd	s1,8(sp)
    80000cae:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb0:	100024f3          	csrr	s1,sstatus
    80000cb4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cb8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cba:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cbe:	00001097          	auipc	ra,0x1
    80000cc2:	060080e7          	jalr	96(ra) # 80001d1e <mycpu>
    80000cc6:	5d3c                	lw	a5,120(a0)
    80000cc8:	cf89                	beqz	a5,80000ce2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cca:	00001097          	auipc	ra,0x1
    80000cce:	054080e7          	jalr	84(ra) # 80001d1e <mycpu>
    80000cd2:	5d3c                	lw	a5,120(a0)
    80000cd4:	2785                	addiw	a5,a5,1
    80000cd6:	dd3c                	sw	a5,120(a0)
}
    80000cd8:	60e2                	ld	ra,24(sp)
    80000cda:	6442                	ld	s0,16(sp)
    80000cdc:	64a2                	ld	s1,8(sp)
    80000cde:	6105                	addi	sp,sp,32
    80000ce0:	8082                	ret
    mycpu()->intena = old;
    80000ce2:	00001097          	auipc	ra,0x1
    80000ce6:	03c080e7          	jalr	60(ra) # 80001d1e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cea:	8085                	srli	s1,s1,0x1
    80000cec:	8885                	andi	s1,s1,1
    80000cee:	dd64                	sw	s1,124(a0)
    80000cf0:	bfe9                	j	80000cca <push_off+0x24>

0000000080000cf2 <acquire>:
{
    80000cf2:	1101                	addi	sp,sp,-32
    80000cf4:	ec06                	sd	ra,24(sp)
    80000cf6:	e822                	sd	s0,16(sp)
    80000cf8:	e426                	sd	s1,8(sp)
    80000cfa:	1000                	addi	s0,sp,32
    80000cfc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cfe:	00000097          	auipc	ra,0x0
    80000d02:	fa8080e7          	jalr	-88(ra) # 80000ca6 <push_off>
  if(holding(lk))
    80000d06:	8526                	mv	a0,s1
    80000d08:	00000097          	auipc	ra,0x0
    80000d0c:	f70080e7          	jalr	-144(ra) # 80000c78 <holding>
    80000d10:	e911                	bnez	a0,80000d24 <acquire+0x32>
    __sync_fetch_and_add(&(lk->n), 1);
    80000d12:	4785                	li	a5,1
    80000d14:	01c48713          	addi	a4,s1,28
    80000d18:	0f50000f          	fence	iorw,ow
    80000d1c:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d20:	4705                	li	a4,1
    80000d22:	a839                	j	80000d40 <acquire+0x4e>
    panic("acquire");
    80000d24:	00007517          	auipc	a0,0x7
    80000d28:	34c50513          	addi	a0,a0,844 # 80008070 <digits+0x30>
    80000d2c:	00000097          	auipc	ra,0x0
    80000d30:	824080e7          	jalr	-2012(ra) # 80000550 <panic>
    __sync_fetch_and_add(&(lk->nts), 1);
    80000d34:	01848793          	addi	a5,s1,24
    80000d38:	0f50000f          	fence	iorw,ow
    80000d3c:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d40:	87ba                	mv	a5,a4
    80000d42:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d46:	2781                	sext.w	a5,a5
    80000d48:	f7f5                	bnez	a5,80000d34 <acquire+0x42>
  __sync_synchronize();
    80000d4a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d4e:	00001097          	auipc	ra,0x1
    80000d52:	fd0080e7          	jalr	-48(ra) # 80001d1e <mycpu>
    80000d56:	e888                	sd	a0,16(s1)
}
    80000d58:	60e2                	ld	ra,24(sp)
    80000d5a:	6442                	ld	s0,16(sp)
    80000d5c:	64a2                	ld	s1,8(sp)
    80000d5e:	6105                	addi	sp,sp,32
    80000d60:	8082                	ret

0000000080000d62 <pop_off>:

void
pop_off(void)
{
    80000d62:	1141                	addi	sp,sp,-16
    80000d64:	e406                	sd	ra,8(sp)
    80000d66:	e022                	sd	s0,0(sp)
    80000d68:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d6a:	00001097          	auipc	ra,0x1
    80000d6e:	fb4080e7          	jalr	-76(ra) # 80001d1e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d72:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d76:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d78:	e78d                	bnez	a5,80000da2 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d7a:	5d3c                	lw	a5,120(a0)
    80000d7c:	02f05b63          	blez	a5,80000db2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d80:	37fd                	addiw	a5,a5,-1
    80000d82:	0007871b          	sext.w	a4,a5
    80000d86:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d88:	eb09                	bnez	a4,80000d9a <pop_off+0x38>
    80000d8a:	5d7c                	lw	a5,124(a0)
    80000d8c:	c799                	beqz	a5,80000d9a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d8e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d92:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d96:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret
    panic("pop_off - interruptible");
    80000da2:	00007517          	auipc	a0,0x7
    80000da6:	2d650513          	addi	a0,a0,726 # 80008078 <digits+0x38>
    80000daa:	fffff097          	auipc	ra,0xfffff
    80000dae:	7a6080e7          	jalr	1958(ra) # 80000550 <panic>
    panic("pop_off");
    80000db2:	00007517          	auipc	a0,0x7
    80000db6:	2de50513          	addi	a0,a0,734 # 80008090 <digits+0x50>
    80000dba:	fffff097          	auipc	ra,0xfffff
    80000dbe:	796080e7          	jalr	1942(ra) # 80000550 <panic>

0000000080000dc2 <release>:
{
    80000dc2:	1101                	addi	sp,sp,-32
    80000dc4:	ec06                	sd	ra,24(sp)
    80000dc6:	e822                	sd	s0,16(sp)
    80000dc8:	e426                	sd	s1,8(sp)
    80000dca:	1000                	addi	s0,sp,32
    80000dcc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dce:	00000097          	auipc	ra,0x0
    80000dd2:	eaa080e7          	jalr	-342(ra) # 80000c78 <holding>
    80000dd6:	c115                	beqz	a0,80000dfa <release+0x38>
  lk->cpu = 0;
    80000dd8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ddc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000de0:	0f50000f          	fence	iorw,ow
    80000de4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000de8:	00000097          	auipc	ra,0x0
    80000dec:	f7a080e7          	jalr	-134(ra) # 80000d62 <pop_off>
}
    80000df0:	60e2                	ld	ra,24(sp)
    80000df2:	6442                	ld	s0,16(sp)
    80000df4:	64a2                	ld	s1,8(sp)
    80000df6:	6105                	addi	sp,sp,32
    80000df8:	8082                	ret
    panic("release");
    80000dfa:	00007517          	auipc	a0,0x7
    80000dfe:	29e50513          	addi	a0,a0,670 # 80008098 <digits+0x58>
    80000e02:	fffff097          	auipc	ra,0xfffff
    80000e06:	74e080e7          	jalr	1870(ra) # 80000550 <panic>

0000000080000e0a <freelock>:
{
    80000e0a:	1101                	addi	sp,sp,-32
    80000e0c:	ec06                	sd	ra,24(sp)
    80000e0e:	e822                	sd	s0,16(sp)
    80000e10:	e426                	sd	s1,8(sp)
    80000e12:	1000                	addi	s0,sp,32
    80000e14:	84aa                	mv	s1,a0
  acquire(&lock_locks);
    80000e16:	00010517          	auipc	a0,0x10
    80000e1a:	5b250513          	addi	a0,a0,1458 # 800113c8 <lock_locks>
    80000e1e:	00000097          	auipc	ra,0x0
    80000e22:	ed4080e7          	jalr	-300(ra) # 80000cf2 <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e26:	00010717          	auipc	a4,0x10
    80000e2a:	5c270713          	addi	a4,a4,1474 # 800113e8 <locks>
    80000e2e:	4781                	li	a5,0
    80000e30:	1f400613          	li	a2,500
    if(locks[i] == lk) {
    80000e34:	6314                	ld	a3,0(a4)
    80000e36:	00968763          	beq	a3,s1,80000e44 <freelock+0x3a>
  for (i = 0; i < NLOCK; i++) {
    80000e3a:	2785                	addiw	a5,a5,1
    80000e3c:	0721                	addi	a4,a4,8
    80000e3e:	fec79be3          	bne	a5,a2,80000e34 <freelock+0x2a>
    80000e42:	a809                	j	80000e54 <freelock+0x4a>
      locks[i] = 0;
    80000e44:	078e                	slli	a5,a5,0x3
    80000e46:	00010717          	auipc	a4,0x10
    80000e4a:	5a270713          	addi	a4,a4,1442 # 800113e8 <locks>
    80000e4e:	97ba                	add	a5,a5,a4
    80000e50:	0007b023          	sd	zero,0(a5)
  release(&lock_locks);
    80000e54:	00010517          	auipc	a0,0x10
    80000e58:	57450513          	addi	a0,a0,1396 # 800113c8 <lock_locks>
    80000e5c:	00000097          	auipc	ra,0x0
    80000e60:	f66080e7          	jalr	-154(ra) # 80000dc2 <release>
}
    80000e64:	60e2                	ld	ra,24(sp)
    80000e66:	6442                	ld	s0,16(sp)
    80000e68:	64a2                	ld	s1,8(sp)
    80000e6a:	6105                	addi	sp,sp,32
    80000e6c:	8082                	ret

0000000080000e6e <initlock>:
{
    80000e6e:	1101                	addi	sp,sp,-32
    80000e70:	ec06                	sd	ra,24(sp)
    80000e72:	e822                	sd	s0,16(sp)
    80000e74:	e426                	sd	s1,8(sp)
    80000e76:	1000                	addi	s0,sp,32
    80000e78:	84aa                	mv	s1,a0
  lk->name = name;
    80000e7a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000e7c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000e80:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80000e84:	00052c23          	sw	zero,24(a0)
  lk->n = 0;
    80000e88:	00052e23          	sw	zero,28(a0)
  acquire(&lock_locks);
    80000e8c:	00010517          	auipc	a0,0x10
    80000e90:	53c50513          	addi	a0,a0,1340 # 800113c8 <lock_locks>
    80000e94:	00000097          	auipc	ra,0x0
    80000e98:	e5e080e7          	jalr	-418(ra) # 80000cf2 <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e9c:	00010717          	auipc	a4,0x10
    80000ea0:	54c70713          	addi	a4,a4,1356 # 800113e8 <locks>
    80000ea4:	4781                	li	a5,0
    80000ea6:	1f400693          	li	a3,500
    if(locks[i] == 0) {
    80000eaa:	6310                	ld	a2,0(a4)
    80000eac:	ce09                	beqz	a2,80000ec6 <initlock+0x58>
  for (i = 0; i < NLOCK; i++) {
    80000eae:	2785                	addiw	a5,a5,1
    80000eb0:	0721                	addi	a4,a4,8
    80000eb2:	fed79ce3          	bne	a5,a3,80000eaa <initlock+0x3c>
  panic("findslot");
    80000eb6:	00007517          	auipc	a0,0x7
    80000eba:	1ea50513          	addi	a0,a0,490 # 800080a0 <digits+0x60>
    80000ebe:	fffff097          	auipc	ra,0xfffff
    80000ec2:	692080e7          	jalr	1682(ra) # 80000550 <panic>
      locks[i] = lk;
    80000ec6:	078e                	slli	a5,a5,0x3
    80000ec8:	00010717          	auipc	a4,0x10
    80000ecc:	52070713          	addi	a4,a4,1312 # 800113e8 <locks>
    80000ed0:	97ba                	add	a5,a5,a4
    80000ed2:	e384                	sd	s1,0(a5)
      release(&lock_locks);
    80000ed4:	00010517          	auipc	a0,0x10
    80000ed8:	4f450513          	addi	a0,a0,1268 # 800113c8 <lock_locks>
    80000edc:	00000097          	auipc	ra,0x0
    80000ee0:	ee6080e7          	jalr	-282(ra) # 80000dc2 <release>
}
    80000ee4:	60e2                	ld	ra,24(sp)
    80000ee6:	6442                	ld	s0,16(sp)
    80000ee8:	64a2                	ld	s1,8(sp)
    80000eea:	6105                	addi	sp,sp,32
    80000eec:	8082                	ret

0000000080000eee <snprint_lock>:
#ifdef LAB_LOCK
int
snprint_lock(char *buf, int sz, struct spinlock *lk)
{
  int n = 0;
  if(lk->n > 0) {
    80000eee:	4e5c                	lw	a5,28(a2)
    80000ef0:	00f04463          	bgtz	a5,80000ef8 <snprint_lock+0xa>
  int n = 0;
    80000ef4:	4501                	li	a0,0
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
                 lk->name, lk->nts, lk->n);
  }
  return n;
}
    80000ef6:	8082                	ret
{
    80000ef8:	1141                	addi	sp,sp,-16
    80000efa:	e406                	sd	ra,8(sp)
    80000efc:	e022                	sd	s0,0(sp)
    80000efe:	0800                	addi	s0,sp,16
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
    80000f00:	4e18                	lw	a4,24(a2)
    80000f02:	6614                	ld	a3,8(a2)
    80000f04:	00007617          	auipc	a2,0x7
    80000f08:	1ac60613          	addi	a2,a2,428 # 800080b0 <digits+0x70>
    80000f0c:	00006097          	auipc	ra,0x6
    80000f10:	a56080e7          	jalr	-1450(ra) # 80006962 <snprintf>
}
    80000f14:	60a2                	ld	ra,8(sp)
    80000f16:	6402                	ld	s0,0(sp)
    80000f18:	0141                	addi	sp,sp,16
    80000f1a:	8082                	ret

0000000080000f1c <statslock>:

int
statslock(char *buf, int sz) {
    80000f1c:	7159                	addi	sp,sp,-112
    80000f1e:	f486                	sd	ra,104(sp)
    80000f20:	f0a2                	sd	s0,96(sp)
    80000f22:	eca6                	sd	s1,88(sp)
    80000f24:	e8ca                	sd	s2,80(sp)
    80000f26:	e4ce                	sd	s3,72(sp)
    80000f28:	e0d2                	sd	s4,64(sp)
    80000f2a:	fc56                	sd	s5,56(sp)
    80000f2c:	f85a                	sd	s6,48(sp)
    80000f2e:	f45e                	sd	s7,40(sp)
    80000f30:	f062                	sd	s8,32(sp)
    80000f32:	ec66                	sd	s9,24(sp)
    80000f34:	e86a                	sd	s10,16(sp)
    80000f36:	e46e                	sd	s11,8(sp)
    80000f38:	1880                	addi	s0,sp,112
    80000f3a:	8aaa                	mv	s5,a0
    80000f3c:	8b2e                	mv	s6,a1
  int n;
  int tot = 0;

  acquire(&lock_locks);
    80000f3e:	00010517          	auipc	a0,0x10
    80000f42:	48a50513          	addi	a0,a0,1162 # 800113c8 <lock_locks>
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	dac080e7          	jalr	-596(ra) # 80000cf2 <acquire>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f4e:	00007617          	auipc	a2,0x7
    80000f52:	19260613          	addi	a2,a2,402 # 800080e0 <digits+0xa0>
    80000f56:	85da                	mv	a1,s6
    80000f58:	8556                	mv	a0,s5
    80000f5a:	00006097          	auipc	ra,0x6
    80000f5e:	a08080e7          	jalr	-1528(ra) # 80006962 <snprintf>
    80000f62:	892a                	mv	s2,a0
  for(int i = 0; i < NLOCK; i++) {
    80000f64:	00010c97          	auipc	s9,0x10
    80000f68:	484c8c93          	addi	s9,s9,1156 # 800113e8 <locks>
    80000f6c:	00011c17          	auipc	s8,0x11
    80000f70:	41cc0c13          	addi	s8,s8,1052 # 80012388 <pid_lock>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f74:	84e6                	mv	s1,s9
  int tot = 0;
    80000f76:	4a01                	li	s4,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000f78:	00007b97          	auipc	s7,0x7
    80000f7c:	188b8b93          	addi	s7,s7,392 # 80008100 <digits+0xc0>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000f80:	00007d17          	auipc	s10,0x7
    80000f84:	0e8d0d13          	addi	s10,s10,232 # 80008068 <digits+0x28>
    80000f88:	a01d                	j	80000fae <statslock+0x92>
      tot += locks[i]->nts;
    80000f8a:	0009b603          	ld	a2,0(s3)
    80000f8e:	4e1c                	lw	a5,24(a2)
    80000f90:	01478a3b          	addw	s4,a5,s4
      n += snprint_lock(buf +n, sz-n, locks[i]);
    80000f94:	412b05bb          	subw	a1,s6,s2
    80000f98:	012a8533          	add	a0,s5,s2
    80000f9c:	00000097          	auipc	ra,0x0
    80000fa0:	f52080e7          	jalr	-174(ra) # 80000eee <snprint_lock>
    80000fa4:	0125093b          	addw	s2,a0,s2
  for(int i = 0; i < NLOCK; i++) {
    80000fa8:	04a1                	addi	s1,s1,8
    80000faa:	05848763          	beq	s1,s8,80000ff8 <statslock+0xdc>
    if(locks[i] == 0)
    80000fae:	89a6                	mv	s3,s1
    80000fb0:	609c                	ld	a5,0(s1)
    80000fb2:	c3b9                	beqz	a5,80000ff8 <statslock+0xdc>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000fb4:	0087bd83          	ld	s11,8(a5)
    80000fb8:	855e                	mv	a0,s7
    80000fba:	00000097          	auipc	ra,0x0
    80000fbe:	2a0080e7          	jalr	672(ra) # 8000125a <strlen>
    80000fc2:	0005061b          	sext.w	a2,a0
    80000fc6:	85de                	mv	a1,s7
    80000fc8:	856e                	mv	a0,s11
    80000fca:	00000097          	auipc	ra,0x0
    80000fce:	1e4080e7          	jalr	484(ra) # 800011ae <strncmp>
    80000fd2:	dd45                	beqz	a0,80000f8a <statslock+0x6e>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000fd4:	609c                	ld	a5,0(s1)
    80000fd6:	0087bd83          	ld	s11,8(a5)
    80000fda:	856a                	mv	a0,s10
    80000fdc:	00000097          	auipc	ra,0x0
    80000fe0:	27e080e7          	jalr	638(ra) # 8000125a <strlen>
    80000fe4:	0005061b          	sext.w	a2,a0
    80000fe8:	85ea                	mv	a1,s10
    80000fea:	856e                	mv	a0,s11
    80000fec:	00000097          	auipc	ra,0x0
    80000ff0:	1c2080e7          	jalr	450(ra) # 800011ae <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000ff4:	f955                	bnez	a0,80000fa8 <statslock+0x8c>
    80000ff6:	bf51                	j	80000f8a <statslock+0x6e>
    }
  }
  
  n += snprintf(buf+n, sz-n, "--- top 5 contended locks:\n");
    80000ff8:	00007617          	auipc	a2,0x7
    80000ffc:	11060613          	addi	a2,a2,272 # 80008108 <digits+0xc8>
    80001000:	412b05bb          	subw	a1,s6,s2
    80001004:	012a8533          	add	a0,s5,s2
    80001008:	00006097          	auipc	ra,0x6
    8000100c:	95a080e7          	jalr	-1702(ra) # 80006962 <snprintf>
    80001010:	012509bb          	addw	s3,a0,s2
    80001014:	4b95                	li	s7,5
  int last = 100000000;
    80001016:	05f5e537          	lui	a0,0x5f5e
    8000101a:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t = 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    8000101e:	4c01                	li	s8,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80001020:	00010497          	auipc	s1,0x10
    80001024:	3c848493          	addi	s1,s1,968 # 800113e8 <locks>
    for(int i = 0; i < NLOCK; i++) {
    80001028:	1f400913          	li	s2,500
    8000102c:	a881                	j	8000107c <statslock+0x160>
    8000102e:	2705                	addiw	a4,a4,1
    80001030:	06a1                	addi	a3,a3,8
    80001032:	03270063          	beq	a4,s2,80001052 <statslock+0x136>
      if(locks[i] == 0)
    80001036:	629c                	ld	a5,0(a3)
    80001038:	cf89                	beqz	a5,80001052 <statslock+0x136>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    8000103a:	4f90                	lw	a2,24(a5)
    8000103c:	00359793          	slli	a5,a1,0x3
    80001040:	97a6                	add	a5,a5,s1
    80001042:	639c                	ld	a5,0(a5)
    80001044:	4f9c                	lw	a5,24(a5)
    80001046:	fec7d4e3          	bge	a5,a2,8000102e <statslock+0x112>
    8000104a:	fea652e3          	bge	a2,a0,8000102e <statslock+0x112>
    8000104e:	85ba                	mv	a1,a4
    80001050:	bff9                	j	8000102e <statslock+0x112>
        top = i;
      }
    }
    n += snprint_lock(buf+n, sz-n, locks[top]);
    80001052:	058e                	slli	a1,a1,0x3
    80001054:	00b48d33          	add	s10,s1,a1
    80001058:	000d3603          	ld	a2,0(s10)
    8000105c:	413b05bb          	subw	a1,s6,s3
    80001060:	013a8533          	add	a0,s5,s3
    80001064:	00000097          	auipc	ra,0x0
    80001068:	e8a080e7          	jalr	-374(ra) # 80000eee <snprint_lock>
    8000106c:	013509bb          	addw	s3,a0,s3
    last = locks[top]->nts;
    80001070:	000d3783          	ld	a5,0(s10)
    80001074:	4f88                	lw	a0,24(a5)
  for(int t = 0; t < 5; t++) {
    80001076:	3bfd                	addiw	s7,s7,-1
    80001078:	000b8663          	beqz	s7,80001084 <statslock+0x168>
  int tot = 0;
    8000107c:	86e6                	mv	a3,s9
    for(int i = 0; i < NLOCK; i++) {
    8000107e:	8762                	mv	a4,s8
    int top = 0;
    80001080:	85e2                	mv	a1,s8
    80001082:	bf55                	j	80001036 <statslock+0x11a>
  }
  n += snprintf(buf+n, sz-n, "tot= %d\n", tot);
    80001084:	86d2                	mv	a3,s4
    80001086:	00007617          	auipc	a2,0x7
    8000108a:	0a260613          	addi	a2,a2,162 # 80008128 <digits+0xe8>
    8000108e:	413b05bb          	subw	a1,s6,s3
    80001092:	013a8533          	add	a0,s5,s3
    80001096:	00006097          	auipc	ra,0x6
    8000109a:	8cc080e7          	jalr	-1844(ra) # 80006962 <snprintf>
    8000109e:	013509bb          	addw	s3,a0,s3
  release(&lock_locks);  
    800010a2:	00010517          	auipc	a0,0x10
    800010a6:	32650513          	addi	a0,a0,806 # 800113c8 <lock_locks>
    800010aa:	00000097          	auipc	ra,0x0
    800010ae:	d18080e7          	jalr	-744(ra) # 80000dc2 <release>
  return n;
}
    800010b2:	854e                	mv	a0,s3
    800010b4:	70a6                	ld	ra,104(sp)
    800010b6:	7406                	ld	s0,96(sp)
    800010b8:	64e6                	ld	s1,88(sp)
    800010ba:	6946                	ld	s2,80(sp)
    800010bc:	69a6                	ld	s3,72(sp)
    800010be:	6a06                	ld	s4,64(sp)
    800010c0:	7ae2                	ld	s5,56(sp)
    800010c2:	7b42                	ld	s6,48(sp)
    800010c4:	7ba2                	ld	s7,40(sp)
    800010c6:	7c02                	ld	s8,32(sp)
    800010c8:	6ce2                	ld	s9,24(sp)
    800010ca:	6d42                	ld	s10,16(sp)
    800010cc:	6da2                	ld	s11,8(sp)
    800010ce:	6165                	addi	sp,sp,112
    800010d0:	8082                	ret

00000000800010d2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    800010d2:	1141                	addi	sp,sp,-16
    800010d4:	e422                	sd	s0,8(sp)
    800010d6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    800010d8:	ce09                	beqz	a2,800010f2 <memset+0x20>
    800010da:	87aa                	mv	a5,a0
    800010dc:	fff6071b          	addiw	a4,a2,-1
    800010e0:	1702                	slli	a4,a4,0x20
    800010e2:	9301                	srli	a4,a4,0x20
    800010e4:	0705                	addi	a4,a4,1
    800010e6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    800010e8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    800010ec:	0785                	addi	a5,a5,1
    800010ee:	fee79de3          	bne	a5,a4,800010e8 <memset+0x16>
  }
  return dst;
}
    800010f2:	6422                	ld	s0,8(sp)
    800010f4:	0141                	addi	sp,sp,16
    800010f6:	8082                	ret

00000000800010f8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    800010f8:	1141                	addi	sp,sp,-16
    800010fa:	e422                	sd	s0,8(sp)
    800010fc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    800010fe:	ca05                	beqz	a2,8000112e <memcmp+0x36>
    80001100:	fff6069b          	addiw	a3,a2,-1
    80001104:	1682                	slli	a3,a3,0x20
    80001106:	9281                	srli	a3,a3,0x20
    80001108:	0685                	addi	a3,a3,1
    8000110a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    8000110c:	00054783          	lbu	a5,0(a0)
    80001110:	0005c703          	lbu	a4,0(a1)
    80001114:	00e79863          	bne	a5,a4,80001124 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80001118:	0505                	addi	a0,a0,1
    8000111a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    8000111c:	fed518e3          	bne	a0,a3,8000110c <memcmp+0x14>
  }

  return 0;
    80001120:	4501                	li	a0,0
    80001122:	a019                	j	80001128 <memcmp+0x30>
      return *s1 - *s2;
    80001124:	40e7853b          	subw	a0,a5,a4
}
    80001128:	6422                	ld	s0,8(sp)
    8000112a:	0141                	addi	sp,sp,16
    8000112c:	8082                	ret
  return 0;
    8000112e:	4501                	li	a0,0
    80001130:	bfe5                	j	80001128 <memcmp+0x30>

0000000080001132 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80001132:	1141                	addi	sp,sp,-16
    80001134:	e422                	sd	s0,8(sp)
    80001136:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80001138:	00a5f963          	bgeu	a1,a0,8000114a <memmove+0x18>
    8000113c:	02061713          	slli	a4,a2,0x20
    80001140:	9301                	srli	a4,a4,0x20
    80001142:	00e587b3          	add	a5,a1,a4
    80001146:	02f56563          	bltu	a0,a5,80001170 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    8000114a:	fff6069b          	addiw	a3,a2,-1
    8000114e:	ce11                	beqz	a2,8000116a <memmove+0x38>
    80001150:	1682                	slli	a3,a3,0x20
    80001152:	9281                	srli	a3,a3,0x20
    80001154:	0685                	addi	a3,a3,1
    80001156:	96ae                	add	a3,a3,a1
    80001158:	87aa                	mv	a5,a0
      *d++ = *s++;
    8000115a:	0585                	addi	a1,a1,1
    8000115c:	0785                	addi	a5,a5,1
    8000115e:	fff5c703          	lbu	a4,-1(a1)
    80001162:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80001166:	fed59ae3          	bne	a1,a3,8000115a <memmove+0x28>

  return dst;
}
    8000116a:	6422                	ld	s0,8(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    d += n;
    80001170:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80001172:	fff6069b          	addiw	a3,a2,-1
    80001176:	da75                	beqz	a2,8000116a <memmove+0x38>
    80001178:	02069613          	slli	a2,a3,0x20
    8000117c:	9201                	srli	a2,a2,0x20
    8000117e:	fff64613          	not	a2,a2
    80001182:	963e                	add	a2,a2,a5
      *--d = *--s;
    80001184:	17fd                	addi	a5,a5,-1
    80001186:	177d                	addi	a4,a4,-1
    80001188:	0007c683          	lbu	a3,0(a5)
    8000118c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80001190:	fec79ae3          	bne	a5,a2,80001184 <memmove+0x52>
    80001194:	bfd9                	j	8000116a <memmove+0x38>

0000000080001196 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80001196:	1141                	addi	sp,sp,-16
    80001198:	e406                	sd	ra,8(sp)
    8000119a:	e022                	sd	s0,0(sp)
    8000119c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	f94080e7          	jalr	-108(ra) # 80001132 <memmove>
}
    800011a6:	60a2                	ld	ra,8(sp)
    800011a8:	6402                	ld	s0,0(sp)
    800011aa:	0141                	addi	sp,sp,16
    800011ac:	8082                	ret

00000000800011ae <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    800011ae:	1141                	addi	sp,sp,-16
    800011b0:	e422                	sd	s0,8(sp)
    800011b2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    800011b4:	ce11                	beqz	a2,800011d0 <strncmp+0x22>
    800011b6:	00054783          	lbu	a5,0(a0)
    800011ba:	cf89                	beqz	a5,800011d4 <strncmp+0x26>
    800011bc:	0005c703          	lbu	a4,0(a1)
    800011c0:	00f71a63          	bne	a4,a5,800011d4 <strncmp+0x26>
    n--, p++, q++;
    800011c4:	367d                	addiw	a2,a2,-1
    800011c6:	0505                	addi	a0,a0,1
    800011c8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    800011ca:	f675                	bnez	a2,800011b6 <strncmp+0x8>
  if(n == 0)
    return 0;
    800011cc:	4501                	li	a0,0
    800011ce:	a809                	j	800011e0 <strncmp+0x32>
    800011d0:	4501                	li	a0,0
    800011d2:	a039                	j	800011e0 <strncmp+0x32>
  if(n == 0)
    800011d4:	ca09                	beqz	a2,800011e6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    800011d6:	00054503          	lbu	a0,0(a0)
    800011da:	0005c783          	lbu	a5,0(a1)
    800011de:	9d1d                	subw	a0,a0,a5
}
    800011e0:	6422                	ld	s0,8(sp)
    800011e2:	0141                	addi	sp,sp,16
    800011e4:	8082                	ret
    return 0;
    800011e6:	4501                	li	a0,0
    800011e8:	bfe5                	j	800011e0 <strncmp+0x32>

00000000800011ea <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800011ea:	1141                	addi	sp,sp,-16
    800011ec:	e422                	sd	s0,8(sp)
    800011ee:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800011f0:	872a                	mv	a4,a0
    800011f2:	8832                	mv	a6,a2
    800011f4:	367d                	addiw	a2,a2,-1
    800011f6:	01005963          	blez	a6,80001208 <strncpy+0x1e>
    800011fa:	0705                	addi	a4,a4,1
    800011fc:	0005c783          	lbu	a5,0(a1)
    80001200:	fef70fa3          	sb	a5,-1(a4)
    80001204:	0585                	addi	a1,a1,1
    80001206:	f7f5                	bnez	a5,800011f2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80001208:	00c05d63          	blez	a2,80001222 <strncpy+0x38>
    8000120c:	86ba                	mv	a3,a4
    *s++ = 0;
    8000120e:	0685                	addi	a3,a3,1
    80001210:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80001214:	fff6c793          	not	a5,a3
    80001218:	9fb9                	addw	a5,a5,a4
    8000121a:	010787bb          	addw	a5,a5,a6
    8000121e:	fef048e3          	bgtz	a5,8000120e <strncpy+0x24>
  return os;
}
    80001222:	6422                	ld	s0,8(sp)
    80001224:	0141                	addi	sp,sp,16
    80001226:	8082                	ret

0000000080001228 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80001228:	1141                	addi	sp,sp,-16
    8000122a:	e422                	sd	s0,8(sp)
    8000122c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    8000122e:	02c05363          	blez	a2,80001254 <safestrcpy+0x2c>
    80001232:	fff6069b          	addiw	a3,a2,-1
    80001236:	1682                	slli	a3,a3,0x20
    80001238:	9281                	srli	a3,a3,0x20
    8000123a:	96ae                	add	a3,a3,a1
    8000123c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    8000123e:	00d58963          	beq	a1,a3,80001250 <safestrcpy+0x28>
    80001242:	0585                	addi	a1,a1,1
    80001244:	0785                	addi	a5,a5,1
    80001246:	fff5c703          	lbu	a4,-1(a1)
    8000124a:	fee78fa3          	sb	a4,-1(a5)
    8000124e:	fb65                	bnez	a4,8000123e <safestrcpy+0x16>
    ;
  *s = 0;
    80001250:	00078023          	sb	zero,0(a5)
  return os;
}
    80001254:	6422                	ld	s0,8(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <strlen>:

int
strlen(const char *s)
{
    8000125a:	1141                	addi	sp,sp,-16
    8000125c:	e422                	sd	s0,8(sp)
    8000125e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001260:	00054783          	lbu	a5,0(a0)
    80001264:	cf91                	beqz	a5,80001280 <strlen+0x26>
    80001266:	0505                	addi	a0,a0,1
    80001268:	87aa                	mv	a5,a0
    8000126a:	4685                	li	a3,1
    8000126c:	9e89                	subw	a3,a3,a0
    8000126e:	00f6853b          	addw	a0,a3,a5
    80001272:	0785                	addi	a5,a5,1
    80001274:	fff7c703          	lbu	a4,-1(a5)
    80001278:	fb7d                	bnez	a4,8000126e <strlen+0x14>
    ;
  return n;
}
    8000127a:	6422                	ld	s0,8(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret
  for(n = 0; s[n]; n++)
    80001280:	4501                	li	a0,0
    80001282:	bfe5                	j	8000127a <strlen+0x20>

0000000080001284 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001284:	1141                	addi	sp,sp,-16
    80001286:	e406                	sd	ra,8(sp)
    80001288:	e022                	sd	s0,0(sp)
    8000128a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    8000128c:	00001097          	auipc	ra,0x1
    80001290:	a82080e7          	jalr	-1406(ra) # 80001d0e <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001294:	00008717          	auipc	a4,0x8
    80001298:	d7870713          	addi	a4,a4,-648 # 8000900c <started>
  if(cpuid() == 0){
    8000129c:	c139                	beqz	a0,800012e2 <main+0x5e>
    while(started == 0)
    8000129e:	431c                	lw	a5,0(a4)
    800012a0:	2781                	sext.w	a5,a5
    800012a2:	dff5                	beqz	a5,8000129e <main+0x1a>
      ;
    __sync_synchronize();
    800012a4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    800012a8:	00001097          	auipc	ra,0x1
    800012ac:	a66080e7          	jalr	-1434(ra) # 80001d0e <cpuid>
    800012b0:	85aa                	mv	a1,a0
    800012b2:	00007517          	auipc	a0,0x7
    800012b6:	e9e50513          	addi	a0,a0,-354 # 80008150 <digits+0x110>
    800012ba:	fffff097          	auipc	ra,0xfffff
    800012be:	2e0080e7          	jalr	736(ra) # 8000059a <printf>
    kvminithart();    // turn on paging
    800012c2:	00000097          	auipc	ra,0x0
    800012c6:	186080e7          	jalr	390(ra) # 80001448 <kvminithart>
    trapinithart();   // install kernel trap vector
    800012ca:	00001097          	auipc	ra,0x1
    800012ce:	6ce080e7          	jalr	1742(ra) # 80002998 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800012d2:	00005097          	auipc	ra,0x5
    800012d6:	ece080e7          	jalr	-306(ra) # 800061a0 <plicinithart>
  }

  scheduler();        
    800012da:	00001097          	auipc	ra,0x1
    800012de:	f90080e7          	jalr	-112(ra) # 8000226a <scheduler>
    consoleinit();
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	180080e7          	jalr	384(ra) # 80000462 <consoleinit>
    statsinit();
    800012ea:	00005097          	auipc	ra,0x5
    800012ee:	59c080e7          	jalr	1436(ra) # 80006886 <statsinit>
    printfinit();
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	48e080e7          	jalr	1166(ra) # 80000780 <printfinit>
    printf("\n");
    800012fa:	00007517          	auipc	a0,0x7
    800012fe:	e6650513          	addi	a0,a0,-410 # 80008160 <digits+0x120>
    80001302:	fffff097          	auipc	ra,0xfffff
    80001306:	298080e7          	jalr	664(ra) # 8000059a <printf>
    printf("xv6 kernel is booting\n");
    8000130a:	00007517          	auipc	a0,0x7
    8000130e:	e2e50513          	addi	a0,a0,-466 # 80008138 <digits+0xf8>
    80001312:	fffff097          	auipc	ra,0xfffff
    80001316:	288080e7          	jalr	648(ra) # 8000059a <printf>
    printf("\n");
    8000131a:	00007517          	auipc	a0,0x7
    8000131e:	e4650513          	addi	a0,a0,-442 # 80008160 <digits+0x120>
    80001322:	fffff097          	auipc	ra,0xfffff
    80001326:	278080e7          	jalr	632(ra) # 8000059a <printf>
    kinit();         // physical page allocator
    8000132a:	fffff097          	auipc	ra,0xfffff
    8000132e:	7f4080e7          	jalr	2036(ra) # 80000b1e <kinit>
    kvminit();       // create kernel page table
    80001332:	00000097          	auipc	ra,0x0
    80001336:	242080e7          	jalr	578(ra) # 80001574 <kvminit>
    kvminithart();   // turn on paging
    8000133a:	00000097          	auipc	ra,0x0
    8000133e:	10e080e7          	jalr	270(ra) # 80001448 <kvminithart>
    procinit();      // process table
    80001342:	00001097          	auipc	ra,0x1
    80001346:	8fc080e7          	jalr	-1796(ra) # 80001c3e <procinit>
    trapinit();      // trap vectors
    8000134a:	00001097          	auipc	ra,0x1
    8000134e:	626080e7          	jalr	1574(ra) # 80002970 <trapinit>
    trapinithart();  // install kernel trap vector
    80001352:	00001097          	auipc	ra,0x1
    80001356:	646080e7          	jalr	1606(ra) # 80002998 <trapinithart>
    plicinit();      // set up interrupt controller
    8000135a:	00005097          	auipc	ra,0x5
    8000135e:	e30080e7          	jalr	-464(ra) # 8000618a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001362:	00005097          	auipc	ra,0x5
    80001366:	e3e080e7          	jalr	-450(ra) # 800061a0 <plicinithart>
    binit();         // buffer cache
    8000136a:	00002097          	auipc	ra,0x2
    8000136e:	d82080e7          	jalr	-638(ra) # 800030ec <binit>
    iinit();         // inode cache
    80001372:	00002097          	auipc	ra,0x2
    80001376:	650080e7          	jalr	1616(ra) # 800039c2 <iinit>
    fileinit();      // file table
    8000137a:	00003097          	auipc	ra,0x3
    8000137e:	600080e7          	jalr	1536(ra) # 8000497a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001382:	00005097          	auipc	ra,0x5
    80001386:	f40080e7          	jalr	-192(ra) # 800062c2 <virtio_disk_init>
    userinit();      // first user process
    8000138a:	00001097          	auipc	ra,0x1
    8000138e:	c7a080e7          	jalr	-902(ra) # 80002004 <userinit>
    __sync_synchronize();
    80001392:	0ff0000f          	fence
    started = 1;
    80001396:	4785                	li	a5,1
    80001398:	00008717          	auipc	a4,0x8
    8000139c:	c6f72a23          	sw	a5,-908(a4) # 8000900c <started>
    800013a0:	bf2d                	j	800012da <main+0x56>

00000000800013a2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800013a2:	7139                	addi	sp,sp,-64
    800013a4:	fc06                	sd	ra,56(sp)
    800013a6:	f822                	sd	s0,48(sp)
    800013a8:	f426                	sd	s1,40(sp)
    800013aa:	f04a                	sd	s2,32(sp)
    800013ac:	ec4e                	sd	s3,24(sp)
    800013ae:	e852                	sd	s4,16(sp)
    800013b0:	e456                	sd	s5,8(sp)
    800013b2:	e05a                	sd	s6,0(sp)
    800013b4:	0080                	addi	s0,sp,64
    800013b6:	84aa                	mv	s1,a0
    800013b8:	89ae                	mv	s3,a1
    800013ba:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800013bc:	57fd                	li	a5,-1
    800013be:	83e9                	srli	a5,a5,0x1a
    800013c0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800013c2:	4b31                	li	s6,12
  if(va >= MAXVA)
    800013c4:	04b7f263          	bgeu	a5,a1,80001408 <walk+0x66>
    panic("walk");
    800013c8:	00007517          	auipc	a0,0x7
    800013cc:	da050513          	addi	a0,a0,-608 # 80008168 <digits+0x128>
    800013d0:	fffff097          	auipc	ra,0xfffff
    800013d4:	180080e7          	jalr	384(ra) # 80000550 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800013d8:	060a8663          	beqz	s5,80001444 <walk+0xa2>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	79e080e7          	jalr	1950(ra) # 80000b7a <kalloc>
    800013e4:	84aa                	mv	s1,a0
    800013e6:	c529                	beqz	a0,80001430 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800013e8:	6605                	lui	a2,0x1
    800013ea:	4581                	li	a1,0
    800013ec:	00000097          	auipc	ra,0x0
    800013f0:	ce6080e7          	jalr	-794(ra) # 800010d2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800013f4:	00c4d793          	srli	a5,s1,0xc
    800013f8:	07aa                	slli	a5,a5,0xa
    800013fa:	0017e793          	ori	a5,a5,1
    800013fe:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001402:	3a5d                	addiw	s4,s4,-9
    80001404:	036a0063          	beq	s4,s6,80001424 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001408:	0149d933          	srl	s2,s3,s4
    8000140c:	1ff97913          	andi	s2,s2,511
    80001410:	090e                	slli	s2,s2,0x3
    80001412:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001414:	00093483          	ld	s1,0(s2)
    80001418:	0014f793          	andi	a5,s1,1
    8000141c:	dfd5                	beqz	a5,800013d8 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000141e:	80a9                	srli	s1,s1,0xa
    80001420:	04b2                	slli	s1,s1,0xc
    80001422:	b7c5                	j	80001402 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001424:	00c9d513          	srli	a0,s3,0xc
    80001428:	1ff57513          	andi	a0,a0,511
    8000142c:	050e                	slli	a0,a0,0x3
    8000142e:	9526                	add	a0,a0,s1
}
    80001430:	70e2                	ld	ra,56(sp)
    80001432:	7442                	ld	s0,48(sp)
    80001434:	74a2                	ld	s1,40(sp)
    80001436:	7902                	ld	s2,32(sp)
    80001438:	69e2                	ld	s3,24(sp)
    8000143a:	6a42                	ld	s4,16(sp)
    8000143c:	6aa2                	ld	s5,8(sp)
    8000143e:	6b02                	ld	s6,0(sp)
    80001440:	6121                	addi	sp,sp,64
    80001442:	8082                	ret
        return 0;
    80001444:	4501                	li	a0,0
    80001446:	b7ed                	j	80001430 <walk+0x8e>

0000000080001448 <kvminithart>:
{
    80001448:	1141                	addi	sp,sp,-16
    8000144a:	e422                	sd	s0,8(sp)
    8000144c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000144e:	00008797          	auipc	a5,0x8
    80001452:	bc27b783          	ld	a5,-1086(a5) # 80009010 <kernel_pagetable>
    80001456:	83b1                	srli	a5,a5,0xc
    80001458:	577d                	li	a4,-1
    8000145a:	177e                	slli	a4,a4,0x3f
    8000145c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000145e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001462:	12000073          	sfence.vma
}
    80001466:	6422                	ld	s0,8(sp)
    80001468:	0141                	addi	sp,sp,16
    8000146a:	8082                	ret

000000008000146c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000146c:	57fd                	li	a5,-1
    8000146e:	83e9                	srli	a5,a5,0x1a
    80001470:	00b7f463          	bgeu	a5,a1,80001478 <walkaddr+0xc>
    return 0;
    80001474:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001476:	8082                	ret
{
    80001478:	1141                	addi	sp,sp,-16
    8000147a:	e406                	sd	ra,8(sp)
    8000147c:	e022                	sd	s0,0(sp)
    8000147e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001480:	4601                	li	a2,0
    80001482:	00000097          	auipc	ra,0x0
    80001486:	f20080e7          	jalr	-224(ra) # 800013a2 <walk>
  if(pte == 0)
    8000148a:	c105                	beqz	a0,800014aa <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000148c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000148e:	0117f693          	andi	a3,a5,17
    80001492:	4745                	li	a4,17
    return 0;
    80001494:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001496:	00e68663          	beq	a3,a4,800014a2 <walkaddr+0x36>
}
    8000149a:	60a2                	ld	ra,8(sp)
    8000149c:	6402                	ld	s0,0(sp)
    8000149e:	0141                	addi	sp,sp,16
    800014a0:	8082                	ret
  pa = PTE2PA(*pte);
    800014a2:	00a7d513          	srli	a0,a5,0xa
    800014a6:	0532                	slli	a0,a0,0xc
  return pa;
    800014a8:	bfcd                	j	8000149a <walkaddr+0x2e>
    return 0;
    800014aa:	4501                	li	a0,0
    800014ac:	b7fd                	j	8000149a <walkaddr+0x2e>

00000000800014ae <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800014ae:	715d                	addi	sp,sp,-80
    800014b0:	e486                	sd	ra,72(sp)
    800014b2:	e0a2                	sd	s0,64(sp)
    800014b4:	fc26                	sd	s1,56(sp)
    800014b6:	f84a                	sd	s2,48(sp)
    800014b8:	f44e                	sd	s3,40(sp)
    800014ba:	f052                	sd	s4,32(sp)
    800014bc:	ec56                	sd	s5,24(sp)
    800014be:	e85a                	sd	s6,16(sp)
    800014c0:	e45e                	sd	s7,8(sp)
    800014c2:	0880                	addi	s0,sp,80
    800014c4:	8aaa                	mv	s5,a0
    800014c6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800014c8:	777d                	lui	a4,0xfffff
    800014ca:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800014ce:	167d                	addi	a2,a2,-1
    800014d0:	00b609b3          	add	s3,a2,a1
    800014d4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800014d8:	893e                	mv	s2,a5
    800014da:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800014de:	6b85                	lui	s7,0x1
    800014e0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800014e4:	4605                	li	a2,1
    800014e6:	85ca                	mv	a1,s2
    800014e8:	8556                	mv	a0,s5
    800014ea:	00000097          	auipc	ra,0x0
    800014ee:	eb8080e7          	jalr	-328(ra) # 800013a2 <walk>
    800014f2:	c51d                	beqz	a0,80001520 <mappages+0x72>
    if(*pte & PTE_V)
    800014f4:	611c                	ld	a5,0(a0)
    800014f6:	8b85                	andi	a5,a5,1
    800014f8:	ef81                	bnez	a5,80001510 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800014fa:	80b1                	srli	s1,s1,0xc
    800014fc:	04aa                	slli	s1,s1,0xa
    800014fe:	0164e4b3          	or	s1,s1,s6
    80001502:	0014e493          	ori	s1,s1,1
    80001506:	e104                	sd	s1,0(a0)
    if(a == last)
    80001508:	03390863          	beq	s2,s3,80001538 <mappages+0x8a>
    a += PGSIZE;
    8000150c:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000150e:	bfc9                	j	800014e0 <mappages+0x32>
      panic("remap");
    80001510:	00007517          	auipc	a0,0x7
    80001514:	c6050513          	addi	a0,a0,-928 # 80008170 <digits+0x130>
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	038080e7          	jalr	56(ra) # 80000550 <panic>
      return -1;
    80001520:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001522:	60a6                	ld	ra,72(sp)
    80001524:	6406                	ld	s0,64(sp)
    80001526:	74e2                	ld	s1,56(sp)
    80001528:	7942                	ld	s2,48(sp)
    8000152a:	79a2                	ld	s3,40(sp)
    8000152c:	7a02                	ld	s4,32(sp)
    8000152e:	6ae2                	ld	s5,24(sp)
    80001530:	6b42                	ld	s6,16(sp)
    80001532:	6ba2                	ld	s7,8(sp)
    80001534:	6161                	addi	sp,sp,80
    80001536:	8082                	ret
  return 0;
    80001538:	4501                	li	a0,0
    8000153a:	b7e5                	j	80001522 <mappages+0x74>

000000008000153c <kvmmap>:
{
    8000153c:	1141                	addi	sp,sp,-16
    8000153e:	e406                	sd	ra,8(sp)
    80001540:	e022                	sd	s0,0(sp)
    80001542:	0800                	addi	s0,sp,16
    80001544:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001546:	86ae                	mv	a3,a1
    80001548:	85aa                	mv	a1,a0
    8000154a:	00008517          	auipc	a0,0x8
    8000154e:	ac653503          	ld	a0,-1338(a0) # 80009010 <kernel_pagetable>
    80001552:	00000097          	auipc	ra,0x0
    80001556:	f5c080e7          	jalr	-164(ra) # 800014ae <mappages>
    8000155a:	e509                	bnez	a0,80001564 <kvmmap+0x28>
}
    8000155c:	60a2                	ld	ra,8(sp)
    8000155e:	6402                	ld	s0,0(sp)
    80001560:	0141                	addi	sp,sp,16
    80001562:	8082                	ret
    panic("kvmmap");
    80001564:	00007517          	auipc	a0,0x7
    80001568:	c1450513          	addi	a0,a0,-1004 # 80008178 <digits+0x138>
    8000156c:	fffff097          	auipc	ra,0xfffff
    80001570:	fe4080e7          	jalr	-28(ra) # 80000550 <panic>

0000000080001574 <kvminit>:
{
    80001574:	1101                	addi	sp,sp,-32
    80001576:	ec06                	sd	ra,24(sp)
    80001578:	e822                	sd	s0,16(sp)
    8000157a:	e426                	sd	s1,8(sp)
    8000157c:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	5fc080e7          	jalr	1532(ra) # 80000b7a <kalloc>
    80001586:	00008797          	auipc	a5,0x8
    8000158a:	a8a7b523          	sd	a0,-1398(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000158e:	6605                	lui	a2,0x1
    80001590:	4581                	li	a1,0
    80001592:	00000097          	auipc	ra,0x0
    80001596:	b40080e7          	jalr	-1216(ra) # 800010d2 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000159a:	4699                	li	a3,6
    8000159c:	6605                	lui	a2,0x1
    8000159e:	100005b7          	lui	a1,0x10000
    800015a2:	10000537          	lui	a0,0x10000
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	f96080e7          	jalr	-106(ra) # 8000153c <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800015ae:	4699                	li	a3,6
    800015b0:	6605                	lui	a2,0x1
    800015b2:	100015b7          	lui	a1,0x10001
    800015b6:	10001537          	lui	a0,0x10001
    800015ba:	00000097          	auipc	ra,0x0
    800015be:	f82080e7          	jalr	-126(ra) # 8000153c <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800015c2:	4699                	li	a3,6
    800015c4:	00400637          	lui	a2,0x400
    800015c8:	0c0005b7          	lui	a1,0xc000
    800015cc:	0c000537          	lui	a0,0xc000
    800015d0:	00000097          	auipc	ra,0x0
    800015d4:	f6c080e7          	jalr	-148(ra) # 8000153c <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800015d8:	00007497          	auipc	s1,0x7
    800015dc:	a2848493          	addi	s1,s1,-1496 # 80008000 <etext>
    800015e0:	46a9                	li	a3,10
    800015e2:	80007617          	auipc	a2,0x80007
    800015e6:	a1e60613          	addi	a2,a2,-1506 # 8000 <_entry-0x7fff8000>
    800015ea:	4585                	li	a1,1
    800015ec:	05fe                	slli	a1,a1,0x1f
    800015ee:	852e                	mv	a0,a1
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	f4c080e7          	jalr	-180(ra) # 8000153c <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800015f8:	4699                	li	a3,6
    800015fa:	4645                	li	a2,17
    800015fc:	066e                	slli	a2,a2,0x1b
    800015fe:	8e05                	sub	a2,a2,s1
    80001600:	85a6                	mv	a1,s1
    80001602:	8526                	mv	a0,s1
    80001604:	00000097          	auipc	ra,0x0
    80001608:	f38080e7          	jalr	-200(ra) # 8000153c <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000160c:	46a9                	li	a3,10
    8000160e:	6605                	lui	a2,0x1
    80001610:	00006597          	auipc	a1,0x6
    80001614:	9f058593          	addi	a1,a1,-1552 # 80007000 <_trampoline>
    80001618:	04000537          	lui	a0,0x4000
    8000161c:	157d                	addi	a0,a0,-1
    8000161e:	0532                	slli	a0,a0,0xc
    80001620:	00000097          	auipc	ra,0x0
    80001624:	f1c080e7          	jalr	-228(ra) # 8000153c <kvmmap>
}
    80001628:	60e2                	ld	ra,24(sp)
    8000162a:	6442                	ld	s0,16(sp)
    8000162c:	64a2                	ld	s1,8(sp)
    8000162e:	6105                	addi	sp,sp,32
    80001630:	8082                	ret

0000000080001632 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001632:	715d                	addi	sp,sp,-80
    80001634:	e486                	sd	ra,72(sp)
    80001636:	e0a2                	sd	s0,64(sp)
    80001638:	fc26                	sd	s1,56(sp)
    8000163a:	f84a                	sd	s2,48(sp)
    8000163c:	f44e                	sd	s3,40(sp)
    8000163e:	f052                	sd	s4,32(sp)
    80001640:	ec56                	sd	s5,24(sp)
    80001642:	e85a                	sd	s6,16(sp)
    80001644:	e45e                	sd	s7,8(sp)
    80001646:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001648:	03459793          	slli	a5,a1,0x34
    8000164c:	e795                	bnez	a5,80001678 <uvmunmap+0x46>
    8000164e:	8a2a                	mv	s4,a0
    80001650:	892e                	mv	s2,a1
    80001652:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001654:	0632                	slli	a2,a2,0xc
    80001656:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000165a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000165c:	6b05                	lui	s6,0x1
    8000165e:	0735e863          	bltu	a1,s3,800016ce <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001662:	60a6                	ld	ra,72(sp)
    80001664:	6406                	ld	s0,64(sp)
    80001666:	74e2                	ld	s1,56(sp)
    80001668:	7942                	ld	s2,48(sp)
    8000166a:	79a2                	ld	s3,40(sp)
    8000166c:	7a02                	ld	s4,32(sp)
    8000166e:	6ae2                	ld	s5,24(sp)
    80001670:	6b42                	ld	s6,16(sp)
    80001672:	6ba2                	ld	s7,8(sp)
    80001674:	6161                	addi	sp,sp,80
    80001676:	8082                	ret
    panic("uvmunmap: not aligned");
    80001678:	00007517          	auipc	a0,0x7
    8000167c:	b0850513          	addi	a0,a0,-1272 # 80008180 <digits+0x140>
    80001680:	fffff097          	auipc	ra,0xfffff
    80001684:	ed0080e7          	jalr	-304(ra) # 80000550 <panic>
      panic("uvmunmap: walk");
    80001688:	00007517          	auipc	a0,0x7
    8000168c:	b1050513          	addi	a0,a0,-1264 # 80008198 <digits+0x158>
    80001690:	fffff097          	auipc	ra,0xfffff
    80001694:	ec0080e7          	jalr	-320(ra) # 80000550 <panic>
      panic("uvmunmap: not mapped");
    80001698:	00007517          	auipc	a0,0x7
    8000169c:	b1050513          	addi	a0,a0,-1264 # 800081a8 <digits+0x168>
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	eb0080e7          	jalr	-336(ra) # 80000550 <panic>
      panic("uvmunmap: not a leaf");
    800016a8:	00007517          	auipc	a0,0x7
    800016ac:	b1850513          	addi	a0,a0,-1256 # 800081c0 <digits+0x180>
    800016b0:	fffff097          	auipc	ra,0xfffff
    800016b4:	ea0080e7          	jalr	-352(ra) # 80000550 <panic>
      uint64 pa = PTE2PA(*pte);
    800016b8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800016ba:	0532                	slli	a0,a0,0xc
    800016bc:	fffff097          	auipc	ra,0xfffff
    800016c0:	370080e7          	jalr	880(ra) # 80000a2c <kfree>
    *pte = 0;
    800016c4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800016c8:	995a                	add	s2,s2,s6
    800016ca:	f9397ce3          	bgeu	s2,s3,80001662 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800016ce:	4601                	li	a2,0
    800016d0:	85ca                	mv	a1,s2
    800016d2:	8552                	mv	a0,s4
    800016d4:	00000097          	auipc	ra,0x0
    800016d8:	cce080e7          	jalr	-818(ra) # 800013a2 <walk>
    800016dc:	84aa                	mv	s1,a0
    800016de:	d54d                	beqz	a0,80001688 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800016e0:	6108                	ld	a0,0(a0)
    800016e2:	00157793          	andi	a5,a0,1
    800016e6:	dbcd                	beqz	a5,80001698 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800016e8:	3ff57793          	andi	a5,a0,1023
    800016ec:	fb778ee3          	beq	a5,s7,800016a8 <uvmunmap+0x76>
    if(do_free){
    800016f0:	fc0a8ae3          	beqz	s5,800016c4 <uvmunmap+0x92>
    800016f4:	b7d1                	j	800016b8 <uvmunmap+0x86>

00000000800016f6 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800016f6:	1101                	addi	sp,sp,-32
    800016f8:	ec06                	sd	ra,24(sp)
    800016fa:	e822                	sd	s0,16(sp)
    800016fc:	e426                	sd	s1,8(sp)
    800016fe:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001700:	fffff097          	auipc	ra,0xfffff
    80001704:	47a080e7          	jalr	1146(ra) # 80000b7a <kalloc>
    80001708:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000170a:	c519                	beqz	a0,80001718 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000170c:	6605                	lui	a2,0x1
    8000170e:	4581                	li	a1,0
    80001710:	00000097          	auipc	ra,0x0
    80001714:	9c2080e7          	jalr	-1598(ra) # 800010d2 <memset>
  return pagetable;
}
    80001718:	8526                	mv	a0,s1
    8000171a:	60e2                	ld	ra,24(sp)
    8000171c:	6442                	ld	s0,16(sp)
    8000171e:	64a2                	ld	s1,8(sp)
    80001720:	6105                	addi	sp,sp,32
    80001722:	8082                	ret

0000000080001724 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001724:	7179                	addi	sp,sp,-48
    80001726:	f406                	sd	ra,40(sp)
    80001728:	f022                	sd	s0,32(sp)
    8000172a:	ec26                	sd	s1,24(sp)
    8000172c:	e84a                	sd	s2,16(sp)
    8000172e:	e44e                	sd	s3,8(sp)
    80001730:	e052                	sd	s4,0(sp)
    80001732:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001734:	6785                	lui	a5,0x1
    80001736:	04f67863          	bgeu	a2,a5,80001786 <uvminit+0x62>
    8000173a:	8a2a                	mv	s4,a0
    8000173c:	89ae                	mv	s3,a1
    8000173e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001740:	fffff097          	auipc	ra,0xfffff
    80001744:	43a080e7          	jalr	1082(ra) # 80000b7a <kalloc>
    80001748:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000174a:	6605                	lui	a2,0x1
    8000174c:	4581                	li	a1,0
    8000174e:	00000097          	auipc	ra,0x0
    80001752:	984080e7          	jalr	-1660(ra) # 800010d2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001756:	4779                	li	a4,30
    80001758:	86ca                	mv	a3,s2
    8000175a:	6605                	lui	a2,0x1
    8000175c:	4581                	li	a1,0
    8000175e:	8552                	mv	a0,s4
    80001760:	00000097          	auipc	ra,0x0
    80001764:	d4e080e7          	jalr	-690(ra) # 800014ae <mappages>
  memmove(mem, src, sz);
    80001768:	8626                	mv	a2,s1
    8000176a:	85ce                	mv	a1,s3
    8000176c:	854a                	mv	a0,s2
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	9c4080e7          	jalr	-1596(ra) # 80001132 <memmove>
}
    80001776:	70a2                	ld	ra,40(sp)
    80001778:	7402                	ld	s0,32(sp)
    8000177a:	64e2                	ld	s1,24(sp)
    8000177c:	6942                	ld	s2,16(sp)
    8000177e:	69a2                	ld	s3,8(sp)
    80001780:	6a02                	ld	s4,0(sp)
    80001782:	6145                	addi	sp,sp,48
    80001784:	8082                	ret
    panic("inituvm: more than a page");
    80001786:	00007517          	auipc	a0,0x7
    8000178a:	a5250513          	addi	a0,a0,-1454 # 800081d8 <digits+0x198>
    8000178e:	fffff097          	auipc	ra,0xfffff
    80001792:	dc2080e7          	jalr	-574(ra) # 80000550 <panic>

0000000080001796 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001796:	1101                	addi	sp,sp,-32
    80001798:	ec06                	sd	ra,24(sp)
    8000179a:	e822                	sd	s0,16(sp)
    8000179c:	e426                	sd	s1,8(sp)
    8000179e:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800017a0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800017a2:	00b67d63          	bgeu	a2,a1,800017bc <uvmdealloc+0x26>
    800017a6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800017a8:	6785                	lui	a5,0x1
    800017aa:	17fd                	addi	a5,a5,-1
    800017ac:	00f60733          	add	a4,a2,a5
    800017b0:	767d                	lui	a2,0xfffff
    800017b2:	8f71                	and	a4,a4,a2
    800017b4:	97ae                	add	a5,a5,a1
    800017b6:	8ff1                	and	a5,a5,a2
    800017b8:	00f76863          	bltu	a4,a5,800017c8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800017bc:	8526                	mv	a0,s1
    800017be:	60e2                	ld	ra,24(sp)
    800017c0:	6442                	ld	s0,16(sp)
    800017c2:	64a2                	ld	s1,8(sp)
    800017c4:	6105                	addi	sp,sp,32
    800017c6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800017c8:	8f99                	sub	a5,a5,a4
    800017ca:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800017cc:	4685                	li	a3,1
    800017ce:	0007861b          	sext.w	a2,a5
    800017d2:	85ba                	mv	a1,a4
    800017d4:	00000097          	auipc	ra,0x0
    800017d8:	e5e080e7          	jalr	-418(ra) # 80001632 <uvmunmap>
    800017dc:	b7c5                	j	800017bc <uvmdealloc+0x26>

00000000800017de <uvmalloc>:
  if(newsz < oldsz)
    800017de:	0ab66163          	bltu	a2,a1,80001880 <uvmalloc+0xa2>
{
    800017e2:	7139                	addi	sp,sp,-64
    800017e4:	fc06                	sd	ra,56(sp)
    800017e6:	f822                	sd	s0,48(sp)
    800017e8:	f426                	sd	s1,40(sp)
    800017ea:	f04a                	sd	s2,32(sp)
    800017ec:	ec4e                	sd	s3,24(sp)
    800017ee:	e852                	sd	s4,16(sp)
    800017f0:	e456                	sd	s5,8(sp)
    800017f2:	0080                	addi	s0,sp,64
    800017f4:	8aaa                	mv	s5,a0
    800017f6:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800017f8:	6985                	lui	s3,0x1
    800017fa:	19fd                	addi	s3,s3,-1
    800017fc:	95ce                	add	a1,a1,s3
    800017fe:	79fd                	lui	s3,0xfffff
    80001800:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001804:	08c9f063          	bgeu	s3,a2,80001884 <uvmalloc+0xa6>
    80001808:	894e                	mv	s2,s3
    mem = kalloc();
    8000180a:	fffff097          	auipc	ra,0xfffff
    8000180e:	370080e7          	jalr	880(ra) # 80000b7a <kalloc>
    80001812:	84aa                	mv	s1,a0
    if(mem == 0){
    80001814:	c51d                	beqz	a0,80001842 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001816:	6605                	lui	a2,0x1
    80001818:	4581                	li	a1,0
    8000181a:	00000097          	auipc	ra,0x0
    8000181e:	8b8080e7          	jalr	-1864(ra) # 800010d2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001822:	4779                	li	a4,30
    80001824:	86a6                	mv	a3,s1
    80001826:	6605                	lui	a2,0x1
    80001828:	85ca                	mv	a1,s2
    8000182a:	8556                	mv	a0,s5
    8000182c:	00000097          	auipc	ra,0x0
    80001830:	c82080e7          	jalr	-894(ra) # 800014ae <mappages>
    80001834:	e905                	bnez	a0,80001864 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001836:	6785                	lui	a5,0x1
    80001838:	993e                	add	s2,s2,a5
    8000183a:	fd4968e3          	bltu	s2,s4,8000180a <uvmalloc+0x2c>
  return newsz;
    8000183e:	8552                	mv	a0,s4
    80001840:	a809                	j	80001852 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001842:	864e                	mv	a2,s3
    80001844:	85ca                	mv	a1,s2
    80001846:	8556                	mv	a0,s5
    80001848:	00000097          	auipc	ra,0x0
    8000184c:	f4e080e7          	jalr	-178(ra) # 80001796 <uvmdealloc>
      return 0;
    80001850:	4501                	li	a0,0
}
    80001852:	70e2                	ld	ra,56(sp)
    80001854:	7442                	ld	s0,48(sp)
    80001856:	74a2                	ld	s1,40(sp)
    80001858:	7902                	ld	s2,32(sp)
    8000185a:	69e2                	ld	s3,24(sp)
    8000185c:	6a42                	ld	s4,16(sp)
    8000185e:	6aa2                	ld	s5,8(sp)
    80001860:	6121                	addi	sp,sp,64
    80001862:	8082                	ret
      kfree(mem);
    80001864:	8526                	mv	a0,s1
    80001866:	fffff097          	auipc	ra,0xfffff
    8000186a:	1c6080e7          	jalr	454(ra) # 80000a2c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000186e:	864e                	mv	a2,s3
    80001870:	85ca                	mv	a1,s2
    80001872:	8556                	mv	a0,s5
    80001874:	00000097          	auipc	ra,0x0
    80001878:	f22080e7          	jalr	-222(ra) # 80001796 <uvmdealloc>
      return 0;
    8000187c:	4501                	li	a0,0
    8000187e:	bfd1                	j	80001852 <uvmalloc+0x74>
    return oldsz;
    80001880:	852e                	mv	a0,a1
}
    80001882:	8082                	ret
  return newsz;
    80001884:	8532                	mv	a0,a2
    80001886:	b7f1                	j	80001852 <uvmalloc+0x74>

0000000080001888 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001888:	7179                	addi	sp,sp,-48
    8000188a:	f406                	sd	ra,40(sp)
    8000188c:	f022                	sd	s0,32(sp)
    8000188e:	ec26                	sd	s1,24(sp)
    80001890:	e84a                	sd	s2,16(sp)
    80001892:	e44e                	sd	s3,8(sp)
    80001894:	e052                	sd	s4,0(sp)
    80001896:	1800                	addi	s0,sp,48
    80001898:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000189a:	84aa                	mv	s1,a0
    8000189c:	6905                	lui	s2,0x1
    8000189e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018a0:	4985                	li	s3,1
    800018a2:	a821                	j	800018ba <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800018a4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800018a6:	0532                	slli	a0,a0,0xc
    800018a8:	00000097          	auipc	ra,0x0
    800018ac:	fe0080e7          	jalr	-32(ra) # 80001888 <freewalk>
      pagetable[i] = 0;
    800018b0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800018b4:	04a1                	addi	s1,s1,8
    800018b6:	03248163          	beq	s1,s2,800018d8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800018ba:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018bc:	00f57793          	andi	a5,a0,15
    800018c0:	ff3782e3          	beq	a5,s3,800018a4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800018c4:	8905                	andi	a0,a0,1
    800018c6:	d57d                	beqz	a0,800018b4 <freewalk+0x2c>
      panic("freewalk: leaf");
    800018c8:	00007517          	auipc	a0,0x7
    800018cc:	93050513          	addi	a0,a0,-1744 # 800081f8 <digits+0x1b8>
    800018d0:	fffff097          	auipc	ra,0xfffff
    800018d4:	c80080e7          	jalr	-896(ra) # 80000550 <panic>
    }
  }
  kfree((void*)pagetable);
    800018d8:	8552                	mv	a0,s4
    800018da:	fffff097          	auipc	ra,0xfffff
    800018de:	152080e7          	jalr	338(ra) # 80000a2c <kfree>
}
    800018e2:	70a2                	ld	ra,40(sp)
    800018e4:	7402                	ld	s0,32(sp)
    800018e6:	64e2                	ld	s1,24(sp)
    800018e8:	6942                	ld	s2,16(sp)
    800018ea:	69a2                	ld	s3,8(sp)
    800018ec:	6a02                	ld	s4,0(sp)
    800018ee:	6145                	addi	sp,sp,48
    800018f0:	8082                	ret

00000000800018f2 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800018f2:	1101                	addi	sp,sp,-32
    800018f4:	ec06                	sd	ra,24(sp)
    800018f6:	e822                	sd	s0,16(sp)
    800018f8:	e426                	sd	s1,8(sp)
    800018fa:	1000                	addi	s0,sp,32
    800018fc:	84aa                	mv	s1,a0
  if(sz > 0)
    800018fe:	e999                	bnez	a1,80001914 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001900:	8526                	mv	a0,s1
    80001902:	00000097          	auipc	ra,0x0
    80001906:	f86080e7          	jalr	-122(ra) # 80001888 <freewalk>
}
    8000190a:	60e2                	ld	ra,24(sp)
    8000190c:	6442                	ld	s0,16(sp)
    8000190e:	64a2                	ld	s1,8(sp)
    80001910:	6105                	addi	sp,sp,32
    80001912:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001914:	6605                	lui	a2,0x1
    80001916:	167d                	addi	a2,a2,-1
    80001918:	962e                	add	a2,a2,a1
    8000191a:	4685                	li	a3,1
    8000191c:	8231                	srli	a2,a2,0xc
    8000191e:	4581                	li	a1,0
    80001920:	00000097          	auipc	ra,0x0
    80001924:	d12080e7          	jalr	-750(ra) # 80001632 <uvmunmap>
    80001928:	bfe1                	j	80001900 <uvmfree+0xe>

000000008000192a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000192a:	c679                	beqz	a2,800019f8 <uvmcopy+0xce>
{
    8000192c:	715d                	addi	sp,sp,-80
    8000192e:	e486                	sd	ra,72(sp)
    80001930:	e0a2                	sd	s0,64(sp)
    80001932:	fc26                	sd	s1,56(sp)
    80001934:	f84a                	sd	s2,48(sp)
    80001936:	f44e                	sd	s3,40(sp)
    80001938:	f052                	sd	s4,32(sp)
    8000193a:	ec56                	sd	s5,24(sp)
    8000193c:	e85a                	sd	s6,16(sp)
    8000193e:	e45e                	sd	s7,8(sp)
    80001940:	0880                	addi	s0,sp,80
    80001942:	8b2a                	mv	s6,a0
    80001944:	8aae                	mv	s5,a1
    80001946:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001948:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000194a:	4601                	li	a2,0
    8000194c:	85ce                	mv	a1,s3
    8000194e:	855a                	mv	a0,s6
    80001950:	00000097          	auipc	ra,0x0
    80001954:	a52080e7          	jalr	-1454(ra) # 800013a2 <walk>
    80001958:	c531                	beqz	a0,800019a4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000195a:	6118                	ld	a4,0(a0)
    8000195c:	00177793          	andi	a5,a4,1
    80001960:	cbb1                	beqz	a5,800019b4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001962:	00a75593          	srli	a1,a4,0xa
    80001966:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000196a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000196e:	fffff097          	auipc	ra,0xfffff
    80001972:	20c080e7          	jalr	524(ra) # 80000b7a <kalloc>
    80001976:	892a                	mv	s2,a0
    80001978:	c939                	beqz	a0,800019ce <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000197a:	6605                	lui	a2,0x1
    8000197c:	85de                	mv	a1,s7
    8000197e:	fffff097          	auipc	ra,0xfffff
    80001982:	7b4080e7          	jalr	1972(ra) # 80001132 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001986:	8726                	mv	a4,s1
    80001988:	86ca                	mv	a3,s2
    8000198a:	6605                	lui	a2,0x1
    8000198c:	85ce                	mv	a1,s3
    8000198e:	8556                	mv	a0,s5
    80001990:	00000097          	auipc	ra,0x0
    80001994:	b1e080e7          	jalr	-1250(ra) # 800014ae <mappages>
    80001998:	e515                	bnez	a0,800019c4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000199a:	6785                	lui	a5,0x1
    8000199c:	99be                	add	s3,s3,a5
    8000199e:	fb49e6e3          	bltu	s3,s4,8000194a <uvmcopy+0x20>
    800019a2:	a081                	j	800019e2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800019a4:	00007517          	auipc	a0,0x7
    800019a8:	86450513          	addi	a0,a0,-1948 # 80008208 <digits+0x1c8>
    800019ac:	fffff097          	auipc	ra,0xfffff
    800019b0:	ba4080e7          	jalr	-1116(ra) # 80000550 <panic>
      panic("uvmcopy: page not present");
    800019b4:	00007517          	auipc	a0,0x7
    800019b8:	87450513          	addi	a0,a0,-1932 # 80008228 <digits+0x1e8>
    800019bc:	fffff097          	auipc	ra,0xfffff
    800019c0:	b94080e7          	jalr	-1132(ra) # 80000550 <panic>
      kfree(mem);
    800019c4:	854a                	mv	a0,s2
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	066080e7          	jalr	102(ra) # 80000a2c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800019ce:	4685                	li	a3,1
    800019d0:	00c9d613          	srli	a2,s3,0xc
    800019d4:	4581                	li	a1,0
    800019d6:	8556                	mv	a0,s5
    800019d8:	00000097          	auipc	ra,0x0
    800019dc:	c5a080e7          	jalr	-934(ra) # 80001632 <uvmunmap>
  return -1;
    800019e0:	557d                	li	a0,-1
}
    800019e2:	60a6                	ld	ra,72(sp)
    800019e4:	6406                	ld	s0,64(sp)
    800019e6:	74e2                	ld	s1,56(sp)
    800019e8:	7942                	ld	s2,48(sp)
    800019ea:	79a2                	ld	s3,40(sp)
    800019ec:	7a02                	ld	s4,32(sp)
    800019ee:	6ae2                	ld	s5,24(sp)
    800019f0:	6b42                	ld	s6,16(sp)
    800019f2:	6ba2                	ld	s7,8(sp)
    800019f4:	6161                	addi	sp,sp,80
    800019f6:	8082                	ret
  return 0;
    800019f8:	4501                	li	a0,0
}
    800019fa:	8082                	ret

00000000800019fc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800019fc:	1141                	addi	sp,sp,-16
    800019fe:	e406                	sd	ra,8(sp)
    80001a00:	e022                	sd	s0,0(sp)
    80001a02:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001a04:	4601                	li	a2,0
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	99c080e7          	jalr	-1636(ra) # 800013a2 <walk>
  if(pte == 0)
    80001a0e:	c901                	beqz	a0,80001a1e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001a10:	611c                	ld	a5,0(a0)
    80001a12:	9bbd                	andi	a5,a5,-17
    80001a14:	e11c                	sd	a5,0(a0)
}
    80001a16:	60a2                	ld	ra,8(sp)
    80001a18:	6402                	ld	s0,0(sp)
    80001a1a:	0141                	addi	sp,sp,16
    80001a1c:	8082                	ret
    panic("uvmclear");
    80001a1e:	00007517          	auipc	a0,0x7
    80001a22:	82a50513          	addi	a0,a0,-2006 # 80008248 <digits+0x208>
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	b2a080e7          	jalr	-1238(ra) # 80000550 <panic>

0000000080001a2e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a2e:	c6bd                	beqz	a3,80001a9c <copyout+0x6e>
{
    80001a30:	715d                	addi	sp,sp,-80
    80001a32:	e486                	sd	ra,72(sp)
    80001a34:	e0a2                	sd	s0,64(sp)
    80001a36:	fc26                	sd	s1,56(sp)
    80001a38:	f84a                	sd	s2,48(sp)
    80001a3a:	f44e                	sd	s3,40(sp)
    80001a3c:	f052                	sd	s4,32(sp)
    80001a3e:	ec56                	sd	s5,24(sp)
    80001a40:	e85a                	sd	s6,16(sp)
    80001a42:	e45e                	sd	s7,8(sp)
    80001a44:	e062                	sd	s8,0(sp)
    80001a46:	0880                	addi	s0,sp,80
    80001a48:	8b2a                	mv	s6,a0
    80001a4a:	8c2e                	mv	s8,a1
    80001a4c:	8a32                	mv	s4,a2
    80001a4e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001a50:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001a52:	6a85                	lui	s5,0x1
    80001a54:	a015                	j	80001a78 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001a56:	9562                	add	a0,a0,s8
    80001a58:	0004861b          	sext.w	a2,s1
    80001a5c:	85d2                	mv	a1,s4
    80001a5e:	41250533          	sub	a0,a0,s2
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	6d0080e7          	jalr	1744(ra) # 80001132 <memmove>

    len -= n;
    80001a6a:	409989b3          	sub	s3,s3,s1
    src += n;
    80001a6e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001a70:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001a74:	02098263          	beqz	s3,80001a98 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001a78:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a7c:	85ca                	mv	a1,s2
    80001a7e:	855a                	mv	a0,s6
    80001a80:	00000097          	auipc	ra,0x0
    80001a84:	9ec080e7          	jalr	-1556(ra) # 8000146c <walkaddr>
    if(pa0 == 0)
    80001a88:	cd01                	beqz	a0,80001aa0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001a8a:	418904b3          	sub	s1,s2,s8
    80001a8e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001a90:	fc99f3e3          	bgeu	s3,s1,80001a56 <copyout+0x28>
    80001a94:	84ce                	mv	s1,s3
    80001a96:	b7c1                	j	80001a56 <copyout+0x28>
  }
  return 0;
    80001a98:	4501                	li	a0,0
    80001a9a:	a021                	j	80001aa2 <copyout+0x74>
    80001a9c:	4501                	li	a0,0
}
    80001a9e:	8082                	ret
      return -1;
    80001aa0:	557d                	li	a0,-1
}
    80001aa2:	60a6                	ld	ra,72(sp)
    80001aa4:	6406                	ld	s0,64(sp)
    80001aa6:	74e2                	ld	s1,56(sp)
    80001aa8:	7942                	ld	s2,48(sp)
    80001aaa:	79a2                	ld	s3,40(sp)
    80001aac:	7a02                	ld	s4,32(sp)
    80001aae:	6ae2                	ld	s5,24(sp)
    80001ab0:	6b42                	ld	s6,16(sp)
    80001ab2:	6ba2                	ld	s7,8(sp)
    80001ab4:	6c02                	ld	s8,0(sp)
    80001ab6:	6161                	addi	sp,sp,80
    80001ab8:	8082                	ret

0000000080001aba <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001aba:	c6bd                	beqz	a3,80001b28 <copyin+0x6e>
{
    80001abc:	715d                	addi	sp,sp,-80
    80001abe:	e486                	sd	ra,72(sp)
    80001ac0:	e0a2                	sd	s0,64(sp)
    80001ac2:	fc26                	sd	s1,56(sp)
    80001ac4:	f84a                	sd	s2,48(sp)
    80001ac6:	f44e                	sd	s3,40(sp)
    80001ac8:	f052                	sd	s4,32(sp)
    80001aca:	ec56                	sd	s5,24(sp)
    80001acc:	e85a                	sd	s6,16(sp)
    80001ace:	e45e                	sd	s7,8(sp)
    80001ad0:	e062                	sd	s8,0(sp)
    80001ad2:	0880                	addi	s0,sp,80
    80001ad4:	8b2a                	mv	s6,a0
    80001ad6:	8a2e                	mv	s4,a1
    80001ad8:	8c32                	mv	s8,a2
    80001ada:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001adc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001ade:	6a85                	lui	s5,0x1
    80001ae0:	a015                	j	80001b04 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001ae2:	9562                	add	a0,a0,s8
    80001ae4:	0004861b          	sext.w	a2,s1
    80001ae8:	412505b3          	sub	a1,a0,s2
    80001aec:	8552                	mv	a0,s4
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	644080e7          	jalr	1604(ra) # 80001132 <memmove>

    len -= n;
    80001af6:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001afa:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001afc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001b00:	02098263          	beqz	s3,80001b24 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001b04:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001b08:	85ca                	mv	a1,s2
    80001b0a:	855a                	mv	a0,s6
    80001b0c:	00000097          	auipc	ra,0x0
    80001b10:	960080e7          	jalr	-1696(ra) # 8000146c <walkaddr>
    if(pa0 == 0)
    80001b14:	cd01                	beqz	a0,80001b2c <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001b16:	418904b3          	sub	s1,s2,s8
    80001b1a:	94d6                	add	s1,s1,s5
    if(n > len)
    80001b1c:	fc99f3e3          	bgeu	s3,s1,80001ae2 <copyin+0x28>
    80001b20:	84ce                	mv	s1,s3
    80001b22:	b7c1                	j	80001ae2 <copyin+0x28>
  }
  return 0;
    80001b24:	4501                	li	a0,0
    80001b26:	a021                	j	80001b2e <copyin+0x74>
    80001b28:	4501                	li	a0,0
}
    80001b2a:	8082                	ret
      return -1;
    80001b2c:	557d                	li	a0,-1
}
    80001b2e:	60a6                	ld	ra,72(sp)
    80001b30:	6406                	ld	s0,64(sp)
    80001b32:	74e2                	ld	s1,56(sp)
    80001b34:	7942                	ld	s2,48(sp)
    80001b36:	79a2                	ld	s3,40(sp)
    80001b38:	7a02                	ld	s4,32(sp)
    80001b3a:	6ae2                	ld	s5,24(sp)
    80001b3c:	6b42                	ld	s6,16(sp)
    80001b3e:	6ba2                	ld	s7,8(sp)
    80001b40:	6c02                	ld	s8,0(sp)
    80001b42:	6161                	addi	sp,sp,80
    80001b44:	8082                	ret

0000000080001b46 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001b46:	c6c5                	beqz	a3,80001bee <copyinstr+0xa8>
{
    80001b48:	715d                	addi	sp,sp,-80
    80001b4a:	e486                	sd	ra,72(sp)
    80001b4c:	e0a2                	sd	s0,64(sp)
    80001b4e:	fc26                	sd	s1,56(sp)
    80001b50:	f84a                	sd	s2,48(sp)
    80001b52:	f44e                	sd	s3,40(sp)
    80001b54:	f052                	sd	s4,32(sp)
    80001b56:	ec56                	sd	s5,24(sp)
    80001b58:	e85a                	sd	s6,16(sp)
    80001b5a:	e45e                	sd	s7,8(sp)
    80001b5c:	0880                	addi	s0,sp,80
    80001b5e:	8a2a                	mv	s4,a0
    80001b60:	8b2e                	mv	s6,a1
    80001b62:	8bb2                	mv	s7,a2
    80001b64:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001b66:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b68:	6985                	lui	s3,0x1
    80001b6a:	a035                	j	80001b96 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001b6c:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001b70:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001b72:	0017b793          	seqz	a5,a5
    80001b76:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001b7a:	60a6                	ld	ra,72(sp)
    80001b7c:	6406                	ld	s0,64(sp)
    80001b7e:	74e2                	ld	s1,56(sp)
    80001b80:	7942                	ld	s2,48(sp)
    80001b82:	79a2                	ld	s3,40(sp)
    80001b84:	7a02                	ld	s4,32(sp)
    80001b86:	6ae2                	ld	s5,24(sp)
    80001b88:	6b42                	ld	s6,16(sp)
    80001b8a:	6ba2                	ld	s7,8(sp)
    80001b8c:	6161                	addi	sp,sp,80
    80001b8e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001b90:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001b94:	c8a9                	beqz	s1,80001be6 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001b96:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001b9a:	85ca                	mv	a1,s2
    80001b9c:	8552                	mv	a0,s4
    80001b9e:	00000097          	auipc	ra,0x0
    80001ba2:	8ce080e7          	jalr	-1842(ra) # 8000146c <walkaddr>
    if(pa0 == 0)
    80001ba6:	c131                	beqz	a0,80001bea <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001ba8:	41790833          	sub	a6,s2,s7
    80001bac:	984e                	add	a6,a6,s3
    if(n > max)
    80001bae:	0104f363          	bgeu	s1,a6,80001bb4 <copyinstr+0x6e>
    80001bb2:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001bb4:	955e                	add	a0,a0,s7
    80001bb6:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001bba:	fc080be3          	beqz	a6,80001b90 <copyinstr+0x4a>
    80001bbe:	985a                	add	a6,a6,s6
    80001bc0:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001bc2:	41650633          	sub	a2,a0,s6
    80001bc6:	14fd                	addi	s1,s1,-1
    80001bc8:	9b26                	add	s6,s6,s1
    80001bca:	00f60733          	add	a4,a2,a5
    80001bce:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd2fd8>
    80001bd2:	df49                	beqz	a4,80001b6c <copyinstr+0x26>
        *dst = *p;
    80001bd4:	00e78023          	sb	a4,0(a5)
      --max;
    80001bd8:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001bdc:	0785                	addi	a5,a5,1
    while(n > 0){
    80001bde:	ff0796e3          	bne	a5,a6,80001bca <copyinstr+0x84>
      dst++;
    80001be2:	8b42                	mv	s6,a6
    80001be4:	b775                	j	80001b90 <copyinstr+0x4a>
    80001be6:	4781                	li	a5,0
    80001be8:	b769                	j	80001b72 <copyinstr+0x2c>
      return -1;
    80001bea:	557d                	li	a0,-1
    80001bec:	b779                	j	80001b7a <copyinstr+0x34>
  int got_null = 0;
    80001bee:	4781                	li	a5,0
  if(got_null){
    80001bf0:	0017b793          	seqz	a5,a5
    80001bf4:	40f00533          	neg	a0,a5
}
    80001bf8:	8082                	ret

0000000080001bfa <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001bfa:	1101                	addi	sp,sp,-32
    80001bfc:	ec06                	sd	ra,24(sp)
    80001bfe:	e822                	sd	s0,16(sp)
    80001c00:	e426                	sd	s1,8(sp)
    80001c02:	1000                	addi	s0,sp,32
    80001c04:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	072080e7          	jalr	114(ra) # 80000c78 <holding>
    80001c0e:	c909                	beqz	a0,80001c20 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001c10:	789c                	ld	a5,48(s1)
    80001c12:	00978f63          	beq	a5,s1,80001c30 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001c16:	60e2                	ld	ra,24(sp)
    80001c18:	6442                	ld	s0,16(sp)
    80001c1a:	64a2                	ld	s1,8(sp)
    80001c1c:	6105                	addi	sp,sp,32
    80001c1e:	8082                	ret
    panic("wakeup1");
    80001c20:	00006517          	auipc	a0,0x6
    80001c24:	63850513          	addi	a0,a0,1592 # 80008258 <digits+0x218>
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	928080e7          	jalr	-1752(ra) # 80000550 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001c30:	5098                	lw	a4,32(s1)
    80001c32:	4785                	li	a5,1
    80001c34:	fef711e3          	bne	a4,a5,80001c16 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001c38:	4789                	li	a5,2
    80001c3a:	d09c                	sw	a5,32(s1)
}
    80001c3c:	bfe9                	j	80001c16 <wakeup1+0x1c>

0000000080001c3e <procinit>:
{
    80001c3e:	715d                	addi	sp,sp,-80
    80001c40:	e486                	sd	ra,72(sp)
    80001c42:	e0a2                	sd	s0,64(sp)
    80001c44:	fc26                	sd	s1,56(sp)
    80001c46:	f84a                	sd	s2,48(sp)
    80001c48:	f44e                	sd	s3,40(sp)
    80001c4a:	f052                	sd	s4,32(sp)
    80001c4c:	ec56                	sd	s5,24(sp)
    80001c4e:	e85a                	sd	s6,16(sp)
    80001c50:	e45e                	sd	s7,8(sp)
    80001c52:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001c54:	00006597          	auipc	a1,0x6
    80001c58:	60c58593          	addi	a1,a1,1548 # 80008260 <digits+0x220>
    80001c5c:	00010517          	auipc	a0,0x10
    80001c60:	72c50513          	addi	a0,a0,1836 # 80012388 <pid_lock>
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	20a080e7          	jalr	522(ra) # 80000e6e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c6c:	00011917          	auipc	s2,0x11
    80001c70:	b3c90913          	addi	s2,s2,-1220 # 800127a8 <proc>
      initlock(&p->lock, "proc");
    80001c74:	00006b97          	auipc	s7,0x6
    80001c78:	5f4b8b93          	addi	s7,s7,1524 # 80008268 <digits+0x228>
      uint64 va = KSTACK((int) (p - proc));
    80001c7c:	8b4a                	mv	s6,s2
    80001c7e:	00006a97          	auipc	s5,0x6
    80001c82:	382a8a93          	addi	s5,s5,898 # 80008000 <etext>
    80001c86:	040009b7          	lui	s3,0x4000
    80001c8a:	19fd                	addi	s3,s3,-1
    80001c8c:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c8e:	00016a17          	auipc	s4,0x16
    80001c92:	71aa0a13          	addi	s4,s4,1818 # 800183a8 <tickslock>
      initlock(&p->lock, "proc");
    80001c96:	85de                	mv	a1,s7
    80001c98:	854a                	mv	a0,s2
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	1d4080e7          	jalr	468(ra) # 80000e6e <initlock>
      char *pa = kalloc();
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	ed8080e7          	jalr	-296(ra) # 80000b7a <kalloc>
    80001caa:	85aa                	mv	a1,a0
      if(pa == 0)
    80001cac:	c929                	beqz	a0,80001cfe <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001cae:	416904b3          	sub	s1,s2,s6
    80001cb2:	8491                	srai	s1,s1,0x4
    80001cb4:	000ab783          	ld	a5,0(s5)
    80001cb8:	02f484b3          	mul	s1,s1,a5
    80001cbc:	2485                	addiw	s1,s1,1
    80001cbe:	00d4949b          	slliw	s1,s1,0xd
    80001cc2:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001cc6:	4699                	li	a3,6
    80001cc8:	6605                	lui	a2,0x1
    80001cca:	8526                	mv	a0,s1
    80001ccc:	00000097          	auipc	ra,0x0
    80001cd0:	870080e7          	jalr	-1936(ra) # 8000153c <kvmmap>
      p->kstack = va;
    80001cd4:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cd8:	17090913          	addi	s2,s2,368
    80001cdc:	fb491de3          	bne	s2,s4,80001c96 <procinit+0x58>
  kvminithart();
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	768080e7          	jalr	1896(ra) # 80001448 <kvminithart>
}
    80001ce8:	60a6                	ld	ra,72(sp)
    80001cea:	6406                	ld	s0,64(sp)
    80001cec:	74e2                	ld	s1,56(sp)
    80001cee:	7942                	ld	s2,48(sp)
    80001cf0:	79a2                	ld	s3,40(sp)
    80001cf2:	7a02                	ld	s4,32(sp)
    80001cf4:	6ae2                	ld	s5,24(sp)
    80001cf6:	6b42                	ld	s6,16(sp)
    80001cf8:	6ba2                	ld	s7,8(sp)
    80001cfa:	6161                	addi	sp,sp,80
    80001cfc:	8082                	ret
        panic("kalloc");
    80001cfe:	00006517          	auipc	a0,0x6
    80001d02:	57250513          	addi	a0,a0,1394 # 80008270 <digits+0x230>
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	84a080e7          	jalr	-1974(ra) # 80000550 <panic>

0000000080001d0e <cpuid>:
{
    80001d0e:	1141                	addi	sp,sp,-16
    80001d10:	e422                	sd	s0,8(sp)
    80001d12:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d14:	8512                	mv	a0,tp
}
    80001d16:	2501                	sext.w	a0,a0
    80001d18:	6422                	ld	s0,8(sp)
    80001d1a:	0141                	addi	sp,sp,16
    80001d1c:	8082                	ret

0000000080001d1e <mycpu>:
mycpu(void) {
    80001d1e:	1141                	addi	sp,sp,-16
    80001d20:	e422                	sd	s0,8(sp)
    80001d22:	0800                	addi	s0,sp,16
    80001d24:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001d26:	2781                	sext.w	a5,a5
    80001d28:	079e                	slli	a5,a5,0x7
}
    80001d2a:	00010517          	auipc	a0,0x10
    80001d2e:	67e50513          	addi	a0,a0,1662 # 800123a8 <cpus>
    80001d32:	953e                	add	a0,a0,a5
    80001d34:	6422                	ld	s0,8(sp)
    80001d36:	0141                	addi	sp,sp,16
    80001d38:	8082                	ret

0000000080001d3a <myproc>:
myproc(void) {
    80001d3a:	1101                	addi	sp,sp,-32
    80001d3c:	ec06                	sd	ra,24(sp)
    80001d3e:	e822                	sd	s0,16(sp)
    80001d40:	e426                	sd	s1,8(sp)
    80001d42:	1000                	addi	s0,sp,32
  push_off();
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	f62080e7          	jalr	-158(ra) # 80000ca6 <push_off>
    80001d4c:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001d4e:	2781                	sext.w	a5,a5
    80001d50:	079e                	slli	a5,a5,0x7
    80001d52:	00010717          	auipc	a4,0x10
    80001d56:	63670713          	addi	a4,a4,1590 # 80012388 <pid_lock>
    80001d5a:	97ba                	add	a5,a5,a4
    80001d5c:	7384                	ld	s1,32(a5)
  pop_off();
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	004080e7          	jalr	4(ra) # 80000d62 <pop_off>
}
    80001d66:	8526                	mv	a0,s1
    80001d68:	60e2                	ld	ra,24(sp)
    80001d6a:	6442                	ld	s0,16(sp)
    80001d6c:	64a2                	ld	s1,8(sp)
    80001d6e:	6105                	addi	sp,sp,32
    80001d70:	8082                	ret

0000000080001d72 <forkret>:
{
    80001d72:	1141                	addi	sp,sp,-16
    80001d74:	e406                	sd	ra,8(sp)
    80001d76:	e022                	sd	s0,0(sp)
    80001d78:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	fc0080e7          	jalr	-64(ra) # 80001d3a <myproc>
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	040080e7          	jalr	64(ra) # 80000dc2 <release>
  if (first) {
    80001d8a:	00007797          	auipc	a5,0x7
    80001d8e:	b367a783          	lw	a5,-1226(a5) # 800088c0 <first.1672>
    80001d92:	eb89                	bnez	a5,80001da4 <forkret+0x32>
  usertrapret();
    80001d94:	00001097          	auipc	ra,0x1
    80001d98:	c1c080e7          	jalr	-996(ra) # 800029b0 <usertrapret>
}
    80001d9c:	60a2                	ld	ra,8(sp)
    80001d9e:	6402                	ld	s0,0(sp)
    80001da0:	0141                	addi	sp,sp,16
    80001da2:	8082                	ret
    first = 0;
    80001da4:	00007797          	auipc	a5,0x7
    80001da8:	b007ae23          	sw	zero,-1252(a5) # 800088c0 <first.1672>
    fsinit(ROOTDEV);
    80001dac:	4505                	li	a0,1
    80001dae:	00002097          	auipc	ra,0x2
    80001db2:	b94080e7          	jalr	-1132(ra) # 80003942 <fsinit>
    80001db6:	bff9                	j	80001d94 <forkret+0x22>

0000000080001db8 <allocpid>:
allocpid() {
    80001db8:	1101                	addi	sp,sp,-32
    80001dba:	ec06                	sd	ra,24(sp)
    80001dbc:	e822                	sd	s0,16(sp)
    80001dbe:	e426                	sd	s1,8(sp)
    80001dc0:	e04a                	sd	s2,0(sp)
    80001dc2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001dc4:	00010917          	auipc	s2,0x10
    80001dc8:	5c490913          	addi	s2,s2,1476 # 80012388 <pid_lock>
    80001dcc:	854a                	mv	a0,s2
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	f24080e7          	jalr	-220(ra) # 80000cf2 <acquire>
  pid = nextpid;
    80001dd6:	00007797          	auipc	a5,0x7
    80001dda:	aee78793          	addi	a5,a5,-1298 # 800088c4 <nextpid>
    80001dde:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001de0:	0014871b          	addiw	a4,s1,1
    80001de4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001de6:	854a                	mv	a0,s2
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	fda080e7          	jalr	-38(ra) # 80000dc2 <release>
}
    80001df0:	8526                	mv	a0,s1
    80001df2:	60e2                	ld	ra,24(sp)
    80001df4:	6442                	ld	s0,16(sp)
    80001df6:	64a2                	ld	s1,8(sp)
    80001df8:	6902                	ld	s2,0(sp)
    80001dfa:	6105                	addi	sp,sp,32
    80001dfc:	8082                	ret

0000000080001dfe <proc_pagetable>:
{
    80001dfe:	1101                	addi	sp,sp,-32
    80001e00:	ec06                	sd	ra,24(sp)
    80001e02:	e822                	sd	s0,16(sp)
    80001e04:	e426                	sd	s1,8(sp)
    80001e06:	e04a                	sd	s2,0(sp)
    80001e08:	1000                	addi	s0,sp,32
    80001e0a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e0c:	00000097          	auipc	ra,0x0
    80001e10:	8ea080e7          	jalr	-1814(ra) # 800016f6 <uvmcreate>
    80001e14:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e16:	c121                	beqz	a0,80001e56 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e18:	4729                	li	a4,10
    80001e1a:	00005697          	auipc	a3,0x5
    80001e1e:	1e668693          	addi	a3,a3,486 # 80007000 <_trampoline>
    80001e22:	6605                	lui	a2,0x1
    80001e24:	040005b7          	lui	a1,0x4000
    80001e28:	15fd                	addi	a1,a1,-1
    80001e2a:	05b2                	slli	a1,a1,0xc
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	682080e7          	jalr	1666(ra) # 800014ae <mappages>
    80001e34:	02054863          	bltz	a0,80001e64 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e38:	4719                	li	a4,6
    80001e3a:	06093683          	ld	a3,96(s2)
    80001e3e:	6605                	lui	a2,0x1
    80001e40:	020005b7          	lui	a1,0x2000
    80001e44:	15fd                	addi	a1,a1,-1
    80001e46:	05b6                	slli	a1,a1,0xd
    80001e48:	8526                	mv	a0,s1
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	664080e7          	jalr	1636(ra) # 800014ae <mappages>
    80001e52:	02054163          	bltz	a0,80001e74 <proc_pagetable+0x76>
}
    80001e56:	8526                	mv	a0,s1
    80001e58:	60e2                	ld	ra,24(sp)
    80001e5a:	6442                	ld	s0,16(sp)
    80001e5c:	64a2                	ld	s1,8(sp)
    80001e5e:	6902                	ld	s2,0(sp)
    80001e60:	6105                	addi	sp,sp,32
    80001e62:	8082                	ret
    uvmfree(pagetable, 0);
    80001e64:	4581                	li	a1,0
    80001e66:	8526                	mv	a0,s1
    80001e68:	00000097          	auipc	ra,0x0
    80001e6c:	a8a080e7          	jalr	-1398(ra) # 800018f2 <uvmfree>
    return 0;
    80001e70:	4481                	li	s1,0
    80001e72:	b7d5                	j	80001e56 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e74:	4681                	li	a3,0
    80001e76:	4605                	li	a2,1
    80001e78:	040005b7          	lui	a1,0x4000
    80001e7c:	15fd                	addi	a1,a1,-1
    80001e7e:	05b2                	slli	a1,a1,0xc
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	7b0080e7          	jalr	1968(ra) # 80001632 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e8a:	4581                	li	a1,0
    80001e8c:	8526                	mv	a0,s1
    80001e8e:	00000097          	auipc	ra,0x0
    80001e92:	a64080e7          	jalr	-1436(ra) # 800018f2 <uvmfree>
    return 0;
    80001e96:	4481                	li	s1,0
    80001e98:	bf7d                	j	80001e56 <proc_pagetable+0x58>

0000000080001e9a <proc_freepagetable>:
{
    80001e9a:	1101                	addi	sp,sp,-32
    80001e9c:	ec06                	sd	ra,24(sp)
    80001e9e:	e822                	sd	s0,16(sp)
    80001ea0:	e426                	sd	s1,8(sp)
    80001ea2:	e04a                	sd	s2,0(sp)
    80001ea4:	1000                	addi	s0,sp,32
    80001ea6:	84aa                	mv	s1,a0
    80001ea8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001eaa:	4681                	li	a3,0
    80001eac:	4605                	li	a2,1
    80001eae:	040005b7          	lui	a1,0x4000
    80001eb2:	15fd                	addi	a1,a1,-1
    80001eb4:	05b2                	slli	a1,a1,0xc
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	77c080e7          	jalr	1916(ra) # 80001632 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ebe:	4681                	li	a3,0
    80001ec0:	4605                	li	a2,1
    80001ec2:	020005b7          	lui	a1,0x2000
    80001ec6:	15fd                	addi	a1,a1,-1
    80001ec8:	05b6                	slli	a1,a1,0xd
    80001eca:	8526                	mv	a0,s1
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	766080e7          	jalr	1894(ra) # 80001632 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ed4:	85ca                	mv	a1,s2
    80001ed6:	8526                	mv	a0,s1
    80001ed8:	00000097          	auipc	ra,0x0
    80001edc:	a1a080e7          	jalr	-1510(ra) # 800018f2 <uvmfree>
}
    80001ee0:	60e2                	ld	ra,24(sp)
    80001ee2:	6442                	ld	s0,16(sp)
    80001ee4:	64a2                	ld	s1,8(sp)
    80001ee6:	6902                	ld	s2,0(sp)
    80001ee8:	6105                	addi	sp,sp,32
    80001eea:	8082                	ret

0000000080001eec <freeproc>:
{
    80001eec:	1101                	addi	sp,sp,-32
    80001eee:	ec06                	sd	ra,24(sp)
    80001ef0:	e822                	sd	s0,16(sp)
    80001ef2:	e426                	sd	s1,8(sp)
    80001ef4:	1000                	addi	s0,sp,32
    80001ef6:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ef8:	7128                	ld	a0,96(a0)
    80001efa:	c509                	beqz	a0,80001f04 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	b30080e7          	jalr	-1232(ra) # 80000a2c <kfree>
  p->trapframe = 0;
    80001f04:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001f08:	6ca8                	ld	a0,88(s1)
    80001f0a:	c511                	beqz	a0,80001f16 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f0c:	68ac                	ld	a1,80(s1)
    80001f0e:	00000097          	auipc	ra,0x0
    80001f12:	f8c080e7          	jalr	-116(ra) # 80001e9a <proc_freepagetable>
  p->pagetable = 0;
    80001f16:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001f1a:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001f1e:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001f22:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001f26:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001f2a:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001f2e:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001f32:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001f36:	0204a023          	sw	zero,32(s1)
}
    80001f3a:	60e2                	ld	ra,24(sp)
    80001f3c:	6442                	ld	s0,16(sp)
    80001f3e:	64a2                	ld	s1,8(sp)
    80001f40:	6105                	addi	sp,sp,32
    80001f42:	8082                	ret

0000000080001f44 <allocproc>:
{
    80001f44:	1101                	addi	sp,sp,-32
    80001f46:	ec06                	sd	ra,24(sp)
    80001f48:	e822                	sd	s0,16(sp)
    80001f4a:	e426                	sd	s1,8(sp)
    80001f4c:	e04a                	sd	s2,0(sp)
    80001f4e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f50:	00011497          	auipc	s1,0x11
    80001f54:	85848493          	addi	s1,s1,-1960 # 800127a8 <proc>
    80001f58:	00016917          	auipc	s2,0x16
    80001f5c:	45090913          	addi	s2,s2,1104 # 800183a8 <tickslock>
    acquire(&p->lock);
    80001f60:	8526                	mv	a0,s1
    80001f62:	fffff097          	auipc	ra,0xfffff
    80001f66:	d90080e7          	jalr	-624(ra) # 80000cf2 <acquire>
    if(p->state == UNUSED) {
    80001f6a:	509c                	lw	a5,32(s1)
    80001f6c:	cf81                	beqz	a5,80001f84 <allocproc+0x40>
      release(&p->lock);
    80001f6e:	8526                	mv	a0,s1
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	e52080e7          	jalr	-430(ra) # 80000dc2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f78:	17048493          	addi	s1,s1,368
    80001f7c:	ff2492e3          	bne	s1,s2,80001f60 <allocproc+0x1c>
  return 0;
    80001f80:	4481                	li	s1,0
    80001f82:	a0b9                	j	80001fd0 <allocproc+0x8c>
  p->pid = allocpid();
    80001f84:	00000097          	auipc	ra,0x0
    80001f88:	e34080e7          	jalr	-460(ra) # 80001db8 <allocpid>
    80001f8c:	c0a8                	sw	a0,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	bec080e7          	jalr	-1044(ra) # 80000b7a <kalloc>
    80001f96:	892a                	mv	s2,a0
    80001f98:	f0a8                	sd	a0,96(s1)
    80001f9a:	c131                	beqz	a0,80001fde <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001f9c:	8526                	mv	a0,s1
    80001f9e:	00000097          	auipc	ra,0x0
    80001fa2:	e60080e7          	jalr	-416(ra) # 80001dfe <proc_pagetable>
    80001fa6:	892a                	mv	s2,a0
    80001fa8:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001faa:	c129                	beqz	a0,80001fec <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001fac:	07000613          	li	a2,112
    80001fb0:	4581                	li	a1,0
    80001fb2:	06848513          	addi	a0,s1,104
    80001fb6:	fffff097          	auipc	ra,0xfffff
    80001fba:	11c080e7          	jalr	284(ra) # 800010d2 <memset>
  p->context.ra = (uint64)forkret;
    80001fbe:	00000797          	auipc	a5,0x0
    80001fc2:	db478793          	addi	a5,a5,-588 # 80001d72 <forkret>
    80001fc6:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001fc8:	64bc                	ld	a5,72(s1)
    80001fca:	6705                	lui	a4,0x1
    80001fcc:	97ba                	add	a5,a5,a4
    80001fce:	f8bc                	sd	a5,112(s1)
}
    80001fd0:	8526                	mv	a0,s1
    80001fd2:	60e2                	ld	ra,24(sp)
    80001fd4:	6442                	ld	s0,16(sp)
    80001fd6:	64a2                	ld	s1,8(sp)
    80001fd8:	6902                	ld	s2,0(sp)
    80001fda:	6105                	addi	sp,sp,32
    80001fdc:	8082                	ret
    release(&p->lock);
    80001fde:	8526                	mv	a0,s1
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	de2080e7          	jalr	-542(ra) # 80000dc2 <release>
    return 0;
    80001fe8:	84ca                	mv	s1,s2
    80001fea:	b7dd                	j	80001fd0 <allocproc+0x8c>
    freeproc(p);
    80001fec:	8526                	mv	a0,s1
    80001fee:	00000097          	auipc	ra,0x0
    80001ff2:	efe080e7          	jalr	-258(ra) # 80001eec <freeproc>
    release(&p->lock);
    80001ff6:	8526                	mv	a0,s1
    80001ff8:	fffff097          	auipc	ra,0xfffff
    80001ffc:	dca080e7          	jalr	-566(ra) # 80000dc2 <release>
    return 0;
    80002000:	84ca                	mv	s1,s2
    80002002:	b7f9                	j	80001fd0 <allocproc+0x8c>

0000000080002004 <userinit>:
{
    80002004:	1101                	addi	sp,sp,-32
    80002006:	ec06                	sd	ra,24(sp)
    80002008:	e822                	sd	s0,16(sp)
    8000200a:	e426                	sd	s1,8(sp)
    8000200c:	1000                	addi	s0,sp,32
  p = allocproc();
    8000200e:	00000097          	auipc	ra,0x0
    80002012:	f36080e7          	jalr	-202(ra) # 80001f44 <allocproc>
    80002016:	84aa                	mv	s1,a0
  initproc = p;
    80002018:	00007797          	auipc	a5,0x7
    8000201c:	00a7b023          	sd	a0,0(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002020:	03400613          	li	a2,52
    80002024:	00007597          	auipc	a1,0x7
    80002028:	8ac58593          	addi	a1,a1,-1876 # 800088d0 <initcode>
    8000202c:	6d28                	ld	a0,88(a0)
    8000202e:	fffff097          	auipc	ra,0xfffff
    80002032:	6f6080e7          	jalr	1782(ra) # 80001724 <uvminit>
  p->sz = PGSIZE;
    80002036:	6785                	lui	a5,0x1
    80002038:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    8000203a:	70b8                	ld	a4,96(s1)
    8000203c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002040:	70b8                	ld	a4,96(s1)
    80002042:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002044:	4641                	li	a2,16
    80002046:	00006597          	auipc	a1,0x6
    8000204a:	23258593          	addi	a1,a1,562 # 80008278 <digits+0x238>
    8000204e:	16048513          	addi	a0,s1,352
    80002052:	fffff097          	auipc	ra,0xfffff
    80002056:	1d6080e7          	jalr	470(ra) # 80001228 <safestrcpy>
  p->cwd = namei("/");
    8000205a:	00006517          	auipc	a0,0x6
    8000205e:	22e50513          	addi	a0,a0,558 # 80008288 <digits+0x248>
    80002062:	00002097          	auipc	ra,0x2
    80002066:	30c080e7          	jalr	780(ra) # 8000436e <namei>
    8000206a:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    8000206e:	4789                	li	a5,2
    80002070:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    80002072:	8526                	mv	a0,s1
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	d4e080e7          	jalr	-690(ra) # 80000dc2 <release>
}
    8000207c:	60e2                	ld	ra,24(sp)
    8000207e:	6442                	ld	s0,16(sp)
    80002080:	64a2                	ld	s1,8(sp)
    80002082:	6105                	addi	sp,sp,32
    80002084:	8082                	ret

0000000080002086 <growproc>:
{
    80002086:	1101                	addi	sp,sp,-32
    80002088:	ec06                	sd	ra,24(sp)
    8000208a:	e822                	sd	s0,16(sp)
    8000208c:	e426                	sd	s1,8(sp)
    8000208e:	e04a                	sd	s2,0(sp)
    80002090:	1000                	addi	s0,sp,32
    80002092:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002094:	00000097          	auipc	ra,0x0
    80002098:	ca6080e7          	jalr	-858(ra) # 80001d3a <myproc>
    8000209c:	892a                	mv	s2,a0
  sz = p->sz;
    8000209e:	692c                	ld	a1,80(a0)
    800020a0:	0005861b          	sext.w	a2,a1
  if(n > 0){
    800020a4:	00904f63          	bgtz	s1,800020c2 <growproc+0x3c>
  } else if(n < 0){
    800020a8:	0204cc63          	bltz	s1,800020e0 <growproc+0x5a>
  p->sz = sz;
    800020ac:	1602                	slli	a2,a2,0x20
    800020ae:	9201                	srli	a2,a2,0x20
    800020b0:	04c93823          	sd	a2,80(s2)
  return 0;
    800020b4:	4501                	li	a0,0
}
    800020b6:	60e2                	ld	ra,24(sp)
    800020b8:	6442                	ld	s0,16(sp)
    800020ba:	64a2                	ld	s1,8(sp)
    800020bc:	6902                	ld	s2,0(sp)
    800020be:	6105                	addi	sp,sp,32
    800020c0:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800020c2:	9e25                	addw	a2,a2,s1
    800020c4:	1602                	slli	a2,a2,0x20
    800020c6:	9201                	srli	a2,a2,0x20
    800020c8:	1582                	slli	a1,a1,0x20
    800020ca:	9181                	srli	a1,a1,0x20
    800020cc:	6d28                	ld	a0,88(a0)
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	710080e7          	jalr	1808(ra) # 800017de <uvmalloc>
    800020d6:	0005061b          	sext.w	a2,a0
    800020da:	fa69                	bnez	a2,800020ac <growproc+0x26>
      return -1;
    800020dc:	557d                	li	a0,-1
    800020de:	bfe1                	j	800020b6 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020e0:	9e25                	addw	a2,a2,s1
    800020e2:	1602                	slli	a2,a2,0x20
    800020e4:	9201                	srli	a2,a2,0x20
    800020e6:	1582                	slli	a1,a1,0x20
    800020e8:	9181                	srli	a1,a1,0x20
    800020ea:	6d28                	ld	a0,88(a0)
    800020ec:	fffff097          	auipc	ra,0xfffff
    800020f0:	6aa080e7          	jalr	1706(ra) # 80001796 <uvmdealloc>
    800020f4:	0005061b          	sext.w	a2,a0
    800020f8:	bf55                	j	800020ac <growproc+0x26>

00000000800020fa <fork>:
{
    800020fa:	7179                	addi	sp,sp,-48
    800020fc:	f406                	sd	ra,40(sp)
    800020fe:	f022                	sd	s0,32(sp)
    80002100:	ec26                	sd	s1,24(sp)
    80002102:	e84a                	sd	s2,16(sp)
    80002104:	e44e                	sd	s3,8(sp)
    80002106:	e052                	sd	s4,0(sp)
    80002108:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000210a:	00000097          	auipc	ra,0x0
    8000210e:	c30080e7          	jalr	-976(ra) # 80001d3a <myproc>
    80002112:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002114:	00000097          	auipc	ra,0x0
    80002118:	e30080e7          	jalr	-464(ra) # 80001f44 <allocproc>
    8000211c:	c175                	beqz	a0,80002200 <fork+0x106>
    8000211e:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002120:	05093603          	ld	a2,80(s2)
    80002124:	6d2c                	ld	a1,88(a0)
    80002126:	05893503          	ld	a0,88(s2)
    8000212a:	00000097          	auipc	ra,0x0
    8000212e:	800080e7          	jalr	-2048(ra) # 8000192a <uvmcopy>
    80002132:	04054863          	bltz	a0,80002182 <fork+0x88>
  np->sz = p->sz;
    80002136:	05093783          	ld	a5,80(s2)
    8000213a:	04f9b823          	sd	a5,80(s3) # 4000050 <_entry-0x7bffffb0>
  np->parent = p;
    8000213e:	0329b423          	sd	s2,40(s3)
  *(np->trapframe) = *(p->trapframe);
    80002142:	06093683          	ld	a3,96(s2)
    80002146:	87b6                	mv	a5,a3
    80002148:	0609b703          	ld	a4,96(s3)
    8000214c:	12068693          	addi	a3,a3,288
    80002150:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002154:	6788                	ld	a0,8(a5)
    80002156:	6b8c                	ld	a1,16(a5)
    80002158:	6f90                	ld	a2,24(a5)
    8000215a:	01073023          	sd	a6,0(a4)
    8000215e:	e708                	sd	a0,8(a4)
    80002160:	eb0c                	sd	a1,16(a4)
    80002162:	ef10                	sd	a2,24(a4)
    80002164:	02078793          	addi	a5,a5,32
    80002168:	02070713          	addi	a4,a4,32
    8000216c:	fed792e3          	bne	a5,a3,80002150 <fork+0x56>
  np->trapframe->a0 = 0;
    80002170:	0609b783          	ld	a5,96(s3)
    80002174:	0607b823          	sd	zero,112(a5)
    80002178:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    8000217c:	15800a13          	li	s4,344
    80002180:	a03d                	j	800021ae <fork+0xb4>
    freeproc(np);
    80002182:	854e                	mv	a0,s3
    80002184:	00000097          	auipc	ra,0x0
    80002188:	d68080e7          	jalr	-664(ra) # 80001eec <freeproc>
    release(&np->lock);
    8000218c:	854e                	mv	a0,s3
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	c34080e7          	jalr	-972(ra) # 80000dc2 <release>
    return -1;
    80002196:	54fd                	li	s1,-1
    80002198:	a899                	j	800021ee <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    8000219a:	00003097          	auipc	ra,0x3
    8000219e:	872080e7          	jalr	-1934(ra) # 80004a0c <filedup>
    800021a2:	009987b3          	add	a5,s3,s1
    800021a6:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800021a8:	04a1                	addi	s1,s1,8
    800021aa:	01448763          	beq	s1,s4,800021b8 <fork+0xbe>
    if(p->ofile[i])
    800021ae:	009907b3          	add	a5,s2,s1
    800021b2:	6388                	ld	a0,0(a5)
    800021b4:	f17d                	bnez	a0,8000219a <fork+0xa0>
    800021b6:	bfcd                	j	800021a8 <fork+0xae>
  np->cwd = idup(p->cwd);
    800021b8:	15893503          	ld	a0,344(s2)
    800021bc:	00002097          	auipc	ra,0x2
    800021c0:	9c0080e7          	jalr	-1600(ra) # 80003b7c <idup>
    800021c4:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021c8:	4641                	li	a2,16
    800021ca:	16090593          	addi	a1,s2,352
    800021ce:	16098513          	addi	a0,s3,352
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	056080e7          	jalr	86(ra) # 80001228 <safestrcpy>
  pid = np->pid;
    800021da:	0409a483          	lw	s1,64(s3)
  np->state = RUNNABLE;
    800021de:	4789                	li	a5,2
    800021e0:	02f9a023          	sw	a5,32(s3)
  release(&np->lock);
    800021e4:	854e                	mv	a0,s3
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	bdc080e7          	jalr	-1060(ra) # 80000dc2 <release>
}
    800021ee:	8526                	mv	a0,s1
    800021f0:	70a2                	ld	ra,40(sp)
    800021f2:	7402                	ld	s0,32(sp)
    800021f4:	64e2                	ld	s1,24(sp)
    800021f6:	6942                	ld	s2,16(sp)
    800021f8:	69a2                	ld	s3,8(sp)
    800021fa:	6a02                	ld	s4,0(sp)
    800021fc:	6145                	addi	sp,sp,48
    800021fe:	8082                	ret
    return -1;
    80002200:	54fd                	li	s1,-1
    80002202:	b7f5                	j	800021ee <fork+0xf4>

0000000080002204 <reparent>:
{
    80002204:	7179                	addi	sp,sp,-48
    80002206:	f406                	sd	ra,40(sp)
    80002208:	f022                	sd	s0,32(sp)
    8000220a:	ec26                	sd	s1,24(sp)
    8000220c:	e84a                	sd	s2,16(sp)
    8000220e:	e44e                	sd	s3,8(sp)
    80002210:	e052                	sd	s4,0(sp)
    80002212:	1800                	addi	s0,sp,48
    80002214:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002216:	00010497          	auipc	s1,0x10
    8000221a:	59248493          	addi	s1,s1,1426 # 800127a8 <proc>
      pp->parent = initproc;
    8000221e:	00007a17          	auipc	s4,0x7
    80002222:	dfaa0a13          	addi	s4,s4,-518 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002226:	00016997          	auipc	s3,0x16
    8000222a:	18298993          	addi	s3,s3,386 # 800183a8 <tickslock>
    8000222e:	a029                	j	80002238 <reparent+0x34>
    80002230:	17048493          	addi	s1,s1,368
    80002234:	03348363          	beq	s1,s3,8000225a <reparent+0x56>
    if(pp->parent == p){
    80002238:	749c                	ld	a5,40(s1)
    8000223a:	ff279be3          	bne	a5,s2,80002230 <reparent+0x2c>
      acquire(&pp->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	ab2080e7          	jalr	-1358(ra) # 80000cf2 <acquire>
      pp->parent = initproc;
    80002248:	000a3783          	ld	a5,0(s4)
    8000224c:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	b72080e7          	jalr	-1166(ra) # 80000dc2 <release>
    80002258:	bfe1                	j	80002230 <reparent+0x2c>
}
    8000225a:	70a2                	ld	ra,40(sp)
    8000225c:	7402                	ld	s0,32(sp)
    8000225e:	64e2                	ld	s1,24(sp)
    80002260:	6942                	ld	s2,16(sp)
    80002262:	69a2                	ld	s3,8(sp)
    80002264:	6a02                	ld	s4,0(sp)
    80002266:	6145                	addi	sp,sp,48
    80002268:	8082                	ret

000000008000226a <scheduler>:
{
    8000226a:	711d                	addi	sp,sp,-96
    8000226c:	ec86                	sd	ra,88(sp)
    8000226e:	e8a2                	sd	s0,80(sp)
    80002270:	e4a6                	sd	s1,72(sp)
    80002272:	e0ca                	sd	s2,64(sp)
    80002274:	fc4e                	sd	s3,56(sp)
    80002276:	f852                	sd	s4,48(sp)
    80002278:	f456                	sd	s5,40(sp)
    8000227a:	f05a                	sd	s6,32(sp)
    8000227c:	ec5e                	sd	s7,24(sp)
    8000227e:	e862                	sd	s8,16(sp)
    80002280:	e466                	sd	s9,8(sp)
    80002282:	1080                	addi	s0,sp,96
    80002284:	8792                	mv	a5,tp
  int id = r_tp();
    80002286:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002288:	00779c13          	slli	s8,a5,0x7
    8000228c:	00010717          	auipc	a4,0x10
    80002290:	0fc70713          	addi	a4,a4,252 # 80012388 <pid_lock>
    80002294:	9762                	add	a4,a4,s8
    80002296:	02073023          	sd	zero,32(a4)
        swtch(&c->context, &p->context);
    8000229a:	00010717          	auipc	a4,0x10
    8000229e:	11670713          	addi	a4,a4,278 # 800123b0 <cpus+0x8>
    800022a2:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    800022a4:	4a89                	li	s5,2
        c->proc = p;
    800022a6:	079e                	slli	a5,a5,0x7
    800022a8:	00010b17          	auipc	s6,0x10
    800022ac:	0e0b0b13          	addi	s6,s6,224 # 80012388 <pid_lock>
    800022b0:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800022b2:	00016a17          	auipc	s4,0x16
    800022b6:	0f6a0a13          	addi	s4,s4,246 # 800183a8 <tickslock>
    int nproc = 0;
    800022ba:	4c81                	li	s9,0
    800022bc:	a8a1                	j	80002314 <scheduler+0xaa>
        p->state = RUNNING;
    800022be:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    800022c2:	029b3023          	sd	s1,32(s6)
        swtch(&c->context, &p->context);
    800022c6:	06848593          	addi	a1,s1,104
    800022ca:	8562                	mv	a0,s8
    800022cc:	00000097          	auipc	ra,0x0
    800022d0:	63a080e7          	jalr	1594(ra) # 80002906 <swtch>
        c->proc = 0;
    800022d4:	020b3023          	sd	zero,32(s6)
      release(&p->lock);
    800022d8:	8526                	mv	a0,s1
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	ae8080e7          	jalr	-1304(ra) # 80000dc2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022e2:	17048493          	addi	s1,s1,368
    800022e6:	01448d63          	beq	s1,s4,80002300 <scheduler+0x96>
      acquire(&p->lock);
    800022ea:	8526                	mv	a0,s1
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	a06080e7          	jalr	-1530(ra) # 80000cf2 <acquire>
      if(p->state != UNUSED) {
    800022f4:	509c                	lw	a5,32(s1)
    800022f6:	d3ed                	beqz	a5,800022d8 <scheduler+0x6e>
        nproc++;
    800022f8:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    800022fa:	fd579fe3          	bne	a5,s5,800022d8 <scheduler+0x6e>
    800022fe:	b7c1                	j	800022be <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002300:	013aca63          	blt	s5,s3,80002314 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002304:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002308:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000230c:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002310:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002314:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002318:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000231c:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002320:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002322:	00010497          	auipc	s1,0x10
    80002326:	48648493          	addi	s1,s1,1158 # 800127a8 <proc>
        p->state = RUNNING;
    8000232a:	4b8d                	li	s7,3
    8000232c:	bf7d                	j	800022ea <scheduler+0x80>

000000008000232e <sched>:
{
    8000232e:	7179                	addi	sp,sp,-48
    80002330:	f406                	sd	ra,40(sp)
    80002332:	f022                	sd	s0,32(sp)
    80002334:	ec26                	sd	s1,24(sp)
    80002336:	e84a                	sd	s2,16(sp)
    80002338:	e44e                	sd	s3,8(sp)
    8000233a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000233c:	00000097          	auipc	ra,0x0
    80002340:	9fe080e7          	jalr	-1538(ra) # 80001d3a <myproc>
    80002344:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	932080e7          	jalr	-1742(ra) # 80000c78 <holding>
    8000234e:	c93d                	beqz	a0,800023c4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002350:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002352:	2781                	sext.w	a5,a5
    80002354:	079e                	slli	a5,a5,0x7
    80002356:	00010717          	auipc	a4,0x10
    8000235a:	03270713          	addi	a4,a4,50 # 80012388 <pid_lock>
    8000235e:	97ba                	add	a5,a5,a4
    80002360:	0987a703          	lw	a4,152(a5)
    80002364:	4785                	li	a5,1
    80002366:	06f71763          	bne	a4,a5,800023d4 <sched+0xa6>
  if(p->state == RUNNING)
    8000236a:	5098                	lw	a4,32(s1)
    8000236c:	478d                	li	a5,3
    8000236e:	06f70b63          	beq	a4,a5,800023e4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002372:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002376:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002378:	efb5                	bnez	a5,800023f4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000237a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000237c:	00010917          	auipc	s2,0x10
    80002380:	00c90913          	addi	s2,s2,12 # 80012388 <pid_lock>
    80002384:	2781                	sext.w	a5,a5
    80002386:	079e                	slli	a5,a5,0x7
    80002388:	97ca                	add	a5,a5,s2
    8000238a:	09c7a983          	lw	s3,156(a5)
    8000238e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002390:	2781                	sext.w	a5,a5
    80002392:	079e                	slli	a5,a5,0x7
    80002394:	00010597          	auipc	a1,0x10
    80002398:	01c58593          	addi	a1,a1,28 # 800123b0 <cpus+0x8>
    8000239c:	95be                	add	a1,a1,a5
    8000239e:	06848513          	addi	a0,s1,104
    800023a2:	00000097          	auipc	ra,0x0
    800023a6:	564080e7          	jalr	1380(ra) # 80002906 <swtch>
    800023aa:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023ac:	2781                	sext.w	a5,a5
    800023ae:	079e                	slli	a5,a5,0x7
    800023b0:	97ca                	add	a5,a5,s2
    800023b2:	0937ae23          	sw	s3,156(a5)
}
    800023b6:	70a2                	ld	ra,40(sp)
    800023b8:	7402                	ld	s0,32(sp)
    800023ba:	64e2                	ld	s1,24(sp)
    800023bc:	6942                	ld	s2,16(sp)
    800023be:	69a2                	ld	s3,8(sp)
    800023c0:	6145                	addi	sp,sp,48
    800023c2:	8082                	ret
    panic("sched p->lock");
    800023c4:	00006517          	auipc	a0,0x6
    800023c8:	ecc50513          	addi	a0,a0,-308 # 80008290 <digits+0x250>
    800023cc:	ffffe097          	auipc	ra,0xffffe
    800023d0:	184080e7          	jalr	388(ra) # 80000550 <panic>
    panic("sched locks");
    800023d4:	00006517          	auipc	a0,0x6
    800023d8:	ecc50513          	addi	a0,a0,-308 # 800082a0 <digits+0x260>
    800023dc:	ffffe097          	auipc	ra,0xffffe
    800023e0:	174080e7          	jalr	372(ra) # 80000550 <panic>
    panic("sched running");
    800023e4:	00006517          	auipc	a0,0x6
    800023e8:	ecc50513          	addi	a0,a0,-308 # 800082b0 <digits+0x270>
    800023ec:	ffffe097          	auipc	ra,0xffffe
    800023f0:	164080e7          	jalr	356(ra) # 80000550 <panic>
    panic("sched interruptible");
    800023f4:	00006517          	auipc	a0,0x6
    800023f8:	ecc50513          	addi	a0,a0,-308 # 800082c0 <digits+0x280>
    800023fc:	ffffe097          	auipc	ra,0xffffe
    80002400:	154080e7          	jalr	340(ra) # 80000550 <panic>

0000000080002404 <exit>:
{
    80002404:	7179                	addi	sp,sp,-48
    80002406:	f406                	sd	ra,40(sp)
    80002408:	f022                	sd	s0,32(sp)
    8000240a:	ec26                	sd	s1,24(sp)
    8000240c:	e84a                	sd	s2,16(sp)
    8000240e:	e44e                	sd	s3,8(sp)
    80002410:	e052                	sd	s4,0(sp)
    80002412:	1800                	addi	s0,sp,48
    80002414:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002416:	00000097          	auipc	ra,0x0
    8000241a:	924080e7          	jalr	-1756(ra) # 80001d3a <myproc>
    8000241e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002420:	00007797          	auipc	a5,0x7
    80002424:	bf87b783          	ld	a5,-1032(a5) # 80009018 <initproc>
    80002428:	0d850493          	addi	s1,a0,216
    8000242c:	15850913          	addi	s2,a0,344
    80002430:	02a79363          	bne	a5,a0,80002456 <exit+0x52>
    panic("init exiting");
    80002434:	00006517          	auipc	a0,0x6
    80002438:	ea450513          	addi	a0,a0,-348 # 800082d8 <digits+0x298>
    8000243c:	ffffe097          	auipc	ra,0xffffe
    80002440:	114080e7          	jalr	276(ra) # 80000550 <panic>
      fileclose(f);
    80002444:	00002097          	auipc	ra,0x2
    80002448:	61a080e7          	jalr	1562(ra) # 80004a5e <fileclose>
      p->ofile[fd] = 0;
    8000244c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002450:	04a1                	addi	s1,s1,8
    80002452:	01248563          	beq	s1,s2,8000245c <exit+0x58>
    if(p->ofile[fd]){
    80002456:	6088                	ld	a0,0(s1)
    80002458:	f575                	bnez	a0,80002444 <exit+0x40>
    8000245a:	bfdd                	j	80002450 <exit+0x4c>
  begin_op();
    8000245c:	00002097          	auipc	ra,0x2
    80002460:	12e080e7          	jalr	302(ra) # 8000458a <begin_op>
  iput(p->cwd);
    80002464:	1589b503          	ld	a0,344(s3)
    80002468:	00002097          	auipc	ra,0x2
    8000246c:	90c080e7          	jalr	-1780(ra) # 80003d74 <iput>
  end_op();
    80002470:	00002097          	auipc	ra,0x2
    80002474:	19a080e7          	jalr	410(ra) # 8000460a <end_op>
  p->cwd = 0;
    80002478:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    8000247c:	00007497          	auipc	s1,0x7
    80002480:	b9c48493          	addi	s1,s1,-1124 # 80009018 <initproc>
    80002484:	6088                	ld	a0,0(s1)
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	86c080e7          	jalr	-1940(ra) # 80000cf2 <acquire>
  wakeup1(initproc);
    8000248e:	6088                	ld	a0,0(s1)
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	76a080e7          	jalr	1898(ra) # 80001bfa <wakeup1>
  release(&initproc->lock);
    80002498:	6088                	ld	a0,0(s1)
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	928080e7          	jalr	-1752(ra) # 80000dc2 <release>
  acquire(&p->lock);
    800024a2:	854e                	mv	a0,s3
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	84e080e7          	jalr	-1970(ra) # 80000cf2 <acquire>
  struct proc *original_parent = p->parent;
    800024ac:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    800024b0:	854e                	mv	a0,s3
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	910080e7          	jalr	-1776(ra) # 80000dc2 <release>
  acquire(&original_parent->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	836080e7          	jalr	-1994(ra) # 80000cf2 <acquire>
  acquire(&p->lock);
    800024c4:	854e                	mv	a0,s3
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	82c080e7          	jalr	-2004(ra) # 80000cf2 <acquire>
  reparent(p);
    800024ce:	854e                	mv	a0,s3
    800024d0:	00000097          	auipc	ra,0x0
    800024d4:	d34080e7          	jalr	-716(ra) # 80002204 <reparent>
  wakeup1(original_parent);
    800024d8:	8526                	mv	a0,s1
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	720080e7          	jalr	1824(ra) # 80001bfa <wakeup1>
  p->xstate = status;
    800024e2:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    800024e6:	4791                	li	a5,4
    800024e8:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    800024ec:	8526                	mv	a0,s1
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	8d4080e7          	jalr	-1836(ra) # 80000dc2 <release>
  sched();
    800024f6:	00000097          	auipc	ra,0x0
    800024fa:	e38080e7          	jalr	-456(ra) # 8000232e <sched>
  panic("zombie exit");
    800024fe:	00006517          	auipc	a0,0x6
    80002502:	dea50513          	addi	a0,a0,-534 # 800082e8 <digits+0x2a8>
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	04a080e7          	jalr	74(ra) # 80000550 <panic>

000000008000250e <yield>:
{
    8000250e:	1101                	addi	sp,sp,-32
    80002510:	ec06                	sd	ra,24(sp)
    80002512:	e822                	sd	s0,16(sp)
    80002514:	e426                	sd	s1,8(sp)
    80002516:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002518:	00000097          	auipc	ra,0x0
    8000251c:	822080e7          	jalr	-2014(ra) # 80001d3a <myproc>
    80002520:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	7d0080e7          	jalr	2000(ra) # 80000cf2 <acquire>
  p->state = RUNNABLE;
    8000252a:	4789                	li	a5,2
    8000252c:	d09c                	sw	a5,32(s1)
  sched();
    8000252e:	00000097          	auipc	ra,0x0
    80002532:	e00080e7          	jalr	-512(ra) # 8000232e <sched>
  release(&p->lock);
    80002536:	8526                	mv	a0,s1
    80002538:	fffff097          	auipc	ra,0xfffff
    8000253c:	88a080e7          	jalr	-1910(ra) # 80000dc2 <release>
}
    80002540:	60e2                	ld	ra,24(sp)
    80002542:	6442                	ld	s0,16(sp)
    80002544:	64a2                	ld	s1,8(sp)
    80002546:	6105                	addi	sp,sp,32
    80002548:	8082                	ret

000000008000254a <sleep>:
{
    8000254a:	7179                	addi	sp,sp,-48
    8000254c:	f406                	sd	ra,40(sp)
    8000254e:	f022                	sd	s0,32(sp)
    80002550:	ec26                	sd	s1,24(sp)
    80002552:	e84a                	sd	s2,16(sp)
    80002554:	e44e                	sd	s3,8(sp)
    80002556:	1800                	addi	s0,sp,48
    80002558:	89aa                	mv	s3,a0
    8000255a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000255c:	fffff097          	auipc	ra,0xfffff
    80002560:	7de080e7          	jalr	2014(ra) # 80001d3a <myproc>
    80002564:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002566:	05250663          	beq	a0,s2,800025b2 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	788080e7          	jalr	1928(ra) # 80000cf2 <acquire>
    release(lk);
    80002572:	854a                	mv	a0,s2
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	84e080e7          	jalr	-1970(ra) # 80000dc2 <release>
  p->chan = chan;
    8000257c:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    80002580:	4785                	li	a5,1
    80002582:	d09c                	sw	a5,32(s1)
  sched();
    80002584:	00000097          	auipc	ra,0x0
    80002588:	daa080e7          	jalr	-598(ra) # 8000232e <sched>
  p->chan = 0;
    8000258c:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    80002590:	8526                	mv	a0,s1
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	830080e7          	jalr	-2000(ra) # 80000dc2 <release>
    acquire(lk);
    8000259a:	854a                	mv	a0,s2
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	756080e7          	jalr	1878(ra) # 80000cf2 <acquire>
}
    800025a4:	70a2                	ld	ra,40(sp)
    800025a6:	7402                	ld	s0,32(sp)
    800025a8:	64e2                	ld	s1,24(sp)
    800025aa:	6942                	ld	s2,16(sp)
    800025ac:	69a2                	ld	s3,8(sp)
    800025ae:	6145                	addi	sp,sp,48
    800025b0:	8082                	ret
  p->chan = chan;
    800025b2:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    800025b6:	4785                	li	a5,1
    800025b8:	d11c                	sw	a5,32(a0)
  sched();
    800025ba:	00000097          	auipc	ra,0x0
    800025be:	d74080e7          	jalr	-652(ra) # 8000232e <sched>
  p->chan = 0;
    800025c2:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    800025c6:	bff9                	j	800025a4 <sleep+0x5a>

00000000800025c8 <wait>:
{
    800025c8:	715d                	addi	sp,sp,-80
    800025ca:	e486                	sd	ra,72(sp)
    800025cc:	e0a2                	sd	s0,64(sp)
    800025ce:	fc26                	sd	s1,56(sp)
    800025d0:	f84a                	sd	s2,48(sp)
    800025d2:	f44e                	sd	s3,40(sp)
    800025d4:	f052                	sd	s4,32(sp)
    800025d6:	ec56                	sd	s5,24(sp)
    800025d8:	e85a                	sd	s6,16(sp)
    800025da:	e45e                	sd	s7,8(sp)
    800025dc:	e062                	sd	s8,0(sp)
    800025de:	0880                	addi	s0,sp,80
    800025e0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025e2:	fffff097          	auipc	ra,0xfffff
    800025e6:	758080e7          	jalr	1880(ra) # 80001d3a <myproc>
    800025ea:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025ec:	8c2a                	mv	s8,a0
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	704080e7          	jalr	1796(ra) # 80000cf2 <acquire>
    havekids = 0;
    800025f6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025f8:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800025fa:	00016997          	auipc	s3,0x16
    800025fe:	dae98993          	addi	s3,s3,-594 # 800183a8 <tickslock>
        havekids = 1;
    80002602:	4a85                	li	s5,1
    havekids = 0;
    80002604:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002606:	00010497          	auipc	s1,0x10
    8000260a:	1a248493          	addi	s1,s1,418 # 800127a8 <proc>
    8000260e:	a08d                	j	80002670 <wait+0xa8>
          pid = np->pid;
    80002610:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002614:	000b0e63          	beqz	s6,80002630 <wait+0x68>
    80002618:	4691                	li	a3,4
    8000261a:	03c48613          	addi	a2,s1,60
    8000261e:	85da                	mv	a1,s6
    80002620:	05893503          	ld	a0,88(s2)
    80002624:	fffff097          	auipc	ra,0xfffff
    80002628:	40a080e7          	jalr	1034(ra) # 80001a2e <copyout>
    8000262c:	02054263          	bltz	a0,80002650 <wait+0x88>
          freeproc(np);
    80002630:	8526                	mv	a0,s1
    80002632:	00000097          	auipc	ra,0x0
    80002636:	8ba080e7          	jalr	-1862(ra) # 80001eec <freeproc>
          release(&np->lock);
    8000263a:	8526                	mv	a0,s1
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	786080e7          	jalr	1926(ra) # 80000dc2 <release>
          release(&p->lock);
    80002644:	854a                	mv	a0,s2
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	77c080e7          	jalr	1916(ra) # 80000dc2 <release>
          return pid;
    8000264e:	a8a9                	j	800026a8 <wait+0xe0>
            release(&np->lock);
    80002650:	8526                	mv	a0,s1
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	770080e7          	jalr	1904(ra) # 80000dc2 <release>
            release(&p->lock);
    8000265a:	854a                	mv	a0,s2
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	766080e7          	jalr	1894(ra) # 80000dc2 <release>
            return -1;
    80002664:	59fd                	li	s3,-1
    80002666:	a089                	j	800026a8 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002668:	17048493          	addi	s1,s1,368
    8000266c:	03348463          	beq	s1,s3,80002694 <wait+0xcc>
      if(np->parent == p){
    80002670:	749c                	ld	a5,40(s1)
    80002672:	ff279be3          	bne	a5,s2,80002668 <wait+0xa0>
        acquire(&np->lock);
    80002676:	8526                	mv	a0,s1
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	67a080e7          	jalr	1658(ra) # 80000cf2 <acquire>
        if(np->state == ZOMBIE){
    80002680:	509c                	lw	a5,32(s1)
    80002682:	f94787e3          	beq	a5,s4,80002610 <wait+0x48>
        release(&np->lock);
    80002686:	8526                	mv	a0,s1
    80002688:	ffffe097          	auipc	ra,0xffffe
    8000268c:	73a080e7          	jalr	1850(ra) # 80000dc2 <release>
        havekids = 1;
    80002690:	8756                	mv	a4,s5
    80002692:	bfd9                	j	80002668 <wait+0xa0>
    if(!havekids || p->killed){
    80002694:	c701                	beqz	a4,8000269c <wait+0xd4>
    80002696:	03892783          	lw	a5,56(s2)
    8000269a:	c785                	beqz	a5,800026c2 <wait+0xfa>
      release(&p->lock);
    8000269c:	854a                	mv	a0,s2
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	724080e7          	jalr	1828(ra) # 80000dc2 <release>
      return -1;
    800026a6:	59fd                	li	s3,-1
}
    800026a8:	854e                	mv	a0,s3
    800026aa:	60a6                	ld	ra,72(sp)
    800026ac:	6406                	ld	s0,64(sp)
    800026ae:	74e2                	ld	s1,56(sp)
    800026b0:	7942                	ld	s2,48(sp)
    800026b2:	79a2                	ld	s3,40(sp)
    800026b4:	7a02                	ld	s4,32(sp)
    800026b6:	6ae2                	ld	s5,24(sp)
    800026b8:	6b42                	ld	s6,16(sp)
    800026ba:	6ba2                	ld	s7,8(sp)
    800026bc:	6c02                	ld	s8,0(sp)
    800026be:	6161                	addi	sp,sp,80
    800026c0:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800026c2:	85e2                	mv	a1,s8
    800026c4:	854a                	mv	a0,s2
    800026c6:	00000097          	auipc	ra,0x0
    800026ca:	e84080e7          	jalr	-380(ra) # 8000254a <sleep>
    havekids = 0;
    800026ce:	bf1d                	j	80002604 <wait+0x3c>

00000000800026d0 <wakeup>:
{
    800026d0:	7139                	addi	sp,sp,-64
    800026d2:	fc06                	sd	ra,56(sp)
    800026d4:	f822                	sd	s0,48(sp)
    800026d6:	f426                	sd	s1,40(sp)
    800026d8:	f04a                	sd	s2,32(sp)
    800026da:	ec4e                	sd	s3,24(sp)
    800026dc:	e852                	sd	s4,16(sp)
    800026de:	e456                	sd	s5,8(sp)
    800026e0:	0080                	addi	s0,sp,64
    800026e2:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800026e4:	00010497          	auipc	s1,0x10
    800026e8:	0c448493          	addi	s1,s1,196 # 800127a8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800026ec:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026ee:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800026f0:	00016917          	auipc	s2,0x16
    800026f4:	cb890913          	addi	s2,s2,-840 # 800183a8 <tickslock>
    800026f8:	a821                	j	80002710 <wakeup+0x40>
      p->state = RUNNABLE;
    800026fa:	0354a023          	sw	s5,32(s1)
    release(&p->lock);
    800026fe:	8526                	mv	a0,s1
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	6c2080e7          	jalr	1730(ra) # 80000dc2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002708:	17048493          	addi	s1,s1,368
    8000270c:	01248e63          	beq	s1,s2,80002728 <wakeup+0x58>
    acquire(&p->lock);
    80002710:	8526                	mv	a0,s1
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	5e0080e7          	jalr	1504(ra) # 80000cf2 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000271a:	509c                	lw	a5,32(s1)
    8000271c:	ff3791e3          	bne	a5,s3,800026fe <wakeup+0x2e>
    80002720:	789c                	ld	a5,48(s1)
    80002722:	fd479ee3          	bne	a5,s4,800026fe <wakeup+0x2e>
    80002726:	bfd1                	j	800026fa <wakeup+0x2a>
}
    80002728:	70e2                	ld	ra,56(sp)
    8000272a:	7442                	ld	s0,48(sp)
    8000272c:	74a2                	ld	s1,40(sp)
    8000272e:	7902                	ld	s2,32(sp)
    80002730:	69e2                	ld	s3,24(sp)
    80002732:	6a42                	ld	s4,16(sp)
    80002734:	6aa2                	ld	s5,8(sp)
    80002736:	6121                	addi	sp,sp,64
    80002738:	8082                	ret

000000008000273a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000273a:	7179                	addi	sp,sp,-48
    8000273c:	f406                	sd	ra,40(sp)
    8000273e:	f022                	sd	s0,32(sp)
    80002740:	ec26                	sd	s1,24(sp)
    80002742:	e84a                	sd	s2,16(sp)
    80002744:	e44e                	sd	s3,8(sp)
    80002746:	1800                	addi	s0,sp,48
    80002748:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000274a:	00010497          	auipc	s1,0x10
    8000274e:	05e48493          	addi	s1,s1,94 # 800127a8 <proc>
    80002752:	00016997          	auipc	s3,0x16
    80002756:	c5698993          	addi	s3,s3,-938 # 800183a8 <tickslock>
    acquire(&p->lock);
    8000275a:	8526                	mv	a0,s1
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	596080e7          	jalr	1430(ra) # 80000cf2 <acquire>
    if(p->pid == pid){
    80002764:	40bc                	lw	a5,64(s1)
    80002766:	01278d63          	beq	a5,s2,80002780 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000276a:	8526                	mv	a0,s1
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	656080e7          	jalr	1622(ra) # 80000dc2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002774:	17048493          	addi	s1,s1,368
    80002778:	ff3491e3          	bne	s1,s3,8000275a <kill+0x20>
  }
  return -1;
    8000277c:	557d                	li	a0,-1
    8000277e:	a829                	j	80002798 <kill+0x5e>
      p->killed = 1;
    80002780:	4785                	li	a5,1
    80002782:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    80002784:	5098                	lw	a4,32(s1)
    80002786:	4785                	li	a5,1
    80002788:	00f70f63          	beq	a4,a5,800027a6 <kill+0x6c>
      release(&p->lock);
    8000278c:	8526                	mv	a0,s1
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	634080e7          	jalr	1588(ra) # 80000dc2 <release>
      return 0;
    80002796:	4501                	li	a0,0
}
    80002798:	70a2                	ld	ra,40(sp)
    8000279a:	7402                	ld	s0,32(sp)
    8000279c:	64e2                	ld	s1,24(sp)
    8000279e:	6942                	ld	s2,16(sp)
    800027a0:	69a2                	ld	s3,8(sp)
    800027a2:	6145                	addi	sp,sp,48
    800027a4:	8082                	ret
        p->state = RUNNABLE;
    800027a6:	4789                	li	a5,2
    800027a8:	d09c                	sw	a5,32(s1)
    800027aa:	b7cd                	j	8000278c <kill+0x52>

00000000800027ac <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027ac:	7179                	addi	sp,sp,-48
    800027ae:	f406                	sd	ra,40(sp)
    800027b0:	f022                	sd	s0,32(sp)
    800027b2:	ec26                	sd	s1,24(sp)
    800027b4:	e84a                	sd	s2,16(sp)
    800027b6:	e44e                	sd	s3,8(sp)
    800027b8:	e052                	sd	s4,0(sp)
    800027ba:	1800                	addi	s0,sp,48
    800027bc:	84aa                	mv	s1,a0
    800027be:	892e                	mv	s2,a1
    800027c0:	89b2                	mv	s3,a2
    800027c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027c4:	fffff097          	auipc	ra,0xfffff
    800027c8:	576080e7          	jalr	1398(ra) # 80001d3a <myproc>
  if(user_dst){
    800027cc:	c08d                	beqz	s1,800027ee <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027ce:	86d2                	mv	a3,s4
    800027d0:	864e                	mv	a2,s3
    800027d2:	85ca                	mv	a1,s2
    800027d4:	6d28                	ld	a0,88(a0)
    800027d6:	fffff097          	auipc	ra,0xfffff
    800027da:	258080e7          	jalr	600(ra) # 80001a2e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027de:	70a2                	ld	ra,40(sp)
    800027e0:	7402                	ld	s0,32(sp)
    800027e2:	64e2                	ld	s1,24(sp)
    800027e4:	6942                	ld	s2,16(sp)
    800027e6:	69a2                	ld	s3,8(sp)
    800027e8:	6a02                	ld	s4,0(sp)
    800027ea:	6145                	addi	sp,sp,48
    800027ec:	8082                	ret
    memmove((char *)dst, src, len);
    800027ee:	000a061b          	sext.w	a2,s4
    800027f2:	85ce                	mv	a1,s3
    800027f4:	854a                	mv	a0,s2
    800027f6:	fffff097          	auipc	ra,0xfffff
    800027fa:	93c080e7          	jalr	-1732(ra) # 80001132 <memmove>
    return 0;
    800027fe:	8526                	mv	a0,s1
    80002800:	bff9                	j	800027de <either_copyout+0x32>

0000000080002802 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002802:	7179                	addi	sp,sp,-48
    80002804:	f406                	sd	ra,40(sp)
    80002806:	f022                	sd	s0,32(sp)
    80002808:	ec26                	sd	s1,24(sp)
    8000280a:	e84a                	sd	s2,16(sp)
    8000280c:	e44e                	sd	s3,8(sp)
    8000280e:	e052                	sd	s4,0(sp)
    80002810:	1800                	addi	s0,sp,48
    80002812:	892a                	mv	s2,a0
    80002814:	84ae                	mv	s1,a1
    80002816:	89b2                	mv	s3,a2
    80002818:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000281a:	fffff097          	auipc	ra,0xfffff
    8000281e:	520080e7          	jalr	1312(ra) # 80001d3a <myproc>
  if(user_src){
    80002822:	c08d                	beqz	s1,80002844 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002824:	86d2                	mv	a3,s4
    80002826:	864e                	mv	a2,s3
    80002828:	85ca                	mv	a1,s2
    8000282a:	6d28                	ld	a0,88(a0)
    8000282c:	fffff097          	auipc	ra,0xfffff
    80002830:	28e080e7          	jalr	654(ra) # 80001aba <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002834:	70a2                	ld	ra,40(sp)
    80002836:	7402                	ld	s0,32(sp)
    80002838:	64e2                	ld	s1,24(sp)
    8000283a:	6942                	ld	s2,16(sp)
    8000283c:	69a2                	ld	s3,8(sp)
    8000283e:	6a02                	ld	s4,0(sp)
    80002840:	6145                	addi	sp,sp,48
    80002842:	8082                	ret
    memmove(dst, (char*)src, len);
    80002844:	000a061b          	sext.w	a2,s4
    80002848:	85ce                	mv	a1,s3
    8000284a:	854a                	mv	a0,s2
    8000284c:	fffff097          	auipc	ra,0xfffff
    80002850:	8e6080e7          	jalr	-1818(ra) # 80001132 <memmove>
    return 0;
    80002854:	8526                	mv	a0,s1
    80002856:	bff9                	j	80002834 <either_copyin+0x32>

0000000080002858 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002858:	715d                	addi	sp,sp,-80
    8000285a:	e486                	sd	ra,72(sp)
    8000285c:	e0a2                	sd	s0,64(sp)
    8000285e:	fc26                	sd	s1,56(sp)
    80002860:	f84a                	sd	s2,48(sp)
    80002862:	f44e                	sd	s3,40(sp)
    80002864:	f052                	sd	s4,32(sp)
    80002866:	ec56                	sd	s5,24(sp)
    80002868:	e85a                	sd	s6,16(sp)
    8000286a:	e45e                	sd	s7,8(sp)
    8000286c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000286e:	00006517          	auipc	a0,0x6
    80002872:	8f250513          	addi	a0,a0,-1806 # 80008160 <digits+0x120>
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	d24080e7          	jalr	-732(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000287e:	00010497          	auipc	s1,0x10
    80002882:	08a48493          	addi	s1,s1,138 # 80012908 <proc+0x160>
    80002886:	00016917          	auipc	s2,0x16
    8000288a:	c8290913          	addi	s2,s2,-894 # 80018508 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000288e:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002890:	00006997          	auipc	s3,0x6
    80002894:	a6898993          	addi	s3,s3,-1432 # 800082f8 <digits+0x2b8>
    printf("%d %s %s", p->pid, state, p->name);
    80002898:	00006a97          	auipc	s5,0x6
    8000289c:	a68a8a93          	addi	s5,s5,-1432 # 80008300 <digits+0x2c0>
    printf("\n");
    800028a0:	00006a17          	auipc	s4,0x6
    800028a4:	8c0a0a13          	addi	s4,s4,-1856 # 80008160 <digits+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028a8:	00006b97          	auipc	s7,0x6
    800028ac:	a90b8b93          	addi	s7,s7,-1392 # 80008338 <states.1712>
    800028b0:	a00d                	j	800028d2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028b2:	ee06a583          	lw	a1,-288(a3)
    800028b6:	8556                	mv	a0,s5
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	ce2080e7          	jalr	-798(ra) # 8000059a <printf>
    printf("\n");
    800028c0:	8552                	mv	a0,s4
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	cd8080e7          	jalr	-808(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028ca:	17048493          	addi	s1,s1,368
    800028ce:	03248163          	beq	s1,s2,800028f0 <procdump+0x98>
    if(p->state == UNUSED)
    800028d2:	86a6                	mv	a3,s1
    800028d4:	ec04a783          	lw	a5,-320(s1)
    800028d8:	dbed                	beqz	a5,800028ca <procdump+0x72>
      state = "???";
    800028da:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028dc:	fcfb6be3          	bltu	s6,a5,800028b2 <procdump+0x5a>
    800028e0:	1782                	slli	a5,a5,0x20
    800028e2:	9381                	srli	a5,a5,0x20
    800028e4:	078e                	slli	a5,a5,0x3
    800028e6:	97de                	add	a5,a5,s7
    800028e8:	6390                	ld	a2,0(a5)
    800028ea:	f661                	bnez	a2,800028b2 <procdump+0x5a>
      state = "???";
    800028ec:	864e                	mv	a2,s3
    800028ee:	b7d1                	j	800028b2 <procdump+0x5a>
  }
}
    800028f0:	60a6                	ld	ra,72(sp)
    800028f2:	6406                	ld	s0,64(sp)
    800028f4:	74e2                	ld	s1,56(sp)
    800028f6:	7942                	ld	s2,48(sp)
    800028f8:	79a2                	ld	s3,40(sp)
    800028fa:	7a02                	ld	s4,32(sp)
    800028fc:	6ae2                	ld	s5,24(sp)
    800028fe:	6b42                	ld	s6,16(sp)
    80002900:	6ba2                	ld	s7,8(sp)
    80002902:	6161                	addi	sp,sp,80
    80002904:	8082                	ret

0000000080002906 <swtch>:
    80002906:	00153023          	sd	ra,0(a0)
    8000290a:	00253423          	sd	sp,8(a0)
    8000290e:	e900                	sd	s0,16(a0)
    80002910:	ed04                	sd	s1,24(a0)
    80002912:	03253023          	sd	s2,32(a0)
    80002916:	03353423          	sd	s3,40(a0)
    8000291a:	03453823          	sd	s4,48(a0)
    8000291e:	03553c23          	sd	s5,56(a0)
    80002922:	05653023          	sd	s6,64(a0)
    80002926:	05753423          	sd	s7,72(a0)
    8000292a:	05853823          	sd	s8,80(a0)
    8000292e:	05953c23          	sd	s9,88(a0)
    80002932:	07a53023          	sd	s10,96(a0)
    80002936:	07b53423          	sd	s11,104(a0)
    8000293a:	0005b083          	ld	ra,0(a1)
    8000293e:	0085b103          	ld	sp,8(a1)
    80002942:	6980                	ld	s0,16(a1)
    80002944:	6d84                	ld	s1,24(a1)
    80002946:	0205b903          	ld	s2,32(a1)
    8000294a:	0285b983          	ld	s3,40(a1)
    8000294e:	0305ba03          	ld	s4,48(a1)
    80002952:	0385ba83          	ld	s5,56(a1)
    80002956:	0405bb03          	ld	s6,64(a1)
    8000295a:	0485bb83          	ld	s7,72(a1)
    8000295e:	0505bc03          	ld	s8,80(a1)
    80002962:	0585bc83          	ld	s9,88(a1)
    80002966:	0605bd03          	ld	s10,96(a1)
    8000296a:	0685bd83          	ld	s11,104(a1)
    8000296e:	8082                	ret

0000000080002970 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002970:	1141                	addi	sp,sp,-16
    80002972:	e406                	sd	ra,8(sp)
    80002974:	e022                	sd	s0,0(sp)
    80002976:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002978:	00006597          	auipc	a1,0x6
    8000297c:	9e858593          	addi	a1,a1,-1560 # 80008360 <states.1712+0x28>
    80002980:	00016517          	auipc	a0,0x16
    80002984:	a2850513          	addi	a0,a0,-1496 # 800183a8 <tickslock>
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	4e6080e7          	jalr	1254(ra) # 80000e6e <initlock>
}
    80002990:	60a2                	ld	ra,8(sp)
    80002992:	6402                	ld	s0,0(sp)
    80002994:	0141                	addi	sp,sp,16
    80002996:	8082                	ret

0000000080002998 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002998:	1141                	addi	sp,sp,-16
    8000299a:	e422                	sd	s0,8(sp)
    8000299c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000299e:	00003797          	auipc	a5,0x3
    800029a2:	73278793          	addi	a5,a5,1842 # 800060d0 <kernelvec>
    800029a6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029aa:	6422                	ld	s0,8(sp)
    800029ac:	0141                	addi	sp,sp,16
    800029ae:	8082                	ret

00000000800029b0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029b0:	1141                	addi	sp,sp,-16
    800029b2:	e406                	sd	ra,8(sp)
    800029b4:	e022                	sd	s0,0(sp)
    800029b6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029b8:	fffff097          	auipc	ra,0xfffff
    800029bc:	382080e7          	jalr	898(ra) # 80001d3a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029c4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029ca:	00004617          	auipc	a2,0x4
    800029ce:	63660613          	addi	a2,a2,1590 # 80007000 <_trampoline>
    800029d2:	00004697          	auipc	a3,0x4
    800029d6:	62e68693          	addi	a3,a3,1582 # 80007000 <_trampoline>
    800029da:	8e91                	sub	a3,a3,a2
    800029dc:	040007b7          	lui	a5,0x4000
    800029e0:	17fd                	addi	a5,a5,-1
    800029e2:	07b2                	slli	a5,a5,0xc
    800029e4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029e6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029ea:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029ec:	180026f3          	csrr	a3,satp
    800029f0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029f2:	7138                	ld	a4,96(a0)
    800029f4:	6534                	ld	a3,72(a0)
    800029f6:	6585                	lui	a1,0x1
    800029f8:	96ae                	add	a3,a3,a1
    800029fa:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029fc:	7138                	ld	a4,96(a0)
    800029fe:	00000697          	auipc	a3,0x0
    80002a02:	13868693          	addi	a3,a3,312 # 80002b36 <usertrap>
    80002a06:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a08:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a0a:	8692                	mv	a3,tp
    80002a0c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a12:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a16:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a1a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a1e:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a20:	6f18                	ld	a4,24(a4)
    80002a22:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a26:	6d2c                	ld	a1,88(a0)
    80002a28:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a2a:	00004717          	auipc	a4,0x4
    80002a2e:	66670713          	addi	a4,a4,1638 # 80007090 <userret>
    80002a32:	8f11                	sub	a4,a4,a2
    80002a34:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a36:	577d                	li	a4,-1
    80002a38:	177e                	slli	a4,a4,0x3f
    80002a3a:	8dd9                	or	a1,a1,a4
    80002a3c:	02000537          	lui	a0,0x2000
    80002a40:	157d                	addi	a0,a0,-1
    80002a42:	0536                	slli	a0,a0,0xd
    80002a44:	9782                	jalr	a5
}
    80002a46:	60a2                	ld	ra,8(sp)
    80002a48:	6402                	ld	s0,0(sp)
    80002a4a:	0141                	addi	sp,sp,16
    80002a4c:	8082                	ret

0000000080002a4e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a4e:	1101                	addi	sp,sp,-32
    80002a50:	ec06                	sd	ra,24(sp)
    80002a52:	e822                	sd	s0,16(sp)
    80002a54:	e426                	sd	s1,8(sp)
    80002a56:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a58:	00016497          	auipc	s1,0x16
    80002a5c:	95048493          	addi	s1,s1,-1712 # 800183a8 <tickslock>
    80002a60:	8526                	mv	a0,s1
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	290080e7          	jalr	656(ra) # 80000cf2 <acquire>
  ticks++;
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	5b650513          	addi	a0,a0,1462 # 80009020 <ticks>
    80002a72:	411c                	lw	a5,0(a0)
    80002a74:	2785                	addiw	a5,a5,1
    80002a76:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a78:	00000097          	auipc	ra,0x0
    80002a7c:	c58080e7          	jalr	-936(ra) # 800026d0 <wakeup>
  release(&tickslock);
    80002a80:	8526                	mv	a0,s1
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	340080e7          	jalr	832(ra) # 80000dc2 <release>
}
    80002a8a:	60e2                	ld	ra,24(sp)
    80002a8c:	6442                	ld	s0,16(sp)
    80002a8e:	64a2                	ld	s1,8(sp)
    80002a90:	6105                	addi	sp,sp,32
    80002a92:	8082                	ret

0000000080002a94 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a94:	1101                	addi	sp,sp,-32
    80002a96:	ec06                	sd	ra,24(sp)
    80002a98:	e822                	sd	s0,16(sp)
    80002a9a:	e426                	sd	s1,8(sp)
    80002a9c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a9e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002aa2:	00074d63          	bltz	a4,80002abc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002aa6:	57fd                	li	a5,-1
    80002aa8:	17fe                	slli	a5,a5,0x3f
    80002aaa:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002aac:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002aae:	06f70363          	beq	a4,a5,80002b14 <devintr+0x80>
  }
}
    80002ab2:	60e2                	ld	ra,24(sp)
    80002ab4:	6442                	ld	s0,16(sp)
    80002ab6:	64a2                	ld	s1,8(sp)
    80002ab8:	6105                	addi	sp,sp,32
    80002aba:	8082                	ret
     (scause & 0xff) == 9){
    80002abc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ac0:	46a5                	li	a3,9
    80002ac2:	fed792e3          	bne	a5,a3,80002aa6 <devintr+0x12>
    int irq = plic_claim();
    80002ac6:	00003097          	auipc	ra,0x3
    80002aca:	712080e7          	jalr	1810(ra) # 800061d8 <plic_claim>
    80002ace:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ad0:	47a9                	li	a5,10
    80002ad2:	02f50763          	beq	a0,a5,80002b00 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ad6:	4785                	li	a5,1
    80002ad8:	02f50963          	beq	a0,a5,80002b0a <devintr+0x76>
    return 1;
    80002adc:	4505                	li	a0,1
    } else if(irq){
    80002ade:	d8f1                	beqz	s1,80002ab2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ae0:	85a6                	mv	a1,s1
    80002ae2:	00006517          	auipc	a0,0x6
    80002ae6:	88650513          	addi	a0,a0,-1914 # 80008368 <states.1712+0x30>
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	ab0080e7          	jalr	-1360(ra) # 8000059a <printf>
      plic_complete(irq);
    80002af2:	8526                	mv	a0,s1
    80002af4:	00003097          	auipc	ra,0x3
    80002af8:	708080e7          	jalr	1800(ra) # 800061fc <plic_complete>
    return 1;
    80002afc:	4505                	li	a0,1
    80002afe:	bf55                	j	80002ab2 <devintr+0x1e>
      uartintr();
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	edc080e7          	jalr	-292(ra) # 800009dc <uartintr>
    80002b08:	b7ed                	j	80002af2 <devintr+0x5e>
      virtio_disk_intr();
    80002b0a:	00004097          	auipc	ra,0x4
    80002b0e:	bd2080e7          	jalr	-1070(ra) # 800066dc <virtio_disk_intr>
    80002b12:	b7c5                	j	80002af2 <devintr+0x5e>
    if(cpuid() == 0){
    80002b14:	fffff097          	auipc	ra,0xfffff
    80002b18:	1fa080e7          	jalr	506(ra) # 80001d0e <cpuid>
    80002b1c:	c901                	beqz	a0,80002b2c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b1e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b22:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b24:	14479073          	csrw	sip,a5
    return 2;
    80002b28:	4509                	li	a0,2
    80002b2a:	b761                	j	80002ab2 <devintr+0x1e>
      clockintr();
    80002b2c:	00000097          	auipc	ra,0x0
    80002b30:	f22080e7          	jalr	-222(ra) # 80002a4e <clockintr>
    80002b34:	b7ed                	j	80002b1e <devintr+0x8a>

0000000080002b36 <usertrap>:
{
    80002b36:	1101                	addi	sp,sp,-32
    80002b38:	ec06                	sd	ra,24(sp)
    80002b3a:	e822                	sd	s0,16(sp)
    80002b3c:	e426                	sd	s1,8(sp)
    80002b3e:	e04a                	sd	s2,0(sp)
    80002b40:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b42:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b46:	1007f793          	andi	a5,a5,256
    80002b4a:	e3ad                	bnez	a5,80002bac <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b4c:	00003797          	auipc	a5,0x3
    80002b50:	58478793          	addi	a5,a5,1412 # 800060d0 <kernelvec>
    80002b54:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b58:	fffff097          	auipc	ra,0xfffff
    80002b5c:	1e2080e7          	jalr	482(ra) # 80001d3a <myproc>
    80002b60:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b62:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b64:	14102773          	csrr	a4,sepc
    80002b68:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b6a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b6e:	47a1                	li	a5,8
    80002b70:	04f71c63          	bne	a4,a5,80002bc8 <usertrap+0x92>
    if(p->killed)
    80002b74:	5d1c                	lw	a5,56(a0)
    80002b76:	e3b9                	bnez	a5,80002bbc <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b78:	70b8                	ld	a4,96(s1)
    80002b7a:	6f1c                	ld	a5,24(a4)
    80002b7c:	0791                	addi	a5,a5,4
    80002b7e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b80:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b84:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b88:	10079073          	csrw	sstatus,a5
    syscall();
    80002b8c:	00000097          	auipc	ra,0x0
    80002b90:	2e0080e7          	jalr	736(ra) # 80002e6c <syscall>
  if(p->killed)
    80002b94:	5c9c                	lw	a5,56(s1)
    80002b96:	ebc1                	bnez	a5,80002c26 <usertrap+0xf0>
  usertrapret();
    80002b98:	00000097          	auipc	ra,0x0
    80002b9c:	e18080e7          	jalr	-488(ra) # 800029b0 <usertrapret>
}
    80002ba0:	60e2                	ld	ra,24(sp)
    80002ba2:	6442                	ld	s0,16(sp)
    80002ba4:	64a2                	ld	s1,8(sp)
    80002ba6:	6902                	ld	s2,0(sp)
    80002ba8:	6105                	addi	sp,sp,32
    80002baa:	8082                	ret
    panic("usertrap: not from user mode");
    80002bac:	00005517          	auipc	a0,0x5
    80002bb0:	7dc50513          	addi	a0,a0,2012 # 80008388 <states.1712+0x50>
    80002bb4:	ffffe097          	auipc	ra,0xffffe
    80002bb8:	99c080e7          	jalr	-1636(ra) # 80000550 <panic>
      exit(-1);
    80002bbc:	557d                	li	a0,-1
    80002bbe:	00000097          	auipc	ra,0x0
    80002bc2:	846080e7          	jalr	-1978(ra) # 80002404 <exit>
    80002bc6:	bf4d                	j	80002b78 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bc8:	00000097          	auipc	ra,0x0
    80002bcc:	ecc080e7          	jalr	-308(ra) # 80002a94 <devintr>
    80002bd0:	892a                	mv	s2,a0
    80002bd2:	c501                	beqz	a0,80002bda <usertrap+0xa4>
  if(p->killed)
    80002bd4:	5c9c                	lw	a5,56(s1)
    80002bd6:	c3a1                	beqz	a5,80002c16 <usertrap+0xe0>
    80002bd8:	a815                	j	80002c0c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bda:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bde:	40b0                	lw	a2,64(s1)
    80002be0:	00005517          	auipc	a0,0x5
    80002be4:	7c850513          	addi	a0,a0,1992 # 800083a8 <states.1712+0x70>
    80002be8:	ffffe097          	auipc	ra,0xffffe
    80002bec:	9b2080e7          	jalr	-1614(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bf0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bf4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bf8:	00005517          	auipc	a0,0x5
    80002bfc:	7e050513          	addi	a0,a0,2016 # 800083d8 <states.1712+0xa0>
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	99a080e7          	jalr	-1638(ra) # 8000059a <printf>
    p->killed = 1;
    80002c08:	4785                	li	a5,1
    80002c0a:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002c0c:	557d                	li	a0,-1
    80002c0e:	fffff097          	auipc	ra,0xfffff
    80002c12:	7f6080e7          	jalr	2038(ra) # 80002404 <exit>
  if(which_dev == 2)
    80002c16:	4789                	li	a5,2
    80002c18:	f8f910e3          	bne	s2,a5,80002b98 <usertrap+0x62>
    yield();
    80002c1c:	00000097          	auipc	ra,0x0
    80002c20:	8f2080e7          	jalr	-1806(ra) # 8000250e <yield>
    80002c24:	bf95                	j	80002b98 <usertrap+0x62>
  int which_dev = 0;
    80002c26:	4901                	li	s2,0
    80002c28:	b7d5                	j	80002c0c <usertrap+0xd6>

0000000080002c2a <kerneltrap>:
{
    80002c2a:	7179                	addi	sp,sp,-48
    80002c2c:	f406                	sd	ra,40(sp)
    80002c2e:	f022                	sd	s0,32(sp)
    80002c30:	ec26                	sd	s1,24(sp)
    80002c32:	e84a                	sd	s2,16(sp)
    80002c34:	e44e                	sd	s3,8(sp)
    80002c36:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c38:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c3c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c40:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c44:	1004f793          	andi	a5,s1,256
    80002c48:	cb85                	beqz	a5,80002c78 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c4a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c4e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c50:	ef85                	bnez	a5,80002c88 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c52:	00000097          	auipc	ra,0x0
    80002c56:	e42080e7          	jalr	-446(ra) # 80002a94 <devintr>
    80002c5a:	cd1d                	beqz	a0,80002c98 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c5c:	4789                	li	a5,2
    80002c5e:	06f50a63          	beq	a0,a5,80002cd2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c62:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c66:	10049073          	csrw	sstatus,s1
}
    80002c6a:	70a2                	ld	ra,40(sp)
    80002c6c:	7402                	ld	s0,32(sp)
    80002c6e:	64e2                	ld	s1,24(sp)
    80002c70:	6942                	ld	s2,16(sp)
    80002c72:	69a2                	ld	s3,8(sp)
    80002c74:	6145                	addi	sp,sp,48
    80002c76:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c78:	00005517          	auipc	a0,0x5
    80002c7c:	78050513          	addi	a0,a0,1920 # 800083f8 <states.1712+0xc0>
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	8d0080e7          	jalr	-1840(ra) # 80000550 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c88:	00005517          	auipc	a0,0x5
    80002c8c:	79850513          	addi	a0,a0,1944 # 80008420 <states.1712+0xe8>
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	8c0080e7          	jalr	-1856(ra) # 80000550 <panic>
    printf("scause %p\n", scause);
    80002c98:	85ce                	mv	a1,s3
    80002c9a:	00005517          	auipc	a0,0x5
    80002c9e:	7a650513          	addi	a0,a0,1958 # 80008440 <states.1712+0x108>
    80002ca2:	ffffe097          	auipc	ra,0xffffe
    80002ca6:	8f8080e7          	jalr	-1800(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002caa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cae:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cb2:	00005517          	auipc	a0,0x5
    80002cb6:	79e50513          	addi	a0,a0,1950 # 80008450 <states.1712+0x118>
    80002cba:	ffffe097          	auipc	ra,0xffffe
    80002cbe:	8e0080e7          	jalr	-1824(ra) # 8000059a <printf>
    panic("kerneltrap");
    80002cc2:	00005517          	auipc	a0,0x5
    80002cc6:	7a650513          	addi	a0,a0,1958 # 80008468 <states.1712+0x130>
    80002cca:	ffffe097          	auipc	ra,0xffffe
    80002cce:	886080e7          	jalr	-1914(ra) # 80000550 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	068080e7          	jalr	104(ra) # 80001d3a <myproc>
    80002cda:	d541                	beqz	a0,80002c62 <kerneltrap+0x38>
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	05e080e7          	jalr	94(ra) # 80001d3a <myproc>
    80002ce4:	5118                	lw	a4,32(a0)
    80002ce6:	478d                	li	a5,3
    80002ce8:	f6f71de3          	bne	a4,a5,80002c62 <kerneltrap+0x38>
    yield();
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	822080e7          	jalr	-2014(ra) # 8000250e <yield>
    80002cf4:	b7bd                	j	80002c62 <kerneltrap+0x38>

0000000080002cf6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	e426                	sd	s1,8(sp)
    80002cfe:	1000                	addi	s0,sp,32
    80002d00:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	038080e7          	jalr	56(ra) # 80001d3a <myproc>
  switch (n) {
    80002d0a:	4795                	li	a5,5
    80002d0c:	0497e163          	bltu	a5,s1,80002d4e <argraw+0x58>
    80002d10:	048a                	slli	s1,s1,0x2
    80002d12:	00005717          	auipc	a4,0x5
    80002d16:	78e70713          	addi	a4,a4,1934 # 800084a0 <states.1712+0x168>
    80002d1a:	94ba                	add	s1,s1,a4
    80002d1c:	409c                	lw	a5,0(s1)
    80002d1e:	97ba                	add	a5,a5,a4
    80002d20:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d22:	713c                	ld	a5,96(a0)
    80002d24:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d26:	60e2                	ld	ra,24(sp)
    80002d28:	6442                	ld	s0,16(sp)
    80002d2a:	64a2                	ld	s1,8(sp)
    80002d2c:	6105                	addi	sp,sp,32
    80002d2e:	8082                	ret
    return p->trapframe->a1;
    80002d30:	713c                	ld	a5,96(a0)
    80002d32:	7fa8                	ld	a0,120(a5)
    80002d34:	bfcd                	j	80002d26 <argraw+0x30>
    return p->trapframe->a2;
    80002d36:	713c                	ld	a5,96(a0)
    80002d38:	63c8                	ld	a0,128(a5)
    80002d3a:	b7f5                	j	80002d26 <argraw+0x30>
    return p->trapframe->a3;
    80002d3c:	713c                	ld	a5,96(a0)
    80002d3e:	67c8                	ld	a0,136(a5)
    80002d40:	b7dd                	j	80002d26 <argraw+0x30>
    return p->trapframe->a4;
    80002d42:	713c                	ld	a5,96(a0)
    80002d44:	6bc8                	ld	a0,144(a5)
    80002d46:	b7c5                	j	80002d26 <argraw+0x30>
    return p->trapframe->a5;
    80002d48:	713c                	ld	a5,96(a0)
    80002d4a:	6fc8                	ld	a0,152(a5)
    80002d4c:	bfe9                	j	80002d26 <argraw+0x30>
  panic("argraw");
    80002d4e:	00005517          	auipc	a0,0x5
    80002d52:	72a50513          	addi	a0,a0,1834 # 80008478 <states.1712+0x140>
    80002d56:	ffffd097          	auipc	ra,0xffffd
    80002d5a:	7fa080e7          	jalr	2042(ra) # 80000550 <panic>

0000000080002d5e <fetchaddr>:
{
    80002d5e:	1101                	addi	sp,sp,-32
    80002d60:	ec06                	sd	ra,24(sp)
    80002d62:	e822                	sd	s0,16(sp)
    80002d64:	e426                	sd	s1,8(sp)
    80002d66:	e04a                	sd	s2,0(sp)
    80002d68:	1000                	addi	s0,sp,32
    80002d6a:	84aa                	mv	s1,a0
    80002d6c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	fcc080e7          	jalr	-52(ra) # 80001d3a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d76:	693c                	ld	a5,80(a0)
    80002d78:	02f4f863          	bgeu	s1,a5,80002da8 <fetchaddr+0x4a>
    80002d7c:	00848713          	addi	a4,s1,8
    80002d80:	02e7e663          	bltu	a5,a4,80002dac <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d84:	46a1                	li	a3,8
    80002d86:	8626                	mv	a2,s1
    80002d88:	85ca                	mv	a1,s2
    80002d8a:	6d28                	ld	a0,88(a0)
    80002d8c:	fffff097          	auipc	ra,0xfffff
    80002d90:	d2e080e7          	jalr	-722(ra) # 80001aba <copyin>
    80002d94:	00a03533          	snez	a0,a0
    80002d98:	40a00533          	neg	a0,a0
}
    80002d9c:	60e2                	ld	ra,24(sp)
    80002d9e:	6442                	ld	s0,16(sp)
    80002da0:	64a2                	ld	s1,8(sp)
    80002da2:	6902                	ld	s2,0(sp)
    80002da4:	6105                	addi	sp,sp,32
    80002da6:	8082                	ret
    return -1;
    80002da8:	557d                	li	a0,-1
    80002daa:	bfcd                	j	80002d9c <fetchaddr+0x3e>
    80002dac:	557d                	li	a0,-1
    80002dae:	b7fd                	j	80002d9c <fetchaddr+0x3e>

0000000080002db0 <fetchstr>:
{
    80002db0:	7179                	addi	sp,sp,-48
    80002db2:	f406                	sd	ra,40(sp)
    80002db4:	f022                	sd	s0,32(sp)
    80002db6:	ec26                	sd	s1,24(sp)
    80002db8:	e84a                	sd	s2,16(sp)
    80002dba:	e44e                	sd	s3,8(sp)
    80002dbc:	1800                	addi	s0,sp,48
    80002dbe:	892a                	mv	s2,a0
    80002dc0:	84ae                	mv	s1,a1
    80002dc2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	f76080e7          	jalr	-138(ra) # 80001d3a <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dcc:	86ce                	mv	a3,s3
    80002dce:	864a                	mv	a2,s2
    80002dd0:	85a6                	mv	a1,s1
    80002dd2:	6d28                	ld	a0,88(a0)
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	d72080e7          	jalr	-654(ra) # 80001b46 <copyinstr>
  if(err < 0)
    80002ddc:	00054763          	bltz	a0,80002dea <fetchstr+0x3a>
  return strlen(buf);
    80002de0:	8526                	mv	a0,s1
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	478080e7          	jalr	1144(ra) # 8000125a <strlen>
}
    80002dea:	70a2                	ld	ra,40(sp)
    80002dec:	7402                	ld	s0,32(sp)
    80002dee:	64e2                	ld	s1,24(sp)
    80002df0:	6942                	ld	s2,16(sp)
    80002df2:	69a2                	ld	s3,8(sp)
    80002df4:	6145                	addi	sp,sp,48
    80002df6:	8082                	ret

0000000080002df8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002df8:	1101                	addi	sp,sp,-32
    80002dfa:	ec06                	sd	ra,24(sp)
    80002dfc:	e822                	sd	s0,16(sp)
    80002dfe:	e426                	sd	s1,8(sp)
    80002e00:	1000                	addi	s0,sp,32
    80002e02:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e04:	00000097          	auipc	ra,0x0
    80002e08:	ef2080e7          	jalr	-270(ra) # 80002cf6 <argraw>
    80002e0c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e0e:	4501                	li	a0,0
    80002e10:	60e2                	ld	ra,24(sp)
    80002e12:	6442                	ld	s0,16(sp)
    80002e14:	64a2                	ld	s1,8(sp)
    80002e16:	6105                	addi	sp,sp,32
    80002e18:	8082                	ret

0000000080002e1a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e1a:	1101                	addi	sp,sp,-32
    80002e1c:	ec06                	sd	ra,24(sp)
    80002e1e:	e822                	sd	s0,16(sp)
    80002e20:	e426                	sd	s1,8(sp)
    80002e22:	1000                	addi	s0,sp,32
    80002e24:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	ed0080e7          	jalr	-304(ra) # 80002cf6 <argraw>
    80002e2e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e30:	4501                	li	a0,0
    80002e32:	60e2                	ld	ra,24(sp)
    80002e34:	6442                	ld	s0,16(sp)
    80002e36:	64a2                	ld	s1,8(sp)
    80002e38:	6105                	addi	sp,sp,32
    80002e3a:	8082                	ret

0000000080002e3c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e3c:	1101                	addi	sp,sp,-32
    80002e3e:	ec06                	sd	ra,24(sp)
    80002e40:	e822                	sd	s0,16(sp)
    80002e42:	e426                	sd	s1,8(sp)
    80002e44:	e04a                	sd	s2,0(sp)
    80002e46:	1000                	addi	s0,sp,32
    80002e48:	84ae                	mv	s1,a1
    80002e4a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e4c:	00000097          	auipc	ra,0x0
    80002e50:	eaa080e7          	jalr	-342(ra) # 80002cf6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e54:	864a                	mv	a2,s2
    80002e56:	85a6                	mv	a1,s1
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	f58080e7          	jalr	-168(ra) # 80002db0 <fetchstr>
}
    80002e60:	60e2                	ld	ra,24(sp)
    80002e62:	6442                	ld	s0,16(sp)
    80002e64:	64a2                	ld	s1,8(sp)
    80002e66:	6902                	ld	s2,0(sp)
    80002e68:	6105                	addi	sp,sp,32
    80002e6a:	8082                	ret

0000000080002e6c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e6c:	1101                	addi	sp,sp,-32
    80002e6e:	ec06                	sd	ra,24(sp)
    80002e70:	e822                	sd	s0,16(sp)
    80002e72:	e426                	sd	s1,8(sp)
    80002e74:	e04a                	sd	s2,0(sp)
    80002e76:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	ec2080e7          	jalr	-318(ra) # 80001d3a <myproc>
    80002e80:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e82:	06053903          	ld	s2,96(a0)
    80002e86:	0a893783          	ld	a5,168(s2)
    80002e8a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e8e:	37fd                	addiw	a5,a5,-1
    80002e90:	4751                	li	a4,20
    80002e92:	00f76f63          	bltu	a4,a5,80002eb0 <syscall+0x44>
    80002e96:	00369713          	slli	a4,a3,0x3
    80002e9a:	00005797          	auipc	a5,0x5
    80002e9e:	61e78793          	addi	a5,a5,1566 # 800084b8 <syscalls>
    80002ea2:	97ba                	add	a5,a5,a4
    80002ea4:	639c                	ld	a5,0(a5)
    80002ea6:	c789                	beqz	a5,80002eb0 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ea8:	9782                	jalr	a5
    80002eaa:	06a93823          	sd	a0,112(s2)
    80002eae:	a839                	j	80002ecc <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002eb0:	16048613          	addi	a2,s1,352
    80002eb4:	40ac                	lw	a1,64(s1)
    80002eb6:	00005517          	auipc	a0,0x5
    80002eba:	5ca50513          	addi	a0,a0,1482 # 80008480 <states.1712+0x148>
    80002ebe:	ffffd097          	auipc	ra,0xffffd
    80002ec2:	6dc080e7          	jalr	1756(ra) # 8000059a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ec6:	70bc                	ld	a5,96(s1)
    80002ec8:	577d                	li	a4,-1
    80002eca:	fbb8                	sd	a4,112(a5)
  }
}
    80002ecc:	60e2                	ld	ra,24(sp)
    80002ece:	6442                	ld	s0,16(sp)
    80002ed0:	64a2                	ld	s1,8(sp)
    80002ed2:	6902                	ld	s2,0(sp)
    80002ed4:	6105                	addi	sp,sp,32
    80002ed6:	8082                	ret

0000000080002ed8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ed8:	1101                	addi	sp,sp,-32
    80002eda:	ec06                	sd	ra,24(sp)
    80002edc:	e822                	sd	s0,16(sp)
    80002ede:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ee0:	fec40593          	addi	a1,s0,-20
    80002ee4:	4501                	li	a0,0
    80002ee6:	00000097          	auipc	ra,0x0
    80002eea:	f12080e7          	jalr	-238(ra) # 80002df8 <argint>
    return -1;
    80002eee:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ef0:	00054963          	bltz	a0,80002f02 <sys_exit+0x2a>
  exit(n);
    80002ef4:	fec42503          	lw	a0,-20(s0)
    80002ef8:	fffff097          	auipc	ra,0xfffff
    80002efc:	50c080e7          	jalr	1292(ra) # 80002404 <exit>
  return 0;  // not reached
    80002f00:	4781                	li	a5,0
}
    80002f02:	853e                	mv	a0,a5
    80002f04:	60e2                	ld	ra,24(sp)
    80002f06:	6442                	ld	s0,16(sp)
    80002f08:	6105                	addi	sp,sp,32
    80002f0a:	8082                	ret

0000000080002f0c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f0c:	1141                	addi	sp,sp,-16
    80002f0e:	e406                	sd	ra,8(sp)
    80002f10:	e022                	sd	s0,0(sp)
    80002f12:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	e26080e7          	jalr	-474(ra) # 80001d3a <myproc>
}
    80002f1c:	4128                	lw	a0,64(a0)
    80002f1e:	60a2                	ld	ra,8(sp)
    80002f20:	6402                	ld	s0,0(sp)
    80002f22:	0141                	addi	sp,sp,16
    80002f24:	8082                	ret

0000000080002f26 <sys_fork>:

uint64
sys_fork(void)
{
    80002f26:	1141                	addi	sp,sp,-16
    80002f28:	e406                	sd	ra,8(sp)
    80002f2a:	e022                	sd	s0,0(sp)
    80002f2c:	0800                	addi	s0,sp,16
  return fork();
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	1cc080e7          	jalr	460(ra) # 800020fa <fork>
}
    80002f36:	60a2                	ld	ra,8(sp)
    80002f38:	6402                	ld	s0,0(sp)
    80002f3a:	0141                	addi	sp,sp,16
    80002f3c:	8082                	ret

0000000080002f3e <sys_wait>:

uint64
sys_wait(void)
{
    80002f3e:	1101                	addi	sp,sp,-32
    80002f40:	ec06                	sd	ra,24(sp)
    80002f42:	e822                	sd	s0,16(sp)
    80002f44:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f46:	fe840593          	addi	a1,s0,-24
    80002f4a:	4501                	li	a0,0
    80002f4c:	00000097          	auipc	ra,0x0
    80002f50:	ece080e7          	jalr	-306(ra) # 80002e1a <argaddr>
    80002f54:	87aa                	mv	a5,a0
    return -1;
    80002f56:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f58:	0007c863          	bltz	a5,80002f68 <sys_wait+0x2a>
  return wait(p);
    80002f5c:	fe843503          	ld	a0,-24(s0)
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	668080e7          	jalr	1640(ra) # 800025c8 <wait>
}
    80002f68:	60e2                	ld	ra,24(sp)
    80002f6a:	6442                	ld	s0,16(sp)
    80002f6c:	6105                	addi	sp,sp,32
    80002f6e:	8082                	ret

0000000080002f70 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f70:	7179                	addi	sp,sp,-48
    80002f72:	f406                	sd	ra,40(sp)
    80002f74:	f022                	sd	s0,32(sp)
    80002f76:	ec26                	sd	s1,24(sp)
    80002f78:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f7a:	fdc40593          	addi	a1,s0,-36
    80002f7e:	4501                	li	a0,0
    80002f80:	00000097          	auipc	ra,0x0
    80002f84:	e78080e7          	jalr	-392(ra) # 80002df8 <argint>
    80002f88:	87aa                	mv	a5,a0
    return -1;
    80002f8a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f8c:	0207c063          	bltz	a5,80002fac <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	daa080e7          	jalr	-598(ra) # 80001d3a <myproc>
    80002f98:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002f9a:	fdc42503          	lw	a0,-36(s0)
    80002f9e:	fffff097          	auipc	ra,0xfffff
    80002fa2:	0e8080e7          	jalr	232(ra) # 80002086 <growproc>
    80002fa6:	00054863          	bltz	a0,80002fb6 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002faa:	8526                	mv	a0,s1
}
    80002fac:	70a2                	ld	ra,40(sp)
    80002fae:	7402                	ld	s0,32(sp)
    80002fb0:	64e2                	ld	s1,24(sp)
    80002fb2:	6145                	addi	sp,sp,48
    80002fb4:	8082                	ret
    return -1;
    80002fb6:	557d                	li	a0,-1
    80002fb8:	bfd5                	j	80002fac <sys_sbrk+0x3c>

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
    80002fd2:	e2a080e7          	jalr	-470(ra) # 80002df8 <argint>
    return -1;
    80002fd6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fd8:	06054563          	bltz	a0,80003042 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fdc:	00015517          	auipc	a0,0x15
    80002fe0:	3cc50513          	addi	a0,a0,972 # 800183a8 <tickslock>
    80002fe4:	ffffe097          	auipc	ra,0xffffe
    80002fe8:	d0e080e7          	jalr	-754(ra) # 80000cf2 <acquire>
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
    80002ffe:	3ae98993          	addi	s3,s3,942 # 800183a8 <tickslock>
    80003002:	00006497          	auipc	s1,0x6
    80003006:	01e48493          	addi	s1,s1,30 # 80009020 <ticks>
    if(myproc()->killed){
    8000300a:	fffff097          	auipc	ra,0xfffff
    8000300e:	d30080e7          	jalr	-720(ra) # 80001d3a <myproc>
    80003012:	5d1c                	lw	a5,56(a0)
    80003014:	ef9d                	bnez	a5,80003052 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003016:	85ce                	mv	a1,s3
    80003018:	8526                	mv	a0,s1
    8000301a:	fffff097          	auipc	ra,0xfffff
    8000301e:	530080e7          	jalr	1328(ra) # 8000254a <sleep>
  while(ticks - ticks0 < n){
    80003022:	409c                	lw	a5,0(s1)
    80003024:	412787bb          	subw	a5,a5,s2
    80003028:	fcc42703          	lw	a4,-52(s0)
    8000302c:	fce7efe3          	bltu	a5,a4,8000300a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003030:	00015517          	auipc	a0,0x15
    80003034:	37850513          	addi	a0,a0,888 # 800183a8 <tickslock>
    80003038:	ffffe097          	auipc	ra,0xffffe
    8000303c:	d8a080e7          	jalr	-630(ra) # 80000dc2 <release>
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
    80003056:	35650513          	addi	a0,a0,854 # 800183a8 <tickslock>
    8000305a:	ffffe097          	auipc	ra,0xffffe
    8000305e:	d68080e7          	jalr	-664(ra) # 80000dc2 <release>
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
    80003078:	d84080e7          	jalr	-636(ra) # 80002df8 <argint>
    8000307c:	87aa                	mv	a5,a0
    return -1;
    8000307e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003080:	0007c863          	bltz	a5,80003090 <sys_kill+0x2a>
  return kill(pid);
    80003084:	fec42503          	lw	a0,-20(s0)
    80003088:	fffff097          	auipc	ra,0xfffff
    8000308c:	6b2080e7          	jalr	1714(ra) # 8000273a <kill>
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
    800030a6:	30650513          	addi	a0,a0,774 # 800183a8 <tickslock>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	c48080e7          	jalr	-952(ra) # 80000cf2 <acquire>
  xticks = ticks;
    800030b2:	00006497          	auipc	s1,0x6
    800030b6:	f6e4a483          	lw	s1,-146(s1) # 80009020 <ticks>
  release(&tickslock);
    800030ba:	00015517          	auipc	a0,0x15
    800030be:	2ee50513          	addi	a0,a0,750 # 800183a8 <tickslock>
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	d00080e7          	jalr	-768(ra) # 80000dc2 <release>
  return xticks;
}
    800030ca:	02049513          	slli	a0,s1,0x20
    800030ce:	9101                	srli	a0,a0,0x20
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	64a2                	ld	s1,8(sp)
    800030d6:	6105                	addi	sp,sp,32
    800030d8:	8082                	ret

00000000800030da <hash>:
} bcache;
  
//散列函数
int
hash(int blockno)
{
    800030da:	1141                	addi	sp,sp,-16
    800030dc:	e422                	sd	s0,8(sp)
    800030de:	0800                	addi	s0,sp,16
  return blockno % NBUCKET;
}
    800030e0:	47b5                	li	a5,13
    800030e2:	02f5653b          	remw	a0,a0,a5
    800030e6:	6422                	ld	s0,8(sp)
    800030e8:	0141                	addi	sp,sp,16
    800030ea:	8082                	ret

00000000800030ec <binit>:

void
binit(void)
{
    800030ec:	7179                	addi	sp,sp,-48
    800030ee:	f406                	sd	ra,40(sp)
    800030f0:	f022                	sd	s0,32(sp)
    800030f2:	ec26                	sd	s1,24(sp)
    800030f4:	e84a                	sd	s2,16(sp)
    800030f6:	e44e                	sd	s3,8(sp)
    800030f8:	e052                	sd	s4,0(sp)
    800030fa:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.biglock, "bcache_biglock");
    800030fc:	00005597          	auipc	a1,0x5
    80003100:	46c58593          	addi	a1,a1,1132 # 80008568 <syscalls+0xb0>
    80003104:	00015517          	auipc	a0,0x15
    80003108:	2c450513          	addi	a0,a0,708 # 800183c8 <bcache>
    8000310c:	ffffe097          	auipc	ra,0xffffe
    80003110:	d62080e7          	jalr	-670(ra) # 80000e6e <initlock>
  for (int i = 0; i < NBUCKET; i++)
    80003114:	00015497          	auipc	s1,0x15
    80003118:	2d448493          	addi	s1,s1,724 # 800183e8 <bcache+0x20>
    8000311c:	00015997          	auipc	s3,0x15
    80003120:	46c98993          	addi	s3,s3,1132 # 80018588 <bcache+0x1c0>
    initlock(&bcache.lock[i], "bcache");
    80003124:	00005917          	auipc	s2,0x5
    80003128:	fdc90913          	addi	s2,s2,-36 # 80008100 <digits+0xc0>
    8000312c:	85ca                	mv	a1,s2
    8000312e:	8526                	mv	a0,s1
    80003130:	ffffe097          	auipc	ra,0xffffe
    80003134:	d3e080e7          	jalr	-706(ra) # 80000e6e <initlock>
  for (int i = 0; i < NBUCKET; i++)
    80003138:	02048493          	addi	s1,s1,32
    8000313c:	ff3498e3          	bne	s1,s3,8000312c <binit+0x40>
    80003140:	0001e797          	auipc	a5,0x1e
    80003144:	87878793          	addi	a5,a5,-1928 # 800209b8 <bcache+0x85f0>
    80003148:	00015717          	auipc	a4,0x15
    8000314c:	28070713          	addi	a4,a4,640 # 800183c8 <bcache>
    80003150:	66b1                	lui	a3,0xc
    80003152:	f3868693          	addi	a3,a3,-200 # bf38 <_entry-0x7fff40c8>
    80003156:	9736                	add	a4,a4,a3
  // Create linked list of buffers
  //bcache.head.prev = &bcache.head;
  //bcache.head.next = &bcache.head;
  //每个节点前驱后继都是自身，初始化  
  for (int i = 0; i < NBUCKET; i++) {
    bcache.head[i].next = &bcache.head[i];
    80003158:	efbc                	sd	a5,88(a5)
    bcache.head[i].prev = &bcache.head[i];
    8000315a:	ebbc                	sd	a5,80(a5)
  for (int i = 0; i < NBUCKET; i++) {
    8000315c:	46878793          	addi	a5,a5,1128
    80003160:	fee79ce3          	bne	a5,a4,80003158 <binit+0x6c>
  }
    
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003164:	00015497          	auipc	s1,0x15
    80003168:	42448493          	addi	s1,s1,1060 # 80018588 <bcache+0x1c0>
    b->next = bcache.head[0].next;
    8000316c:	0001d917          	auipc	s2,0x1d
    80003170:	25c90913          	addi	s2,s2,604 # 800203c8 <bcache+0x8000>
    b->prev = &bcache.head[0];
    80003174:	0001e997          	auipc	s3,0x1e
    80003178:	84498993          	addi	s3,s3,-1980 # 800209b8 <bcache+0x85f0>
    initsleeplock(&b->lock, "buffer");
    8000317c:	00005a17          	auipc	s4,0x5
    80003180:	3fca0a13          	addi	s4,s4,1020 # 80008578 <syscalls+0xc0>
    b->next = bcache.head[0].next;
    80003184:	64893783          	ld	a5,1608(s2)
    80003188:	ecbc                	sd	a5,88(s1)
    b->prev = &bcache.head[0];
    8000318a:	0534b823          	sd	s3,80(s1)
    initsleeplock(&b->lock, "buffer");
    8000318e:	85d2                	mv	a1,s4
    80003190:	01048513          	addi	a0,s1,16
    80003194:	00001097          	auipc	ra,0x1
    80003198:	6bc080e7          	jalr	1724(ra) # 80004850 <initsleeplock>
    bcache.head[0].next->prev = b;
    8000319c:	64893783          	ld	a5,1608(s2)
    800031a0:	eba4                	sd	s1,80(a5)
    bcache.head[0].next = b;
    800031a2:	64993423          	sd	s1,1608(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031a6:	46848493          	addi	s1,s1,1128
    800031aa:	fd349de3          	bne	s1,s3,80003184 <binit+0x98>
  }
}
    800031ae:	70a2                	ld	ra,40(sp)
    800031b0:	7402                	ld	s0,32(sp)
    800031b2:	64e2                	ld	s1,24(sp)
    800031b4:	6942                	ld	s2,16(sp)
    800031b6:	69a2                	ld	s3,8(sp)
    800031b8:	6a02                	ld	s4,0(sp)
    800031ba:	6145                	addi	sp,sp,48
    800031bc:	8082                	ret

00000000800031be <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031be:	7159                	addi	sp,sp,-112
    800031c0:	f486                	sd	ra,104(sp)
    800031c2:	f0a2                	sd	s0,96(sp)
    800031c4:	eca6                	sd	s1,88(sp)
    800031c6:	e8ca                	sd	s2,80(sp)
    800031c8:	e4ce                	sd	s3,72(sp)
    800031ca:	e0d2                	sd	s4,64(sp)
    800031cc:	fc56                	sd	s5,56(sp)
    800031ce:	f85a                	sd	s6,48(sp)
    800031d0:	f45e                	sd	s7,40(sp)
    800031d2:	f062                	sd	s8,32(sp)
    800031d4:	ec66                	sd	s9,24(sp)
    800031d6:	e86a                	sd	s10,16(sp)
    800031d8:	e46e                	sd	s11,8(sp)
    800031da:	1880                	addi	s0,sp,112
    800031dc:	8baa                	mv	s7,a0
    800031de:	8b2e                	mv	s6,a1
  return blockno % NBUCKET;
    800031e0:	49b5                	li	s3,13
    800031e2:	0335e9bb          	remw	s3,a1,s3
    800031e6:	00098c1b          	sext.w	s8,s3
  acquire(&bcache.lock[i]);
    800031ea:	001c0a13          	addi	s4,s8,1
    800031ee:	0a16                	slli	s4,s4,0x5
    800031f0:	00015917          	auipc	s2,0x15
    800031f4:	1d890913          	addi	s2,s2,472 # 800183c8 <bcache>
    800031f8:	9a4a                	add	s4,s4,s2
    800031fa:	8552                	mv	a0,s4
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	af6080e7          	jalr	-1290(ra) # 80000cf2 <acquire>
  for(b = bcache.head[i].next; b != &bcache.head[i]; b = b->next){
    80003204:	46800793          	li	a5,1128
    80003208:	02fc07b3          	mul	a5,s8,a5
    8000320c:	00f906b3          	add	a3,s2,a5
    80003210:	6721                	lui	a4,0x8
    80003212:	96ba                	add	a3,a3,a4
    80003214:	6486b483          	ld	s1,1608(a3)
    80003218:	5f070713          	addi	a4,a4,1520 # 85f0 <_entry-0x7fff7a10>
    8000321c:	97ba                	add	a5,a5,a4
    8000321e:	993e                	add	s2,s2,a5
    80003220:	05249863          	bne	s1,s2,80003270 <bread+0xb2>
  release(&bcache.lock[i]);
    80003224:	8552                	mv	a0,s4
    80003226:	ffffe097          	auipc	ra,0xffffe
    8000322a:	b9c080e7          	jalr	-1124(ra) # 80000dc2 <release>
  acquire(&bcache.biglock);
    8000322e:	00015517          	auipc	a0,0x15
    80003232:	19a50513          	addi	a0,a0,410 # 800183c8 <bcache>
    80003236:	ffffe097          	auipc	ra,0xffffe
    8000323a:	abc080e7          	jalr	-1348(ra) # 80000cf2 <acquire>
  acquire(&bcache.lock[i]);
    8000323e:	8552                	mv	a0,s4
    80003240:	ffffe097          	auipc	ra,0xffffe
    80003244:	ab2080e7          	jalr	-1358(ra) # 80000cf2 <acquire>
  for (b = bcache.head[i].next; b != &bcache.head[i]; b = b->next) {
    80003248:	46800713          	li	a4,1128
    8000324c:	02ec0733          	mul	a4,s8,a4
    80003250:	00015797          	auipc	a5,0x15
    80003254:	17878793          	addi	a5,a5,376 # 800183c8 <bcache>
    80003258:	973e                	add	a4,a4,a5
    8000325a:	67a1                	lui	a5,0x8
    8000325c:	97ba                	add	a5,a5,a4
    8000325e:	6487b783          	ld	a5,1608(a5) # 8648 <_entry-0x7fff79b8>
    80003262:	0f278763          	beq	a5,s2,80003350 <bread+0x192>
    80003266:	84be                	mv	s1,a5
    80003268:	a825                	j	800032a0 <bread+0xe2>
  for(b = bcache.head[i].next; b != &bcache.head[i]; b = b->next){
    8000326a:	6ca4                	ld	s1,88(s1)
    8000326c:	fb248ce3          	beq	s1,s2,80003224 <bread+0x66>
    if(b->dev == dev && b->blockno == blockno){
    80003270:	449c                	lw	a5,8(s1)
    80003272:	ff779ce3          	bne	a5,s7,8000326a <bread+0xac>
    80003276:	44dc                	lw	a5,12(s1)
    80003278:	ff6799e3          	bne	a5,s6,8000326a <bread+0xac>
      b->refcnt++;
    8000327c:	44bc                	lw	a5,72(s1)
    8000327e:	2785                	addiw	a5,a5,1
    80003280:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock[i]);
    80003282:	8552                	mv	a0,s4
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	b3e080e7          	jalr	-1218(ra) # 80000dc2 <release>
      acquiresleep(&b->lock);
    8000328c:	01048513          	addi	a0,s1,16
    80003290:	00001097          	auipc	ra,0x1
    80003294:	5fa080e7          	jalr	1530(ra) # 8000488a <acquiresleep>
      return b;
    80003298:	a245                	j	80003438 <bread+0x27a>
  for (b = bcache.head[i].next; b != &bcache.head[i]; b = b->next) {
    8000329a:	6ca4                	ld	s1,88(s1)
    8000329c:	03248f63          	beq	s1,s2,800032da <bread+0x11c>
    if(b->dev == dev && b->blockno == blockno) {
    800032a0:	4498                	lw	a4,8(s1)
    800032a2:	ff771ce3          	bne	a4,s7,8000329a <bread+0xdc>
    800032a6:	44d8                	lw	a4,12(s1)
    800032a8:	ff6719e3          	bne	a4,s6,8000329a <bread+0xdc>
      b->refcnt++;
    800032ac:	44bc                	lw	a5,72(s1)
    800032ae:	2785                	addiw	a5,a5,1
    800032b0:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock[i]);
    800032b2:	8552                	mv	a0,s4
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	b0e080e7          	jalr	-1266(ra) # 80000dc2 <release>
      release(&bcache.biglock);
    800032bc:	00015517          	auipc	a0,0x15
    800032c0:	10c50513          	addi	a0,a0,268 # 800183c8 <bcache>
    800032c4:	ffffe097          	auipc	ra,0xffffe
    800032c8:	afe080e7          	jalr	-1282(ra) # 80000dc2 <release>
      acquiresleep(&b->lock);
    800032cc:	01048513          	addi	a0,s1,16
    800032d0:	00001097          	auipc	ra,0x1
    800032d4:	5ba080e7          	jalr	1466(ra) # 8000488a <acquiresleep>
      return b;
    800032d8:	a285                	j	80003438 <bread+0x27a>
    800032da:	4c81                	li	s9,0
    800032dc:	4481                	li	s1,0
    800032de:	a039                	j	800032ec <bread+0x12e>
      min_ticks = b->lastuse;
    800032e0:	4607ac83          	lw	s9,1120(a5)
    800032e4:	84be                	mv	s1,a5
  for (b = bcache.head[i].next; b != &bcache.head[i]; b = b->next) {
    800032e6:	6fbc                	ld	a5,88(a5)
    800032e8:	01278a63          	beq	a5,s2,800032fc <bread+0x13e>
    if (b->refcnt == 0 && (b2 == 0 || b->lastuse < min_ticks)) {
    800032ec:	47b8                	lw	a4,72(a5)
    800032ee:	ff65                	bnez	a4,800032e6 <bread+0x128>
    800032f0:	d8e5                	beqz	s1,800032e0 <bread+0x122>
    800032f2:	4607a703          	lw	a4,1120(a5)
    800032f6:	ff9778e3          	bgeu	a4,s9,800032e6 <bread+0x128>
    800032fa:	b7dd                	j	800032e0 <bread+0x122>
  if (b2) {
    800032fc:	ec89                	bnez	s1,80003316 <bread+0x158>
  for (int j = hash(i + 1); j != i; j = hash(j + 1)) {
    800032fe:	2985                	addiw	s3,s3,1
  return blockno % NBUCKET;
    80003300:	47b5                	li	a5,13
    80003302:	02f9e9bb          	remw	s3,s3,a5
  for (int j = hash(i + 1); j != i; j = hash(j + 1)) {
    80003306:	153c0b63          	beq	s8,s3,8000345c <bread+0x29e>
    acquire(&bcache.lock[j]);
    8000330a:	00015d17          	auipc	s10,0x15
    8000330e:	0bed0d13          	addi	s10,s10,190 # 800183c8 <bcache>
    for (b = bcache.head[j].next; b != &bcache.head[j]; b = b->next) {
    80003312:	6da1                	lui	s11,0x8
    80003314:	a8ad                	j	8000338e <bread+0x1d0>
    b2->dev = dev;
    80003316:	0174a423          	sw	s7,8(s1)
    b2->blockno = blockno;
    8000331a:	0164a623          	sw	s6,12(s1)
    b2->refcnt++;
    8000331e:	44bc                	lw	a5,72(s1)
    80003320:	2785                	addiw	a5,a5,1
    80003322:	c4bc                	sw	a5,72(s1)
    b2->valid = 0;
    80003324:	0004a023          	sw	zero,0(s1)
    release(&bcache.lock[i]);
    80003328:	8552                	mv	a0,s4
    8000332a:	ffffe097          	auipc	ra,0xffffe
    8000332e:	a98080e7          	jalr	-1384(ra) # 80000dc2 <release>
    release(&bcache.biglock);
    80003332:	00015517          	auipc	a0,0x15
    80003336:	09650513          	addi	a0,a0,150 # 800183c8 <bcache>
    8000333a:	ffffe097          	auipc	ra,0xffffe
    8000333e:	a88080e7          	jalr	-1400(ra) # 80000dc2 <release>
    acquiresleep(&b2->lock);
    80003342:	01048513          	addi	a0,s1,16
    80003346:	00001097          	auipc	ra,0x1
    8000334a:	544080e7          	jalr	1348(ra) # 8000488a <acquiresleep>
    return b2;
    8000334e:	a0ed                	j	80003438 <bread+0x27a>
  int i = hash(blockno), min_ticks = 0;
    80003350:	4c81                	li	s9,0
    80003352:	b775                	j	800032fe <bread+0x140>
        min_ticks = b->lastuse;
    80003354:	4607ac83          	lw	s9,1120(a5)
    80003358:	84be                	mv	s1,a5
    for (b = bcache.head[j].next; b != &bcache.head[j]; b = b->next) {
    8000335a:	6fbc                	ld	a5,88(a5)
    8000335c:	06f70463          	beq	a4,a5,800033c4 <bread+0x206>
      if (b->refcnt == 0 && (b2 == 0 || b->lastuse < min_ticks)) {
    80003360:	47b4                	lw	a3,72(a5)
    80003362:	e699                	bnez	a3,80003370 <bread+0x1b2>
    80003364:	d8e5                	beqz	s1,80003354 <bread+0x196>
    80003366:	4607a683          	lw	a3,1120(a5)
    8000336a:	ff96f8e3          	bgeu	a3,s9,8000335a <bread+0x19c>
    8000336e:	b7dd                	j	80003354 <bread+0x196>
    for (b = bcache.head[j].next; b != &bcache.head[j]; b = b->next) {
    80003370:	6fbc                	ld	a5,88(a5)
    80003372:	fef717e3          	bne	a4,a5,80003360 <bread+0x1a2>
    if(b2) {
    80003376:	e4b9                	bnez	s1,800033c4 <bread+0x206>
    release(&bcache.lock[j]);
    80003378:	8556                	mv	a0,s5
    8000337a:	ffffe097          	auipc	ra,0xffffe
    8000337e:	a48080e7          	jalr	-1464(ra) # 80000dc2 <release>
  for (int j = hash(i + 1); j != i; j = hash(j + 1)) {
    80003382:	2985                	addiw	s3,s3,1
  return blockno % NBUCKET;
    80003384:	47b5                	li	a5,13
    80003386:	02f9e9bb          	remw	s3,s3,a5
  for (int j = hash(i + 1); j != i; j = hash(j + 1)) {
    8000338a:	0d3c0963          	beq	s8,s3,8000345c <bread+0x29e>
    acquire(&bcache.lock[j]);
    8000338e:	00198a93          	addi	s5,s3,1
    80003392:	0a96                	slli	s5,s5,0x5
    80003394:	9aea                	add	s5,s5,s10
    80003396:	8556                	mv	a0,s5
    80003398:	ffffe097          	auipc	ra,0xffffe
    8000339c:	95a080e7          	jalr	-1702(ra) # 80000cf2 <acquire>
    for (b = bcache.head[j].next; b != &bcache.head[j]; b = b->next) {
    800033a0:	46800793          	li	a5,1128
    800033a4:	02f98733          	mul	a4,s3,a5
    800033a8:	00ed07b3          	add	a5,s10,a4
    800033ac:	97ee                	add	a5,a5,s11
    800033ae:	6487b783          	ld	a5,1608(a5)
    800033b2:	66a1                	lui	a3,0x8
    800033b4:	5f068693          	addi	a3,a3,1520 # 85f0 <_entry-0x7fff7a10>
    800033b8:	9736                	add	a4,a4,a3
    800033ba:	976a                	add	a4,a4,s10
    800033bc:	faf70ee3          	beq	a4,a5,80003378 <bread+0x1ba>
    800033c0:	4481                	li	s1,0
    800033c2:	bf79                	j	80003360 <bread+0x1a2>
      b2->dev = dev;
    800033c4:	0174a423          	sw	s7,8(s1)
      b2->refcnt++;
    800033c8:	44bc                	lw	a5,72(s1)
    800033ca:	2785                	addiw	a5,a5,1
    800033cc:	c4bc                	sw	a5,72(s1)
      b2->valid = 0;
    800033ce:	0004a023          	sw	zero,0(s1)
      b2->blockno = blockno;
    800033d2:	0164a623          	sw	s6,12(s1)
      b2->next->prev = b2->prev;
    800033d6:	6cbc                	ld	a5,88(s1)
    800033d8:	68b8                	ld	a4,80(s1)
    800033da:	ebb8                	sd	a4,80(a5)
      b2->prev->next = b2->next;
    800033dc:	68bc                	ld	a5,80(s1)
    800033de:	6cb8                	ld	a4,88(s1)
    800033e0:	efb8                	sd	a4,88(a5)
      release(&bcache.lock[j]);
    800033e2:	8556                	mv	a0,s5
    800033e4:	ffffe097          	auipc	ra,0xffffe
    800033e8:	9de080e7          	jalr	-1570(ra) # 80000dc2 <release>
      b2->next = bcache.head[i].next;
    800033ec:	00015997          	auipc	s3,0x15
    800033f0:	fdc98993          	addi	s3,s3,-36 # 800183c8 <bcache>
    800033f4:	46800793          	li	a5,1128
    800033f8:	02fc0c33          	mul	s8,s8,a5
    800033fc:	018987b3          	add	a5,s3,s8
    80003400:	6c21                	lui	s8,0x8
    80003402:	9c3e                	add	s8,s8,a5
    80003404:	648c3783          	ld	a5,1608(s8) # 8648 <_entry-0x7fff79b8>
    80003408:	ecbc                	sd	a5,88(s1)
      b2->prev = &bcache.head[i];
    8000340a:	0524b823          	sd	s2,80(s1)
      bcache.head[i].next->prev = b2;
    8000340e:	648c3783          	ld	a5,1608(s8)
    80003412:	eba4                	sd	s1,80(a5)
      bcache.head[i].next = b2;
    80003414:	649c3423          	sd	s1,1608(s8)
      release(&bcache.lock[i]);
    80003418:	8552                	mv	a0,s4
    8000341a:	ffffe097          	auipc	ra,0xffffe
    8000341e:	9a8080e7          	jalr	-1624(ra) # 80000dc2 <release>
      release(&bcache.biglock);
    80003422:	854e                	mv	a0,s3
    80003424:	ffffe097          	auipc	ra,0xffffe
    80003428:	99e080e7          	jalr	-1634(ra) # 80000dc2 <release>
      acquiresleep(&b2->lock);
    8000342c:	01048513          	addi	a0,s1,16
    80003430:	00001097          	auipc	ra,0x1
    80003434:	45a080e7          	jalr	1114(ra) # 8000488a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003438:	409c                	lw	a5,0(s1)
    8000343a:	c7b1                	beqz	a5,80003486 <bread+0x2c8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000343c:	8526                	mv	a0,s1
    8000343e:	70a6                	ld	ra,104(sp)
    80003440:	7406                	ld	s0,96(sp)
    80003442:	64e6                	ld	s1,88(sp)
    80003444:	6946                	ld	s2,80(sp)
    80003446:	69a6                	ld	s3,72(sp)
    80003448:	6a06                	ld	s4,64(sp)
    8000344a:	7ae2                	ld	s5,56(sp)
    8000344c:	7b42                	ld	s6,48(sp)
    8000344e:	7ba2                	ld	s7,40(sp)
    80003450:	7c02                	ld	s8,32(sp)
    80003452:	6ce2                	ld	s9,24(sp)
    80003454:	6d42                	ld	s10,16(sp)
    80003456:	6da2                	ld	s11,8(sp)
    80003458:	6165                	addi	sp,sp,112
    8000345a:	8082                	ret
  release(&bcache.lock[i]);
    8000345c:	8552                	mv	a0,s4
    8000345e:	ffffe097          	auipc	ra,0xffffe
    80003462:	964080e7          	jalr	-1692(ra) # 80000dc2 <release>
  release(&bcache.biglock);
    80003466:	00015517          	auipc	a0,0x15
    8000346a:	f6250513          	addi	a0,a0,-158 # 800183c8 <bcache>
    8000346e:	ffffe097          	auipc	ra,0xffffe
    80003472:	954080e7          	jalr	-1708(ra) # 80000dc2 <release>
  panic("bget: no buffers");
    80003476:	00005517          	auipc	a0,0x5
    8000347a:	10a50513          	addi	a0,a0,266 # 80008580 <syscalls+0xc8>
    8000347e:	ffffd097          	auipc	ra,0xffffd
    80003482:	0d2080e7          	jalr	210(ra) # 80000550 <panic>
    virtio_disk_rw(b, 0);
    80003486:	4581                	li	a1,0
    80003488:	8526                	mv	a0,s1
    8000348a:	00003097          	auipc	ra,0x3
    8000348e:	f7c080e7          	jalr	-132(ra) # 80006406 <virtio_disk_rw>
    b->valid = 1;
    80003492:	4785                	li	a5,1
    80003494:	c09c                	sw	a5,0(s1)
  return b;
    80003496:	b75d                	j	8000343c <bread+0x27e>

0000000080003498 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003498:	1101                	addi	sp,sp,-32
    8000349a:	ec06                	sd	ra,24(sp)
    8000349c:	e822                	sd	s0,16(sp)
    8000349e:	e426                	sd	s1,8(sp)
    800034a0:	1000                	addi	s0,sp,32
    800034a2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034a4:	0541                	addi	a0,a0,16
    800034a6:	00001097          	auipc	ra,0x1
    800034aa:	47e080e7          	jalr	1150(ra) # 80004924 <holdingsleep>
    800034ae:	cd01                	beqz	a0,800034c6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034b0:	4585                	li	a1,1
    800034b2:	8526                	mv	a0,s1
    800034b4:	00003097          	auipc	ra,0x3
    800034b8:	f52080e7          	jalr	-174(ra) # 80006406 <virtio_disk_rw>
}
    800034bc:	60e2                	ld	ra,24(sp)
    800034be:	6442                	ld	s0,16(sp)
    800034c0:	64a2                	ld	s1,8(sp)
    800034c2:	6105                	addi	sp,sp,32
    800034c4:	8082                	ret
    panic("bwrite");
    800034c6:	00005517          	auipc	a0,0x5
    800034ca:	0d250513          	addi	a0,a0,210 # 80008598 <syscalls+0xe0>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	082080e7          	jalr	130(ra) # 80000550 <panic>

00000000800034d6 <brelse>:
// Release a locked buffer.
// Move to the head of the most-recently-used list.

void
brelse(struct buf *b)
{
    800034d6:	1101                	addi	sp,sp,-32
    800034d8:	ec06                	sd	ra,24(sp)
    800034da:	e822                	sd	s0,16(sp)
    800034dc:	e426                	sd	s1,8(sp)
    800034de:	e04a                	sd	s2,0(sp)
    800034e0:	1000                	addi	s0,sp,32
    800034e2:	892a                	mv	s2,a0
  if(!holdingsleep(&b->lock))
    800034e4:	01050493          	addi	s1,a0,16
    800034e8:	8526                	mv	a0,s1
    800034ea:	00001097          	auipc	ra,0x1
    800034ee:	43a080e7          	jalr	1082(ra) # 80004924 <holdingsleep>
    800034f2:	c125                	beqz	a0,80003552 <brelse+0x7c>
    panic("brelse");

  releasesleep(&b->lock);
    800034f4:	8526                	mv	a0,s1
    800034f6:	00001097          	auipc	ra,0x1
    800034fa:	3ea080e7          	jalr	1002(ra) # 800048e0 <releasesleep>
  return blockno % NBUCKET;
    800034fe:	00c92483          	lw	s1,12(s2)

  int i = hash(b->blockno);

  acquire(&bcache.lock[i]);
    80003502:	47b5                	li	a5,13
    80003504:	02f4e4bb          	remw	s1,s1,a5
    80003508:	0485                	addi	s1,s1,1
    8000350a:	0496                	slli	s1,s1,0x5
    8000350c:	00015797          	auipc	a5,0x15
    80003510:	ebc78793          	addi	a5,a5,-324 # 800183c8 <bcache>
    80003514:	94be                	add	s1,s1,a5
    80003516:	8526                	mv	a0,s1
    80003518:	ffffd097          	auipc	ra,0xffffd
    8000351c:	7da080e7          	jalr	2010(ra) # 80000cf2 <acquire>
  b->refcnt--;
    80003520:	04892783          	lw	a5,72(s2)
    80003524:	37fd                	addiw	a5,a5,-1
    80003526:	0007871b          	sext.w	a4,a5
    8000352a:	04f92423          	sw	a5,72(s2)
  if (b->refcnt == 0) {
    8000352e:	e719                	bnez	a4,8000353c <brelse+0x66>
    //b->prev->next = b->next;
    //b->next = bcache.head[i].next;
    //b->prev = &bcache.head[i];
    //bcache.head[i].next->prev = b;
    //bcache.head[i].next = b;
    b->lastuse = ticks;
    80003530:	00006797          	auipc	a5,0x6
    80003534:	af07a783          	lw	a5,-1296(a5) # 80009020 <ticks>
    80003538:	46f92023          	sw	a5,1120(s2)
  }

  release(&bcache.lock[i]);
    8000353c:	8526                	mv	a0,s1
    8000353e:	ffffe097          	auipc	ra,0xffffe
    80003542:	884080e7          	jalr	-1916(ra) # 80000dc2 <release>
}
    80003546:	60e2                	ld	ra,24(sp)
    80003548:	6442                	ld	s0,16(sp)
    8000354a:	64a2                	ld	s1,8(sp)
    8000354c:	6902                	ld	s2,0(sp)
    8000354e:	6105                	addi	sp,sp,32
    80003550:	8082                	ret
    panic("brelse");
    80003552:	00005517          	auipc	a0,0x5
    80003556:	04e50513          	addi	a0,a0,78 # 800085a0 <syscalls+0xe8>
    8000355a:	ffffd097          	auipc	ra,0xffffd
    8000355e:	ff6080e7          	jalr	-10(ra) # 80000550 <panic>

0000000080003562 <bpin>:

void
bpin(struct buf *b) {
    80003562:	1101                	addi	sp,sp,-32
    80003564:	ec06                	sd	ra,24(sp)
    80003566:	e822                	sd	s0,16(sp)
    80003568:	e426                	sd	s1,8(sp)
    8000356a:	e04a                	sd	s2,0(sp)
    8000356c:	1000                	addi	s0,sp,32
    8000356e:	892a                	mv	s2,a0
  return blockno % NBUCKET;
    80003570:	4544                	lw	s1,12(a0)
  int i = hash(b->blockno);
  acquire(&bcache.lock[i]);
    80003572:	47b5                	li	a5,13
    80003574:	02f4e4bb          	remw	s1,s1,a5
    80003578:	0485                	addi	s1,s1,1
    8000357a:	0496                	slli	s1,s1,0x5
    8000357c:	00015797          	auipc	a5,0x15
    80003580:	e4c78793          	addi	a5,a5,-436 # 800183c8 <bcache>
    80003584:	94be                	add	s1,s1,a5
    80003586:	8526                	mv	a0,s1
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	76a080e7          	jalr	1898(ra) # 80000cf2 <acquire>
  b->refcnt++;
    80003590:	04892783          	lw	a5,72(s2)
    80003594:	2785                	addiw	a5,a5,1
    80003596:	04f92423          	sw	a5,72(s2)
  release(&bcache.lock[i]);
    8000359a:	8526                	mv	a0,s1
    8000359c:	ffffe097          	auipc	ra,0xffffe
    800035a0:	826080e7          	jalr	-2010(ra) # 80000dc2 <release>
}
    800035a4:	60e2                	ld	ra,24(sp)
    800035a6:	6442                	ld	s0,16(sp)
    800035a8:	64a2                	ld	s1,8(sp)
    800035aa:	6902                	ld	s2,0(sp)
    800035ac:	6105                	addi	sp,sp,32
    800035ae:	8082                	ret

00000000800035b0 <bunpin>:

void
bunpin(struct buf *b) {
    800035b0:	1101                	addi	sp,sp,-32
    800035b2:	ec06                	sd	ra,24(sp)
    800035b4:	e822                	sd	s0,16(sp)
    800035b6:	e426                	sd	s1,8(sp)
    800035b8:	e04a                	sd	s2,0(sp)
    800035ba:	1000                	addi	s0,sp,32
    800035bc:	892a                	mv	s2,a0
  return blockno % NBUCKET;
    800035be:	4544                	lw	s1,12(a0)
  int i = hash(b->blockno);
  acquire(&bcache.lock[i]);
    800035c0:	47b5                	li	a5,13
    800035c2:	02f4e4bb          	remw	s1,s1,a5
    800035c6:	0485                	addi	s1,s1,1
    800035c8:	0496                	slli	s1,s1,0x5
    800035ca:	00015797          	auipc	a5,0x15
    800035ce:	dfe78793          	addi	a5,a5,-514 # 800183c8 <bcache>
    800035d2:	94be                	add	s1,s1,a5
    800035d4:	8526                	mv	a0,s1
    800035d6:	ffffd097          	auipc	ra,0xffffd
    800035da:	71c080e7          	jalr	1820(ra) # 80000cf2 <acquire>
  b->refcnt--;
    800035de:	04892783          	lw	a5,72(s2)
    800035e2:	37fd                	addiw	a5,a5,-1
    800035e4:	04f92423          	sw	a5,72(s2)
  release(&bcache.lock[i]);
    800035e8:	8526                	mv	a0,s1
    800035ea:	ffffd097          	auipc	ra,0xffffd
    800035ee:	7d8080e7          	jalr	2008(ra) # 80000dc2 <release>
    800035f2:	60e2                	ld	ra,24(sp)
    800035f4:	6442                	ld	s0,16(sp)
    800035f6:	64a2                	ld	s1,8(sp)
    800035f8:	6902                	ld	s2,0(sp)
    800035fa:	6105                	addi	sp,sp,32
    800035fc:	8082                	ret

00000000800035fe <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035fe:	1101                	addi	sp,sp,-32
    80003600:	ec06                	sd	ra,24(sp)
    80003602:	e822                	sd	s0,16(sp)
    80003604:	e426                	sd	s1,8(sp)
    80003606:	e04a                	sd	s2,0(sp)
    80003608:	1000                	addi	s0,sp,32
    8000360a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000360c:	00d5d59b          	srliw	a1,a1,0xd
    80003610:	00021797          	auipc	a5,0x21
    80003614:	d0c7a783          	lw	a5,-756(a5) # 8002431c <sb+0x1c>
    80003618:	9dbd                	addw	a1,a1,a5
    8000361a:	00000097          	auipc	ra,0x0
    8000361e:	ba4080e7          	jalr	-1116(ra) # 800031be <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003622:	0074f713          	andi	a4,s1,7
    80003626:	4785                	li	a5,1
    80003628:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000362c:	14ce                	slli	s1,s1,0x33
    8000362e:	90d9                	srli	s1,s1,0x36
    80003630:	00950733          	add	a4,a0,s1
    80003634:	06074703          	lbu	a4,96(a4)
    80003638:	00e7f6b3          	and	a3,a5,a4
    8000363c:	c69d                	beqz	a3,8000366a <bfree+0x6c>
    8000363e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003640:	94aa                	add	s1,s1,a0
    80003642:	fff7c793          	not	a5,a5
    80003646:	8ff9                	and	a5,a5,a4
    80003648:	06f48023          	sb	a5,96(s1)
  log_write(bp);
    8000364c:	00001097          	auipc	ra,0x1
    80003650:	116080e7          	jalr	278(ra) # 80004762 <log_write>
  brelse(bp);
    80003654:	854a                	mv	a0,s2
    80003656:	00000097          	auipc	ra,0x0
    8000365a:	e80080e7          	jalr	-384(ra) # 800034d6 <brelse>
}
    8000365e:	60e2                	ld	ra,24(sp)
    80003660:	6442                	ld	s0,16(sp)
    80003662:	64a2                	ld	s1,8(sp)
    80003664:	6902                	ld	s2,0(sp)
    80003666:	6105                	addi	sp,sp,32
    80003668:	8082                	ret
    panic("freeing free block");
    8000366a:	00005517          	auipc	a0,0x5
    8000366e:	f3e50513          	addi	a0,a0,-194 # 800085a8 <syscalls+0xf0>
    80003672:	ffffd097          	auipc	ra,0xffffd
    80003676:	ede080e7          	jalr	-290(ra) # 80000550 <panic>

000000008000367a <balloc>:
{
    8000367a:	711d                	addi	sp,sp,-96
    8000367c:	ec86                	sd	ra,88(sp)
    8000367e:	e8a2                	sd	s0,80(sp)
    80003680:	e4a6                	sd	s1,72(sp)
    80003682:	e0ca                	sd	s2,64(sp)
    80003684:	fc4e                	sd	s3,56(sp)
    80003686:	f852                	sd	s4,48(sp)
    80003688:	f456                	sd	s5,40(sp)
    8000368a:	f05a                	sd	s6,32(sp)
    8000368c:	ec5e                	sd	s7,24(sp)
    8000368e:	e862                	sd	s8,16(sp)
    80003690:	e466                	sd	s9,8(sp)
    80003692:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003694:	00021797          	auipc	a5,0x21
    80003698:	c707a783          	lw	a5,-912(a5) # 80024304 <sb+0x4>
    8000369c:	cbd1                	beqz	a5,80003730 <balloc+0xb6>
    8000369e:	8baa                	mv	s7,a0
    800036a0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036a2:	00021b17          	auipc	s6,0x21
    800036a6:	c5eb0b13          	addi	s6,s6,-930 # 80024300 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036aa:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036ac:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036ae:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036b0:	6c89                	lui	s9,0x2
    800036b2:	a831                	j	800036ce <balloc+0x54>
    brelse(bp);
    800036b4:	854a                	mv	a0,s2
    800036b6:	00000097          	auipc	ra,0x0
    800036ba:	e20080e7          	jalr	-480(ra) # 800034d6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036be:	015c87bb          	addw	a5,s9,s5
    800036c2:	00078a9b          	sext.w	s5,a5
    800036c6:	004b2703          	lw	a4,4(s6)
    800036ca:	06eaf363          	bgeu	s5,a4,80003730 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800036ce:	41fad79b          	sraiw	a5,s5,0x1f
    800036d2:	0137d79b          	srliw	a5,a5,0x13
    800036d6:	015787bb          	addw	a5,a5,s5
    800036da:	40d7d79b          	sraiw	a5,a5,0xd
    800036de:	01cb2583          	lw	a1,28(s6)
    800036e2:	9dbd                	addw	a1,a1,a5
    800036e4:	855e                	mv	a0,s7
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	ad8080e7          	jalr	-1320(ra) # 800031be <bread>
    800036ee:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036f0:	004b2503          	lw	a0,4(s6)
    800036f4:	000a849b          	sext.w	s1,s5
    800036f8:	8662                	mv	a2,s8
    800036fa:	faa4fde3          	bgeu	s1,a0,800036b4 <balloc+0x3a>
      m = 1 << (bi % 8);
    800036fe:	41f6579b          	sraiw	a5,a2,0x1f
    80003702:	01d7d69b          	srliw	a3,a5,0x1d
    80003706:	00c6873b          	addw	a4,a3,a2
    8000370a:	00777793          	andi	a5,a4,7
    8000370e:	9f95                	subw	a5,a5,a3
    80003710:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003714:	4037571b          	sraiw	a4,a4,0x3
    80003718:	00e906b3          	add	a3,s2,a4
    8000371c:	0606c683          	lbu	a3,96(a3)
    80003720:	00d7f5b3          	and	a1,a5,a3
    80003724:	cd91                	beqz	a1,80003740 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003726:	2605                	addiw	a2,a2,1
    80003728:	2485                	addiw	s1,s1,1
    8000372a:	fd4618e3          	bne	a2,s4,800036fa <balloc+0x80>
    8000372e:	b759                	j	800036b4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003730:	00005517          	auipc	a0,0x5
    80003734:	e9050513          	addi	a0,a0,-368 # 800085c0 <syscalls+0x108>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	e18080e7          	jalr	-488(ra) # 80000550 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003740:	974a                	add	a4,a4,s2
    80003742:	8fd5                	or	a5,a5,a3
    80003744:	06f70023          	sb	a5,96(a4)
        log_write(bp);
    80003748:	854a                	mv	a0,s2
    8000374a:	00001097          	auipc	ra,0x1
    8000374e:	018080e7          	jalr	24(ra) # 80004762 <log_write>
        brelse(bp);
    80003752:	854a                	mv	a0,s2
    80003754:	00000097          	auipc	ra,0x0
    80003758:	d82080e7          	jalr	-638(ra) # 800034d6 <brelse>
  bp = bread(dev, bno);
    8000375c:	85a6                	mv	a1,s1
    8000375e:	855e                	mv	a0,s7
    80003760:	00000097          	auipc	ra,0x0
    80003764:	a5e080e7          	jalr	-1442(ra) # 800031be <bread>
    80003768:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000376a:	40000613          	li	a2,1024
    8000376e:	4581                	li	a1,0
    80003770:	06050513          	addi	a0,a0,96
    80003774:	ffffe097          	auipc	ra,0xffffe
    80003778:	95e080e7          	jalr	-1698(ra) # 800010d2 <memset>
  log_write(bp);
    8000377c:	854a                	mv	a0,s2
    8000377e:	00001097          	auipc	ra,0x1
    80003782:	fe4080e7          	jalr	-28(ra) # 80004762 <log_write>
  brelse(bp);
    80003786:	854a                	mv	a0,s2
    80003788:	00000097          	auipc	ra,0x0
    8000378c:	d4e080e7          	jalr	-690(ra) # 800034d6 <brelse>
}
    80003790:	8526                	mv	a0,s1
    80003792:	60e6                	ld	ra,88(sp)
    80003794:	6446                	ld	s0,80(sp)
    80003796:	64a6                	ld	s1,72(sp)
    80003798:	6906                	ld	s2,64(sp)
    8000379a:	79e2                	ld	s3,56(sp)
    8000379c:	7a42                	ld	s4,48(sp)
    8000379e:	7aa2                	ld	s5,40(sp)
    800037a0:	7b02                	ld	s6,32(sp)
    800037a2:	6be2                	ld	s7,24(sp)
    800037a4:	6c42                	ld	s8,16(sp)
    800037a6:	6ca2                	ld	s9,8(sp)
    800037a8:	6125                	addi	sp,sp,96
    800037aa:	8082                	ret

00000000800037ac <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800037ac:	7179                	addi	sp,sp,-48
    800037ae:	f406                	sd	ra,40(sp)
    800037b0:	f022                	sd	s0,32(sp)
    800037b2:	ec26                	sd	s1,24(sp)
    800037b4:	e84a                	sd	s2,16(sp)
    800037b6:	e44e                	sd	s3,8(sp)
    800037b8:	e052                	sd	s4,0(sp)
    800037ba:	1800                	addi	s0,sp,48
    800037bc:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037be:	47ad                	li	a5,11
    800037c0:	04b7fe63          	bgeu	a5,a1,8000381c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800037c4:	ff45849b          	addiw	s1,a1,-12
    800037c8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037cc:	0ff00793          	li	a5,255
    800037d0:	0ae7e363          	bltu	a5,a4,80003876 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800037d4:	08852583          	lw	a1,136(a0)
    800037d8:	c5ad                	beqz	a1,80003842 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800037da:	00092503          	lw	a0,0(s2)
    800037de:	00000097          	auipc	ra,0x0
    800037e2:	9e0080e7          	jalr	-1568(ra) # 800031be <bread>
    800037e6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037e8:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    800037ec:	02049593          	slli	a1,s1,0x20
    800037f0:	9181                	srli	a1,a1,0x20
    800037f2:	058a                	slli	a1,a1,0x2
    800037f4:	00b784b3          	add	s1,a5,a1
    800037f8:	0004a983          	lw	s3,0(s1)
    800037fc:	04098d63          	beqz	s3,80003856 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003800:	8552                	mv	a0,s4
    80003802:	00000097          	auipc	ra,0x0
    80003806:	cd4080e7          	jalr	-812(ra) # 800034d6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000380a:	854e                	mv	a0,s3
    8000380c:	70a2                	ld	ra,40(sp)
    8000380e:	7402                	ld	s0,32(sp)
    80003810:	64e2                	ld	s1,24(sp)
    80003812:	6942                	ld	s2,16(sp)
    80003814:	69a2                	ld	s3,8(sp)
    80003816:	6a02                	ld	s4,0(sp)
    80003818:	6145                	addi	sp,sp,48
    8000381a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000381c:	02059493          	slli	s1,a1,0x20
    80003820:	9081                	srli	s1,s1,0x20
    80003822:	048a                	slli	s1,s1,0x2
    80003824:	94aa                	add	s1,s1,a0
    80003826:	0584a983          	lw	s3,88(s1)
    8000382a:	fe0990e3          	bnez	s3,8000380a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000382e:	4108                	lw	a0,0(a0)
    80003830:	00000097          	auipc	ra,0x0
    80003834:	e4a080e7          	jalr	-438(ra) # 8000367a <balloc>
    80003838:	0005099b          	sext.w	s3,a0
    8000383c:	0534ac23          	sw	s3,88(s1)
    80003840:	b7e9                	j	8000380a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003842:	4108                	lw	a0,0(a0)
    80003844:	00000097          	auipc	ra,0x0
    80003848:	e36080e7          	jalr	-458(ra) # 8000367a <balloc>
    8000384c:	0005059b          	sext.w	a1,a0
    80003850:	08b92423          	sw	a1,136(s2)
    80003854:	b759                	j	800037da <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003856:	00092503          	lw	a0,0(s2)
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	e20080e7          	jalr	-480(ra) # 8000367a <balloc>
    80003862:	0005099b          	sext.w	s3,a0
    80003866:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000386a:	8552                	mv	a0,s4
    8000386c:	00001097          	auipc	ra,0x1
    80003870:	ef6080e7          	jalr	-266(ra) # 80004762 <log_write>
    80003874:	b771                	j	80003800 <bmap+0x54>
  panic("bmap: out of range");
    80003876:	00005517          	auipc	a0,0x5
    8000387a:	d6250513          	addi	a0,a0,-670 # 800085d8 <syscalls+0x120>
    8000387e:	ffffd097          	auipc	ra,0xffffd
    80003882:	cd2080e7          	jalr	-814(ra) # 80000550 <panic>

0000000080003886 <iget>:
{
    80003886:	7179                	addi	sp,sp,-48
    80003888:	f406                	sd	ra,40(sp)
    8000388a:	f022                	sd	s0,32(sp)
    8000388c:	ec26                	sd	s1,24(sp)
    8000388e:	e84a                	sd	s2,16(sp)
    80003890:	e44e                	sd	s3,8(sp)
    80003892:	e052                	sd	s4,0(sp)
    80003894:	1800                	addi	s0,sp,48
    80003896:	89aa                	mv	s3,a0
    80003898:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000389a:	00021517          	auipc	a0,0x21
    8000389e:	a8650513          	addi	a0,a0,-1402 # 80024320 <icache>
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	450080e7          	jalr	1104(ra) # 80000cf2 <acquire>
  empty = 0;
    800038aa:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800038ac:	00021497          	auipc	s1,0x21
    800038b0:	a9448493          	addi	s1,s1,-1388 # 80024340 <icache+0x20>
    800038b4:	00022697          	auipc	a3,0x22
    800038b8:	6ac68693          	addi	a3,a3,1708 # 80025f60 <log>
    800038bc:	a039                	j	800038ca <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038be:	02090b63          	beqz	s2,800038f4 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800038c2:	09048493          	addi	s1,s1,144
    800038c6:	02d48a63          	beq	s1,a3,800038fa <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038ca:	449c                	lw	a5,8(s1)
    800038cc:	fef059e3          	blez	a5,800038be <iget+0x38>
    800038d0:	4098                	lw	a4,0(s1)
    800038d2:	ff3716e3          	bne	a4,s3,800038be <iget+0x38>
    800038d6:	40d8                	lw	a4,4(s1)
    800038d8:	ff4713e3          	bne	a4,s4,800038be <iget+0x38>
      ip->ref++;
    800038dc:	2785                	addiw	a5,a5,1
    800038de:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800038e0:	00021517          	auipc	a0,0x21
    800038e4:	a4050513          	addi	a0,a0,-1472 # 80024320 <icache>
    800038e8:	ffffd097          	auipc	ra,0xffffd
    800038ec:	4da080e7          	jalr	1242(ra) # 80000dc2 <release>
      return ip;
    800038f0:	8926                	mv	s2,s1
    800038f2:	a03d                	j	80003920 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038f4:	f7f9                	bnez	a5,800038c2 <iget+0x3c>
    800038f6:	8926                	mv	s2,s1
    800038f8:	b7e9                	j	800038c2 <iget+0x3c>
  if(empty == 0)
    800038fa:	02090c63          	beqz	s2,80003932 <iget+0xac>
  ip->dev = dev;
    800038fe:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003902:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003906:	4785                	li	a5,1
    80003908:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000390c:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    80003910:	00021517          	auipc	a0,0x21
    80003914:	a1050513          	addi	a0,a0,-1520 # 80024320 <icache>
    80003918:	ffffd097          	auipc	ra,0xffffd
    8000391c:	4aa080e7          	jalr	1194(ra) # 80000dc2 <release>
}
    80003920:	854a                	mv	a0,s2
    80003922:	70a2                	ld	ra,40(sp)
    80003924:	7402                	ld	s0,32(sp)
    80003926:	64e2                	ld	s1,24(sp)
    80003928:	6942                	ld	s2,16(sp)
    8000392a:	69a2                	ld	s3,8(sp)
    8000392c:	6a02                	ld	s4,0(sp)
    8000392e:	6145                	addi	sp,sp,48
    80003930:	8082                	ret
    panic("iget: no inodes");
    80003932:	00005517          	auipc	a0,0x5
    80003936:	cbe50513          	addi	a0,a0,-834 # 800085f0 <syscalls+0x138>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	c16080e7          	jalr	-1002(ra) # 80000550 <panic>

0000000080003942 <fsinit>:
fsinit(int dev) {
    80003942:	7179                	addi	sp,sp,-48
    80003944:	f406                	sd	ra,40(sp)
    80003946:	f022                	sd	s0,32(sp)
    80003948:	ec26                	sd	s1,24(sp)
    8000394a:	e84a                	sd	s2,16(sp)
    8000394c:	e44e                	sd	s3,8(sp)
    8000394e:	1800                	addi	s0,sp,48
    80003950:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003952:	4585                	li	a1,1
    80003954:	00000097          	auipc	ra,0x0
    80003958:	86a080e7          	jalr	-1942(ra) # 800031be <bread>
    8000395c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000395e:	00021997          	auipc	s3,0x21
    80003962:	9a298993          	addi	s3,s3,-1630 # 80024300 <sb>
    80003966:	02000613          	li	a2,32
    8000396a:	06050593          	addi	a1,a0,96
    8000396e:	854e                	mv	a0,s3
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	7c2080e7          	jalr	1986(ra) # 80001132 <memmove>
  brelse(bp);
    80003978:	8526                	mv	a0,s1
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	b5c080e7          	jalr	-1188(ra) # 800034d6 <brelse>
  if(sb.magic != FSMAGIC)
    80003982:	0009a703          	lw	a4,0(s3)
    80003986:	102037b7          	lui	a5,0x10203
    8000398a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000398e:	02f71263          	bne	a4,a5,800039b2 <fsinit+0x70>
  initlog(dev, &sb);
    80003992:	00021597          	auipc	a1,0x21
    80003996:	96e58593          	addi	a1,a1,-1682 # 80024300 <sb>
    8000399a:	854a                	mv	a0,s2
    8000399c:	00001097          	auipc	ra,0x1
    800039a0:	b4a080e7          	jalr	-1206(ra) # 800044e6 <initlog>
}
    800039a4:	70a2                	ld	ra,40(sp)
    800039a6:	7402                	ld	s0,32(sp)
    800039a8:	64e2                	ld	s1,24(sp)
    800039aa:	6942                	ld	s2,16(sp)
    800039ac:	69a2                	ld	s3,8(sp)
    800039ae:	6145                	addi	sp,sp,48
    800039b0:	8082                	ret
    panic("invalid file system");
    800039b2:	00005517          	auipc	a0,0x5
    800039b6:	c4e50513          	addi	a0,a0,-946 # 80008600 <syscalls+0x148>
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	b96080e7          	jalr	-1130(ra) # 80000550 <panic>

00000000800039c2 <iinit>:
{
    800039c2:	7179                	addi	sp,sp,-48
    800039c4:	f406                	sd	ra,40(sp)
    800039c6:	f022                	sd	s0,32(sp)
    800039c8:	ec26                	sd	s1,24(sp)
    800039ca:	e84a                	sd	s2,16(sp)
    800039cc:	e44e                	sd	s3,8(sp)
    800039ce:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800039d0:	00005597          	auipc	a1,0x5
    800039d4:	c4858593          	addi	a1,a1,-952 # 80008618 <syscalls+0x160>
    800039d8:	00021517          	auipc	a0,0x21
    800039dc:	94850513          	addi	a0,a0,-1720 # 80024320 <icache>
    800039e0:	ffffd097          	auipc	ra,0xffffd
    800039e4:	48e080e7          	jalr	1166(ra) # 80000e6e <initlock>
  for(i = 0; i < NINODE; i++) {
    800039e8:	00021497          	auipc	s1,0x21
    800039ec:	96848493          	addi	s1,s1,-1688 # 80024350 <icache+0x30>
    800039f0:	00022997          	auipc	s3,0x22
    800039f4:	58098993          	addi	s3,s3,1408 # 80025f70 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800039f8:	00005917          	auipc	s2,0x5
    800039fc:	c2890913          	addi	s2,s2,-984 # 80008620 <syscalls+0x168>
    80003a00:	85ca                	mv	a1,s2
    80003a02:	8526                	mv	a0,s1
    80003a04:	00001097          	auipc	ra,0x1
    80003a08:	e4c080e7          	jalr	-436(ra) # 80004850 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a0c:	09048493          	addi	s1,s1,144
    80003a10:	ff3498e3          	bne	s1,s3,80003a00 <iinit+0x3e>
}
    80003a14:	70a2                	ld	ra,40(sp)
    80003a16:	7402                	ld	s0,32(sp)
    80003a18:	64e2                	ld	s1,24(sp)
    80003a1a:	6942                	ld	s2,16(sp)
    80003a1c:	69a2                	ld	s3,8(sp)
    80003a1e:	6145                	addi	sp,sp,48
    80003a20:	8082                	ret

0000000080003a22 <ialloc>:
{
    80003a22:	715d                	addi	sp,sp,-80
    80003a24:	e486                	sd	ra,72(sp)
    80003a26:	e0a2                	sd	s0,64(sp)
    80003a28:	fc26                	sd	s1,56(sp)
    80003a2a:	f84a                	sd	s2,48(sp)
    80003a2c:	f44e                	sd	s3,40(sp)
    80003a2e:	f052                	sd	s4,32(sp)
    80003a30:	ec56                	sd	s5,24(sp)
    80003a32:	e85a                	sd	s6,16(sp)
    80003a34:	e45e                	sd	s7,8(sp)
    80003a36:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a38:	00021717          	auipc	a4,0x21
    80003a3c:	8d472703          	lw	a4,-1836(a4) # 8002430c <sb+0xc>
    80003a40:	4785                	li	a5,1
    80003a42:	04e7fa63          	bgeu	a5,a4,80003a96 <ialloc+0x74>
    80003a46:	8aaa                	mv	s5,a0
    80003a48:	8bae                	mv	s7,a1
    80003a4a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a4c:	00021a17          	auipc	s4,0x21
    80003a50:	8b4a0a13          	addi	s4,s4,-1868 # 80024300 <sb>
    80003a54:	00048b1b          	sext.w	s6,s1
    80003a58:	0044d593          	srli	a1,s1,0x4
    80003a5c:	018a2783          	lw	a5,24(s4)
    80003a60:	9dbd                	addw	a1,a1,a5
    80003a62:	8556                	mv	a0,s5
    80003a64:	fffff097          	auipc	ra,0xfffff
    80003a68:	75a080e7          	jalr	1882(ra) # 800031be <bread>
    80003a6c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a6e:	06050993          	addi	s3,a0,96
    80003a72:	00f4f793          	andi	a5,s1,15
    80003a76:	079a                	slli	a5,a5,0x6
    80003a78:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a7a:	00099783          	lh	a5,0(s3)
    80003a7e:	c785                	beqz	a5,80003aa6 <ialloc+0x84>
    brelse(bp);
    80003a80:	00000097          	auipc	ra,0x0
    80003a84:	a56080e7          	jalr	-1450(ra) # 800034d6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a88:	0485                	addi	s1,s1,1
    80003a8a:	00ca2703          	lw	a4,12(s4)
    80003a8e:	0004879b          	sext.w	a5,s1
    80003a92:	fce7e1e3          	bltu	a5,a4,80003a54 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a96:	00005517          	auipc	a0,0x5
    80003a9a:	b9250513          	addi	a0,a0,-1134 # 80008628 <syscalls+0x170>
    80003a9e:	ffffd097          	auipc	ra,0xffffd
    80003aa2:	ab2080e7          	jalr	-1358(ra) # 80000550 <panic>
      memset(dip, 0, sizeof(*dip));
    80003aa6:	04000613          	li	a2,64
    80003aaa:	4581                	li	a1,0
    80003aac:	854e                	mv	a0,s3
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	624080e7          	jalr	1572(ra) # 800010d2 <memset>
      dip->type = type;
    80003ab6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003aba:	854a                	mv	a0,s2
    80003abc:	00001097          	auipc	ra,0x1
    80003ac0:	ca6080e7          	jalr	-858(ra) # 80004762 <log_write>
      brelse(bp);
    80003ac4:	854a                	mv	a0,s2
    80003ac6:	00000097          	auipc	ra,0x0
    80003aca:	a10080e7          	jalr	-1520(ra) # 800034d6 <brelse>
      return iget(dev, inum);
    80003ace:	85da                	mv	a1,s6
    80003ad0:	8556                	mv	a0,s5
    80003ad2:	00000097          	auipc	ra,0x0
    80003ad6:	db4080e7          	jalr	-588(ra) # 80003886 <iget>
}
    80003ada:	60a6                	ld	ra,72(sp)
    80003adc:	6406                	ld	s0,64(sp)
    80003ade:	74e2                	ld	s1,56(sp)
    80003ae0:	7942                	ld	s2,48(sp)
    80003ae2:	79a2                	ld	s3,40(sp)
    80003ae4:	7a02                	ld	s4,32(sp)
    80003ae6:	6ae2                	ld	s5,24(sp)
    80003ae8:	6b42                	ld	s6,16(sp)
    80003aea:	6ba2                	ld	s7,8(sp)
    80003aec:	6161                	addi	sp,sp,80
    80003aee:	8082                	ret

0000000080003af0 <iupdate>:
{
    80003af0:	1101                	addi	sp,sp,-32
    80003af2:	ec06                	sd	ra,24(sp)
    80003af4:	e822                	sd	s0,16(sp)
    80003af6:	e426                	sd	s1,8(sp)
    80003af8:	e04a                	sd	s2,0(sp)
    80003afa:	1000                	addi	s0,sp,32
    80003afc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003afe:	415c                	lw	a5,4(a0)
    80003b00:	0047d79b          	srliw	a5,a5,0x4
    80003b04:	00021597          	auipc	a1,0x21
    80003b08:	8145a583          	lw	a1,-2028(a1) # 80024318 <sb+0x18>
    80003b0c:	9dbd                	addw	a1,a1,a5
    80003b0e:	4108                	lw	a0,0(a0)
    80003b10:	fffff097          	auipc	ra,0xfffff
    80003b14:	6ae080e7          	jalr	1710(ra) # 800031be <bread>
    80003b18:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b1a:	06050793          	addi	a5,a0,96
    80003b1e:	40c8                	lw	a0,4(s1)
    80003b20:	893d                	andi	a0,a0,15
    80003b22:	051a                	slli	a0,a0,0x6
    80003b24:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b26:	04c49703          	lh	a4,76(s1)
    80003b2a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b2e:	04e49703          	lh	a4,78(s1)
    80003b32:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b36:	05049703          	lh	a4,80(s1)
    80003b3a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b3e:	05249703          	lh	a4,82(s1)
    80003b42:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b46:	48f8                	lw	a4,84(s1)
    80003b48:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b4a:	03400613          	li	a2,52
    80003b4e:	05848593          	addi	a1,s1,88
    80003b52:	0531                	addi	a0,a0,12
    80003b54:	ffffd097          	auipc	ra,0xffffd
    80003b58:	5de080e7          	jalr	1502(ra) # 80001132 <memmove>
  log_write(bp);
    80003b5c:	854a                	mv	a0,s2
    80003b5e:	00001097          	auipc	ra,0x1
    80003b62:	c04080e7          	jalr	-1020(ra) # 80004762 <log_write>
  brelse(bp);
    80003b66:	854a                	mv	a0,s2
    80003b68:	00000097          	auipc	ra,0x0
    80003b6c:	96e080e7          	jalr	-1682(ra) # 800034d6 <brelse>
}
    80003b70:	60e2                	ld	ra,24(sp)
    80003b72:	6442                	ld	s0,16(sp)
    80003b74:	64a2                	ld	s1,8(sp)
    80003b76:	6902                	ld	s2,0(sp)
    80003b78:	6105                	addi	sp,sp,32
    80003b7a:	8082                	ret

0000000080003b7c <idup>:
{
    80003b7c:	1101                	addi	sp,sp,-32
    80003b7e:	ec06                	sd	ra,24(sp)
    80003b80:	e822                	sd	s0,16(sp)
    80003b82:	e426                	sd	s1,8(sp)
    80003b84:	1000                	addi	s0,sp,32
    80003b86:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b88:	00020517          	auipc	a0,0x20
    80003b8c:	79850513          	addi	a0,a0,1944 # 80024320 <icache>
    80003b90:	ffffd097          	auipc	ra,0xffffd
    80003b94:	162080e7          	jalr	354(ra) # 80000cf2 <acquire>
  ip->ref++;
    80003b98:	449c                	lw	a5,8(s1)
    80003b9a:	2785                	addiw	a5,a5,1
    80003b9c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b9e:	00020517          	auipc	a0,0x20
    80003ba2:	78250513          	addi	a0,a0,1922 # 80024320 <icache>
    80003ba6:	ffffd097          	auipc	ra,0xffffd
    80003baa:	21c080e7          	jalr	540(ra) # 80000dc2 <release>
}
    80003bae:	8526                	mv	a0,s1
    80003bb0:	60e2                	ld	ra,24(sp)
    80003bb2:	6442                	ld	s0,16(sp)
    80003bb4:	64a2                	ld	s1,8(sp)
    80003bb6:	6105                	addi	sp,sp,32
    80003bb8:	8082                	ret

0000000080003bba <ilock>:
{
    80003bba:	1101                	addi	sp,sp,-32
    80003bbc:	ec06                	sd	ra,24(sp)
    80003bbe:	e822                	sd	s0,16(sp)
    80003bc0:	e426                	sd	s1,8(sp)
    80003bc2:	e04a                	sd	s2,0(sp)
    80003bc4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bc6:	c115                	beqz	a0,80003bea <ilock+0x30>
    80003bc8:	84aa                	mv	s1,a0
    80003bca:	451c                	lw	a5,8(a0)
    80003bcc:	00f05f63          	blez	a5,80003bea <ilock+0x30>
  acquiresleep(&ip->lock);
    80003bd0:	0541                	addi	a0,a0,16
    80003bd2:	00001097          	auipc	ra,0x1
    80003bd6:	cb8080e7          	jalr	-840(ra) # 8000488a <acquiresleep>
  if(ip->valid == 0){
    80003bda:	44bc                	lw	a5,72(s1)
    80003bdc:	cf99                	beqz	a5,80003bfa <ilock+0x40>
}
    80003bde:	60e2                	ld	ra,24(sp)
    80003be0:	6442                	ld	s0,16(sp)
    80003be2:	64a2                	ld	s1,8(sp)
    80003be4:	6902                	ld	s2,0(sp)
    80003be6:	6105                	addi	sp,sp,32
    80003be8:	8082                	ret
    panic("ilock");
    80003bea:	00005517          	auipc	a0,0x5
    80003bee:	a5650513          	addi	a0,a0,-1450 # 80008640 <syscalls+0x188>
    80003bf2:	ffffd097          	auipc	ra,0xffffd
    80003bf6:	95e080e7          	jalr	-1698(ra) # 80000550 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bfa:	40dc                	lw	a5,4(s1)
    80003bfc:	0047d79b          	srliw	a5,a5,0x4
    80003c00:	00020597          	auipc	a1,0x20
    80003c04:	7185a583          	lw	a1,1816(a1) # 80024318 <sb+0x18>
    80003c08:	9dbd                	addw	a1,a1,a5
    80003c0a:	4088                	lw	a0,0(s1)
    80003c0c:	fffff097          	auipc	ra,0xfffff
    80003c10:	5b2080e7          	jalr	1458(ra) # 800031be <bread>
    80003c14:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c16:	06050593          	addi	a1,a0,96
    80003c1a:	40dc                	lw	a5,4(s1)
    80003c1c:	8bbd                	andi	a5,a5,15
    80003c1e:	079a                	slli	a5,a5,0x6
    80003c20:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c22:	00059783          	lh	a5,0(a1)
    80003c26:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    80003c2a:	00259783          	lh	a5,2(a1)
    80003c2e:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    80003c32:	00459783          	lh	a5,4(a1)
    80003c36:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    80003c3a:	00659783          	lh	a5,6(a1)
    80003c3e:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    80003c42:	459c                	lw	a5,8(a1)
    80003c44:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c46:	03400613          	li	a2,52
    80003c4a:	05b1                	addi	a1,a1,12
    80003c4c:	05848513          	addi	a0,s1,88
    80003c50:	ffffd097          	auipc	ra,0xffffd
    80003c54:	4e2080e7          	jalr	1250(ra) # 80001132 <memmove>
    brelse(bp);
    80003c58:	854a                	mv	a0,s2
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	87c080e7          	jalr	-1924(ra) # 800034d6 <brelse>
    ip->valid = 1;
    80003c62:	4785                	li	a5,1
    80003c64:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    80003c66:	04c49783          	lh	a5,76(s1)
    80003c6a:	fbb5                	bnez	a5,80003bde <ilock+0x24>
      panic("ilock: no type");
    80003c6c:	00005517          	auipc	a0,0x5
    80003c70:	9dc50513          	addi	a0,a0,-1572 # 80008648 <syscalls+0x190>
    80003c74:	ffffd097          	auipc	ra,0xffffd
    80003c78:	8dc080e7          	jalr	-1828(ra) # 80000550 <panic>

0000000080003c7c <iunlock>:
{
    80003c7c:	1101                	addi	sp,sp,-32
    80003c7e:	ec06                	sd	ra,24(sp)
    80003c80:	e822                	sd	s0,16(sp)
    80003c82:	e426                	sd	s1,8(sp)
    80003c84:	e04a                	sd	s2,0(sp)
    80003c86:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c88:	c905                	beqz	a0,80003cb8 <iunlock+0x3c>
    80003c8a:	84aa                	mv	s1,a0
    80003c8c:	01050913          	addi	s2,a0,16
    80003c90:	854a                	mv	a0,s2
    80003c92:	00001097          	auipc	ra,0x1
    80003c96:	c92080e7          	jalr	-878(ra) # 80004924 <holdingsleep>
    80003c9a:	cd19                	beqz	a0,80003cb8 <iunlock+0x3c>
    80003c9c:	449c                	lw	a5,8(s1)
    80003c9e:	00f05d63          	blez	a5,80003cb8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ca2:	854a                	mv	a0,s2
    80003ca4:	00001097          	auipc	ra,0x1
    80003ca8:	c3c080e7          	jalr	-964(ra) # 800048e0 <releasesleep>
}
    80003cac:	60e2                	ld	ra,24(sp)
    80003cae:	6442                	ld	s0,16(sp)
    80003cb0:	64a2                	ld	s1,8(sp)
    80003cb2:	6902                	ld	s2,0(sp)
    80003cb4:	6105                	addi	sp,sp,32
    80003cb6:	8082                	ret
    panic("iunlock");
    80003cb8:	00005517          	auipc	a0,0x5
    80003cbc:	9a050513          	addi	a0,a0,-1632 # 80008658 <syscalls+0x1a0>
    80003cc0:	ffffd097          	auipc	ra,0xffffd
    80003cc4:	890080e7          	jalr	-1904(ra) # 80000550 <panic>

0000000080003cc8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003cc8:	7179                	addi	sp,sp,-48
    80003cca:	f406                	sd	ra,40(sp)
    80003ccc:	f022                	sd	s0,32(sp)
    80003cce:	ec26                	sd	s1,24(sp)
    80003cd0:	e84a                	sd	s2,16(sp)
    80003cd2:	e44e                	sd	s3,8(sp)
    80003cd4:	e052                	sd	s4,0(sp)
    80003cd6:	1800                	addi	s0,sp,48
    80003cd8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cda:	05850493          	addi	s1,a0,88
    80003cde:	08850913          	addi	s2,a0,136
    80003ce2:	a021                	j	80003cea <itrunc+0x22>
    80003ce4:	0491                	addi	s1,s1,4
    80003ce6:	01248d63          	beq	s1,s2,80003d00 <itrunc+0x38>
    if(ip->addrs[i]){
    80003cea:	408c                	lw	a1,0(s1)
    80003cec:	dde5                	beqz	a1,80003ce4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cee:	0009a503          	lw	a0,0(s3)
    80003cf2:	00000097          	auipc	ra,0x0
    80003cf6:	90c080e7          	jalr	-1780(ra) # 800035fe <bfree>
      ip->addrs[i] = 0;
    80003cfa:	0004a023          	sw	zero,0(s1)
    80003cfe:	b7dd                	j	80003ce4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d00:	0889a583          	lw	a1,136(s3)
    80003d04:	e185                	bnez	a1,80003d24 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d06:	0409aa23          	sw	zero,84(s3)
  iupdate(ip);
    80003d0a:	854e                	mv	a0,s3
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	de4080e7          	jalr	-540(ra) # 80003af0 <iupdate>
}
    80003d14:	70a2                	ld	ra,40(sp)
    80003d16:	7402                	ld	s0,32(sp)
    80003d18:	64e2                	ld	s1,24(sp)
    80003d1a:	6942                	ld	s2,16(sp)
    80003d1c:	69a2                	ld	s3,8(sp)
    80003d1e:	6a02                	ld	s4,0(sp)
    80003d20:	6145                	addi	sp,sp,48
    80003d22:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d24:	0009a503          	lw	a0,0(s3)
    80003d28:	fffff097          	auipc	ra,0xfffff
    80003d2c:	496080e7          	jalr	1174(ra) # 800031be <bread>
    80003d30:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d32:	06050493          	addi	s1,a0,96
    80003d36:	46050913          	addi	s2,a0,1120
    80003d3a:	a811                	j	80003d4e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d3c:	0009a503          	lw	a0,0(s3)
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	8be080e7          	jalr	-1858(ra) # 800035fe <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d48:	0491                	addi	s1,s1,4
    80003d4a:	01248563          	beq	s1,s2,80003d54 <itrunc+0x8c>
      if(a[j])
    80003d4e:	408c                	lw	a1,0(s1)
    80003d50:	dde5                	beqz	a1,80003d48 <itrunc+0x80>
    80003d52:	b7ed                	j	80003d3c <itrunc+0x74>
    brelse(bp);
    80003d54:	8552                	mv	a0,s4
    80003d56:	fffff097          	auipc	ra,0xfffff
    80003d5a:	780080e7          	jalr	1920(ra) # 800034d6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d5e:	0889a583          	lw	a1,136(s3)
    80003d62:	0009a503          	lw	a0,0(s3)
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	898080e7          	jalr	-1896(ra) # 800035fe <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d6e:	0809a423          	sw	zero,136(s3)
    80003d72:	bf51                	j	80003d06 <itrunc+0x3e>

0000000080003d74 <iput>:
{
    80003d74:	1101                	addi	sp,sp,-32
    80003d76:	ec06                	sd	ra,24(sp)
    80003d78:	e822                	sd	s0,16(sp)
    80003d7a:	e426                	sd	s1,8(sp)
    80003d7c:	e04a                	sd	s2,0(sp)
    80003d7e:	1000                	addi	s0,sp,32
    80003d80:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003d82:	00020517          	auipc	a0,0x20
    80003d86:	59e50513          	addi	a0,a0,1438 # 80024320 <icache>
    80003d8a:	ffffd097          	auipc	ra,0xffffd
    80003d8e:	f68080e7          	jalr	-152(ra) # 80000cf2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d92:	4498                	lw	a4,8(s1)
    80003d94:	4785                	li	a5,1
    80003d96:	02f70363          	beq	a4,a5,80003dbc <iput+0x48>
  ip->ref--;
    80003d9a:	449c                	lw	a5,8(s1)
    80003d9c:	37fd                	addiw	a5,a5,-1
    80003d9e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003da0:	00020517          	auipc	a0,0x20
    80003da4:	58050513          	addi	a0,a0,1408 # 80024320 <icache>
    80003da8:	ffffd097          	auipc	ra,0xffffd
    80003dac:	01a080e7          	jalr	26(ra) # 80000dc2 <release>
}
    80003db0:	60e2                	ld	ra,24(sp)
    80003db2:	6442                	ld	s0,16(sp)
    80003db4:	64a2                	ld	s1,8(sp)
    80003db6:	6902                	ld	s2,0(sp)
    80003db8:	6105                	addi	sp,sp,32
    80003dba:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dbc:	44bc                	lw	a5,72(s1)
    80003dbe:	dff1                	beqz	a5,80003d9a <iput+0x26>
    80003dc0:	05249783          	lh	a5,82(s1)
    80003dc4:	fbf9                	bnez	a5,80003d9a <iput+0x26>
    acquiresleep(&ip->lock);
    80003dc6:	01048913          	addi	s2,s1,16
    80003dca:	854a                	mv	a0,s2
    80003dcc:	00001097          	auipc	ra,0x1
    80003dd0:	abe080e7          	jalr	-1346(ra) # 8000488a <acquiresleep>
    release(&icache.lock);
    80003dd4:	00020517          	auipc	a0,0x20
    80003dd8:	54c50513          	addi	a0,a0,1356 # 80024320 <icache>
    80003ddc:	ffffd097          	auipc	ra,0xffffd
    80003de0:	fe6080e7          	jalr	-26(ra) # 80000dc2 <release>
    itrunc(ip);
    80003de4:	8526                	mv	a0,s1
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	ee2080e7          	jalr	-286(ra) # 80003cc8 <itrunc>
    ip->type = 0;
    80003dee:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    80003df2:	8526                	mv	a0,s1
    80003df4:	00000097          	auipc	ra,0x0
    80003df8:	cfc080e7          	jalr	-772(ra) # 80003af0 <iupdate>
    ip->valid = 0;
    80003dfc:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003e00:	854a                	mv	a0,s2
    80003e02:	00001097          	auipc	ra,0x1
    80003e06:	ade080e7          	jalr	-1314(ra) # 800048e0 <releasesleep>
    acquire(&icache.lock);
    80003e0a:	00020517          	auipc	a0,0x20
    80003e0e:	51650513          	addi	a0,a0,1302 # 80024320 <icache>
    80003e12:	ffffd097          	auipc	ra,0xffffd
    80003e16:	ee0080e7          	jalr	-288(ra) # 80000cf2 <acquire>
    80003e1a:	b741                	j	80003d9a <iput+0x26>

0000000080003e1c <iunlockput>:
{
    80003e1c:	1101                	addi	sp,sp,-32
    80003e1e:	ec06                	sd	ra,24(sp)
    80003e20:	e822                	sd	s0,16(sp)
    80003e22:	e426                	sd	s1,8(sp)
    80003e24:	1000                	addi	s0,sp,32
    80003e26:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	e54080e7          	jalr	-428(ra) # 80003c7c <iunlock>
  iput(ip);
    80003e30:	8526                	mv	a0,s1
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	f42080e7          	jalr	-190(ra) # 80003d74 <iput>
}
    80003e3a:	60e2                	ld	ra,24(sp)
    80003e3c:	6442                	ld	s0,16(sp)
    80003e3e:	64a2                	ld	s1,8(sp)
    80003e40:	6105                	addi	sp,sp,32
    80003e42:	8082                	ret

0000000080003e44 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e44:	1141                	addi	sp,sp,-16
    80003e46:	e422                	sd	s0,8(sp)
    80003e48:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e4a:	411c                	lw	a5,0(a0)
    80003e4c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e4e:	415c                	lw	a5,4(a0)
    80003e50:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e52:	04c51783          	lh	a5,76(a0)
    80003e56:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e5a:	05251783          	lh	a5,82(a0)
    80003e5e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e62:	05456783          	lwu	a5,84(a0)
    80003e66:	e99c                	sd	a5,16(a1)
}
    80003e68:	6422                	ld	s0,8(sp)
    80003e6a:	0141                	addi	sp,sp,16
    80003e6c:	8082                	ret

0000000080003e6e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e6e:	497c                	lw	a5,84(a0)
    80003e70:	0ed7e963          	bltu	a5,a3,80003f62 <readi+0xf4>
{
    80003e74:	7159                	addi	sp,sp,-112
    80003e76:	f486                	sd	ra,104(sp)
    80003e78:	f0a2                	sd	s0,96(sp)
    80003e7a:	eca6                	sd	s1,88(sp)
    80003e7c:	e8ca                	sd	s2,80(sp)
    80003e7e:	e4ce                	sd	s3,72(sp)
    80003e80:	e0d2                	sd	s4,64(sp)
    80003e82:	fc56                	sd	s5,56(sp)
    80003e84:	f85a                	sd	s6,48(sp)
    80003e86:	f45e                	sd	s7,40(sp)
    80003e88:	f062                	sd	s8,32(sp)
    80003e8a:	ec66                	sd	s9,24(sp)
    80003e8c:	e86a                	sd	s10,16(sp)
    80003e8e:	e46e                	sd	s11,8(sp)
    80003e90:	1880                	addi	s0,sp,112
    80003e92:	8baa                	mv	s7,a0
    80003e94:	8c2e                	mv	s8,a1
    80003e96:	8ab2                	mv	s5,a2
    80003e98:	84b6                	mv	s1,a3
    80003e9a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e9c:	9f35                	addw	a4,a4,a3
    return 0;
    80003e9e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ea0:	0ad76063          	bltu	a4,a3,80003f40 <readi+0xd2>
  if(off + n > ip->size)
    80003ea4:	00e7f463          	bgeu	a5,a4,80003eac <readi+0x3e>
    n = ip->size - off;
    80003ea8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eac:	0a0b0963          	beqz	s6,80003f5e <readi+0xf0>
    80003eb0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eb2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003eb6:	5cfd                	li	s9,-1
    80003eb8:	a82d                	j	80003ef2 <readi+0x84>
    80003eba:	020a1d93          	slli	s11,s4,0x20
    80003ebe:	020ddd93          	srli	s11,s11,0x20
    80003ec2:	06090613          	addi	a2,s2,96
    80003ec6:	86ee                	mv	a3,s11
    80003ec8:	963a                	add	a2,a2,a4
    80003eca:	85d6                	mv	a1,s5
    80003ecc:	8562                	mv	a0,s8
    80003ece:	fffff097          	auipc	ra,0xfffff
    80003ed2:	8de080e7          	jalr	-1826(ra) # 800027ac <either_copyout>
    80003ed6:	05950d63          	beq	a0,s9,80003f30 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003eda:	854a                	mv	a0,s2
    80003edc:	fffff097          	auipc	ra,0xfffff
    80003ee0:	5fa080e7          	jalr	1530(ra) # 800034d6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ee4:	013a09bb          	addw	s3,s4,s3
    80003ee8:	009a04bb          	addw	s1,s4,s1
    80003eec:	9aee                	add	s5,s5,s11
    80003eee:	0569f763          	bgeu	s3,s6,80003f3c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ef2:	000ba903          	lw	s2,0(s7)
    80003ef6:	00a4d59b          	srliw	a1,s1,0xa
    80003efa:	855e                	mv	a0,s7
    80003efc:	00000097          	auipc	ra,0x0
    80003f00:	8b0080e7          	jalr	-1872(ra) # 800037ac <bmap>
    80003f04:	0005059b          	sext.w	a1,a0
    80003f08:	854a                	mv	a0,s2
    80003f0a:	fffff097          	auipc	ra,0xfffff
    80003f0e:	2b4080e7          	jalr	692(ra) # 800031be <bread>
    80003f12:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f14:	3ff4f713          	andi	a4,s1,1023
    80003f18:	40ed07bb          	subw	a5,s10,a4
    80003f1c:	413b06bb          	subw	a3,s6,s3
    80003f20:	8a3e                	mv	s4,a5
    80003f22:	2781                	sext.w	a5,a5
    80003f24:	0006861b          	sext.w	a2,a3
    80003f28:	f8f679e3          	bgeu	a2,a5,80003eba <readi+0x4c>
    80003f2c:	8a36                	mv	s4,a3
    80003f2e:	b771                	j	80003eba <readi+0x4c>
      brelse(bp);
    80003f30:	854a                	mv	a0,s2
    80003f32:	fffff097          	auipc	ra,0xfffff
    80003f36:	5a4080e7          	jalr	1444(ra) # 800034d6 <brelse>
      tot = -1;
    80003f3a:	59fd                	li	s3,-1
  }
  return tot;
    80003f3c:	0009851b          	sext.w	a0,s3
}
    80003f40:	70a6                	ld	ra,104(sp)
    80003f42:	7406                	ld	s0,96(sp)
    80003f44:	64e6                	ld	s1,88(sp)
    80003f46:	6946                	ld	s2,80(sp)
    80003f48:	69a6                	ld	s3,72(sp)
    80003f4a:	6a06                	ld	s4,64(sp)
    80003f4c:	7ae2                	ld	s5,56(sp)
    80003f4e:	7b42                	ld	s6,48(sp)
    80003f50:	7ba2                	ld	s7,40(sp)
    80003f52:	7c02                	ld	s8,32(sp)
    80003f54:	6ce2                	ld	s9,24(sp)
    80003f56:	6d42                	ld	s10,16(sp)
    80003f58:	6da2                	ld	s11,8(sp)
    80003f5a:	6165                	addi	sp,sp,112
    80003f5c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f5e:	89da                	mv	s3,s6
    80003f60:	bff1                	j	80003f3c <readi+0xce>
    return 0;
    80003f62:	4501                	li	a0,0
}
    80003f64:	8082                	ret

0000000080003f66 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f66:	497c                	lw	a5,84(a0)
    80003f68:	10d7e763          	bltu	a5,a3,80004076 <writei+0x110>
{
    80003f6c:	7159                	addi	sp,sp,-112
    80003f6e:	f486                	sd	ra,104(sp)
    80003f70:	f0a2                	sd	s0,96(sp)
    80003f72:	eca6                	sd	s1,88(sp)
    80003f74:	e8ca                	sd	s2,80(sp)
    80003f76:	e4ce                	sd	s3,72(sp)
    80003f78:	e0d2                	sd	s4,64(sp)
    80003f7a:	fc56                	sd	s5,56(sp)
    80003f7c:	f85a                	sd	s6,48(sp)
    80003f7e:	f45e                	sd	s7,40(sp)
    80003f80:	f062                	sd	s8,32(sp)
    80003f82:	ec66                	sd	s9,24(sp)
    80003f84:	e86a                	sd	s10,16(sp)
    80003f86:	e46e                	sd	s11,8(sp)
    80003f88:	1880                	addi	s0,sp,112
    80003f8a:	8baa                	mv	s7,a0
    80003f8c:	8c2e                	mv	s8,a1
    80003f8e:	8ab2                	mv	s5,a2
    80003f90:	8936                	mv	s2,a3
    80003f92:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f94:	00e687bb          	addw	a5,a3,a4
    80003f98:	0ed7e163          	bltu	a5,a3,8000407a <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f9c:	00043737          	lui	a4,0x43
    80003fa0:	0cf76f63          	bltu	a4,a5,8000407e <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fa4:	0a0b0863          	beqz	s6,80004054 <writei+0xee>
    80003fa8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003faa:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fae:	5cfd                	li	s9,-1
    80003fb0:	a091                	j	80003ff4 <writei+0x8e>
    80003fb2:	02099d93          	slli	s11,s3,0x20
    80003fb6:	020ddd93          	srli	s11,s11,0x20
    80003fba:	06048513          	addi	a0,s1,96
    80003fbe:	86ee                	mv	a3,s11
    80003fc0:	8656                	mv	a2,s5
    80003fc2:	85e2                	mv	a1,s8
    80003fc4:	953a                	add	a0,a0,a4
    80003fc6:	fffff097          	auipc	ra,0xfffff
    80003fca:	83c080e7          	jalr	-1988(ra) # 80002802 <either_copyin>
    80003fce:	07950263          	beq	a0,s9,80004032 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003fd2:	8526                	mv	a0,s1
    80003fd4:	00000097          	auipc	ra,0x0
    80003fd8:	78e080e7          	jalr	1934(ra) # 80004762 <log_write>
    brelse(bp);
    80003fdc:	8526                	mv	a0,s1
    80003fde:	fffff097          	auipc	ra,0xfffff
    80003fe2:	4f8080e7          	jalr	1272(ra) # 800034d6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fe6:	01498a3b          	addw	s4,s3,s4
    80003fea:	0129893b          	addw	s2,s3,s2
    80003fee:	9aee                	add	s5,s5,s11
    80003ff0:	056a7763          	bgeu	s4,s6,8000403e <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ff4:	000ba483          	lw	s1,0(s7)
    80003ff8:	00a9559b          	srliw	a1,s2,0xa
    80003ffc:	855e                	mv	a0,s7
    80003ffe:	fffff097          	auipc	ra,0xfffff
    80004002:	7ae080e7          	jalr	1966(ra) # 800037ac <bmap>
    80004006:	0005059b          	sext.w	a1,a0
    8000400a:	8526                	mv	a0,s1
    8000400c:	fffff097          	auipc	ra,0xfffff
    80004010:	1b2080e7          	jalr	434(ra) # 800031be <bread>
    80004014:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004016:	3ff97713          	andi	a4,s2,1023
    8000401a:	40ed07bb          	subw	a5,s10,a4
    8000401e:	414b06bb          	subw	a3,s6,s4
    80004022:	89be                	mv	s3,a5
    80004024:	2781                	sext.w	a5,a5
    80004026:	0006861b          	sext.w	a2,a3
    8000402a:	f8f674e3          	bgeu	a2,a5,80003fb2 <writei+0x4c>
    8000402e:	89b6                	mv	s3,a3
    80004030:	b749                	j	80003fb2 <writei+0x4c>
      brelse(bp);
    80004032:	8526                	mv	a0,s1
    80004034:	fffff097          	auipc	ra,0xfffff
    80004038:	4a2080e7          	jalr	1186(ra) # 800034d6 <brelse>
      n = -1;
    8000403c:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    8000403e:	054ba783          	lw	a5,84(s7)
    80004042:	0127f463          	bgeu	a5,s2,8000404a <writei+0xe4>
      ip->size = off;
    80004046:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    8000404a:	855e                	mv	a0,s7
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	aa4080e7          	jalr	-1372(ra) # 80003af0 <iupdate>
  }

  return n;
    80004054:	000b051b          	sext.w	a0,s6
}
    80004058:	70a6                	ld	ra,104(sp)
    8000405a:	7406                	ld	s0,96(sp)
    8000405c:	64e6                	ld	s1,88(sp)
    8000405e:	6946                	ld	s2,80(sp)
    80004060:	69a6                	ld	s3,72(sp)
    80004062:	6a06                	ld	s4,64(sp)
    80004064:	7ae2                	ld	s5,56(sp)
    80004066:	7b42                	ld	s6,48(sp)
    80004068:	7ba2                	ld	s7,40(sp)
    8000406a:	7c02                	ld	s8,32(sp)
    8000406c:	6ce2                	ld	s9,24(sp)
    8000406e:	6d42                	ld	s10,16(sp)
    80004070:	6da2                	ld	s11,8(sp)
    80004072:	6165                	addi	sp,sp,112
    80004074:	8082                	ret
    return -1;
    80004076:	557d                	li	a0,-1
}
    80004078:	8082                	ret
    return -1;
    8000407a:	557d                	li	a0,-1
    8000407c:	bff1                	j	80004058 <writei+0xf2>
    return -1;
    8000407e:	557d                	li	a0,-1
    80004080:	bfe1                	j	80004058 <writei+0xf2>

0000000080004082 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004082:	1141                	addi	sp,sp,-16
    80004084:	e406                	sd	ra,8(sp)
    80004086:	e022                	sd	s0,0(sp)
    80004088:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000408a:	4639                	li	a2,14
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	122080e7          	jalr	290(ra) # 800011ae <strncmp>
}
    80004094:	60a2                	ld	ra,8(sp)
    80004096:	6402                	ld	s0,0(sp)
    80004098:	0141                	addi	sp,sp,16
    8000409a:	8082                	ret

000000008000409c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000409c:	7139                	addi	sp,sp,-64
    8000409e:	fc06                	sd	ra,56(sp)
    800040a0:	f822                	sd	s0,48(sp)
    800040a2:	f426                	sd	s1,40(sp)
    800040a4:	f04a                	sd	s2,32(sp)
    800040a6:	ec4e                	sd	s3,24(sp)
    800040a8:	e852                	sd	s4,16(sp)
    800040aa:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040ac:	04c51703          	lh	a4,76(a0)
    800040b0:	4785                	li	a5,1
    800040b2:	00f71a63          	bne	a4,a5,800040c6 <dirlookup+0x2a>
    800040b6:	892a                	mv	s2,a0
    800040b8:	89ae                	mv	s3,a1
    800040ba:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040bc:	497c                	lw	a5,84(a0)
    800040be:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040c0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040c2:	e79d                	bnez	a5,800040f0 <dirlookup+0x54>
    800040c4:	a8a5                	j	8000413c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040c6:	00004517          	auipc	a0,0x4
    800040ca:	59a50513          	addi	a0,a0,1434 # 80008660 <syscalls+0x1a8>
    800040ce:	ffffc097          	auipc	ra,0xffffc
    800040d2:	482080e7          	jalr	1154(ra) # 80000550 <panic>
      panic("dirlookup read");
    800040d6:	00004517          	auipc	a0,0x4
    800040da:	5a250513          	addi	a0,a0,1442 # 80008678 <syscalls+0x1c0>
    800040de:	ffffc097          	auipc	ra,0xffffc
    800040e2:	472080e7          	jalr	1138(ra) # 80000550 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040e6:	24c1                	addiw	s1,s1,16
    800040e8:	05492783          	lw	a5,84(s2)
    800040ec:	04f4f763          	bgeu	s1,a5,8000413a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040f0:	4741                	li	a4,16
    800040f2:	86a6                	mv	a3,s1
    800040f4:	fc040613          	addi	a2,s0,-64
    800040f8:	4581                	li	a1,0
    800040fa:	854a                	mv	a0,s2
    800040fc:	00000097          	auipc	ra,0x0
    80004100:	d72080e7          	jalr	-654(ra) # 80003e6e <readi>
    80004104:	47c1                	li	a5,16
    80004106:	fcf518e3          	bne	a0,a5,800040d6 <dirlookup+0x3a>
    if(de.inum == 0)
    8000410a:	fc045783          	lhu	a5,-64(s0)
    8000410e:	dfe1                	beqz	a5,800040e6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004110:	fc240593          	addi	a1,s0,-62
    80004114:	854e                	mv	a0,s3
    80004116:	00000097          	auipc	ra,0x0
    8000411a:	f6c080e7          	jalr	-148(ra) # 80004082 <namecmp>
    8000411e:	f561                	bnez	a0,800040e6 <dirlookup+0x4a>
      if(poff)
    80004120:	000a0463          	beqz	s4,80004128 <dirlookup+0x8c>
        *poff = off;
    80004124:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004128:	fc045583          	lhu	a1,-64(s0)
    8000412c:	00092503          	lw	a0,0(s2)
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	756080e7          	jalr	1878(ra) # 80003886 <iget>
    80004138:	a011                	j	8000413c <dirlookup+0xa0>
  return 0;
    8000413a:	4501                	li	a0,0
}
    8000413c:	70e2                	ld	ra,56(sp)
    8000413e:	7442                	ld	s0,48(sp)
    80004140:	74a2                	ld	s1,40(sp)
    80004142:	7902                	ld	s2,32(sp)
    80004144:	69e2                	ld	s3,24(sp)
    80004146:	6a42                	ld	s4,16(sp)
    80004148:	6121                	addi	sp,sp,64
    8000414a:	8082                	ret

000000008000414c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000414c:	711d                	addi	sp,sp,-96
    8000414e:	ec86                	sd	ra,88(sp)
    80004150:	e8a2                	sd	s0,80(sp)
    80004152:	e4a6                	sd	s1,72(sp)
    80004154:	e0ca                	sd	s2,64(sp)
    80004156:	fc4e                	sd	s3,56(sp)
    80004158:	f852                	sd	s4,48(sp)
    8000415a:	f456                	sd	s5,40(sp)
    8000415c:	f05a                	sd	s6,32(sp)
    8000415e:	ec5e                	sd	s7,24(sp)
    80004160:	e862                	sd	s8,16(sp)
    80004162:	e466                	sd	s9,8(sp)
    80004164:	1080                	addi	s0,sp,96
    80004166:	84aa                	mv	s1,a0
    80004168:	8b2e                	mv	s6,a1
    8000416a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000416c:	00054703          	lbu	a4,0(a0)
    80004170:	02f00793          	li	a5,47
    80004174:	02f70363          	beq	a4,a5,8000419a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004178:	ffffe097          	auipc	ra,0xffffe
    8000417c:	bc2080e7          	jalr	-1086(ra) # 80001d3a <myproc>
    80004180:	15853503          	ld	a0,344(a0)
    80004184:	00000097          	auipc	ra,0x0
    80004188:	9f8080e7          	jalr	-1544(ra) # 80003b7c <idup>
    8000418c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000418e:	02f00913          	li	s2,47
  len = path - s;
    80004192:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004194:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004196:	4c05                	li	s8,1
    80004198:	a865                	j	80004250 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000419a:	4585                	li	a1,1
    8000419c:	4505                	li	a0,1
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	6e8080e7          	jalr	1768(ra) # 80003886 <iget>
    800041a6:	89aa                	mv	s3,a0
    800041a8:	b7dd                	j	8000418e <namex+0x42>
      iunlockput(ip);
    800041aa:	854e                	mv	a0,s3
    800041ac:	00000097          	auipc	ra,0x0
    800041b0:	c70080e7          	jalr	-912(ra) # 80003e1c <iunlockput>
      return 0;
    800041b4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041b6:	854e                	mv	a0,s3
    800041b8:	60e6                	ld	ra,88(sp)
    800041ba:	6446                	ld	s0,80(sp)
    800041bc:	64a6                	ld	s1,72(sp)
    800041be:	6906                	ld	s2,64(sp)
    800041c0:	79e2                	ld	s3,56(sp)
    800041c2:	7a42                	ld	s4,48(sp)
    800041c4:	7aa2                	ld	s5,40(sp)
    800041c6:	7b02                	ld	s6,32(sp)
    800041c8:	6be2                	ld	s7,24(sp)
    800041ca:	6c42                	ld	s8,16(sp)
    800041cc:	6ca2                	ld	s9,8(sp)
    800041ce:	6125                	addi	sp,sp,96
    800041d0:	8082                	ret
      iunlock(ip);
    800041d2:	854e                	mv	a0,s3
    800041d4:	00000097          	auipc	ra,0x0
    800041d8:	aa8080e7          	jalr	-1368(ra) # 80003c7c <iunlock>
      return ip;
    800041dc:	bfe9                	j	800041b6 <namex+0x6a>
      iunlockput(ip);
    800041de:	854e                	mv	a0,s3
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	c3c080e7          	jalr	-964(ra) # 80003e1c <iunlockput>
      return 0;
    800041e8:	89d2                	mv	s3,s4
    800041ea:	b7f1                	j	800041b6 <namex+0x6a>
  len = path - s;
    800041ec:	40b48633          	sub	a2,s1,a1
    800041f0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800041f4:	094cd463          	bge	s9,s4,8000427c <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041f8:	4639                	li	a2,14
    800041fa:	8556                	mv	a0,s5
    800041fc:	ffffd097          	auipc	ra,0xffffd
    80004200:	f36080e7          	jalr	-202(ra) # 80001132 <memmove>
  while(*path == '/')
    80004204:	0004c783          	lbu	a5,0(s1)
    80004208:	01279763          	bne	a5,s2,80004216 <namex+0xca>
    path++;
    8000420c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000420e:	0004c783          	lbu	a5,0(s1)
    80004212:	ff278de3          	beq	a5,s2,8000420c <namex+0xc0>
    ilock(ip);
    80004216:	854e                	mv	a0,s3
    80004218:	00000097          	auipc	ra,0x0
    8000421c:	9a2080e7          	jalr	-1630(ra) # 80003bba <ilock>
    if(ip->type != T_DIR){
    80004220:	04c99783          	lh	a5,76(s3)
    80004224:	f98793e3          	bne	a5,s8,800041aa <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004228:	000b0563          	beqz	s6,80004232 <namex+0xe6>
    8000422c:	0004c783          	lbu	a5,0(s1)
    80004230:	d3cd                	beqz	a5,800041d2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004232:	865e                	mv	a2,s7
    80004234:	85d6                	mv	a1,s5
    80004236:	854e                	mv	a0,s3
    80004238:	00000097          	auipc	ra,0x0
    8000423c:	e64080e7          	jalr	-412(ra) # 8000409c <dirlookup>
    80004240:	8a2a                	mv	s4,a0
    80004242:	dd51                	beqz	a0,800041de <namex+0x92>
    iunlockput(ip);
    80004244:	854e                	mv	a0,s3
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	bd6080e7          	jalr	-1066(ra) # 80003e1c <iunlockput>
    ip = next;
    8000424e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004250:	0004c783          	lbu	a5,0(s1)
    80004254:	05279763          	bne	a5,s2,800042a2 <namex+0x156>
    path++;
    80004258:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000425a:	0004c783          	lbu	a5,0(s1)
    8000425e:	ff278de3          	beq	a5,s2,80004258 <namex+0x10c>
  if(*path == 0)
    80004262:	c79d                	beqz	a5,80004290 <namex+0x144>
    path++;
    80004264:	85a6                	mv	a1,s1
  len = path - s;
    80004266:	8a5e                	mv	s4,s7
    80004268:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000426a:	01278963          	beq	a5,s2,8000427c <namex+0x130>
    8000426e:	dfbd                	beqz	a5,800041ec <namex+0xa0>
    path++;
    80004270:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004272:	0004c783          	lbu	a5,0(s1)
    80004276:	ff279ce3          	bne	a5,s2,8000426e <namex+0x122>
    8000427a:	bf8d                	j	800041ec <namex+0xa0>
    memmove(name, s, len);
    8000427c:	2601                	sext.w	a2,a2
    8000427e:	8556                	mv	a0,s5
    80004280:	ffffd097          	auipc	ra,0xffffd
    80004284:	eb2080e7          	jalr	-334(ra) # 80001132 <memmove>
    name[len] = 0;
    80004288:	9a56                	add	s4,s4,s5
    8000428a:	000a0023          	sb	zero,0(s4)
    8000428e:	bf9d                	j	80004204 <namex+0xb8>
  if(nameiparent){
    80004290:	f20b03e3          	beqz	s6,800041b6 <namex+0x6a>
    iput(ip);
    80004294:	854e                	mv	a0,s3
    80004296:	00000097          	auipc	ra,0x0
    8000429a:	ade080e7          	jalr	-1314(ra) # 80003d74 <iput>
    return 0;
    8000429e:	4981                	li	s3,0
    800042a0:	bf19                	j	800041b6 <namex+0x6a>
  if(*path == 0)
    800042a2:	d7fd                	beqz	a5,80004290 <namex+0x144>
  while(*path != '/' && *path != 0)
    800042a4:	0004c783          	lbu	a5,0(s1)
    800042a8:	85a6                	mv	a1,s1
    800042aa:	b7d1                	j	8000426e <namex+0x122>

00000000800042ac <dirlink>:
{
    800042ac:	7139                	addi	sp,sp,-64
    800042ae:	fc06                	sd	ra,56(sp)
    800042b0:	f822                	sd	s0,48(sp)
    800042b2:	f426                	sd	s1,40(sp)
    800042b4:	f04a                	sd	s2,32(sp)
    800042b6:	ec4e                	sd	s3,24(sp)
    800042b8:	e852                	sd	s4,16(sp)
    800042ba:	0080                	addi	s0,sp,64
    800042bc:	892a                	mv	s2,a0
    800042be:	8a2e                	mv	s4,a1
    800042c0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042c2:	4601                	li	a2,0
    800042c4:	00000097          	auipc	ra,0x0
    800042c8:	dd8080e7          	jalr	-552(ra) # 8000409c <dirlookup>
    800042cc:	e93d                	bnez	a0,80004342 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ce:	05492483          	lw	s1,84(s2)
    800042d2:	c49d                	beqz	s1,80004300 <dirlink+0x54>
    800042d4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042d6:	4741                	li	a4,16
    800042d8:	86a6                	mv	a3,s1
    800042da:	fc040613          	addi	a2,s0,-64
    800042de:	4581                	li	a1,0
    800042e0:	854a                	mv	a0,s2
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	b8c080e7          	jalr	-1140(ra) # 80003e6e <readi>
    800042ea:	47c1                	li	a5,16
    800042ec:	06f51163          	bne	a0,a5,8000434e <dirlink+0xa2>
    if(de.inum == 0)
    800042f0:	fc045783          	lhu	a5,-64(s0)
    800042f4:	c791                	beqz	a5,80004300 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042f6:	24c1                	addiw	s1,s1,16
    800042f8:	05492783          	lw	a5,84(s2)
    800042fc:	fcf4ede3          	bltu	s1,a5,800042d6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004300:	4639                	li	a2,14
    80004302:	85d2                	mv	a1,s4
    80004304:	fc240513          	addi	a0,s0,-62
    80004308:	ffffd097          	auipc	ra,0xffffd
    8000430c:	ee2080e7          	jalr	-286(ra) # 800011ea <strncpy>
  de.inum = inum;
    80004310:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004314:	4741                	li	a4,16
    80004316:	86a6                	mv	a3,s1
    80004318:	fc040613          	addi	a2,s0,-64
    8000431c:	4581                	li	a1,0
    8000431e:	854a                	mv	a0,s2
    80004320:	00000097          	auipc	ra,0x0
    80004324:	c46080e7          	jalr	-954(ra) # 80003f66 <writei>
    80004328:	872a                	mv	a4,a0
    8000432a:	47c1                	li	a5,16
  return 0;
    8000432c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000432e:	02f71863          	bne	a4,a5,8000435e <dirlink+0xb2>
}
    80004332:	70e2                	ld	ra,56(sp)
    80004334:	7442                	ld	s0,48(sp)
    80004336:	74a2                	ld	s1,40(sp)
    80004338:	7902                	ld	s2,32(sp)
    8000433a:	69e2                	ld	s3,24(sp)
    8000433c:	6a42                	ld	s4,16(sp)
    8000433e:	6121                	addi	sp,sp,64
    80004340:	8082                	ret
    iput(ip);
    80004342:	00000097          	auipc	ra,0x0
    80004346:	a32080e7          	jalr	-1486(ra) # 80003d74 <iput>
    return -1;
    8000434a:	557d                	li	a0,-1
    8000434c:	b7dd                	j	80004332 <dirlink+0x86>
      panic("dirlink read");
    8000434e:	00004517          	auipc	a0,0x4
    80004352:	33a50513          	addi	a0,a0,826 # 80008688 <syscalls+0x1d0>
    80004356:	ffffc097          	auipc	ra,0xffffc
    8000435a:	1fa080e7          	jalr	506(ra) # 80000550 <panic>
    panic("dirlink");
    8000435e:	00004517          	auipc	a0,0x4
    80004362:	44a50513          	addi	a0,a0,1098 # 800087a8 <syscalls+0x2f0>
    80004366:	ffffc097          	auipc	ra,0xffffc
    8000436a:	1ea080e7          	jalr	490(ra) # 80000550 <panic>

000000008000436e <namei>:

struct inode*
namei(char *path)
{
    8000436e:	1101                	addi	sp,sp,-32
    80004370:	ec06                	sd	ra,24(sp)
    80004372:	e822                	sd	s0,16(sp)
    80004374:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004376:	fe040613          	addi	a2,s0,-32
    8000437a:	4581                	li	a1,0
    8000437c:	00000097          	auipc	ra,0x0
    80004380:	dd0080e7          	jalr	-560(ra) # 8000414c <namex>
}
    80004384:	60e2                	ld	ra,24(sp)
    80004386:	6442                	ld	s0,16(sp)
    80004388:	6105                	addi	sp,sp,32
    8000438a:	8082                	ret

000000008000438c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000438c:	1141                	addi	sp,sp,-16
    8000438e:	e406                	sd	ra,8(sp)
    80004390:	e022                	sd	s0,0(sp)
    80004392:	0800                	addi	s0,sp,16
    80004394:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004396:	4585                	li	a1,1
    80004398:	00000097          	auipc	ra,0x0
    8000439c:	db4080e7          	jalr	-588(ra) # 8000414c <namex>
}
    800043a0:	60a2                	ld	ra,8(sp)
    800043a2:	6402                	ld	s0,0(sp)
    800043a4:	0141                	addi	sp,sp,16
    800043a6:	8082                	ret

00000000800043a8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043a8:	1101                	addi	sp,sp,-32
    800043aa:	ec06                	sd	ra,24(sp)
    800043ac:	e822                	sd	s0,16(sp)
    800043ae:	e426                	sd	s1,8(sp)
    800043b0:	e04a                	sd	s2,0(sp)
    800043b2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043b4:	00022917          	auipc	s2,0x22
    800043b8:	bac90913          	addi	s2,s2,-1108 # 80025f60 <log>
    800043bc:	02092583          	lw	a1,32(s2)
    800043c0:	03092503          	lw	a0,48(s2)
    800043c4:	fffff097          	auipc	ra,0xfffff
    800043c8:	dfa080e7          	jalr	-518(ra) # 800031be <bread>
    800043cc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043ce:	03492683          	lw	a3,52(s2)
    800043d2:	d134                	sw	a3,96(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043d4:	02d05763          	blez	a3,80004402 <write_head+0x5a>
    800043d8:	00022797          	auipc	a5,0x22
    800043dc:	bc078793          	addi	a5,a5,-1088 # 80025f98 <log+0x38>
    800043e0:	06450713          	addi	a4,a0,100
    800043e4:	36fd                	addiw	a3,a3,-1
    800043e6:	1682                	slli	a3,a3,0x20
    800043e8:	9281                	srli	a3,a3,0x20
    800043ea:	068a                	slli	a3,a3,0x2
    800043ec:	00022617          	auipc	a2,0x22
    800043f0:	bb060613          	addi	a2,a2,-1104 # 80025f9c <log+0x3c>
    800043f4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043f6:	4390                	lw	a2,0(a5)
    800043f8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043fa:	0791                	addi	a5,a5,4
    800043fc:	0711                	addi	a4,a4,4
    800043fe:	fed79ce3          	bne	a5,a3,800043f6 <write_head+0x4e>
  }
  bwrite(buf);
    80004402:	8526                	mv	a0,s1
    80004404:	fffff097          	auipc	ra,0xfffff
    80004408:	094080e7          	jalr	148(ra) # 80003498 <bwrite>
  brelse(buf);
    8000440c:	8526                	mv	a0,s1
    8000440e:	fffff097          	auipc	ra,0xfffff
    80004412:	0c8080e7          	jalr	200(ra) # 800034d6 <brelse>
}
    80004416:	60e2                	ld	ra,24(sp)
    80004418:	6442                	ld	s0,16(sp)
    8000441a:	64a2                	ld	s1,8(sp)
    8000441c:	6902                	ld	s2,0(sp)
    8000441e:	6105                	addi	sp,sp,32
    80004420:	8082                	ret

0000000080004422 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004422:	00022797          	auipc	a5,0x22
    80004426:	b727a783          	lw	a5,-1166(a5) # 80025f94 <log+0x34>
    8000442a:	0af05d63          	blez	a5,800044e4 <install_trans+0xc2>
{
    8000442e:	7139                	addi	sp,sp,-64
    80004430:	fc06                	sd	ra,56(sp)
    80004432:	f822                	sd	s0,48(sp)
    80004434:	f426                	sd	s1,40(sp)
    80004436:	f04a                	sd	s2,32(sp)
    80004438:	ec4e                	sd	s3,24(sp)
    8000443a:	e852                	sd	s4,16(sp)
    8000443c:	e456                	sd	s5,8(sp)
    8000443e:	e05a                	sd	s6,0(sp)
    80004440:	0080                	addi	s0,sp,64
    80004442:	8b2a                	mv	s6,a0
    80004444:	00022a97          	auipc	s5,0x22
    80004448:	b54a8a93          	addi	s5,s5,-1196 # 80025f98 <log+0x38>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000444c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000444e:	00022997          	auipc	s3,0x22
    80004452:	b1298993          	addi	s3,s3,-1262 # 80025f60 <log>
    80004456:	a035                	j	80004482 <install_trans+0x60>
      bunpin(dbuf);
    80004458:	8526                	mv	a0,s1
    8000445a:	fffff097          	auipc	ra,0xfffff
    8000445e:	156080e7          	jalr	342(ra) # 800035b0 <bunpin>
    brelse(lbuf);
    80004462:	854a                	mv	a0,s2
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	072080e7          	jalr	114(ra) # 800034d6 <brelse>
    brelse(dbuf);
    8000446c:	8526                	mv	a0,s1
    8000446e:	fffff097          	auipc	ra,0xfffff
    80004472:	068080e7          	jalr	104(ra) # 800034d6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004476:	2a05                	addiw	s4,s4,1
    80004478:	0a91                	addi	s5,s5,4
    8000447a:	0349a783          	lw	a5,52(s3)
    8000447e:	04fa5963          	bge	s4,a5,800044d0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004482:	0209a583          	lw	a1,32(s3)
    80004486:	014585bb          	addw	a1,a1,s4
    8000448a:	2585                	addiw	a1,a1,1
    8000448c:	0309a503          	lw	a0,48(s3)
    80004490:	fffff097          	auipc	ra,0xfffff
    80004494:	d2e080e7          	jalr	-722(ra) # 800031be <bread>
    80004498:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000449a:	000aa583          	lw	a1,0(s5)
    8000449e:	0309a503          	lw	a0,48(s3)
    800044a2:	fffff097          	auipc	ra,0xfffff
    800044a6:	d1c080e7          	jalr	-740(ra) # 800031be <bread>
    800044aa:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044ac:	40000613          	li	a2,1024
    800044b0:	06090593          	addi	a1,s2,96
    800044b4:	06050513          	addi	a0,a0,96
    800044b8:	ffffd097          	auipc	ra,0xffffd
    800044bc:	c7a080e7          	jalr	-902(ra) # 80001132 <memmove>
    bwrite(dbuf);  // write dst to disk
    800044c0:	8526                	mv	a0,s1
    800044c2:	fffff097          	auipc	ra,0xfffff
    800044c6:	fd6080e7          	jalr	-42(ra) # 80003498 <bwrite>
    if(recovering == 0)
    800044ca:	f80b1ce3          	bnez	s6,80004462 <install_trans+0x40>
    800044ce:	b769                	j	80004458 <install_trans+0x36>
}
    800044d0:	70e2                	ld	ra,56(sp)
    800044d2:	7442                	ld	s0,48(sp)
    800044d4:	74a2                	ld	s1,40(sp)
    800044d6:	7902                	ld	s2,32(sp)
    800044d8:	69e2                	ld	s3,24(sp)
    800044da:	6a42                	ld	s4,16(sp)
    800044dc:	6aa2                	ld	s5,8(sp)
    800044de:	6b02                	ld	s6,0(sp)
    800044e0:	6121                	addi	sp,sp,64
    800044e2:	8082                	ret
    800044e4:	8082                	ret

00000000800044e6 <initlog>:
{
    800044e6:	7179                	addi	sp,sp,-48
    800044e8:	f406                	sd	ra,40(sp)
    800044ea:	f022                	sd	s0,32(sp)
    800044ec:	ec26                	sd	s1,24(sp)
    800044ee:	e84a                	sd	s2,16(sp)
    800044f0:	e44e                	sd	s3,8(sp)
    800044f2:	1800                	addi	s0,sp,48
    800044f4:	892a                	mv	s2,a0
    800044f6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044f8:	00022497          	auipc	s1,0x22
    800044fc:	a6848493          	addi	s1,s1,-1432 # 80025f60 <log>
    80004500:	00004597          	auipc	a1,0x4
    80004504:	19858593          	addi	a1,a1,408 # 80008698 <syscalls+0x1e0>
    80004508:	8526                	mv	a0,s1
    8000450a:	ffffd097          	auipc	ra,0xffffd
    8000450e:	964080e7          	jalr	-1692(ra) # 80000e6e <initlock>
  log.start = sb->logstart;
    80004512:	0149a583          	lw	a1,20(s3)
    80004516:	d08c                	sw	a1,32(s1)
  log.size = sb->nlog;
    80004518:	0109a783          	lw	a5,16(s3)
    8000451c:	d0dc                	sw	a5,36(s1)
  log.dev = dev;
    8000451e:	0324a823          	sw	s2,48(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004522:	854a                	mv	a0,s2
    80004524:	fffff097          	auipc	ra,0xfffff
    80004528:	c9a080e7          	jalr	-870(ra) # 800031be <bread>
  log.lh.n = lh->n;
    8000452c:	513c                	lw	a5,96(a0)
    8000452e:	d8dc                	sw	a5,52(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004530:	02f05563          	blez	a5,8000455a <initlog+0x74>
    80004534:	06450713          	addi	a4,a0,100
    80004538:	00022697          	auipc	a3,0x22
    8000453c:	a6068693          	addi	a3,a3,-1440 # 80025f98 <log+0x38>
    80004540:	37fd                	addiw	a5,a5,-1
    80004542:	1782                	slli	a5,a5,0x20
    80004544:	9381                	srli	a5,a5,0x20
    80004546:	078a                	slli	a5,a5,0x2
    80004548:	06850613          	addi	a2,a0,104
    8000454c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000454e:	4310                	lw	a2,0(a4)
    80004550:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004552:	0711                	addi	a4,a4,4
    80004554:	0691                	addi	a3,a3,4
    80004556:	fef71ce3          	bne	a4,a5,8000454e <initlog+0x68>
  brelse(buf);
    8000455a:	fffff097          	auipc	ra,0xfffff
    8000455e:	f7c080e7          	jalr	-132(ra) # 800034d6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004562:	4505                	li	a0,1
    80004564:	00000097          	auipc	ra,0x0
    80004568:	ebe080e7          	jalr	-322(ra) # 80004422 <install_trans>
  log.lh.n = 0;
    8000456c:	00022797          	auipc	a5,0x22
    80004570:	a207a423          	sw	zero,-1496(a5) # 80025f94 <log+0x34>
  write_head(); // clear the log
    80004574:	00000097          	auipc	ra,0x0
    80004578:	e34080e7          	jalr	-460(ra) # 800043a8 <write_head>
}
    8000457c:	70a2                	ld	ra,40(sp)
    8000457e:	7402                	ld	s0,32(sp)
    80004580:	64e2                	ld	s1,24(sp)
    80004582:	6942                	ld	s2,16(sp)
    80004584:	69a2                	ld	s3,8(sp)
    80004586:	6145                	addi	sp,sp,48
    80004588:	8082                	ret

000000008000458a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000458a:	1101                	addi	sp,sp,-32
    8000458c:	ec06                	sd	ra,24(sp)
    8000458e:	e822                	sd	s0,16(sp)
    80004590:	e426                	sd	s1,8(sp)
    80004592:	e04a                	sd	s2,0(sp)
    80004594:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004596:	00022517          	auipc	a0,0x22
    8000459a:	9ca50513          	addi	a0,a0,-1590 # 80025f60 <log>
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	754080e7          	jalr	1876(ra) # 80000cf2 <acquire>
  while(1){
    if(log.committing){
    800045a6:	00022497          	auipc	s1,0x22
    800045aa:	9ba48493          	addi	s1,s1,-1606 # 80025f60 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045ae:	4979                	li	s2,30
    800045b0:	a039                	j	800045be <begin_op+0x34>
      sleep(&log, &log.lock);
    800045b2:	85a6                	mv	a1,s1
    800045b4:	8526                	mv	a0,s1
    800045b6:	ffffe097          	auipc	ra,0xffffe
    800045ba:	f94080e7          	jalr	-108(ra) # 8000254a <sleep>
    if(log.committing){
    800045be:	54dc                	lw	a5,44(s1)
    800045c0:	fbed                	bnez	a5,800045b2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045c2:	549c                	lw	a5,40(s1)
    800045c4:	0017871b          	addiw	a4,a5,1
    800045c8:	0007069b          	sext.w	a3,a4
    800045cc:	0027179b          	slliw	a5,a4,0x2
    800045d0:	9fb9                	addw	a5,a5,a4
    800045d2:	0017979b          	slliw	a5,a5,0x1
    800045d6:	58d8                	lw	a4,52(s1)
    800045d8:	9fb9                	addw	a5,a5,a4
    800045da:	00f95963          	bge	s2,a5,800045ec <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045de:	85a6                	mv	a1,s1
    800045e0:	8526                	mv	a0,s1
    800045e2:	ffffe097          	auipc	ra,0xffffe
    800045e6:	f68080e7          	jalr	-152(ra) # 8000254a <sleep>
    800045ea:	bfd1                	j	800045be <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045ec:	00022517          	auipc	a0,0x22
    800045f0:	97450513          	addi	a0,a0,-1676 # 80025f60 <log>
    800045f4:	d514                	sw	a3,40(a0)
      release(&log.lock);
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	7cc080e7          	jalr	1996(ra) # 80000dc2 <release>
      break;
    }
  }
}
    800045fe:	60e2                	ld	ra,24(sp)
    80004600:	6442                	ld	s0,16(sp)
    80004602:	64a2                	ld	s1,8(sp)
    80004604:	6902                	ld	s2,0(sp)
    80004606:	6105                	addi	sp,sp,32
    80004608:	8082                	ret

000000008000460a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000460a:	7139                	addi	sp,sp,-64
    8000460c:	fc06                	sd	ra,56(sp)
    8000460e:	f822                	sd	s0,48(sp)
    80004610:	f426                	sd	s1,40(sp)
    80004612:	f04a                	sd	s2,32(sp)
    80004614:	ec4e                	sd	s3,24(sp)
    80004616:	e852                	sd	s4,16(sp)
    80004618:	e456                	sd	s5,8(sp)
    8000461a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000461c:	00022497          	auipc	s1,0x22
    80004620:	94448493          	addi	s1,s1,-1724 # 80025f60 <log>
    80004624:	8526                	mv	a0,s1
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	6cc080e7          	jalr	1740(ra) # 80000cf2 <acquire>
  log.outstanding -= 1;
    8000462e:	549c                	lw	a5,40(s1)
    80004630:	37fd                	addiw	a5,a5,-1
    80004632:	0007891b          	sext.w	s2,a5
    80004636:	d49c                	sw	a5,40(s1)
  if(log.committing)
    80004638:	54dc                	lw	a5,44(s1)
    8000463a:	efb9                	bnez	a5,80004698 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000463c:	06091663          	bnez	s2,800046a8 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004640:	00022497          	auipc	s1,0x22
    80004644:	92048493          	addi	s1,s1,-1760 # 80025f60 <log>
    80004648:	4785                	li	a5,1
    8000464a:	d4dc                	sw	a5,44(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000464c:	8526                	mv	a0,s1
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	774080e7          	jalr	1908(ra) # 80000dc2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004656:	58dc                	lw	a5,52(s1)
    80004658:	06f04763          	bgtz	a5,800046c6 <end_op+0xbc>
    acquire(&log.lock);
    8000465c:	00022497          	auipc	s1,0x22
    80004660:	90448493          	addi	s1,s1,-1788 # 80025f60 <log>
    80004664:	8526                	mv	a0,s1
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	68c080e7          	jalr	1676(ra) # 80000cf2 <acquire>
    log.committing = 0;
    8000466e:	0204a623          	sw	zero,44(s1)
    wakeup(&log);
    80004672:	8526                	mv	a0,s1
    80004674:	ffffe097          	auipc	ra,0xffffe
    80004678:	05c080e7          	jalr	92(ra) # 800026d0 <wakeup>
    release(&log.lock);
    8000467c:	8526                	mv	a0,s1
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	744080e7          	jalr	1860(ra) # 80000dc2 <release>
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
    panic("log.committing");
    80004698:	00004517          	auipc	a0,0x4
    8000469c:	00850513          	addi	a0,a0,8 # 800086a0 <syscalls+0x1e8>
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	eb0080e7          	jalr	-336(ra) # 80000550 <panic>
    wakeup(&log);
    800046a8:	00022497          	auipc	s1,0x22
    800046ac:	8b848493          	addi	s1,s1,-1864 # 80025f60 <log>
    800046b0:	8526                	mv	a0,s1
    800046b2:	ffffe097          	auipc	ra,0xffffe
    800046b6:	01e080e7          	jalr	30(ra) # 800026d0 <wakeup>
  release(&log.lock);
    800046ba:	8526                	mv	a0,s1
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	706080e7          	jalr	1798(ra) # 80000dc2 <release>
  if(do_commit){
    800046c4:	b7c9                	j	80004686 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046c6:	00022a97          	auipc	s5,0x22
    800046ca:	8d2a8a93          	addi	s5,s5,-1838 # 80025f98 <log+0x38>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046ce:	00022a17          	auipc	s4,0x22
    800046d2:	892a0a13          	addi	s4,s4,-1902 # 80025f60 <log>
    800046d6:	020a2583          	lw	a1,32(s4)
    800046da:	012585bb          	addw	a1,a1,s2
    800046de:	2585                	addiw	a1,a1,1
    800046e0:	030a2503          	lw	a0,48(s4)
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	ada080e7          	jalr	-1318(ra) # 800031be <bread>
    800046ec:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046ee:	000aa583          	lw	a1,0(s5)
    800046f2:	030a2503          	lw	a0,48(s4)
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	ac8080e7          	jalr	-1336(ra) # 800031be <bread>
    800046fe:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004700:	40000613          	li	a2,1024
    80004704:	06050593          	addi	a1,a0,96
    80004708:	06048513          	addi	a0,s1,96
    8000470c:	ffffd097          	auipc	ra,0xffffd
    80004710:	a26080e7          	jalr	-1498(ra) # 80001132 <memmove>
    bwrite(to);  // write the log
    80004714:	8526                	mv	a0,s1
    80004716:	fffff097          	auipc	ra,0xfffff
    8000471a:	d82080e7          	jalr	-638(ra) # 80003498 <bwrite>
    brelse(from);
    8000471e:	854e                	mv	a0,s3
    80004720:	fffff097          	auipc	ra,0xfffff
    80004724:	db6080e7          	jalr	-586(ra) # 800034d6 <brelse>
    brelse(to);
    80004728:	8526                	mv	a0,s1
    8000472a:	fffff097          	auipc	ra,0xfffff
    8000472e:	dac080e7          	jalr	-596(ra) # 800034d6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004732:	2905                	addiw	s2,s2,1
    80004734:	0a91                	addi	s5,s5,4
    80004736:	034a2783          	lw	a5,52(s4)
    8000473a:	f8f94ee3          	blt	s2,a5,800046d6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000473e:	00000097          	auipc	ra,0x0
    80004742:	c6a080e7          	jalr	-918(ra) # 800043a8 <write_head>
    install_trans(0); // Now install writes to home locations
    80004746:	4501                	li	a0,0
    80004748:	00000097          	auipc	ra,0x0
    8000474c:	cda080e7          	jalr	-806(ra) # 80004422 <install_trans>
    log.lh.n = 0;
    80004750:	00022797          	auipc	a5,0x22
    80004754:	8407a223          	sw	zero,-1980(a5) # 80025f94 <log+0x34>
    write_head();    // Erase the transaction from the log
    80004758:	00000097          	auipc	ra,0x0
    8000475c:	c50080e7          	jalr	-944(ra) # 800043a8 <write_head>
    80004760:	bdf5                	j	8000465c <end_op+0x52>

0000000080004762 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004762:	1101                	addi	sp,sp,-32
    80004764:	ec06                	sd	ra,24(sp)
    80004766:	e822                	sd	s0,16(sp)
    80004768:	e426                	sd	s1,8(sp)
    8000476a:	e04a                	sd	s2,0(sp)
    8000476c:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000476e:	00022717          	auipc	a4,0x22
    80004772:	82672703          	lw	a4,-2010(a4) # 80025f94 <log+0x34>
    80004776:	47f5                	li	a5,29
    80004778:	08e7c063          	blt	a5,a4,800047f8 <log_write+0x96>
    8000477c:	84aa                	mv	s1,a0
    8000477e:	00022797          	auipc	a5,0x22
    80004782:	8067a783          	lw	a5,-2042(a5) # 80025f84 <log+0x24>
    80004786:	37fd                	addiw	a5,a5,-1
    80004788:	06f75863          	bge	a4,a5,800047f8 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000478c:	00021797          	auipc	a5,0x21
    80004790:	7fc7a783          	lw	a5,2044(a5) # 80025f88 <log+0x28>
    80004794:	06f05a63          	blez	a5,80004808 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004798:	00021917          	auipc	s2,0x21
    8000479c:	7c890913          	addi	s2,s2,1992 # 80025f60 <log>
    800047a0:	854a                	mv	a0,s2
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	550080e7          	jalr	1360(ra) # 80000cf2 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800047aa:	03492603          	lw	a2,52(s2)
    800047ae:	06c05563          	blez	a2,80004818 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800047b2:	44cc                	lw	a1,12(s1)
    800047b4:	00021717          	auipc	a4,0x21
    800047b8:	7e470713          	addi	a4,a4,2020 # 80025f98 <log+0x38>
  for (i = 0; i < log.lh.n; i++) {
    800047bc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800047be:	4314                	lw	a3,0(a4)
    800047c0:	04b68d63          	beq	a3,a1,8000481a <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800047c4:	2785                	addiw	a5,a5,1
    800047c6:	0711                	addi	a4,a4,4
    800047c8:	fec79be3          	bne	a5,a2,800047be <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047cc:	0631                	addi	a2,a2,12
    800047ce:	060a                	slli	a2,a2,0x2
    800047d0:	00021797          	auipc	a5,0x21
    800047d4:	79078793          	addi	a5,a5,1936 # 80025f60 <log>
    800047d8:	963e                	add	a2,a2,a5
    800047da:	44dc                	lw	a5,12(s1)
    800047dc:	c61c                	sw	a5,8(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047de:	8526                	mv	a0,s1
    800047e0:	fffff097          	auipc	ra,0xfffff
    800047e4:	d82080e7          	jalr	-638(ra) # 80003562 <bpin>
    log.lh.n++;
    800047e8:	00021717          	auipc	a4,0x21
    800047ec:	77870713          	addi	a4,a4,1912 # 80025f60 <log>
    800047f0:	5b5c                	lw	a5,52(a4)
    800047f2:	2785                	addiw	a5,a5,1
    800047f4:	db5c                	sw	a5,52(a4)
    800047f6:	a83d                	j	80004834 <log_write+0xd2>
    panic("too big a transaction");
    800047f8:	00004517          	auipc	a0,0x4
    800047fc:	eb850513          	addi	a0,a0,-328 # 800086b0 <syscalls+0x1f8>
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	d50080e7          	jalr	-688(ra) # 80000550 <panic>
    panic("log_write outside of trans");
    80004808:	00004517          	auipc	a0,0x4
    8000480c:	ec050513          	addi	a0,a0,-320 # 800086c8 <syscalls+0x210>
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	d40080e7          	jalr	-704(ra) # 80000550 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004818:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000481a:	00c78713          	addi	a4,a5,12
    8000481e:	00271693          	slli	a3,a4,0x2
    80004822:	00021717          	auipc	a4,0x21
    80004826:	73e70713          	addi	a4,a4,1854 # 80025f60 <log>
    8000482a:	9736                	add	a4,a4,a3
    8000482c:	44d4                	lw	a3,12(s1)
    8000482e:	c714                	sw	a3,8(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004830:	faf607e3          	beq	a2,a5,800047de <log_write+0x7c>
  }
  release(&log.lock);
    80004834:	00021517          	auipc	a0,0x21
    80004838:	72c50513          	addi	a0,a0,1836 # 80025f60 <log>
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	586080e7          	jalr	1414(ra) # 80000dc2 <release>
}
    80004844:	60e2                	ld	ra,24(sp)
    80004846:	6442                	ld	s0,16(sp)
    80004848:	64a2                	ld	s1,8(sp)
    8000484a:	6902                	ld	s2,0(sp)
    8000484c:	6105                	addi	sp,sp,32
    8000484e:	8082                	ret

0000000080004850 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004850:	1101                	addi	sp,sp,-32
    80004852:	ec06                	sd	ra,24(sp)
    80004854:	e822                	sd	s0,16(sp)
    80004856:	e426                	sd	s1,8(sp)
    80004858:	e04a                	sd	s2,0(sp)
    8000485a:	1000                	addi	s0,sp,32
    8000485c:	84aa                	mv	s1,a0
    8000485e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004860:	00004597          	auipc	a1,0x4
    80004864:	e8858593          	addi	a1,a1,-376 # 800086e8 <syscalls+0x230>
    80004868:	0521                	addi	a0,a0,8
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	604080e7          	jalr	1540(ra) # 80000e6e <initlock>
  lk->name = name;
    80004872:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    80004876:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000487a:	0204a823          	sw	zero,48(s1)
}
    8000487e:	60e2                	ld	ra,24(sp)
    80004880:	6442                	ld	s0,16(sp)
    80004882:	64a2                	ld	s1,8(sp)
    80004884:	6902                	ld	s2,0(sp)
    80004886:	6105                	addi	sp,sp,32
    80004888:	8082                	ret

000000008000488a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000488a:	1101                	addi	sp,sp,-32
    8000488c:	ec06                	sd	ra,24(sp)
    8000488e:	e822                	sd	s0,16(sp)
    80004890:	e426                	sd	s1,8(sp)
    80004892:	e04a                	sd	s2,0(sp)
    80004894:	1000                	addi	s0,sp,32
    80004896:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004898:	00850913          	addi	s2,a0,8
    8000489c:	854a                	mv	a0,s2
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	454080e7          	jalr	1108(ra) # 80000cf2 <acquire>
  while (lk->locked) {
    800048a6:	409c                	lw	a5,0(s1)
    800048a8:	cb89                	beqz	a5,800048ba <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048aa:	85ca                	mv	a1,s2
    800048ac:	8526                	mv	a0,s1
    800048ae:	ffffe097          	auipc	ra,0xffffe
    800048b2:	c9c080e7          	jalr	-868(ra) # 8000254a <sleep>
  while (lk->locked) {
    800048b6:	409c                	lw	a5,0(s1)
    800048b8:	fbed                	bnez	a5,800048aa <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048ba:	4785                	li	a5,1
    800048bc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800048be:	ffffd097          	auipc	ra,0xffffd
    800048c2:	47c080e7          	jalr	1148(ra) # 80001d3a <myproc>
    800048c6:	413c                	lw	a5,64(a0)
    800048c8:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    800048ca:	854a                	mv	a0,s2
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	4f6080e7          	jalr	1270(ra) # 80000dc2 <release>
}
    800048d4:	60e2                	ld	ra,24(sp)
    800048d6:	6442                	ld	s0,16(sp)
    800048d8:	64a2                	ld	s1,8(sp)
    800048da:	6902                	ld	s2,0(sp)
    800048dc:	6105                	addi	sp,sp,32
    800048de:	8082                	ret

00000000800048e0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048e0:	1101                	addi	sp,sp,-32
    800048e2:	ec06                	sd	ra,24(sp)
    800048e4:	e822                	sd	s0,16(sp)
    800048e6:	e426                	sd	s1,8(sp)
    800048e8:	e04a                	sd	s2,0(sp)
    800048ea:	1000                	addi	s0,sp,32
    800048ec:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048ee:	00850913          	addi	s2,a0,8
    800048f2:	854a                	mv	a0,s2
    800048f4:	ffffc097          	auipc	ra,0xffffc
    800048f8:	3fe080e7          	jalr	1022(ra) # 80000cf2 <acquire>
  lk->locked = 0;
    800048fc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004900:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    80004904:	8526                	mv	a0,s1
    80004906:	ffffe097          	auipc	ra,0xffffe
    8000490a:	dca080e7          	jalr	-566(ra) # 800026d0 <wakeup>
  release(&lk->lk);
    8000490e:	854a                	mv	a0,s2
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	4b2080e7          	jalr	1202(ra) # 80000dc2 <release>
}
    80004918:	60e2                	ld	ra,24(sp)
    8000491a:	6442                	ld	s0,16(sp)
    8000491c:	64a2                	ld	s1,8(sp)
    8000491e:	6902                	ld	s2,0(sp)
    80004920:	6105                	addi	sp,sp,32
    80004922:	8082                	ret

0000000080004924 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004924:	7179                	addi	sp,sp,-48
    80004926:	f406                	sd	ra,40(sp)
    80004928:	f022                	sd	s0,32(sp)
    8000492a:	ec26                	sd	s1,24(sp)
    8000492c:	e84a                	sd	s2,16(sp)
    8000492e:	e44e                	sd	s3,8(sp)
    80004930:	1800                	addi	s0,sp,48
    80004932:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004934:	00850913          	addi	s2,a0,8
    80004938:	854a                	mv	a0,s2
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	3b8080e7          	jalr	952(ra) # 80000cf2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004942:	409c                	lw	a5,0(s1)
    80004944:	ef99                	bnez	a5,80004962 <holdingsleep+0x3e>
    80004946:	4481                	li	s1,0
  release(&lk->lk);
    80004948:	854a                	mv	a0,s2
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	478080e7          	jalr	1144(ra) # 80000dc2 <release>
  return r;
}
    80004952:	8526                	mv	a0,s1
    80004954:	70a2                	ld	ra,40(sp)
    80004956:	7402                	ld	s0,32(sp)
    80004958:	64e2                	ld	s1,24(sp)
    8000495a:	6942                	ld	s2,16(sp)
    8000495c:	69a2                	ld	s3,8(sp)
    8000495e:	6145                	addi	sp,sp,48
    80004960:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004962:	0304a983          	lw	s3,48(s1)
    80004966:	ffffd097          	auipc	ra,0xffffd
    8000496a:	3d4080e7          	jalr	980(ra) # 80001d3a <myproc>
    8000496e:	4124                	lw	s1,64(a0)
    80004970:	413484b3          	sub	s1,s1,s3
    80004974:	0014b493          	seqz	s1,s1
    80004978:	bfc1                	j	80004948 <holdingsleep+0x24>

000000008000497a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000497a:	1141                	addi	sp,sp,-16
    8000497c:	e406                	sd	ra,8(sp)
    8000497e:	e022                	sd	s0,0(sp)
    80004980:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004982:	00004597          	auipc	a1,0x4
    80004986:	d7658593          	addi	a1,a1,-650 # 800086f8 <syscalls+0x240>
    8000498a:	00021517          	auipc	a0,0x21
    8000498e:	72650513          	addi	a0,a0,1830 # 800260b0 <ftable>
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	4dc080e7          	jalr	1244(ra) # 80000e6e <initlock>
}
    8000499a:	60a2                	ld	ra,8(sp)
    8000499c:	6402                	ld	s0,0(sp)
    8000499e:	0141                	addi	sp,sp,16
    800049a0:	8082                	ret

00000000800049a2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049a2:	1101                	addi	sp,sp,-32
    800049a4:	ec06                	sd	ra,24(sp)
    800049a6:	e822                	sd	s0,16(sp)
    800049a8:	e426                	sd	s1,8(sp)
    800049aa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049ac:	00021517          	auipc	a0,0x21
    800049b0:	70450513          	addi	a0,a0,1796 # 800260b0 <ftable>
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	33e080e7          	jalr	830(ra) # 80000cf2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049bc:	00021497          	auipc	s1,0x21
    800049c0:	71448493          	addi	s1,s1,1812 # 800260d0 <ftable+0x20>
    800049c4:	00022717          	auipc	a4,0x22
    800049c8:	6ac70713          	addi	a4,a4,1708 # 80027070 <ftable+0xfc0>
    if(f->ref == 0){
    800049cc:	40dc                	lw	a5,4(s1)
    800049ce:	cf99                	beqz	a5,800049ec <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049d0:	02848493          	addi	s1,s1,40
    800049d4:	fee49ce3          	bne	s1,a4,800049cc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049d8:	00021517          	auipc	a0,0x21
    800049dc:	6d850513          	addi	a0,a0,1752 # 800260b0 <ftable>
    800049e0:	ffffc097          	auipc	ra,0xffffc
    800049e4:	3e2080e7          	jalr	994(ra) # 80000dc2 <release>
  return 0;
    800049e8:	4481                	li	s1,0
    800049ea:	a819                	j	80004a00 <filealloc+0x5e>
      f->ref = 1;
    800049ec:	4785                	li	a5,1
    800049ee:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049f0:	00021517          	auipc	a0,0x21
    800049f4:	6c050513          	addi	a0,a0,1728 # 800260b0 <ftable>
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	3ca080e7          	jalr	970(ra) # 80000dc2 <release>
}
    80004a00:	8526                	mv	a0,s1
    80004a02:	60e2                	ld	ra,24(sp)
    80004a04:	6442                	ld	s0,16(sp)
    80004a06:	64a2                	ld	s1,8(sp)
    80004a08:	6105                	addi	sp,sp,32
    80004a0a:	8082                	ret

0000000080004a0c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a0c:	1101                	addi	sp,sp,-32
    80004a0e:	ec06                	sd	ra,24(sp)
    80004a10:	e822                	sd	s0,16(sp)
    80004a12:	e426                	sd	s1,8(sp)
    80004a14:	1000                	addi	s0,sp,32
    80004a16:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a18:	00021517          	auipc	a0,0x21
    80004a1c:	69850513          	addi	a0,a0,1688 # 800260b0 <ftable>
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	2d2080e7          	jalr	722(ra) # 80000cf2 <acquire>
  if(f->ref < 1)
    80004a28:	40dc                	lw	a5,4(s1)
    80004a2a:	02f05263          	blez	a5,80004a4e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a2e:	2785                	addiw	a5,a5,1
    80004a30:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a32:	00021517          	auipc	a0,0x21
    80004a36:	67e50513          	addi	a0,a0,1662 # 800260b0 <ftable>
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	388080e7          	jalr	904(ra) # 80000dc2 <release>
  return f;
}
    80004a42:	8526                	mv	a0,s1
    80004a44:	60e2                	ld	ra,24(sp)
    80004a46:	6442                	ld	s0,16(sp)
    80004a48:	64a2                	ld	s1,8(sp)
    80004a4a:	6105                	addi	sp,sp,32
    80004a4c:	8082                	ret
    panic("filedup");
    80004a4e:	00004517          	auipc	a0,0x4
    80004a52:	cb250513          	addi	a0,a0,-846 # 80008700 <syscalls+0x248>
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	afa080e7          	jalr	-1286(ra) # 80000550 <panic>

0000000080004a5e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a5e:	7139                	addi	sp,sp,-64
    80004a60:	fc06                	sd	ra,56(sp)
    80004a62:	f822                	sd	s0,48(sp)
    80004a64:	f426                	sd	s1,40(sp)
    80004a66:	f04a                	sd	s2,32(sp)
    80004a68:	ec4e                	sd	s3,24(sp)
    80004a6a:	e852                	sd	s4,16(sp)
    80004a6c:	e456                	sd	s5,8(sp)
    80004a6e:	0080                	addi	s0,sp,64
    80004a70:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a72:	00021517          	auipc	a0,0x21
    80004a76:	63e50513          	addi	a0,a0,1598 # 800260b0 <ftable>
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	278080e7          	jalr	632(ra) # 80000cf2 <acquire>
  if(f->ref < 1)
    80004a82:	40dc                	lw	a5,4(s1)
    80004a84:	06f05163          	blez	a5,80004ae6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a88:	37fd                	addiw	a5,a5,-1
    80004a8a:	0007871b          	sext.w	a4,a5
    80004a8e:	c0dc                	sw	a5,4(s1)
    80004a90:	06e04363          	bgtz	a4,80004af6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a94:	0004a903          	lw	s2,0(s1)
    80004a98:	0094ca83          	lbu	s5,9(s1)
    80004a9c:	0104ba03          	ld	s4,16(s1)
    80004aa0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004aa4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004aa8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004aac:	00021517          	auipc	a0,0x21
    80004ab0:	60450513          	addi	a0,a0,1540 # 800260b0 <ftable>
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	30e080e7          	jalr	782(ra) # 80000dc2 <release>

  if(ff.type == FD_PIPE){
    80004abc:	4785                	li	a5,1
    80004abe:	04f90d63          	beq	s2,a5,80004b18 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ac2:	3979                	addiw	s2,s2,-2
    80004ac4:	4785                	li	a5,1
    80004ac6:	0527e063          	bltu	a5,s2,80004b06 <fileclose+0xa8>
    begin_op();
    80004aca:	00000097          	auipc	ra,0x0
    80004ace:	ac0080e7          	jalr	-1344(ra) # 8000458a <begin_op>
    iput(ff.ip);
    80004ad2:	854e                	mv	a0,s3
    80004ad4:	fffff097          	auipc	ra,0xfffff
    80004ad8:	2a0080e7          	jalr	672(ra) # 80003d74 <iput>
    end_op();
    80004adc:	00000097          	auipc	ra,0x0
    80004ae0:	b2e080e7          	jalr	-1234(ra) # 8000460a <end_op>
    80004ae4:	a00d                	j	80004b06 <fileclose+0xa8>
    panic("fileclose");
    80004ae6:	00004517          	auipc	a0,0x4
    80004aea:	c2250513          	addi	a0,a0,-990 # 80008708 <syscalls+0x250>
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	a62080e7          	jalr	-1438(ra) # 80000550 <panic>
    release(&ftable.lock);
    80004af6:	00021517          	auipc	a0,0x21
    80004afa:	5ba50513          	addi	a0,a0,1466 # 800260b0 <ftable>
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	2c4080e7          	jalr	708(ra) # 80000dc2 <release>
  }
}
    80004b06:	70e2                	ld	ra,56(sp)
    80004b08:	7442                	ld	s0,48(sp)
    80004b0a:	74a2                	ld	s1,40(sp)
    80004b0c:	7902                	ld	s2,32(sp)
    80004b0e:	69e2                	ld	s3,24(sp)
    80004b10:	6a42                	ld	s4,16(sp)
    80004b12:	6aa2                	ld	s5,8(sp)
    80004b14:	6121                	addi	sp,sp,64
    80004b16:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b18:	85d6                	mv	a1,s5
    80004b1a:	8552                	mv	a0,s4
    80004b1c:	00000097          	auipc	ra,0x0
    80004b20:	372080e7          	jalr	882(ra) # 80004e8e <pipeclose>
    80004b24:	b7cd                	j	80004b06 <fileclose+0xa8>

0000000080004b26 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b26:	715d                	addi	sp,sp,-80
    80004b28:	e486                	sd	ra,72(sp)
    80004b2a:	e0a2                	sd	s0,64(sp)
    80004b2c:	fc26                	sd	s1,56(sp)
    80004b2e:	f84a                	sd	s2,48(sp)
    80004b30:	f44e                	sd	s3,40(sp)
    80004b32:	0880                	addi	s0,sp,80
    80004b34:	84aa                	mv	s1,a0
    80004b36:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b38:	ffffd097          	auipc	ra,0xffffd
    80004b3c:	202080e7          	jalr	514(ra) # 80001d3a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b40:	409c                	lw	a5,0(s1)
    80004b42:	37f9                	addiw	a5,a5,-2
    80004b44:	4705                	li	a4,1
    80004b46:	04f76763          	bltu	a4,a5,80004b94 <filestat+0x6e>
    80004b4a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b4c:	6c88                	ld	a0,24(s1)
    80004b4e:	fffff097          	auipc	ra,0xfffff
    80004b52:	06c080e7          	jalr	108(ra) # 80003bba <ilock>
    stati(f->ip, &st);
    80004b56:	fb840593          	addi	a1,s0,-72
    80004b5a:	6c88                	ld	a0,24(s1)
    80004b5c:	fffff097          	auipc	ra,0xfffff
    80004b60:	2e8080e7          	jalr	744(ra) # 80003e44 <stati>
    iunlock(f->ip);
    80004b64:	6c88                	ld	a0,24(s1)
    80004b66:	fffff097          	auipc	ra,0xfffff
    80004b6a:	116080e7          	jalr	278(ra) # 80003c7c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b6e:	46e1                	li	a3,24
    80004b70:	fb840613          	addi	a2,s0,-72
    80004b74:	85ce                	mv	a1,s3
    80004b76:	05893503          	ld	a0,88(s2)
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	eb4080e7          	jalr	-332(ra) # 80001a2e <copyout>
    80004b82:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b86:	60a6                	ld	ra,72(sp)
    80004b88:	6406                	ld	s0,64(sp)
    80004b8a:	74e2                	ld	s1,56(sp)
    80004b8c:	7942                	ld	s2,48(sp)
    80004b8e:	79a2                	ld	s3,40(sp)
    80004b90:	6161                	addi	sp,sp,80
    80004b92:	8082                	ret
  return -1;
    80004b94:	557d                	li	a0,-1
    80004b96:	bfc5                	j	80004b86 <filestat+0x60>

0000000080004b98 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b98:	7179                	addi	sp,sp,-48
    80004b9a:	f406                	sd	ra,40(sp)
    80004b9c:	f022                	sd	s0,32(sp)
    80004b9e:	ec26                	sd	s1,24(sp)
    80004ba0:	e84a                	sd	s2,16(sp)
    80004ba2:	e44e                	sd	s3,8(sp)
    80004ba4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ba6:	00854783          	lbu	a5,8(a0)
    80004baa:	c3d5                	beqz	a5,80004c4e <fileread+0xb6>
    80004bac:	84aa                	mv	s1,a0
    80004bae:	89ae                	mv	s3,a1
    80004bb0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bb2:	411c                	lw	a5,0(a0)
    80004bb4:	4705                	li	a4,1
    80004bb6:	04e78963          	beq	a5,a4,80004c08 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bba:	470d                	li	a4,3
    80004bbc:	04e78d63          	beq	a5,a4,80004c16 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bc0:	4709                	li	a4,2
    80004bc2:	06e79e63          	bne	a5,a4,80004c3e <fileread+0xa6>
    ilock(f->ip);
    80004bc6:	6d08                	ld	a0,24(a0)
    80004bc8:	fffff097          	auipc	ra,0xfffff
    80004bcc:	ff2080e7          	jalr	-14(ra) # 80003bba <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004bd0:	874a                	mv	a4,s2
    80004bd2:	5094                	lw	a3,32(s1)
    80004bd4:	864e                	mv	a2,s3
    80004bd6:	4585                	li	a1,1
    80004bd8:	6c88                	ld	a0,24(s1)
    80004bda:	fffff097          	auipc	ra,0xfffff
    80004bde:	294080e7          	jalr	660(ra) # 80003e6e <readi>
    80004be2:	892a                	mv	s2,a0
    80004be4:	00a05563          	blez	a0,80004bee <fileread+0x56>
      f->off += r;
    80004be8:	509c                	lw	a5,32(s1)
    80004bea:	9fa9                	addw	a5,a5,a0
    80004bec:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bee:	6c88                	ld	a0,24(s1)
    80004bf0:	fffff097          	auipc	ra,0xfffff
    80004bf4:	08c080e7          	jalr	140(ra) # 80003c7c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bf8:	854a                	mv	a0,s2
    80004bfa:	70a2                	ld	ra,40(sp)
    80004bfc:	7402                	ld	s0,32(sp)
    80004bfe:	64e2                	ld	s1,24(sp)
    80004c00:	6942                	ld	s2,16(sp)
    80004c02:	69a2                	ld	s3,8(sp)
    80004c04:	6145                	addi	sp,sp,48
    80004c06:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c08:	6908                	ld	a0,16(a0)
    80004c0a:	00000097          	auipc	ra,0x0
    80004c0e:	422080e7          	jalr	1058(ra) # 8000502c <piperead>
    80004c12:	892a                	mv	s2,a0
    80004c14:	b7d5                	j	80004bf8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c16:	02451783          	lh	a5,36(a0)
    80004c1a:	03079693          	slli	a3,a5,0x30
    80004c1e:	92c1                	srli	a3,a3,0x30
    80004c20:	4725                	li	a4,9
    80004c22:	02d76863          	bltu	a4,a3,80004c52 <fileread+0xba>
    80004c26:	0792                	slli	a5,a5,0x4
    80004c28:	00021717          	auipc	a4,0x21
    80004c2c:	3e870713          	addi	a4,a4,1000 # 80026010 <devsw>
    80004c30:	97ba                	add	a5,a5,a4
    80004c32:	639c                	ld	a5,0(a5)
    80004c34:	c38d                	beqz	a5,80004c56 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c36:	4505                	li	a0,1
    80004c38:	9782                	jalr	a5
    80004c3a:	892a                	mv	s2,a0
    80004c3c:	bf75                	j	80004bf8 <fileread+0x60>
    panic("fileread");
    80004c3e:	00004517          	auipc	a0,0x4
    80004c42:	ada50513          	addi	a0,a0,-1318 # 80008718 <syscalls+0x260>
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	90a080e7          	jalr	-1782(ra) # 80000550 <panic>
    return -1;
    80004c4e:	597d                	li	s2,-1
    80004c50:	b765                	j	80004bf8 <fileread+0x60>
      return -1;
    80004c52:	597d                	li	s2,-1
    80004c54:	b755                	j	80004bf8 <fileread+0x60>
    80004c56:	597d                	li	s2,-1
    80004c58:	b745                	j	80004bf8 <fileread+0x60>

0000000080004c5a <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004c5a:	00954783          	lbu	a5,9(a0)
    80004c5e:	14078563          	beqz	a5,80004da8 <filewrite+0x14e>
{
    80004c62:	715d                	addi	sp,sp,-80
    80004c64:	e486                	sd	ra,72(sp)
    80004c66:	e0a2                	sd	s0,64(sp)
    80004c68:	fc26                	sd	s1,56(sp)
    80004c6a:	f84a                	sd	s2,48(sp)
    80004c6c:	f44e                	sd	s3,40(sp)
    80004c6e:	f052                	sd	s4,32(sp)
    80004c70:	ec56                	sd	s5,24(sp)
    80004c72:	e85a                	sd	s6,16(sp)
    80004c74:	e45e                	sd	s7,8(sp)
    80004c76:	e062                	sd	s8,0(sp)
    80004c78:	0880                	addi	s0,sp,80
    80004c7a:	892a                	mv	s2,a0
    80004c7c:	8aae                	mv	s5,a1
    80004c7e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c80:	411c                	lw	a5,0(a0)
    80004c82:	4705                	li	a4,1
    80004c84:	02e78263          	beq	a5,a4,80004ca8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c88:	470d                	li	a4,3
    80004c8a:	02e78563          	beq	a5,a4,80004cb4 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c8e:	4709                	li	a4,2
    80004c90:	10e79463          	bne	a5,a4,80004d98 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c94:	0ec05e63          	blez	a2,80004d90 <filewrite+0x136>
    int i = 0;
    80004c98:	4981                	li	s3,0
    80004c9a:	6b05                	lui	s6,0x1
    80004c9c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ca0:	6b85                	lui	s7,0x1
    80004ca2:	c00b8b9b          	addiw	s7,s7,-1024
    80004ca6:	a851                	j	80004d3a <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004ca8:	6908                	ld	a0,16(a0)
    80004caa:	00000097          	auipc	ra,0x0
    80004cae:	25e080e7          	jalr	606(ra) # 80004f08 <pipewrite>
    80004cb2:	a85d                	j	80004d68 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004cb4:	02451783          	lh	a5,36(a0)
    80004cb8:	03079693          	slli	a3,a5,0x30
    80004cbc:	92c1                	srli	a3,a3,0x30
    80004cbe:	4725                	li	a4,9
    80004cc0:	0ed76663          	bltu	a4,a3,80004dac <filewrite+0x152>
    80004cc4:	0792                	slli	a5,a5,0x4
    80004cc6:	00021717          	auipc	a4,0x21
    80004cca:	34a70713          	addi	a4,a4,842 # 80026010 <devsw>
    80004cce:	97ba                	add	a5,a5,a4
    80004cd0:	679c                	ld	a5,8(a5)
    80004cd2:	cff9                	beqz	a5,80004db0 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004cd4:	4505                	li	a0,1
    80004cd6:	9782                	jalr	a5
    80004cd8:	a841                	j	80004d68 <filewrite+0x10e>
    80004cda:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004cde:	00000097          	auipc	ra,0x0
    80004ce2:	8ac080e7          	jalr	-1876(ra) # 8000458a <begin_op>
      ilock(f->ip);
    80004ce6:	01893503          	ld	a0,24(s2)
    80004cea:	fffff097          	auipc	ra,0xfffff
    80004cee:	ed0080e7          	jalr	-304(ra) # 80003bba <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cf2:	8762                	mv	a4,s8
    80004cf4:	02092683          	lw	a3,32(s2)
    80004cf8:	01598633          	add	a2,s3,s5
    80004cfc:	4585                	li	a1,1
    80004cfe:	01893503          	ld	a0,24(s2)
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	264080e7          	jalr	612(ra) # 80003f66 <writei>
    80004d0a:	84aa                	mv	s1,a0
    80004d0c:	02a05f63          	blez	a0,80004d4a <filewrite+0xf0>
        f->off += r;
    80004d10:	02092783          	lw	a5,32(s2)
    80004d14:	9fa9                	addw	a5,a5,a0
    80004d16:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d1a:	01893503          	ld	a0,24(s2)
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	f5e080e7          	jalr	-162(ra) # 80003c7c <iunlock>
      end_op();
    80004d26:	00000097          	auipc	ra,0x0
    80004d2a:	8e4080e7          	jalr	-1820(ra) # 8000460a <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004d2e:	049c1963          	bne	s8,s1,80004d80 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004d32:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d36:	0349d663          	bge	s3,s4,80004d62 <filewrite+0x108>
      int n1 = n - i;
    80004d3a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d3e:	84be                	mv	s1,a5
    80004d40:	2781                	sext.w	a5,a5
    80004d42:	f8fb5ce3          	bge	s6,a5,80004cda <filewrite+0x80>
    80004d46:	84de                	mv	s1,s7
    80004d48:	bf49                	j	80004cda <filewrite+0x80>
      iunlock(f->ip);
    80004d4a:	01893503          	ld	a0,24(s2)
    80004d4e:	fffff097          	auipc	ra,0xfffff
    80004d52:	f2e080e7          	jalr	-210(ra) # 80003c7c <iunlock>
      end_op();
    80004d56:	00000097          	auipc	ra,0x0
    80004d5a:	8b4080e7          	jalr	-1868(ra) # 8000460a <end_op>
      if(r < 0)
    80004d5e:	fc04d8e3          	bgez	s1,80004d2e <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004d62:	8552                	mv	a0,s4
    80004d64:	033a1863          	bne	s4,s3,80004d94 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d68:	60a6                	ld	ra,72(sp)
    80004d6a:	6406                	ld	s0,64(sp)
    80004d6c:	74e2                	ld	s1,56(sp)
    80004d6e:	7942                	ld	s2,48(sp)
    80004d70:	79a2                	ld	s3,40(sp)
    80004d72:	7a02                	ld	s4,32(sp)
    80004d74:	6ae2                	ld	s5,24(sp)
    80004d76:	6b42                	ld	s6,16(sp)
    80004d78:	6ba2                	ld	s7,8(sp)
    80004d7a:	6c02                	ld	s8,0(sp)
    80004d7c:	6161                	addi	sp,sp,80
    80004d7e:	8082                	ret
        panic("short filewrite");
    80004d80:	00004517          	auipc	a0,0x4
    80004d84:	9a850513          	addi	a0,a0,-1624 # 80008728 <syscalls+0x270>
    80004d88:	ffffb097          	auipc	ra,0xffffb
    80004d8c:	7c8080e7          	jalr	1992(ra) # 80000550 <panic>
    int i = 0;
    80004d90:	4981                	li	s3,0
    80004d92:	bfc1                	j	80004d62 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004d94:	557d                	li	a0,-1
    80004d96:	bfc9                	j	80004d68 <filewrite+0x10e>
    panic("filewrite");
    80004d98:	00004517          	auipc	a0,0x4
    80004d9c:	9a050513          	addi	a0,a0,-1632 # 80008738 <syscalls+0x280>
    80004da0:	ffffb097          	auipc	ra,0xffffb
    80004da4:	7b0080e7          	jalr	1968(ra) # 80000550 <panic>
    return -1;
    80004da8:	557d                	li	a0,-1
}
    80004daa:	8082                	ret
      return -1;
    80004dac:	557d                	li	a0,-1
    80004dae:	bf6d                	j	80004d68 <filewrite+0x10e>
    80004db0:	557d                	li	a0,-1
    80004db2:	bf5d                	j	80004d68 <filewrite+0x10e>

0000000080004db4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004db4:	7179                	addi	sp,sp,-48
    80004db6:	f406                	sd	ra,40(sp)
    80004db8:	f022                	sd	s0,32(sp)
    80004dba:	ec26                	sd	s1,24(sp)
    80004dbc:	e84a                	sd	s2,16(sp)
    80004dbe:	e44e                	sd	s3,8(sp)
    80004dc0:	e052                	sd	s4,0(sp)
    80004dc2:	1800                	addi	s0,sp,48
    80004dc4:	84aa                	mv	s1,a0
    80004dc6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004dc8:	0005b023          	sd	zero,0(a1)
    80004dcc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004dd0:	00000097          	auipc	ra,0x0
    80004dd4:	bd2080e7          	jalr	-1070(ra) # 800049a2 <filealloc>
    80004dd8:	e088                	sd	a0,0(s1)
    80004dda:	c551                	beqz	a0,80004e66 <pipealloc+0xb2>
    80004ddc:	00000097          	auipc	ra,0x0
    80004de0:	bc6080e7          	jalr	-1082(ra) # 800049a2 <filealloc>
    80004de4:	00aa3023          	sd	a0,0(s4)
    80004de8:	c92d                	beqz	a0,80004e5a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004dea:	ffffc097          	auipc	ra,0xffffc
    80004dee:	d90080e7          	jalr	-624(ra) # 80000b7a <kalloc>
    80004df2:	892a                	mv	s2,a0
    80004df4:	c125                	beqz	a0,80004e54 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004df6:	4985                	li	s3,1
    80004df8:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004dfc:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004e00:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004e04:	22052023          	sw	zero,544(a0)
  initlock(&pi->lock, "pipe");
    80004e08:	00004597          	auipc	a1,0x4
    80004e0c:	94058593          	addi	a1,a1,-1728 # 80008748 <syscalls+0x290>
    80004e10:	ffffc097          	auipc	ra,0xffffc
    80004e14:	05e080e7          	jalr	94(ra) # 80000e6e <initlock>
  (*f0)->type = FD_PIPE;
    80004e18:	609c                	ld	a5,0(s1)
    80004e1a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e1e:	609c                	ld	a5,0(s1)
    80004e20:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e24:	609c                	ld	a5,0(s1)
    80004e26:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e2a:	609c                	ld	a5,0(s1)
    80004e2c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e30:	000a3783          	ld	a5,0(s4)
    80004e34:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e38:	000a3783          	ld	a5,0(s4)
    80004e3c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e40:	000a3783          	ld	a5,0(s4)
    80004e44:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e48:	000a3783          	ld	a5,0(s4)
    80004e4c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e50:	4501                	li	a0,0
    80004e52:	a025                	j	80004e7a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e54:	6088                	ld	a0,0(s1)
    80004e56:	e501                	bnez	a0,80004e5e <pipealloc+0xaa>
    80004e58:	a039                	j	80004e66 <pipealloc+0xb2>
    80004e5a:	6088                	ld	a0,0(s1)
    80004e5c:	c51d                	beqz	a0,80004e8a <pipealloc+0xd6>
    fileclose(*f0);
    80004e5e:	00000097          	auipc	ra,0x0
    80004e62:	c00080e7          	jalr	-1024(ra) # 80004a5e <fileclose>
  if(*f1)
    80004e66:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e6a:	557d                	li	a0,-1
  if(*f1)
    80004e6c:	c799                	beqz	a5,80004e7a <pipealloc+0xc6>
    fileclose(*f1);
    80004e6e:	853e                	mv	a0,a5
    80004e70:	00000097          	auipc	ra,0x0
    80004e74:	bee080e7          	jalr	-1042(ra) # 80004a5e <fileclose>
  return -1;
    80004e78:	557d                	li	a0,-1
}
    80004e7a:	70a2                	ld	ra,40(sp)
    80004e7c:	7402                	ld	s0,32(sp)
    80004e7e:	64e2                	ld	s1,24(sp)
    80004e80:	6942                	ld	s2,16(sp)
    80004e82:	69a2                	ld	s3,8(sp)
    80004e84:	6a02                	ld	s4,0(sp)
    80004e86:	6145                	addi	sp,sp,48
    80004e88:	8082                	ret
  return -1;
    80004e8a:	557d                	li	a0,-1
    80004e8c:	b7fd                	j	80004e7a <pipealloc+0xc6>

0000000080004e8e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e8e:	1101                	addi	sp,sp,-32
    80004e90:	ec06                	sd	ra,24(sp)
    80004e92:	e822                	sd	s0,16(sp)
    80004e94:	e426                	sd	s1,8(sp)
    80004e96:	e04a                	sd	s2,0(sp)
    80004e98:	1000                	addi	s0,sp,32
    80004e9a:	84aa                	mv	s1,a0
    80004e9c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	e54080e7          	jalr	-428(ra) # 80000cf2 <acquire>
  if(writable){
    80004ea6:	04090263          	beqz	s2,80004eea <pipeclose+0x5c>
    pi->writeopen = 0;
    80004eaa:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004eae:	22048513          	addi	a0,s1,544
    80004eb2:	ffffe097          	auipc	ra,0xffffe
    80004eb6:	81e080e7          	jalr	-2018(ra) # 800026d0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004eba:	2284b783          	ld	a5,552(s1)
    80004ebe:	ef9d                	bnez	a5,80004efc <pipeclose+0x6e>
    release(&pi->lock);
    80004ec0:	8526                	mv	a0,s1
    80004ec2:	ffffc097          	auipc	ra,0xffffc
    80004ec6:	f00080e7          	jalr	-256(ra) # 80000dc2 <release>
#ifdef LAB_LOCK
    freelock(&pi->lock);
    80004eca:	8526                	mv	a0,s1
    80004ecc:	ffffc097          	auipc	ra,0xffffc
    80004ed0:	f3e080e7          	jalr	-194(ra) # 80000e0a <freelock>
#endif    
    kfree((char*)pi);
    80004ed4:	8526                	mv	a0,s1
    80004ed6:	ffffc097          	auipc	ra,0xffffc
    80004eda:	b56080e7          	jalr	-1194(ra) # 80000a2c <kfree>
  } else
    release(&pi->lock);
}
    80004ede:	60e2                	ld	ra,24(sp)
    80004ee0:	6442                	ld	s0,16(sp)
    80004ee2:	64a2                	ld	s1,8(sp)
    80004ee4:	6902                	ld	s2,0(sp)
    80004ee6:	6105                	addi	sp,sp,32
    80004ee8:	8082                	ret
    pi->readopen = 0;
    80004eea:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004eee:	22448513          	addi	a0,s1,548
    80004ef2:	ffffd097          	auipc	ra,0xffffd
    80004ef6:	7de080e7          	jalr	2014(ra) # 800026d0 <wakeup>
    80004efa:	b7c1                	j	80004eba <pipeclose+0x2c>
    release(&pi->lock);
    80004efc:	8526                	mv	a0,s1
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	ec4080e7          	jalr	-316(ra) # 80000dc2 <release>
}
    80004f06:	bfe1                	j	80004ede <pipeclose+0x50>

0000000080004f08 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f08:	7119                	addi	sp,sp,-128
    80004f0a:	fc86                	sd	ra,120(sp)
    80004f0c:	f8a2                	sd	s0,112(sp)
    80004f0e:	f4a6                	sd	s1,104(sp)
    80004f10:	f0ca                	sd	s2,96(sp)
    80004f12:	ecce                	sd	s3,88(sp)
    80004f14:	e8d2                	sd	s4,80(sp)
    80004f16:	e4d6                	sd	s5,72(sp)
    80004f18:	e0da                	sd	s6,64(sp)
    80004f1a:	fc5e                	sd	s7,56(sp)
    80004f1c:	f862                	sd	s8,48(sp)
    80004f1e:	f466                	sd	s9,40(sp)
    80004f20:	f06a                	sd	s10,32(sp)
    80004f22:	ec6e                	sd	s11,24(sp)
    80004f24:	0100                	addi	s0,sp,128
    80004f26:	84aa                	mv	s1,a0
    80004f28:	8cae                	mv	s9,a1
    80004f2a:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004f2c:	ffffd097          	auipc	ra,0xffffd
    80004f30:	e0e080e7          	jalr	-498(ra) # 80001d3a <myproc>
    80004f34:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004f36:	8526                	mv	a0,s1
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	dba080e7          	jalr	-582(ra) # 80000cf2 <acquire>
  for(i = 0; i < n; i++){
    80004f40:	0d605963          	blez	s6,80005012 <pipewrite+0x10a>
    80004f44:	89a6                	mv	s3,s1
    80004f46:	3b7d                	addiw	s6,s6,-1
    80004f48:	1b02                	slli	s6,s6,0x20
    80004f4a:	020b5b13          	srli	s6,s6,0x20
    80004f4e:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004f50:	22048a93          	addi	s5,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004f54:	22448a13          	addi	s4,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f58:	5dfd                	li	s11,-1
    80004f5a:	000b8d1b          	sext.w	s10,s7
    80004f5e:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004f60:	2204a783          	lw	a5,544(s1)
    80004f64:	2244a703          	lw	a4,548(s1)
    80004f68:	2007879b          	addiw	a5,a5,512
    80004f6c:	02f71b63          	bne	a4,a5,80004fa2 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004f70:	2284a783          	lw	a5,552(s1)
    80004f74:	cbad                	beqz	a5,80004fe6 <pipewrite+0xde>
    80004f76:	03892783          	lw	a5,56(s2)
    80004f7a:	e7b5                	bnez	a5,80004fe6 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004f7c:	8556                	mv	a0,s5
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	752080e7          	jalr	1874(ra) # 800026d0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f86:	85ce                	mv	a1,s3
    80004f88:	8552                	mv	a0,s4
    80004f8a:	ffffd097          	auipc	ra,0xffffd
    80004f8e:	5c0080e7          	jalr	1472(ra) # 8000254a <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004f92:	2204a783          	lw	a5,544(s1)
    80004f96:	2244a703          	lw	a4,548(s1)
    80004f9a:	2007879b          	addiw	a5,a5,512
    80004f9e:	fcf709e3          	beq	a4,a5,80004f70 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fa2:	4685                	li	a3,1
    80004fa4:	019b8633          	add	a2,s7,s9
    80004fa8:	f8f40593          	addi	a1,s0,-113
    80004fac:	05893503          	ld	a0,88(s2)
    80004fb0:	ffffd097          	auipc	ra,0xffffd
    80004fb4:	b0a080e7          	jalr	-1270(ra) # 80001aba <copyin>
    80004fb8:	05b50e63          	beq	a0,s11,80005014 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004fbc:	2244a783          	lw	a5,548(s1)
    80004fc0:	0017871b          	addiw	a4,a5,1
    80004fc4:	22e4a223          	sw	a4,548(s1)
    80004fc8:	1ff7f793          	andi	a5,a5,511
    80004fcc:	97a6                	add	a5,a5,s1
    80004fce:	f8f44703          	lbu	a4,-113(s0)
    80004fd2:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80004fd6:	001d0c1b          	addiw	s8,s10,1
    80004fda:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004fde:	036b8b63          	beq	s7,s6,80005014 <pipewrite+0x10c>
    80004fe2:	8bbe                	mv	s7,a5
    80004fe4:	bf9d                	j	80004f5a <pipewrite+0x52>
        release(&pi->lock);
    80004fe6:	8526                	mv	a0,s1
    80004fe8:	ffffc097          	auipc	ra,0xffffc
    80004fec:	dda080e7          	jalr	-550(ra) # 80000dc2 <release>
        return -1;
    80004ff0:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004ff2:	8562                	mv	a0,s8
    80004ff4:	70e6                	ld	ra,120(sp)
    80004ff6:	7446                	ld	s0,112(sp)
    80004ff8:	74a6                	ld	s1,104(sp)
    80004ffa:	7906                	ld	s2,96(sp)
    80004ffc:	69e6                	ld	s3,88(sp)
    80004ffe:	6a46                	ld	s4,80(sp)
    80005000:	6aa6                	ld	s5,72(sp)
    80005002:	6b06                	ld	s6,64(sp)
    80005004:	7be2                	ld	s7,56(sp)
    80005006:	7c42                	ld	s8,48(sp)
    80005008:	7ca2                	ld	s9,40(sp)
    8000500a:	7d02                	ld	s10,32(sp)
    8000500c:	6de2                	ld	s11,24(sp)
    8000500e:	6109                	addi	sp,sp,128
    80005010:	8082                	ret
  for(i = 0; i < n; i++){
    80005012:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80005014:	22048513          	addi	a0,s1,544
    80005018:	ffffd097          	auipc	ra,0xffffd
    8000501c:	6b8080e7          	jalr	1720(ra) # 800026d0 <wakeup>
  release(&pi->lock);
    80005020:	8526                	mv	a0,s1
    80005022:	ffffc097          	auipc	ra,0xffffc
    80005026:	da0080e7          	jalr	-608(ra) # 80000dc2 <release>
  return i;
    8000502a:	b7e1                	j	80004ff2 <pipewrite+0xea>

000000008000502c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000502c:	715d                	addi	sp,sp,-80
    8000502e:	e486                	sd	ra,72(sp)
    80005030:	e0a2                	sd	s0,64(sp)
    80005032:	fc26                	sd	s1,56(sp)
    80005034:	f84a                	sd	s2,48(sp)
    80005036:	f44e                	sd	s3,40(sp)
    80005038:	f052                	sd	s4,32(sp)
    8000503a:	ec56                	sd	s5,24(sp)
    8000503c:	e85a                	sd	s6,16(sp)
    8000503e:	0880                	addi	s0,sp,80
    80005040:	84aa                	mv	s1,a0
    80005042:	892e                	mv	s2,a1
    80005044:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005046:	ffffd097          	auipc	ra,0xffffd
    8000504a:	cf4080e7          	jalr	-780(ra) # 80001d3a <myproc>
    8000504e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005050:	8b26                	mv	s6,s1
    80005052:	8526                	mv	a0,s1
    80005054:	ffffc097          	auipc	ra,0xffffc
    80005058:	c9e080e7          	jalr	-866(ra) # 80000cf2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000505c:	2204a703          	lw	a4,544(s1)
    80005060:	2244a783          	lw	a5,548(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005064:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005068:	02f71463          	bne	a4,a5,80005090 <piperead+0x64>
    8000506c:	22c4a783          	lw	a5,556(s1)
    80005070:	c385                	beqz	a5,80005090 <piperead+0x64>
    if(pr->killed){
    80005072:	038a2783          	lw	a5,56(s4)
    80005076:	ebc1                	bnez	a5,80005106 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005078:	85da                	mv	a1,s6
    8000507a:	854e                	mv	a0,s3
    8000507c:	ffffd097          	auipc	ra,0xffffd
    80005080:	4ce080e7          	jalr	1230(ra) # 8000254a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005084:	2204a703          	lw	a4,544(s1)
    80005088:	2244a783          	lw	a5,548(s1)
    8000508c:	fef700e3          	beq	a4,a5,8000506c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005090:	09505263          	blez	s5,80005114 <piperead+0xe8>
    80005094:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005096:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005098:	2204a783          	lw	a5,544(s1)
    8000509c:	2244a703          	lw	a4,548(s1)
    800050a0:	02f70d63          	beq	a4,a5,800050da <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050a4:	0017871b          	addiw	a4,a5,1
    800050a8:	22e4a023          	sw	a4,544(s1)
    800050ac:	1ff7f793          	andi	a5,a5,511
    800050b0:	97a6                	add	a5,a5,s1
    800050b2:	0207c783          	lbu	a5,32(a5)
    800050b6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050ba:	4685                	li	a3,1
    800050bc:	fbf40613          	addi	a2,s0,-65
    800050c0:	85ca                	mv	a1,s2
    800050c2:	058a3503          	ld	a0,88(s4)
    800050c6:	ffffd097          	auipc	ra,0xffffd
    800050ca:	968080e7          	jalr	-1688(ra) # 80001a2e <copyout>
    800050ce:	01650663          	beq	a0,s6,800050da <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050d2:	2985                	addiw	s3,s3,1
    800050d4:	0905                	addi	s2,s2,1
    800050d6:	fd3a91e3          	bne	s5,s3,80005098 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050da:	22448513          	addi	a0,s1,548
    800050de:	ffffd097          	auipc	ra,0xffffd
    800050e2:	5f2080e7          	jalr	1522(ra) # 800026d0 <wakeup>
  release(&pi->lock);
    800050e6:	8526                	mv	a0,s1
    800050e8:	ffffc097          	auipc	ra,0xffffc
    800050ec:	cda080e7          	jalr	-806(ra) # 80000dc2 <release>
  return i;
}
    800050f0:	854e                	mv	a0,s3
    800050f2:	60a6                	ld	ra,72(sp)
    800050f4:	6406                	ld	s0,64(sp)
    800050f6:	74e2                	ld	s1,56(sp)
    800050f8:	7942                	ld	s2,48(sp)
    800050fa:	79a2                	ld	s3,40(sp)
    800050fc:	7a02                	ld	s4,32(sp)
    800050fe:	6ae2                	ld	s5,24(sp)
    80005100:	6b42                	ld	s6,16(sp)
    80005102:	6161                	addi	sp,sp,80
    80005104:	8082                	ret
      release(&pi->lock);
    80005106:	8526                	mv	a0,s1
    80005108:	ffffc097          	auipc	ra,0xffffc
    8000510c:	cba080e7          	jalr	-838(ra) # 80000dc2 <release>
      return -1;
    80005110:	59fd                	li	s3,-1
    80005112:	bff9                	j	800050f0 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005114:	4981                	li	s3,0
    80005116:	b7d1                	j	800050da <piperead+0xae>

0000000080005118 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005118:	df010113          	addi	sp,sp,-528
    8000511c:	20113423          	sd	ra,520(sp)
    80005120:	20813023          	sd	s0,512(sp)
    80005124:	ffa6                	sd	s1,504(sp)
    80005126:	fbca                	sd	s2,496(sp)
    80005128:	f7ce                	sd	s3,488(sp)
    8000512a:	f3d2                	sd	s4,480(sp)
    8000512c:	efd6                	sd	s5,472(sp)
    8000512e:	ebda                	sd	s6,464(sp)
    80005130:	e7de                	sd	s7,456(sp)
    80005132:	e3e2                	sd	s8,448(sp)
    80005134:	ff66                	sd	s9,440(sp)
    80005136:	fb6a                	sd	s10,432(sp)
    80005138:	f76e                	sd	s11,424(sp)
    8000513a:	0c00                	addi	s0,sp,528
    8000513c:	84aa                	mv	s1,a0
    8000513e:	dea43c23          	sd	a0,-520(s0)
    80005142:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005146:	ffffd097          	auipc	ra,0xffffd
    8000514a:	bf4080e7          	jalr	-1036(ra) # 80001d3a <myproc>
    8000514e:	892a                	mv	s2,a0

  begin_op();
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	43a080e7          	jalr	1082(ra) # 8000458a <begin_op>

  if((ip = namei(path)) == 0){
    80005158:	8526                	mv	a0,s1
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	214080e7          	jalr	532(ra) # 8000436e <namei>
    80005162:	c92d                	beqz	a0,800051d4 <exec+0xbc>
    80005164:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005166:	fffff097          	auipc	ra,0xfffff
    8000516a:	a54080e7          	jalr	-1452(ra) # 80003bba <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000516e:	04000713          	li	a4,64
    80005172:	4681                	li	a3,0
    80005174:	e4840613          	addi	a2,s0,-440
    80005178:	4581                	li	a1,0
    8000517a:	8526                	mv	a0,s1
    8000517c:	fffff097          	auipc	ra,0xfffff
    80005180:	cf2080e7          	jalr	-782(ra) # 80003e6e <readi>
    80005184:	04000793          	li	a5,64
    80005188:	00f51a63          	bne	a0,a5,8000519c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000518c:	e4842703          	lw	a4,-440(s0)
    80005190:	464c47b7          	lui	a5,0x464c4
    80005194:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005198:	04f70463          	beq	a4,a5,800051e0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000519c:	8526                	mv	a0,s1
    8000519e:	fffff097          	auipc	ra,0xfffff
    800051a2:	c7e080e7          	jalr	-898(ra) # 80003e1c <iunlockput>
    end_op();
    800051a6:	fffff097          	auipc	ra,0xfffff
    800051aa:	464080e7          	jalr	1124(ra) # 8000460a <end_op>
  }
  return -1;
    800051ae:	557d                	li	a0,-1
}
    800051b0:	20813083          	ld	ra,520(sp)
    800051b4:	20013403          	ld	s0,512(sp)
    800051b8:	74fe                	ld	s1,504(sp)
    800051ba:	795e                	ld	s2,496(sp)
    800051bc:	79be                	ld	s3,488(sp)
    800051be:	7a1e                	ld	s4,480(sp)
    800051c0:	6afe                	ld	s5,472(sp)
    800051c2:	6b5e                	ld	s6,464(sp)
    800051c4:	6bbe                	ld	s7,456(sp)
    800051c6:	6c1e                	ld	s8,448(sp)
    800051c8:	7cfa                	ld	s9,440(sp)
    800051ca:	7d5a                	ld	s10,432(sp)
    800051cc:	7dba                	ld	s11,424(sp)
    800051ce:	21010113          	addi	sp,sp,528
    800051d2:	8082                	ret
    end_op();
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	436080e7          	jalr	1078(ra) # 8000460a <end_op>
    return -1;
    800051dc:	557d                	li	a0,-1
    800051de:	bfc9                	j	800051b0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800051e0:	854a                	mv	a0,s2
    800051e2:	ffffd097          	auipc	ra,0xffffd
    800051e6:	c1c080e7          	jalr	-996(ra) # 80001dfe <proc_pagetable>
    800051ea:	8baa                	mv	s7,a0
    800051ec:	d945                	beqz	a0,8000519c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051ee:	e6842983          	lw	s3,-408(s0)
    800051f2:	e8045783          	lhu	a5,-384(s0)
    800051f6:	c7ad                	beqz	a5,80005260 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800051f8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051fa:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    800051fc:	6c85                	lui	s9,0x1
    800051fe:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005202:	def43823          	sd	a5,-528(s0)
    80005206:	a42d                	j	80005430 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005208:	00003517          	auipc	a0,0x3
    8000520c:	54850513          	addi	a0,a0,1352 # 80008750 <syscalls+0x298>
    80005210:	ffffb097          	auipc	ra,0xffffb
    80005214:	340080e7          	jalr	832(ra) # 80000550 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005218:	8756                	mv	a4,s5
    8000521a:	012d86bb          	addw	a3,s11,s2
    8000521e:	4581                	li	a1,0
    80005220:	8526                	mv	a0,s1
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	c4c080e7          	jalr	-948(ra) # 80003e6e <readi>
    8000522a:	2501                	sext.w	a0,a0
    8000522c:	1aaa9963          	bne	s5,a0,800053de <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005230:	6785                	lui	a5,0x1
    80005232:	0127893b          	addw	s2,a5,s2
    80005236:	77fd                	lui	a5,0xfffff
    80005238:	01478a3b          	addw	s4,a5,s4
    8000523c:	1f897163          	bgeu	s2,s8,8000541e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005240:	02091593          	slli	a1,s2,0x20
    80005244:	9181                	srli	a1,a1,0x20
    80005246:	95ea                	add	a1,a1,s10
    80005248:	855e                	mv	a0,s7
    8000524a:	ffffc097          	auipc	ra,0xffffc
    8000524e:	222080e7          	jalr	546(ra) # 8000146c <walkaddr>
    80005252:	862a                	mv	a2,a0
    if(pa == 0)
    80005254:	d955                	beqz	a0,80005208 <exec+0xf0>
      n = PGSIZE;
    80005256:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005258:	fd9a70e3          	bgeu	s4,s9,80005218 <exec+0x100>
      n = sz - i;
    8000525c:	8ad2                	mv	s5,s4
    8000525e:	bf6d                	j	80005218 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005260:	4901                	li	s2,0
  iunlockput(ip);
    80005262:	8526                	mv	a0,s1
    80005264:	fffff097          	auipc	ra,0xfffff
    80005268:	bb8080e7          	jalr	-1096(ra) # 80003e1c <iunlockput>
  end_op();
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	39e080e7          	jalr	926(ra) # 8000460a <end_op>
  p = myproc();
    80005274:	ffffd097          	auipc	ra,0xffffd
    80005278:	ac6080e7          	jalr	-1338(ra) # 80001d3a <myproc>
    8000527c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000527e:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80005282:	6785                	lui	a5,0x1
    80005284:	17fd                	addi	a5,a5,-1
    80005286:	993e                	add	s2,s2,a5
    80005288:	757d                	lui	a0,0xfffff
    8000528a:	00a977b3          	and	a5,s2,a0
    8000528e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005292:	6609                	lui	a2,0x2
    80005294:	963e                	add	a2,a2,a5
    80005296:	85be                	mv	a1,a5
    80005298:	855e                	mv	a0,s7
    8000529a:	ffffc097          	auipc	ra,0xffffc
    8000529e:	544080e7          	jalr	1348(ra) # 800017de <uvmalloc>
    800052a2:	8b2a                	mv	s6,a0
  ip = 0;
    800052a4:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052a6:	12050c63          	beqz	a0,800053de <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052aa:	75f9                	lui	a1,0xffffe
    800052ac:	95aa                	add	a1,a1,a0
    800052ae:	855e                	mv	a0,s7
    800052b0:	ffffc097          	auipc	ra,0xffffc
    800052b4:	74c080e7          	jalr	1868(ra) # 800019fc <uvmclear>
  stackbase = sp - PGSIZE;
    800052b8:	7c7d                	lui	s8,0xfffff
    800052ba:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800052bc:	e0043783          	ld	a5,-512(s0)
    800052c0:	6388                	ld	a0,0(a5)
    800052c2:	c535                	beqz	a0,8000532e <exec+0x216>
    800052c4:	e8840993          	addi	s3,s0,-376
    800052c8:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800052cc:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800052ce:	ffffc097          	auipc	ra,0xffffc
    800052d2:	f8c080e7          	jalr	-116(ra) # 8000125a <strlen>
    800052d6:	2505                	addiw	a0,a0,1
    800052d8:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052dc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800052e0:	13896363          	bltu	s2,s8,80005406 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052e4:	e0043d83          	ld	s11,-512(s0)
    800052e8:	000dba03          	ld	s4,0(s11) # 8000 <_entry-0x7fff8000>
    800052ec:	8552                	mv	a0,s4
    800052ee:	ffffc097          	auipc	ra,0xffffc
    800052f2:	f6c080e7          	jalr	-148(ra) # 8000125a <strlen>
    800052f6:	0015069b          	addiw	a3,a0,1
    800052fa:	8652                	mv	a2,s4
    800052fc:	85ca                	mv	a1,s2
    800052fe:	855e                	mv	a0,s7
    80005300:	ffffc097          	auipc	ra,0xffffc
    80005304:	72e080e7          	jalr	1838(ra) # 80001a2e <copyout>
    80005308:	10054363          	bltz	a0,8000540e <exec+0x2f6>
    ustack[argc] = sp;
    8000530c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005310:	0485                	addi	s1,s1,1
    80005312:	008d8793          	addi	a5,s11,8
    80005316:	e0f43023          	sd	a5,-512(s0)
    8000531a:	008db503          	ld	a0,8(s11)
    8000531e:	c911                	beqz	a0,80005332 <exec+0x21a>
    if(argc >= MAXARG)
    80005320:	09a1                	addi	s3,s3,8
    80005322:	fb3c96e3          	bne	s9,s3,800052ce <exec+0x1b6>
  sz = sz1;
    80005326:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000532a:	4481                	li	s1,0
    8000532c:	a84d                	j	800053de <exec+0x2c6>
  sp = sz;
    8000532e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005330:	4481                	li	s1,0
  ustack[argc] = 0;
    80005332:	00349793          	slli	a5,s1,0x3
    80005336:	f9040713          	addi	a4,s0,-112
    8000533a:	97ba                	add	a5,a5,a4
    8000533c:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80005340:	00148693          	addi	a3,s1,1
    80005344:	068e                	slli	a3,a3,0x3
    80005346:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000534a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000534e:	01897663          	bgeu	s2,s8,8000535a <exec+0x242>
  sz = sz1;
    80005352:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005356:	4481                	li	s1,0
    80005358:	a059                	j	800053de <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000535a:	e8840613          	addi	a2,s0,-376
    8000535e:	85ca                	mv	a1,s2
    80005360:	855e                	mv	a0,s7
    80005362:	ffffc097          	auipc	ra,0xffffc
    80005366:	6cc080e7          	jalr	1740(ra) # 80001a2e <copyout>
    8000536a:	0a054663          	bltz	a0,80005416 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000536e:	060ab783          	ld	a5,96(s5)
    80005372:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005376:	df843783          	ld	a5,-520(s0)
    8000537a:	0007c703          	lbu	a4,0(a5)
    8000537e:	cf11                	beqz	a4,8000539a <exec+0x282>
    80005380:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005382:	02f00693          	li	a3,47
    80005386:	a029                	j	80005390 <exec+0x278>
  for(last=s=path; *s; s++)
    80005388:	0785                	addi	a5,a5,1
    8000538a:	fff7c703          	lbu	a4,-1(a5)
    8000538e:	c711                	beqz	a4,8000539a <exec+0x282>
    if(*s == '/')
    80005390:	fed71ce3          	bne	a4,a3,80005388 <exec+0x270>
      last = s+1;
    80005394:	def43c23          	sd	a5,-520(s0)
    80005398:	bfc5                	j	80005388 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000539a:	4641                	li	a2,16
    8000539c:	df843583          	ld	a1,-520(s0)
    800053a0:	160a8513          	addi	a0,s5,352
    800053a4:	ffffc097          	auipc	ra,0xffffc
    800053a8:	e84080e7          	jalr	-380(ra) # 80001228 <safestrcpy>
  oldpagetable = p->pagetable;
    800053ac:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    800053b0:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    800053b4:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053b8:	060ab783          	ld	a5,96(s5)
    800053bc:	e6043703          	ld	a4,-416(s0)
    800053c0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053c2:	060ab783          	ld	a5,96(s5)
    800053c6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053ca:	85ea                	mv	a1,s10
    800053cc:	ffffd097          	auipc	ra,0xffffd
    800053d0:	ace080e7          	jalr	-1330(ra) # 80001e9a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053d4:	0004851b          	sext.w	a0,s1
    800053d8:	bbe1                	j	800051b0 <exec+0x98>
    800053da:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800053de:	e0843583          	ld	a1,-504(s0)
    800053e2:	855e                	mv	a0,s7
    800053e4:	ffffd097          	auipc	ra,0xffffd
    800053e8:	ab6080e7          	jalr	-1354(ra) # 80001e9a <proc_freepagetable>
  if(ip){
    800053ec:	da0498e3          	bnez	s1,8000519c <exec+0x84>
  return -1;
    800053f0:	557d                	li	a0,-1
    800053f2:	bb7d                	j	800051b0 <exec+0x98>
    800053f4:	e1243423          	sd	s2,-504(s0)
    800053f8:	b7dd                	j	800053de <exec+0x2c6>
    800053fa:	e1243423          	sd	s2,-504(s0)
    800053fe:	b7c5                	j	800053de <exec+0x2c6>
    80005400:	e1243423          	sd	s2,-504(s0)
    80005404:	bfe9                	j	800053de <exec+0x2c6>
  sz = sz1;
    80005406:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000540a:	4481                	li	s1,0
    8000540c:	bfc9                	j	800053de <exec+0x2c6>
  sz = sz1;
    8000540e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005412:	4481                	li	s1,0
    80005414:	b7e9                	j	800053de <exec+0x2c6>
  sz = sz1;
    80005416:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000541a:	4481                	li	s1,0
    8000541c:	b7c9                	j	800053de <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000541e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005422:	2b05                	addiw	s6,s6,1
    80005424:	0389899b          	addiw	s3,s3,56
    80005428:	e8045783          	lhu	a5,-384(s0)
    8000542c:	e2fb5be3          	bge	s6,a5,80005262 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005430:	2981                	sext.w	s3,s3
    80005432:	03800713          	li	a4,56
    80005436:	86ce                	mv	a3,s3
    80005438:	e1040613          	addi	a2,s0,-496
    8000543c:	4581                	li	a1,0
    8000543e:	8526                	mv	a0,s1
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	a2e080e7          	jalr	-1490(ra) # 80003e6e <readi>
    80005448:	03800793          	li	a5,56
    8000544c:	f8f517e3          	bne	a0,a5,800053da <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005450:	e1042783          	lw	a5,-496(s0)
    80005454:	4705                	li	a4,1
    80005456:	fce796e3          	bne	a5,a4,80005422 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000545a:	e3843603          	ld	a2,-456(s0)
    8000545e:	e3043783          	ld	a5,-464(s0)
    80005462:	f8f669e3          	bltu	a2,a5,800053f4 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005466:	e2043783          	ld	a5,-480(s0)
    8000546a:	963e                	add	a2,a2,a5
    8000546c:	f8f667e3          	bltu	a2,a5,800053fa <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005470:	85ca                	mv	a1,s2
    80005472:	855e                	mv	a0,s7
    80005474:	ffffc097          	auipc	ra,0xffffc
    80005478:	36a080e7          	jalr	874(ra) # 800017de <uvmalloc>
    8000547c:	e0a43423          	sd	a0,-504(s0)
    80005480:	d141                	beqz	a0,80005400 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005482:	e2043d03          	ld	s10,-480(s0)
    80005486:	df043783          	ld	a5,-528(s0)
    8000548a:	00fd77b3          	and	a5,s10,a5
    8000548e:	fba1                	bnez	a5,800053de <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005490:	e1842d83          	lw	s11,-488(s0)
    80005494:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005498:	f80c03e3          	beqz	s8,8000541e <exec+0x306>
    8000549c:	8a62                	mv	s4,s8
    8000549e:	4901                	li	s2,0
    800054a0:	b345                	j	80005240 <exec+0x128>

00000000800054a2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054a2:	7179                	addi	sp,sp,-48
    800054a4:	f406                	sd	ra,40(sp)
    800054a6:	f022                	sd	s0,32(sp)
    800054a8:	ec26                	sd	s1,24(sp)
    800054aa:	e84a                	sd	s2,16(sp)
    800054ac:	1800                	addi	s0,sp,48
    800054ae:	892e                	mv	s2,a1
    800054b0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800054b2:	fdc40593          	addi	a1,s0,-36
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	942080e7          	jalr	-1726(ra) # 80002df8 <argint>
    800054be:	04054063          	bltz	a0,800054fe <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800054c2:	fdc42703          	lw	a4,-36(s0)
    800054c6:	47bd                	li	a5,15
    800054c8:	02e7ed63          	bltu	a5,a4,80005502 <argfd+0x60>
    800054cc:	ffffd097          	auipc	ra,0xffffd
    800054d0:	86e080e7          	jalr	-1938(ra) # 80001d3a <myproc>
    800054d4:	fdc42703          	lw	a4,-36(s0)
    800054d8:	01a70793          	addi	a5,a4,26
    800054dc:	078e                	slli	a5,a5,0x3
    800054de:	953e                	add	a0,a0,a5
    800054e0:	651c                	ld	a5,8(a0)
    800054e2:	c395                	beqz	a5,80005506 <argfd+0x64>
    return -1;
  if(pfd)
    800054e4:	00090463          	beqz	s2,800054ec <argfd+0x4a>
    *pfd = fd;
    800054e8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054ec:	4501                	li	a0,0
  if(pf)
    800054ee:	c091                	beqz	s1,800054f2 <argfd+0x50>
    *pf = f;
    800054f0:	e09c                	sd	a5,0(s1)
}
    800054f2:	70a2                	ld	ra,40(sp)
    800054f4:	7402                	ld	s0,32(sp)
    800054f6:	64e2                	ld	s1,24(sp)
    800054f8:	6942                	ld	s2,16(sp)
    800054fa:	6145                	addi	sp,sp,48
    800054fc:	8082                	ret
    return -1;
    800054fe:	557d                	li	a0,-1
    80005500:	bfcd                	j	800054f2 <argfd+0x50>
    return -1;
    80005502:	557d                	li	a0,-1
    80005504:	b7fd                	j	800054f2 <argfd+0x50>
    80005506:	557d                	li	a0,-1
    80005508:	b7ed                	j	800054f2 <argfd+0x50>

000000008000550a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000550a:	1101                	addi	sp,sp,-32
    8000550c:	ec06                	sd	ra,24(sp)
    8000550e:	e822                	sd	s0,16(sp)
    80005510:	e426                	sd	s1,8(sp)
    80005512:	1000                	addi	s0,sp,32
    80005514:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005516:	ffffd097          	auipc	ra,0xffffd
    8000551a:	824080e7          	jalr	-2012(ra) # 80001d3a <myproc>
    8000551e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005520:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd30b0>
    80005524:	4501                	li	a0,0
    80005526:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005528:	6398                	ld	a4,0(a5)
    8000552a:	cb19                	beqz	a4,80005540 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000552c:	2505                	addiw	a0,a0,1
    8000552e:	07a1                	addi	a5,a5,8
    80005530:	fed51ce3          	bne	a0,a3,80005528 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005534:	557d                	li	a0,-1
}
    80005536:	60e2                	ld	ra,24(sp)
    80005538:	6442                	ld	s0,16(sp)
    8000553a:	64a2                	ld	s1,8(sp)
    8000553c:	6105                	addi	sp,sp,32
    8000553e:	8082                	ret
      p->ofile[fd] = f;
    80005540:	01a50793          	addi	a5,a0,26
    80005544:	078e                	slli	a5,a5,0x3
    80005546:	963e                	add	a2,a2,a5
    80005548:	e604                	sd	s1,8(a2)
      return fd;
    8000554a:	b7f5                	j	80005536 <fdalloc+0x2c>

000000008000554c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000554c:	715d                	addi	sp,sp,-80
    8000554e:	e486                	sd	ra,72(sp)
    80005550:	e0a2                	sd	s0,64(sp)
    80005552:	fc26                	sd	s1,56(sp)
    80005554:	f84a                	sd	s2,48(sp)
    80005556:	f44e                	sd	s3,40(sp)
    80005558:	f052                	sd	s4,32(sp)
    8000555a:	ec56                	sd	s5,24(sp)
    8000555c:	0880                	addi	s0,sp,80
    8000555e:	89ae                	mv	s3,a1
    80005560:	8ab2                	mv	s5,a2
    80005562:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005564:	fb040593          	addi	a1,s0,-80
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	e24080e7          	jalr	-476(ra) # 8000438c <nameiparent>
    80005570:	892a                	mv	s2,a0
    80005572:	12050f63          	beqz	a0,800056b0 <create+0x164>
    return 0;

  ilock(dp);
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	644080e7          	jalr	1604(ra) # 80003bba <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000557e:	4601                	li	a2,0
    80005580:	fb040593          	addi	a1,s0,-80
    80005584:	854a                	mv	a0,s2
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	b16080e7          	jalr	-1258(ra) # 8000409c <dirlookup>
    8000558e:	84aa                	mv	s1,a0
    80005590:	c921                	beqz	a0,800055e0 <create+0x94>
    iunlockput(dp);
    80005592:	854a                	mv	a0,s2
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	888080e7          	jalr	-1912(ra) # 80003e1c <iunlockput>
    ilock(ip);
    8000559c:	8526                	mv	a0,s1
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	61c080e7          	jalr	1564(ra) # 80003bba <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055a6:	2981                	sext.w	s3,s3
    800055a8:	4789                	li	a5,2
    800055aa:	02f99463          	bne	s3,a5,800055d2 <create+0x86>
    800055ae:	04c4d783          	lhu	a5,76(s1)
    800055b2:	37f9                	addiw	a5,a5,-2
    800055b4:	17c2                	slli	a5,a5,0x30
    800055b6:	93c1                	srli	a5,a5,0x30
    800055b8:	4705                	li	a4,1
    800055ba:	00f76c63          	bltu	a4,a5,800055d2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800055be:	8526                	mv	a0,s1
    800055c0:	60a6                	ld	ra,72(sp)
    800055c2:	6406                	ld	s0,64(sp)
    800055c4:	74e2                	ld	s1,56(sp)
    800055c6:	7942                	ld	s2,48(sp)
    800055c8:	79a2                	ld	s3,40(sp)
    800055ca:	7a02                	ld	s4,32(sp)
    800055cc:	6ae2                	ld	s5,24(sp)
    800055ce:	6161                	addi	sp,sp,80
    800055d0:	8082                	ret
    iunlockput(ip);
    800055d2:	8526                	mv	a0,s1
    800055d4:	fffff097          	auipc	ra,0xfffff
    800055d8:	848080e7          	jalr	-1976(ra) # 80003e1c <iunlockput>
    return 0;
    800055dc:	4481                	li	s1,0
    800055de:	b7c5                	j	800055be <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800055e0:	85ce                	mv	a1,s3
    800055e2:	00092503          	lw	a0,0(s2)
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	43c080e7          	jalr	1084(ra) # 80003a22 <ialloc>
    800055ee:	84aa                	mv	s1,a0
    800055f0:	c529                	beqz	a0,8000563a <create+0xee>
  ilock(ip);
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	5c8080e7          	jalr	1480(ra) # 80003bba <ilock>
  ip->major = major;
    800055fa:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    800055fe:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    80005602:	4785                	li	a5,1
    80005604:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005608:	8526                	mv	a0,s1
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	4e6080e7          	jalr	1254(ra) # 80003af0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005612:	2981                	sext.w	s3,s3
    80005614:	4785                	li	a5,1
    80005616:	02f98a63          	beq	s3,a5,8000564a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000561a:	40d0                	lw	a2,4(s1)
    8000561c:	fb040593          	addi	a1,s0,-80
    80005620:	854a                	mv	a0,s2
    80005622:	fffff097          	auipc	ra,0xfffff
    80005626:	c8a080e7          	jalr	-886(ra) # 800042ac <dirlink>
    8000562a:	06054b63          	bltz	a0,800056a0 <create+0x154>
  iunlockput(dp);
    8000562e:	854a                	mv	a0,s2
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	7ec080e7          	jalr	2028(ra) # 80003e1c <iunlockput>
  return ip;
    80005638:	b759                	j	800055be <create+0x72>
    panic("create: ialloc");
    8000563a:	00003517          	auipc	a0,0x3
    8000563e:	13650513          	addi	a0,a0,310 # 80008770 <syscalls+0x2b8>
    80005642:	ffffb097          	auipc	ra,0xffffb
    80005646:	f0e080e7          	jalr	-242(ra) # 80000550 <panic>
    dp->nlink++;  // for ".."
    8000564a:	05295783          	lhu	a5,82(s2)
    8000564e:	2785                	addiw	a5,a5,1
    80005650:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    80005654:	854a                	mv	a0,s2
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	49a080e7          	jalr	1178(ra) # 80003af0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000565e:	40d0                	lw	a2,4(s1)
    80005660:	00003597          	auipc	a1,0x3
    80005664:	12058593          	addi	a1,a1,288 # 80008780 <syscalls+0x2c8>
    80005668:	8526                	mv	a0,s1
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	c42080e7          	jalr	-958(ra) # 800042ac <dirlink>
    80005672:	00054f63          	bltz	a0,80005690 <create+0x144>
    80005676:	00492603          	lw	a2,4(s2)
    8000567a:	00003597          	auipc	a1,0x3
    8000567e:	10e58593          	addi	a1,a1,270 # 80008788 <syscalls+0x2d0>
    80005682:	8526                	mv	a0,s1
    80005684:	fffff097          	auipc	ra,0xfffff
    80005688:	c28080e7          	jalr	-984(ra) # 800042ac <dirlink>
    8000568c:	f80557e3          	bgez	a0,8000561a <create+0xce>
      panic("create dots");
    80005690:	00003517          	auipc	a0,0x3
    80005694:	10050513          	addi	a0,a0,256 # 80008790 <syscalls+0x2d8>
    80005698:	ffffb097          	auipc	ra,0xffffb
    8000569c:	eb8080e7          	jalr	-328(ra) # 80000550 <panic>
    panic("create: dirlink");
    800056a0:	00003517          	auipc	a0,0x3
    800056a4:	10050513          	addi	a0,a0,256 # 800087a0 <syscalls+0x2e8>
    800056a8:	ffffb097          	auipc	ra,0xffffb
    800056ac:	ea8080e7          	jalr	-344(ra) # 80000550 <panic>
    return 0;
    800056b0:	84aa                	mv	s1,a0
    800056b2:	b731                	j	800055be <create+0x72>

00000000800056b4 <sys_dup>:
{
    800056b4:	7179                	addi	sp,sp,-48
    800056b6:	f406                	sd	ra,40(sp)
    800056b8:	f022                	sd	s0,32(sp)
    800056ba:	ec26                	sd	s1,24(sp)
    800056bc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800056be:	fd840613          	addi	a2,s0,-40
    800056c2:	4581                	li	a1,0
    800056c4:	4501                	li	a0,0
    800056c6:	00000097          	auipc	ra,0x0
    800056ca:	ddc080e7          	jalr	-548(ra) # 800054a2 <argfd>
    return -1;
    800056ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056d0:	02054363          	bltz	a0,800056f6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800056d4:	fd843503          	ld	a0,-40(s0)
    800056d8:	00000097          	auipc	ra,0x0
    800056dc:	e32080e7          	jalr	-462(ra) # 8000550a <fdalloc>
    800056e0:	84aa                	mv	s1,a0
    return -1;
    800056e2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056e4:	00054963          	bltz	a0,800056f6 <sys_dup+0x42>
  filedup(f);
    800056e8:	fd843503          	ld	a0,-40(s0)
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	320080e7          	jalr	800(ra) # 80004a0c <filedup>
  return fd;
    800056f4:	87a6                	mv	a5,s1
}
    800056f6:	853e                	mv	a0,a5
    800056f8:	70a2                	ld	ra,40(sp)
    800056fa:	7402                	ld	s0,32(sp)
    800056fc:	64e2                	ld	s1,24(sp)
    800056fe:	6145                	addi	sp,sp,48
    80005700:	8082                	ret

0000000080005702 <sys_read>:
{
    80005702:	7179                	addi	sp,sp,-48
    80005704:	f406                	sd	ra,40(sp)
    80005706:	f022                	sd	s0,32(sp)
    80005708:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000570a:	fe840613          	addi	a2,s0,-24
    8000570e:	4581                	li	a1,0
    80005710:	4501                	li	a0,0
    80005712:	00000097          	auipc	ra,0x0
    80005716:	d90080e7          	jalr	-624(ra) # 800054a2 <argfd>
    return -1;
    8000571a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000571c:	04054163          	bltz	a0,8000575e <sys_read+0x5c>
    80005720:	fe440593          	addi	a1,s0,-28
    80005724:	4509                	li	a0,2
    80005726:	ffffd097          	auipc	ra,0xffffd
    8000572a:	6d2080e7          	jalr	1746(ra) # 80002df8 <argint>
    return -1;
    8000572e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005730:	02054763          	bltz	a0,8000575e <sys_read+0x5c>
    80005734:	fd840593          	addi	a1,s0,-40
    80005738:	4505                	li	a0,1
    8000573a:	ffffd097          	auipc	ra,0xffffd
    8000573e:	6e0080e7          	jalr	1760(ra) # 80002e1a <argaddr>
    return -1;
    80005742:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005744:	00054d63          	bltz	a0,8000575e <sys_read+0x5c>
  return fileread(f, p, n);
    80005748:	fe442603          	lw	a2,-28(s0)
    8000574c:	fd843583          	ld	a1,-40(s0)
    80005750:	fe843503          	ld	a0,-24(s0)
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	444080e7          	jalr	1092(ra) # 80004b98 <fileread>
    8000575c:	87aa                	mv	a5,a0
}
    8000575e:	853e                	mv	a0,a5
    80005760:	70a2                	ld	ra,40(sp)
    80005762:	7402                	ld	s0,32(sp)
    80005764:	6145                	addi	sp,sp,48
    80005766:	8082                	ret

0000000080005768 <sys_write>:
{
    80005768:	7179                	addi	sp,sp,-48
    8000576a:	f406                	sd	ra,40(sp)
    8000576c:	f022                	sd	s0,32(sp)
    8000576e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005770:	fe840613          	addi	a2,s0,-24
    80005774:	4581                	li	a1,0
    80005776:	4501                	li	a0,0
    80005778:	00000097          	auipc	ra,0x0
    8000577c:	d2a080e7          	jalr	-726(ra) # 800054a2 <argfd>
    return -1;
    80005780:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005782:	04054163          	bltz	a0,800057c4 <sys_write+0x5c>
    80005786:	fe440593          	addi	a1,s0,-28
    8000578a:	4509                	li	a0,2
    8000578c:	ffffd097          	auipc	ra,0xffffd
    80005790:	66c080e7          	jalr	1644(ra) # 80002df8 <argint>
    return -1;
    80005794:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005796:	02054763          	bltz	a0,800057c4 <sys_write+0x5c>
    8000579a:	fd840593          	addi	a1,s0,-40
    8000579e:	4505                	li	a0,1
    800057a0:	ffffd097          	auipc	ra,0xffffd
    800057a4:	67a080e7          	jalr	1658(ra) # 80002e1a <argaddr>
    return -1;
    800057a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057aa:	00054d63          	bltz	a0,800057c4 <sys_write+0x5c>
  return filewrite(f, p, n);
    800057ae:	fe442603          	lw	a2,-28(s0)
    800057b2:	fd843583          	ld	a1,-40(s0)
    800057b6:	fe843503          	ld	a0,-24(s0)
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	4a0080e7          	jalr	1184(ra) # 80004c5a <filewrite>
    800057c2:	87aa                	mv	a5,a0
}
    800057c4:	853e                	mv	a0,a5
    800057c6:	70a2                	ld	ra,40(sp)
    800057c8:	7402                	ld	s0,32(sp)
    800057ca:	6145                	addi	sp,sp,48
    800057cc:	8082                	ret

00000000800057ce <sys_close>:
{
    800057ce:	1101                	addi	sp,sp,-32
    800057d0:	ec06                	sd	ra,24(sp)
    800057d2:	e822                	sd	s0,16(sp)
    800057d4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057d6:	fe040613          	addi	a2,s0,-32
    800057da:	fec40593          	addi	a1,s0,-20
    800057de:	4501                	li	a0,0
    800057e0:	00000097          	auipc	ra,0x0
    800057e4:	cc2080e7          	jalr	-830(ra) # 800054a2 <argfd>
    return -1;
    800057e8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057ea:	02054463          	bltz	a0,80005812 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057ee:	ffffc097          	auipc	ra,0xffffc
    800057f2:	54c080e7          	jalr	1356(ra) # 80001d3a <myproc>
    800057f6:	fec42783          	lw	a5,-20(s0)
    800057fa:	07e9                	addi	a5,a5,26
    800057fc:	078e                	slli	a5,a5,0x3
    800057fe:	97aa                	add	a5,a5,a0
    80005800:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005804:	fe043503          	ld	a0,-32(s0)
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	256080e7          	jalr	598(ra) # 80004a5e <fileclose>
  return 0;
    80005810:	4781                	li	a5,0
}
    80005812:	853e                	mv	a0,a5
    80005814:	60e2                	ld	ra,24(sp)
    80005816:	6442                	ld	s0,16(sp)
    80005818:	6105                	addi	sp,sp,32
    8000581a:	8082                	ret

000000008000581c <sys_fstat>:
{
    8000581c:	1101                	addi	sp,sp,-32
    8000581e:	ec06                	sd	ra,24(sp)
    80005820:	e822                	sd	s0,16(sp)
    80005822:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005824:	fe840613          	addi	a2,s0,-24
    80005828:	4581                	li	a1,0
    8000582a:	4501                	li	a0,0
    8000582c:	00000097          	auipc	ra,0x0
    80005830:	c76080e7          	jalr	-906(ra) # 800054a2 <argfd>
    return -1;
    80005834:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005836:	02054563          	bltz	a0,80005860 <sys_fstat+0x44>
    8000583a:	fe040593          	addi	a1,s0,-32
    8000583e:	4505                	li	a0,1
    80005840:	ffffd097          	auipc	ra,0xffffd
    80005844:	5da080e7          	jalr	1498(ra) # 80002e1a <argaddr>
    return -1;
    80005848:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000584a:	00054b63          	bltz	a0,80005860 <sys_fstat+0x44>
  return filestat(f, st);
    8000584e:	fe043583          	ld	a1,-32(s0)
    80005852:	fe843503          	ld	a0,-24(s0)
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	2d0080e7          	jalr	720(ra) # 80004b26 <filestat>
    8000585e:	87aa                	mv	a5,a0
}
    80005860:	853e                	mv	a0,a5
    80005862:	60e2                	ld	ra,24(sp)
    80005864:	6442                	ld	s0,16(sp)
    80005866:	6105                	addi	sp,sp,32
    80005868:	8082                	ret

000000008000586a <sys_link>:
{
    8000586a:	7169                	addi	sp,sp,-304
    8000586c:	f606                	sd	ra,296(sp)
    8000586e:	f222                	sd	s0,288(sp)
    80005870:	ee26                	sd	s1,280(sp)
    80005872:	ea4a                	sd	s2,272(sp)
    80005874:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005876:	08000613          	li	a2,128
    8000587a:	ed040593          	addi	a1,s0,-304
    8000587e:	4501                	li	a0,0
    80005880:	ffffd097          	auipc	ra,0xffffd
    80005884:	5bc080e7          	jalr	1468(ra) # 80002e3c <argstr>
    return -1;
    80005888:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000588a:	10054e63          	bltz	a0,800059a6 <sys_link+0x13c>
    8000588e:	08000613          	li	a2,128
    80005892:	f5040593          	addi	a1,s0,-176
    80005896:	4505                	li	a0,1
    80005898:	ffffd097          	auipc	ra,0xffffd
    8000589c:	5a4080e7          	jalr	1444(ra) # 80002e3c <argstr>
    return -1;
    800058a0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058a2:	10054263          	bltz	a0,800059a6 <sys_link+0x13c>
  begin_op();
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	ce4080e7          	jalr	-796(ra) # 8000458a <begin_op>
  if((ip = namei(old)) == 0){
    800058ae:	ed040513          	addi	a0,s0,-304
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	abc080e7          	jalr	-1348(ra) # 8000436e <namei>
    800058ba:	84aa                	mv	s1,a0
    800058bc:	c551                	beqz	a0,80005948 <sys_link+0xde>
  ilock(ip);
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	2fc080e7          	jalr	764(ra) # 80003bba <ilock>
  if(ip->type == T_DIR){
    800058c6:	04c49703          	lh	a4,76(s1)
    800058ca:	4785                	li	a5,1
    800058cc:	08f70463          	beq	a4,a5,80005954 <sys_link+0xea>
  ip->nlink++;
    800058d0:	0524d783          	lhu	a5,82(s1)
    800058d4:	2785                	addiw	a5,a5,1
    800058d6:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    800058da:	8526                	mv	a0,s1
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	214080e7          	jalr	532(ra) # 80003af0 <iupdate>
  iunlock(ip);
    800058e4:	8526                	mv	a0,s1
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	396080e7          	jalr	918(ra) # 80003c7c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058ee:	fd040593          	addi	a1,s0,-48
    800058f2:	f5040513          	addi	a0,s0,-176
    800058f6:	fffff097          	auipc	ra,0xfffff
    800058fa:	a96080e7          	jalr	-1386(ra) # 8000438c <nameiparent>
    800058fe:	892a                	mv	s2,a0
    80005900:	c935                	beqz	a0,80005974 <sys_link+0x10a>
  ilock(dp);
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	2b8080e7          	jalr	696(ra) # 80003bba <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000590a:	00092703          	lw	a4,0(s2)
    8000590e:	409c                	lw	a5,0(s1)
    80005910:	04f71d63          	bne	a4,a5,8000596a <sys_link+0x100>
    80005914:	40d0                	lw	a2,4(s1)
    80005916:	fd040593          	addi	a1,s0,-48
    8000591a:	854a                	mv	a0,s2
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	990080e7          	jalr	-1648(ra) # 800042ac <dirlink>
    80005924:	04054363          	bltz	a0,8000596a <sys_link+0x100>
  iunlockput(dp);
    80005928:	854a                	mv	a0,s2
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	4f2080e7          	jalr	1266(ra) # 80003e1c <iunlockput>
  iput(ip);
    80005932:	8526                	mv	a0,s1
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	440080e7          	jalr	1088(ra) # 80003d74 <iput>
  end_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	cce080e7          	jalr	-818(ra) # 8000460a <end_op>
  return 0;
    80005944:	4781                	li	a5,0
    80005946:	a085                	j	800059a6 <sys_link+0x13c>
    end_op();
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	cc2080e7          	jalr	-830(ra) # 8000460a <end_op>
    return -1;
    80005950:	57fd                	li	a5,-1
    80005952:	a891                	j	800059a6 <sys_link+0x13c>
    iunlockput(ip);
    80005954:	8526                	mv	a0,s1
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	4c6080e7          	jalr	1222(ra) # 80003e1c <iunlockput>
    end_op();
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	cac080e7          	jalr	-852(ra) # 8000460a <end_op>
    return -1;
    80005966:	57fd                	li	a5,-1
    80005968:	a83d                	j	800059a6 <sys_link+0x13c>
    iunlockput(dp);
    8000596a:	854a                	mv	a0,s2
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	4b0080e7          	jalr	1200(ra) # 80003e1c <iunlockput>
  ilock(ip);
    80005974:	8526                	mv	a0,s1
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	244080e7          	jalr	580(ra) # 80003bba <ilock>
  ip->nlink--;
    8000597e:	0524d783          	lhu	a5,82(s1)
    80005982:	37fd                	addiw	a5,a5,-1
    80005984:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005988:	8526                	mv	a0,s1
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	166080e7          	jalr	358(ra) # 80003af0 <iupdate>
  iunlockput(ip);
    80005992:	8526                	mv	a0,s1
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	488080e7          	jalr	1160(ra) # 80003e1c <iunlockput>
  end_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	c6e080e7          	jalr	-914(ra) # 8000460a <end_op>
  return -1;
    800059a4:	57fd                	li	a5,-1
}
    800059a6:	853e                	mv	a0,a5
    800059a8:	70b2                	ld	ra,296(sp)
    800059aa:	7412                	ld	s0,288(sp)
    800059ac:	64f2                	ld	s1,280(sp)
    800059ae:	6952                	ld	s2,272(sp)
    800059b0:	6155                	addi	sp,sp,304
    800059b2:	8082                	ret

00000000800059b4 <sys_unlink>:
{
    800059b4:	7151                	addi	sp,sp,-240
    800059b6:	f586                	sd	ra,232(sp)
    800059b8:	f1a2                	sd	s0,224(sp)
    800059ba:	eda6                	sd	s1,216(sp)
    800059bc:	e9ca                	sd	s2,208(sp)
    800059be:	e5ce                	sd	s3,200(sp)
    800059c0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800059c2:	08000613          	li	a2,128
    800059c6:	f3040593          	addi	a1,s0,-208
    800059ca:	4501                	li	a0,0
    800059cc:	ffffd097          	auipc	ra,0xffffd
    800059d0:	470080e7          	jalr	1136(ra) # 80002e3c <argstr>
    800059d4:	18054163          	bltz	a0,80005b56 <sys_unlink+0x1a2>
  begin_op();
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	bb2080e7          	jalr	-1102(ra) # 8000458a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059e0:	fb040593          	addi	a1,s0,-80
    800059e4:	f3040513          	addi	a0,s0,-208
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	9a4080e7          	jalr	-1628(ra) # 8000438c <nameiparent>
    800059f0:	84aa                	mv	s1,a0
    800059f2:	c979                	beqz	a0,80005ac8 <sys_unlink+0x114>
  ilock(dp);
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	1c6080e7          	jalr	454(ra) # 80003bba <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059fc:	00003597          	auipc	a1,0x3
    80005a00:	d8458593          	addi	a1,a1,-636 # 80008780 <syscalls+0x2c8>
    80005a04:	fb040513          	addi	a0,s0,-80
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	67a080e7          	jalr	1658(ra) # 80004082 <namecmp>
    80005a10:	14050a63          	beqz	a0,80005b64 <sys_unlink+0x1b0>
    80005a14:	00003597          	auipc	a1,0x3
    80005a18:	d7458593          	addi	a1,a1,-652 # 80008788 <syscalls+0x2d0>
    80005a1c:	fb040513          	addi	a0,s0,-80
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	662080e7          	jalr	1634(ra) # 80004082 <namecmp>
    80005a28:	12050e63          	beqz	a0,80005b64 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a2c:	f2c40613          	addi	a2,s0,-212
    80005a30:	fb040593          	addi	a1,s0,-80
    80005a34:	8526                	mv	a0,s1
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	666080e7          	jalr	1638(ra) # 8000409c <dirlookup>
    80005a3e:	892a                	mv	s2,a0
    80005a40:	12050263          	beqz	a0,80005b64 <sys_unlink+0x1b0>
  ilock(ip);
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	176080e7          	jalr	374(ra) # 80003bba <ilock>
  if(ip->nlink < 1)
    80005a4c:	05291783          	lh	a5,82(s2)
    80005a50:	08f05263          	blez	a5,80005ad4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a54:	04c91703          	lh	a4,76(s2)
    80005a58:	4785                	li	a5,1
    80005a5a:	08f70563          	beq	a4,a5,80005ae4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a5e:	4641                	li	a2,16
    80005a60:	4581                	li	a1,0
    80005a62:	fc040513          	addi	a0,s0,-64
    80005a66:	ffffb097          	auipc	ra,0xffffb
    80005a6a:	66c080e7          	jalr	1644(ra) # 800010d2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a6e:	4741                	li	a4,16
    80005a70:	f2c42683          	lw	a3,-212(s0)
    80005a74:	fc040613          	addi	a2,s0,-64
    80005a78:	4581                	li	a1,0
    80005a7a:	8526                	mv	a0,s1
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	4ea080e7          	jalr	1258(ra) # 80003f66 <writei>
    80005a84:	47c1                	li	a5,16
    80005a86:	0af51563          	bne	a0,a5,80005b30 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a8a:	04c91703          	lh	a4,76(s2)
    80005a8e:	4785                	li	a5,1
    80005a90:	0af70863          	beq	a4,a5,80005b40 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a94:	8526                	mv	a0,s1
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	386080e7          	jalr	902(ra) # 80003e1c <iunlockput>
  ip->nlink--;
    80005a9e:	05295783          	lhu	a5,82(s2)
    80005aa2:	37fd                	addiw	a5,a5,-1
    80005aa4:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    80005aa8:	854a                	mv	a0,s2
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	046080e7          	jalr	70(ra) # 80003af0 <iupdate>
  iunlockput(ip);
    80005ab2:	854a                	mv	a0,s2
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	368080e7          	jalr	872(ra) # 80003e1c <iunlockput>
  end_op();
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	b4e080e7          	jalr	-1202(ra) # 8000460a <end_op>
  return 0;
    80005ac4:	4501                	li	a0,0
    80005ac6:	a84d                	j	80005b78 <sys_unlink+0x1c4>
    end_op();
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	b42080e7          	jalr	-1214(ra) # 8000460a <end_op>
    return -1;
    80005ad0:	557d                	li	a0,-1
    80005ad2:	a05d                	j	80005b78 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ad4:	00003517          	auipc	a0,0x3
    80005ad8:	cdc50513          	addi	a0,a0,-804 # 800087b0 <syscalls+0x2f8>
    80005adc:	ffffb097          	auipc	ra,0xffffb
    80005ae0:	a74080e7          	jalr	-1420(ra) # 80000550 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ae4:	05492703          	lw	a4,84(s2)
    80005ae8:	02000793          	li	a5,32
    80005aec:	f6e7f9e3          	bgeu	a5,a4,80005a5e <sys_unlink+0xaa>
    80005af0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005af4:	4741                	li	a4,16
    80005af6:	86ce                	mv	a3,s3
    80005af8:	f1840613          	addi	a2,s0,-232
    80005afc:	4581                	li	a1,0
    80005afe:	854a                	mv	a0,s2
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	36e080e7          	jalr	878(ra) # 80003e6e <readi>
    80005b08:	47c1                	li	a5,16
    80005b0a:	00f51b63          	bne	a0,a5,80005b20 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b0e:	f1845783          	lhu	a5,-232(s0)
    80005b12:	e7a1                	bnez	a5,80005b5a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b14:	29c1                	addiw	s3,s3,16
    80005b16:	05492783          	lw	a5,84(s2)
    80005b1a:	fcf9ede3          	bltu	s3,a5,80005af4 <sys_unlink+0x140>
    80005b1e:	b781                	j	80005a5e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b20:	00003517          	auipc	a0,0x3
    80005b24:	ca850513          	addi	a0,a0,-856 # 800087c8 <syscalls+0x310>
    80005b28:	ffffb097          	auipc	ra,0xffffb
    80005b2c:	a28080e7          	jalr	-1496(ra) # 80000550 <panic>
    panic("unlink: writei");
    80005b30:	00003517          	auipc	a0,0x3
    80005b34:	cb050513          	addi	a0,a0,-848 # 800087e0 <syscalls+0x328>
    80005b38:	ffffb097          	auipc	ra,0xffffb
    80005b3c:	a18080e7          	jalr	-1512(ra) # 80000550 <panic>
    dp->nlink--;
    80005b40:	0524d783          	lhu	a5,82(s1)
    80005b44:	37fd                	addiw	a5,a5,-1
    80005b46:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    80005b4a:	8526                	mv	a0,s1
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	fa4080e7          	jalr	-92(ra) # 80003af0 <iupdate>
    80005b54:	b781                	j	80005a94 <sys_unlink+0xe0>
    return -1;
    80005b56:	557d                	li	a0,-1
    80005b58:	a005                	j	80005b78 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b5a:	854a                	mv	a0,s2
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	2c0080e7          	jalr	704(ra) # 80003e1c <iunlockput>
  iunlockput(dp);
    80005b64:	8526                	mv	a0,s1
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	2b6080e7          	jalr	694(ra) # 80003e1c <iunlockput>
  end_op();
    80005b6e:	fffff097          	auipc	ra,0xfffff
    80005b72:	a9c080e7          	jalr	-1380(ra) # 8000460a <end_op>
  return -1;
    80005b76:	557d                	li	a0,-1
}
    80005b78:	70ae                	ld	ra,232(sp)
    80005b7a:	740e                	ld	s0,224(sp)
    80005b7c:	64ee                	ld	s1,216(sp)
    80005b7e:	694e                	ld	s2,208(sp)
    80005b80:	69ae                	ld	s3,200(sp)
    80005b82:	616d                	addi	sp,sp,240
    80005b84:	8082                	ret

0000000080005b86 <sys_open>:

uint64
sys_open(void)
{
    80005b86:	7131                	addi	sp,sp,-192
    80005b88:	fd06                	sd	ra,184(sp)
    80005b8a:	f922                	sd	s0,176(sp)
    80005b8c:	f526                	sd	s1,168(sp)
    80005b8e:	f14a                	sd	s2,160(sp)
    80005b90:	ed4e                	sd	s3,152(sp)
    80005b92:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b94:	08000613          	li	a2,128
    80005b98:	f5040593          	addi	a1,s0,-176
    80005b9c:	4501                	li	a0,0
    80005b9e:	ffffd097          	auipc	ra,0xffffd
    80005ba2:	29e080e7          	jalr	670(ra) # 80002e3c <argstr>
    return -1;
    80005ba6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ba8:	0c054163          	bltz	a0,80005c6a <sys_open+0xe4>
    80005bac:	f4c40593          	addi	a1,s0,-180
    80005bb0:	4505                	li	a0,1
    80005bb2:	ffffd097          	auipc	ra,0xffffd
    80005bb6:	246080e7          	jalr	582(ra) # 80002df8 <argint>
    80005bba:	0a054863          	bltz	a0,80005c6a <sys_open+0xe4>

  begin_op();
    80005bbe:	fffff097          	auipc	ra,0xfffff
    80005bc2:	9cc080e7          	jalr	-1588(ra) # 8000458a <begin_op>

  if(omode & O_CREATE){
    80005bc6:	f4c42783          	lw	a5,-180(s0)
    80005bca:	2007f793          	andi	a5,a5,512
    80005bce:	cbdd                	beqz	a5,80005c84 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005bd0:	4681                	li	a3,0
    80005bd2:	4601                	li	a2,0
    80005bd4:	4589                	li	a1,2
    80005bd6:	f5040513          	addi	a0,s0,-176
    80005bda:	00000097          	auipc	ra,0x0
    80005bde:	972080e7          	jalr	-1678(ra) # 8000554c <create>
    80005be2:	892a                	mv	s2,a0
    if(ip == 0){
    80005be4:	c959                	beqz	a0,80005c7a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005be6:	04c91703          	lh	a4,76(s2)
    80005bea:	478d                	li	a5,3
    80005bec:	00f71763          	bne	a4,a5,80005bfa <sys_open+0x74>
    80005bf0:	04e95703          	lhu	a4,78(s2)
    80005bf4:	47a5                	li	a5,9
    80005bf6:	0ce7ec63          	bltu	a5,a4,80005cce <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	da8080e7          	jalr	-600(ra) # 800049a2 <filealloc>
    80005c02:	89aa                	mv	s3,a0
    80005c04:	10050263          	beqz	a0,80005d08 <sys_open+0x182>
    80005c08:	00000097          	auipc	ra,0x0
    80005c0c:	902080e7          	jalr	-1790(ra) # 8000550a <fdalloc>
    80005c10:	84aa                	mv	s1,a0
    80005c12:	0e054663          	bltz	a0,80005cfe <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c16:	04c91703          	lh	a4,76(s2)
    80005c1a:	478d                	li	a5,3
    80005c1c:	0cf70463          	beq	a4,a5,80005ce4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c20:	4789                	li	a5,2
    80005c22:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c26:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c2a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c2e:	f4c42783          	lw	a5,-180(s0)
    80005c32:	0017c713          	xori	a4,a5,1
    80005c36:	8b05                	andi	a4,a4,1
    80005c38:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c3c:	0037f713          	andi	a4,a5,3
    80005c40:	00e03733          	snez	a4,a4
    80005c44:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c48:	4007f793          	andi	a5,a5,1024
    80005c4c:	c791                	beqz	a5,80005c58 <sys_open+0xd2>
    80005c4e:	04c91703          	lh	a4,76(s2)
    80005c52:	4789                	li	a5,2
    80005c54:	08f70f63          	beq	a4,a5,80005cf2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c58:	854a                	mv	a0,s2
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	022080e7          	jalr	34(ra) # 80003c7c <iunlock>
  end_op();
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	9a8080e7          	jalr	-1624(ra) # 8000460a <end_op>

  return fd;
}
    80005c6a:	8526                	mv	a0,s1
    80005c6c:	70ea                	ld	ra,184(sp)
    80005c6e:	744a                	ld	s0,176(sp)
    80005c70:	74aa                	ld	s1,168(sp)
    80005c72:	790a                	ld	s2,160(sp)
    80005c74:	69ea                	ld	s3,152(sp)
    80005c76:	6129                	addi	sp,sp,192
    80005c78:	8082                	ret
      end_op();
    80005c7a:	fffff097          	auipc	ra,0xfffff
    80005c7e:	990080e7          	jalr	-1648(ra) # 8000460a <end_op>
      return -1;
    80005c82:	b7e5                	j	80005c6a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c84:	f5040513          	addi	a0,s0,-176
    80005c88:	ffffe097          	auipc	ra,0xffffe
    80005c8c:	6e6080e7          	jalr	1766(ra) # 8000436e <namei>
    80005c90:	892a                	mv	s2,a0
    80005c92:	c905                	beqz	a0,80005cc2 <sys_open+0x13c>
    ilock(ip);
    80005c94:	ffffe097          	auipc	ra,0xffffe
    80005c98:	f26080e7          	jalr	-218(ra) # 80003bba <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c9c:	04c91703          	lh	a4,76(s2)
    80005ca0:	4785                	li	a5,1
    80005ca2:	f4f712e3          	bne	a4,a5,80005be6 <sys_open+0x60>
    80005ca6:	f4c42783          	lw	a5,-180(s0)
    80005caa:	dba1                	beqz	a5,80005bfa <sys_open+0x74>
      iunlockput(ip);
    80005cac:	854a                	mv	a0,s2
    80005cae:	ffffe097          	auipc	ra,0xffffe
    80005cb2:	16e080e7          	jalr	366(ra) # 80003e1c <iunlockput>
      end_op();
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	954080e7          	jalr	-1708(ra) # 8000460a <end_op>
      return -1;
    80005cbe:	54fd                	li	s1,-1
    80005cc0:	b76d                	j	80005c6a <sys_open+0xe4>
      end_op();
    80005cc2:	fffff097          	auipc	ra,0xfffff
    80005cc6:	948080e7          	jalr	-1720(ra) # 8000460a <end_op>
      return -1;
    80005cca:	54fd                	li	s1,-1
    80005ccc:	bf79                	j	80005c6a <sys_open+0xe4>
    iunlockput(ip);
    80005cce:	854a                	mv	a0,s2
    80005cd0:	ffffe097          	auipc	ra,0xffffe
    80005cd4:	14c080e7          	jalr	332(ra) # 80003e1c <iunlockput>
    end_op();
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	932080e7          	jalr	-1742(ra) # 8000460a <end_op>
    return -1;
    80005ce0:	54fd                	li	s1,-1
    80005ce2:	b761                	j	80005c6a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ce4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ce8:	04e91783          	lh	a5,78(s2)
    80005cec:	02f99223          	sh	a5,36(s3)
    80005cf0:	bf2d                	j	80005c2a <sys_open+0xa4>
    itrunc(ip);
    80005cf2:	854a                	mv	a0,s2
    80005cf4:	ffffe097          	auipc	ra,0xffffe
    80005cf8:	fd4080e7          	jalr	-44(ra) # 80003cc8 <itrunc>
    80005cfc:	bfb1                	j	80005c58 <sys_open+0xd2>
      fileclose(f);
    80005cfe:	854e                	mv	a0,s3
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	d5e080e7          	jalr	-674(ra) # 80004a5e <fileclose>
    iunlockput(ip);
    80005d08:	854a                	mv	a0,s2
    80005d0a:	ffffe097          	auipc	ra,0xffffe
    80005d0e:	112080e7          	jalr	274(ra) # 80003e1c <iunlockput>
    end_op();
    80005d12:	fffff097          	auipc	ra,0xfffff
    80005d16:	8f8080e7          	jalr	-1800(ra) # 8000460a <end_op>
    return -1;
    80005d1a:	54fd                	li	s1,-1
    80005d1c:	b7b9                	j	80005c6a <sys_open+0xe4>

0000000080005d1e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d1e:	7175                	addi	sp,sp,-144
    80005d20:	e506                	sd	ra,136(sp)
    80005d22:	e122                	sd	s0,128(sp)
    80005d24:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	864080e7          	jalr	-1948(ra) # 8000458a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d2e:	08000613          	li	a2,128
    80005d32:	f7040593          	addi	a1,s0,-144
    80005d36:	4501                	li	a0,0
    80005d38:	ffffd097          	auipc	ra,0xffffd
    80005d3c:	104080e7          	jalr	260(ra) # 80002e3c <argstr>
    80005d40:	02054963          	bltz	a0,80005d72 <sys_mkdir+0x54>
    80005d44:	4681                	li	a3,0
    80005d46:	4601                	li	a2,0
    80005d48:	4585                	li	a1,1
    80005d4a:	f7040513          	addi	a0,s0,-144
    80005d4e:	fffff097          	auipc	ra,0xfffff
    80005d52:	7fe080e7          	jalr	2046(ra) # 8000554c <create>
    80005d56:	cd11                	beqz	a0,80005d72 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d58:	ffffe097          	auipc	ra,0xffffe
    80005d5c:	0c4080e7          	jalr	196(ra) # 80003e1c <iunlockput>
  end_op();
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	8aa080e7          	jalr	-1878(ra) # 8000460a <end_op>
  return 0;
    80005d68:	4501                	li	a0,0
}
    80005d6a:	60aa                	ld	ra,136(sp)
    80005d6c:	640a                	ld	s0,128(sp)
    80005d6e:	6149                	addi	sp,sp,144
    80005d70:	8082                	ret
    end_op();
    80005d72:	fffff097          	auipc	ra,0xfffff
    80005d76:	898080e7          	jalr	-1896(ra) # 8000460a <end_op>
    return -1;
    80005d7a:	557d                	li	a0,-1
    80005d7c:	b7fd                	j	80005d6a <sys_mkdir+0x4c>

0000000080005d7e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d7e:	7135                	addi	sp,sp,-160
    80005d80:	ed06                	sd	ra,152(sp)
    80005d82:	e922                	sd	s0,144(sp)
    80005d84:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d86:	fffff097          	auipc	ra,0xfffff
    80005d8a:	804080e7          	jalr	-2044(ra) # 8000458a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d8e:	08000613          	li	a2,128
    80005d92:	f7040593          	addi	a1,s0,-144
    80005d96:	4501                	li	a0,0
    80005d98:	ffffd097          	auipc	ra,0xffffd
    80005d9c:	0a4080e7          	jalr	164(ra) # 80002e3c <argstr>
    80005da0:	04054a63          	bltz	a0,80005df4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005da4:	f6c40593          	addi	a1,s0,-148
    80005da8:	4505                	li	a0,1
    80005daa:	ffffd097          	auipc	ra,0xffffd
    80005dae:	04e080e7          	jalr	78(ra) # 80002df8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005db2:	04054163          	bltz	a0,80005df4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005db6:	f6840593          	addi	a1,s0,-152
    80005dba:	4509                	li	a0,2
    80005dbc:	ffffd097          	auipc	ra,0xffffd
    80005dc0:	03c080e7          	jalr	60(ra) # 80002df8 <argint>
     argint(1, &major) < 0 ||
    80005dc4:	02054863          	bltz	a0,80005df4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005dc8:	f6841683          	lh	a3,-152(s0)
    80005dcc:	f6c41603          	lh	a2,-148(s0)
    80005dd0:	458d                	li	a1,3
    80005dd2:	f7040513          	addi	a0,s0,-144
    80005dd6:	fffff097          	auipc	ra,0xfffff
    80005dda:	776080e7          	jalr	1910(ra) # 8000554c <create>
     argint(2, &minor) < 0 ||
    80005dde:	c919                	beqz	a0,80005df4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005de0:	ffffe097          	auipc	ra,0xffffe
    80005de4:	03c080e7          	jalr	60(ra) # 80003e1c <iunlockput>
  end_op();
    80005de8:	fffff097          	auipc	ra,0xfffff
    80005dec:	822080e7          	jalr	-2014(ra) # 8000460a <end_op>
  return 0;
    80005df0:	4501                	li	a0,0
    80005df2:	a031                	j	80005dfe <sys_mknod+0x80>
    end_op();
    80005df4:	fffff097          	auipc	ra,0xfffff
    80005df8:	816080e7          	jalr	-2026(ra) # 8000460a <end_op>
    return -1;
    80005dfc:	557d                	li	a0,-1
}
    80005dfe:	60ea                	ld	ra,152(sp)
    80005e00:	644a                	ld	s0,144(sp)
    80005e02:	610d                	addi	sp,sp,160
    80005e04:	8082                	ret

0000000080005e06 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e06:	7135                	addi	sp,sp,-160
    80005e08:	ed06                	sd	ra,152(sp)
    80005e0a:	e922                	sd	s0,144(sp)
    80005e0c:	e526                	sd	s1,136(sp)
    80005e0e:	e14a                	sd	s2,128(sp)
    80005e10:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e12:	ffffc097          	auipc	ra,0xffffc
    80005e16:	f28080e7          	jalr	-216(ra) # 80001d3a <myproc>
    80005e1a:	892a                	mv	s2,a0
  
  begin_op();
    80005e1c:	ffffe097          	auipc	ra,0xffffe
    80005e20:	76e080e7          	jalr	1902(ra) # 8000458a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e24:	08000613          	li	a2,128
    80005e28:	f6040593          	addi	a1,s0,-160
    80005e2c:	4501                	li	a0,0
    80005e2e:	ffffd097          	auipc	ra,0xffffd
    80005e32:	00e080e7          	jalr	14(ra) # 80002e3c <argstr>
    80005e36:	04054b63          	bltz	a0,80005e8c <sys_chdir+0x86>
    80005e3a:	f6040513          	addi	a0,s0,-160
    80005e3e:	ffffe097          	auipc	ra,0xffffe
    80005e42:	530080e7          	jalr	1328(ra) # 8000436e <namei>
    80005e46:	84aa                	mv	s1,a0
    80005e48:	c131                	beqz	a0,80005e8c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e4a:	ffffe097          	auipc	ra,0xffffe
    80005e4e:	d70080e7          	jalr	-656(ra) # 80003bba <ilock>
  if(ip->type != T_DIR){
    80005e52:	04c49703          	lh	a4,76(s1)
    80005e56:	4785                	li	a5,1
    80005e58:	04f71063          	bne	a4,a5,80005e98 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e5c:	8526                	mv	a0,s1
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	e1e080e7          	jalr	-482(ra) # 80003c7c <iunlock>
  iput(p->cwd);
    80005e66:	15893503          	ld	a0,344(s2)
    80005e6a:	ffffe097          	auipc	ra,0xffffe
    80005e6e:	f0a080e7          	jalr	-246(ra) # 80003d74 <iput>
  end_op();
    80005e72:	ffffe097          	auipc	ra,0xffffe
    80005e76:	798080e7          	jalr	1944(ra) # 8000460a <end_op>
  p->cwd = ip;
    80005e7a:	14993c23          	sd	s1,344(s2)
  return 0;
    80005e7e:	4501                	li	a0,0
}
    80005e80:	60ea                	ld	ra,152(sp)
    80005e82:	644a                	ld	s0,144(sp)
    80005e84:	64aa                	ld	s1,136(sp)
    80005e86:	690a                	ld	s2,128(sp)
    80005e88:	610d                	addi	sp,sp,160
    80005e8a:	8082                	ret
    end_op();
    80005e8c:	ffffe097          	auipc	ra,0xffffe
    80005e90:	77e080e7          	jalr	1918(ra) # 8000460a <end_op>
    return -1;
    80005e94:	557d                	li	a0,-1
    80005e96:	b7ed                	j	80005e80 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e98:	8526                	mv	a0,s1
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	f82080e7          	jalr	-126(ra) # 80003e1c <iunlockput>
    end_op();
    80005ea2:	ffffe097          	auipc	ra,0xffffe
    80005ea6:	768080e7          	jalr	1896(ra) # 8000460a <end_op>
    return -1;
    80005eaa:	557d                	li	a0,-1
    80005eac:	bfd1                	j	80005e80 <sys_chdir+0x7a>

0000000080005eae <sys_exec>:

uint64
sys_exec(void)
{
    80005eae:	7145                	addi	sp,sp,-464
    80005eb0:	e786                	sd	ra,456(sp)
    80005eb2:	e3a2                	sd	s0,448(sp)
    80005eb4:	ff26                	sd	s1,440(sp)
    80005eb6:	fb4a                	sd	s2,432(sp)
    80005eb8:	f74e                	sd	s3,424(sp)
    80005eba:	f352                	sd	s4,416(sp)
    80005ebc:	ef56                	sd	s5,408(sp)
    80005ebe:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ec0:	08000613          	li	a2,128
    80005ec4:	f4040593          	addi	a1,s0,-192
    80005ec8:	4501                	li	a0,0
    80005eca:	ffffd097          	auipc	ra,0xffffd
    80005ece:	f72080e7          	jalr	-142(ra) # 80002e3c <argstr>
    return -1;
    80005ed2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ed4:	0c054a63          	bltz	a0,80005fa8 <sys_exec+0xfa>
    80005ed8:	e3840593          	addi	a1,s0,-456
    80005edc:	4505                	li	a0,1
    80005ede:	ffffd097          	auipc	ra,0xffffd
    80005ee2:	f3c080e7          	jalr	-196(ra) # 80002e1a <argaddr>
    80005ee6:	0c054163          	bltz	a0,80005fa8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005eea:	10000613          	li	a2,256
    80005eee:	4581                	li	a1,0
    80005ef0:	e4040513          	addi	a0,s0,-448
    80005ef4:	ffffb097          	auipc	ra,0xffffb
    80005ef8:	1de080e7          	jalr	478(ra) # 800010d2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005efc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f00:	89a6                	mv	s3,s1
    80005f02:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f04:	02000a13          	li	s4,32
    80005f08:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f0c:	00391513          	slli	a0,s2,0x3
    80005f10:	e3040593          	addi	a1,s0,-464
    80005f14:	e3843783          	ld	a5,-456(s0)
    80005f18:	953e                	add	a0,a0,a5
    80005f1a:	ffffd097          	auipc	ra,0xffffd
    80005f1e:	e44080e7          	jalr	-444(ra) # 80002d5e <fetchaddr>
    80005f22:	02054a63          	bltz	a0,80005f56 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f26:	e3043783          	ld	a5,-464(s0)
    80005f2a:	c3b9                	beqz	a5,80005f70 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f2c:	ffffb097          	auipc	ra,0xffffb
    80005f30:	c4e080e7          	jalr	-946(ra) # 80000b7a <kalloc>
    80005f34:	85aa                	mv	a1,a0
    80005f36:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f3a:	cd11                	beqz	a0,80005f56 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f3c:	6605                	lui	a2,0x1
    80005f3e:	e3043503          	ld	a0,-464(s0)
    80005f42:	ffffd097          	auipc	ra,0xffffd
    80005f46:	e6e080e7          	jalr	-402(ra) # 80002db0 <fetchstr>
    80005f4a:	00054663          	bltz	a0,80005f56 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f4e:	0905                	addi	s2,s2,1
    80005f50:	09a1                	addi	s3,s3,8
    80005f52:	fb491be3          	bne	s2,s4,80005f08 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f56:	10048913          	addi	s2,s1,256
    80005f5a:	6088                	ld	a0,0(s1)
    80005f5c:	c529                	beqz	a0,80005fa6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005f5e:	ffffb097          	auipc	ra,0xffffb
    80005f62:	ace080e7          	jalr	-1330(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f66:	04a1                	addi	s1,s1,8
    80005f68:	ff2499e3          	bne	s1,s2,80005f5a <sys_exec+0xac>
  return -1;
    80005f6c:	597d                	li	s2,-1
    80005f6e:	a82d                	j	80005fa8 <sys_exec+0xfa>
      argv[i] = 0;
    80005f70:	0a8e                	slli	s5,s5,0x3
    80005f72:	fc040793          	addi	a5,s0,-64
    80005f76:	9abe                	add	s5,s5,a5
    80005f78:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f7c:	e4040593          	addi	a1,s0,-448
    80005f80:	f4040513          	addi	a0,s0,-192
    80005f84:	fffff097          	auipc	ra,0xfffff
    80005f88:	194080e7          	jalr	404(ra) # 80005118 <exec>
    80005f8c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f8e:	10048993          	addi	s3,s1,256
    80005f92:	6088                	ld	a0,0(s1)
    80005f94:	c911                	beqz	a0,80005fa8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f96:	ffffb097          	auipc	ra,0xffffb
    80005f9a:	a96080e7          	jalr	-1386(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f9e:	04a1                	addi	s1,s1,8
    80005fa0:	ff3499e3          	bne	s1,s3,80005f92 <sys_exec+0xe4>
    80005fa4:	a011                	j	80005fa8 <sys_exec+0xfa>
  return -1;
    80005fa6:	597d                	li	s2,-1
}
    80005fa8:	854a                	mv	a0,s2
    80005faa:	60be                	ld	ra,456(sp)
    80005fac:	641e                	ld	s0,448(sp)
    80005fae:	74fa                	ld	s1,440(sp)
    80005fb0:	795a                	ld	s2,432(sp)
    80005fb2:	79ba                	ld	s3,424(sp)
    80005fb4:	7a1a                	ld	s4,416(sp)
    80005fb6:	6afa                	ld	s5,408(sp)
    80005fb8:	6179                	addi	sp,sp,464
    80005fba:	8082                	ret

0000000080005fbc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005fbc:	7139                	addi	sp,sp,-64
    80005fbe:	fc06                	sd	ra,56(sp)
    80005fc0:	f822                	sd	s0,48(sp)
    80005fc2:	f426                	sd	s1,40(sp)
    80005fc4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fc6:	ffffc097          	auipc	ra,0xffffc
    80005fca:	d74080e7          	jalr	-652(ra) # 80001d3a <myproc>
    80005fce:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005fd0:	fd840593          	addi	a1,s0,-40
    80005fd4:	4501                	li	a0,0
    80005fd6:	ffffd097          	auipc	ra,0xffffd
    80005fda:	e44080e7          	jalr	-444(ra) # 80002e1a <argaddr>
    return -1;
    80005fde:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005fe0:	0e054063          	bltz	a0,800060c0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005fe4:	fc840593          	addi	a1,s0,-56
    80005fe8:	fd040513          	addi	a0,s0,-48
    80005fec:	fffff097          	auipc	ra,0xfffff
    80005ff0:	dc8080e7          	jalr	-568(ra) # 80004db4 <pipealloc>
    return -1;
    80005ff4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ff6:	0c054563          	bltz	a0,800060c0 <sys_pipe+0x104>
  fd0 = -1;
    80005ffa:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ffe:	fd043503          	ld	a0,-48(s0)
    80006002:	fffff097          	auipc	ra,0xfffff
    80006006:	508080e7          	jalr	1288(ra) # 8000550a <fdalloc>
    8000600a:	fca42223          	sw	a0,-60(s0)
    8000600e:	08054c63          	bltz	a0,800060a6 <sys_pipe+0xea>
    80006012:	fc843503          	ld	a0,-56(s0)
    80006016:	fffff097          	auipc	ra,0xfffff
    8000601a:	4f4080e7          	jalr	1268(ra) # 8000550a <fdalloc>
    8000601e:	fca42023          	sw	a0,-64(s0)
    80006022:	06054863          	bltz	a0,80006092 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006026:	4691                	li	a3,4
    80006028:	fc440613          	addi	a2,s0,-60
    8000602c:	fd843583          	ld	a1,-40(s0)
    80006030:	6ca8                	ld	a0,88(s1)
    80006032:	ffffc097          	auipc	ra,0xffffc
    80006036:	9fc080e7          	jalr	-1540(ra) # 80001a2e <copyout>
    8000603a:	02054063          	bltz	a0,8000605a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000603e:	4691                	li	a3,4
    80006040:	fc040613          	addi	a2,s0,-64
    80006044:	fd843583          	ld	a1,-40(s0)
    80006048:	0591                	addi	a1,a1,4
    8000604a:	6ca8                	ld	a0,88(s1)
    8000604c:	ffffc097          	auipc	ra,0xffffc
    80006050:	9e2080e7          	jalr	-1566(ra) # 80001a2e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006054:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006056:	06055563          	bgez	a0,800060c0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000605a:	fc442783          	lw	a5,-60(s0)
    8000605e:	07e9                	addi	a5,a5,26
    80006060:	078e                	slli	a5,a5,0x3
    80006062:	97a6                	add	a5,a5,s1
    80006064:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006068:	fc042503          	lw	a0,-64(s0)
    8000606c:	0569                	addi	a0,a0,26
    8000606e:	050e                	slli	a0,a0,0x3
    80006070:	9526                	add	a0,a0,s1
    80006072:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006076:	fd043503          	ld	a0,-48(s0)
    8000607a:	fffff097          	auipc	ra,0xfffff
    8000607e:	9e4080e7          	jalr	-1564(ra) # 80004a5e <fileclose>
    fileclose(wf);
    80006082:	fc843503          	ld	a0,-56(s0)
    80006086:	fffff097          	auipc	ra,0xfffff
    8000608a:	9d8080e7          	jalr	-1576(ra) # 80004a5e <fileclose>
    return -1;
    8000608e:	57fd                	li	a5,-1
    80006090:	a805                	j	800060c0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006092:	fc442783          	lw	a5,-60(s0)
    80006096:	0007c863          	bltz	a5,800060a6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000609a:	01a78513          	addi	a0,a5,26
    8000609e:	050e                	slli	a0,a0,0x3
    800060a0:	9526                	add	a0,a0,s1
    800060a2:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    800060a6:	fd043503          	ld	a0,-48(s0)
    800060aa:	fffff097          	auipc	ra,0xfffff
    800060ae:	9b4080e7          	jalr	-1612(ra) # 80004a5e <fileclose>
    fileclose(wf);
    800060b2:	fc843503          	ld	a0,-56(s0)
    800060b6:	fffff097          	auipc	ra,0xfffff
    800060ba:	9a8080e7          	jalr	-1624(ra) # 80004a5e <fileclose>
    return -1;
    800060be:	57fd                	li	a5,-1
}
    800060c0:	853e                	mv	a0,a5
    800060c2:	70e2                	ld	ra,56(sp)
    800060c4:	7442                	ld	s0,48(sp)
    800060c6:	74a2                	ld	s1,40(sp)
    800060c8:	6121                	addi	sp,sp,64
    800060ca:	8082                	ret
    800060cc:	0000                	unimp
	...

00000000800060d0 <kernelvec>:
    800060d0:	7111                	addi	sp,sp,-256
    800060d2:	e006                	sd	ra,0(sp)
    800060d4:	e40a                	sd	sp,8(sp)
    800060d6:	e80e                	sd	gp,16(sp)
    800060d8:	ec12                	sd	tp,24(sp)
    800060da:	f016                	sd	t0,32(sp)
    800060dc:	f41a                	sd	t1,40(sp)
    800060de:	f81e                	sd	t2,48(sp)
    800060e0:	fc22                	sd	s0,56(sp)
    800060e2:	e0a6                	sd	s1,64(sp)
    800060e4:	e4aa                	sd	a0,72(sp)
    800060e6:	e8ae                	sd	a1,80(sp)
    800060e8:	ecb2                	sd	a2,88(sp)
    800060ea:	f0b6                	sd	a3,96(sp)
    800060ec:	f4ba                	sd	a4,104(sp)
    800060ee:	f8be                	sd	a5,112(sp)
    800060f0:	fcc2                	sd	a6,120(sp)
    800060f2:	e146                	sd	a7,128(sp)
    800060f4:	e54a                	sd	s2,136(sp)
    800060f6:	e94e                	sd	s3,144(sp)
    800060f8:	ed52                	sd	s4,152(sp)
    800060fa:	f156                	sd	s5,160(sp)
    800060fc:	f55a                	sd	s6,168(sp)
    800060fe:	f95e                	sd	s7,176(sp)
    80006100:	fd62                	sd	s8,184(sp)
    80006102:	e1e6                	sd	s9,192(sp)
    80006104:	e5ea                	sd	s10,200(sp)
    80006106:	e9ee                	sd	s11,208(sp)
    80006108:	edf2                	sd	t3,216(sp)
    8000610a:	f1f6                	sd	t4,224(sp)
    8000610c:	f5fa                	sd	t5,232(sp)
    8000610e:	f9fe                	sd	t6,240(sp)
    80006110:	b1bfc0ef          	jal	ra,80002c2a <kerneltrap>
    80006114:	6082                	ld	ra,0(sp)
    80006116:	6122                	ld	sp,8(sp)
    80006118:	61c2                	ld	gp,16(sp)
    8000611a:	7282                	ld	t0,32(sp)
    8000611c:	7322                	ld	t1,40(sp)
    8000611e:	73c2                	ld	t2,48(sp)
    80006120:	7462                	ld	s0,56(sp)
    80006122:	6486                	ld	s1,64(sp)
    80006124:	6526                	ld	a0,72(sp)
    80006126:	65c6                	ld	a1,80(sp)
    80006128:	6666                	ld	a2,88(sp)
    8000612a:	7686                	ld	a3,96(sp)
    8000612c:	7726                	ld	a4,104(sp)
    8000612e:	77c6                	ld	a5,112(sp)
    80006130:	7866                	ld	a6,120(sp)
    80006132:	688a                	ld	a7,128(sp)
    80006134:	692a                	ld	s2,136(sp)
    80006136:	69ca                	ld	s3,144(sp)
    80006138:	6a6a                	ld	s4,152(sp)
    8000613a:	7a8a                	ld	s5,160(sp)
    8000613c:	7b2a                	ld	s6,168(sp)
    8000613e:	7bca                	ld	s7,176(sp)
    80006140:	7c6a                	ld	s8,184(sp)
    80006142:	6c8e                	ld	s9,192(sp)
    80006144:	6d2e                	ld	s10,200(sp)
    80006146:	6dce                	ld	s11,208(sp)
    80006148:	6e6e                	ld	t3,216(sp)
    8000614a:	7e8e                	ld	t4,224(sp)
    8000614c:	7f2e                	ld	t5,232(sp)
    8000614e:	7fce                	ld	t6,240(sp)
    80006150:	6111                	addi	sp,sp,256
    80006152:	10200073          	sret
    80006156:	00000013          	nop
    8000615a:	00000013          	nop
    8000615e:	0001                	nop

0000000080006160 <timervec>:
    80006160:	34051573          	csrrw	a0,mscratch,a0
    80006164:	e10c                	sd	a1,0(a0)
    80006166:	e510                	sd	a2,8(a0)
    80006168:	e914                	sd	a3,16(a0)
    8000616a:	6d0c                	ld	a1,24(a0)
    8000616c:	7110                	ld	a2,32(a0)
    8000616e:	6194                	ld	a3,0(a1)
    80006170:	96b2                	add	a3,a3,a2
    80006172:	e194                	sd	a3,0(a1)
    80006174:	4589                	li	a1,2
    80006176:	14459073          	csrw	sip,a1
    8000617a:	6914                	ld	a3,16(a0)
    8000617c:	6510                	ld	a2,8(a0)
    8000617e:	610c                	ld	a1,0(a0)
    80006180:	34051573          	csrrw	a0,mscratch,a0
    80006184:	30200073          	mret
	...

000000008000618a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000618a:	1141                	addi	sp,sp,-16
    8000618c:	e422                	sd	s0,8(sp)
    8000618e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006190:	0c0007b7          	lui	a5,0xc000
    80006194:	4705                	li	a4,1
    80006196:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006198:	c3d8                	sw	a4,4(a5)
}
    8000619a:	6422                	ld	s0,8(sp)
    8000619c:	0141                	addi	sp,sp,16
    8000619e:	8082                	ret

00000000800061a0 <plicinithart>:

void
plicinithart(void)
{
    800061a0:	1141                	addi	sp,sp,-16
    800061a2:	e406                	sd	ra,8(sp)
    800061a4:	e022                	sd	s0,0(sp)
    800061a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061a8:	ffffc097          	auipc	ra,0xffffc
    800061ac:	b66080e7          	jalr	-1178(ra) # 80001d0e <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061b0:	0085171b          	slliw	a4,a0,0x8
    800061b4:	0c0027b7          	lui	a5,0xc002
    800061b8:	97ba                	add	a5,a5,a4
    800061ba:	40200713          	li	a4,1026
    800061be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061c2:	00d5151b          	slliw	a0,a0,0xd
    800061c6:	0c2017b7          	lui	a5,0xc201
    800061ca:	953e                	add	a0,a0,a5
    800061cc:	00052023          	sw	zero,0(a0)
}
    800061d0:	60a2                	ld	ra,8(sp)
    800061d2:	6402                	ld	s0,0(sp)
    800061d4:	0141                	addi	sp,sp,16
    800061d6:	8082                	ret

00000000800061d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061d8:	1141                	addi	sp,sp,-16
    800061da:	e406                	sd	ra,8(sp)
    800061dc:	e022                	sd	s0,0(sp)
    800061de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061e0:	ffffc097          	auipc	ra,0xffffc
    800061e4:	b2e080e7          	jalr	-1234(ra) # 80001d0e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061e8:	00d5179b          	slliw	a5,a0,0xd
    800061ec:	0c201537          	lui	a0,0xc201
    800061f0:	953e                	add	a0,a0,a5
  return irq;
}
    800061f2:	4148                	lw	a0,4(a0)
    800061f4:	60a2                	ld	ra,8(sp)
    800061f6:	6402                	ld	s0,0(sp)
    800061f8:	0141                	addi	sp,sp,16
    800061fa:	8082                	ret

00000000800061fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061fc:	1101                	addi	sp,sp,-32
    800061fe:	ec06                	sd	ra,24(sp)
    80006200:	e822                	sd	s0,16(sp)
    80006202:	e426                	sd	s1,8(sp)
    80006204:	1000                	addi	s0,sp,32
    80006206:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006208:	ffffc097          	auipc	ra,0xffffc
    8000620c:	b06080e7          	jalr	-1274(ra) # 80001d0e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006210:	00d5151b          	slliw	a0,a0,0xd
    80006214:	0c2017b7          	lui	a5,0xc201
    80006218:	97aa                	add	a5,a5,a0
    8000621a:	c3c4                	sw	s1,4(a5)
}
    8000621c:	60e2                	ld	ra,24(sp)
    8000621e:	6442                	ld	s0,16(sp)
    80006220:	64a2                	ld	s1,8(sp)
    80006222:	6105                	addi	sp,sp,32
    80006224:	8082                	ret

0000000080006226 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006226:	1141                	addi	sp,sp,-16
    80006228:	e406                	sd	ra,8(sp)
    8000622a:	e022                	sd	s0,0(sp)
    8000622c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000622e:	479d                	li	a5,7
    80006230:	06a7c963          	blt	a5,a0,800062a2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006234:	00022797          	auipc	a5,0x22
    80006238:	dcc78793          	addi	a5,a5,-564 # 80028000 <disk>
    8000623c:	00a78733          	add	a4,a5,a0
    80006240:	6789                	lui	a5,0x2
    80006242:	97ba                	add	a5,a5,a4
    80006244:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006248:	e7ad                	bnez	a5,800062b2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000624a:	00451793          	slli	a5,a0,0x4
    8000624e:	00024717          	auipc	a4,0x24
    80006252:	db270713          	addi	a4,a4,-590 # 8002a000 <disk+0x2000>
    80006256:	6314                	ld	a3,0(a4)
    80006258:	96be                	add	a3,a3,a5
    8000625a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000625e:	6314                	ld	a3,0(a4)
    80006260:	96be                	add	a3,a3,a5
    80006262:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006266:	6314                	ld	a3,0(a4)
    80006268:	96be                	add	a3,a3,a5
    8000626a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000626e:	6318                	ld	a4,0(a4)
    80006270:	97ba                	add	a5,a5,a4
    80006272:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006276:	00022797          	auipc	a5,0x22
    8000627a:	d8a78793          	addi	a5,a5,-630 # 80028000 <disk>
    8000627e:	97aa                	add	a5,a5,a0
    80006280:	6509                	lui	a0,0x2
    80006282:	953e                	add	a0,a0,a5
    80006284:	4785                	li	a5,1
    80006286:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000628a:	00024517          	auipc	a0,0x24
    8000628e:	d8e50513          	addi	a0,a0,-626 # 8002a018 <disk+0x2018>
    80006292:	ffffc097          	auipc	ra,0xffffc
    80006296:	43e080e7          	jalr	1086(ra) # 800026d0 <wakeup>
}
    8000629a:	60a2                	ld	ra,8(sp)
    8000629c:	6402                	ld	s0,0(sp)
    8000629e:	0141                	addi	sp,sp,16
    800062a0:	8082                	ret
    panic("free_desc 1");
    800062a2:	00002517          	auipc	a0,0x2
    800062a6:	54e50513          	addi	a0,a0,1358 # 800087f0 <syscalls+0x338>
    800062aa:	ffffa097          	auipc	ra,0xffffa
    800062ae:	2a6080e7          	jalr	678(ra) # 80000550 <panic>
    panic("free_desc 2");
    800062b2:	00002517          	auipc	a0,0x2
    800062b6:	54e50513          	addi	a0,a0,1358 # 80008800 <syscalls+0x348>
    800062ba:	ffffa097          	auipc	ra,0xffffa
    800062be:	296080e7          	jalr	662(ra) # 80000550 <panic>

00000000800062c2 <virtio_disk_init>:
{
    800062c2:	1101                	addi	sp,sp,-32
    800062c4:	ec06                	sd	ra,24(sp)
    800062c6:	e822                	sd	s0,16(sp)
    800062c8:	e426                	sd	s1,8(sp)
    800062ca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062cc:	00002597          	auipc	a1,0x2
    800062d0:	54458593          	addi	a1,a1,1348 # 80008810 <syscalls+0x358>
    800062d4:	00024517          	auipc	a0,0x24
    800062d8:	e5450513          	addi	a0,a0,-428 # 8002a128 <disk+0x2128>
    800062dc:	ffffb097          	auipc	ra,0xffffb
    800062e0:	b92080e7          	jalr	-1134(ra) # 80000e6e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062e4:	100017b7          	lui	a5,0x10001
    800062e8:	4398                	lw	a4,0(a5)
    800062ea:	2701                	sext.w	a4,a4
    800062ec:	747277b7          	lui	a5,0x74727
    800062f0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062f4:	0ef71163          	bne	a4,a5,800063d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062f8:	100017b7          	lui	a5,0x10001
    800062fc:	43dc                	lw	a5,4(a5)
    800062fe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006300:	4705                	li	a4,1
    80006302:	0ce79a63          	bne	a5,a4,800063d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006306:	100017b7          	lui	a5,0x10001
    8000630a:	479c                	lw	a5,8(a5)
    8000630c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000630e:	4709                	li	a4,2
    80006310:	0ce79363          	bne	a5,a4,800063d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006314:	100017b7          	lui	a5,0x10001
    80006318:	47d8                	lw	a4,12(a5)
    8000631a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000631c:	554d47b7          	lui	a5,0x554d4
    80006320:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006324:	0af71963          	bne	a4,a5,800063d6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006328:	100017b7          	lui	a5,0x10001
    8000632c:	4705                	li	a4,1
    8000632e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006330:	470d                	li	a4,3
    80006332:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006334:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006336:	c7ffe737          	lui	a4,0xc7ffe
    8000633a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd2737>
    8000633e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006340:	2701                	sext.w	a4,a4
    80006342:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006344:	472d                	li	a4,11
    80006346:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006348:	473d                	li	a4,15
    8000634a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000634c:	6705                	lui	a4,0x1
    8000634e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006350:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006354:	5bdc                	lw	a5,52(a5)
    80006356:	2781                	sext.w	a5,a5
  if(max == 0)
    80006358:	c7d9                	beqz	a5,800063e6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000635a:	471d                	li	a4,7
    8000635c:	08f77d63          	bgeu	a4,a5,800063f6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006360:	100014b7          	lui	s1,0x10001
    80006364:	47a1                	li	a5,8
    80006366:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006368:	6609                	lui	a2,0x2
    8000636a:	4581                	li	a1,0
    8000636c:	00022517          	auipc	a0,0x22
    80006370:	c9450513          	addi	a0,a0,-876 # 80028000 <disk>
    80006374:	ffffb097          	auipc	ra,0xffffb
    80006378:	d5e080e7          	jalr	-674(ra) # 800010d2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000637c:	00022717          	auipc	a4,0x22
    80006380:	c8470713          	addi	a4,a4,-892 # 80028000 <disk>
    80006384:	00c75793          	srli	a5,a4,0xc
    80006388:	2781                	sext.w	a5,a5
    8000638a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000638c:	00024797          	auipc	a5,0x24
    80006390:	c7478793          	addi	a5,a5,-908 # 8002a000 <disk+0x2000>
    80006394:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006396:	00022717          	auipc	a4,0x22
    8000639a:	cea70713          	addi	a4,a4,-790 # 80028080 <disk+0x80>
    8000639e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800063a0:	00023717          	auipc	a4,0x23
    800063a4:	c6070713          	addi	a4,a4,-928 # 80029000 <disk+0x1000>
    800063a8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800063aa:	4705                	li	a4,1
    800063ac:	00e78c23          	sb	a4,24(a5)
    800063b0:	00e78ca3          	sb	a4,25(a5)
    800063b4:	00e78d23          	sb	a4,26(a5)
    800063b8:	00e78da3          	sb	a4,27(a5)
    800063bc:	00e78e23          	sb	a4,28(a5)
    800063c0:	00e78ea3          	sb	a4,29(a5)
    800063c4:	00e78f23          	sb	a4,30(a5)
    800063c8:	00e78fa3          	sb	a4,31(a5)
}
    800063cc:	60e2                	ld	ra,24(sp)
    800063ce:	6442                	ld	s0,16(sp)
    800063d0:	64a2                	ld	s1,8(sp)
    800063d2:	6105                	addi	sp,sp,32
    800063d4:	8082                	ret
    panic("could not find virtio disk");
    800063d6:	00002517          	auipc	a0,0x2
    800063da:	44a50513          	addi	a0,a0,1098 # 80008820 <syscalls+0x368>
    800063de:	ffffa097          	auipc	ra,0xffffa
    800063e2:	172080e7          	jalr	370(ra) # 80000550 <panic>
    panic("virtio disk has no queue 0");
    800063e6:	00002517          	auipc	a0,0x2
    800063ea:	45a50513          	addi	a0,a0,1114 # 80008840 <syscalls+0x388>
    800063ee:	ffffa097          	auipc	ra,0xffffa
    800063f2:	162080e7          	jalr	354(ra) # 80000550 <panic>
    panic("virtio disk max queue too short");
    800063f6:	00002517          	auipc	a0,0x2
    800063fa:	46a50513          	addi	a0,a0,1130 # 80008860 <syscalls+0x3a8>
    800063fe:	ffffa097          	auipc	ra,0xffffa
    80006402:	152080e7          	jalr	338(ra) # 80000550 <panic>

0000000080006406 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006406:	7159                	addi	sp,sp,-112
    80006408:	f486                	sd	ra,104(sp)
    8000640a:	f0a2                	sd	s0,96(sp)
    8000640c:	eca6                	sd	s1,88(sp)
    8000640e:	e8ca                	sd	s2,80(sp)
    80006410:	e4ce                	sd	s3,72(sp)
    80006412:	e0d2                	sd	s4,64(sp)
    80006414:	fc56                	sd	s5,56(sp)
    80006416:	f85a                	sd	s6,48(sp)
    80006418:	f45e                	sd	s7,40(sp)
    8000641a:	f062                	sd	s8,32(sp)
    8000641c:	ec66                	sd	s9,24(sp)
    8000641e:	e86a                	sd	s10,16(sp)
    80006420:	1880                	addi	s0,sp,112
    80006422:	892a                	mv	s2,a0
    80006424:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006426:	00c52c83          	lw	s9,12(a0)
    8000642a:	001c9c9b          	slliw	s9,s9,0x1
    8000642e:	1c82                	slli	s9,s9,0x20
    80006430:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006434:	00024517          	auipc	a0,0x24
    80006438:	cf450513          	addi	a0,a0,-780 # 8002a128 <disk+0x2128>
    8000643c:	ffffb097          	auipc	ra,0xffffb
    80006440:	8b6080e7          	jalr	-1866(ra) # 80000cf2 <acquire>
  for(int i = 0; i < 3; i++){
    80006444:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006446:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006448:	00022b97          	auipc	s7,0x22
    8000644c:	bb8b8b93          	addi	s7,s7,-1096 # 80028000 <disk>
    80006450:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006452:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006454:	8a4e                	mv	s4,s3
    80006456:	a051                	j	800064da <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006458:	00fb86b3          	add	a3,s7,a5
    8000645c:	96da                	add	a3,a3,s6
    8000645e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006462:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006464:	0207c563          	bltz	a5,8000648e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006468:	2485                	addiw	s1,s1,1
    8000646a:	0711                	addi	a4,a4,4
    8000646c:	25548063          	beq	s1,s5,800066ac <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006470:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006472:	00024697          	auipc	a3,0x24
    80006476:	ba668693          	addi	a3,a3,-1114 # 8002a018 <disk+0x2018>
    8000647a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000647c:	0006c583          	lbu	a1,0(a3)
    80006480:	fde1                	bnez	a1,80006458 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006482:	2785                	addiw	a5,a5,1
    80006484:	0685                	addi	a3,a3,1
    80006486:	ff879be3          	bne	a5,s8,8000647c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000648a:	57fd                	li	a5,-1
    8000648c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000648e:	02905a63          	blez	s1,800064c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006492:	f9042503          	lw	a0,-112(s0)
    80006496:	00000097          	auipc	ra,0x0
    8000649a:	d90080e7          	jalr	-624(ra) # 80006226 <free_desc>
      for(int j = 0; j < i; j++)
    8000649e:	4785                	li	a5,1
    800064a0:	0297d163          	bge	a5,s1,800064c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064a4:	f9442503          	lw	a0,-108(s0)
    800064a8:	00000097          	auipc	ra,0x0
    800064ac:	d7e080e7          	jalr	-642(ra) # 80006226 <free_desc>
      for(int j = 0; j < i; j++)
    800064b0:	4789                	li	a5,2
    800064b2:	0097d863          	bge	a5,s1,800064c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064b6:	f9842503          	lw	a0,-104(s0)
    800064ba:	00000097          	auipc	ra,0x0
    800064be:	d6c080e7          	jalr	-660(ra) # 80006226 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064c2:	00024597          	auipc	a1,0x24
    800064c6:	c6658593          	addi	a1,a1,-922 # 8002a128 <disk+0x2128>
    800064ca:	00024517          	auipc	a0,0x24
    800064ce:	b4e50513          	addi	a0,a0,-1202 # 8002a018 <disk+0x2018>
    800064d2:	ffffc097          	auipc	ra,0xffffc
    800064d6:	078080e7          	jalr	120(ra) # 8000254a <sleep>
  for(int i = 0; i < 3; i++){
    800064da:	f9040713          	addi	a4,s0,-112
    800064de:	84ce                	mv	s1,s3
    800064e0:	bf41                	j	80006470 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800064e2:	20058713          	addi	a4,a1,512
    800064e6:	00471693          	slli	a3,a4,0x4
    800064ea:	00022717          	auipc	a4,0x22
    800064ee:	b1670713          	addi	a4,a4,-1258 # 80028000 <disk>
    800064f2:	9736                	add	a4,a4,a3
    800064f4:	4685                	li	a3,1
    800064f6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064fa:	20058713          	addi	a4,a1,512
    800064fe:	00471693          	slli	a3,a4,0x4
    80006502:	00022717          	auipc	a4,0x22
    80006506:	afe70713          	addi	a4,a4,-1282 # 80028000 <disk>
    8000650a:	9736                	add	a4,a4,a3
    8000650c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006510:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006514:	7679                	lui	a2,0xffffe
    80006516:	963e                	add	a2,a2,a5
    80006518:	00024697          	auipc	a3,0x24
    8000651c:	ae868693          	addi	a3,a3,-1304 # 8002a000 <disk+0x2000>
    80006520:	6298                	ld	a4,0(a3)
    80006522:	9732                	add	a4,a4,a2
    80006524:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006526:	6298                	ld	a4,0(a3)
    80006528:	9732                	add	a4,a4,a2
    8000652a:	4541                	li	a0,16
    8000652c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000652e:	6298                	ld	a4,0(a3)
    80006530:	9732                	add	a4,a4,a2
    80006532:	4505                	li	a0,1
    80006534:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006538:	f9442703          	lw	a4,-108(s0)
    8000653c:	6288                	ld	a0,0(a3)
    8000653e:	962a                	add	a2,a2,a0
    80006540:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd1fe6>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006544:	0712                	slli	a4,a4,0x4
    80006546:	6290                	ld	a2,0(a3)
    80006548:	963a                	add	a2,a2,a4
    8000654a:	06090513          	addi	a0,s2,96
    8000654e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006550:	6294                	ld	a3,0(a3)
    80006552:	96ba                	add	a3,a3,a4
    80006554:	40000613          	li	a2,1024
    80006558:	c690                	sw	a2,8(a3)
  if(write)
    8000655a:	140d0063          	beqz	s10,8000669a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000655e:	00024697          	auipc	a3,0x24
    80006562:	aa26b683          	ld	a3,-1374(a3) # 8002a000 <disk+0x2000>
    80006566:	96ba                	add	a3,a3,a4
    80006568:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000656c:	00022817          	auipc	a6,0x22
    80006570:	a9480813          	addi	a6,a6,-1388 # 80028000 <disk>
    80006574:	00024517          	auipc	a0,0x24
    80006578:	a8c50513          	addi	a0,a0,-1396 # 8002a000 <disk+0x2000>
    8000657c:	6114                	ld	a3,0(a0)
    8000657e:	96ba                	add	a3,a3,a4
    80006580:	00c6d603          	lhu	a2,12(a3)
    80006584:	00166613          	ori	a2,a2,1
    80006588:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000658c:	f9842683          	lw	a3,-104(s0)
    80006590:	6110                	ld	a2,0(a0)
    80006592:	9732                	add	a4,a4,a2
    80006594:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006598:	20058613          	addi	a2,a1,512
    8000659c:	0612                	slli	a2,a2,0x4
    8000659e:	9642                	add	a2,a2,a6
    800065a0:	577d                	li	a4,-1
    800065a2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800065a6:	00469713          	slli	a4,a3,0x4
    800065aa:	6114                	ld	a3,0(a0)
    800065ac:	96ba                	add	a3,a3,a4
    800065ae:	03078793          	addi	a5,a5,48
    800065b2:	97c2                	add	a5,a5,a6
    800065b4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800065b6:	611c                	ld	a5,0(a0)
    800065b8:	97ba                	add	a5,a5,a4
    800065ba:	4685                	li	a3,1
    800065bc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065be:	611c                	ld	a5,0(a0)
    800065c0:	97ba                	add	a5,a5,a4
    800065c2:	4809                	li	a6,2
    800065c4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800065c8:	611c                	ld	a5,0(a0)
    800065ca:	973e                	add	a4,a4,a5
    800065cc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065d0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800065d4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065d8:	6518                	ld	a4,8(a0)
    800065da:	00275783          	lhu	a5,2(a4)
    800065de:	8b9d                	andi	a5,a5,7
    800065e0:	0786                	slli	a5,a5,0x1
    800065e2:	97ba                	add	a5,a5,a4
    800065e4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800065e8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065ec:	6518                	ld	a4,8(a0)
    800065ee:	00275783          	lhu	a5,2(a4)
    800065f2:	2785                	addiw	a5,a5,1
    800065f4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065f8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065fc:	100017b7          	lui	a5,0x10001
    80006600:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006604:	00492703          	lw	a4,4(s2)
    80006608:	4785                	li	a5,1
    8000660a:	02f71163          	bne	a4,a5,8000662c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000660e:	00024997          	auipc	s3,0x24
    80006612:	b1a98993          	addi	s3,s3,-1254 # 8002a128 <disk+0x2128>
  while(b->disk == 1) {
    80006616:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006618:	85ce                	mv	a1,s3
    8000661a:	854a                	mv	a0,s2
    8000661c:	ffffc097          	auipc	ra,0xffffc
    80006620:	f2e080e7          	jalr	-210(ra) # 8000254a <sleep>
  while(b->disk == 1) {
    80006624:	00492783          	lw	a5,4(s2)
    80006628:	fe9788e3          	beq	a5,s1,80006618 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000662c:	f9042903          	lw	s2,-112(s0)
    80006630:	20090793          	addi	a5,s2,512
    80006634:	00479713          	slli	a4,a5,0x4
    80006638:	00022797          	auipc	a5,0x22
    8000663c:	9c878793          	addi	a5,a5,-1592 # 80028000 <disk>
    80006640:	97ba                	add	a5,a5,a4
    80006642:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006646:	00024997          	auipc	s3,0x24
    8000664a:	9ba98993          	addi	s3,s3,-1606 # 8002a000 <disk+0x2000>
    8000664e:	00491713          	slli	a4,s2,0x4
    80006652:	0009b783          	ld	a5,0(s3)
    80006656:	97ba                	add	a5,a5,a4
    80006658:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000665c:	854a                	mv	a0,s2
    8000665e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006662:	00000097          	auipc	ra,0x0
    80006666:	bc4080e7          	jalr	-1084(ra) # 80006226 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000666a:	8885                	andi	s1,s1,1
    8000666c:	f0ed                	bnez	s1,8000664e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000666e:	00024517          	auipc	a0,0x24
    80006672:	aba50513          	addi	a0,a0,-1350 # 8002a128 <disk+0x2128>
    80006676:	ffffa097          	auipc	ra,0xffffa
    8000667a:	74c080e7          	jalr	1868(ra) # 80000dc2 <release>
}
    8000667e:	70a6                	ld	ra,104(sp)
    80006680:	7406                	ld	s0,96(sp)
    80006682:	64e6                	ld	s1,88(sp)
    80006684:	6946                	ld	s2,80(sp)
    80006686:	69a6                	ld	s3,72(sp)
    80006688:	6a06                	ld	s4,64(sp)
    8000668a:	7ae2                	ld	s5,56(sp)
    8000668c:	7b42                	ld	s6,48(sp)
    8000668e:	7ba2                	ld	s7,40(sp)
    80006690:	7c02                	ld	s8,32(sp)
    80006692:	6ce2                	ld	s9,24(sp)
    80006694:	6d42                	ld	s10,16(sp)
    80006696:	6165                	addi	sp,sp,112
    80006698:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000669a:	00024697          	auipc	a3,0x24
    8000669e:	9666b683          	ld	a3,-1690(a3) # 8002a000 <disk+0x2000>
    800066a2:	96ba                	add	a3,a3,a4
    800066a4:	4609                	li	a2,2
    800066a6:	00c69623          	sh	a2,12(a3)
    800066aa:	b5c9                	j	8000656c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066ac:	f9042583          	lw	a1,-112(s0)
    800066b0:	20058793          	addi	a5,a1,512
    800066b4:	0792                	slli	a5,a5,0x4
    800066b6:	00022517          	auipc	a0,0x22
    800066ba:	9f250513          	addi	a0,a0,-1550 # 800280a8 <disk+0xa8>
    800066be:	953e                	add	a0,a0,a5
  if(write)
    800066c0:	e20d11e3          	bnez	s10,800064e2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800066c4:	20058713          	addi	a4,a1,512
    800066c8:	00471693          	slli	a3,a4,0x4
    800066cc:	00022717          	auipc	a4,0x22
    800066d0:	93470713          	addi	a4,a4,-1740 # 80028000 <disk>
    800066d4:	9736                	add	a4,a4,a3
    800066d6:	0a072423          	sw	zero,168(a4)
    800066da:	b505                	j	800064fa <virtio_disk_rw+0xf4>

00000000800066dc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066dc:	1101                	addi	sp,sp,-32
    800066de:	ec06                	sd	ra,24(sp)
    800066e0:	e822                	sd	s0,16(sp)
    800066e2:	e426                	sd	s1,8(sp)
    800066e4:	e04a                	sd	s2,0(sp)
    800066e6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066e8:	00024517          	auipc	a0,0x24
    800066ec:	a4050513          	addi	a0,a0,-1472 # 8002a128 <disk+0x2128>
    800066f0:	ffffa097          	auipc	ra,0xffffa
    800066f4:	602080e7          	jalr	1538(ra) # 80000cf2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066f8:	10001737          	lui	a4,0x10001
    800066fc:	533c                	lw	a5,96(a4)
    800066fe:	8b8d                	andi	a5,a5,3
    80006700:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006702:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006706:	00024797          	auipc	a5,0x24
    8000670a:	8fa78793          	addi	a5,a5,-1798 # 8002a000 <disk+0x2000>
    8000670e:	6b94                	ld	a3,16(a5)
    80006710:	0207d703          	lhu	a4,32(a5)
    80006714:	0026d783          	lhu	a5,2(a3)
    80006718:	06f70163          	beq	a4,a5,8000677a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000671c:	00022917          	auipc	s2,0x22
    80006720:	8e490913          	addi	s2,s2,-1820 # 80028000 <disk>
    80006724:	00024497          	auipc	s1,0x24
    80006728:	8dc48493          	addi	s1,s1,-1828 # 8002a000 <disk+0x2000>
    __sync_synchronize();
    8000672c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006730:	6898                	ld	a4,16(s1)
    80006732:	0204d783          	lhu	a5,32(s1)
    80006736:	8b9d                	andi	a5,a5,7
    80006738:	078e                	slli	a5,a5,0x3
    8000673a:	97ba                	add	a5,a5,a4
    8000673c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000673e:	20078713          	addi	a4,a5,512
    80006742:	0712                	slli	a4,a4,0x4
    80006744:	974a                	add	a4,a4,s2
    80006746:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000674a:	e731                	bnez	a4,80006796 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000674c:	20078793          	addi	a5,a5,512
    80006750:	0792                	slli	a5,a5,0x4
    80006752:	97ca                	add	a5,a5,s2
    80006754:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006756:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000675a:	ffffc097          	auipc	ra,0xffffc
    8000675e:	f76080e7          	jalr	-138(ra) # 800026d0 <wakeup>

    disk.used_idx += 1;
    80006762:	0204d783          	lhu	a5,32(s1)
    80006766:	2785                	addiw	a5,a5,1
    80006768:	17c2                	slli	a5,a5,0x30
    8000676a:	93c1                	srli	a5,a5,0x30
    8000676c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006770:	6898                	ld	a4,16(s1)
    80006772:	00275703          	lhu	a4,2(a4)
    80006776:	faf71be3          	bne	a4,a5,8000672c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000677a:	00024517          	auipc	a0,0x24
    8000677e:	9ae50513          	addi	a0,a0,-1618 # 8002a128 <disk+0x2128>
    80006782:	ffffa097          	auipc	ra,0xffffa
    80006786:	640080e7          	jalr	1600(ra) # 80000dc2 <release>
}
    8000678a:	60e2                	ld	ra,24(sp)
    8000678c:	6442                	ld	s0,16(sp)
    8000678e:	64a2                	ld	s1,8(sp)
    80006790:	6902                	ld	s2,0(sp)
    80006792:	6105                	addi	sp,sp,32
    80006794:	8082                	ret
      panic("virtio_disk_intr status");
    80006796:	00002517          	auipc	a0,0x2
    8000679a:	0ea50513          	addi	a0,a0,234 # 80008880 <syscalls+0x3c8>
    8000679e:	ffffa097          	auipc	ra,0xffffa
    800067a2:	db2080e7          	jalr	-590(ra) # 80000550 <panic>

00000000800067a6 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    800067a6:	1141                	addi	sp,sp,-16
    800067a8:	e422                	sd	s0,8(sp)
    800067aa:	0800                	addi	s0,sp,16
  return -1;
}
    800067ac:	557d                	li	a0,-1
    800067ae:	6422                	ld	s0,8(sp)
    800067b0:	0141                	addi	sp,sp,16
    800067b2:	8082                	ret

00000000800067b4 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800067b4:	7179                	addi	sp,sp,-48
    800067b6:	f406                	sd	ra,40(sp)
    800067b8:	f022                	sd	s0,32(sp)
    800067ba:	ec26                	sd	s1,24(sp)
    800067bc:	e84a                	sd	s2,16(sp)
    800067be:	e44e                	sd	s3,8(sp)
    800067c0:	e052                	sd	s4,0(sp)
    800067c2:	1800                	addi	s0,sp,48
    800067c4:	892a                	mv	s2,a0
    800067c6:	89ae                	mv	s3,a1
    800067c8:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800067ca:	00025517          	auipc	a0,0x25
    800067ce:	83650513          	addi	a0,a0,-1994 # 8002b000 <stats>
    800067d2:	ffffa097          	auipc	ra,0xffffa
    800067d6:	520080e7          	jalr	1312(ra) # 80000cf2 <acquire>

  if(stats.sz == 0) {
    800067da:	00026797          	auipc	a5,0x26
    800067de:	8467a783          	lw	a5,-1978(a5) # 8002c020 <stats+0x1020>
    800067e2:	cbb5                	beqz	a5,80006856 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    800067e4:	00026797          	auipc	a5,0x26
    800067e8:	81c78793          	addi	a5,a5,-2020 # 8002c000 <stats+0x1000>
    800067ec:	53d8                	lw	a4,36(a5)
    800067ee:	539c                	lw	a5,32(a5)
    800067f0:	9f99                	subw	a5,a5,a4
    800067f2:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800067f6:	06d05e63          	blez	a3,80006872 <statsread+0xbe>
    if(m > n)
    800067fa:	8a3e                	mv	s4,a5
    800067fc:	00d4d363          	bge	s1,a3,80006802 <statsread+0x4e>
    80006800:	8a26                	mv	s4,s1
    80006802:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006806:	86a6                	mv	a3,s1
    80006808:	00025617          	auipc	a2,0x25
    8000680c:	81860613          	addi	a2,a2,-2024 # 8002b020 <stats+0x20>
    80006810:	963a                	add	a2,a2,a4
    80006812:	85ce                	mv	a1,s3
    80006814:	854a                	mv	a0,s2
    80006816:	ffffc097          	auipc	ra,0xffffc
    8000681a:	f96080e7          	jalr	-106(ra) # 800027ac <either_copyout>
    8000681e:	57fd                	li	a5,-1
    80006820:	00f50a63          	beq	a0,a5,80006834 <statsread+0x80>
      stats.off += m;
    80006824:	00025717          	auipc	a4,0x25
    80006828:	7dc70713          	addi	a4,a4,2012 # 8002c000 <stats+0x1000>
    8000682c:	535c                	lw	a5,36(a4)
    8000682e:	014787bb          	addw	a5,a5,s4
    80006832:	d35c                	sw	a5,36(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006834:	00024517          	auipc	a0,0x24
    80006838:	7cc50513          	addi	a0,a0,1996 # 8002b000 <stats>
    8000683c:	ffffa097          	auipc	ra,0xffffa
    80006840:	586080e7          	jalr	1414(ra) # 80000dc2 <release>
  return m;
}
    80006844:	8526                	mv	a0,s1
    80006846:	70a2                	ld	ra,40(sp)
    80006848:	7402                	ld	s0,32(sp)
    8000684a:	64e2                	ld	s1,24(sp)
    8000684c:	6942                	ld	s2,16(sp)
    8000684e:	69a2                	ld	s3,8(sp)
    80006850:	6a02                	ld	s4,0(sp)
    80006852:	6145                	addi	sp,sp,48
    80006854:	8082                	ret
    stats.sz = statslock(stats.buf, BUFSZ);
    80006856:	6585                	lui	a1,0x1
    80006858:	00024517          	auipc	a0,0x24
    8000685c:	7c850513          	addi	a0,a0,1992 # 8002b020 <stats+0x20>
    80006860:	ffffa097          	auipc	ra,0xffffa
    80006864:	6bc080e7          	jalr	1724(ra) # 80000f1c <statslock>
    80006868:	00025797          	auipc	a5,0x25
    8000686c:	7aa7ac23          	sw	a0,1976(a5) # 8002c020 <stats+0x1020>
    80006870:	bf95                	j	800067e4 <statsread+0x30>
    stats.sz = 0;
    80006872:	00025797          	auipc	a5,0x25
    80006876:	78e78793          	addi	a5,a5,1934 # 8002c000 <stats+0x1000>
    8000687a:	0207a023          	sw	zero,32(a5)
    stats.off = 0;
    8000687e:	0207a223          	sw	zero,36(a5)
    m = -1;
    80006882:	54fd                	li	s1,-1
    80006884:	bf45                	j	80006834 <statsread+0x80>

0000000080006886 <statsinit>:

void
statsinit(void)
{
    80006886:	1141                	addi	sp,sp,-16
    80006888:	e406                	sd	ra,8(sp)
    8000688a:	e022                	sd	s0,0(sp)
    8000688c:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000688e:	00002597          	auipc	a1,0x2
    80006892:	00a58593          	addi	a1,a1,10 # 80008898 <syscalls+0x3e0>
    80006896:	00024517          	auipc	a0,0x24
    8000689a:	76a50513          	addi	a0,a0,1898 # 8002b000 <stats>
    8000689e:	ffffa097          	auipc	ra,0xffffa
    800068a2:	5d0080e7          	jalr	1488(ra) # 80000e6e <initlock>

  devsw[STATS].read = statsread;
    800068a6:	0001f797          	auipc	a5,0x1f
    800068aa:	76a78793          	addi	a5,a5,1898 # 80026010 <devsw>
    800068ae:	00000717          	auipc	a4,0x0
    800068b2:	f0670713          	addi	a4,a4,-250 # 800067b4 <statsread>
    800068b6:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    800068b8:	00000717          	auipc	a4,0x0
    800068bc:	eee70713          	addi	a4,a4,-274 # 800067a6 <statswrite>
    800068c0:	f798                	sd	a4,40(a5)
}
    800068c2:	60a2                	ld	ra,8(sp)
    800068c4:	6402                	ld	s0,0(sp)
    800068c6:	0141                	addi	sp,sp,16
    800068c8:	8082                	ret

00000000800068ca <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800068ca:	1101                	addi	sp,sp,-32
    800068cc:	ec22                	sd	s0,24(sp)
    800068ce:	1000                	addi	s0,sp,32
    800068d0:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800068d2:	c299                	beqz	a3,800068d8 <sprintint+0xe>
    800068d4:	0805c163          	bltz	a1,80006956 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    800068d8:	2581                	sext.w	a1,a1
    800068da:	4301                	li	t1,0

  i = 0;
    800068dc:	fe040713          	addi	a4,s0,-32
    800068e0:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    800068e2:	2601                	sext.w	a2,a2
    800068e4:	00002697          	auipc	a3,0x2
    800068e8:	fbc68693          	addi	a3,a3,-68 # 800088a0 <digits>
    800068ec:	88aa                	mv	a7,a0
    800068ee:	2505                	addiw	a0,a0,1
    800068f0:	02c5f7bb          	remuw	a5,a1,a2
    800068f4:	1782                	slli	a5,a5,0x20
    800068f6:	9381                	srli	a5,a5,0x20
    800068f8:	97b6                	add	a5,a5,a3
    800068fa:	0007c783          	lbu	a5,0(a5)
    800068fe:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    80006902:	0005879b          	sext.w	a5,a1
    80006906:	02c5d5bb          	divuw	a1,a1,a2
    8000690a:	0705                	addi	a4,a4,1
    8000690c:	fec7f0e3          	bgeu	a5,a2,800068ec <sprintint+0x22>

  if(sign)
    80006910:	00030b63          	beqz	t1,80006926 <sprintint+0x5c>
    buf[i++] = '-';
    80006914:	ff040793          	addi	a5,s0,-16
    80006918:	97aa                	add	a5,a5,a0
    8000691a:	02d00713          	li	a4,45
    8000691e:	fee78823          	sb	a4,-16(a5)
    80006922:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006926:	02a05c63          	blez	a0,8000695e <sprintint+0x94>
    8000692a:	fe040793          	addi	a5,s0,-32
    8000692e:	00a78733          	add	a4,a5,a0
    80006932:	87c2                	mv	a5,a6
    80006934:	0805                	addi	a6,a6,1
    80006936:	fff5061b          	addiw	a2,a0,-1
    8000693a:	1602                	slli	a2,a2,0x20
    8000693c:	9201                	srli	a2,a2,0x20
    8000693e:	9642                	add	a2,a2,a6
  *s = c;
    80006940:	fff74683          	lbu	a3,-1(a4)
    80006944:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006948:	177d                	addi	a4,a4,-1
    8000694a:	0785                	addi	a5,a5,1
    8000694c:	fec79ae3          	bne	a5,a2,80006940 <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    80006950:	6462                	ld	s0,24(sp)
    80006952:	6105                	addi	sp,sp,32
    80006954:	8082                	ret
    x = -xx;
    80006956:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    8000695a:	4305                	li	t1,1
    x = -xx;
    8000695c:	b741                	j	800068dc <sprintint+0x12>
  while(--i >= 0)
    8000695e:	4501                	li	a0,0
    80006960:	bfc5                	j	80006950 <sprintint+0x86>

0000000080006962 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006962:	7171                	addi	sp,sp,-176
    80006964:	fc86                	sd	ra,120(sp)
    80006966:	f8a2                	sd	s0,112(sp)
    80006968:	f4a6                	sd	s1,104(sp)
    8000696a:	f0ca                	sd	s2,96(sp)
    8000696c:	ecce                	sd	s3,88(sp)
    8000696e:	e8d2                	sd	s4,80(sp)
    80006970:	e4d6                	sd	s5,72(sp)
    80006972:	e0da                	sd	s6,64(sp)
    80006974:	fc5e                	sd	s7,56(sp)
    80006976:	f862                	sd	s8,48(sp)
    80006978:	f466                	sd	s9,40(sp)
    8000697a:	f06a                	sd	s10,32(sp)
    8000697c:	ec6e                	sd	s11,24(sp)
    8000697e:	0100                	addi	s0,sp,128
    80006980:	e414                	sd	a3,8(s0)
    80006982:	e818                	sd	a4,16(s0)
    80006984:	ec1c                	sd	a5,24(s0)
    80006986:	03043023          	sd	a6,32(s0)
    8000698a:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000698e:	ca0d                	beqz	a2,800069c0 <snprintf+0x5e>
    80006990:	8baa                	mv	s7,a0
    80006992:	89ae                	mv	s3,a1
    80006994:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006996:	00840793          	addi	a5,s0,8
    8000699a:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    8000699e:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800069a0:	4901                	li	s2,0
    800069a2:	02b05763          	blez	a1,800069d0 <snprintf+0x6e>
    if(c != '%'){
    800069a6:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    800069aa:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    800069ae:	02800d93          	li	s11,40
  *s = c;
    800069b2:	02500d13          	li	s10,37
    switch(c){
    800069b6:	07800c93          	li	s9,120
    800069ba:	06400c13          	li	s8,100
    800069be:	a01d                	j	800069e4 <snprintf+0x82>
    panic("null fmt");
    800069c0:	00001517          	auipc	a0,0x1
    800069c4:	66850513          	addi	a0,a0,1640 # 80008028 <etext+0x28>
    800069c8:	ffffa097          	auipc	ra,0xffffa
    800069cc:	b88080e7          	jalr	-1144(ra) # 80000550 <panic>
  int off = 0;
    800069d0:	4481                	li	s1,0
    800069d2:	a86d                	j	80006a8c <snprintf+0x12a>
  *s = c;
    800069d4:	009b8733          	add	a4,s7,s1
    800069d8:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800069dc:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800069de:	2905                	addiw	s2,s2,1
    800069e0:	0b34d663          	bge	s1,s3,80006a8c <snprintf+0x12a>
    800069e4:	012a07b3          	add	a5,s4,s2
    800069e8:	0007c783          	lbu	a5,0(a5)
    800069ec:	0007871b          	sext.w	a4,a5
    800069f0:	cfd1                	beqz	a5,80006a8c <snprintf+0x12a>
    if(c != '%'){
    800069f2:	ff5711e3          	bne	a4,s5,800069d4 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    800069f6:	2905                	addiw	s2,s2,1
    800069f8:	012a07b3          	add	a5,s4,s2
    800069fc:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    80006a00:	c7d1                	beqz	a5,80006a8c <snprintf+0x12a>
    switch(c){
    80006a02:	05678c63          	beq	a5,s6,80006a5a <snprintf+0xf8>
    80006a06:	02fb6763          	bltu	s6,a5,80006a34 <snprintf+0xd2>
    80006a0a:	0b578763          	beq	a5,s5,80006ab8 <snprintf+0x156>
    80006a0e:	0b879b63          	bne	a5,s8,80006ac4 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    80006a12:	f8843783          	ld	a5,-120(s0)
    80006a16:	00878713          	addi	a4,a5,8
    80006a1a:	f8e43423          	sd	a4,-120(s0)
    80006a1e:	4685                	li	a3,1
    80006a20:	4629                	li	a2,10
    80006a22:	438c                	lw	a1,0(a5)
    80006a24:	009b8533          	add	a0,s7,s1
    80006a28:	00000097          	auipc	ra,0x0
    80006a2c:	ea2080e7          	jalr	-350(ra) # 800068ca <sprintint>
    80006a30:	9ca9                	addw	s1,s1,a0
      break;
    80006a32:	b775                	j	800069de <snprintf+0x7c>
    switch(c){
    80006a34:	09979863          	bne	a5,s9,80006ac4 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006a38:	f8843783          	ld	a5,-120(s0)
    80006a3c:	00878713          	addi	a4,a5,8
    80006a40:	f8e43423          	sd	a4,-120(s0)
    80006a44:	4685                	li	a3,1
    80006a46:	4641                	li	a2,16
    80006a48:	438c                	lw	a1,0(a5)
    80006a4a:	009b8533          	add	a0,s7,s1
    80006a4e:	00000097          	auipc	ra,0x0
    80006a52:	e7c080e7          	jalr	-388(ra) # 800068ca <sprintint>
    80006a56:	9ca9                	addw	s1,s1,a0
      break;
    80006a58:	b759                	j	800069de <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006a5a:	f8843783          	ld	a5,-120(s0)
    80006a5e:	00878713          	addi	a4,a5,8
    80006a62:	f8e43423          	sd	a4,-120(s0)
    80006a66:	639c                	ld	a5,0(a5)
    80006a68:	c3b1                	beqz	a5,80006aac <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006a6a:	0007c703          	lbu	a4,0(a5)
    80006a6e:	db25                	beqz	a4,800069de <snprintf+0x7c>
    80006a70:	0134de63          	bge	s1,s3,80006a8c <snprintf+0x12a>
    80006a74:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006a78:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006a7c:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006a7e:	0785                	addi	a5,a5,1
    80006a80:	0007c703          	lbu	a4,0(a5)
    80006a84:	df29                	beqz	a4,800069de <snprintf+0x7c>
    80006a86:	0685                	addi	a3,a3,1
    80006a88:	fe9998e3          	bne	s3,s1,80006a78 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006a8c:	8526                	mv	a0,s1
    80006a8e:	70e6                	ld	ra,120(sp)
    80006a90:	7446                	ld	s0,112(sp)
    80006a92:	74a6                	ld	s1,104(sp)
    80006a94:	7906                	ld	s2,96(sp)
    80006a96:	69e6                	ld	s3,88(sp)
    80006a98:	6a46                	ld	s4,80(sp)
    80006a9a:	6aa6                	ld	s5,72(sp)
    80006a9c:	6b06                	ld	s6,64(sp)
    80006a9e:	7be2                	ld	s7,56(sp)
    80006aa0:	7c42                	ld	s8,48(sp)
    80006aa2:	7ca2                	ld	s9,40(sp)
    80006aa4:	7d02                	ld	s10,32(sp)
    80006aa6:	6de2                	ld	s11,24(sp)
    80006aa8:	614d                	addi	sp,sp,176
    80006aaa:	8082                	ret
        s = "(null)";
    80006aac:	00001797          	auipc	a5,0x1
    80006ab0:	57478793          	addi	a5,a5,1396 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006ab4:	876e                	mv	a4,s11
    80006ab6:	bf6d                	j	80006a70 <snprintf+0x10e>
  *s = c;
    80006ab8:	009b87b3          	add	a5,s7,s1
    80006abc:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    80006ac0:	2485                	addiw	s1,s1,1
      break;
    80006ac2:	bf31                	j	800069de <snprintf+0x7c>
  *s = c;
    80006ac4:	009b8733          	add	a4,s7,s1
    80006ac8:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006acc:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006ad0:	975e                	add	a4,a4,s7
    80006ad2:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006ad6:	2489                	addiw	s1,s1,2
      break;
    80006ad8:	b719                	j	800069de <snprintf+0x7c>
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
