/* config.osx.h
   Generated from libbacktrace ./configure on macOS (Darwin arm64, Xcode CLT 15+).
   Hand-edited: HAVE_ZLIB / HAVE_LIBLZMA / HAVE_ZSTD undefined to drop optional
   link-time deps (those defines only gate test programs we don't compile). */

#define BACKTRACE_ELF_SIZE unused
#define BACKTRACE_XCOFF_SIZE unused

#define HAVE_ATOMIC_FUNCTIONS 1
#define HAVE_CLOCK_GETTIME 1
#define HAVE_DECL_GETPAGESIZE 1
#define HAVE_DECL_STRNLEN 1
#define HAVE_DECL__PGMPTR 0
#define HAVE_DLFCN_H 1
/* #undef HAVE_DL_ITERATE_PHDR */
#define HAVE_FCNTL 1
/* #undef HAVE_GETEXECNAME */
#define HAVE_GETIPINFO 1
#define HAVE_INTTYPES_H 1
/* #undef HAVE_KERN_PROC */
/* #undef HAVE_KERN_PROC_ARGS */
/* #undef HAVE_LIBLZMA */
/* #undef HAVE_LINK_H */
/* #undef HAVE_LOADQUERY */
#define HAVE_LSTAT 1
#define HAVE_MACH_O_DYLD_H 1
#define HAVE_MEMORY_H 1
#define HAVE_READLINK 1
#define HAVE_STDINT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRINGS_H 1
#define HAVE_STRING_H 1
#define HAVE_SYNC_FUNCTIONS 1
/* #undef HAVE_SYS_LDR_H */
/* #undef HAVE_SYS_LINK_H */
#define HAVE_SYS_MMAN_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TYPES_H 1
/* #undef HAVE_TLHELP32_H */
#define HAVE_UNISTD_H 1
/* #undef HAVE_WINDOWS_H */
/* #undef HAVE_ZLIB */
/* #undef HAVE_ZSTD */

#define LT_OBJDIR ".libs/"
#define PACKAGE_BUGREPORT ""
#define PACKAGE_NAME "package-unused"
#define PACKAGE_STRING "package-unused version-unused"
#define PACKAGE_TARNAME "libbacktrace"
#define PACKAGE_URL ""
#define PACKAGE_VERSION "version-unused"

#define STDC_HEADERS 1

#ifndef _ALL_SOURCE
# define _ALL_SOURCE 1
#endif
#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif
#ifndef _POSIX_PTHREAD_SEMANTICS
# define _POSIX_PTHREAD_SEMANTICS 1
#endif
#ifndef _TANDEM_SOURCE
# define _TANDEM_SOURCE 1
#endif
#ifndef __EXTENSIONS__
# define __EXTENSIONS__ 1
#endif

#ifndef _DARWIN_USE_64_BIT_INODE
# define _DARWIN_USE_64_BIT_INODE 1
#endif

/* #undef _FILE_OFFSET_BITS */
/* #undef _LARGE_FILES */
/* #undef _MINIX */
/* #undef _POSIX_1_SOURCE */
/* #undef _POSIX_SOURCE */
