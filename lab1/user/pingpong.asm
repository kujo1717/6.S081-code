
user/_pingpong:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "./user.h"
#include "stddef.h"

int
main(int argc, char *argv[])
{
   0:	7139                	addi	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	0080                	addi	s0,sp,64
    int ptoc_fd[2], ctop_fd[2];
    pipe(ptoc_fd);
   a:	fd840513          	addi	a0,s0,-40
   e:	00000097          	auipc	ra,0x0
  12:	36e080e7          	jalr	878(ra) # 37c <pipe>
    pipe(ctop_fd);
  16:	fd040513          	addi	a0,s0,-48
  1a:	00000097          	auipc	ra,0x0
  1e:	362080e7          	jalr	866(ra) # 37c <pipe>
    char buf[8];
    if (fork() == 0) {
  22:	00000097          	auipc	ra,0x0
  26:	342080e7          	jalr	834(ra) # 364 <fork>
  2a:	e13d                	bnez	a0,90 <main+0x90>
        // child process
        read(ptoc_fd[0], buf, 4);
  2c:	4611                	li	a2,4
  2e:	fc840593          	addi	a1,s0,-56
  32:	fd842503          	lw	a0,-40(s0)
  36:	00000097          	auipc	ra,0x0
  3a:	34e080e7          	jalr	846(ra) # 384 <read>
        printf("%d: received %s\n", getpid(), buf);
  3e:	00000097          	auipc	ra,0x0
  42:	3ae080e7          	jalr	942(ra) # 3ec <getpid>
  46:	85aa                	mv	a1,a0
  48:	fc840613          	addi	a2,s0,-56
  4c:	00001517          	auipc	a0,0x1
  50:	83c50513          	addi	a0,a0,-1988 # 888 <malloc+0xe6>
  54:	00000097          	auipc	ra,0x0
  58:	690080e7          	jalr	1680(ra) # 6e4 <printf>
        write(ctop_fd[1], "pong", strlen("pong"));
  5c:	fd442483          	lw	s1,-44(s0)
  60:	00001517          	auipc	a0,0x1
  64:	84050513          	addi	a0,a0,-1984 # 8a0 <malloc+0xfe>
  68:	00000097          	auipc	ra,0x0
  6c:	0d6080e7          	jalr	214(ra) # 13e <strlen>
  70:	0005061b          	sext.w	a2,a0
  74:	00001597          	auipc	a1,0x1
  78:	82c58593          	addi	a1,a1,-2004 # 8a0 <malloc+0xfe>
  7c:	8526                	mv	a0,s1
  7e:	00000097          	auipc	ra,0x0
  82:	30e080e7          	jalr	782(ra) # 38c <write>
        write(ptoc_fd[1], "ping", strlen("ping"));
        wait(NULL);
        read(ctop_fd[0], buf, 4);
        printf("%d: received %s\n", getpid(), buf);
    }
    exit(0);
  86:	4501                	li	a0,0
  88:	00000097          	auipc	ra,0x0
  8c:	2e4080e7          	jalr	740(ra) # 36c <exit>
        write(ptoc_fd[1], "ping", strlen("ping"));
  90:	fdc42483          	lw	s1,-36(s0)
  94:	00001517          	auipc	a0,0x1
  98:	81450513          	addi	a0,a0,-2028 # 8a8 <malloc+0x106>
  9c:	00000097          	auipc	ra,0x0
  a0:	0a2080e7          	jalr	162(ra) # 13e <strlen>
  a4:	0005061b          	sext.w	a2,a0
  a8:	00001597          	auipc	a1,0x1
  ac:	80058593          	addi	a1,a1,-2048 # 8a8 <malloc+0x106>
  b0:	8526                	mv	a0,s1
  b2:	00000097          	auipc	ra,0x0
  b6:	2da080e7          	jalr	730(ra) # 38c <write>
        wait(NULL);
  ba:	4501                	li	a0,0
  bc:	00000097          	auipc	ra,0x0
  c0:	2b8080e7          	jalr	696(ra) # 374 <wait>
        read(ctop_fd[0], buf, 4);
  c4:	4611                	li	a2,4
  c6:	fc840593          	addi	a1,s0,-56
  ca:	fd042503          	lw	a0,-48(s0)
  ce:	00000097          	auipc	ra,0x0
  d2:	2b6080e7          	jalr	694(ra) # 384 <read>
        printf("%d: received %s\n", getpid(), buf);
  d6:	00000097          	auipc	ra,0x0
  da:	316080e7          	jalr	790(ra) # 3ec <getpid>
  de:	85aa                	mv	a1,a0
  e0:	fc840613          	addi	a2,s0,-56
  e4:	00000517          	auipc	a0,0x0
  e8:	7a450513          	addi	a0,a0,1956 # 888 <malloc+0xe6>
  ec:	00000097          	auipc	ra,0x0
  f0:	5f8080e7          	jalr	1528(ra) # 6e4 <printf>
  f4:	bf49                	j	86 <main+0x86>

00000000000000f6 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  f6:	1141                	addi	sp,sp,-16
  f8:	e422                	sd	s0,8(sp)
  fa:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  fc:	87aa                	mv	a5,a0
  fe:	0585                	addi	a1,a1,1
 100:	0785                	addi	a5,a5,1
 102:	fff5c703          	lbu	a4,-1(a1)
 106:	fee78fa3          	sb	a4,-1(a5)
 10a:	fb75                	bnez	a4,fe <strcpy+0x8>
    ;
  return os;
}
 10c:	6422                	ld	s0,8(sp)
 10e:	0141                	addi	sp,sp,16
 110:	8082                	ret

0000000000000112 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 112:	1141                	addi	sp,sp,-16
 114:	e422                	sd	s0,8(sp)
 116:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 118:	00054783          	lbu	a5,0(a0)
 11c:	cb91                	beqz	a5,130 <strcmp+0x1e>
 11e:	0005c703          	lbu	a4,0(a1)
 122:	00f71763          	bne	a4,a5,130 <strcmp+0x1e>
    p++, q++;
 126:	0505                	addi	a0,a0,1
 128:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 12a:	00054783          	lbu	a5,0(a0)
 12e:	fbe5                	bnez	a5,11e <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 130:	0005c503          	lbu	a0,0(a1)
}
 134:	40a7853b          	subw	a0,a5,a0
 138:	6422                	ld	s0,8(sp)
 13a:	0141                	addi	sp,sp,16
 13c:	8082                	ret

000000000000013e <strlen>:

uint
strlen(const char *s)
{
 13e:	1141                	addi	sp,sp,-16
 140:	e422                	sd	s0,8(sp)
 142:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 144:	00054783          	lbu	a5,0(a0)
 148:	cf91                	beqz	a5,164 <strlen+0x26>
 14a:	0505                	addi	a0,a0,1
 14c:	87aa                	mv	a5,a0
 14e:	4685                	li	a3,1
 150:	9e89                	subw	a3,a3,a0
 152:	00f6853b          	addw	a0,a3,a5
 156:	0785                	addi	a5,a5,1
 158:	fff7c703          	lbu	a4,-1(a5)
 15c:	fb7d                	bnez	a4,152 <strlen+0x14>
    ;
  return n;
}
 15e:	6422                	ld	s0,8(sp)
 160:	0141                	addi	sp,sp,16
 162:	8082                	ret
  for(n = 0; s[n]; n++)
 164:	4501                	li	a0,0
 166:	bfe5                	j	15e <strlen+0x20>

0000000000000168 <memset>:

void*
memset(void *dst, int c, uint n)
{
 168:	1141                	addi	sp,sp,-16
 16a:	e422                	sd	s0,8(sp)
 16c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 16e:	ce09                	beqz	a2,188 <memset+0x20>
 170:	87aa                	mv	a5,a0
 172:	fff6071b          	addiw	a4,a2,-1
 176:	1702                	slli	a4,a4,0x20
 178:	9301                	srli	a4,a4,0x20
 17a:	0705                	addi	a4,a4,1
 17c:	972a                	add	a4,a4,a0
    cdst[i] = c;
 17e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 182:	0785                	addi	a5,a5,1
 184:	fee79de3          	bne	a5,a4,17e <memset+0x16>
  }
  return dst;
}
 188:	6422                	ld	s0,8(sp)
 18a:	0141                	addi	sp,sp,16
 18c:	8082                	ret

000000000000018e <strchr>:

char*
strchr(const char *s, char c)
{
 18e:	1141                	addi	sp,sp,-16
 190:	e422                	sd	s0,8(sp)
 192:	0800                	addi	s0,sp,16
  for(; *s; s++)
 194:	00054783          	lbu	a5,0(a0)
 198:	cb99                	beqz	a5,1ae <strchr+0x20>
    if(*s == c)
 19a:	00f58763          	beq	a1,a5,1a8 <strchr+0x1a>
  for(; *s; s++)
 19e:	0505                	addi	a0,a0,1
 1a0:	00054783          	lbu	a5,0(a0)
 1a4:	fbfd                	bnez	a5,19a <strchr+0xc>
      return (char*)s;
  return 0;
 1a6:	4501                	li	a0,0
}
 1a8:	6422                	ld	s0,8(sp)
 1aa:	0141                	addi	sp,sp,16
 1ac:	8082                	ret
  return 0;
 1ae:	4501                	li	a0,0
 1b0:	bfe5                	j	1a8 <strchr+0x1a>

00000000000001b2 <gets>:

char*
gets(char *buf, int max)
{
 1b2:	711d                	addi	sp,sp,-96
 1b4:	ec86                	sd	ra,88(sp)
 1b6:	e8a2                	sd	s0,80(sp)
 1b8:	e4a6                	sd	s1,72(sp)
 1ba:	e0ca                	sd	s2,64(sp)
 1bc:	fc4e                	sd	s3,56(sp)
 1be:	f852                	sd	s4,48(sp)
 1c0:	f456                	sd	s5,40(sp)
 1c2:	f05a                	sd	s6,32(sp)
 1c4:	ec5e                	sd	s7,24(sp)
 1c6:	1080                	addi	s0,sp,96
 1c8:	8baa                	mv	s7,a0
 1ca:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1cc:	892a                	mv	s2,a0
 1ce:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1d0:	4aa9                	li	s5,10
 1d2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1d4:	89a6                	mv	s3,s1
 1d6:	2485                	addiw	s1,s1,1
 1d8:	0344d863          	bge	s1,s4,208 <gets+0x56>
    cc = read(0, &c, 1);
 1dc:	4605                	li	a2,1
 1de:	faf40593          	addi	a1,s0,-81
 1e2:	4501                	li	a0,0
 1e4:	00000097          	auipc	ra,0x0
 1e8:	1a0080e7          	jalr	416(ra) # 384 <read>
    if(cc < 1)
 1ec:	00a05e63          	blez	a0,208 <gets+0x56>
    buf[i++] = c;
 1f0:	faf44783          	lbu	a5,-81(s0)
 1f4:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1f8:	01578763          	beq	a5,s5,206 <gets+0x54>
 1fc:	0905                	addi	s2,s2,1
 1fe:	fd679be3          	bne	a5,s6,1d4 <gets+0x22>
  for(i=0; i+1 < max; ){
 202:	89a6                	mv	s3,s1
 204:	a011                	j	208 <gets+0x56>
 206:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 208:	99de                	add	s3,s3,s7
 20a:	00098023          	sb	zero,0(s3)
  return buf;
}
 20e:	855e                	mv	a0,s7
 210:	60e6                	ld	ra,88(sp)
 212:	6446                	ld	s0,80(sp)
 214:	64a6                	ld	s1,72(sp)
 216:	6906                	ld	s2,64(sp)
 218:	79e2                	ld	s3,56(sp)
 21a:	7a42                	ld	s4,48(sp)
 21c:	7aa2                	ld	s5,40(sp)
 21e:	7b02                	ld	s6,32(sp)
 220:	6be2                	ld	s7,24(sp)
 222:	6125                	addi	sp,sp,96
 224:	8082                	ret

0000000000000226 <stat>:

int
stat(const char *n, struct stat *st)
{
 226:	1101                	addi	sp,sp,-32
 228:	ec06                	sd	ra,24(sp)
 22a:	e822                	sd	s0,16(sp)
 22c:	e426                	sd	s1,8(sp)
 22e:	e04a                	sd	s2,0(sp)
 230:	1000                	addi	s0,sp,32
 232:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 234:	4581                	li	a1,0
 236:	00000097          	auipc	ra,0x0
 23a:	176080e7          	jalr	374(ra) # 3ac <open>
  if(fd < 0)
 23e:	02054563          	bltz	a0,268 <stat+0x42>
 242:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 244:	85ca                	mv	a1,s2
 246:	00000097          	auipc	ra,0x0
 24a:	17e080e7          	jalr	382(ra) # 3c4 <fstat>
 24e:	892a                	mv	s2,a0
  close(fd);
 250:	8526                	mv	a0,s1
 252:	00000097          	auipc	ra,0x0
 256:	142080e7          	jalr	322(ra) # 394 <close>
  return r;
}
 25a:	854a                	mv	a0,s2
 25c:	60e2                	ld	ra,24(sp)
 25e:	6442                	ld	s0,16(sp)
 260:	64a2                	ld	s1,8(sp)
 262:	6902                	ld	s2,0(sp)
 264:	6105                	addi	sp,sp,32
 266:	8082                	ret
    return -1;
 268:	597d                	li	s2,-1
 26a:	bfc5                	j	25a <stat+0x34>

000000000000026c <atoi>:

int
atoi(const char *s)
{
 26c:	1141                	addi	sp,sp,-16
 26e:	e422                	sd	s0,8(sp)
 270:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 272:	00054603          	lbu	a2,0(a0)
 276:	fd06079b          	addiw	a5,a2,-48
 27a:	0ff7f793          	andi	a5,a5,255
 27e:	4725                	li	a4,9
 280:	02f76963          	bltu	a4,a5,2b2 <atoi+0x46>
 284:	86aa                	mv	a3,a0
  n = 0;
 286:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 288:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 28a:	0685                	addi	a3,a3,1
 28c:	0025179b          	slliw	a5,a0,0x2
 290:	9fa9                	addw	a5,a5,a0
 292:	0017979b          	slliw	a5,a5,0x1
 296:	9fb1                	addw	a5,a5,a2
 298:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 29c:	0006c603          	lbu	a2,0(a3)
 2a0:	fd06071b          	addiw	a4,a2,-48
 2a4:	0ff77713          	andi	a4,a4,255
 2a8:	fee5f1e3          	bgeu	a1,a4,28a <atoi+0x1e>
  return n;
}
 2ac:	6422                	ld	s0,8(sp)
 2ae:	0141                	addi	sp,sp,16
 2b0:	8082                	ret
  n = 0;
 2b2:	4501                	li	a0,0
 2b4:	bfe5                	j	2ac <atoi+0x40>

00000000000002b6 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2b6:	1141                	addi	sp,sp,-16
 2b8:	e422                	sd	s0,8(sp)
 2ba:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2bc:	02b57663          	bgeu	a0,a1,2e8 <memmove+0x32>
    while(n-- > 0)
 2c0:	02c05163          	blez	a2,2e2 <memmove+0x2c>
 2c4:	fff6079b          	addiw	a5,a2,-1
 2c8:	1782                	slli	a5,a5,0x20
 2ca:	9381                	srli	a5,a5,0x20
 2cc:	0785                	addi	a5,a5,1
 2ce:	97aa                	add	a5,a5,a0
  dst = vdst;
 2d0:	872a                	mv	a4,a0
      *dst++ = *src++;
 2d2:	0585                	addi	a1,a1,1
 2d4:	0705                	addi	a4,a4,1
 2d6:	fff5c683          	lbu	a3,-1(a1)
 2da:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2de:	fee79ae3          	bne	a5,a4,2d2 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2e2:	6422                	ld	s0,8(sp)
 2e4:	0141                	addi	sp,sp,16
 2e6:	8082                	ret
    dst += n;
 2e8:	00c50733          	add	a4,a0,a2
    src += n;
 2ec:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2ee:	fec05ae3          	blez	a2,2e2 <memmove+0x2c>
 2f2:	fff6079b          	addiw	a5,a2,-1
 2f6:	1782                	slli	a5,a5,0x20
 2f8:	9381                	srli	a5,a5,0x20
 2fa:	fff7c793          	not	a5,a5
 2fe:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 300:	15fd                	addi	a1,a1,-1
 302:	177d                	addi	a4,a4,-1
 304:	0005c683          	lbu	a3,0(a1)
 308:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 30c:	fee79ae3          	bne	a5,a4,300 <memmove+0x4a>
 310:	bfc9                	j	2e2 <memmove+0x2c>

0000000000000312 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 312:	1141                	addi	sp,sp,-16
 314:	e422                	sd	s0,8(sp)
 316:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 318:	ca05                	beqz	a2,348 <memcmp+0x36>
 31a:	fff6069b          	addiw	a3,a2,-1
 31e:	1682                	slli	a3,a3,0x20
 320:	9281                	srli	a3,a3,0x20
 322:	0685                	addi	a3,a3,1
 324:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 326:	00054783          	lbu	a5,0(a0)
 32a:	0005c703          	lbu	a4,0(a1)
 32e:	00e79863          	bne	a5,a4,33e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 332:	0505                	addi	a0,a0,1
    p2++;
 334:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 336:	fed518e3          	bne	a0,a3,326 <memcmp+0x14>
  }
  return 0;
 33a:	4501                	li	a0,0
 33c:	a019                	j	342 <memcmp+0x30>
      return *p1 - *p2;
 33e:	40e7853b          	subw	a0,a5,a4
}
 342:	6422                	ld	s0,8(sp)
 344:	0141                	addi	sp,sp,16
 346:	8082                	ret
  return 0;
 348:	4501                	li	a0,0
 34a:	bfe5                	j	342 <memcmp+0x30>

000000000000034c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 34c:	1141                	addi	sp,sp,-16
 34e:	e406                	sd	ra,8(sp)
 350:	e022                	sd	s0,0(sp)
 352:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 354:	00000097          	auipc	ra,0x0
 358:	f62080e7          	jalr	-158(ra) # 2b6 <memmove>
}
 35c:	60a2                	ld	ra,8(sp)
 35e:	6402                	ld	s0,0(sp)
 360:	0141                	addi	sp,sp,16
 362:	8082                	ret

0000000000000364 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 364:	4885                	li	a7,1
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <exit>:
.global exit
exit:
 li a7, SYS_exit
 36c:	4889                	li	a7,2
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <wait>:
.global wait
wait:
 li a7, SYS_wait
 374:	488d                	li	a7,3
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 37c:	4891                	li	a7,4
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <read>:
.global read
read:
 li a7, SYS_read
 384:	4895                	li	a7,5
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <write>:
.global write
write:
 li a7, SYS_write
 38c:	48c1                	li	a7,16
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <close>:
.global close
close:
 li a7, SYS_close
 394:	48d5                	li	a7,21
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <kill>:
.global kill
kill:
 li a7, SYS_kill
 39c:	4899                	li	a7,6
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3a4:	489d                	li	a7,7
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <open>:
.global open
open:
 li a7, SYS_open
 3ac:	48bd                	li	a7,15
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3b4:	48c5                	li	a7,17
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3bc:	48c9                	li	a7,18
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3c4:	48a1                	li	a7,8
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <link>:
.global link
link:
 li a7, SYS_link
 3cc:	48cd                	li	a7,19
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3d4:	48d1                	li	a7,20
 ecall
 3d6:	00000073          	ecall
 ret
 3da:	8082                	ret

00000000000003dc <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3dc:	48a5                	li	a7,9
 ecall
 3de:	00000073          	ecall
 ret
 3e2:	8082                	ret

00000000000003e4 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3e4:	48a9                	li	a7,10
 ecall
 3e6:	00000073          	ecall
 ret
 3ea:	8082                	ret

00000000000003ec <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3ec:	48ad                	li	a7,11
 ecall
 3ee:	00000073          	ecall
 ret
 3f2:	8082                	ret

00000000000003f4 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3f4:	48b1                	li	a7,12
 ecall
 3f6:	00000073          	ecall
 ret
 3fa:	8082                	ret

00000000000003fc <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3fc:	48b5                	li	a7,13
 ecall
 3fe:	00000073          	ecall
 ret
 402:	8082                	ret

0000000000000404 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 404:	48b9                	li	a7,14
 ecall
 406:	00000073          	ecall
 ret
 40a:	8082                	ret

000000000000040c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 40c:	1101                	addi	sp,sp,-32
 40e:	ec06                	sd	ra,24(sp)
 410:	e822                	sd	s0,16(sp)
 412:	1000                	addi	s0,sp,32
 414:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 418:	4605                	li	a2,1
 41a:	fef40593          	addi	a1,s0,-17
 41e:	00000097          	auipc	ra,0x0
 422:	f6e080e7          	jalr	-146(ra) # 38c <write>
}
 426:	60e2                	ld	ra,24(sp)
 428:	6442                	ld	s0,16(sp)
 42a:	6105                	addi	sp,sp,32
 42c:	8082                	ret

000000000000042e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 42e:	7139                	addi	sp,sp,-64
 430:	fc06                	sd	ra,56(sp)
 432:	f822                	sd	s0,48(sp)
 434:	f426                	sd	s1,40(sp)
 436:	f04a                	sd	s2,32(sp)
 438:	ec4e                	sd	s3,24(sp)
 43a:	0080                	addi	s0,sp,64
 43c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 43e:	c299                	beqz	a3,444 <printint+0x16>
 440:	0805c863          	bltz	a1,4d0 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 444:	2581                	sext.w	a1,a1
  neg = 0;
 446:	4881                	li	a7,0
 448:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 44c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 44e:	2601                	sext.w	a2,a2
 450:	00000517          	auipc	a0,0x0
 454:	46850513          	addi	a0,a0,1128 # 8b8 <digits>
 458:	883a                	mv	a6,a4
 45a:	2705                	addiw	a4,a4,1
 45c:	02c5f7bb          	remuw	a5,a1,a2
 460:	1782                	slli	a5,a5,0x20
 462:	9381                	srli	a5,a5,0x20
 464:	97aa                	add	a5,a5,a0
 466:	0007c783          	lbu	a5,0(a5)
 46a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 46e:	0005879b          	sext.w	a5,a1
 472:	02c5d5bb          	divuw	a1,a1,a2
 476:	0685                	addi	a3,a3,1
 478:	fec7f0e3          	bgeu	a5,a2,458 <printint+0x2a>
  if(neg)
 47c:	00088b63          	beqz	a7,492 <printint+0x64>
    buf[i++] = '-';
 480:	fd040793          	addi	a5,s0,-48
 484:	973e                	add	a4,a4,a5
 486:	02d00793          	li	a5,45
 48a:	fef70823          	sb	a5,-16(a4)
 48e:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 492:	02e05863          	blez	a4,4c2 <printint+0x94>
 496:	fc040793          	addi	a5,s0,-64
 49a:	00e78933          	add	s2,a5,a4
 49e:	fff78993          	addi	s3,a5,-1
 4a2:	99ba                	add	s3,s3,a4
 4a4:	377d                	addiw	a4,a4,-1
 4a6:	1702                	slli	a4,a4,0x20
 4a8:	9301                	srli	a4,a4,0x20
 4aa:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4ae:	fff94583          	lbu	a1,-1(s2)
 4b2:	8526                	mv	a0,s1
 4b4:	00000097          	auipc	ra,0x0
 4b8:	f58080e7          	jalr	-168(ra) # 40c <putc>
  while(--i >= 0)
 4bc:	197d                	addi	s2,s2,-1
 4be:	ff3918e3          	bne	s2,s3,4ae <printint+0x80>
}
 4c2:	70e2                	ld	ra,56(sp)
 4c4:	7442                	ld	s0,48(sp)
 4c6:	74a2                	ld	s1,40(sp)
 4c8:	7902                	ld	s2,32(sp)
 4ca:	69e2                	ld	s3,24(sp)
 4cc:	6121                	addi	sp,sp,64
 4ce:	8082                	ret
    x = -xx;
 4d0:	40b005bb          	negw	a1,a1
    neg = 1;
 4d4:	4885                	li	a7,1
    x = -xx;
 4d6:	bf8d                	j	448 <printint+0x1a>

00000000000004d8 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4d8:	7119                	addi	sp,sp,-128
 4da:	fc86                	sd	ra,120(sp)
 4dc:	f8a2                	sd	s0,112(sp)
 4de:	f4a6                	sd	s1,104(sp)
 4e0:	f0ca                	sd	s2,96(sp)
 4e2:	ecce                	sd	s3,88(sp)
 4e4:	e8d2                	sd	s4,80(sp)
 4e6:	e4d6                	sd	s5,72(sp)
 4e8:	e0da                	sd	s6,64(sp)
 4ea:	fc5e                	sd	s7,56(sp)
 4ec:	f862                	sd	s8,48(sp)
 4ee:	f466                	sd	s9,40(sp)
 4f0:	f06a                	sd	s10,32(sp)
 4f2:	ec6e                	sd	s11,24(sp)
 4f4:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4f6:	0005c903          	lbu	s2,0(a1)
 4fa:	18090f63          	beqz	s2,698 <vprintf+0x1c0>
 4fe:	8aaa                	mv	s5,a0
 500:	8b32                	mv	s6,a2
 502:	00158493          	addi	s1,a1,1
  state = 0;
 506:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 508:	02500a13          	li	s4,37
      if(c == 'd'){
 50c:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 510:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 514:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 518:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 51c:	00000b97          	auipc	s7,0x0
 520:	39cb8b93          	addi	s7,s7,924 # 8b8 <digits>
 524:	a839                	j	542 <vprintf+0x6a>
        putc(fd, c);
 526:	85ca                	mv	a1,s2
 528:	8556                	mv	a0,s5
 52a:	00000097          	auipc	ra,0x0
 52e:	ee2080e7          	jalr	-286(ra) # 40c <putc>
 532:	a019                	j	538 <vprintf+0x60>
    } else if(state == '%'){
 534:	01498f63          	beq	s3,s4,552 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 538:	0485                	addi	s1,s1,1
 53a:	fff4c903          	lbu	s2,-1(s1)
 53e:	14090d63          	beqz	s2,698 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 542:	0009079b          	sext.w	a5,s2
    if(state == 0){
 546:	fe0997e3          	bnez	s3,534 <vprintf+0x5c>
      if(c == '%'){
 54a:	fd479ee3          	bne	a5,s4,526 <vprintf+0x4e>
        state = '%';
 54e:	89be                	mv	s3,a5
 550:	b7e5                	j	538 <vprintf+0x60>
      if(c == 'd'){
 552:	05878063          	beq	a5,s8,592 <vprintf+0xba>
      } else if(c == 'l') {
 556:	05978c63          	beq	a5,s9,5ae <vprintf+0xd6>
      } else if(c == 'x') {
 55a:	07a78863          	beq	a5,s10,5ca <vprintf+0xf2>
      } else if(c == 'p') {
 55e:	09b78463          	beq	a5,s11,5e6 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 562:	07300713          	li	a4,115
 566:	0ce78663          	beq	a5,a4,632 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 56a:	06300713          	li	a4,99
 56e:	0ee78e63          	beq	a5,a4,66a <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 572:	11478863          	beq	a5,s4,682 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 576:	85d2                	mv	a1,s4
 578:	8556                	mv	a0,s5
 57a:	00000097          	auipc	ra,0x0
 57e:	e92080e7          	jalr	-366(ra) # 40c <putc>
        putc(fd, c);
 582:	85ca                	mv	a1,s2
 584:	8556                	mv	a0,s5
 586:	00000097          	auipc	ra,0x0
 58a:	e86080e7          	jalr	-378(ra) # 40c <putc>
      }
      state = 0;
 58e:	4981                	li	s3,0
 590:	b765                	j	538 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 592:	008b0913          	addi	s2,s6,8
 596:	4685                	li	a3,1
 598:	4629                	li	a2,10
 59a:	000b2583          	lw	a1,0(s6)
 59e:	8556                	mv	a0,s5
 5a0:	00000097          	auipc	ra,0x0
 5a4:	e8e080e7          	jalr	-370(ra) # 42e <printint>
 5a8:	8b4a                	mv	s6,s2
      state = 0;
 5aa:	4981                	li	s3,0
 5ac:	b771                	j	538 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5ae:	008b0913          	addi	s2,s6,8
 5b2:	4681                	li	a3,0
 5b4:	4629                	li	a2,10
 5b6:	000b2583          	lw	a1,0(s6)
 5ba:	8556                	mv	a0,s5
 5bc:	00000097          	auipc	ra,0x0
 5c0:	e72080e7          	jalr	-398(ra) # 42e <printint>
 5c4:	8b4a                	mv	s6,s2
      state = 0;
 5c6:	4981                	li	s3,0
 5c8:	bf85                	j	538 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5ca:	008b0913          	addi	s2,s6,8
 5ce:	4681                	li	a3,0
 5d0:	4641                	li	a2,16
 5d2:	000b2583          	lw	a1,0(s6)
 5d6:	8556                	mv	a0,s5
 5d8:	00000097          	auipc	ra,0x0
 5dc:	e56080e7          	jalr	-426(ra) # 42e <printint>
 5e0:	8b4a                	mv	s6,s2
      state = 0;
 5e2:	4981                	li	s3,0
 5e4:	bf91                	j	538 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5e6:	008b0793          	addi	a5,s6,8
 5ea:	f8f43423          	sd	a5,-120(s0)
 5ee:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5f2:	03000593          	li	a1,48
 5f6:	8556                	mv	a0,s5
 5f8:	00000097          	auipc	ra,0x0
 5fc:	e14080e7          	jalr	-492(ra) # 40c <putc>
  putc(fd, 'x');
 600:	85ea                	mv	a1,s10
 602:	8556                	mv	a0,s5
 604:	00000097          	auipc	ra,0x0
 608:	e08080e7          	jalr	-504(ra) # 40c <putc>
 60c:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 60e:	03c9d793          	srli	a5,s3,0x3c
 612:	97de                	add	a5,a5,s7
 614:	0007c583          	lbu	a1,0(a5)
 618:	8556                	mv	a0,s5
 61a:	00000097          	auipc	ra,0x0
 61e:	df2080e7          	jalr	-526(ra) # 40c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 622:	0992                	slli	s3,s3,0x4
 624:	397d                	addiw	s2,s2,-1
 626:	fe0914e3          	bnez	s2,60e <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 62a:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 62e:	4981                	li	s3,0
 630:	b721                	j	538 <vprintf+0x60>
        s = va_arg(ap, char*);
 632:	008b0993          	addi	s3,s6,8
 636:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 63a:	02090163          	beqz	s2,65c <vprintf+0x184>
        while(*s != 0){
 63e:	00094583          	lbu	a1,0(s2)
 642:	c9a1                	beqz	a1,692 <vprintf+0x1ba>
          putc(fd, *s);
 644:	8556                	mv	a0,s5
 646:	00000097          	auipc	ra,0x0
 64a:	dc6080e7          	jalr	-570(ra) # 40c <putc>
          s++;
 64e:	0905                	addi	s2,s2,1
        while(*s != 0){
 650:	00094583          	lbu	a1,0(s2)
 654:	f9e5                	bnez	a1,644 <vprintf+0x16c>
        s = va_arg(ap, char*);
 656:	8b4e                	mv	s6,s3
      state = 0;
 658:	4981                	li	s3,0
 65a:	bdf9                	j	538 <vprintf+0x60>
          s = "(null)";
 65c:	00000917          	auipc	s2,0x0
 660:	25490913          	addi	s2,s2,596 # 8b0 <malloc+0x10e>
        while(*s != 0){
 664:	02800593          	li	a1,40
 668:	bff1                	j	644 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 66a:	008b0913          	addi	s2,s6,8
 66e:	000b4583          	lbu	a1,0(s6)
 672:	8556                	mv	a0,s5
 674:	00000097          	auipc	ra,0x0
 678:	d98080e7          	jalr	-616(ra) # 40c <putc>
 67c:	8b4a                	mv	s6,s2
      state = 0;
 67e:	4981                	li	s3,0
 680:	bd65                	j	538 <vprintf+0x60>
        putc(fd, c);
 682:	85d2                	mv	a1,s4
 684:	8556                	mv	a0,s5
 686:	00000097          	auipc	ra,0x0
 68a:	d86080e7          	jalr	-634(ra) # 40c <putc>
      state = 0;
 68e:	4981                	li	s3,0
 690:	b565                	j	538 <vprintf+0x60>
        s = va_arg(ap, char*);
 692:	8b4e                	mv	s6,s3
      state = 0;
 694:	4981                	li	s3,0
 696:	b54d                	j	538 <vprintf+0x60>
    }
  }
}
 698:	70e6                	ld	ra,120(sp)
 69a:	7446                	ld	s0,112(sp)
 69c:	74a6                	ld	s1,104(sp)
 69e:	7906                	ld	s2,96(sp)
 6a0:	69e6                	ld	s3,88(sp)
 6a2:	6a46                	ld	s4,80(sp)
 6a4:	6aa6                	ld	s5,72(sp)
 6a6:	6b06                	ld	s6,64(sp)
 6a8:	7be2                	ld	s7,56(sp)
 6aa:	7c42                	ld	s8,48(sp)
 6ac:	7ca2                	ld	s9,40(sp)
 6ae:	7d02                	ld	s10,32(sp)
 6b0:	6de2                	ld	s11,24(sp)
 6b2:	6109                	addi	sp,sp,128
 6b4:	8082                	ret

00000000000006b6 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6b6:	715d                	addi	sp,sp,-80
 6b8:	ec06                	sd	ra,24(sp)
 6ba:	e822                	sd	s0,16(sp)
 6bc:	1000                	addi	s0,sp,32
 6be:	e010                	sd	a2,0(s0)
 6c0:	e414                	sd	a3,8(s0)
 6c2:	e818                	sd	a4,16(s0)
 6c4:	ec1c                	sd	a5,24(s0)
 6c6:	03043023          	sd	a6,32(s0)
 6ca:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6ce:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6d2:	8622                	mv	a2,s0
 6d4:	00000097          	auipc	ra,0x0
 6d8:	e04080e7          	jalr	-508(ra) # 4d8 <vprintf>
}
 6dc:	60e2                	ld	ra,24(sp)
 6de:	6442                	ld	s0,16(sp)
 6e0:	6161                	addi	sp,sp,80
 6e2:	8082                	ret

00000000000006e4 <printf>:

void
printf(const char *fmt, ...)
{
 6e4:	711d                	addi	sp,sp,-96
 6e6:	ec06                	sd	ra,24(sp)
 6e8:	e822                	sd	s0,16(sp)
 6ea:	1000                	addi	s0,sp,32
 6ec:	e40c                	sd	a1,8(s0)
 6ee:	e810                	sd	a2,16(s0)
 6f0:	ec14                	sd	a3,24(s0)
 6f2:	f018                	sd	a4,32(s0)
 6f4:	f41c                	sd	a5,40(s0)
 6f6:	03043823          	sd	a6,48(s0)
 6fa:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6fe:	00840613          	addi	a2,s0,8
 702:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 706:	85aa                	mv	a1,a0
 708:	4505                	li	a0,1
 70a:	00000097          	auipc	ra,0x0
 70e:	dce080e7          	jalr	-562(ra) # 4d8 <vprintf>
}
 712:	60e2                	ld	ra,24(sp)
 714:	6442                	ld	s0,16(sp)
 716:	6125                	addi	sp,sp,96
 718:	8082                	ret

000000000000071a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 71a:	1141                	addi	sp,sp,-16
 71c:	e422                	sd	s0,8(sp)
 71e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 720:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 724:	00000797          	auipc	a5,0x0
 728:	1ac7b783          	ld	a5,428(a5) # 8d0 <freep>
 72c:	a805                	j	75c <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 72e:	4618                	lw	a4,8(a2)
 730:	9db9                	addw	a1,a1,a4
 732:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 736:	6398                	ld	a4,0(a5)
 738:	6318                	ld	a4,0(a4)
 73a:	fee53823          	sd	a4,-16(a0)
 73e:	a091                	j	782 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 740:	ff852703          	lw	a4,-8(a0)
 744:	9e39                	addw	a2,a2,a4
 746:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 748:	ff053703          	ld	a4,-16(a0)
 74c:	e398                	sd	a4,0(a5)
 74e:	a099                	j	794 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 750:	6398                	ld	a4,0(a5)
 752:	00e7e463          	bltu	a5,a4,75a <free+0x40>
 756:	00e6ea63          	bltu	a3,a4,76a <free+0x50>
{
 75a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 75c:	fed7fae3          	bgeu	a5,a3,750 <free+0x36>
 760:	6398                	ld	a4,0(a5)
 762:	00e6e463          	bltu	a3,a4,76a <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 766:	fee7eae3          	bltu	a5,a4,75a <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 76a:	ff852583          	lw	a1,-8(a0)
 76e:	6390                	ld	a2,0(a5)
 770:	02059713          	slli	a4,a1,0x20
 774:	9301                	srli	a4,a4,0x20
 776:	0712                	slli	a4,a4,0x4
 778:	9736                	add	a4,a4,a3
 77a:	fae60ae3          	beq	a2,a4,72e <free+0x14>
    bp->s.ptr = p->s.ptr;
 77e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 782:	4790                	lw	a2,8(a5)
 784:	02061713          	slli	a4,a2,0x20
 788:	9301                	srli	a4,a4,0x20
 78a:	0712                	slli	a4,a4,0x4
 78c:	973e                	add	a4,a4,a5
 78e:	fae689e3          	beq	a3,a4,740 <free+0x26>
  } else
    p->s.ptr = bp;
 792:	e394                	sd	a3,0(a5)
  freep = p;
 794:	00000717          	auipc	a4,0x0
 798:	12f73e23          	sd	a5,316(a4) # 8d0 <freep>
}
 79c:	6422                	ld	s0,8(sp)
 79e:	0141                	addi	sp,sp,16
 7a0:	8082                	ret

00000000000007a2 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7a2:	7139                	addi	sp,sp,-64
 7a4:	fc06                	sd	ra,56(sp)
 7a6:	f822                	sd	s0,48(sp)
 7a8:	f426                	sd	s1,40(sp)
 7aa:	f04a                	sd	s2,32(sp)
 7ac:	ec4e                	sd	s3,24(sp)
 7ae:	e852                	sd	s4,16(sp)
 7b0:	e456                	sd	s5,8(sp)
 7b2:	e05a                	sd	s6,0(sp)
 7b4:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7b6:	02051493          	slli	s1,a0,0x20
 7ba:	9081                	srli	s1,s1,0x20
 7bc:	04bd                	addi	s1,s1,15
 7be:	8091                	srli	s1,s1,0x4
 7c0:	0014899b          	addiw	s3,s1,1
 7c4:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7c6:	00000517          	auipc	a0,0x0
 7ca:	10a53503          	ld	a0,266(a0) # 8d0 <freep>
 7ce:	c515                	beqz	a0,7fa <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7d0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7d2:	4798                	lw	a4,8(a5)
 7d4:	02977f63          	bgeu	a4,s1,812 <malloc+0x70>
 7d8:	8a4e                	mv	s4,s3
 7da:	0009871b          	sext.w	a4,s3
 7de:	6685                	lui	a3,0x1
 7e0:	00d77363          	bgeu	a4,a3,7e6 <malloc+0x44>
 7e4:	6a05                	lui	s4,0x1
 7e6:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7ea:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7ee:	00000917          	auipc	s2,0x0
 7f2:	0e290913          	addi	s2,s2,226 # 8d0 <freep>
  if(p == (char*)-1)
 7f6:	5afd                	li	s5,-1
 7f8:	a88d                	j	86a <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 7fa:	00000797          	auipc	a5,0x0
 7fe:	0de78793          	addi	a5,a5,222 # 8d8 <base>
 802:	00000717          	auipc	a4,0x0
 806:	0cf73723          	sd	a5,206(a4) # 8d0 <freep>
 80a:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 80c:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 810:	b7e1                	j	7d8 <malloc+0x36>
      if(p->s.size == nunits)
 812:	02e48b63          	beq	s1,a4,848 <malloc+0xa6>
        p->s.size -= nunits;
 816:	4137073b          	subw	a4,a4,s3
 81a:	c798                	sw	a4,8(a5)
        p += p->s.size;
 81c:	1702                	slli	a4,a4,0x20
 81e:	9301                	srli	a4,a4,0x20
 820:	0712                	slli	a4,a4,0x4
 822:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 824:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 828:	00000717          	auipc	a4,0x0
 82c:	0aa73423          	sd	a0,168(a4) # 8d0 <freep>
      return (void*)(p + 1);
 830:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 834:	70e2                	ld	ra,56(sp)
 836:	7442                	ld	s0,48(sp)
 838:	74a2                	ld	s1,40(sp)
 83a:	7902                	ld	s2,32(sp)
 83c:	69e2                	ld	s3,24(sp)
 83e:	6a42                	ld	s4,16(sp)
 840:	6aa2                	ld	s5,8(sp)
 842:	6b02                	ld	s6,0(sp)
 844:	6121                	addi	sp,sp,64
 846:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 848:	6398                	ld	a4,0(a5)
 84a:	e118                	sd	a4,0(a0)
 84c:	bff1                	j	828 <malloc+0x86>
  hp->s.size = nu;
 84e:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 852:	0541                	addi	a0,a0,16
 854:	00000097          	auipc	ra,0x0
 858:	ec6080e7          	jalr	-314(ra) # 71a <free>
  return freep;
 85c:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 860:	d971                	beqz	a0,834 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 862:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 864:	4798                	lw	a4,8(a5)
 866:	fa9776e3          	bgeu	a4,s1,812 <malloc+0x70>
    if(p == freep)
 86a:	00093703          	ld	a4,0(s2)
 86e:	853e                	mv	a0,a5
 870:	fef719e3          	bne	a4,a5,862 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 874:	8552                	mv	a0,s4
 876:	00000097          	auipc	ra,0x0
 87a:	b7e080e7          	jalr	-1154(ra) # 3f4 <sbrk>
  if(p == (char*)-1)
 87e:	fd5518e3          	bne	a0,s5,84e <malloc+0xac>
        return 0;
 882:	4501                	li	a0,0
 884:	bf45                	j	834 <malloc+0x92>
