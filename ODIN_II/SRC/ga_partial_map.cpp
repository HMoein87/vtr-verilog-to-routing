
#include "odin_types.h"
#include "odin_globals.h"
#include "netlist_visualizer.h"

#include "netlist_utils.h"
#include "node_creation_library.h"
#include "odin_util.h"

#include "partial_map.h"
#include "multipliers.h"
#include "hard_blocks.h"
#include "math.h"
#include "memories.h"
#include "adders.h"
#include "subtractions.h"
#include "vtr_memory.h"
#include "vtr_util.h"

#include "ga_partial_map.h"
#include "netlist_statistic.h"

#define fmt_len 16
#define tbl_width 4
#define block_len (fmt_len * tbl_width)
#define NARROW_PAD "---------------------------"
#define WIDE_PAD "==========================="

connection_t* new_connection(nnode_t* parent);
void free_connection_subtree(connection_t* to_delete);
static stat_t* get_stats(connection_t* conn, netlist_t* netlist, short traverse_number);
connection_t* instantiate_subgraph(nnode_t* original_node, ga_type_e type, instantiate_logic_fn_t fn, short mark, netlist_t* netlist);

ga_type_e* generation_stat(ga_type_e* src, int population_size);
ga_type_e* new_generation(int population_size, ga_type_e initial_type);
ga_type_e* new_mutation(ga_type_e* src, int population_size, int type_length);

void free_ga_items_in_list(ga_t* list);

double partial_map_ga_item(ga_t* list, ga_type_e* type_list, netlist_t* netlist, short traverse_number, stat_t* current_values);
static void print_type_stat(stat_t* current_values, ga_t* list, ga_type_e* mapping, netlist_t* netlist);
static void print_header();

/*----------------------------------------------------------------------new_generation
 * (function: partial_map_ga_item_top) 
 *--------------------------------------------------------------------*/
ga_type_e* get_best_mapping_for(ga_t* list, netlist_t* netlist, short traverse_number) {
    // if we have items in the list we apply GA mapping
    ga_type_e* best_generation = NULL;
    if (list->size) {
        stat_t current_values;
        print_header();
        best_generation = new_generation(list->size, list->initial_type);
        double best_fit = partial_map_ga_item(list, best_generation, netlist, traverse_number, &current_values);
        ga_type_e* best_mutation = best_generation;

        if (global_args.ga_partial_map.provenance() == argparse::Provenance::SPECIFIED) {
            for (int i = 0; i < configuration.generation_count; i += 1) {
                best_mutation = best_generation;

                printf(">Generation_number %d\n", i);
                printf("parent_fitness %f\n", best_fit);
                print_type_stat(&current_values, list, best_mutation, netlist);

                for (int j = 1; j < configuration.generation_size; j += 1) {
                    ga_type_e* mutation = new_mutation(best_generation, list->size, list->type_length);
                    double current_fit = partial_map_ga_item(list, mutation, netlist, traverse_number, &current_values);

                    printf("current_fitness %lf\n", current_fit);

                    print_type_stat(&current_values, list, mutation, netlist);

                    if (current_fit < best_fit) {
                        if (best_mutation != best_generation) {
                            vtr::free(best_mutation);
                        }
                        best_mutation = mutation;
                        best_fit = current_fit;
                    } else {
                        vtr::free(mutation);
                    }
                }
                if (best_generation != best_mutation) {
                    vtr::free(best_generation);
                    best_generation = best_mutation;
                    best_fit = partial_map_ga_item(list, best_generation, netlist, traverse_number, &current_values);
                    // force to recompute the whole tree
                    traverse_number += 1;
                    compute_statistics(netlist, traverse_number);
                }
            }
        }
    }
    return best_generation;
}

/*----------------------------------------------------------------------
 * (function: partial_map_adders) This function employ the new type of 
 * adders into the adder list and after that, it instantiates adders and 
 * shrinks them into logics
 *--------------------------------------------------------------------*/
double partial_map_ga_item(ga_t* list, ga_type_e* type_list, netlist_t* netlist, short traverse_number, stat_t* current_values) {
    init(current_values);

    for (int i = 0; i < list->size; i += 1) {
        connection_t* conn = list->connectivity[type_list[i]][i];

        if (conn != NULL) {
            // we have the connections, we can simply remap the I/O
            reattach_connection(conn);
        } else {
            conn = instantiate_subgraph(list->node[i],
                                        type_list[i],
                                        list->instantiate_soft_logic,
                                        -1, // force a later recomputation
                                        netlist);
        }
        list->connectivity[type_list[i]][i] = conn;

        stat_t* node_stat = get_stats(conn, netlist, traverse_number);

        // this will aggregate partial metrics into one place
        do_compute_metric(current_values, node_stat);
        // print_stats(&current_values);

        delete_stat(node_stat);
    }
    // now we finalize to get the actual average
    finalize_compute_metric(current_values, list->size);

    return fitness_calc(netlist, current_values);
}

connection_t* new_connection(nnode_t* parent) {
    connection_t* connection = NULL;
    if (parent) {
        connection = (connection_t*)vtr::calloc(1, sizeof(connection_t));
        // get the current stats
        connection->input = init_signal_list();
        if (parent->input_pins
            && parent->num_input_pins) {
            connection->input->count = parent->num_input_pins;
            connection->input->pins = (npin_t**)vtr::calloc(parent->num_input_pins, sizeof(npin_t*));
            for (int i = 0; i < connection->input->count; i += 1) {
                // directly copy the pointer here
                connection->input->pins[i] = parent->input_pins[i];
            }
        }

        connection->output = init_signal_list();
        if (parent->output_pins
            && parent->num_output_pins) {
            connection->output->count = parent->num_output_pins;
            connection->output->pins = (npin_t**)vtr::calloc(parent->num_output_pins, sizeof(npin_t*));
            for (int i = 0; i < connection->output->count; i += 1) {
                // directly copy the pointer here
                connection->output->pins[i] = parent->output_pins[i];
            }
        }
    connection->parent = parent;
    }

    return connection;
}

void reattach_connection(connection_t* conn) {
    reattach(conn->input, UPWARD);
    reattach(conn->output, DOWNWARD);
}

static stat_t* get_stats(connection_t* conn, netlist_t* netlist, short traverse_number) {
    return get_stats(conn->input, conn->output, netlist, traverse_number);
}

void free_connection_subtree(connection_t* to_delete) {
    if (to_delete) {
        recursive_remove_subtree(to_delete->input, to_delete->output);
        //free leftover pins alloc'd
        for (int k = 0; k < to_delete->input->count; k += 1) {
            free_npin(to_delete->input->pins[k]);
        }
        for (int k = 0; k < to_delete->output->count; k += 1) {
            free_npin(to_delete->output->pins[k]);
        }
    }
    free_connection(to_delete);
}

void free_connection(connection_t* to_delete) {
    if (to_delete) {
        free_nnode(to_delete->parent);
        to_delete->parent = NULL;
        free_signal_list(to_delete->input);
        to_delete->input = NULL;
        free_signal_list(to_delete->output);
        to_delete->output = NULL;
        vtr::free(to_delete);
        to_delete = NULL;
    }
}

ga_t* new_ga_t(instantiate_logic_fn_t instantiate_soft_logic, int type_length, int initial_type, operation_list op) {
    ga_t* ga_item_list = (ga_t*)vtr::calloc(1, sizeof(ga_t));

    ga_item_list->node = NULL;
    ga_item_list->op = op;
    ga_item_list->size = 0;
    ga_item_list->instantiate_soft_logic = instantiate_soft_logic;
    ga_item_list->type_length = type_length;
    ga_item_list->initial_type = initial_type;
    ga_item_list->connectivity = (connection_t***)vtr::calloc(type_length, sizeof(connection_t**));

    return ga_item_list;
}

void add_to_ga_t(ga_t* list, nnode_t* node) {
    if (node) {
        list->node = (nnode_t**)vtr::realloc(list->node, sizeof(nnode_t*) * (list->size + 1));
        list->node[list->size] = node;

        for (int i = 0; i < list->type_length; i++) {
            list->connectivity[i] = (connection_t**)vtr::realloc(list->connectivity[i], sizeof(connection_t*) * (list->size + 1));
            list->connectivity[i][list->size] = NULL;
        }

        list->size += 1;
    }
}

connection_t* instantiate_subgraph(nnode_t* original_node, ga_type_e type, instantiate_logic_fn_t fn, short mark, netlist_t* netlist) {
    nnode_t* node_duplicate = duplicate_nnode(original_node);
    connection_t* conn = new_connection(node_duplicate);
    fn(type, node_duplicate, mark, netlist);
    return conn;
}

void free_ga_items_in_list(ga_t* list) {
    if (list) {
        if (list->node) {
            for (int i = 0; i < list->size; i++) {
                /* TODO: fix this */
                // free_nnode(list->node[i]);
            }
            vtr::free(list->node);
            list->node = NULL;
        }
        if (list->connectivity) {
            for (int i = 0; i < list->type_length; i++) {
                for (int j = 0; j < list->size; j++) {
                    /* TODO: fix this */
                    // free_connection_subtree(list->connectivity[i][j]);
                }
                vtr::free(list->connectivity[i]);
            }

            vtr::free(list->connectivity);
            list->connectivity = NULL;
        }
    }
}

ga_t* free_ga_t(ga_t* list) {
    if (list) {
        free_ga_items_in_list(list);
        vtr::free(list);
        list = NULL;
    }
    return list;
}

/*--------------------------------------------------------------------- 
 * This function creates a new generation. It changes the values of the 
 * genes by doing mutation. In each generation, except of the first one,
 * the parent of the next generation will be the fittest chromosome in 
 * the previous generation.
 *--------------------------------------------------------------------*/
ga_type_e* new_generation(int population_size, ga_type_e initial_type) {
    // Initilization of new generation
    ga_type_e* generation = (ga_type_e*)vtr::malloc(population_size * sizeof(ga_type_e));
    memset(generation, initial_type, population_size * sizeof(ga_type_e));
    return generation;
}

/*--------------------------------------------------------------------- 
 * This function changes the value of the genes in the given chromosome.
 * Based on the specified mutation rate, it finds the position of genes 
 * which should be mutated randomly, and after that, it changes their 
 * values through rand function.
 *--------------------------------------------------------------------*/
ga_type_e* new_mutation(ga_type_e* src, int population_size, int type_length) {
    // Initilization of new generation
    ga_type_e* new_mutation = (ga_type_e*)vtr::malloc(population_size * sizeof(ga_type_e));
    memcpy(new_mutation, src, sizeof(ga_type_e) * population_size);

    // Find a point and flip the chromosome from there
    // int cross_point = rand % num_of_adders;
    // Find points based on the mutation rate and change their values randomly

    int mutation_count = configuration.mutation_rate * population_size;
    mutation_count = std::min(population_size, mutation_count);

    for (int count = 0; count < mutation_count; count += 1) {
        int i = rand() % population_size;
        new_mutation[i] = (ga_type_e)(rand() % type_length);
    }

    return new_mutation;
}

/******************************************
 * helper functions
 */
static void print_header() {
    printf("%s\n", WIDE_PAD);
    printf("Physical Mapping statistics\n");
    printf("%-*s %-*s %-*s\n",
           fmt_len, "Logic Type",
           fmt_len, "Count",
           fmt_len, "Nets");
}

static void print_type_stat(stat_t* current_values, ga_t* list, ga_type_e* mapping, netlist_t* netlist) {
    long long* type_count = (long long*)vtr::calloc(list->type_length, sizeof(long long));
    const char* op_name
        = name_based_on_op(list->op);
    long long op_count = list->size;

    for (int i = 0; i < list->size; i += 1) {
        type_count[mapping[i]] += 1;
    }

    long long net_count_after = netlist->num_logic_element;

    printf("max_depth: %d\nmax_fan-in: %d\nmax_fan-out: %d\n",
           (int)(current_values->upward.depth.max + current_values->downward.depth.max),
           (int)(current_values->upward.faning.max),
           (int)(current_values->downward.faning.max));

    printf("%-*s %-*lld %-*lld\n",
           fmt_len, op_name,
           fmt_len, op_count,
           fmt_len, net_count_after);

    for (int i = 0; i < list->type_length; i++) {
        std::string type_name = "  - ";
        type_name += name_based_on_type((adder_type_e)i);

        printf("%-*s %-*lld\n",
               fmt_len, type_name.c_str(),
               fmt_len, type_count[i]);
    }
    vtr::free(type_count);

    printf("%s\n", NARROW_PAD);
}