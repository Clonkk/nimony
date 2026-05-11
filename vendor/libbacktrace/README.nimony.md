# Vendored libbacktrace

Source: <https://github.com/ianlancetaylor/libbacktrace>
License: 3-clause BSD (see `LICENSE`).

## Layout

- `include/` — public + internal headers, copied verbatim from upstream
  (`backtrace.h`, `backtrace-supported.h`, `internal.h`, `filenames.h`).
- `src/` — the subset of `.c` files needed for Linux/macOS:
  `atomic, backtrace, dwarf, fileline, mmap, mmapio, posix, print, simple, sort, state, elf, macho`.
  We do **not** vendor `pecoff.c`, `xcoff.c`, `read.c`, `alloc.c`, the test
  programs (`btest.c`, `ttest.c`, `ztest.c`, etc.), or the optional compression
  backends. The `print.c` and `simple.c` files are present for completeness but
  `lib/std/stacktraces.nim` calls `backtrace_full` only.
- `config/config.h` — a thin shim that selects `config.linux.h` or
  `config.osx.h` based on the `BACKTRACE_CONFIG_*` define set by
  `lib/std/stacktraces.nim`.

## Refreshing `config.h`

Both `config/config.osx.h` and `config/config.linux.h` are
hand-curated snapshots of the autoconf-generated `config.h`. To refresh:

```sh
git clone --depth=1 https://github.com/ianlancetaylor/libbacktrace.git /tmp/libbacktrace
cd /tmp/libbacktrace
./configure
cp config.h /path/to/nimony/vendor/libbacktrace/config/config.<os>.h
```

Then edit the copy:
- Drop `HAVE_ZLIB`, `HAVE_LIBLZMA`, `HAVE_ZSTD` (they only gate test programs
  but configure may pick them up if those libs happen to be installed).
- Add the file header comment.

The `config.linux.h` checked in here was authored from the configure output
pattern (`HAVE_DL_ITERATE_PHDR`, `HAVE_LINK_H`, `BACKTRACE_ELF_SIZE 64`) rather
than freshly generated on a Linux host. **Verify on first Linux build** and
refresh from a real `./configure` run if anything is off.

## `backtrace-supported.h`

This is checked in pre-generated. The defines (`BACKTRACE_SUPPORTED 1`,
`BACKTRACE_USES_MALLOC 0`, `BACKTRACE_SUPPORTS_THREADS 1`,
`BACKTRACE_SUPPORTS_DATA 1`) hold for Linux + macOS as long as we build with
`mmap.c` + `mmapio.c` (which we do). If we ever swap in `alloc.c` + `read.c`,
flip `BACKTRACE_USES_MALLOC` to `1` here.
