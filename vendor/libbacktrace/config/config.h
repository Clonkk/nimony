/* Dispatcher for vendored libbacktrace config.h.
   stacktraces.nim sets BACKTRACE_CONFIG_LINUX or BACKTRACE_CONFIG_OSX. */

#if defined(BACKTRACE_CONFIG_OSX) || (!defined(BACKTRACE_CONFIG_LINUX) && (defined(__APPLE__) && defined(__MACH__)))
#  include "config.osx.h"
#elif defined(BACKTRACE_CONFIG_LINUX) || defined(__linux__)
#  include "config.linux.h"
#else
#  error "vendor/libbacktrace: no config.h for this platform"
#endif
