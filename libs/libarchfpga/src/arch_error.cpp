#include <cstdarg>

#include "vtr_util.h"
#include "arch_error.h"

void archfpga_throw(const char* filename, int line, const char* fmt, ...) {
    va_list va_args;

    va_start(va_args, fmt);

    auto msg = vtr::vstring_fmt(fmt, va_args);

    va_end(va_args);

    fprintf(stderr, "Ooops unexpected stuff: %s\n", msg.c_str());
    //throw ArchFpgaError(msg, filename, line);
}
