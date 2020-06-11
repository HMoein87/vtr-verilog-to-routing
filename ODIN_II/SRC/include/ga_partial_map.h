#ifndef GA_PARTIAL_MAP_H
#define GA_PARTIAL_MAP_H

#include "odin_types.h"

typedef short ga_type_e;
typedef void (*instantiate_logic_fn_t)(ga_type_e, nnode_t*, short, netlist_t*);

struct connection_t {
    nnode_t* parent;

    signal_list_t* input;
    signal_list_t* output;
};

struct ga_t {
    operation_list op;
    nnode_t** node;
    connection_t*** connectivity;
    int size;

    instantiate_logic_fn_t instantiate_soft_logic;
    int type_length;
    int initial_type;
};

// Declarations
ga_t* new_ga_t(instantiate_logic_fn_t instantiate_soft_logic,
               int type_length,
               int initial_type,
               operation_list op);

void add_to_ga_t(ga_t* list, nnode_t* node);
ga_t* free_ga_t(ga_t* list);

ga_type_e* get_best_mapping_for(ga_t* list, netlist_t* netlist, short traverse_number);
void reattach_connection(connection_t* conn);
void free_connection(connection_t* to_delete);

#endif //GA_PARTIAL_MAP_H
