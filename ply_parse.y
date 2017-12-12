%{
/* ply_parse.y --- parser for the header of the ply file.
 * Author: Luis Colorado <luiscoloradourcola@gmail.com>
 * Date: Wed Dec  6 15:40:53 EET 2017
 */

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#include "ply.h"
#include "ply_parse.h"
#include "ply_lex.h"

#define YYERROR_VERBOSE 1

#define F(arg) __FILE__":%d:%s:" arg, __LINE__, __func__

#define RULE(left, right) do {         \
        printf(                        \
            F(" RULE[%d]: \033[1;33m" #left      \
            "\033[1;31m <==\033[m"     \
            right "\033[m\n"),         \
            __LINE__);                 \
    } while(0)

#define T(arg) " \033[36m" #arg
#define N(arg) " \033[32m" #arg
#define EMPTY  " \033[34m/* empty */"
#define ERROR  " \033[31m<<ERROR>>"

PlyProperty *new_property(PlyToken *type, PlyToken *name);
PlyProperty *new_list_property(PlyToken *size_type, PlyToken *elem_type, PlyToken *name);
int yyerror(const char *s);

%}

%token PLY FORMAT COMMENT OBJ_INFO TOKERROR
%token ELEMENT PROPERTY LIST END_HEADER CRLF
%token <tok> IDENT UNSLIT SIGLIT FLTLIT STRLIT TEXT
%type <prop> property

%union {
   struct PlyToken *tok; 
   PlyProperty *prop;
}

%%

ply_header:
          PLY
          format
          comment_list
          obj_info_list
          element_list
          END_HEADER {
            RULE(ply_header,
                T(PLY)
                N(format)
                N(comment_list)
                N(obj_info_list)
                N(element_list)
                T(END_HEADER));
            return 0;
          };

format: FORMAT IDENT FLTLIT CRLF {
        RULE(format, T(FORMAT) T(IDENT) T(FLTLIT) T(CRLF));
      };

comment_list: comment_list COMMENT TEXT CRLF {
                RULE(comment_list, N(comment_list) T(COMMENT) T(TEXT) T(CRLF));
            }
            | /* empty */ {
                RULE(comment_list, EMPTY);
            };

obj_info_list: obj_info_list OBJ_INFO TEXT CRLF {
                RULE(obj_info_list, N(obj_info_list) T(OBJ_INFO) T(TEXT) T(CRLF));
             }
             | /* empty */ {
                RULE(obj_info_list, EMPTY);
             };

element_list: element_list element {
                RULE(element_list, N(element_list) N(element));
            }
            | /* empty */ {
                RULE(element_list, EMPTY);
            };

element: ELEMENT IDENT UNSLIT CRLF
         property_list {
            RULE(element, T(ELEMENT) T(IDENT) T(UNSLIT) T(CRLF) N(property_list));
       }
       | error CRLF {
            RULE(element, ERROR T(CRLF));
       };

property_list: property_list property {
                RULE(property_list, N(property_list) N(property));
             }
             | /* empty */ {
                RULE(property_list, EMPTY);
             }

property: PROPERTY IDENT IDENT CRLF {
            RULE(property, T(PROPERTY) T(IDENT) T(IDENT) T(CRLF));
            $$ = new_property($2, $3);
        }
        | PROPERTY LIST IDENT IDENT IDENT CRLF {
            RULE(property, T(PROPERTY) T(LIST) T(IDENT) T(IDENT) T(IDENT) T(CRLF));
            $$ = new_list_property($3, $4, $5);
        }
        
%%

#if DEBUG
int main()
{
    yyparse();
}
#endif

int yyerror(const char *s)
{
    fprintf(stderr, F("%s\n"), s);
    return 0;
} /* yyerror */

PlyProperty *new_property(PlyToken *type, PlyToken *name)
{
    PlyProperty *res = ply_malloc(sizeof *res);
    assert(res != NULL);
    return res;
} /* new_list_property */

PlyProperty *new_list_property(PlyToken *size_type, PlyToken *elem_type, PlyToken *name)
{
    PlyProperty *res = ply_malloc(sizeof *res);
    assert(res != NULL);
    return res;
} /* new_list_property */
