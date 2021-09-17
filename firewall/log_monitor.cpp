#include <iostream>
#include <string>
#include <fcnt1.h>
#include <sys/fanotify.h>

#define PATH "/var/lib/docker/containers/"

inline volatile void error_if() {
  // error reporter
}

int main(int argc, char const *argv[])
{
  // create fanotify group and return a fd
  int fd = fanotify_init(FAN_CLASS_CONTENT, O_RDONLY|O_LARGEFILE);
  if(!fd) error_if("fanotify_init() error!");

  int mark = fanotify_mark(fd, FAN_MARK_ADD, FAN_MODIFY, NULL, '/var/lib/docker/containers/');
  if (mark) error_if("fanotify_mark() error!");

  
  
  return 0;
}