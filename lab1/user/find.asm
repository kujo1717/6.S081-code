
user/_find:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <find>:
#include "kernel/fs.h"

// find 函数
void
find(char *dir, char *file)
{   
   0:	d8010113          	addi	sp,sp,-640
   4:	26113c23          	sd	ra,632(sp)
   8:	26813823          	sd	s0,624(sp)
   c:	26913423          	sd	s1,616(sp)
  10:	27213023          	sd	s2,608(sp)
  14:	25313c23          	sd	s3,600(sp)
  18:	25413823          	sd	s4,592(sp)
  1c:	25513423          	sd	s5,584(sp)
  20:	25613023          	sd	s6,576(sp)
  24:	23713c23          	sd	s7,568(sp)
  28:	0500                	addi	s0,sp,640
  2a:	892a                	mv	s2,a0
  2c:	89ae                	mv	s3,a1
    // 声明与文件相关的结构体
    struct dirent de;
    struct stat st;

    // open() 函数打开路径，返回一个文件描述符，如果错误返回 -1
    if ((fd = open(dir, 0)) < 0)
  2e:	4581                	li	a1,0
  30:	00000097          	auipc	ra,0x0
  34:	4dc080e7          	jalr	1244(ra) # 50c <open>
  38:	06054463          	bltz	a0,a0 <find+0xa0>
  3c:	84aa                	mv	s1,a0
    // 系统调用 fstat 与 stat 类似，但它以文件描述符作为参数
    // int stat(char *, struct stat *);
    // stat 系统调用，可以获得一个已存在文件的模式，并将此模式赋值给它的副本
    // stat 以文件名作为参数，返回文件的 i 结点中的所有信息
    // 如果出错，则返回 -1
    if (fstat(fd, &st) < 0)
  3e:	d8840593          	addi	a1,s0,-632
  42:	00000097          	auipc	ra,0x0
  46:	4e2080e7          	jalr	1250(ra) # 524 <fstat>
  4a:	06054663          	bltz	a0,b6 <find+0xb6>
        close(fd);
        return;
    }

    // 如果不是目录类型
    if (st.type != T_DIR)
  4e:	d9041703          	lh	a4,-624(s0)
  52:	4785                	li	a5,1
  54:	08f70163          	beq	a4,a5,d6 <find+0xd6>
    {
        // 报类型不是目录错误
        fprintf(2, "find: %s is not a directory\n", dir);
  58:	864a                	mv	a2,s2
  5a:	00001597          	auipc	a1,0x1
  5e:	9be58593          	addi	a1,a1,-1602 # a18 <malloc+0x116>
  62:	4509                	li	a0,2
  64:	00000097          	auipc	ra,0x0
  68:	7b2080e7          	jalr	1970(ra) # 816 <fprintf>
        // 关闭文件描述符 fd
        close(fd);
  6c:	8526                	mv	a0,s1
  6e:	00000097          	auipc	ra,0x0
  72:	486080e7          	jalr	1158(ra) # 4f4 <close>
        {
            // 打印缓冲区存放的路径
            printf("%s\n", buf);
        } 
    }
}
  76:	27813083          	ld	ra,632(sp)
  7a:	27013403          	ld	s0,624(sp)
  7e:	26813483          	ld	s1,616(sp)
  82:	26013903          	ld	s2,608(sp)
  86:	25813983          	ld	s3,600(sp)
  8a:	25013a03          	ld	s4,592(sp)
  8e:	24813a83          	ld	s5,584(sp)
  92:	24013b03          	ld	s6,576(sp)
  96:	23813b83          	ld	s7,568(sp)
  9a:	28010113          	addi	sp,sp,640
  9e:	8082                	ret
        fprintf(2, "find: cannot open %s\n", dir);
  a0:	864a                	mv	a2,s2
  a2:	00001597          	auipc	a1,0x1
  a6:	94658593          	addi	a1,a1,-1722 # 9e8 <malloc+0xe6>
  aa:	4509                	li	a0,2
  ac:	00000097          	auipc	ra,0x0
  b0:	76a080e7          	jalr	1898(ra) # 816 <fprintf>
        return;
  b4:	b7c9                	j	76 <find+0x76>
        fprintf(2, "find: cannot stat %s\n", dir);
  b6:	864a                	mv	a2,s2
  b8:	00001597          	auipc	a1,0x1
  bc:	94858593          	addi	a1,a1,-1720 # a00 <malloc+0xfe>
  c0:	4509                	li	a0,2
  c2:	00000097          	auipc	ra,0x0
  c6:	754080e7          	jalr	1876(ra) # 816 <fprintf>
        close(fd);
  ca:	8526                	mv	a0,s1
  cc:	00000097          	auipc	ra,0x0
  d0:	428080e7          	jalr	1064(ra) # 4f4 <close>
        return;
  d4:	b74d                	j	76 <find+0x76>
    if(strlen(dir) + 1 + DIRSIZ + 1 > sizeof buf)
  d6:	854a                	mv	a0,s2
  d8:	00000097          	auipc	ra,0x0
  dc:	1c6080e7          	jalr	454(ra) # 29e <strlen>
  e0:	2541                	addiw	a0,a0,16
  e2:	20000793          	li	a5,512
  e6:	0ea7e463          	bltu	a5,a0,1ce <find+0x1ce>
    strcpy(buf, dir);
  ea:	85ca                	mv	a1,s2
  ec:	db040513          	addi	a0,s0,-592
  f0:	00000097          	auipc	ra,0x0
  f4:	166080e7          	jalr	358(ra) # 256 <strcpy>
    p = buf + strlen(buf);
  f8:	db040513          	addi	a0,s0,-592
  fc:	00000097          	auipc	ra,0x0
 100:	1a2080e7          	jalr	418(ra) # 29e <strlen>
 104:	02051913          	slli	s2,a0,0x20
 108:	02095913          	srli	s2,s2,0x20
 10c:	db040793          	addi	a5,s0,-592
 110:	993e                	add	s2,s2,a5
    *p++ = '/';
 112:	00190b13          	addi	s6,s2,1
 116:	02f00793          	li	a5,47
 11a:	00f90023          	sb	a5,0(s2)
        if (!strcmp(de.name, ".") || !strcmp(de.name, ".."))
 11e:	00001a97          	auipc	s5,0x1
 122:	93aa8a93          	addi	s5,s5,-1734 # a58 <malloc+0x156>
 126:	00001b97          	auipc	s7,0x1
 12a:	93ab8b93          	addi	s7,s7,-1734 # a60 <malloc+0x15e>
 12e:	da240a13          	addi	s4,s0,-606
    while (read(fd, &de, sizeof(de)) == sizeof(de))
 132:	4641                	li	a2,16
 134:	da040593          	addi	a1,s0,-608
 138:	8526                	mv	a0,s1
 13a:	00000097          	auipc	ra,0x0
 13e:	3aa080e7          	jalr	938(ra) # 4e4 <read>
 142:	47c1                	li	a5,16
 144:	f2f519e3          	bne	a0,a5,76 <find+0x76>
        if(de.inum == 0)
 148:	da045783          	lhu	a5,-608(s0)
 14c:	d3fd                	beqz	a5,132 <find+0x132>
        if (!strcmp(de.name, ".") || !strcmp(de.name, ".."))
 14e:	85d6                	mv	a1,s5
 150:	8552                	mv	a0,s4
 152:	00000097          	auipc	ra,0x0
 156:	120080e7          	jalr	288(ra) # 272 <strcmp>
 15a:	dd61                	beqz	a0,132 <find+0x132>
 15c:	85de                	mv	a1,s7
 15e:	8552                	mv	a0,s4
 160:	00000097          	auipc	ra,0x0
 164:	112080e7          	jalr	274(ra) # 272 <strcmp>
 168:	d569                	beqz	a0,132 <find+0x132>
        memmove(p, de.name, DIRSIZ);
 16a:	4639                	li	a2,14
 16c:	da240593          	addi	a1,s0,-606
 170:	855a                	mv	a0,s6
 172:	00000097          	auipc	ra,0x0
 176:	2a4080e7          	jalr	676(ra) # 416 <memmove>
        p[DIRSIZ] = 0;
 17a:	000907a3          	sb	zero,15(s2)
        if(stat(buf, &st) < 0)
 17e:	d8840593          	addi	a1,s0,-632
 182:	db040513          	addi	a0,s0,-592
 186:	00000097          	auipc	ra,0x0
 18a:	200080e7          	jalr	512(ra) # 386 <stat>
 18e:	04054f63          	bltz	a0,1ec <find+0x1ec>
        if (st.type == T_DIR)
 192:	d9041783          	lh	a5,-624(s0)
 196:	0007869b          	sext.w	a3,a5
 19a:	4705                	li	a4,1
 19c:	06e68463          	beq	a3,a4,204 <find+0x204>
        else if (st.type == T_FILE && !strcmp(de.name, file))
 1a0:	2781                	sext.w	a5,a5
 1a2:	4709                	li	a4,2
 1a4:	f8e797e3          	bne	a5,a4,132 <find+0x132>
 1a8:	85ce                	mv	a1,s3
 1aa:	da240513          	addi	a0,s0,-606
 1ae:	00000097          	auipc	ra,0x0
 1b2:	0c4080e7          	jalr	196(ra) # 272 <strcmp>
 1b6:	fd35                	bnez	a0,132 <find+0x132>
            printf("%s\n", buf);
 1b8:	db040593          	addi	a1,s0,-592
 1bc:	00001517          	auipc	a0,0x1
 1c0:	8ac50513          	addi	a0,a0,-1876 # a68 <malloc+0x166>
 1c4:	00000097          	auipc	ra,0x0
 1c8:	680080e7          	jalr	1664(ra) # 844 <printf>
 1cc:	b79d                	j	132 <find+0x132>
        fprintf(2, "find: directory too long\n");
 1ce:	00001597          	auipc	a1,0x1
 1d2:	86a58593          	addi	a1,a1,-1942 # a38 <malloc+0x136>
 1d6:	4509                	li	a0,2
 1d8:	00000097          	auipc	ra,0x0
 1dc:	63e080e7          	jalr	1598(ra) # 816 <fprintf>
        close(fd);
 1e0:	8526                	mv	a0,s1
 1e2:	00000097          	auipc	ra,0x0
 1e6:	312080e7          	jalr	786(ra) # 4f4 <close>
        return;
 1ea:	b571                	j	76 <find+0x76>
            fprintf(2, "find: cannot stat %s\n", buf);
 1ec:	db040613          	addi	a2,s0,-592
 1f0:	00001597          	auipc	a1,0x1
 1f4:	81058593          	addi	a1,a1,-2032 # a00 <malloc+0xfe>
 1f8:	4509                	li	a0,2
 1fa:	00000097          	auipc	ra,0x0
 1fe:	61c080e7          	jalr	1564(ra) # 816 <fprintf>
            continue;
 202:	bf05                	j	132 <find+0x132>
            find(buf, file);
 204:	85ce                	mv	a1,s3
 206:	db040513          	addi	a0,s0,-592
 20a:	00000097          	auipc	ra,0x0
 20e:	df6080e7          	jalr	-522(ra) # 0 <find>
 212:	b705                	j	132 <find+0x132>

0000000000000214 <main>:

int
main(int argc, char *argv[])
{
 214:	1141                	addi	sp,sp,-16
 216:	e406                	sd	ra,8(sp)
 218:	e022                	sd	s0,0(sp)
 21a:	0800                	addi	s0,sp,16
    // 如果参数个数不为 3 则报错
    if (argc != 3)
 21c:	470d                	li	a4,3
 21e:	02e50063          	beq	a0,a4,23e <main+0x2a>
    {
        // 输出提示
        fprintf(2, "usage: find dirName fileName\n");
 222:	00001597          	auipc	a1,0x1
 226:	84e58593          	addi	a1,a1,-1970 # a70 <malloc+0x16e>
 22a:	4509                	li	a0,2
 22c:	00000097          	auipc	ra,0x0
 230:	5ea080e7          	jalr	1514(ra) # 816 <fprintf>
        // 异常退出
        exit(1);
 234:	4505                	li	a0,1
 236:	00000097          	auipc	ra,0x0
 23a:	296080e7          	jalr	662(ra) # 4cc <exit>
 23e:	87ae                	mv	a5,a1
    }
    // 调用 find 函数查找指定目录下的文件
    find(argv[1], argv[2]);
 240:	698c                	ld	a1,16(a1)
 242:	6788                	ld	a0,8(a5)
 244:	00000097          	auipc	ra,0x0
 248:	dbc080e7          	jalr	-580(ra) # 0 <find>
    // 正常退出
    exit(0);
 24c:	4501                	li	a0,0
 24e:	00000097          	auipc	ra,0x0
 252:	27e080e7          	jalr	638(ra) # 4cc <exit>

0000000000000256 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 256:	1141                	addi	sp,sp,-16
 258:	e422                	sd	s0,8(sp)
 25a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 25c:	87aa                	mv	a5,a0
 25e:	0585                	addi	a1,a1,1
 260:	0785                	addi	a5,a5,1
 262:	fff5c703          	lbu	a4,-1(a1)
 266:	fee78fa3          	sb	a4,-1(a5)
 26a:	fb75                	bnez	a4,25e <strcpy+0x8>
    ;
  return os;
}
 26c:	6422                	ld	s0,8(sp)
 26e:	0141                	addi	sp,sp,16
 270:	8082                	ret

0000000000000272 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 272:	1141                	addi	sp,sp,-16
 274:	e422                	sd	s0,8(sp)
 276:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 278:	00054783          	lbu	a5,0(a0)
 27c:	cb91                	beqz	a5,290 <strcmp+0x1e>
 27e:	0005c703          	lbu	a4,0(a1)
 282:	00f71763          	bne	a4,a5,290 <strcmp+0x1e>
    p++, q++;
 286:	0505                	addi	a0,a0,1
 288:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 28a:	00054783          	lbu	a5,0(a0)
 28e:	fbe5                	bnez	a5,27e <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 290:	0005c503          	lbu	a0,0(a1)
}
 294:	40a7853b          	subw	a0,a5,a0
 298:	6422                	ld	s0,8(sp)
 29a:	0141                	addi	sp,sp,16
 29c:	8082                	ret

000000000000029e <strlen>:

uint
strlen(const char *s)
{
 29e:	1141                	addi	sp,sp,-16
 2a0:	e422                	sd	s0,8(sp)
 2a2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2a4:	00054783          	lbu	a5,0(a0)
 2a8:	cf91                	beqz	a5,2c4 <strlen+0x26>
 2aa:	0505                	addi	a0,a0,1
 2ac:	87aa                	mv	a5,a0
 2ae:	4685                	li	a3,1
 2b0:	9e89                	subw	a3,a3,a0
 2b2:	00f6853b          	addw	a0,a3,a5
 2b6:	0785                	addi	a5,a5,1
 2b8:	fff7c703          	lbu	a4,-1(a5)
 2bc:	fb7d                	bnez	a4,2b2 <strlen+0x14>
    ;
  return n;
}
 2be:	6422                	ld	s0,8(sp)
 2c0:	0141                	addi	sp,sp,16
 2c2:	8082                	ret
  for(n = 0; s[n]; n++)
 2c4:	4501                	li	a0,0
 2c6:	bfe5                	j	2be <strlen+0x20>

00000000000002c8 <memset>:

void*
memset(void *dst, int c, uint n)
{
 2c8:	1141                	addi	sp,sp,-16
 2ca:	e422                	sd	s0,8(sp)
 2cc:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2ce:	ce09                	beqz	a2,2e8 <memset+0x20>
 2d0:	87aa                	mv	a5,a0
 2d2:	fff6071b          	addiw	a4,a2,-1
 2d6:	1702                	slli	a4,a4,0x20
 2d8:	9301                	srli	a4,a4,0x20
 2da:	0705                	addi	a4,a4,1
 2dc:	972a                	add	a4,a4,a0
    cdst[i] = c;
 2de:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 2e2:	0785                	addi	a5,a5,1
 2e4:	fee79de3          	bne	a5,a4,2de <memset+0x16>
  }
  return dst;
}
 2e8:	6422                	ld	s0,8(sp)
 2ea:	0141                	addi	sp,sp,16
 2ec:	8082                	ret

00000000000002ee <strchr>:

char*
strchr(const char *s, char c)
{
 2ee:	1141                	addi	sp,sp,-16
 2f0:	e422                	sd	s0,8(sp)
 2f2:	0800                	addi	s0,sp,16
  for(; *s; s++)
 2f4:	00054783          	lbu	a5,0(a0)
 2f8:	cb99                	beqz	a5,30e <strchr+0x20>
    if(*s == c)
 2fa:	00f58763          	beq	a1,a5,308 <strchr+0x1a>
  for(; *s; s++)
 2fe:	0505                	addi	a0,a0,1
 300:	00054783          	lbu	a5,0(a0)
 304:	fbfd                	bnez	a5,2fa <strchr+0xc>
      return (char*)s;
  return 0;
 306:	4501                	li	a0,0
}
 308:	6422                	ld	s0,8(sp)
 30a:	0141                	addi	sp,sp,16
 30c:	8082                	ret
  return 0;
 30e:	4501                	li	a0,0
 310:	bfe5                	j	308 <strchr+0x1a>

0000000000000312 <gets>:

char*
gets(char *buf, int max)
{
 312:	711d                	addi	sp,sp,-96
 314:	ec86                	sd	ra,88(sp)
 316:	e8a2                	sd	s0,80(sp)
 318:	e4a6                	sd	s1,72(sp)
 31a:	e0ca                	sd	s2,64(sp)
 31c:	fc4e                	sd	s3,56(sp)
 31e:	f852                	sd	s4,48(sp)
 320:	f456                	sd	s5,40(sp)
 322:	f05a                	sd	s6,32(sp)
 324:	ec5e                	sd	s7,24(sp)
 326:	1080                	addi	s0,sp,96
 328:	8baa                	mv	s7,a0
 32a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 32c:	892a                	mv	s2,a0
 32e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 330:	4aa9                	li	s5,10
 332:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 334:	89a6                	mv	s3,s1
 336:	2485                	addiw	s1,s1,1
 338:	0344d863          	bge	s1,s4,368 <gets+0x56>
    cc = read(0, &c, 1);
 33c:	4605                	li	a2,1
 33e:	faf40593          	addi	a1,s0,-81
 342:	4501                	li	a0,0
 344:	00000097          	auipc	ra,0x0
 348:	1a0080e7          	jalr	416(ra) # 4e4 <read>
    if(cc < 1)
 34c:	00a05e63          	blez	a0,368 <gets+0x56>
    buf[i++] = c;
 350:	faf44783          	lbu	a5,-81(s0)
 354:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 358:	01578763          	beq	a5,s5,366 <gets+0x54>
 35c:	0905                	addi	s2,s2,1
 35e:	fd679be3          	bne	a5,s6,334 <gets+0x22>
  for(i=0; i+1 < max; ){
 362:	89a6                	mv	s3,s1
 364:	a011                	j	368 <gets+0x56>
 366:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 368:	99de                	add	s3,s3,s7
 36a:	00098023          	sb	zero,0(s3)
  return buf;
}
 36e:	855e                	mv	a0,s7
 370:	60e6                	ld	ra,88(sp)
 372:	6446                	ld	s0,80(sp)
 374:	64a6                	ld	s1,72(sp)
 376:	6906                	ld	s2,64(sp)
 378:	79e2                	ld	s3,56(sp)
 37a:	7a42                	ld	s4,48(sp)
 37c:	7aa2                	ld	s5,40(sp)
 37e:	7b02                	ld	s6,32(sp)
 380:	6be2                	ld	s7,24(sp)
 382:	6125                	addi	sp,sp,96
 384:	8082                	ret

0000000000000386 <stat>:

int
stat(const char *n, struct stat *st)
{
 386:	1101                	addi	sp,sp,-32
 388:	ec06                	sd	ra,24(sp)
 38a:	e822                	sd	s0,16(sp)
 38c:	e426                	sd	s1,8(sp)
 38e:	e04a                	sd	s2,0(sp)
 390:	1000                	addi	s0,sp,32
 392:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 394:	4581                	li	a1,0
 396:	00000097          	auipc	ra,0x0
 39a:	176080e7          	jalr	374(ra) # 50c <open>
  if(fd < 0)
 39e:	02054563          	bltz	a0,3c8 <stat+0x42>
 3a2:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3a4:	85ca                	mv	a1,s2
 3a6:	00000097          	auipc	ra,0x0
 3aa:	17e080e7          	jalr	382(ra) # 524 <fstat>
 3ae:	892a                	mv	s2,a0
  close(fd);
 3b0:	8526                	mv	a0,s1
 3b2:	00000097          	auipc	ra,0x0
 3b6:	142080e7          	jalr	322(ra) # 4f4 <close>
  return r;
}
 3ba:	854a                	mv	a0,s2
 3bc:	60e2                	ld	ra,24(sp)
 3be:	6442                	ld	s0,16(sp)
 3c0:	64a2                	ld	s1,8(sp)
 3c2:	6902                	ld	s2,0(sp)
 3c4:	6105                	addi	sp,sp,32
 3c6:	8082                	ret
    return -1;
 3c8:	597d                	li	s2,-1
 3ca:	bfc5                	j	3ba <stat+0x34>

00000000000003cc <atoi>:

int
atoi(const char *s)
{
 3cc:	1141                	addi	sp,sp,-16
 3ce:	e422                	sd	s0,8(sp)
 3d0:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 3d2:	00054603          	lbu	a2,0(a0)
 3d6:	fd06079b          	addiw	a5,a2,-48
 3da:	0ff7f793          	andi	a5,a5,255
 3de:	4725                	li	a4,9
 3e0:	02f76963          	bltu	a4,a5,412 <atoi+0x46>
 3e4:	86aa                	mv	a3,a0
  n = 0;
 3e6:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 3e8:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 3ea:	0685                	addi	a3,a3,1
 3ec:	0025179b          	slliw	a5,a0,0x2
 3f0:	9fa9                	addw	a5,a5,a0
 3f2:	0017979b          	slliw	a5,a5,0x1
 3f6:	9fb1                	addw	a5,a5,a2
 3f8:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 3fc:	0006c603          	lbu	a2,0(a3)
 400:	fd06071b          	addiw	a4,a2,-48
 404:	0ff77713          	andi	a4,a4,255
 408:	fee5f1e3          	bgeu	a1,a4,3ea <atoi+0x1e>
  return n;
}
 40c:	6422                	ld	s0,8(sp)
 40e:	0141                	addi	sp,sp,16
 410:	8082                	ret
  n = 0;
 412:	4501                	li	a0,0
 414:	bfe5                	j	40c <atoi+0x40>

0000000000000416 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 416:	1141                	addi	sp,sp,-16
 418:	e422                	sd	s0,8(sp)
 41a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 41c:	02b57663          	bgeu	a0,a1,448 <memmove+0x32>
    while(n-- > 0)
 420:	02c05163          	blez	a2,442 <memmove+0x2c>
 424:	fff6079b          	addiw	a5,a2,-1
 428:	1782                	slli	a5,a5,0x20
 42a:	9381                	srli	a5,a5,0x20
 42c:	0785                	addi	a5,a5,1
 42e:	97aa                	add	a5,a5,a0
  dst = vdst;
 430:	872a                	mv	a4,a0
      *dst++ = *src++;
 432:	0585                	addi	a1,a1,1
 434:	0705                	addi	a4,a4,1
 436:	fff5c683          	lbu	a3,-1(a1)
 43a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 43e:	fee79ae3          	bne	a5,a4,432 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 442:	6422                	ld	s0,8(sp)
 444:	0141                	addi	sp,sp,16
 446:	8082                	ret
    dst += n;
 448:	00c50733          	add	a4,a0,a2
    src += n;
 44c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 44e:	fec05ae3          	blez	a2,442 <memmove+0x2c>
 452:	fff6079b          	addiw	a5,a2,-1
 456:	1782                	slli	a5,a5,0x20
 458:	9381                	srli	a5,a5,0x20
 45a:	fff7c793          	not	a5,a5
 45e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 460:	15fd                	addi	a1,a1,-1
 462:	177d                	addi	a4,a4,-1
 464:	0005c683          	lbu	a3,0(a1)
 468:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 46c:	fee79ae3          	bne	a5,a4,460 <memmove+0x4a>
 470:	bfc9                	j	442 <memmove+0x2c>

0000000000000472 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 472:	1141                	addi	sp,sp,-16
 474:	e422                	sd	s0,8(sp)
 476:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 478:	ca05                	beqz	a2,4a8 <memcmp+0x36>
 47a:	fff6069b          	addiw	a3,a2,-1
 47e:	1682                	slli	a3,a3,0x20
 480:	9281                	srli	a3,a3,0x20
 482:	0685                	addi	a3,a3,1
 484:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 486:	00054783          	lbu	a5,0(a0)
 48a:	0005c703          	lbu	a4,0(a1)
 48e:	00e79863          	bne	a5,a4,49e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 492:	0505                	addi	a0,a0,1
    p2++;
 494:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 496:	fed518e3          	bne	a0,a3,486 <memcmp+0x14>
  }
  return 0;
 49a:	4501                	li	a0,0
 49c:	a019                	j	4a2 <memcmp+0x30>
      return *p1 - *p2;
 49e:	40e7853b          	subw	a0,a5,a4
}
 4a2:	6422                	ld	s0,8(sp)
 4a4:	0141                	addi	sp,sp,16
 4a6:	8082                	ret
  return 0;
 4a8:	4501                	li	a0,0
 4aa:	bfe5                	j	4a2 <memcmp+0x30>

00000000000004ac <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4ac:	1141                	addi	sp,sp,-16
 4ae:	e406                	sd	ra,8(sp)
 4b0:	e022                	sd	s0,0(sp)
 4b2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4b4:	00000097          	auipc	ra,0x0
 4b8:	f62080e7          	jalr	-158(ra) # 416 <memmove>
}
 4bc:	60a2                	ld	ra,8(sp)
 4be:	6402                	ld	s0,0(sp)
 4c0:	0141                	addi	sp,sp,16
 4c2:	8082                	ret

00000000000004c4 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4c4:	4885                	li	a7,1
 ecall
 4c6:	00000073          	ecall
 ret
 4ca:	8082                	ret

00000000000004cc <exit>:
.global exit
exit:
 li a7, SYS_exit
 4cc:	4889                	li	a7,2
 ecall
 4ce:	00000073          	ecall
 ret
 4d2:	8082                	ret

00000000000004d4 <wait>:
.global wait
wait:
 li a7, SYS_wait
 4d4:	488d                	li	a7,3
 ecall
 4d6:	00000073          	ecall
 ret
 4da:	8082                	ret

00000000000004dc <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4dc:	4891                	li	a7,4
 ecall
 4de:	00000073          	ecall
 ret
 4e2:	8082                	ret

00000000000004e4 <read>:
.global read
read:
 li a7, SYS_read
 4e4:	4895                	li	a7,5
 ecall
 4e6:	00000073          	ecall
 ret
 4ea:	8082                	ret

00000000000004ec <write>:
.global write
write:
 li a7, SYS_write
 4ec:	48c1                	li	a7,16
 ecall
 4ee:	00000073          	ecall
 ret
 4f2:	8082                	ret

00000000000004f4 <close>:
.global close
close:
 li a7, SYS_close
 4f4:	48d5                	li	a7,21
 ecall
 4f6:	00000073          	ecall
 ret
 4fa:	8082                	ret

00000000000004fc <kill>:
.global kill
kill:
 li a7, SYS_kill
 4fc:	4899                	li	a7,6
 ecall
 4fe:	00000073          	ecall
 ret
 502:	8082                	ret

0000000000000504 <exec>:
.global exec
exec:
 li a7, SYS_exec
 504:	489d                	li	a7,7
 ecall
 506:	00000073          	ecall
 ret
 50a:	8082                	ret

000000000000050c <open>:
.global open
open:
 li a7, SYS_open
 50c:	48bd                	li	a7,15
 ecall
 50e:	00000073          	ecall
 ret
 512:	8082                	ret

0000000000000514 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 514:	48c5                	li	a7,17
 ecall
 516:	00000073          	ecall
 ret
 51a:	8082                	ret

000000000000051c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 51c:	48c9                	li	a7,18
 ecall
 51e:	00000073          	ecall
 ret
 522:	8082                	ret

0000000000000524 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 524:	48a1                	li	a7,8
 ecall
 526:	00000073          	ecall
 ret
 52a:	8082                	ret

000000000000052c <link>:
.global link
link:
 li a7, SYS_link
 52c:	48cd                	li	a7,19
 ecall
 52e:	00000073          	ecall
 ret
 532:	8082                	ret

0000000000000534 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 534:	48d1                	li	a7,20
 ecall
 536:	00000073          	ecall
 ret
 53a:	8082                	ret

000000000000053c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 53c:	48a5                	li	a7,9
 ecall
 53e:	00000073          	ecall
 ret
 542:	8082                	ret

0000000000000544 <dup>:
.global dup
dup:
 li a7, SYS_dup
 544:	48a9                	li	a7,10
 ecall
 546:	00000073          	ecall
 ret
 54a:	8082                	ret

000000000000054c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 54c:	48ad                	li	a7,11
 ecall
 54e:	00000073          	ecall
 ret
 552:	8082                	ret

0000000000000554 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 554:	48b1                	li	a7,12
 ecall
 556:	00000073          	ecall
 ret
 55a:	8082                	ret

000000000000055c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 55c:	48b5                	li	a7,13
 ecall
 55e:	00000073          	ecall
 ret
 562:	8082                	ret

0000000000000564 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 564:	48b9                	li	a7,14
 ecall
 566:	00000073          	ecall
 ret
 56a:	8082                	ret

000000000000056c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 56c:	1101                	addi	sp,sp,-32
 56e:	ec06                	sd	ra,24(sp)
 570:	e822                	sd	s0,16(sp)
 572:	1000                	addi	s0,sp,32
 574:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 578:	4605                	li	a2,1
 57a:	fef40593          	addi	a1,s0,-17
 57e:	00000097          	auipc	ra,0x0
 582:	f6e080e7          	jalr	-146(ra) # 4ec <write>
}
 586:	60e2                	ld	ra,24(sp)
 588:	6442                	ld	s0,16(sp)
 58a:	6105                	addi	sp,sp,32
 58c:	8082                	ret

000000000000058e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 58e:	7139                	addi	sp,sp,-64
 590:	fc06                	sd	ra,56(sp)
 592:	f822                	sd	s0,48(sp)
 594:	f426                	sd	s1,40(sp)
 596:	f04a                	sd	s2,32(sp)
 598:	ec4e                	sd	s3,24(sp)
 59a:	0080                	addi	s0,sp,64
 59c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 59e:	c299                	beqz	a3,5a4 <printint+0x16>
 5a0:	0805c863          	bltz	a1,630 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5a4:	2581                	sext.w	a1,a1
  neg = 0;
 5a6:	4881                	li	a7,0
 5a8:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 5ac:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 5ae:	2601                	sext.w	a2,a2
 5b0:	00000517          	auipc	a0,0x0
 5b4:	4e850513          	addi	a0,a0,1256 # a98 <digits>
 5b8:	883a                	mv	a6,a4
 5ba:	2705                	addiw	a4,a4,1
 5bc:	02c5f7bb          	remuw	a5,a1,a2
 5c0:	1782                	slli	a5,a5,0x20
 5c2:	9381                	srli	a5,a5,0x20
 5c4:	97aa                	add	a5,a5,a0
 5c6:	0007c783          	lbu	a5,0(a5)
 5ca:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 5ce:	0005879b          	sext.w	a5,a1
 5d2:	02c5d5bb          	divuw	a1,a1,a2
 5d6:	0685                	addi	a3,a3,1
 5d8:	fec7f0e3          	bgeu	a5,a2,5b8 <printint+0x2a>
  if(neg)
 5dc:	00088b63          	beqz	a7,5f2 <printint+0x64>
    buf[i++] = '-';
 5e0:	fd040793          	addi	a5,s0,-48
 5e4:	973e                	add	a4,a4,a5
 5e6:	02d00793          	li	a5,45
 5ea:	fef70823          	sb	a5,-16(a4)
 5ee:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 5f2:	02e05863          	blez	a4,622 <printint+0x94>
 5f6:	fc040793          	addi	a5,s0,-64
 5fa:	00e78933          	add	s2,a5,a4
 5fe:	fff78993          	addi	s3,a5,-1
 602:	99ba                	add	s3,s3,a4
 604:	377d                	addiw	a4,a4,-1
 606:	1702                	slli	a4,a4,0x20
 608:	9301                	srli	a4,a4,0x20
 60a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 60e:	fff94583          	lbu	a1,-1(s2)
 612:	8526                	mv	a0,s1
 614:	00000097          	auipc	ra,0x0
 618:	f58080e7          	jalr	-168(ra) # 56c <putc>
  while(--i >= 0)
 61c:	197d                	addi	s2,s2,-1
 61e:	ff3918e3          	bne	s2,s3,60e <printint+0x80>
}
 622:	70e2                	ld	ra,56(sp)
 624:	7442                	ld	s0,48(sp)
 626:	74a2                	ld	s1,40(sp)
 628:	7902                	ld	s2,32(sp)
 62a:	69e2                	ld	s3,24(sp)
 62c:	6121                	addi	sp,sp,64
 62e:	8082                	ret
    x = -xx;
 630:	40b005bb          	negw	a1,a1
    neg = 1;
 634:	4885                	li	a7,1
    x = -xx;
 636:	bf8d                	j	5a8 <printint+0x1a>

0000000000000638 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 638:	7119                	addi	sp,sp,-128
 63a:	fc86                	sd	ra,120(sp)
 63c:	f8a2                	sd	s0,112(sp)
 63e:	f4a6                	sd	s1,104(sp)
 640:	f0ca                	sd	s2,96(sp)
 642:	ecce                	sd	s3,88(sp)
 644:	e8d2                	sd	s4,80(sp)
 646:	e4d6                	sd	s5,72(sp)
 648:	e0da                	sd	s6,64(sp)
 64a:	fc5e                	sd	s7,56(sp)
 64c:	f862                	sd	s8,48(sp)
 64e:	f466                	sd	s9,40(sp)
 650:	f06a                	sd	s10,32(sp)
 652:	ec6e                	sd	s11,24(sp)
 654:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 656:	0005c903          	lbu	s2,0(a1)
 65a:	18090f63          	beqz	s2,7f8 <vprintf+0x1c0>
 65e:	8aaa                	mv	s5,a0
 660:	8b32                	mv	s6,a2
 662:	00158493          	addi	s1,a1,1
  state = 0;
 666:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 668:	02500a13          	li	s4,37
      if(c == 'd'){
 66c:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 670:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 674:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 678:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 67c:	00000b97          	auipc	s7,0x0
 680:	41cb8b93          	addi	s7,s7,1052 # a98 <digits>
 684:	a839                	j	6a2 <vprintf+0x6a>
        putc(fd, c);
 686:	85ca                	mv	a1,s2
 688:	8556                	mv	a0,s5
 68a:	00000097          	auipc	ra,0x0
 68e:	ee2080e7          	jalr	-286(ra) # 56c <putc>
 692:	a019                	j	698 <vprintf+0x60>
    } else if(state == '%'){
 694:	01498f63          	beq	s3,s4,6b2 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 698:	0485                	addi	s1,s1,1
 69a:	fff4c903          	lbu	s2,-1(s1)
 69e:	14090d63          	beqz	s2,7f8 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6a2:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6a6:	fe0997e3          	bnez	s3,694 <vprintf+0x5c>
      if(c == '%'){
 6aa:	fd479ee3          	bne	a5,s4,686 <vprintf+0x4e>
        state = '%';
 6ae:	89be                	mv	s3,a5
 6b0:	b7e5                	j	698 <vprintf+0x60>
      if(c == 'd'){
 6b2:	05878063          	beq	a5,s8,6f2 <vprintf+0xba>
      } else if(c == 'l') {
 6b6:	05978c63          	beq	a5,s9,70e <vprintf+0xd6>
      } else if(c == 'x') {
 6ba:	07a78863          	beq	a5,s10,72a <vprintf+0xf2>
      } else if(c == 'p') {
 6be:	09b78463          	beq	a5,s11,746 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 6c2:	07300713          	li	a4,115
 6c6:	0ce78663          	beq	a5,a4,792 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6ca:	06300713          	li	a4,99
 6ce:	0ee78e63          	beq	a5,a4,7ca <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 6d2:	11478863          	beq	a5,s4,7e2 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 6d6:	85d2                	mv	a1,s4
 6d8:	8556                	mv	a0,s5
 6da:	00000097          	auipc	ra,0x0
 6de:	e92080e7          	jalr	-366(ra) # 56c <putc>
        putc(fd, c);
 6e2:	85ca                	mv	a1,s2
 6e4:	8556                	mv	a0,s5
 6e6:	00000097          	auipc	ra,0x0
 6ea:	e86080e7          	jalr	-378(ra) # 56c <putc>
      }
      state = 0;
 6ee:	4981                	li	s3,0
 6f0:	b765                	j	698 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 6f2:	008b0913          	addi	s2,s6,8
 6f6:	4685                	li	a3,1
 6f8:	4629                	li	a2,10
 6fa:	000b2583          	lw	a1,0(s6)
 6fe:	8556                	mv	a0,s5
 700:	00000097          	auipc	ra,0x0
 704:	e8e080e7          	jalr	-370(ra) # 58e <printint>
 708:	8b4a                	mv	s6,s2
      state = 0;
 70a:	4981                	li	s3,0
 70c:	b771                	j	698 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 70e:	008b0913          	addi	s2,s6,8
 712:	4681                	li	a3,0
 714:	4629                	li	a2,10
 716:	000b2583          	lw	a1,0(s6)
 71a:	8556                	mv	a0,s5
 71c:	00000097          	auipc	ra,0x0
 720:	e72080e7          	jalr	-398(ra) # 58e <printint>
 724:	8b4a                	mv	s6,s2
      state = 0;
 726:	4981                	li	s3,0
 728:	bf85                	j	698 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 72a:	008b0913          	addi	s2,s6,8
 72e:	4681                	li	a3,0
 730:	4641                	li	a2,16
 732:	000b2583          	lw	a1,0(s6)
 736:	8556                	mv	a0,s5
 738:	00000097          	auipc	ra,0x0
 73c:	e56080e7          	jalr	-426(ra) # 58e <printint>
 740:	8b4a                	mv	s6,s2
      state = 0;
 742:	4981                	li	s3,0
 744:	bf91                	j	698 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 746:	008b0793          	addi	a5,s6,8
 74a:	f8f43423          	sd	a5,-120(s0)
 74e:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 752:	03000593          	li	a1,48
 756:	8556                	mv	a0,s5
 758:	00000097          	auipc	ra,0x0
 75c:	e14080e7          	jalr	-492(ra) # 56c <putc>
  putc(fd, 'x');
 760:	85ea                	mv	a1,s10
 762:	8556                	mv	a0,s5
 764:	00000097          	auipc	ra,0x0
 768:	e08080e7          	jalr	-504(ra) # 56c <putc>
 76c:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 76e:	03c9d793          	srli	a5,s3,0x3c
 772:	97de                	add	a5,a5,s7
 774:	0007c583          	lbu	a1,0(a5)
 778:	8556                	mv	a0,s5
 77a:	00000097          	auipc	ra,0x0
 77e:	df2080e7          	jalr	-526(ra) # 56c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 782:	0992                	slli	s3,s3,0x4
 784:	397d                	addiw	s2,s2,-1
 786:	fe0914e3          	bnez	s2,76e <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 78a:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 78e:	4981                	li	s3,0
 790:	b721                	j	698 <vprintf+0x60>
        s = va_arg(ap, char*);
 792:	008b0993          	addi	s3,s6,8
 796:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 79a:	02090163          	beqz	s2,7bc <vprintf+0x184>
        while(*s != 0){
 79e:	00094583          	lbu	a1,0(s2)
 7a2:	c9a1                	beqz	a1,7f2 <vprintf+0x1ba>
          putc(fd, *s);
 7a4:	8556                	mv	a0,s5
 7a6:	00000097          	auipc	ra,0x0
 7aa:	dc6080e7          	jalr	-570(ra) # 56c <putc>
          s++;
 7ae:	0905                	addi	s2,s2,1
        while(*s != 0){
 7b0:	00094583          	lbu	a1,0(s2)
 7b4:	f9e5                	bnez	a1,7a4 <vprintf+0x16c>
        s = va_arg(ap, char*);
 7b6:	8b4e                	mv	s6,s3
      state = 0;
 7b8:	4981                	li	s3,0
 7ba:	bdf9                	j	698 <vprintf+0x60>
          s = "(null)";
 7bc:	00000917          	auipc	s2,0x0
 7c0:	2d490913          	addi	s2,s2,724 # a90 <malloc+0x18e>
        while(*s != 0){
 7c4:	02800593          	li	a1,40
 7c8:	bff1                	j	7a4 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 7ca:	008b0913          	addi	s2,s6,8
 7ce:	000b4583          	lbu	a1,0(s6)
 7d2:	8556                	mv	a0,s5
 7d4:	00000097          	auipc	ra,0x0
 7d8:	d98080e7          	jalr	-616(ra) # 56c <putc>
 7dc:	8b4a                	mv	s6,s2
      state = 0;
 7de:	4981                	li	s3,0
 7e0:	bd65                	j	698 <vprintf+0x60>
        putc(fd, c);
 7e2:	85d2                	mv	a1,s4
 7e4:	8556                	mv	a0,s5
 7e6:	00000097          	auipc	ra,0x0
 7ea:	d86080e7          	jalr	-634(ra) # 56c <putc>
      state = 0;
 7ee:	4981                	li	s3,0
 7f0:	b565                	j	698 <vprintf+0x60>
        s = va_arg(ap, char*);
 7f2:	8b4e                	mv	s6,s3
      state = 0;
 7f4:	4981                	li	s3,0
 7f6:	b54d                	j	698 <vprintf+0x60>
    }
  }
}
 7f8:	70e6                	ld	ra,120(sp)
 7fa:	7446                	ld	s0,112(sp)
 7fc:	74a6                	ld	s1,104(sp)
 7fe:	7906                	ld	s2,96(sp)
 800:	69e6                	ld	s3,88(sp)
 802:	6a46                	ld	s4,80(sp)
 804:	6aa6                	ld	s5,72(sp)
 806:	6b06                	ld	s6,64(sp)
 808:	7be2                	ld	s7,56(sp)
 80a:	7c42                	ld	s8,48(sp)
 80c:	7ca2                	ld	s9,40(sp)
 80e:	7d02                	ld	s10,32(sp)
 810:	6de2                	ld	s11,24(sp)
 812:	6109                	addi	sp,sp,128
 814:	8082                	ret

0000000000000816 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 816:	715d                	addi	sp,sp,-80
 818:	ec06                	sd	ra,24(sp)
 81a:	e822                	sd	s0,16(sp)
 81c:	1000                	addi	s0,sp,32
 81e:	e010                	sd	a2,0(s0)
 820:	e414                	sd	a3,8(s0)
 822:	e818                	sd	a4,16(s0)
 824:	ec1c                	sd	a5,24(s0)
 826:	03043023          	sd	a6,32(s0)
 82a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 82e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 832:	8622                	mv	a2,s0
 834:	00000097          	auipc	ra,0x0
 838:	e04080e7          	jalr	-508(ra) # 638 <vprintf>
}
 83c:	60e2                	ld	ra,24(sp)
 83e:	6442                	ld	s0,16(sp)
 840:	6161                	addi	sp,sp,80
 842:	8082                	ret

0000000000000844 <printf>:

void
printf(const char *fmt, ...)
{
 844:	711d                	addi	sp,sp,-96
 846:	ec06                	sd	ra,24(sp)
 848:	e822                	sd	s0,16(sp)
 84a:	1000                	addi	s0,sp,32
 84c:	e40c                	sd	a1,8(s0)
 84e:	e810                	sd	a2,16(s0)
 850:	ec14                	sd	a3,24(s0)
 852:	f018                	sd	a4,32(s0)
 854:	f41c                	sd	a5,40(s0)
 856:	03043823          	sd	a6,48(s0)
 85a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 85e:	00840613          	addi	a2,s0,8
 862:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 866:	85aa                	mv	a1,a0
 868:	4505                	li	a0,1
 86a:	00000097          	auipc	ra,0x0
 86e:	dce080e7          	jalr	-562(ra) # 638 <vprintf>
}
 872:	60e2                	ld	ra,24(sp)
 874:	6442                	ld	s0,16(sp)
 876:	6125                	addi	sp,sp,96
 878:	8082                	ret

000000000000087a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 87a:	1141                	addi	sp,sp,-16
 87c:	e422                	sd	s0,8(sp)
 87e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 880:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 884:	00000797          	auipc	a5,0x0
 888:	22c7b783          	ld	a5,556(a5) # ab0 <freep>
 88c:	a805                	j	8bc <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 88e:	4618                	lw	a4,8(a2)
 890:	9db9                	addw	a1,a1,a4
 892:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 896:	6398                	ld	a4,0(a5)
 898:	6318                	ld	a4,0(a4)
 89a:	fee53823          	sd	a4,-16(a0)
 89e:	a091                	j	8e2 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8a0:	ff852703          	lw	a4,-8(a0)
 8a4:	9e39                	addw	a2,a2,a4
 8a6:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8a8:	ff053703          	ld	a4,-16(a0)
 8ac:	e398                	sd	a4,0(a5)
 8ae:	a099                	j	8f4 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8b0:	6398                	ld	a4,0(a5)
 8b2:	00e7e463          	bltu	a5,a4,8ba <free+0x40>
 8b6:	00e6ea63          	bltu	a3,a4,8ca <free+0x50>
{
 8ba:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8bc:	fed7fae3          	bgeu	a5,a3,8b0 <free+0x36>
 8c0:	6398                	ld	a4,0(a5)
 8c2:	00e6e463          	bltu	a3,a4,8ca <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8c6:	fee7eae3          	bltu	a5,a4,8ba <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 8ca:	ff852583          	lw	a1,-8(a0)
 8ce:	6390                	ld	a2,0(a5)
 8d0:	02059713          	slli	a4,a1,0x20
 8d4:	9301                	srli	a4,a4,0x20
 8d6:	0712                	slli	a4,a4,0x4
 8d8:	9736                	add	a4,a4,a3
 8da:	fae60ae3          	beq	a2,a4,88e <free+0x14>
    bp->s.ptr = p->s.ptr;
 8de:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 8e2:	4790                	lw	a2,8(a5)
 8e4:	02061713          	slli	a4,a2,0x20
 8e8:	9301                	srli	a4,a4,0x20
 8ea:	0712                	slli	a4,a4,0x4
 8ec:	973e                	add	a4,a4,a5
 8ee:	fae689e3          	beq	a3,a4,8a0 <free+0x26>
  } else
    p->s.ptr = bp;
 8f2:	e394                	sd	a3,0(a5)
  freep = p;
 8f4:	00000717          	auipc	a4,0x0
 8f8:	1af73e23          	sd	a5,444(a4) # ab0 <freep>
}
 8fc:	6422                	ld	s0,8(sp)
 8fe:	0141                	addi	sp,sp,16
 900:	8082                	ret

0000000000000902 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 902:	7139                	addi	sp,sp,-64
 904:	fc06                	sd	ra,56(sp)
 906:	f822                	sd	s0,48(sp)
 908:	f426                	sd	s1,40(sp)
 90a:	f04a                	sd	s2,32(sp)
 90c:	ec4e                	sd	s3,24(sp)
 90e:	e852                	sd	s4,16(sp)
 910:	e456                	sd	s5,8(sp)
 912:	e05a                	sd	s6,0(sp)
 914:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 916:	02051493          	slli	s1,a0,0x20
 91a:	9081                	srli	s1,s1,0x20
 91c:	04bd                	addi	s1,s1,15
 91e:	8091                	srli	s1,s1,0x4
 920:	0014899b          	addiw	s3,s1,1
 924:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 926:	00000517          	auipc	a0,0x0
 92a:	18a53503          	ld	a0,394(a0) # ab0 <freep>
 92e:	c515                	beqz	a0,95a <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 930:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 932:	4798                	lw	a4,8(a5)
 934:	02977f63          	bgeu	a4,s1,972 <malloc+0x70>
 938:	8a4e                	mv	s4,s3
 93a:	0009871b          	sext.w	a4,s3
 93e:	6685                	lui	a3,0x1
 940:	00d77363          	bgeu	a4,a3,946 <malloc+0x44>
 944:	6a05                	lui	s4,0x1
 946:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 94a:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 94e:	00000917          	auipc	s2,0x0
 952:	16290913          	addi	s2,s2,354 # ab0 <freep>
  if(p == (char*)-1)
 956:	5afd                	li	s5,-1
 958:	a88d                	j	9ca <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 95a:	00000797          	auipc	a5,0x0
 95e:	15e78793          	addi	a5,a5,350 # ab8 <base>
 962:	00000717          	auipc	a4,0x0
 966:	14f73723          	sd	a5,334(a4) # ab0 <freep>
 96a:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 96c:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 970:	b7e1                	j	938 <malloc+0x36>
      if(p->s.size == nunits)
 972:	02e48b63          	beq	s1,a4,9a8 <malloc+0xa6>
        p->s.size -= nunits;
 976:	4137073b          	subw	a4,a4,s3
 97a:	c798                	sw	a4,8(a5)
        p += p->s.size;
 97c:	1702                	slli	a4,a4,0x20
 97e:	9301                	srli	a4,a4,0x20
 980:	0712                	slli	a4,a4,0x4
 982:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 984:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 988:	00000717          	auipc	a4,0x0
 98c:	12a73423          	sd	a0,296(a4) # ab0 <freep>
      return (void*)(p + 1);
 990:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 994:	70e2                	ld	ra,56(sp)
 996:	7442                	ld	s0,48(sp)
 998:	74a2                	ld	s1,40(sp)
 99a:	7902                	ld	s2,32(sp)
 99c:	69e2                	ld	s3,24(sp)
 99e:	6a42                	ld	s4,16(sp)
 9a0:	6aa2                	ld	s5,8(sp)
 9a2:	6b02                	ld	s6,0(sp)
 9a4:	6121                	addi	sp,sp,64
 9a6:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9a8:	6398                	ld	a4,0(a5)
 9aa:	e118                	sd	a4,0(a0)
 9ac:	bff1                	j	988 <malloc+0x86>
  hp->s.size = nu;
 9ae:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 9b2:	0541                	addi	a0,a0,16
 9b4:	00000097          	auipc	ra,0x0
 9b8:	ec6080e7          	jalr	-314(ra) # 87a <free>
  return freep;
 9bc:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 9c0:	d971                	beqz	a0,994 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9c2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9c4:	4798                	lw	a4,8(a5)
 9c6:	fa9776e3          	bgeu	a4,s1,972 <malloc+0x70>
    if(p == freep)
 9ca:	00093703          	ld	a4,0(s2)
 9ce:	853e                	mv	a0,a5
 9d0:	fef719e3          	bne	a4,a5,9c2 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 9d4:	8552                	mv	a0,s4
 9d6:	00000097          	auipc	ra,0x0
 9da:	b7e080e7          	jalr	-1154(ra) # 554 <sbrk>
  if(p == (char*)-1)
 9de:	fd5518e3          	bne	a0,s5,9ae <malloc+0xac>
        return 0;
 9e2:	4501                	li	a0,0
 9e4:	bf45                	j	994 <malloc+0x92>
