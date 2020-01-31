/*
Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
*/

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "odin_globals.h"
#include "odin_util.h"
#include "read_blif.h"
#include "string_cache.h"

#include "netlist_utils.h"
#include "odin_types.h"
#include "Hashtable.hpp"
#include "netlist_check.h"
#include "node_creation_library.h"
#include "simulate_blif.h"
#include "vtr_util.h"
#include "vtr_memory.h"

#define TOKENS		" \t\n"
#define PAD_NAME	"unconn"

#define READ_BLIF_BUFFER 1048576 // 1MB

long file_line_number;
int line_count;

// Stores pin names of the form port[pin]
struct hard_block_pins{
	int count;
	char **names;
	// Maps name to index.
	Hashtable *index;
};

// Stores port names, and their sizes.
struct hard_block_ports{
	char *signature;
	int count;
	int *sizes;
	char **names;
	// Maps portname to index.
	Hashtable *index;
};

// Stores all information pertaining to a hard block model. (.model)
struct hard_block_model{
	char *name;

	hard_block_pins *inputs;
	hard_block_pins *outputs;

	hard_block_ports *input_ports;
	hard_block_ports *output_ports;
};

// A cache structure for models.
struct hard_block_models{
	hard_block_model **models;
	int count;
	// Maps name to model
	Hashtable *index;
};


netlist_t * blif_netlist;
bool static skip_reading_bit_map=false;


void rb_create_top_driver_nets(const char *instance_name_prefix, Hashtable *output_nets_hash);
void rb_look_for_clocks();// not sure if this is needed
void add_top_input_nodes(FILE *file, Hashtable *output_nets_hash);
void rb_create_top_output_nodes(FILE *file);
int read_tokens (char *buffer, hard_block_models *models, FILE *file, Hashtable *output_nets_hash);
static void dum_parse (char *buffer, FILE *file);
void create_internal_node_and_driver(FILE *file, Hashtable *output_nets_hash);
operation_list read_bit_map(int input_count, nnode_t * node, FILE *file);
void create_latch_node_and_driver(FILE *file, Hashtable *output_nets_hash);
void create_hard_block_nodes(hard_block_models *models, FILE *file, Hashtable *output_nets_hash);
void hook_up_nets(Hashtable *output_nets_hash);
void hook_up_node(nnode_t *node, Hashtable *output_nets_hash);
void free_hard_block_model(hard_block_model *model);
char *get_hard_block_port_name(char *name);
long get_hard_block_pin_number(char *original_name);
static int compare_hard_block_pin_names(const void *p1, const void *p2);
hard_block_ports *get_hard_block_ports(char **pins, int count);
Hashtable *index_names(char **names, int count);
Hashtable *associate_names(char **names1, char **names2, int count);
void free_hard_block_pins(hard_block_pins *p);
void free_hard_block_ports(hard_block_ports *p);


hard_block_model *get_hard_block_model(char *name, hard_block_ports *ports, hard_block_models *models);
void add_hard_block_model(hard_block_model *m, hard_block_ports *ports, hard_block_models *models);
char *generate_hard_block_ports_signature(hard_block_ports *ports);
int verify_hard_block_ports_against_model(hard_block_ports *ports, hard_block_model *model);
hard_block_model *read_hard_block_model(char *name_subckt, hard_block_ports *ports, FILE *file);


void free_hard_block_models(hard_block_models *models);

hard_block_models *create_hard_block_models();

int count_blif_lines(FILE *file);

/*
 * Reads a blif file with the given filename and produces
 * a netlist which is referred to by the global variable
 * "blif_netlist".
 */
netlist_t *read_blif()
{
	current_parse_file = 0;
	blif_netlist = allocate_netlist();
	/*Opening the blif file */
	FILE *file = vtr::fopen (configuration.list_of_file_names[current_parse_file].c_str(), "r");
	if (file == NULL)
	{
		error_message(ARG_ERROR, -1, current_parse_file, "cannot open file: %s\n", configuration.list_of_file_names[current_parse_file].c_str());
	}
	int num_lines = count_blif_lines(file);

	Hashtable *output_nets_hash = new Hashtable();

	printf("Reading top level module\n"); fflush(stdout);
	/* create the top level module */
	rb_create_top_driver_nets("top", output_nets_hash);

	/* Extracting the netlist by reading the blif file */
	printf("Reading blif netlist..."); fflush(stdout);

	file_line_number  = 0;
	line_count = 0;
	int position   = -1;
	double time    = wall_time();
	// A cache of hard block models indexed by name. As each one is read, it's stored here to be used again.
	hard_block_models *models = create_hard_block_models();
	printf("\n");
	char buffer[READ_BLIF_BUFFER];
	while (vtr::fgets(buffer, READ_BLIF_BUFFER, file) && read_tokens(buffer, models, file, output_nets_hash))
	{	// Print a progress bar indicating completeness.
		position = print_progress_bar((++line_count)/(double)num_lines, position, 50, wall_time() - time);
	}
	free_hard_block_models(models);
	/* Now look for high-level signals */
	rb_look_for_clocks();
	// We the estimate of completion is rough...make sure we end up at 100%. ;)
	print_progress_bar(1.0, position, 50, wall_time() - time);
	printf("-------------------------------------\n"); fflush(stdout);

	// Outputs netlist graph.
	check_netlist(blif_netlist);
	delete output_nets_hash;
	fclose (file);
	return blif_netlist;
}



/*---------------------------------------------------------------------------------------------
 * (function: read_tokens)
 *
 * Parses the given line from the blif file. Returns true if there are more lines
 * to read.
 *-------------------------------------------------------------------------------------------*/
int read_tokens (char *buffer, hard_block_models *models, FILE *file, Hashtable *output_nets_hash)
{
	/* Figures out which, if any token is at the start of this line and *
	 * takes the appropriate action.                                    */
	char *token = vtr::strtok (buffer, TOKENS, file, buffer);

	if (token)
	{
		if(skip_reading_bit_map && ((token[0] == '0') || (token[0] == '1') || (token[0] == '-')))
		{
			dum_parse(buffer, file);
		}
		else
		{
			skip_reading_bit_map= false;
			if (strcmp (token, ".inputs") == 0)
			{
				add_top_input_nodes(file, output_nets_hash);// create the top input nodes
			}
			else if (strcmp (token, ".outputs") == 0)
			{
				rb_create_top_output_nodes(file);// create the top output nodes
			}
			else if (strcmp (token, ".names") == 0)
			{
				create_internal_node_and_driver(file, output_nets_hash);
				skip_reading_bit_map = true;
			}
			else if (strcmp(token,".latch") == 0)
			{
				create_latch_node_and_driver(file, output_nets_hash);
			}
			else if (strcmp(token,".subckt") == 0)
			{
				create_hard_block_nodes(models, file, output_nets_hash);
			}
			else if (strcmp(token,".end")==0)
			{
				// Marks the end of the main module of the blif
				// Call function to hook up the nets
				hook_up_nets(output_nets_hash);
				return false;
			}
			else if (strcmp(token,".model")==0)
			{
				// Ignore models.
				dum_parse(buffer, file);
			}
		}
	}
	return true;
}


/***************************************************************************************
 * function:create_latch_node_and_driver
 *   to create an ff node and driver from that node
 *
 *	Berkeley Logic Interchange Format (BLIF) p:4
 *	The generic-latch construct can be used to create any type of latch or flip-flop (see also the library-gate section).
 *	A generic-latch is declared as follows:
 *
 *	.latch <input> <output> [<type> <control>] [<init-val>]
 *	- <input> 	is the data input to the latch.
 *	- <output> 	is the output of the latch.
 *	- <type>	is one of {fe, re, ah, al, as}, which correspond to 
 * 		“falling edge”, “rising edge”, “active high”, “active low”, or “asynchronous.”
 *	- <control> is the clocking signal for the latch. It can be a .clock of the model, 
 *   	the output of any function in the model, or the word “NIL” for no clock.
 *	- <init-val> is the initial state of the latch, which can be one of {0, 1, 2, 3}. “2” stands for “don’t care” and “3” is
 *		“unknown.” Unspecified, it is assumed “3”.
 *
 * **If a latch does not have a controlling clock specified, it is assumed that it is actually controlled by a single
 *	global clock. The behavior of this global clock may be interpreted differently by the various algorithms that may
 *	manipulate the model after the model has been read in. Therefore, the user should be aware of these varying
 *	interpretations if latches are specified with no controlling clocks. **
 ***************************************************************************************/
#define MAX_LATCH_TOKENS 5
#define MIN_LATCH_TOKENS 2

void create_latch_node_and_driver(FILE *file, Hashtable *output_nets_hash)
{

	// set defaults
	nnode_t *new_node = allocate_nnode();
	new_node->related_ast_node = NULL;
	new_node->type = FF_NODE;

	const char *latch_input = NULL;
	const char *latch_output = NULL;
	new_node->edge_type = RISING_EDGE_SENSITIVITY;
	const char *latch_clock = DEFAULT_CLOCK_NAME;
	new_node->initial_value = BitSpace::_init;

	std::vector<const char *> latch_token;
	char *ptr = NULL;
	char buffer[READ_BLIF_BUFFER] = { 0 };
	while((ptr = vtr::strtok (NULL, TOKENS, file, buffer)) != NULL)
	{
		latch_token.push_back(ptr);
	}

	/* the .latch is invalid */
	if ( latch_token.size() < MIN_LATCH_TOKENS || latch_token.size() > MAX_LATCH_TOKENS )
	{
		error_message(BLIF_ERROR, line_count, current_parse_file, 
			"Malformed latch in blif file, got %d tokens, expected .latch <input> <output> [<type> <control>] [<init-val>]\n",
				latch_token.size());
	}

	int current_token = 0;
	latch_input = latch_token[current_token++];
	latch_output = latch_token[current_token++];

	if(current_token < latch_token.size())
	{
		edge_type_e temp_edge = edge_type_blif_enum(latch_token[current_token]);
		if(temp_edge != UNDEFINED_SENSITIVITY)
		{
			current_token++;

			new_node->edge_type = temp_edge;

			// now parse the clock
			latch_clock = latch_token[current_token++];
		}
	}

	if(current_token < latch_token.size())
	{
		BitSpace::bit_value_t temp_init_val = parse_init_val_blif(latch_token[current_token]);
		if(temp_init_val != (BitSpace::bit_value_t)-1)
		{
			current_token++;

			new_node->initial_value = temp_init_val;
		}
	}

	if(current_token < latch_token.size())
	{
		error_message(BLIF_ERROR, line_count, current_parse_file, "%s\n", 
				"Malformed latch in blif file, unable to parse latch properly, expected .latch <input> <output> [<type> <control>] [<init-val>]");
	}

	/* allocate the output pin (there is always one output pin) */
	allocate_more_output_pins(new_node, 1);
	add_output_port_information(new_node, 1);

	/* allocate the input pin */
	allocate_more_input_pins(new_node,2);/* input[1] is clock */

	/* add the port information */
	int i;
	for(i = 0; i < 2; i++)
	{
		add_input_port_information(new_node,1);
	}

	/* add names and type information to the created input pins */

	npin_t *new_pin = NULL;

	new_pin = allocate_npin();
	new_pin->name = vtr::strdup(latch_input);
	new_pin->type = INPUT;
	add_input_pin_to_node(new_node, new_pin,0);

	new_pin = allocate_npin();
	new_pin->name = vtr::strdup(latch_clock);
	new_pin->type = INPUT;
	add_input_pin_to_node(new_node, new_pin,1);

	/* add a name for the node, keeping the name of the node same as the output */
	new_node->name = make_full_ref_name(latch_output,NULL, NULL, NULL,-1);

	/*add this node to blif_netlist as an ff (flip-flop) node */
	blif_netlist->ff_nodes = (nnode_t **)vtr::realloc(blif_netlist->ff_nodes, sizeof(nnode_t*)*(blif_netlist->num_ff_nodes+1));
	blif_netlist->ff_nodes[blif_netlist->num_ff_nodes++] = new_node;
	new_node->file_number = current_parse_file;
	new_node->line_number = line_count;

	/*add name information and a net(driver) for the output */
	nnet_t *new_net = allocate_nnet();
	new_net->name = new_node->name;

	new_pin = allocate_npin();
	new_pin->name = new_node->name;
	new_pin->type = OUTPUT;
	add_output_pin_to_node(new_node, new_pin, 0);
	add_driver_pin_to_net(new_net, new_pin);

	output_nets_hash->add(new_node->name, new_net);
	vtr::free(ptr);
}

/*---------------------------------------------------------------------------------------------
   * function:create_hard_block_nodes
     to create the hard block nodes
*-------------------------------------------------------------------------------------------*/
void create_hard_block_nodes(hard_block_models *models, FILE *file, Hashtable *output_nets_hash)
{
	char buffer[READ_BLIF_BUFFER];
	char *subcircuit_name = vtr::strtok (NULL, TOKENS, file, buffer);

	/* storing the names on the formal-actual parameter */
	char *token;
	int count = 0;
	// Contains strings of the form port[pin]=port~pin
	char **names_parameters = NULL;
	while ((token = vtr::strtok (NULL, TOKENS, file, buffer)) != NULL)
  	{
		names_parameters          = (char**)vtr::realloc(names_parameters, sizeof(char*)*(count + 1));
		names_parameters[count++] = vtr::strdup(token);
  	}

	// Split the name parameters at the equals sign.
	char **mappings = (char**)vtr::calloc(count, sizeof(char*));
	char **names    = (char**)vtr::calloc(count, sizeof(char*));
	int i = 0;
	for (i = 0; i < count; i++)
	{
		mappings[i] = vtr::strdup(strtok(names_parameters[i], "="));
		names[i]    = vtr::strdup(strtok(NULL, "="));
	}

	// Associate mappings with their connections.
	Hashtable *mapping_index = associate_names(mappings, names, count);

	// Sort the mappings.
	qsort(mappings,  count,  sizeof(char *), compare_hard_block_pin_names);

	for(i = 0; i < count; i++)
		vtr::free(names_parameters[i]);

	vtr::free(names_parameters);

	// Index the mappings in a hard_block_ports struct.
	hard_block_ports *ports = get_hard_block_ports(mappings, count);

	for (i = 0; i < count; i++)
	{
		vtr::free(mappings[i]);
		mappings[i] = NULL;
	}
	
	vtr::free(mappings);
	mappings = NULL;


	// Look up the model in the models cache.
 	hard_block_model *model = NULL;
 	if ((subcircuit_name != NULL) && (!(model = get_hard_block_model(subcircuit_name, ports, models))))
 	{
 		// If the model isn's present, scan ahead and find it.
 		model = read_hard_block_model(subcircuit_name, ports, file);
 		// Add it to the cache.
 		add_hard_block_model(model, ports, models);
 	}

	nnode_t *new_node = allocate_nnode();

	// Name the node subcircuit_name~hard_block_number so that the name is unique.
	static long hard_block_number = 0;
	odin_sprintf(buffer, "%s~%ld", subcircuit_name, hard_block_number++);
	new_node->name = make_full_ref_name(buffer, NULL, NULL, NULL,-1);

	// Determine the type of hard block.
	char *subcircuit_name_prefix = vtr::strdup(subcircuit_name);
	subcircuit_name_prefix[5] = '\0';
	if (!strcmp(subcircuit_name, "multiply") || !strcmp(subcircuit_name_prefix, "mult_"))
		new_node->type = MULTIPLY;
	else if (!strcmp(subcircuit_name, "adder") || !strcmp(subcircuit_name_prefix, "adder"))
		new_node->type = ADD;
	else if (!strcmp(subcircuit_name, "sub") || !strcmp(subcircuit_name_prefix, "sub"))
			new_node->type = MINUS;
	else
	{
		new_node->type = MEMORY;
	}
	vtr::free(subcircuit_name_prefix);

	/* Add input and output ports to the new node. */
	{
		hard_block_ports *p;
		p = model->input_ports;
		for (i = 0; i < p->count; i++)
			add_input_port_information(new_node, p->sizes[i]);

		p = model->output_ports;
		for (i = 0; i < p->count; i++)
			add_output_port_information(new_node, p->sizes[i]);
	}

	// Allocate pins positions.
	if (model->inputs->count  > 0)
		allocate_more_input_pins (new_node, model->inputs->count);
	if (model->outputs->count > 0)
		allocate_more_output_pins(new_node, model->outputs->count);

	// Add input pins.
  	for(i = 0; i < model->inputs->count; i++)
  	{
  		char *mapping = model->inputs->names[i];
  		char *name    = (char *)mapping_index->get(mapping);

  		if (!name)
  			error_message(NETLIST_ERROR, file_line_number, current_parse_file, "Invalid hard block mapping: %s", mapping);

		npin_t *new_pin = allocate_npin();
		new_pin->name = vtr::strdup(name);
		new_pin->type = INPUT;
		new_pin->mapping = get_hard_block_port_name(mapping);

		add_input_pin_to_node(new_node, new_pin, i);
  	}

	// Add output pins, nets, and index each net.
  	for(i = 0; i < model->outputs->count; i++)
  	{
  		char *mapping = model->outputs->names[i];
  		char *name = (char *)mapping_index->get(mapping);

  		if (!name) error_message(NETLIST_ERROR, file_line_number, current_parse_file,"Invalid hard block mapping: %s", model->outputs->names[i]);

		npin_t *new_pin = allocate_npin();
		new_pin->name = vtr::strdup(name);
		new_pin->type = OUTPUT;
		new_pin->mapping = get_hard_block_port_name(mapping);

		add_output_pin_to_node(new_node, new_pin, i);

		nnet_t *new_net = allocate_nnet();
		new_net->name = vtr::strdup(name);

		add_driver_pin_to_net(new_net,new_pin);

		// Index the net by name.
		output_nets_hash->add(name, new_net);
	}

  	// Create a fake ast node.
	new_node->related_ast_node = (ast_node_t *)vtr::calloc(1, sizeof(ast_node_t));
	new_node->related_ast_node->children = (ast_node_t **)vtr::calloc(1,sizeof(ast_node_t *));
	new_node->related_ast_node->children[0] = (ast_node_t *)vtr::calloc(1, sizeof(ast_node_t));
	new_node->related_ast_node->children[0]->types.identifier = vtr::strdup(subcircuit_name);

  	/*add this node to blif_netlist as an internal node */
  	blif_netlist->internal_nodes = (nnode_t **)vtr::realloc(blif_netlist->internal_nodes, sizeof(nnode_t*) * (blif_netlist->num_internal_nodes + 1));
  	blif_netlist->internal_nodes[blif_netlist->num_internal_nodes++] = new_node;
	new_node->file_number = current_parse_file;
	new_node->line_number = line_count;

  	free_hard_block_ports(ports);
  	mapping_index->destroy_free_items();
	delete mapping_index;		
  	vtr::free(names);


}

/*---------------------------------------------------------------------------------------------
   * function:create_internal_node_and_driver
     to create an internal node and driver from that node
*-------------------------------------------------------------------------------------------*/
void create_internal_node_and_driver(FILE *file, Hashtable *output_nets_hash)
{
	/* Storing the names of the input and the final output in array names */
	char *ptr = NULL;
	char **names = NULL; // stores the names of the input and the output, last name stored would be of the output
	int input_count = 0;
	char buffer[READ_BLIF_BUFFER];
	while ((ptr = vtr::strtok (NULL, TOKENS, file, buffer)))
	{
		names = (char**)vtr::realloc(names, sizeof(char*) * (input_count + 1));
		names[input_count++]= vtr::strdup(ptr);
	}

	/* assigning the new_node */
	nnode_t *new_node = allocate_nnode();
	new_node->related_ast_node = NULL;

	new_node->type = GENERIC;
	read_bit_map(input_count-1, new_node, file);

	/* allocate the input pin (= input_count-1)*/
	if (input_count-1 > 0) // check if there is any input pins
	{
		allocate_more_input_pins(new_node, input_count-1);
		for(int i = 0; i < input_count-1; i++)
		{
			add_input_port_information(new_node, 1);
		}
	}

	/* add names and type information to the created input pins */
	for(int i = 0; i <= input_count-2; i++)
	{
		npin_t *new_pin = allocate_npin();
		new_pin->name = vtr::strdup(names[i]);
		new_pin->type = INPUT;
		add_input_pin_to_node(new_node, new_pin, i);
	}

	/* allocate the output pin (there is always one output pin) */
	allocate_more_output_pins(new_node, 1);
	add_output_port_information(new_node, 1);

	/* add a name for the node, keeping the name of the node same as the output */
	new_node->name = make_full_ref_name(names[input_count-1],NULL, NULL, NULL,-1);

	/*add this node to blif_netlist as an internal node */
	blif_netlist->internal_nodes = (nnode_t**)vtr::realloc(blif_netlist->internal_nodes, sizeof(nnode_t*)*(blif_netlist->num_internal_nodes+1));
	blif_netlist->internal_nodes[blif_netlist->num_internal_nodes++] = new_node;
	new_node->file_number = current_parse_file;
	new_node->line_number = line_count;

	/*add name information and a net(driver) for the output */

	npin_t *new_pin = allocate_npin();
	new_pin->name = new_node->name;
	new_pin->type = OUTPUT;

	add_output_pin_to_node(new_node, new_pin, 0);

	nnet_t *new_net = allocate_nnet();
	new_net->name = new_node->name;

	add_driver_pin_to_net(new_net,new_pin);

	output_nets_hash->add(new_node->name, new_net);

	/* Free the char** names */
	for(int i = 0; i < input_count; i++)
	{
		vtr::free(names[i]);
	}

	vtr::free(names);
}


static BitSpace::bit_value_t char_to_init_value(char input)
{
	switch(input)
	{
		case '0':	return BitSpace::_0;
		case '1':	return BitSpace::_1;
		case '-':	return BitSpace::_x;
		default:	return BitSpace::_init;
	}
}
/***************************************
 * function: read_bit_map
 * read the bit map for simulation
 */
operation_list read_bit_map(int input_count, nnode_t *node, FILE *file)
{
	fpos_t pos;
	int last_line = file_line_number;
	fgetpos(file,&pos);

	operation_list to_return = GENERIC;
	char buffer[READ_BLIF_BUFFER];

	bool done_parsing = false;
	char *line = NULL;
	while(NULL != (line = fgets (buffer, READ_BLIF_BUFFER, file)) && !done_parsing)
	{
		char *output_bit = NULL;
		char *bitset = NULL;

		char *token = strtok(buffer,TOKENS);
		// default to ouptut gnd
		if(!token)
		{
			break;
		}
		else
		{
			output_bit = token;
		}

		token = strtok(NULL,TOKENS);
		if(token)
		{
			bitset = output_bit;
			output_bit = token;
		}

		token = strtok(NULL,TOKENS);
		if(token)
		{
			break;
		}

		if(strlen(output_bit) != 1)
		{
			break;
		}

		BitSpace::bit_value_t output_val = char_to_init_value(output_bit[0]);
		if(output_val != BitSpace::_0 && output_val != BitSpace::_1)
		{
			break;
		}

		node->bitmap[output_val].push_back(std::vector<BitSpace::bit_value_t>());
		for (int i=0; bitset && i<strlen(bitset); i++)
		{
			output_val = char_to_init_value(bitset[i]);
			if(bit_is_defined(output_val))
			{
				node->bitmap[output_val].back().push_back(char_to_init_value(bitset[i]));
			}
			else
			{
				// this was not a bitset so we remove the vector and break out since we are done parsing
				node->bitmap[output_val].pop_back();
				done_parsing = true;
				break;
			}
		} 

		if	(! node->bitmap[output_val].empty()
		&&	node->bitmap[output_val].back().size() != input_count)
		{
			error_message(NETLIST_ERROR, file_line_number, current_parse_file,
				"Unable to parse blif lut line, expected %d input, got %d", input_count, node->bitmap[output_val].back().size());
		}
	}

	// default to GND if nothing is there
	if(node->bitmap[0].size() == 0
	&& node->bitmap[1].size() == 0)
	{
		if (input_count == 0)
		{
			node->bitmap[0].push_back(std::vector<BitSpace::bit_value_t>());
		}
		else
		{
			error_message(NETLIST_ERROR, file_line_number, current_parse_file,
				"Expected a lut with bitmap of size %d but nothing was provided: %s", input_count, buffer);
		}
		
	}
	
	file_line_number = last_line;
	fsetpos(file,&pos);

	return to_return;
}

/*
*---------------------------------------------------------------------------------------------
   * function: add_top_input_nodes
     to add the top level inputs to the netlist
*-------------------------------------------------------------------------------------------*/
static void build_top_input_node(const char *name_str, Hashtable *output_nets_hash)
{
	char *temp_string = make_full_ref_name(name_str, NULL, NULL,NULL, -1);

	/* create a new top input node and net*/

	nnode_t *new_node = allocate_nnode();

	new_node->related_ast_node = NULL;
	new_node->type = INPUT_NODE;

	/* add the name of the input variable */
	new_node->name = temp_string;

	new_node->file_number = current_parse_file;
	new_node->line_number = line_count;

	/* allocate the pins needed */
	allocate_more_output_pins(new_node, 1);
	add_output_port_information(new_node, 1);

	/* Create the pin connection for the net */
	npin_t *new_pin = allocate_npin();
	new_pin->name = vtr::strdup(temp_string);
	new_pin->type = OUTPUT;

	/* hookup the pin, net, and node */
	add_output_pin_to_node(new_node, new_pin, 0);

	nnet_t *new_net = allocate_nnet();
	new_net->name = vtr::strdup(temp_string);

	add_driver_pin_to_net(new_net, new_pin);

	blif_netlist->top_input_nodes = (nnode_t**)vtr::realloc(blif_netlist->top_input_nodes, sizeof(nnode_t*)*(blif_netlist->num_top_input_nodes+1));
	blif_netlist->top_input_nodes[blif_netlist->num_top_input_nodes++] = new_node;

	//long sc_spot = sc_add_string(output_nets_sc, temp_string);
	//if (output_nets_sc->data[sc_spot])
	//warning_message(NETLIST_ERROR,linenum,-1, "Net (%s) with the same name already created\n",temp_string);

	//output_nets_sc->data[sc_spot] = new_net;

	output_nets_hash->add(temp_string, new_net);
}

void add_top_input_nodes(FILE *file, Hashtable *output_nets_hash)
{

	char *ptr;
	char buffer[READ_BLIF_BUFFER];
	while ((ptr = vtr::strtok (NULL, TOKENS, file, buffer)))
	{
		build_top_input_node(ptr, output_nets_hash);
	}
}

/*---------------------------------------------------------------------------------------------
   * function: create_top_output_nodes
     to add the top level outputs to the netlist
*-------------------------------------------------------------------------------------------*/
void rb_create_top_output_nodes(FILE *file)
{
	char *ptr;
	char buffer[READ_BLIF_BUFFER];

	while ((ptr = vtr::strtok (NULL, TOKENS, file, buffer)))
	{
		char *temp_string = make_full_ref_name(ptr, NULL, NULL,NULL, -1);;

		/*add_a_fanout_pin_to_net((nnet_t*)output_nets_sc->data[sc_spot], new_pin);*/

		/* create a new top output node and */
		nnode_t *new_node = allocate_nnode();
		new_node->related_ast_node = NULL;
		new_node->type = OUTPUT_NODE;

		/* add the name of the output variable */
		new_node->name = temp_string;

		/* allocate the input pin needed */
		allocate_more_input_pins(new_node, 1);
		add_input_port_information(new_node, 1);

		/* Create the pin connection for the net */
		npin_t *new_pin = allocate_npin();
		new_pin->name   = temp_string;
		/* hookup the pin, net, and node */
		add_input_pin_to_node(new_node, new_pin, 0);

		/*adding the node to the blif_netlist output nodes
		add_node_to_netlist() function can also be used */
		blif_netlist->top_output_nodes = (nnode_t**)vtr::realloc(blif_netlist->top_output_nodes, sizeof(nnode_t*)*(blif_netlist->num_top_output_nodes+1));
		blif_netlist->top_output_nodes[blif_netlist->num_top_output_nodes++] = new_node;
		new_node->file_number = current_parse_file;
		new_node->line_number = line_count;
	}
}


/*---------------------------------------------------------------------------------------------
   * (function: look_for_clocks)
 *-------------------------------------------------------------------------------------------*/

void rb_look_for_clocks()
{
	int i;
	for (i = 0; i < blif_netlist->num_ff_nodes; i++)
	{
		if (blif_netlist->ff_nodes[i]->input_pins[1]->net->driver_pin->node->type == INPUT_NODE)
		{
			blif_netlist->ff_nodes[i]->input_pins[1]->net->driver_pin->node->type = CLOCK_NODE;
		}
	}

}

/*----------------------------------------------------------------------------
function: Creates the drivers for the top module
   Top module is :
                * Special as all inputs are actually drivers.
                * Also make the 0 and 1 constant nodes at this point.
---------------------------------------------------------------------------*/
void rb_create_top_driver_nets(const char *instance_name_prefix, Hashtable *output_nets_hash)
{
	npin_t *new_pin;
	/* create the constant nets */

	/* Pad net */
	blif_netlist->pad_net = allocate_nnet();
	blif_netlist->pad_net->name = make_full_ref_name(instance_name_prefix, NULL, NULL, PAD_NAME, -1);
	blif_netlist->pad_node = allocate_nnode();
	blif_netlist->pad_node->name = vtr::strdup(PAD_NAME);
	blif_netlist->pad_node->type = PAD_NODE;
	allocate_more_output_pins(blif_netlist->pad_node, 1);
	add_output_port_information(blif_netlist->pad_node, 1);
	new_pin = allocate_npin();
	add_output_pin_to_node(blif_netlist->pad_node, new_pin, 0);
	add_driver_pin_to_net(blif_netlist->pad_net, new_pin);
	output_nets_hash->add(PAD_NAME, blif_netlist->pad_net);

	/* Global Clock net */
	blif_netlist->default_clock_net = allocate_nnet();
	blif_netlist->default_clock_net->name = make_full_ref_name(instance_name_prefix, NULL, NULL, DEFAULT_CLOCK_NAME, -1);
	blif_netlist->default_clock_node = allocate_nnode();
	blif_netlist->default_clock_node->name = vtr::strdup(DEFAULT_CLOCK_NAME);
	blif_netlist->default_clock_node->type = CLOCK_NODE;
	allocate_more_output_pins(blif_netlist->default_clock_node, 1);
	add_output_port_information(blif_netlist->default_clock_node, 1);
	new_pin = allocate_npin();
	add_output_pin_to_node(blif_netlist->default_clock_node, new_pin, 0);
	add_driver_pin_to_net(blif_netlist->default_clock_net, new_pin);
	output_nets_hash->add(DEFAULT_CLOCK_NAME, blif_netlist->default_clock_net);
}

/*---------------------------------------------------------------------------------------------
 * (function: dum_parse)
 *-------------------------------------------------------------------------------------------*/
static void dum_parse (char *buffer, FILE *file)
{
	/* Continue parsing to the end of this (possibly continued) line. */
	while (vtr::strtok (NULL, TOKENS, file, buffer));
}



/*---------------------------------------------------------------------------------------------
 * function: hook_up_nets()
 * find the output nets and add the corresponding nets
 *-------------------------------------------------------------------------------------------*/
void hook_up_nets(Hashtable *output_nets_hash)
{
	nnode_t **node_sets[] = {blif_netlist->internal_nodes,     blif_netlist->ff_nodes,     blif_netlist->top_output_nodes};
	int          counts[] = {blif_netlist->num_internal_nodes, blif_netlist->num_ff_nodes, blif_netlist->num_top_output_nodes};
	int        num_sets   = 3;

	/* hook all the input pins in all the internal nodes to the net */
	int i;
	for (i = 0; i < num_sets; i++)
	{
		int j;
		for(j = 0; j < counts[i]; j++)
		{
			nnode_t *node = node_sets[i][j];
			hook_up_node(node, output_nets_hash);
		}
	}
}

/*
 * Connect the given node's input pins to their corresponding nets by
 * looking each one up in the output_nets_sc.
 */
void hook_up_node(nnode_t *node, Hashtable *output_nets_hash)
{
	int j;
	for(j = 0; j < node->num_input_pins; j++)
	{
		npin_t *input_pin = node->input_pins[j];

		nnet_t *output_net = (nnet_t *)output_nets_hash->get(input_pin->name);

		if(!output_net)
			error_message(NETLIST_ERROR,file_line_number, current_parse_file, "Error: Could not hook up the pin %s: not available.", input_pin->name);

		add_fanout_pin_to_net(output_net, input_pin);
	}
}

/*
 * Scans ahead in the given file to find the
 * model for the hard block by the given name.
 * Returns the file to its original position when finished.
 */
hard_block_model *read_hard_block_model(char *name_subckt, hard_block_ports *ports, FILE *file)
{
	// Store the current position in the file.
	fpos_t pos;
	int last_line = file_line_number;
	fgetpos(file,&pos);

	hard_block_model *model;

	while(1) {
		model = NULL;

		// Search the file for .model followed buy the subcircuit name.
		char buffer[READ_BLIF_BUFFER];
		while (vtr::fgets(buffer, READ_BLIF_BUFFER, file))
		{
			char *token = vtr::strtok(buffer,TOKENS, file, buffer);
			// match .model followed by the subcircuit name.
			if (token && !strcmp(token,".model") && !strcmp(vtr::strtok(NULL,TOKENS, file, buffer), name_subckt))
			{
				model = (hard_block_model *)vtr::calloc(1, sizeof(hard_block_model));
				model->name = vtr::strdup(name_subckt);
				model->inputs = (hard_block_pins *)vtr::calloc(1, sizeof(hard_block_pins));
				model->inputs->count = 0;
				model->inputs->names = NULL;

				model->outputs = (hard_block_pins *)vtr::calloc(1, sizeof(hard_block_pins));
				model->outputs->count = 0;
				model->outputs->names = NULL;

				// Read the inputs and outputs.
				while (vtr::fgets(buffer, READ_BLIF_BUFFER, file))
				{
					char *first_word = vtr::strtok(buffer, TOKENS, file, buffer);
					if(first_word)
					{
						if(!strcmp(first_word, ".inputs"))
						{
							char *name;
							while ((name = vtr::strtok(NULL, TOKENS, file, buffer)))
							{
								model->inputs->names = (char **)vtr::realloc(model->inputs->names, sizeof(char *) * (model->inputs->count + 1));
								model->inputs->names[model->inputs->count++] = vtr::strdup(name);
							}
						}
						else if(!strcmp(first_word, ".outputs"))
						{
							char *name;
							while ((name = vtr::strtok(NULL, TOKENS, file, buffer)))
							{
								model->outputs->names = (char **)vtr::realloc(model->outputs->names, sizeof(char *) * (model->outputs->count + 1));
								model->outputs->names[model->outputs->count++] = vtr::strdup(name);
							}
						}
						else if(!strcmp(first_word, ".end"))
						{
							break;
						}
					}
				}
				break;
			}
		}

		if(!model || feof(file))
			error_message(NETLIST_ERROR, last_line, current_parse_file, "A subcircuit model for '%s' with matching ports was not found.",name_subckt);

		// Sort the names.
		qsort(model->inputs->names,  model->inputs->count,  sizeof(char *), compare_hard_block_pin_names);
		qsort(model->outputs->names, model->outputs->count, sizeof(char *), compare_hard_block_pin_names);

		// Index the names.
		model->inputs->index  = index_names(model->inputs->names, model->inputs->count);
		model->outputs->index = index_names(model->outputs->names, model->outputs->count);

		// Organise the names into ports.
		model->input_ports  = get_hard_block_ports(model->inputs->names,  model->inputs->count);
		model->output_ports = get_hard_block_ports(model->outputs->names, model->outputs->count);

		// Check that the model we've read matches the ports of the instance we are trying to match.
		if (verify_hard_block_ports_against_model(ports, model))
		{
			break;
		}
		else
		{	// If not, free it, and keep looking.
			free_hard_block_model(model);
		}
	}

	// Restore the original position in the file.
	file_line_number = last_line;
 	fsetpos(file,&pos);

	return model;
}

/*
 * Callback function for qsort which compares pin names
 * of the form port_name[pin_number] primarily
 * on the port_name, and on the pin_number if the port_names
 * are identical.
 */
static int compare_hard_block_pin_names(const void *p1, const void *p2)
{
	char *name1 = *(char * const *)p1;
	char *name2 = *(char * const *)p2;

	char *port_name1 = get_hard_block_port_name(name1);
	char *port_name2 = get_hard_block_port_name(name2);
	int portname_difference = strcmp(port_name1, port_name2);
	vtr::free(port_name1);
	vtr::free(port_name2);

	// If the portnames are the same, compare the pin numbers.
	if (!portname_difference)
	{
		int n1 = get_hard_block_pin_number(name1);
		int n2 = get_hard_block_pin_number(name2);
		return n1 - n2;
	}
	else
	{
		return portname_difference;
	}
}

/*
 * Creates a hashtable index for an array of strings of
 * the form names[i]=>i.
 */
Hashtable *index_names(char **names, int count)
{
	Hashtable *index = new Hashtable();
	for (long i = 0; i < count; i++)
	{
		int *offset = (int *)vtr::calloc(1, sizeof(int));
		*offset = i;
		index->add(names[i], offset);
	}
	return index;
}

/*
 * Create an associative index of names1[i]=>names2[i]
 */
Hashtable *associate_names(char **names1, char **names2, int count)
{
	Hashtable *index = new Hashtable();
	for (long i = 0; i < count; i++)
		index->add(names1[i], names2[i]);

	return index;
}


/*
 * Organises the given strings representing pin names on a hard block
 * model into ports, and indexes the ports by name. Returns the organised
 * ports as a hard_block_ports struct.
 */
hard_block_ports *get_hard_block_ports(char **pins, int count)
{
	// Count the input port sizes.
	hard_block_ports *ports = (hard_block_ports *)vtr::calloc(1, sizeof(hard_block_ports));
	ports->count = 0;
	ports->sizes = NULL;
	ports->names = NULL;
	char *prev_portname = NULL;
	int i;
	for (i = 0; i < count; i++)
	{
		char *portname = get_hard_block_port_name(pins[i]);
		// Compare the part of the name before the "["
		if (!i || strcmp(prev_portname, portname))
		{
			ports->sizes = (int *)vtr::realloc(ports->sizes, sizeof(int) * (ports->count + 1));
			ports->names = (char **)vtr::realloc(ports->names, sizeof(char *) * (ports->count + 1));

			ports->sizes[ports->count] = 0;
			ports->names[ports->count] = vtr::strdup(portname);
			ports->count++;

		}

		if ( prev_portname != NULL )
			vtr::free(prev_portname);

		prev_portname = portname;
		ports->sizes[ports->count-1]++;
	}

	if ( prev_portname != NULL )
		vtr::free(prev_portname);

	ports->signature = generate_hard_block_ports_signature(ports);
	ports->index     = index_names(ports->names, ports->count);

	return ports;
}

/*
 * Check for inconsistencies between the hard block model and the ports found
 * in the hard block instance. Returns false if differences are found.
 */
int verify_hard_block_ports_against_model(hard_block_ports *ports, hard_block_model *model)
{
	hard_block_ports *port_sets[] = {model->input_ports, model->output_ports};
	int i;
	for (i = 0; i < 2; i++)
	{
		hard_block_ports *p = port_sets[i];
		int j;
		for (j = 0; j < p->count; j++)
		{
			// Look up each port from the model in "ports"
			char *name = p->names[j];
			int   size = p->sizes[j];
			int  *idx  = (int *)ports->index->get(name);
			// Model port not specified in ports.
			if (!idx)
			{
				//printf("Model port not specified in ports. %s\n", name);
				return false;
			}

			// Make sure they match in size.
			int instance_size = ports->sizes[*idx];
			// Port sizes differ.
			if (size != instance_size)
			{
				//printf("Port sizes differ. %s\n", name);
				return false;
			}
		}
	}

	hard_block_ports *in = model->input_ports;
	hard_block_ports *out = model->output_ports;
	int j;
	for (j = 0; j < ports->count; j++)
	{
		// Look up each port from the subckt to make sure it appears in the model.
		char *name   = ports->names[j];
		int *in_idx  = (int *)in->index->get(name);
		int *out_idx = (int *)out->index->get(name);
		// Port does not appear in the model.
		if (!in_idx && !out_idx)
		{
			//printf("Port does not appear in the model. %s\n", name);
			return false;
		}
	}

	return true;
}

/*
 * Generates string which represents the geometry of the given hard block ports.
 */
char *generate_hard_block_ports_signature(hard_block_ports *ports)
{
	char buffer[READ_BLIF_BUFFER];
	buffer[0] = '\0';

	strcat(buffer, "_");

	int j;
	for (j = 0; j < ports->count; j++)
	{
		char buffer1[READ_BLIF_BUFFER];
		odin_sprintf(buffer1, "%s_%d_", ports->names[j], ports->sizes[j]);
		strcat(buffer, buffer1);
	}
	return vtr::strdup(buffer);
}

/*
 * Gets the text in the given string which occurs
 * before the first instance of "[". The string is
 * presumably of the form "port[pin_number]"
 *
 * The retuned string is strduped and must be freed.
 * The original string is unaffected.
 */
char *get_hard_block_port_name(char *name)
{
	name = vtr::strdup(name);
	if (strchr(name,'['))
		return strtok(name,"[");
	else
		return name;
}

/*
 * Parses a port name of the form port[pin_number]
 * and returns the pin number as a long. Returns -1
 * if there is no [pin_number] in the name. Throws an
 * error if pin_number is not parsable as a long.
 *
 * The original string is unaffected.
 */
long get_hard_block_pin_number(char *original_name)
{
	if (!strchr(original_name,'['))
		return -1;

	char *name = vtr::strdup(original_name);
	strtok(name,"[");
	char *endptr;
	char *pin_number_string = strtok(NULL,"]");
	long pin_number = strtol(pin_number_string, &endptr, 10);

	if (pin_number_string == endptr)
		error_message(NETLIST_ERROR,file_line_number, current_parse_file,"The given port name \"%s\" does not contain a valid pin number.", original_name);

	vtr::free(name);

	return pin_number;
}

/*
 * Adds the given model to the hard block model cache.
 */
void add_hard_block_model(hard_block_model *m, hard_block_ports *ports, hard_block_models *models)
{
	if(models && m)
	{
		char needle[READ_BLIF_BUFFER] = { 0 };

		if(m->name && ports && ports->signature)
			sprintf(needle, "%s%s", m->name, ports->signature);
		else if(m->name) 
			sprintf(needle, "%s", m->name);
		else if(ports && ports->signature)
			sprintf(needle, "%s", ports->signature);
		
		if(strlen(needle) > 0)
		{
			models->count += 1;

			models->models = (hard_block_model **)vtr::realloc(models->models, models->count * sizeof(hard_block_model *));
			models->models[models->count-1] = m;
			models->index->add(needle, m);
		}
	}
}

/*
 * Looks up a hard block model by name. Returns null if the
 * model is not found.
 */
hard_block_model *get_hard_block_model(char *name, hard_block_ports *ports, hard_block_models *models)
{
	hard_block_model *to_return = NULL;
	char needle[READ_BLIF_BUFFER] = { 0 };

	if(name && ports && ports->signature)
		sprintf(needle, "%s%s", name, ports->signature);
	else if(name) 
		sprintf(needle, "%s", name);
	else if(ports && ports->signature)
		sprintf(needle, "%s", ports->signature);
	
	if(strlen(needle) > 0) 
		to_return = (hard_block_model *)models->index->get(needle);

	return to_return;
}

/*
 * Creates a new hard block model cache.
 */
hard_block_models *create_hard_block_models()
{
	hard_block_models *m = (hard_block_models *)vtr::calloc(1, sizeof(hard_block_models));
	m->models = NULL;
	m->count  = 0;
	m->index  = new Hashtable();

	return m;
}

/*
 * Counts the number of lines in the given blif file
 * before a .end token is hit.
 */
int count_blif_lines(FILE *file)
{
	int num_lines = 0;
	char buffer[READ_BLIF_BUFFER];
	while (vtr::fgets(buffer, READ_BLIF_BUFFER, file))
	{
		if (strstr(buffer, ".end"))
			break;
		num_lines++;
	}
	rewind(file);
	return num_lines;
}

/*
 * Frees the hard block model cache, freeing
 * all encapsulated hard block models.
 */
void free_hard_block_models(hard_block_models *models)
{
	//does not delete the items in the hash
	delete models->index;
	int i;
	for (i = 0; i < models->count; i++)
		free_hard_block_model(models->models[i]);

	vtr::free(models->models);
	vtr::free(models);
}


/*
 * Frees a hard_block_model.
 */
void free_hard_block_model(hard_block_model *model)
{
	free_hard_block_pins(model->inputs);
	free_hard_block_pins(model->outputs);

	free_hard_block_ports(model->input_ports);
	free_hard_block_ports(model->output_ports);

	vtr::free(model->name); 
	vtr::free(model);
}

/*
 * Frees hard_block_pins
 */
void free_hard_block_pins(hard_block_pins *p)
{
	while (p->count--)
		vtr::free(p->names[p->count]);

	vtr::free(p->names);

	p->index->destroy_free_items();
	delete p->index;
	vtr::free(p);
}

/*
 * Frees hard_block_ports
 */
void free_hard_block_ports(hard_block_ports *p)
{
	while(p->count--)
		vtr::free(p->names[p->count]);

	vtr::free(p->signature);
	vtr::free(p->names);
	vtr::free(p->sizes);

	p->index->destroy_free_items();
	delete p->index;
	vtr::free(p);
}
