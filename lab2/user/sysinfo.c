#include "../kernel/param.h"
#include "../kernel/types.h"
#include "../kernel/sysinfo.h"
#include "./user.h"

int
main(int argc, char *argv[])
{
    // 参数个数非法
    if (argc != 1)
    {
        //报错
        fprintf(2, "Usage: %s need not param\n", argv[0]);
        exit(1);
    }

    struct sysinfo info;
    sysinfo(&info);
    // 打印系统信息
    printf("free space: %d\nused process: %d\n", info.freemem, info.nproc);
    exit(0);
}
