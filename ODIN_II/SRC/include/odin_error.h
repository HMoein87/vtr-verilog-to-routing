#ifndef ODIN_ERROR_H
#define ODIN_ERROR_H

#include <cstdio>
#include <cstdlib>
#include <vector>
#include <string>

enum odin_error {
    NO_ERROR,
    /* for error during odin bootup */
    ARG_ERROR,
    /* for parsing and AST creation errors */
    PARSE_ERROR,
    /* for netlist creation oerrors */
    NETLIST_ERROR,
    /* for blif read errors */
    BLIF_ERROR,
    /* for errors in netlist (clustered after tvpack) errors */
    NETLIST_FILE_ERROR,
    /* for errors in activation estimateion creation */
    ACTIVATION_ERROR,
    /* for errors in the netlist simulation */
    SIMULATION_ERROR,
    /* for error in ACE */
    ACE,
};

extern const char* odin_error_STR[];
extern std::vector<std::pair<std::string, int>> include_file_names;

// causes an interrupt in GDB
static inline void _verbose_assert(bool condition, const char* condition_str, const char* odin_file_name, long odin_line_number, const char* odin_function_name) {
    fflush(stdout);
    if (!condition) {
        fprintf(stderr, "Assertion failed(%s)@[%s]%s::%ld \n", condition_str, odin_file_name, odin_function_name, odin_line_number);
        fflush(stderr);
        std::abort();
    }
}

#define oassert(condition) _verbose_assert(condition, #condition, __FILE__, __LINE__, __func__)

void _log_message(odin_error error_type, long column, long line_number, long file, bool soft_error, const char* function_file_name, long function_line, const char* function_name, const char* message, ...);

#define error_message(error_type, line_number, file, message, ...) _log_message(error_type, -1, line_number, file, false, __FILE__, __LINE__, __func__, message, __VA_ARGS__)
#define possible_error_message(error_type, line_number, file, message, ...) _log_message(error_type, -1, line_number, file, global_args.permissive.value(), __FILE__, __LINE__, __func__, message, __VA_ARGS__)
#define delayed_error_message(error_type, column, line_number, file, message, ...) _log_message(error_type, column, line_number, file, true, __FILE__, __LINE__, __func__, message, __VA_ARGS__)
#define warning_message(error_type, line_number, file, message, ...) _log_message(error_type, -1, line_number, file, true, __FILE__, __LINE__, __func__, message, __VA_ARGS__)

void verify_delayed_error();

#endif