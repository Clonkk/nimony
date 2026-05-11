## Stack traces backed by libbacktrace, with C++ and NIFC name demangling.

{.feature: "lenientnils".}

import std / syncio

# ---- libbacktrace integration ----------------------------------------------

# Nimony emits `char` as `unsigned char`; libbacktrace uses `const char *`. The
# resulting function-pointer mismatches are ABI-compatible on every platform we
# care about, so silence the corresponding warning that recent clang/gcc
# escalate to an error.
{.passC: "-Wno-incompatible-function-pointer-types".}
{.passC: "-Wno-incompatible-pointer-types".}
# DWARF debug info is required for libbacktrace to resolve file/line/function.
{.passC: "-g".}

when defined(macosx):
  {.passL: "-lc++".}
  {.build("C", "${path}/../../vendor/libbacktrace/src/atomic.c",   "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_OSX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/backtrace.c","-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_OSX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/dwarf.c",    "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_OSX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/fileline.c", "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_OSX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/mmap.c",     "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_OSX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/mmapio.c",   "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_OSX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/posix.c",    "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_OSX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/print.c",    "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_OSX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/simple.c",   "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_OSX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/sort.c",     "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_OSX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/state.c",    "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_OSX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/macho.c",    "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_OSX").}
elif defined(linux):
  {.passL: "-lstdc++".}
  {.build("C", "${path}/../../vendor/libbacktrace/src/atomic.c",   "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_LINUX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/backtrace.c","-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_LINUX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/dwarf.c",    "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_LINUX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/fileline.c", "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_LINUX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/mmap.c",     "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_LINUX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/mmapio.c",   "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_LINUX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/posix.c",    "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_LINUX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/print.c",    "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_LINUX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/simple.c",   "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_LINUX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/sort.c",     "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_LINUX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/state.c",    "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_LINUX").}
  {.build("C", "${path}/../../vendor/libbacktrace/src/elf.c",      "-I${path}/../../vendor/libbacktrace/include -I${path}/../../vendor/libbacktrace/config -DBACKTRACE_CONFIG_LINUX").}
else:
  {.error: "std/stacktraces is only supported on Linux and macOS".}

type
  BacktraceState {.importc: "struct backtrace_state",
                   header: "${path}/../../vendor/libbacktrace/include/backtrace.h".} = object

  BacktraceErrorCb = proc (data: pointer; msg: cstring; errnum: cint) {.cdecl.}
  BacktraceFullCb  = proc (data: pointer; pc: uint; filename: cstring;
                           lineno: cint; function: cstring): cint {.cdecl.}

proc backtrace_create_state(filename: cstring; threaded: cint;
                            errorCb: BacktraceErrorCb;
                            data: pointer): ptr BacktraceState
  {.importc: "backtrace_create_state",
    header: "${path}/../../vendor/libbacktrace/include/backtrace.h", cdecl.}

proc backtrace_full(state: ptr BacktraceState; skip: cint;
                    cb: BacktraceFullCb; errorCb: BacktraceErrorCb;
                    data: pointer): cint
  {.importc: "backtrace_full",
    header: "${path}/../../vendor/libbacktrace/include/backtrace.h", cdecl.}

# ---- C bindings used internally --------------------------------------------

proc c_fwrite(buf: pointer; size, n: uint; f: File): uint
  {.importc: "fwrite", header: "<stdio.h>".}

proc c_snprintf(buf: cstring; n: csize_t; frmt: cstring): cint
  {.header: "<stdio.h>", importc: "snprintf", varargs.}

proc c_free(p: pointer) {.importc: "free", header: "<stdlib.h>".}

proc cxaDemangle(mangled: cstring; output: pointer; length: ptr csize_t;
                 status: ptr cint): cstring
  {.importc: "__cxa_demangle", cdecl.}

# execinfo fallback — used when libbacktrace can't find debug info (typical on
# macOS without a .dSYM bundle). Gives symbol names only, no file/line.
proc execinfo_backtrace(buf: ptr UncheckedArray[pointer]; size: cint): cint
  {.importc: "backtrace", header: "<execinfo.h>", cdecl.}
proc execinfo_backtrace_symbols(buf: ptr UncheckedArray[pointer];
                                size: cint): ptr UncheckedArray[cstring]
  {.importc: "backtrace_symbols", header: "<execinfo.h>", cdecl.}

# ---- C++ demangling --------------------------------------------------------

proc tryCxxDemangle(name: cstring): string =
  if name == nil: return ""
  if name.len < 2 or name[0] != '_': return ""
  if name[1] != 'Z' and not (name.len >= 3 and name[1] == '_' and name[2] == 'Z'):
    return ""
  var status: cint = 0
  let raw = cxaDemangle(name, nil, nil, addr status)
  if status == 0 and raw != nil:
    result = fromCString(raw)
    c_free(cast[pointer](raw))
  else:
    result = ""

# ---- NIFC name unmangling --------------------------------------------------

proc hexVal(c: char): int {.inline.} =
  case c
  of '0'..'9': int(c) - int('0')
  of 'A'..'F': int(c) - int('A') + 10
  of 'a'..'f': int(c) - int('a') + 10
  else: -1

proc tryToken(s: cstring; sLen, i: int; tok: string; replace: string;
              dst: var string): int =
  if i + tok.len > sLen: return 0
  var k = 0
  while k < tok.len:
    if s[i + k] != tok[k]: return 0
    inc k
  dst.add replace
  result = tok.len

proc nifcUnmangle*(name: cstring): string =
  ## Inverse of mangleToC in src/nifc/mangler.nim. Exposed so that
  ## stacktrace-like tools can demangle Nimony-emitted C symbols externally.
  if name == nil: return ""
  let n = name.len
  result = newStringOfCap(n)
  var i = 0
  while i < n:
    let c = name[i]
    case c
    of 'Q':
      if i + 1 < n and name[i+1] == 'Q':
        result.add 'Q'
        inc i, 2
      elif i + 1 < n and name[i+1] == '_':
        result.add '_'
        inc i, 2
      else:
        result.add 'Q'
        inc i
    of 'X':
      if i + 3 < n:
        let hi = hexVal(name[i+1])
        let lo = hexVal(name[i+2])
        if hi >= 0 and lo >= 0 and name[i+3] == 'Q':
          result.add char((hi shl 4) or lo)
          inc i, 4
          continue
      result.add 'X'
      inc i
    of '_':
      result.add '.'
      inc i
    of 'g':
      let m1 = tryToken(name, n, i, "getQ", "[]", result)
      if m1 > 0: inc i, m1
      else:
        let m2 = tryToken(name, n, i, "geQ", ">=", result)
        if m2 > 0: inc i, m2
        else:
          let m3 = tryToken(name, n, i, "gtQ", ">", result)
          if m3 > 0: inc i, m3
          else:
            result.add c
            inc i
    of 'p':
      let m1 = tryToken(name, n, i, "putQ", "[]=", result)
      if m1 > 0: inc i, m1
      else:
        let m2 = tryToken(name, n, i, "percentQ", "%", result)
        if m2 > 0: inc i, m2
        else:
          let m3 = tryToken(name, n, i, "plusQ", "+", result)
          if m3 > 0: inc i, m3
          else:
            result.add c
            inc i
    of 'e':
      let m1 = tryToken(name, n, i, "eqQ", "==", result)
      if m1 > 0: inc i, m1
      else:
        let m2 = tryToken(name, n, i, "emarkQ", "!", result)
        if m2 > 0: inc i, m2
        else:
          let m3 = tryToken(name, n, i, "eQ", "=", result)
          if m3 > 0: inc i, m3
          else:
            result.add c
            inc i
    of 'l':
      let m1 = tryToken(name, n, i, "leQ", "<=", result)
      if m1 > 0: inc i, m1
      else:
        let m2 = tryToken(name, n, i, "ltQ", "<", result)
        if m2 > 0: inc i, m2
        else:
          result.add c
          inc i
    of 'd':
      let m = tryToken(name, n, i, "dollarQ", "$", result)
      if m > 0: inc i, m
      else:
        result.add c
        inc i
    of 'a':
      let m1 = tryToken(name, n, i, "ampQ", "&", result)
      if m1 > 0: inc i, m1
      else:
        let m2 = tryToken(name, n, i, "atQ", "@", result)
        if m2 > 0: inc i, m2
        else:
          result.add c
          inc i
    of 'r':
      let m = tryToken(name, n, i, "roofQ", "^", result)
      if m > 0: inc i, m
      else:
        result.add c
        inc i
    of 'q':
      let m = tryToken(name, n, i, "qmarkQ", "?", result)
      if m > 0: inc i, m
      else:
        result.add c
        inc i
    of 's':
      let m1 = tryToken(name, n, i, "starQ", "*", result)
      if m1 > 0: inc i, m1
      else:
        let m2 = tryToken(name, n, i, "slashQ", "/", result)
        if m2 > 0: inc i, m2
        else:
          result.add c
          inc i
    of 'm':
      let m = tryToken(name, n, i, "minusQ", "-", result)
      if m > 0: inc i, m
      else:
        result.add c
        inc i
    of 'b':
      let m1 = tryToken(name, n, i, "bslashQ", "\\", result)
      if m1 > 0: inc i, m1
      else:
        let m2 = tryToken(name, n, i, "barQ", "|", result)
        if m2 > 0: inc i, m2
        else:
          result.add c
          inc i
    of 't':
      let m = tryToken(name, n, i, "tildeQ", "~", result)
      if m > 0: inc i, m
      else:
        result.add c
        inc i
    of 'c':
      let m = tryToken(name, n, i, "colonQ", ":", result)
      if m > 0: inc i, m
      else:
        result.add c
        inc i
    else:
      result.add c
      inc i

proc splitNifcSym(s: string; base, modSuffix: var string) =
  ## Mirrors splitSymName in src/lib/symparser: the trailing component after
  ## the last '.<non-digit>' boundary is the module suffix; the part before
  ## the final '.<digit>+' suffix is the basename.
  base = ""
  modSuffix = ""
  if s.len == 0: return
  var i = s.len - 2
  var modStart = -1
  var versionDot = -1
  while i > 0:
    if s[i] == '.':
      let nxt = s[i+1]
      if nxt >= '0' and nxt <= '9':
        versionDot = i
        break
      else:
        modStart = i
    dec i
  if versionDot >= 0:
    base = substr(s, 0, versionDot-1)
    if modStart > versionDot:
      modSuffix = substr(s, modStart+1)
  elif modStart >= 0:
    base = substr(s, 0, modStart-1)
    modSuffix = substr(s, modStart+1)
  else:
    base = s

# ---- per-frame name resolution --------------------------------------------

proc resolveName(function: cstring): string =
  if function == nil:
    return "??"
  let cxx = tryCxxDemangle(function)
  if cxx.len > 0:
    return cxx
  let unmangled = nifcUnmangle(function)
  var base = ""
  var modSuffix = ""
  splitNifcSym(unmangled, base, modSuffix)
  if base.len == 0:
    return unmangled
  if modSuffix.len > 0:
    result = base
    result.add " ["
    result.add modSuffix
    result.add "]"
  else:
    result = base

# ---- frame formatting ------------------------------------------------------

proc formatFrame(filename: cstring; lineno: cint; function: cstring): string =
  let fn = resolveName(function)
  let file =
    if filename == nil: "<unknown>"
    else: fromCString(filename)
  result = file
  result.add "("
  var lbuf {.noinit.}: array[0..31, char]
  discard c_snprintf(cast[cstring](addr lbuf), csize_t(32), cstring"%d", lineno)
  result.add fromCString(cast[cstring](addr lbuf))
  result.add ") "
  result.add fn
  result.add "\n"

# ---- libbacktrace state singleton -----------------------------------------

var btState: ptr BacktraceState = nil

proc btErrorIgnore(data: pointer; msg: cstring; errnum: cint) {.cdecl.} =
  discard

proc ensureState(): ptr BacktraceState =
  if btState == nil:
    btState = backtrace_create_state(nil, 1.cint, btErrorIgnore, nil)
  result = btState

# ---- File sink -------------------------------------------------------------

type FileSink = object
  f: File
  frames: int
  errored: bool

proc fileFrameCb(data: pointer; pc: uint; filename: cstring;
                 lineno: cint; function: cstring): cint {.cdecl.} =
  let sink = cast[ptr FileSink](data)
  let line = formatFrame(filename, lineno, function)
  discard c_fwrite(readRawData(line), 1'u, line.len.uint, sink.f)
  inc sink.frames
  result = 0

proc fileErrorCb(data: pointer; msg: cstring; errnum: cint) {.cdecl.} =
  let sink = cast[ptr FileSink](data)
  sink.errored = true

# ---- string sink -----------------------------------------------------------

type StringSink = object
  buf: string
  frames: int
  errored: bool

proc stringFrameCb(data: pointer; pc: uint; filename: cstring;
                   lineno: cint; function: cstring): cint {.cdecl.} =
  let sink = cast[ptr StringSink](data)
  sink.buf.add formatFrame(filename, lineno, function)
  inc sink.frames
  result = 0

proc stringErrorCb(data: pointer; msg: cstring; errnum: cint) {.cdecl.} =
  let sink = cast[ptr StringSink](data)
  sink.errored = true

# ---- execinfo fallback parser ---------------------------------------------

proc extractSymbol(line: cstring): string =
  ## backtrace_symbols formats vary by platform. macOS:
  ##   "  0   tstacktrace  0x10001b5cc symname + 12"
  ## Linux glibc:
  ##   "./tstacktrace(symname+0x12) [0x55a...]"
  ## Extract the symbol token and return it; empty string if not found.
  if line == nil: return ""
  let n = line.len
  when defined(macosx):
    # find " 0x", skip past hex address, then take the next whitespace-delimited word
    var i = 0
    while i + 2 < n:
      if line[i] == ' ' and line[i+1] == '0' and line[i+2] == 'x':
        inc i, 3
        while i < n and line[i] != ' ': inc i  # skip the hex digits
        while i < n and line[i] == ' ': inc i  # skip spaces
        var j = i
        while j < n and line[j] != ' ': inc j
        return substr(fromCString(line), i, j-1)
      inc i
    return ""
  elif defined(linux):
    # find '(' ... '+'
    var i = 0
    while i < n and line[i] != '(': inc i
    if i >= n: return ""
    let start = i + 1
    var j = start
    while j < n and line[j] != '+' and line[j] != ')': inc j
    if j == start: return ""
    return substr(fromCString(line), start, j-1)
  else:
    return ""

proc formatFallbackFrame(rawLine: cstring): string =
  let symRaw = extractSymbol(rawLine)
  if symRaw.len == 0:
    result = fromCString(rawLine)
    result.add "\n"
    return
  var sym = symRaw
  let cxx = tryCxxDemangle(toCString(sym))
  var resolved: string
  if cxx.len > 0:
    resolved = cxx
  else:
    let un = nifcUnmangle(toCString(sym))
    var base = ""
    var modSuffix = ""
    splitNifcSym(un, base, modSuffix)
    if base.len == 0:
      resolved = un
    elif modSuffix.len > 0:
      resolved = base
      resolved.add " ["
      resolved.add modSuffix
      resolved.add "]"
    else:
      resolved = base
  result = "<unknown>(0) "
  result.add resolved
  result.add "\n"

proc execinfoCollect(skip: cint; sink: pointer;
                     emit: proc (sink: pointer; line: string) {.nimcall.}) =
  const MaxFrames = 64
  var pcs {.noinit.}: array[MaxFrames, pointer]
  let n = execinfo_backtrace(cast[ptr UncheckedArray[pointer]](addr pcs),
                             cint(MaxFrames))
  if n <= 0: return
  let syms = execinfo_backtrace_symbols(
    cast[ptr UncheckedArray[pointer]](addr pcs), n)
  if syms == nil: return
  var i = int(skip)
  while i < n:
    let line = formatFallbackFrame(syms[i])
    emit(sink, line)
    inc i
  c_free(cast[pointer](syms))

proc emitToFile(sink: pointer; line: string) {.nimcall.} =
  let s = cast[ptr FileSink](sink)
  discard c_fwrite(readRawData(line), 1'u, line.len.uint, s.f)

proc emitToString(sink: pointer; line: string) {.nimcall.} =
  let s = cast[ptr StringSink](sink)
  s.buf.add line

# ---- public API ------------------------------------------------------------

const SkipFrames = 2.cint
  ## skip backtrace_full itself + the writeStackTrace/getStackTrace frame.

proc writeStackTrace*(f: File) =
  ## Writes the current stack trace to `f`. Uses libbacktrace; on macOS without
  ## a .dSYM bundle, falls back to execinfo (no file/line, but symbols only).
  let st = ensureState()
  var sink = FileSink(f: f, frames: 0, errored: false)
  if st != nil:
    discard backtrace_full(st, SkipFrames, fileFrameCb, fileErrorCb, addr sink)
  if sink.frames == 0:
    execinfoCollect(SkipFrames, addr sink, emitToFile)

proc writeStackTrace*() =
  ## Writes the current stack trace to standard error.
  writeStackTrace(stderr)

proc getStackTrace*(): string =
  ## Returns the current stack trace as a string. Uses libbacktrace; on macOS
  ## without a .dSYM bundle, falls back to execinfo (no file/line, but symbols
  ## only).
  let st = ensureState()
  var sink = StringSink(buf: "", frames: 0, errored: false)
  if st != nil:
    discard backtrace_full(st, SkipFrames, stringFrameCb, stringErrorCb,
                           addr sink)
  if sink.frames == 0:
    execinfoCollect(SkipFrames, addr sink, emitToString)
  result = sink.buf
