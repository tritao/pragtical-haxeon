#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char **argv) {
  if (argc < 2) return 64;
  if (strcmp(argv[1], "inspect") == 0) {
    char cwd[4096];
    if (!getcwd(cwd, sizeof(cwd))) return 65;
    printf("cwd=%s\nenv=%s\narg=%s\n", cwd, getenv("PHX_TEST") ? getenv("PHX_TEST") : "", argc > 2 ? argv[2] : "");
    fprintf(stderr, "fixture-stderr\n");
    return 0;
  }
  if (strcmp(argv[1], "exit") == 0) return argc > 2 ? atoi(argv[2]) : 1;
  if (strcmp(argv[1], "flood") == 0) {
    int count = argc > 2 ? atoi(argv[2]) : 0;
    for (int index = 0; index < count; index++) putchar('x');
    return 0;
  }
  if (strcmp(argv[1], "copy") == 0) {
    char buffer[4096];
    size_t count;
    while ((count = fread(buffer, 1, sizeof(buffer), stdin)) > 0)
      if (fwrite(buffer, 1, count, stdout) != count) return 67;
    return ferror(stdin) ? 68 : 0;
  }
  if (strcmp(argv[1], "unicode-boundary") == 0) {
    for (int index = 0; index < 4095; index++) putchar('x');
    fputs("😀", stdout);
    return 0;
  }
  if (strcmp(argv[1], "diagnostic") == 0) {
    printf("%s:2:3: fixture error\n", argc > 2 ? argv[2] : "missing.c");
    return 0;
  }
  if (strcmp(argv[1], "sleep") == 0) {
    sleep(30);
    return 0;
  }
  return 66;
}
