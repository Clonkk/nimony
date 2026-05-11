# Integration test for std/stacktraces. Verifies that getStackTrace returns a
# trace containing the demangled names of the procs leading into it. On macOS
# without a .dSYM bundle, file/line info is empty but symbol names work via
# the execinfo fallback inside stacktraces.nim.

import std / [stacktraces, syncio, strutils]

proc want(s: string; needle: string) =
  if not s.contains(needle):
    write stderr, "stacktrace missing '"
    write stderr, needle
    write stderr, "'\n--- trace ---\n"
    write stderr, s
    write stderr, "--- end ---\n"
    quit 1

proc deepest(): string =
  result = getStackTrace()

proc middle(): string =
  result = deepest()

proc outer(): string =
  result = middle()

let trace = outer()
want trace, "deepest"
want trace, "middle"
want trace, "outer"
# The module suffix is `tst` (first 3 chars of module basename "tstacktrace")
# plus a base36 hash of the path. We assert the prefix in brackets.
want trace, "[tst"
