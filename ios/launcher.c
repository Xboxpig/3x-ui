#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT 6
#define JETSAM_LIMIT_MB 256

extern int memorystatus_control(uint32_t command, int32_t pid, uint32_t flags,
                                void *buffer, size_t buffersize);

static const char *select_target(const char *invocation) {
    const char *base = strrchr(invocation, '/');
    base = base == NULL ? invocation : base + 1;

    if (strstr(base, "xray") != NULL) {
        return "/var/jb/usr/local/x-ui/bin/xray-ios-arm64.real";
    }
    return "/var/jb/usr/local/x-ui/x-ui.real";
}

int main(int argc, char **argv) {
    (void)argc;

    if (memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT, getpid(),
                             JETSAM_LIMIT_MB, NULL, 0) != 0) {
        fprintf(stderr, "jetsam launcher: unable to set %d MB limit: %s\n",
                JETSAM_LIMIT_MB, strerror(errno));
        return 126;
    }

    const char *target = select_target(argv[0]);
    argv[0] = (char *)target;
    execv(target, argv);

    fprintf(stderr, "jetsam launcher: execv(%s) failed: %s\n", target,
            strerror(errno));
    return 127;
}
