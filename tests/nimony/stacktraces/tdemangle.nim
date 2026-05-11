import std / [stacktraces, syncio]

var failed = 0

proc check(actual, expected: string; tag: string) =
  if actual != expected:
    write stderr, "FAIL "
    write stderr, tag
    write stderr, ": expected '"
    write stderr, expected
    write stderr, "', got '"
    write stderr, actual
    write stderr, "'\n"
    inc failed

# Round-trip the canonical mangleToC examples from src/nifc/mangler.nim.
check nifcUnmangle(cstring"foo_3_baz"),       "foo.3.baz",     "foo.3.baz"
check nifcUnmangle(cstring"QQueryqmarkQ"),    "Query?",        "Query?"
check nifcUnmangle(cstring"abcQ_defQ_putQ"),  "abc_def_[]=",   "abc_def_[]="
check nifcUnmangle(cstring"getQ"),            "[]",            "[]"

# Each operator escape.
check nifcUnmangle(cstring"eqQ"),       "==", "eqQ"
check nifcUnmangle(cstring"eQ"),        "=",  "eQ"
check nifcUnmangle(cstring"leQ"),       "<=", "leQ"
check nifcUnmangle(cstring"ltQ"),       "<",  "ltQ"
check nifcUnmangle(cstring"geQ"),       ">=", "geQ"
check nifcUnmangle(cstring"gtQ"),       ">",  "gtQ"
check nifcUnmangle(cstring"dollarQ"),   "$",  "dollarQ"
check nifcUnmangle(cstring"percentQ"),  "%",  "percentQ"
check nifcUnmangle(cstring"ampQ"),      "&",  "ampQ"
check nifcUnmangle(cstring"roofQ"),     "^",  "roofQ"
check nifcUnmangle(cstring"emarkQ"),    "!",  "emarkQ"
check nifcUnmangle(cstring"qmarkQ"),    "?",  "qmarkQ"
check nifcUnmangle(cstring"starQ"),     "*",  "starQ"
check nifcUnmangle(cstring"plusQ"),     "+",  "plusQ"
check nifcUnmangle(cstring"minusQ"),    "-",  "minusQ"
check nifcUnmangle(cstring"slashQ"),    "/",  "slashQ"
check nifcUnmangle(cstring"bslashQ"),   "\\", "bslashQ"
check nifcUnmangle(cstring"tildeQ"),    "~",  "tildeQ"
check nifcUnmangle(cstring"colonQ"),    ":",  "colonQ"
check nifcUnmangle(cstring"atQ"),       "@",  "atQ"
check nifcUnmangle(cstring"barQ"),      "|",  "barQ"

# Q-escape passthrough.
check nifcUnmangle(cstring"QQ"),        "Q",  "QQ -> Q"
check nifcUnmangle(cstring"Q_"),        "_",  "Q_ -> _"

# Hex byte escape.
check nifcUnmangle(cstring"X41Q"),      "A",  "X41Q -> A (uppercase hex)"
check nifcUnmangle(cstring"X41QX42Q"),  "AB", "X41QX42Q -> AB"

# Realistic Nimony-emitted symbol: deepest.0.tstac<hash>.
check nifcUnmangle(cstring"deepest_0_tstacXYZ"), "deepest.0.tstacXYZ", "fullsym"

# Empty input.
check nifcUnmangle(cstring""), "", "empty"

if failed > 0:
  write stderr, "FAILED "
  write stderr, $failed
  write stderr, " demangle case(s)\n"
  quit 1
