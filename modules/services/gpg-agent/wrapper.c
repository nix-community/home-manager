// Simple wrapper to activate launchd sockets
// and set them up in the same way systemd would
// so that we can use gpg-agent in --supervised mode

#include <errno.h>
#include <err.h>
#include <unistd.h>
#include <launch.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>

int get_launchd_socket(const char *sockName)
{
  // Get our sockets from launchd
  int *fds = NULL;
  size_t count = 0;
  errno = launch_activate_socket(sockName, &fds, &count);

  if (errno != 0 || fds == NULL || count < 1)
  {
    warn("Error getting socket FD from launchd");
    return 0;
  }

  if (count != 1)
  {
    warnx("Expected one FD from launchd, got %zu. Only using first socket.", count);
  }

  // Unset FD_CLOEXEC bit
  fcntl(fds[0], F_SETFD, fcntl(fds[0], F_GETFD, 0) & ~FD_CLOEXEC);

  if (fds)
  {
    free(fds);
  }

  return 1;
}

int main(int argc, char **argv)
{
  // List of sockets we're going to check for
  const char *sockets[] = {
      "ssh",
      "browser",
      "extra",
      "std"};
  int fds = 0;
  char *fdsString = NULL;
  char *fdNames = NULL;
  char *tmpfdNames = NULL;

  // Activate the sockets and count and store names
  for (int i = 0; i < sizeof(sockets) / sizeof(sockets[0]); i++)
  {
    if (get_launchd_socket(sockets[i]))
    {
      fds++;
      asprintf(&fdNames, (tmpfdNames == NULL ? "%s%s" : "%s:%s"), (tmpfdNames == NULL ? "" : tmpfdNames), sockets[i]);
      if (tmpfdNames)
      {
        free(tmpfdNames);
      }
      tmpfdNames = fdNames;
    }
  }

  // Set the ENV var for our PID
  char *pidString = NULL;
  asprintf(&pidString, "%ld", (long)getpid());
  setenv("LISTEN_PID", pidString, 0);
  free(pidString);

  // Set the number of FDs we've opened
  asprintf(&fdsString, "%d", fds);
  setenv("LISTEN_FDS", fdsString, 0);
  free(fdsString);

  // And their names
  setenv("LISTEN_FDNAMES", (fdNames == NULL ? "" : fdNames), 0);
  free(fdNames);

  // Launch the command we were passed
  ++argv;
  if (*argv)
  {
    execvp(*argv, argv);
    err(1, "Error executing command");
  }
  else
  {
    errx(1, "No command specified");
  }
}

