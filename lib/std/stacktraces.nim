## Stack traces with C++ and NIFC name demangling.
##
## On Linux the system-installed `libbacktrace` (link with `-lbacktrace`,
## package `libbacktrace-dev` / `libbacktrace-devel`) provides file/line info.
## On macOS we use `<execinfo.h>` + `dladdr` from libSystem — symbol names
## only, no file/line — because Apple does not package libbacktrace.

{.feature: "lenientnils".}

import std / [syncio, strutils]

# ---- C++ demangling --------------------------------------------------------

proc cxaDemangle(mangled: cstring; output: pointer; length: ptr csize_t;
                 status: ptr cint): cstring
  {.importc: "__cxa_demangle", cdecl.}

# Demangler output is allocated with `malloc`; we have to free it with the C
# allocator, not Nimony's. mimalloc may not own this pointer.
proc c_free(p: pointer) {.importc: "free", header: "<stdlib.h>".}

when defined(macosx):
  {.passL: "-lc++".}
elif defined(linux):
  {.passL: "-lstdc++".}

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
#
# Design
# ------
# Nimony's NIFC backend (src/nifc/mangler.nim) maps every non-C-identifier
# character to an escape sequence so that an arbitrary symbol like
# `foo.3.bar` or `[]=` survives as a valid C identifier. Two properties of
# that scheme make the inverse cheap and unambiguous:
#
#   1. `Q` is the universal terminator. The mangler doubles real `Q` to `QQ`,
#      and every multi-char escape (`getQ`, `putQ`, `eqQ`, `dollarQ`, …) ends
#      in `Q`. So when we see a `Q` mid-token we are always at the end of an
#      escape, never in the middle of payload.
#
#   2. The mangler never emits a bare `_`: literal `_` becomes `Q_`, literal
#      `.` becomes `_`. So in unmangled output a lone `_` always reverses to
#      `.` (the NIF qualifier separator between basename, version, and
#      module suffix).
#
# The unmangler walks left-to-right:
#
#   * `QQ` → `Q`, `Q_` → `_`            (handled in the 'Q' arm of the case).
#   * `XHHQ` → byte with hex value HH    (handled in the 'X' arm).
#   * Bare `_` → `.`                     (handled in the '_' arm).
#   * Lowercase letter: might start a multi-char escape. We scan forward up to
#     `MaxEscapeLen` chars looking for a `Q`, look up the substring in the
#     `NifcEscapes` table, and emit the replacement on match. On miss, the
#     letter is part of an ordinary identifier and we emit it verbatim.
#   * Anything else: passes through unchanged.
#
# `NifcEscapes` is kept as a flat const array (not a hash table) because there
# are only 23 entries; a linear probe filtered by length is well under a
# microsecond per symbol and avoids depending on `std/tables` from a low-level
# diagnostic module.

# Token → replacement table for mangleToC's multi-char escapes. All tokens end
# in 'Q' and `Q` itself only appears as the terminator (real `Q` is doubled to
# `QQ` and handled separately), so to recognise an escape we scan forward to
# the next `Q` and look up the substring.
const NifcEscapes: array[23, (string, string)] = [
  ("getQ",     "[]"),
  ("putQ",     "[]="),
  ("eqQ",      "=="),
  ("eQ",       "="),
  ("leQ",      "<="),
  ("ltQ",      "<"),
  ("geQ",      ">="),
  ("gtQ",      ">"),
  ("dollarQ",  "$"),
  ("percentQ", "%"),
  ("ampQ",     "&"),
  ("roofQ",    "^"),
  ("emarkQ",   "!"),
  ("qmarkQ",   "?"),
  ("starQ",    "*"),
  ("plusQ",    "+"),
  ("minusQ",   "-"),
  ("slashQ",   "/"),
  ("bslashQ",  "\\"),
  ("tildeQ",   "~"),
  ("colonQ",   ":"),
  ("atQ",      "@"),
  ("barQ",     "|"),
]

const MaxEscapeLen = 8  # length of "percentQ"

proc hexVal(c: char): int {.inline.} =
  case c
  of '0'..'9': int(c) - int('0')
  of 'A'..'F': int(c) - int('A') + 10
  of 'a'..'f': int(c) - int('a') + 10
  else: -1

proc lookupEscape(name: cstring; start, qPos: int): int =
  ## If name[start..qPos] matches one of NifcEscapes, append the replacement
  ## via the caller and return the matched length. Returns 0 if no match.
  ## (Caller does the append; we return the index into NifcEscapes via a sign
  ## trick — but easier: just have lookupEscape return the index, -1 on miss.)
  let tokenLen = qPos - start + 1
  for (tok, _) in NifcEscapes:
    if tok.len != tokenLen: continue
    var k = 0
    while k < tokenLen:
      if name[start + k] != tok[k]: break
      inc k
    if k == tokenLen: return tokenLen
  return 0

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
      # `QQ` → `Q`, `Q_` → `_`. A lone `Q` shouldn't occur in valid input;
      # pass it through to be charitable.
      if i + 1 < n and name[i+1] == 'Q':
        result.add 'Q'; inc i, 2
      elif i + 1 < n and name[i+1] == '_':
        result.add '_'; inc i, 2
      else:
        result.add 'Q'; inc i
    of 'X':
      # `XHHQ` → byte with hex value HH.
      if i + 3 < n:
        let hi = hexVal(name[i+1])
        let lo = hexVal(name[i+2])
        if hi >= 0 and lo >= 0 and name[i+3] == 'Q':
          result.add char((hi shl 4) or lo)
          inc i, 4
          continue
      result.add 'X'; inc i
    of '_':
      # mangler never emits bare `_`; `.` becomes `_` and `_` becomes `Q_`.
      result.add '.'; inc i
    of 'a'..'z':
      # Possible multi-char escape ending in 'Q'. Scan forward up to
      # MaxEscapeLen chars looking for the terminator.
      let limit = min(n, i + MaxEscapeLen)
      var q = -1
      var k = i + 1
      while k < limit:
        if name[k] == 'Q':
          q = k
          break
        inc k
      if q >= 0:
        var matchIdx = -1
        let tokLen = q - i + 1
        for idx in 0 ..< NifcEscapes.len:
          if NifcEscapes[idx][0].len != tokLen: continue
          var p = 0
          while p < tokLen:
            if name[i + p] != NifcEscapes[idx][0][p]: break
            inc p
          if p == tokLen:
            matchIdx = idx
            break
        if matchIdx >= 0:
          result.add NifcEscapes[matchIdx][1]
          i = q + 1
          continue
      result.add c
      inc i
    else:
      result.add c
      inc i

proc splitNifcSym(s: string; base, modSuffix: var string) =
  ## Mirrors splitSymName in src/lib/symparser: scan from the right for the
  ## last `.<digit>` (version) and the last `.<non-digit>` (module suffix).
  base = ""
  modSuffix = ""
  if s.len == 0: return
  var i = s.len - 2
  var modStart = -1
  var versionDot = -1
  while i > 0:
    if s[i] == '.':
      let nxt = s[i+1]
      if nxt in {'0'..'9'}:
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

# ---- Linux: libbacktrace --------------------------------------------------

when defined(linux):
  {.passL: "-lbacktrace".}

  type
    BacktraceState {.importc: "struct backtrace_state", header: "backtrace.h".} = object
    BacktraceErrorCb = proc (data: pointer; msg: cstring; errnum: cint) {.cdecl.}
    BacktraceFullCb  = proc (data: pointer; pc: uint; filename: cstring;
                             lineno: cint; function: cstring): cint {.cdecl.}

  proc backtrace_create_state(filename: cstring; threaded: cint;
                              errorCb: BacktraceErrorCb;
                              data: pointer): ptr BacktraceState
    {.importc: "backtrace_create_state", header: "backtrace.h", cdecl.}

  proc backtrace_full(state: ptr BacktraceState; skip: cint;
                      cb: BacktraceFullCb; errorCb: BacktraceErrorCb;
                      data: pointer): cint
    {.importc: "backtrace_full", header: "backtrace.h", cdecl.}

  var btState: ptr BacktraceState = nil

  proc btErrorIgnore(data: pointer; msg: cstring; errnum: cint) {.cdecl.} =
    discard

  proc ensureState(): ptr BacktraceState =
    if btState == nil:
      btState = backtrace_create_state(nil, 1.cint, btErrorIgnore, nil)
    result = btState

# ---- macOS / fallback: execinfo + dladdr ----------------------------------

when defined(macosx) or defined(linux):
  proc execinfo_backtrace(buf: ptr UncheckedArray[pointer]; size: cint): cint
    {.importc: "backtrace", header: "<execinfo.h>", cdecl.}

  type DlInfo {.importc: "Dl_info", header: "<dlfcn.h>", bycopy.} = object
    dli_fname {.importc: "dli_fname".}: cstring
    dli_fbase {.importc: "dli_fbase".}: pointer
    dli_sname {.importc: "dli_sname".}: cstring
    dli_saddr {.importc: "dli_saddr".}: pointer

  proc c_dladdr(p: pointer; info: ptr DlInfo): cint
    {.importc: "dladdr", header: "<dlfcn.h>", cdecl.}

# ---- frame formatting & emission ------------------------------------------

proc appendFrame(buf: var string; filename: cstring; lineno: cint;
                 function: cstring) =
  if filename == nil:
    buf.add "<unknown>"
  else:
    buf.add fromCString(filename)
  buf.add '('
  buf.add $lineno
  buf.add ") "
  buf.add resolveName(function)
  buf.add '\n'

# Linux fileFrameCb / stringFrameCb ----------

when defined(linux):
  type FileSink = object
    f: File
    frames: int

  proc fileFrameCb(data: pointer; pc: uint; filename: cstring;
                   lineno: cint; function: cstring): cint {.cdecl.} =
    let sink = cast[ptr FileSink](data)
    var line = newStringOfCap(64)
    appendFrame(line, filename, lineno, function)
    write sink.f, line
    inc sink.frames
    result = 0

  type StringSink = object
    buf: string
    frames: int

  proc stringFrameCb(data: pointer; pc: uint; filename: cstring;
                     lineno: cint; function: cstring): cint {.cdecl.} =
    let sink = cast[ptr StringSink](data)
    appendFrame(sink.buf, filename, lineno, function)
    inc sink.frames
    result = 0

# dladdr fallback used by both macOS and the Linux no-debug-info path -------

when defined(macosx) or defined(linux):
  proc collectViaDladdr(skip: int; buf: var string) =
    const MaxFrames = 64
    var pcs {.noinit.}: array[MaxFrames, pointer]
    let n = execinfo_backtrace(cast[ptr UncheckedArray[pointer]](addr pcs),
                               cint(MaxFrames))
    if n <= 0: return
    var i = skip
    while i < n:
      var info {.noinit.}: DlInfo
      zeroMem(addr info, sizeof(DlInfo))
      if c_dladdr(pcs[i], addr info) != 0 and info.dli_sname != nil:
        appendFrame(buf, nil, 0.cint, info.dli_sname)
      else:
        buf.add "<unknown>(0) ??\n"
      inc i

# ---- public API ------------------------------------------------------------

const SkipFrames = 2.cint
  ## skip libbacktrace's internals + the writeStackTrace/getStackTrace frame.

proc writeStackTrace*(f: File) =
  ## Writes the current stack trace to `f`. On Linux uses libbacktrace; falls
  ## back to dladdr for frames that libbacktrace can't resolve. On macOS uses
  ## dladdr only (symbol names, no file/line).
  when defined(linux):
    let st = ensureState()
    var sink = FileSink(f: f, frames: 0)
    if st != nil:
      discard backtrace_full(st, SkipFrames, fileFrameCb, nil, addr sink)
    if sink.frames == 0:
      var buf = ""
      collectViaDladdr(int(SkipFrames), buf)
      write f, buf
  elif defined(macosx):
    var buf = ""
    collectViaDladdr(int(SkipFrames), buf)
    write f, buf
  else:
    {.error: "std/stacktraces is only supported on Linux and macOS".}

proc writeStackTrace*() =
  ## Writes the current stack trace to standard error.
  writeStackTrace(stderr)

proc getStackTrace*(): string =
  ## Returns the current stack trace as a string.
  when defined(linux):
    let st = ensureState()
    var sink = StringSink(buf: "", frames: 0)
    if st != nil:
      discard backtrace_full(st, SkipFrames, stringFrameCb, nil, addr sink)
    if sink.frames == 0:
      collectViaDladdr(int(SkipFrames), sink.buf)
    result = sink.buf
  elif defined(macosx):
    result = ""
    collectViaDladdr(int(SkipFrames), result)
  else:
    {.error: "std/stacktraces is only supported on Linux and macOS".}
