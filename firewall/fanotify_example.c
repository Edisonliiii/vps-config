#define _GNU_SOURCE     /* Needed to get O_LARGEFILE definition */
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/fanotify.h>
#include <unistd.h>

/*
struct fanotify_event_metadata {
  __u32 event_len;
  __u8 vers;
  __u8 reserved;
  __u16 metadata_len;
  __aligned_u64 mask;
  __s32 fd;
  __s32 pid;
};
*/

static void handle_events(int fd)
{
  const struct fanotify_event_metadata* metadata;
  struct fanofity_event_metadata buf[200];
  ssize_t len;
  char path[PATH_MAX];
  ssize_t path_len;
  char procfd_path[PATH_MAX];
  struct fanotify_response response;

  /* Loop while events can be read from fanotify fd */
  for (;;) {
    // read some events
    len = read(fd, buf, sizeof(buf));
    if (len == -1 && errno != EAGAIN) {
      perror("read");
      exit(EXIT_FAILURE);
    }
    // check if end of available data reached
    if (len <=0 ) break;
    // point to the first event in the buffer
    metadata = buf;
    // loop over all events in the buffer
    while(FAN_EVENT_OK(metadata, len)) {
      // check that run-time and compile-time struc match
      if (metadata->vers != FANOFIFY_METADATA_VERSION) {
        fprintf(stderr, "Mismatch of fanofify metadata version. \n");
        exit(EXIT_FAILURE);
      }

      if (metadata->fd >= 0) {
        //handle open permission event
        if (metadata->mask & FAN_OPEN_PERM) {
          printf("FAN_OPEN_PERM: ");
          // allow file to  be opened
          response.fd = metadata->fd;
          response.response = FAN_ALLOW;
          write(fd, &response, sizeof(response));
        }

        //handle closing of writable file event
        if (metadata->mask & FAN_CLOSE_WRITE) {
          
        }
      }
    }
  }
}

int main(int argc, char const *argv[])
{
  char buf;
  int fd, poll_num;
  nfds_t nfds;
  struct pollfd fds[2];

  /* check mount point is supplied */
  if (argc != 2) {
    fprintf(stderr, "Usage: %s MOUNT\n", argv[0]);
    exit(EXIT_FAILURE);
  }
  printf("Press enter key to terminate. \n");

  /* Create the fd for accessing the fanotify API */
  fd = fanotify_init(FAN_CLOEXEC | FAN_CLASS_CONTENT | FAN_NONBLOCK,
  	                 O_RDONLY | O_LARGEFILE);
  if (fd == -1) {
    perror("fanotify_init");
    exit(EXIT_FAILURE);
  }

  /* Mark the mount for:
     1. permission events b4 opening files
     2. notification events after closing a write-enabled fd
   */
  if (fanotify_mark(fd, FAN_MARK_ADD | FAN_MARK_MOUNT, 
  	                FAN_OPEN_PERM | FAN_CLOSE_WRITE, AT_FDCWD, argv[i]) == -1) {
    perror("fanotify_mark");
    exit(EXIT_FAILURE);
  }

  /* prepare for polling */
  nfds = 2;

  /* console input */
  fds[0].fd = STDIN_FILENO;
  fds[0].events = POLLIN;

  /* Fanotify input */
  fds[1].fd = fd;
  fds[1].events = POLLIN;

  /* This is the loop to wait for incoming events */
  printf("Listening for events. \n");

  while (1) {
    poll_num = poll(fds, nfds, -1);
    if (poll_num == -1) {
      if (errno == EINTR) continue;
      perror("poll");
      exit(EXIT_FAILURE);
    }

    if (poll_num > 0) {
      if (fds[0].revents & POLLIN) {
        while (read(STDIN_FILENO, &buf, 1) > 0 && buf != '\n') continue;
        break;
      }
      if (fds[1].revents & POLLIN) {
        handle_events(fd);
      }
    }
  }
  printf("Listening for events stopped. \n");
  exit(EXIT_SUCCESS);
}





















































