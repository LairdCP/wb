#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
  unsigned char addr[6];
  char dummy;
  int mac;
  char *input;

  if (argc > 2) {
    fprintf(stderr, "Wrong number of arguments\nUsage: %s ADDRESS\n",
            argv[0]);
    exit(1);
  } else if (argc==2) {
    input = argv[1];
  } else {
    input = argv[0];
  }

  int res = sscanf(input, "%2hhx:%2hhx:%2hhx:%2hhx:%2hhx:%2hhx%c",
                   &addr[0], &addr[1], &addr[2], &addr[3], &addr[4], &addr[5],
                   &dummy);

  if (res == EOF) {
    fprintf(stderr, "Reached end of input without finding mac in aa:bb:cc:xx:yy:zz format\n");
    exit(1);
  } else if (res < 6) {
    fprintf(stderr, "Got fewer hex digits than expected\n");
    exit(1);
  } else if (res > 6) {
    fprintf(stderr, "Got extra characters after input\n");
    exit(1);
  }

  mac = addr[5]+(addr[4] << 8 )+(addr[3]<<16);
  mac++;
  addr[3] = (0xff0000 & mac) >> 16;
  addr[4] = (0xff00 & mac) >> 8;
  addr[5] = (0xff & mac);

  printf("%02hhx:%02hhx:%02hhx:%02hhx:%02hhx:%02hhx\n",
         addr[0], addr[1], addr[2], addr[3], addr[4], addr[5]);

  return 0;
}
