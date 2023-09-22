#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <string.h>
#include <signal.h>
#include <sys/resource.h>

#define PIPE_PATH "/tmp/ramdisk/pipe"
#define PIPE_MAX_SIZE 268435456

/* Globals */
int pd, fd;
uint8_t * buffer;

void signal_handler() {
    printf("\nCtrl+C detected...\n");
    free(buffer);
    close(pd);
    close(fd);
    remove(PIPE_PATH);
    exit(1);
}

/* Increase the maximum number of bytes of memory that may be locked into RAM */
void increase_memlock_rlimit(void)
{
    struct rlimit rlim_new = {
        .rlim_cur	= RLIM_INFINITY,
        .rlim_max	= RLIM_INFINITY,
    };

    if (setrlimit(RLIMIT_MEMLOCK, &rlim_new)) {
        fprintf(stderr, "Failed to increase RLIMIT_MEMLOCK limit!\n");
        exit(1);
    }
}

int main(int argc, char const *argv[])
{
    int pipe_size = 0;
    int len;

    if(argc != 2) {
        printf("USAGE: %s <Output file>\n", argv[0]);
        return 1;
    }

    signal(SIGINT, signal_handler);

    increase_memlock_rlimit();

    buffer = malloc(PIPE_MAX_SIZE);
    if(buffer == NULL) {
        printf("Error allocating buffer memory\n");
        return 1;
    }

    /* Create pipe */
    umask(0666);
    if ((mkfifo(PIPE_PATH, 0666)) != 0) {
        printf("Unable to create the pipe (%d): %s\n", errno, strerror(errno));
        free(buffer);
        return 1;                   /* Print error message and return */
    }

    /* Open pipe */
    if((pd = open(PIPE_PATH, O_RDONLY)) < 0) {
        printf("Unable to open the pipe (%d): %s\n", errno, strerror(errno));
        free(buffer);
        remove(PIPE_PATH);
        return 1;
    }

    /* Adjust pipe parameters */
    if(fcntl(pd, F_SETPIPE_SZ, PIPE_MAX_SIZE) < 0)
        printf("Error setting pipe size (%d): %s\n", errno, strerror(errno));

    /* Open file */
    if((fd = open(argv[1], O_WRONLY | O_CREAT)) < 0) {
        printf("Unable to open output file (%d): %s\n", errno, strerror(errno));
        free(buffer);
        close(pd);
        remove(PIPE_PATH);
        return 1;
    }

    while(1) {
        /* Read from pipe */
        len = read(pd, buffer, PIPE_MAX_SIZE);
        /* Write to file */
        write(fd, buffer, len);
        //fsync(fd);
    }

    return 0;
}