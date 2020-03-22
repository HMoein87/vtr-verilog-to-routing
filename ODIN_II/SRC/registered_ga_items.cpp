#include "registered_ga_items.h"
#include "ga_partial_map.h"
#include "partial_map.h"
#include "odin_error.h"
#include "odin_util.h"
#include "netlist_statistic.h"
#include "vtr_memory.h"

// global with a ga for each op
ga_t* ga_op[operation_list_END] = {0};
bool ga_list_is_registered = false;
int traversal_id = PARTIAL_MAP_TRAVERSE_VALUE_GA_ADDERS;

// fn definition for wrappers
void instantiate_add_w_carry(ga_type_e type, nnode_t* node, short mark, netlist_t* netlist);

// general fn definition
void new_ga(operation_list op, instantiate_logic_fn_t inst_fn, int type_length, int type_init);
void GA_partial_map_top_item(operation_list op, netlist_t* netlist);

/************************************************
 * 
 * Register new types here
 * 
 */
void register_ga() {
    new_ga(ADD, instantiate_add_w_carry, adder_type_END, RCA);

    // signify that we are
    ga_list_is_registered = true;
}

void GA_partial_map_top(netlist_t* netlist) {
    /**
     * 
     * ordering of optimization is crutial 
     * 
     * */

    GA_partial_map_top_item(ADD, netlist);
}

/************************************************
 * wrappers to cast back to type 
 * 
 * When you want to add new function, casting type to int throw warnings,
 * the wrapper help prevent this issue 
 */
void instantiate_add_w_carry(ga_type_e type, nnode_t* node, short mark, netlist_t* netlist) {
    instantiate_add_w_carry((adder_type_e)type, node, mark, netlist);
}

/************************************************
 * 
 * 
 * 
 * 
 *  wrapper to hide the ga calls 
 * 
 * 
 * 
 * */

void new_ga(operation_list op, instantiate_logic_fn_t inst_fn, int type_length, int type_init) {
    oassert(NULL == ga_op[op]);
    oassert(NULL != inst_fn);
    oassert(type_init < type_length);

    ga_op[op] = new_ga_t(inst_fn, type_length, type_init, op);
}

void add_to_ga(nnode_t* node) {
    if (node) {
        if (!ga_list_is_registered) {
            register_ga();
        }

        if (NULL == ga_op[node->type]) {
            error_message(NETLIST_ERROR, -1, -1,
                          "%s does not have a registered GA type. unable to proceed",
                          node_name_based_on_op(node));
        }

        add_to_ga_t(ga_op[node->type], node);
    }
}

void GA_partial_map_top_item(operation_list op, netlist_t* netlist) {
    if (ga_op[op]) {
        ga_type_e* mapping = get_best_mapping_for(ga_op[op], netlist, traversal_id);

        for (int i = 0; i < ga_op[op]->size; i += 1) {
            reattach_connection(ga_op[op]->connectivity[mapping[i]][i]);
            free_connection(ga_op[op]->connectivity[mapping[i]][i]);
            ga_op[op]->connectivity[mapping[i]][i] = NULL;
        }

        vtr::free(mapping);
        free_ga_t(ga_op[op]);
        ga_op[op] = NULL;
        traversal_id += 1;
    }
}
