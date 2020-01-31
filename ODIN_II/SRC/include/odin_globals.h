#ifndef GLOBALS_H
#define GLOBALS_H

#include "odin_types.h"
#include "string_cache.h"
#include "read_xml_arch_file.h"

extern t_logical_block_type* type_descriptors;

/* VERILOG SYNTHESIS GLOBALS */
extern ids default_net_type;

extern global_args_t global_args;
extern config_t configuration;
extern int current_parse_file;

extern long num_modules;
extern ast_node_t **ast_modules;
extern STRING_CACHE *module_names_to_idx;

extern STRING_CACHE *output_nets_sc;
extern STRING_CACHE *input_nets_sc;

extern netlist_t *verilog_netlist;

extern char *one_string;
extern char *zero_string;
extern char *pad_string;

extern t_arch Arch;
extern long file_line_number;

#endif


