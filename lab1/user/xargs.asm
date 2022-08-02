
user/_xargs:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "user/user.h"

#define NULL (int *)0

int main(int argc, char *argv[])
{
   0:	7145                	addi	sp,sp,-464
   2:	e786                	sd	ra,456(sp)
   4:	e3a2                	sd	s0,448(sp)
   6:	ff26                	sd	s1,440(sp)
   8:	fb4a                	sd	s2,432(sp)
   a:	f74e                	sd	s3,424(sp)
   c:	f352                	sd	s4,416(sp)
   e:	ef56                	sd	s5,408(sp)
  10:	0b80                	addi	s0,sp,464
  12:	8aaa                	mv	s5,a0
    char *new_argv[MAXARG];
    int cur_argv;
    for (cur_argv = 1; cur_argv <= argc - 1; cur_argv++)
  14:	4785                	li	a5,1
  16:	02a7d463          	bge	a5,a0,3e <main+0x3e>
  1a:	00858713          	addi	a4,a1,8
  1e:	ec040793          	addi	a5,s0,-320
  22:	ffe5061b          	addiw	a2,a0,-2
  26:	1602                	slli	a2,a2,0x20
  28:	9201                	srli	a2,a2,0x20
  2a:	060e                	slli	a2,a2,0x3
  2c:	ec840693          	addi	a3,s0,-312
  30:	9636                	add	a2,a2,a3
    {
        new_argv[cur_argv - 1] = argv[cur_argv];
  32:	6314                	ld	a3,0(a4)
  34:	e394                	sd	a3,0(a5)
    for (cur_argv = 1; cur_argv <= argc - 1; cur_argv++)
  36:	0721                	addi	a4,a4,8
  38:	07a1                	addi	a5,a5,8
  3a:	fec79ce3          	bne	a5,a2,32 <main+0x32>
    }
    char ch;
    char buf[128];
    char *cur_buf = buf;
    new_argv[argc - 1] = buf;
  3e:	fffa879b          	addiw	a5,s5,-1
  42:	078e                	slli	a5,a5,0x3
  44:	fc040713          	addi	a4,s0,-64
  48:	97ba                	add	a5,a5,a4
  4a:	e3840493          	addi	s1,s0,-456
  4e:	f097b023          	sd	s1,-256(a5)
    cur_argv = argc;
  52:	8956                	mv	s2,s5
    while (read(0, &ch, sizeof(char)) == sizeof(char))
    {
        if (ch == ' ')
  54:	02000993          	li	s3,32
            *cur_buf = '\0';
            cur_buf++;
            new_argv[cur_argv] = cur_buf;
            cur_argv++;
        }
        else if (ch == '\n')
  58:	4a29                	li	s4,10
    while (read(0, &ch, sizeof(char)) == sizeof(char))
  5a:	a821                	j	72 <main+0x72>
            *cur_buf = '\0';
  5c:	00048023          	sb	zero,0(s1)
            cur_buf++;
  60:	0485                	addi	s1,s1,1
            new_argv[cur_argv] = cur_buf;
  62:	00391793          	slli	a5,s2,0x3
  66:	fc040713          	addi	a4,s0,-64
  6a:	97ba                	add	a5,a5,a4
  6c:	f097b023          	sd	s1,-256(a5)
            cur_argv++;
  70:	2905                	addiw	s2,s2,1
    while (read(0, &ch, sizeof(char)) == sizeof(char))
  72:	4605                	li	a2,1
  74:	ebf40593          	addi	a1,s0,-321
  78:	4501                	li	a0,0
  7a:	00000097          	auipc	ra,0x0
  7e:	300080e7          	jalr	768(ra) # 37a <read>
  82:	4785                	li	a5,1
  84:	04f51f63          	bne	a0,a5,e2 <main+0xe2>
        if (ch == ' ')
  88:	ebf44783          	lbu	a5,-321(s0)
  8c:	fd3788e3          	beq	a5,s3,5c <main+0x5c>
        else if (ch == '\n')
  90:	01478663          	beq	a5,s4,9c <main+0x9c>
                cur_argv = argc;
            }
        }
        else
        {
            *cur_buf = ch;
  94:	00f48023          	sb	a5,0(s1)
            cur_buf++;
  98:	0485                	addi	s1,s1,1
  9a:	bfe1                	j	72 <main+0x72>
            *cur_buf = '\0';
  9c:	00048023          	sb	zero,0(s1)
            new_argv[cur_argv] = 0;
  a0:	090e                	slli	s2,s2,0x3
  a2:	fc040793          	addi	a5,s0,-64
  a6:	993e                	add	s2,s2,a5
  a8:	f0093023          	sd	zero,-256(s2)
            int pid = fork();
  ac:	00000097          	auipc	ra,0x0
  b0:	2ae080e7          	jalr	686(ra) # 35a <fork>
            if (pid == 0)
  b4:	c911                	beqz	a0,c8 <main+0xc8>
                wait(NULL);
  b6:	4501                	li	a0,0
  b8:	00000097          	auipc	ra,0x0
  bc:	2b2080e7          	jalr	690(ra) # 36a <wait>
                cur_argv = argc;
  c0:	8956                	mv	s2,s5
                cur_buf = buf;
  c2:	e3840493          	addi	s1,s0,-456
  c6:	b775                	j	72 <main+0x72>
                exec(new_argv[0], new_argv);
  c8:	ec040593          	addi	a1,s0,-320
  cc:	ec043503          	ld	a0,-320(s0)
  d0:	00000097          	auipc	ra,0x0
  d4:	2ca080e7          	jalr	714(ra) # 39a <exec>
                exit(0);
  d8:	4501                	li	a0,0
  da:	00000097          	auipc	ra,0x0
  de:	288080e7          	jalr	648(ra) # 362 <exit>
        }
    }
    exit(0);
  e2:	4501                	li	a0,0
  e4:	00000097          	auipc	ra,0x0
  e8:	27e080e7          	jalr	638(ra) # 362 <exit>

00000000000000ec <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  ec:	1141                	addi	sp,sp,-16
  ee:	e422                	sd	s0,8(sp)
  f0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  f2:	87aa                	mv	a5,a0
  f4:	0585                	addi	a1,a1,1
  f6:	0785                	addi	a5,a5,1
  f8:	fff5c703          	lbu	a4,-1(a1)
  fc:	fee78fa3          	sb	a4,-1(a5)
 100:	fb75                	bnez	a4,f4 <strcpy+0x8>
    ;
  return os;
}
 102:	6422                	ld	s0,8(sp)
 104:	0141                	addi	sp,sp,16
 106:	8082                	ret

0000000000000108 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 108:	1141                	addi	sp,sp,-16
 10a:	e422                	sd	s0,8(sp)
 10c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 10e:	00054783          	lbu	a5,0(a0)
 112:	cb91                	beqz	a5,126 <strcmp+0x1e>
 114:	0005c703          	lbu	a4,0(a1)
 118:	00f71763          	bne	a4,a5,126 <strcmp+0x1e>
    p++, q++;
 11c:	0505                	addi	a0,a0,1
 11e:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 120:	00054783          	lbu	a5,0(a0)
 124:	fbe5                	bnez	a5,114 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 126:	0005c503          	lbu	a0,0(a1)
}
 12a:	40a7853b          	subw	a0,a5,a0
 12e:	6422                	ld	s0,8(sp)
 130:	0141                	addi	sp,sp,16
 132:	8082                	ret

0000000000000134 <strlen>:

uint
strlen(const char *s)
{
 134:	1141                	addi	sp,sp,-16
 136:	e422                	sd	s0,8(sp)
 138:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 13a:	00054783          	lbu	a5,0(a0)
 13e:	cf91                	beqz	a5,15a <strlen+0x26>
 140:	0505                	addi	a0,a0,1
 142:	87aa                	mv	a5,a0
 144:	4685                	li	a3,1
 146:	9e89                	subw	a3,a3,a0
 148:	00f6853b          	addw	a0,a3,a5
 14c:	0785                	addi	a5,a5,1
 14e:	fff7c703          	lbu	a4,-1(a5)
 152:	fb7d                	bnez	a4,148 <strlen+0x14>
    ;
  return n;
}
 154:	6422                	ld	s0,8(sp)
 156:	0141                	addi	sp,sp,16
 158:	8082                	ret
  for(n = 0; s[n]; n++)
 15a:	4501                	li	a0,0
 15c:	bfe5                	j	154 <strlen+0x20>

000000000000015e <memset>:

void*
memset(void *dst, int c, uint n)
{
 15e:	1141                	addi	sp,sp,-16
 160:	e422                	sd	s0,8(sp)
 162:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 164:	ce09                	beqz	a2,17e <memset+0x20>
 166:	87aa                	mv	a5,a0
 168:	fff6071b          	addiw	a4,a2,-1
 16c:	1702                	slli	a4,a4,0x20
 16e:	9301                	srli	a4,a4,0x20
 170:	0705                	addi	a4,a4,1
 172:	972a                	add	a4,a4,a0
    cdst[i] = c;
 174:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 178:	0785                	addi	a5,a5,1
 17a:	fee79de3          	bne	a5,a4,174 <memset+0x16>
  }
  return dst;
}
 17e:	6422                	ld	s0,8(sp)
 180:	0141                	addi	sp,sp,16
 182:	8082                	ret

0000000000000184 <strchr>:

char*
strchr(const char *s, char c)
{
 184:	1141                	addi	sp,sp,-16
 186:	e422                	sd	s0,8(sp)
 188:	0800                	addi	s0,sp,16
  for(; *s; s++)
 18a:	00054783          	lbu	a5,0(a0)
 18e:	cb99                	beqz	a5,1a4 <strchr+0x20>
    if(*s == c)
 190:	00f58763          	beq	a1,a5,19e <strchr+0x1a>
  for(; *s; s++)
 194:	0505                	addi	a0,a0,1
 196:	00054783          	lbu	a5,0(a0)
 19a:	fbfd                	bnez	a5,190 <strchr+0xc>
      return (char*)s;
  return 0;
 19c:	4501                	li	a0,0
}
 19e:	6422                	ld	s0,8(sp)
 1a0:	0141                	addi	sp,sp,16
 1a2:	8082                	ret
  return 0;
 1a4:	4501                	li	a0,0
 1a6:	bfe5                	j	19e <strchr+0x1a>

00000000000001a8 <gets>:

char*
gets(char *buf, int max)
{
 1a8:	711d                	addi	sp,sp,-96
 1aa:	ec86                	sd	ra,88(sp)
 1ac:	e8a2                	sd	s0,80(sp)
 1ae:	e4a6                	sd	s1,72(sp)
 1b0:	e0ca                	sd	s2,64(sp)
 1b2:	fc4e                	sd	s3,56(sp)
 1b4:	f852                	sd	s4,48(sp)
 1b6:	f456                	sd	s5,40(sp)
 1b8:	f05a                	sd	s6,32(sp)
 1ba:	ec5e                	sd	s7,24(sp)
 1bc:	1080                	addi	s0,sp,96
 1be:	8baa                	mv	s7,a0
 1c0:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1c2:	892a                	mv	s2,a0
 1c4:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1c6:	4aa9                	li	s5,10
 1c8:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1ca:	89a6                	mv	s3,s1
 1cc:	2485                	addiw	s1,s1,1
 1ce:	0344d863          	bge	s1,s4,1fe <gets+0x56>
    cc = read(0, &c, 1);
 1d2:	4605                	li	a2,1
 1d4:	faf40593          	addi	a1,s0,-81
 1d8:	4501                	li	a0,0
 1da:	00000097          	auipc	ra,0x0
 1de:	1a0080e7          	jalr	416(ra) # 37a <read>
    if(cc < 1)
 1e2:	00a05e63          	blez	a0,1fe <gets+0x56>
    buf[i++] = c;
 1e6:	faf44783          	lbu	a5,-81(s0)
 1ea:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1ee:	01578763          	beq	a5,s5,1fc <gets+0x54>
 1f2:	0905                	addi	s2,s2,1
 1f4:	fd679be3          	bne	a5,s6,1ca <gets+0x22>
  for(i=0; i+1 < max; ){
 1f8:	89a6                	mv	s3,s1
 1fa:	a011                	j	1fe <gets+0x56>
 1fc:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1fe:	99de                	add	s3,s3,s7
 200:	00098023          	sb	zero,0(s3)
  return buf;
}
 204:	855e                	mv	a0,s7
 206:	60e6                	ld	ra,88(sp)
 208:	6446                	ld	s0,80(sp)
 20a:	64a6                	ld	s1,72(sp)
 20c:	6906                	ld	s2,64(sp)
 20e:	79e2                	ld	s3,56(sp)
 210:	7a42                	ld	s4,48(sp)
 212:	7aa2                	ld	s5,40(sp)
 214:	7b02                	ld	s6,32(sp)
 216:	6be2                	ld	s7,24(sp)
 218:	6125                	addi	sp,sp,96
 21a:	8082                	ret

000000000000021c <stat>:

int
stat(const char *n, struct stat *st)
{
 21c:	1101                	addi	sp,sp,-32
 21e:	ec06                	sd	ra,24(sp)
 220:	e822                	sd	s0,16(sp)
 222:	e426                	sd	s1,8(sp)
 224:	e04a                	sd	s2,0(sp)
 226:	1000                	addi	s0,sp,32
 228:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 22a:	4581                	li	a1,0
 22c:	00000097          	auipc	ra,0x0
 230:	176080e7          	jalr	374(ra) # 3a2 <open>
  if(fd < 0)
 234:	02054563          	bltz	a0,25e <stat+0x42>
 238:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 23a:	85ca                	mv	a1,s2
 23c:	00000097          	auipc	ra,0x0
 240:	17e080e7          	jalr	382(ra) # 3ba <fstat>
 244:	892a                	mv	s2,a0
  close(fd);
 246:	8526                	mv	a0,s1
 248:	00000097          	auipc	ra,0x0
 24c:	142080e7          	jalr	322(ra) # 38a <close>
  return r;
}
 250:	854a                	mv	a0,s2
 252:	60e2                	ld	ra,24(sp)
 254:	6442                	ld	s0,16(sp)
 256:	64a2                	ld	s1,8(sp)
 258:	6902                	ld	s2,0(sp)
 25a:	6105                	addi	sp,sp,32
 25c:	8082                	ret
    return -1;
 25e:	597d                	li	s2,-1
 260:	bfc5                	j	250 <stat+0x34>

0000000000000262 <atoi>:

int
atoi(const char *s)
{
 262:	1141                	addi	sp,sp,-16
 264:	e422                	sd	s0,8(sp)
 266:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 268:	00054603          	lbu	a2,0(a0)
 26c:	fd06079b          	addiw	a5,a2,-48
 270:	0ff7f793          	andi	a5,a5,255
 274:	4725                	li	a4,9
 276:	02f76963          	bltu	a4,a5,2a8 <atoi+0x46>
 27a:	86aa                	mv	a3,a0
  n = 0;
 27c:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 27e:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 280:	0685                	addi	a3,a3,1
 282:	0025179b          	slliw	a5,a0,0x2
 286:	9fa9                	addw	a5,a5,a0
 288:	0017979b          	slliw	a5,a5,0x1
 28c:	9fb1                	addw	a5,a5,a2
 28e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 292:	0006c603          	lbu	a2,0(a3)
 296:	fd06071b          	addiw	a4,a2,-48
 29a:	0ff77713          	andi	a4,a4,255
 29e:	fee5f1e3          	bgeu	a1,a4,280 <atoi+0x1e>
  return n;
}
 2a2:	6422                	ld	s0,8(sp)
 2a4:	0141                	addi	sp,sp,16
 2a6:	8082                	ret
  n = 0;
 2a8:	4501                	li	a0,0
 2aa:	bfe5                	j	2a2 <atoi+0x40>

00000000000002ac <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2ac:	1141                	addi	sp,sp,-16
 2ae:	e422                	sd	s0,8(sp)
 2b0:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2b2:	02b57663          	bgeu	a0,a1,2de <memmove+0x32>
    while(n-- > 0)
 2b6:	02c05163          	blez	a2,2d8 <memmove+0x2c>
 2ba:	fff6079b          	addiw	a5,a2,-1
 2be:	1782                	slli	a5,a5,0x20
 2c0:	9381                	srli	a5,a5,0x20
 2c2:	0785                	addi	a5,a5,1
 2c4:	97aa                	add	a5,a5,a0
  dst = vdst;
 2c6:	872a                	mv	a4,a0
      *dst++ = *src++;
 2c8:	0585                	addi	a1,a1,1
 2ca:	0705                	addi	a4,a4,1
 2cc:	fff5c683          	lbu	a3,-1(a1)
 2d0:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2d4:	fee79ae3          	bne	a5,a4,2c8 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2d8:	6422                	ld	s0,8(sp)
 2da:	0141                	addi	sp,sp,16
 2dc:	8082                	ret
    dst += n;
 2de:	00c50733          	add	a4,a0,a2
    src += n;
 2e2:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2e4:	fec05ae3          	blez	a2,2d8 <memmove+0x2c>
 2e8:	fff6079b          	addiw	a5,a2,-1
 2ec:	1782                	slli	a5,a5,0x20
 2ee:	9381                	srli	a5,a5,0x20
 2f0:	fff7c793          	not	a5,a5
 2f4:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2f6:	15fd                	addi	a1,a1,-1
 2f8:	177d                	addi	a4,a4,-1
 2fa:	0005c683          	lbu	a3,0(a1)
 2fe:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 302:	fee79ae3          	bne	a5,a4,2f6 <memmove+0x4a>
 306:	bfc9                	j	2d8 <memmove+0x2c>

0000000000000308 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 308:	1141                	addi	sp,sp,-16
 30a:	e422                	sd	s0,8(sp)
 30c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 30e:	ca05                	beqz	a2,33e <memcmp+0x36>
 310:	fff6069b          	addiw	a3,a2,-1
 314:	1682                	slli	a3,a3,0x20
 316:	9281                	srli	a3,a3,0x20
 318:	0685                	addi	a3,a3,1
 31a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 31c:	00054783          	lbu	a5,0(a0)
 320:	0005c703          	lbu	a4,0(a1)
 324:	00e79863          	bne	a5,a4,334 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 328:	0505                	addi	a0,a0,1
    p2++;
 32a:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 32c:	fed518e3          	bne	a0,a3,31c <memcmp+0x14>
  }
  return 0;
 330:	4501                	li	a0,0
 332:	a019                	j	338 <memcmp+0x30>
      return *p1 - *p2;
 334:	40e7853b          	subw	a0,a5,a4
}
 338:	6422                	ld	s0,8(sp)
 33a:	0141                	addi	sp,sp,16
 33c:	8082                	ret
  return 0;
 33e:	4501                	li	a0,0
 340:	bfe5                	j	338 <memcmp+0x30>

0000000000000342 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 342:	1141                	addi	sp,sp,-16
 344:	e406                	sd	ra,8(sp)
 346:	e022                	sd	s0,0(sp)
 348:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 34a:	00000097          	auipc	ra,0x0
 34e:	f62080e7          	jalr	-158(ra) # 2ac <memmove>
}
 352:	60a2                	ld	ra,8(sp)
 354:	6402                	ld	s0,0(sp)
 356:	0141                	addi	sp,sp,16
 358:	8082                	ret

000000000000035a <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 35a:	4885                	li	a7,1
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <exit>:
.global exit
exit:
 li a7, SYS_exit
 362:	4889                	li	a7,2
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <wait>:
.global wait
wait:
 li a7, SYS_wait
 36a:	488d                	li	a7,3
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 372:	4891                	li	a7,4
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <read>:
.global read
read:
 li a7, SYS_read
 37a:	4895                	li	a7,5
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <write>:
.global write
write:
 li a7, SYS_write
 382:	48c1                	li	a7,16
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <close>:
.global close
close:
 li a7, SYS_close
 38a:	48d5                	li	a7,21
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <kill>:
.global kill
kill:
 li a7, SYS_kill
 392:	4899                	li	a7,6
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <exec>:
.global exec
exec:
 li a7, SYS_exec
 39a:	489d                	li	a7,7
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <open>:
.global open
open:
 li a7, SYS_open
 3a2:	48bd                	li	a7,15
 ecall
 3a4:	00000073          	ecall
 ret
 3a8:	8082                	ret

00000000000003aa <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3aa:	48c5                	li	a7,17
 ecall
 3ac:	00000073          	ecall
 ret
 3b0:	8082                	ret

00000000000003b2 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3b2:	48c9                	li	a7,18
 ecall
 3b4:	00000073          	ecall
 ret
 3b8:	8082                	ret

00000000000003ba <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3ba:	48a1                	li	a7,8
 ecall
 3bc:	00000073          	ecall
 ret
 3c0:	8082                	ret

00000000000003c2 <link>:
.global link
link:
 li a7, SYS_link
 3c2:	48cd                	li	a7,19
 ecall
 3c4:	00000073          	ecall
 ret
 3c8:	8082                	ret

00000000000003ca <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3ca:	48d1                	li	a7,20
 ecall
 3cc:	00000073          	ecall
 ret
 3d0:	8082                	ret

00000000000003d2 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3d2:	48a5                	li	a7,9
 ecall
 3d4:	00000073          	ecall
 ret
 3d8:	8082                	ret

00000000000003da <dup>:
.global dup
dup:
 li a7, SYS_dup
 3da:	48a9                	li	a7,10
 ecall
 3dc:	00000073          	ecall
 ret
 3e0:	8082                	ret

00000000000003e2 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3e2:	48ad                	li	a7,11
 ecall
 3e4:	00000073          	ecall
 ret
 3e8:	8082                	ret

00000000000003ea <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3ea:	48b1                	li	a7,12
 ecall
 3ec:	00000073          	ecall
 ret
 3f0:	8082                	ret

00000000000003f2 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3f2:	48b5                	li	a7,13
 ecall
 3f4:	00000073          	ecall
 ret
 3f8:	8082                	ret

00000000000003fa <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3fa:	48b9                	li	a7,14
 ecall
 3fc:	00000073          	ecall
 ret
 400:	8082                	ret

0000000000000402 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 402:	1101                	addi	sp,sp,-32
 404:	ec06                	sd	ra,24(sp)
 406:	e822                	sd	s0,16(sp)
 408:	1000                	addi	s0,sp,32
 40a:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 40e:	4605                	li	a2,1
 410:	fef40593          	addi	a1,s0,-17
 414:	00000097          	auipc	ra,0x0
 418:	f6e080e7          	jalr	-146(ra) # 382 <write>
}
 41c:	60e2                	ld	ra,24(sp)
 41e:	6442                	ld	s0,16(sp)
 420:	6105                	addi	sp,sp,32
 422:	8082                	ret

0000000000000424 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 424:	7139                	addi	sp,sp,-64
 426:	fc06                	sd	ra,56(sp)
 428:	f822                	sd	s0,48(sp)
 42a:	f426                	sd	s1,40(sp)
 42c:	f04a                	sd	s2,32(sp)
 42e:	ec4e                	sd	s3,24(sp)
 430:	0080                	addi	s0,sp,64
 432:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 434:	c299                	beqz	a3,43a <printint+0x16>
 436:	0805c863          	bltz	a1,4c6 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 43a:	2581                	sext.w	a1,a1
  neg = 0;
 43c:	4881                	li	a7,0
 43e:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 442:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 444:	2601                	sext.w	a2,a2
 446:	00000517          	auipc	a0,0x0
 44a:	44250513          	addi	a0,a0,1090 # 888 <digits>
 44e:	883a                	mv	a6,a4
 450:	2705                	addiw	a4,a4,1
 452:	02c5f7bb          	remuw	a5,a1,a2
 456:	1782                	slli	a5,a5,0x20
 458:	9381                	srli	a5,a5,0x20
 45a:	97aa                	add	a5,a5,a0
 45c:	0007c783          	lbu	a5,0(a5)
 460:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 464:	0005879b          	sext.w	a5,a1
 468:	02c5d5bb          	divuw	a1,a1,a2
 46c:	0685                	addi	a3,a3,1
 46e:	fec7f0e3          	bgeu	a5,a2,44e <printint+0x2a>
  if(neg)
 472:	00088b63          	beqz	a7,488 <printint+0x64>
    buf[i++] = '-';
 476:	fd040793          	addi	a5,s0,-48
 47a:	973e                	add	a4,a4,a5
 47c:	02d00793          	li	a5,45
 480:	fef70823          	sb	a5,-16(a4)
 484:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 488:	02e05863          	blez	a4,4b8 <printint+0x94>
 48c:	fc040793          	addi	a5,s0,-64
 490:	00e78933          	add	s2,a5,a4
 494:	fff78993          	addi	s3,a5,-1
 498:	99ba                	add	s3,s3,a4
 49a:	377d                	addiw	a4,a4,-1
 49c:	1702                	slli	a4,a4,0x20
 49e:	9301                	srli	a4,a4,0x20
 4a0:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4a4:	fff94583          	lbu	a1,-1(s2)
 4a8:	8526                	mv	a0,s1
 4aa:	00000097          	auipc	ra,0x0
 4ae:	f58080e7          	jalr	-168(ra) # 402 <putc>
  while(--i >= 0)
 4b2:	197d                	addi	s2,s2,-1
 4b4:	ff3918e3          	bne	s2,s3,4a4 <printint+0x80>
}
 4b8:	70e2                	ld	ra,56(sp)
 4ba:	7442                	ld	s0,48(sp)
 4bc:	74a2                	ld	s1,40(sp)
 4be:	7902                	ld	s2,32(sp)
 4c0:	69e2                	ld	s3,24(sp)
 4c2:	6121                	addi	sp,sp,64
 4c4:	8082                	ret
    x = -xx;
 4c6:	40b005bb          	negw	a1,a1
    neg = 1;
 4ca:	4885                	li	a7,1
    x = -xx;
 4cc:	bf8d                	j	43e <printint+0x1a>

00000000000004ce <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4ce:	7119                	addi	sp,sp,-128
 4d0:	fc86                	sd	ra,120(sp)
 4d2:	f8a2                	sd	s0,112(sp)
 4d4:	f4a6                	sd	s1,104(sp)
 4d6:	f0ca                	sd	s2,96(sp)
 4d8:	ecce                	sd	s3,88(sp)
 4da:	e8d2                	sd	s4,80(sp)
 4dc:	e4d6                	sd	s5,72(sp)
 4de:	e0da                	sd	s6,64(sp)
 4e0:	fc5e                	sd	s7,56(sp)
 4e2:	f862                	sd	s8,48(sp)
 4e4:	f466                	sd	s9,40(sp)
 4e6:	f06a                	sd	s10,32(sp)
 4e8:	ec6e                	sd	s11,24(sp)
 4ea:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4ec:	0005c903          	lbu	s2,0(a1)
 4f0:	18090f63          	beqz	s2,68e <vprintf+0x1c0>
 4f4:	8aaa                	mv	s5,a0
 4f6:	8b32                	mv	s6,a2
 4f8:	00158493          	addi	s1,a1,1
  state = 0;
 4fc:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4fe:	02500a13          	li	s4,37
      if(c == 'd'){
 502:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 506:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 50a:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 50e:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 512:	00000b97          	auipc	s7,0x0
 516:	376b8b93          	addi	s7,s7,886 # 888 <digits>
 51a:	a839                	j	538 <vprintf+0x6a>
        putc(fd, c);
 51c:	85ca                	mv	a1,s2
 51e:	8556                	mv	a0,s5
 520:	00000097          	auipc	ra,0x0
 524:	ee2080e7          	jalr	-286(ra) # 402 <putc>
 528:	a019                	j	52e <vprintf+0x60>
    } else if(state == '%'){
 52a:	01498f63          	beq	s3,s4,548 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 52e:	0485                	addi	s1,s1,1
 530:	fff4c903          	lbu	s2,-1(s1)
 534:	14090d63          	beqz	s2,68e <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 538:	0009079b          	sext.w	a5,s2
    if(state == 0){
 53c:	fe0997e3          	bnez	s3,52a <vprintf+0x5c>
      if(c == '%'){
 540:	fd479ee3          	bne	a5,s4,51c <vprintf+0x4e>
        state = '%';
 544:	89be                	mv	s3,a5
 546:	b7e5                	j	52e <vprintf+0x60>
      if(c == 'd'){
 548:	05878063          	beq	a5,s8,588 <vprintf+0xba>
      } else if(c == 'l') {
 54c:	05978c63          	beq	a5,s9,5a4 <vprintf+0xd6>
      } else if(c == 'x') {
 550:	07a78863          	beq	a5,s10,5c0 <vprintf+0xf2>
      } else if(c == 'p') {
 554:	09b78463          	beq	a5,s11,5dc <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 558:	07300713          	li	a4,115
 55c:	0ce78663          	beq	a5,a4,628 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 560:	06300713          	li	a4,99
 564:	0ee78e63          	beq	a5,a4,660 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 568:	11478863          	beq	a5,s4,678 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 56c:	85d2                	mv	a1,s4
 56e:	8556                	mv	a0,s5
 570:	00000097          	auipc	ra,0x0
 574:	e92080e7          	jalr	-366(ra) # 402 <putc>
        putc(fd, c);
 578:	85ca                	mv	a1,s2
 57a:	8556                	mv	a0,s5
 57c:	00000097          	auipc	ra,0x0
 580:	e86080e7          	jalr	-378(ra) # 402 <putc>
      }
      state = 0;
 584:	4981                	li	s3,0
 586:	b765                	j	52e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 588:	008b0913          	addi	s2,s6,8
 58c:	4685                	li	a3,1
 58e:	4629                	li	a2,10
 590:	000b2583          	lw	a1,0(s6)
 594:	8556                	mv	a0,s5
 596:	00000097          	auipc	ra,0x0
 59a:	e8e080e7          	jalr	-370(ra) # 424 <printint>
 59e:	8b4a                	mv	s6,s2
      state = 0;
 5a0:	4981                	li	s3,0
 5a2:	b771                	j	52e <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5a4:	008b0913          	addi	s2,s6,8
 5a8:	4681                	li	a3,0
 5aa:	4629                	li	a2,10
 5ac:	000b2583          	lw	a1,0(s6)
 5b0:	8556                	mv	a0,s5
 5b2:	00000097          	auipc	ra,0x0
 5b6:	e72080e7          	jalr	-398(ra) # 424 <printint>
 5ba:	8b4a                	mv	s6,s2
      state = 0;
 5bc:	4981                	li	s3,0
 5be:	bf85                	j	52e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5c0:	008b0913          	addi	s2,s6,8
 5c4:	4681                	li	a3,0
 5c6:	4641                	li	a2,16
 5c8:	000b2583          	lw	a1,0(s6)
 5cc:	8556                	mv	a0,s5
 5ce:	00000097          	auipc	ra,0x0
 5d2:	e56080e7          	jalr	-426(ra) # 424 <printint>
 5d6:	8b4a                	mv	s6,s2
      state = 0;
 5d8:	4981                	li	s3,0
 5da:	bf91                	j	52e <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5dc:	008b0793          	addi	a5,s6,8
 5e0:	f8f43423          	sd	a5,-120(s0)
 5e4:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5e8:	03000593          	li	a1,48
 5ec:	8556                	mv	a0,s5
 5ee:	00000097          	auipc	ra,0x0
 5f2:	e14080e7          	jalr	-492(ra) # 402 <putc>
  putc(fd, 'x');
 5f6:	85ea                	mv	a1,s10
 5f8:	8556                	mv	a0,s5
 5fa:	00000097          	auipc	ra,0x0
 5fe:	e08080e7          	jalr	-504(ra) # 402 <putc>
 602:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 604:	03c9d793          	srli	a5,s3,0x3c
 608:	97de                	add	a5,a5,s7
 60a:	0007c583          	lbu	a1,0(a5)
 60e:	8556                	mv	a0,s5
 610:	00000097          	auipc	ra,0x0
 614:	df2080e7          	jalr	-526(ra) # 402 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 618:	0992                	slli	s3,s3,0x4
 61a:	397d                	addiw	s2,s2,-1
 61c:	fe0914e3          	bnez	s2,604 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 620:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 624:	4981                	li	s3,0
 626:	b721                	j	52e <vprintf+0x60>
        s = va_arg(ap, char*);
 628:	008b0993          	addi	s3,s6,8
 62c:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 630:	02090163          	beqz	s2,652 <vprintf+0x184>
        while(*s != 0){
 634:	00094583          	lbu	a1,0(s2)
 638:	c9a1                	beqz	a1,688 <vprintf+0x1ba>
          putc(fd, *s);
 63a:	8556                	mv	a0,s5
 63c:	00000097          	auipc	ra,0x0
 640:	dc6080e7          	jalr	-570(ra) # 402 <putc>
          s++;
 644:	0905                	addi	s2,s2,1
        while(*s != 0){
 646:	00094583          	lbu	a1,0(s2)
 64a:	f9e5                	bnez	a1,63a <vprintf+0x16c>
        s = va_arg(ap, char*);
 64c:	8b4e                	mv	s6,s3
      state = 0;
 64e:	4981                	li	s3,0
 650:	bdf9                	j	52e <vprintf+0x60>
          s = "(null)";
 652:	00000917          	auipc	s2,0x0
 656:	22e90913          	addi	s2,s2,558 # 880 <malloc+0xe8>
        while(*s != 0){
 65a:	02800593          	li	a1,40
 65e:	bff1                	j	63a <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 660:	008b0913          	addi	s2,s6,8
 664:	000b4583          	lbu	a1,0(s6)
 668:	8556                	mv	a0,s5
 66a:	00000097          	auipc	ra,0x0
 66e:	d98080e7          	jalr	-616(ra) # 402 <putc>
 672:	8b4a                	mv	s6,s2
      state = 0;
 674:	4981                	li	s3,0
 676:	bd65                	j	52e <vprintf+0x60>
        putc(fd, c);
 678:	85d2                	mv	a1,s4
 67a:	8556                	mv	a0,s5
 67c:	00000097          	auipc	ra,0x0
 680:	d86080e7          	jalr	-634(ra) # 402 <putc>
      state = 0;
 684:	4981                	li	s3,0
 686:	b565                	j	52e <vprintf+0x60>
        s = va_arg(ap, char*);
 688:	8b4e                	mv	s6,s3
      state = 0;
 68a:	4981                	li	s3,0
 68c:	b54d                	j	52e <vprintf+0x60>
    }
  }
}
 68e:	70e6                	ld	ra,120(sp)
 690:	7446                	ld	s0,112(sp)
 692:	74a6                	ld	s1,104(sp)
 694:	7906                	ld	s2,96(sp)
 696:	69e6                	ld	s3,88(sp)
 698:	6a46                	ld	s4,80(sp)
 69a:	6aa6                	ld	s5,72(sp)
 69c:	6b06                	ld	s6,64(sp)
 69e:	7be2                	ld	s7,56(sp)
 6a0:	7c42                	ld	s8,48(sp)
 6a2:	7ca2                	ld	s9,40(sp)
 6a4:	7d02                	ld	s10,32(sp)
 6a6:	6de2                	ld	s11,24(sp)
 6a8:	6109                	addi	sp,sp,128
 6aa:	8082                	ret

00000000000006ac <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6ac:	715d                	addi	sp,sp,-80
 6ae:	ec06                	sd	ra,24(sp)
 6b0:	e822                	sd	s0,16(sp)
 6b2:	1000                	addi	s0,sp,32
 6b4:	e010                	sd	a2,0(s0)
 6b6:	e414                	sd	a3,8(s0)
 6b8:	e818                	sd	a4,16(s0)
 6ba:	ec1c                	sd	a5,24(s0)
 6bc:	03043023          	sd	a6,32(s0)
 6c0:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6c4:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6c8:	8622                	mv	a2,s0
 6ca:	00000097          	auipc	ra,0x0
 6ce:	e04080e7          	jalr	-508(ra) # 4ce <vprintf>
}
 6d2:	60e2                	ld	ra,24(sp)
 6d4:	6442                	ld	s0,16(sp)
 6d6:	6161                	addi	sp,sp,80
 6d8:	8082                	ret

00000000000006da <printf>:

void
printf(const char *fmt, ...)
{
 6da:	711d                	addi	sp,sp,-96
 6dc:	ec06                	sd	ra,24(sp)
 6de:	e822                	sd	s0,16(sp)
 6e0:	1000                	addi	s0,sp,32
 6e2:	e40c                	sd	a1,8(s0)
 6e4:	e810                	sd	a2,16(s0)
 6e6:	ec14                	sd	a3,24(s0)
 6e8:	f018                	sd	a4,32(s0)
 6ea:	f41c                	sd	a5,40(s0)
 6ec:	03043823          	sd	a6,48(s0)
 6f0:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6f4:	00840613          	addi	a2,s0,8
 6f8:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6fc:	85aa                	mv	a1,a0
 6fe:	4505                	li	a0,1
 700:	00000097          	auipc	ra,0x0
 704:	dce080e7          	jalr	-562(ra) # 4ce <vprintf>
}
 708:	60e2                	ld	ra,24(sp)
 70a:	6442                	ld	s0,16(sp)
 70c:	6125                	addi	sp,sp,96
 70e:	8082                	ret

0000000000000710 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 710:	1141                	addi	sp,sp,-16
 712:	e422                	sd	s0,8(sp)
 714:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 716:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 71a:	00000797          	auipc	a5,0x0
 71e:	1867b783          	ld	a5,390(a5) # 8a0 <freep>
 722:	a805                	j	752 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 724:	4618                	lw	a4,8(a2)
 726:	9db9                	addw	a1,a1,a4
 728:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 72c:	6398                	ld	a4,0(a5)
 72e:	6318                	ld	a4,0(a4)
 730:	fee53823          	sd	a4,-16(a0)
 734:	a091                	j	778 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 736:	ff852703          	lw	a4,-8(a0)
 73a:	9e39                	addw	a2,a2,a4
 73c:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 73e:	ff053703          	ld	a4,-16(a0)
 742:	e398                	sd	a4,0(a5)
 744:	a099                	j	78a <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 746:	6398                	ld	a4,0(a5)
 748:	00e7e463          	bltu	a5,a4,750 <free+0x40>
 74c:	00e6ea63          	bltu	a3,a4,760 <free+0x50>
{
 750:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 752:	fed7fae3          	bgeu	a5,a3,746 <free+0x36>
 756:	6398                	ld	a4,0(a5)
 758:	00e6e463          	bltu	a3,a4,760 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 75c:	fee7eae3          	bltu	a5,a4,750 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 760:	ff852583          	lw	a1,-8(a0)
 764:	6390                	ld	a2,0(a5)
 766:	02059713          	slli	a4,a1,0x20
 76a:	9301                	srli	a4,a4,0x20
 76c:	0712                	slli	a4,a4,0x4
 76e:	9736                	add	a4,a4,a3
 770:	fae60ae3          	beq	a2,a4,724 <free+0x14>
    bp->s.ptr = p->s.ptr;
 774:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 778:	4790                	lw	a2,8(a5)
 77a:	02061713          	slli	a4,a2,0x20
 77e:	9301                	srli	a4,a4,0x20
 780:	0712                	slli	a4,a4,0x4
 782:	973e                	add	a4,a4,a5
 784:	fae689e3          	beq	a3,a4,736 <free+0x26>
  } else
    p->s.ptr = bp;
 788:	e394                	sd	a3,0(a5)
  freep = p;
 78a:	00000717          	auipc	a4,0x0
 78e:	10f73b23          	sd	a5,278(a4) # 8a0 <freep>
}
 792:	6422                	ld	s0,8(sp)
 794:	0141                	addi	sp,sp,16
 796:	8082                	ret

0000000000000798 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 798:	7139                	addi	sp,sp,-64
 79a:	fc06                	sd	ra,56(sp)
 79c:	f822                	sd	s0,48(sp)
 79e:	f426                	sd	s1,40(sp)
 7a0:	f04a                	sd	s2,32(sp)
 7a2:	ec4e                	sd	s3,24(sp)
 7a4:	e852                	sd	s4,16(sp)
 7a6:	e456                	sd	s5,8(sp)
 7a8:	e05a                	sd	s6,0(sp)
 7aa:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7ac:	02051493          	slli	s1,a0,0x20
 7b0:	9081                	srli	s1,s1,0x20
 7b2:	04bd                	addi	s1,s1,15
 7b4:	8091                	srli	s1,s1,0x4
 7b6:	0014899b          	addiw	s3,s1,1
 7ba:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7bc:	00000517          	auipc	a0,0x0
 7c0:	0e453503          	ld	a0,228(a0) # 8a0 <freep>
 7c4:	c515                	beqz	a0,7f0 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7c6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7c8:	4798                	lw	a4,8(a5)
 7ca:	02977f63          	bgeu	a4,s1,808 <malloc+0x70>
 7ce:	8a4e                	mv	s4,s3
 7d0:	0009871b          	sext.w	a4,s3
 7d4:	6685                	lui	a3,0x1
 7d6:	00d77363          	bgeu	a4,a3,7dc <malloc+0x44>
 7da:	6a05                	lui	s4,0x1
 7dc:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7e0:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7e4:	00000917          	auipc	s2,0x0
 7e8:	0bc90913          	addi	s2,s2,188 # 8a0 <freep>
  if(p == (char*)-1)
 7ec:	5afd                	li	s5,-1
 7ee:	a88d                	j	860 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 7f0:	00000797          	auipc	a5,0x0
 7f4:	0b878793          	addi	a5,a5,184 # 8a8 <base>
 7f8:	00000717          	auipc	a4,0x0
 7fc:	0af73423          	sd	a5,168(a4) # 8a0 <freep>
 800:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 802:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 806:	b7e1                	j	7ce <malloc+0x36>
      if(p->s.size == nunits)
 808:	02e48b63          	beq	s1,a4,83e <malloc+0xa6>
        p->s.size -= nunits;
 80c:	4137073b          	subw	a4,a4,s3
 810:	c798                	sw	a4,8(a5)
        p += p->s.size;
 812:	1702                	slli	a4,a4,0x20
 814:	9301                	srli	a4,a4,0x20
 816:	0712                	slli	a4,a4,0x4
 818:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 81a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 81e:	00000717          	auipc	a4,0x0
 822:	08a73123          	sd	a0,130(a4) # 8a0 <freep>
      return (void*)(p + 1);
 826:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 82a:	70e2                	ld	ra,56(sp)
 82c:	7442                	ld	s0,48(sp)
 82e:	74a2                	ld	s1,40(sp)
 830:	7902                	ld	s2,32(sp)
 832:	69e2                	ld	s3,24(sp)
 834:	6a42                	ld	s4,16(sp)
 836:	6aa2                	ld	s5,8(sp)
 838:	6b02                	ld	s6,0(sp)
 83a:	6121                	addi	sp,sp,64
 83c:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 83e:	6398                	ld	a4,0(a5)
 840:	e118                	sd	a4,0(a0)
 842:	bff1                	j	81e <malloc+0x86>
  hp->s.size = nu;
 844:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 848:	0541                	addi	a0,a0,16
 84a:	00000097          	auipc	ra,0x0
 84e:	ec6080e7          	jalr	-314(ra) # 710 <free>
  return freep;
 852:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 856:	d971                	beqz	a0,82a <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 858:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 85a:	4798                	lw	a4,8(a5)
 85c:	fa9776e3          	bgeu	a4,s1,808 <malloc+0x70>
    if(p == freep)
 860:	00093703          	ld	a4,0(s2)
 864:	853e                	mv	a0,a5
 866:	fef719e3          	bne	a4,a5,858 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 86a:	8552                	mv	a0,s4
 86c:	00000097          	auipc	ra,0x0
 870:	b7e080e7          	jalr	-1154(ra) # 3ea <sbrk>
  if(p == (char*)-1)
 874:	fd5518e3          	bne	a0,s5,844 <malloc+0xac>
        return 0;
 878:	4501                	li	a0,0
 87a:	bf45                	j	82a <malloc+0x92>
