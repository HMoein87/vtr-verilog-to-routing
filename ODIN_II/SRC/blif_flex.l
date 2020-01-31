%{
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

#include "odin_error.h"
#include "odin_types.h"
#include "odin_util.h"
#include "odin_globals.h"
#include "verilog_bison.h"
#include "vtr_util.h"
#include "scope_util.h"

#include <stdio.h>
#include <string>
#include <vector>
#include <algorithm>
#include <string.h>

#define RECURSIVE_LIMIT 256

#define YY_USER_ACTION {my_yycolumn = current_yycolumn; current_yycolumn = yyleng;}

/* the define below helps with watching the parser go token by token */
#define UNSUPPORTED_TOKEN 	{ delayed_error_message(PARSE_ERROR, my_yycolumn, my_yylineno, current_parse_file, "%s", "Unsuported token"); }

#define _STATE_TOP(str)		{ BEGIN(_state_top(str)); }
#define POP_STATE()			{ _pop_state(); _STATE_TOP("Popped to "); }
#define PUSH_STATE(state)	{ _push_state(state); _STATE_TOP("Pushed to ");}
#define CHANGE_STATE(state) { _pop_state(); _push_state(state); _STATE_TOP("Switched to "); }

struct defines_t 
{
	std::vector<std::string> args;
	std::string body;
};

void MP();
int _state_top(const char *str);
void _pop_state();	
void _push_state(int state);

void push_include(const char *file_name);
bool pop_include();
void pop_buffer_state();
void initialize_defaults();

int my_yylineno = 0;
int my_yycolumn = 1;
int current_yycolumn = 1;
std::vector<int> current_include_stack;
std::vector<int> state_stack = { 0 };

/*
 upon node creation we:
	// deal with input
	for input in input_pin_list:
		if input in unconn_output_net_hash :
			attach the node input pin to the net
			move the net from the unconn_output_net_hash to conn_output_net_hash
		else if input in conn_output_net_hash :
			attach the node input pin to the net
		else :
			create net
			insert the net into the unconn_input_net_hash
			attach the node input pin to the net

	// deal with output
	if output_pin in unconn_input_net_hash :
		attach the node output_pin to the net
		move the net from the unconn_input_net_hash to conn_input_net_hash
	else if input in conn_input_net_hash :
		attach the node output_pin to the net
	else :
		create net
		insert the net into the unconn_output_net_hash
		attach the node output_pin to the net
*/

std::unordered_set<nnet_t> unconn_output_net_hash;
std::unordered_set<nnet_t> conn_output_net_hash;

std::unordered_set<nnet_t> unconn_input_net_hash;
std::unordered_set<nnet_t> conn_input_net_hash;
int current_input_plane_size;

%}

%x INCLUDE BRACKET_MATCH COMMENT MULTI_LINE_COMMENT DEFINE_BODY SKIP ELIFCONDITION NEG_CONDITION CONDITION DEFINE_REMOVAL VAR_PARSE PARSE_DEFINE DEFINE_ARGS

%option noyywrap
%option nounput
%option noinput
%option never-interactive
%option nounistd
%option nodefault
%option case-sensitive

BLIF_IDENTIFIER [[:alpha:]_][[:alnum:]_$]* 

%%

<INITIAL>".model"					{ MP(); return bMODEL;}
<INITIAL>".end"						{ MP(); return bEND;}
<INITIAL>".inputs"					{ MP(); return bINPUTS;}
<INITIAL>".output"					{ MP(); return bOUTPUTS;}
<INITIAL>".latch"					{ MP(); return bLATCH;}

<INITIAL>".names"					{ MP(); PUSH_STATE(PARSE_PLA); current_input_plane_size=0; return bNAMES;}
<PARSE_PLA>BLIF_IDENTIFIER			{ MP(); current_input_plane_size +=1; return bIDENTIFIER; }

<INITIAL>".subckt"					{ MP(); return bSUBCIRCUIT;}
<INITIAL>".blackbox"				{ MP(); return bBLACKBOX;}

<INITIAL>"fe"						{ MP(); return bFALLING_EDGE;}
<INITIAL>"re"						{ MP(); return bRISING_EDGE;}
<INITIAL>"ah"						{ MP(); return bACTIVE_HIGH;}
<INITIAL>"al"						{ MP(); return bACTIVE_LOW;}
<INITIAL>"as"						{ MP(); return bASYNCHRONOUS;}

<INITIAL>[03-]						{ MP(); return yytext[0];}

<INITIAL>BLIF_IDENTIFIER			{ MP(); return bIDENTIFIER; }

    /* general stuff */
<INITIAL>"#"						{ PUSH_STATE(COMMENT); }
    /* skip escapped newline */
<*>\\\r?\n							{ my_yylineno++; my_yycolumn = 1; }
	/* deal with new lines */
<*>\r?\n							{ 
										if(_state_top("") == COMMENT)
										{
											POP_STATE();
										}

										my_yylineno++;
										my_yycolumn = 1;
									}
<*><<EOF>>							{ if ( ! pop_include() ){ yyterminate(); } }
	/* catch all */
<*>.            					{ MP(); }				

%%

void MP()		
{ 
	if (configuration.print_parse_tokens) 
	{
		printf("%d %s\n", my_yylineno, yytext);
	} 
}

int _state_top(const char *str)		
{ 
	int state = state_stack.back(); 
	if (configuration.print_parse_tokens && strlen(str)) 
	{
		printf("%s state: %s\n", str,
			(state == INCLUDE)? 			"INCLUDE":
			(state == COMMENT)? 			"COMMENT":
			(state == MULTI_LINE_COMMENT)? 	"MULTI_LINE_COMMENT":
			(state == DEFINE_BODY)? 		"DEFINE_BODY":
			(state == SKIP)? 				"SKIP":
			(state == ELIFCONDITION)? 		"ELIFCONDITION":
			(state == NEG_CONDITION)? 		"NEG_CONDITION":
			(state == CONDITION)? 			"CONDITION":
			(state == DEFINE_REMOVAL)? 		"DEFINE_REMOVAL":
			(state == VAR_PARSE)? 			"VAR_PARSE":
			(state == PARSE_DEFINE)? 		"PARSE_DEFINE":
			(state == DEFINE_ARGS)? 		"DEFINE_ARGS":
											"INITIAL"
		);
	} 
	return state;
}

void _pop_state()		
{ 
	state_stack.pop_back(); 
	if(state_stack.empty())
	{
		state_stack.push_back(INITIAL);
	} 
}

void _push_state(int state)	
{ 
	state_stack.push_back(state); 
}

static bool has_current_parse_file()
{
	return (
		current_parse_file < include_file_names.size()
		&& current_parse_file >= 0
	);
}

void push_include(const char *file_name)
{

	printf("Adding file %s to parse list\n", file_name);

	std::string tmp(file_name);

	if(tmp[0] == '"')
	{
		tmp.erase(0,1);
	}

	if(tmp.back() == '"')
	{
		tmp.pop_back();
	}

	std::string current_file = "";
	if(has_current_parse_file())
	{
		current_file = include_file_names[current_parse_file].first;
		if(current_include_stack.back() == current_parse_file)
		{
	 		include_file_names[current_parse_file].second = my_yylineno;
		}
	}

	/* we add the path from the current file */
	size_t loc = current_file.find_last_of("/");
	if(loc == std::string::npos)
	{
		current_file = tmp;
	}
	else
	{
		current_file = current_file.substr(0, loc + 1) + tmp;
	}

	yyin = fopen(current_file.c_str(), "r");
	if(yyin == NULL)
	{
		printf("Unable to open %s, trying %s\n", current_file.c_str(), tmp.c_str());
		current_file = tmp;
		yyin = open_file(current_file.c_str(), "r");
	}
	
	my_yylineno = 0;
	current_include_stack.push_back(include_file_names.size());
	include_file_names.push_back({current_file,my_yylineno});

	current_parse_file = current_include_stack.back();
	assert_supported_file_extension(include_file_names.back().first.c_str() , my_yylineno, current_parse_file); 

	YY_BUFFER_STATE yybuff = yy_create_buffer( yyin, YY_BUF_SIZE );
	yypush_buffer_state(yybuff);

}

bool pop_include()
{
	if(has_current_parse_file())
	{
		if(configuration.print_parse_tokens)
		{
			printf("Poping file %s from parse list\n", include_file_names[current_parse_file].first.c_str());
		}
		
		if(yyin)
		{
			fflush(yyin);
			fclose(yyin);
			yyin = NULL;
		}
	}

	if(!current_include_stack.empty())
	{
		current_include_stack.pop_back();
	}

	if(!current_include_stack.empty())
	{
		if(current_include_stack.back() != -1)
		{
			current_parse_file = current_include_stack.back();
		}
	}
	else
	{
		current_parse_file = -1;
	}

	if(has_current_parse_file() && current_parse_file >= 0)
	{
		my_yylineno = include_file_names[current_parse_file].second;

		if(configuration.print_parse_tokens)
		{
			printf("Reading file %s from line %d\n", include_file_names[current_parse_file].first.c_str(), my_yylineno);
		}
	}
	else
	{
		my_yylineno = -1;
	}
	
	yypop_buffer_state(); 
	return ( YY_CURRENT_BUFFER );
}

void initialize_defaults()
{

}
