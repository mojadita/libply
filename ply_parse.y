%{
/* ply_parse.y --- parser for the header of the ply file.
 * Author: Luis Colorado <luiscoloradourcola@gmail.com>
 * Date: Wed Dec  6 15:40:53 EET 2017
 */

#include "ply.h"
#include "ply_parse.h"
#include "ply_lex.h"

#define YYERROR_VERBOSE 1

#define F(arg) __FILE__":%d:%s:" arg, __LINE__, __func__

#define RULE(left, right) do {         \
        printf(                        \
            F(" \033[1;33m" #left      \
            "\033[1;31m <==\033[m"     \
            right "\033[m\n"),         \
            __LINE__);                 \
    } while(0)

#define T(arg) " \033[36m" #arg
#define N(arg) " \033[32m" #arg
#define EMPTY  " \033[34m/* empty */"
#define ERROR  " \033[31m<<ERROR>>"

%}

%token PLY FORMAT COMMENT OBJ_INFO
%token ELEMENT PROPERTY LIST END_HEADER CRLF
%token <tok> IDENT UNSLIT SIGLIT FLTLIT STRLIT TEXT

%union {
   struct PlyToken *tok; 
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
        }
        | PROPERTY LIST IDENT IDENT IDENT CRLF {
            RULE(property, T(PROPERTY) T(LIST) T(IDENT) T(IDENT) T(IDENT) T(CRLF));
        }
        
%%

#if DEBUG
int main()
{
    yyparse();
}
#endif

int yyerror(char *s)
{
    fprintf(stderr, F("%s\n"), s);
} /* yyerror */
