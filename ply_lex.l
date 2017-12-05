%{
/* ply_lex.l --- scanner for the header of a ply file.
 * Author: Luis Colorado <luiscoloradourcola@gmail.com>
 * Date: Tue Dec  5 11:44:07 EET 2017
 */

#include <ply.h>

#ifndef DEBUG
#define DEBUG 0
#endif

#if DEBUG
#define F(fmt) __FILE__":%d:%s:" fmt, __LINE__, __func__
#define RETURN(tok) fprintf(stderr, F("[" #tok "]<%s>\n"), yytext)
#else
#define RETURN(tok) return (PLY_TOK_ ## tok)
#endif

%}
%option noyywrap
%x TEXT
crlf    \r?\n
sp      [ \t]+
ply     ^ply{crlf}
fmt     ^format
com     ^comment{sp}
oi      ^obj_info{sp}
txt     [^ \t\r\n]([ \t]*[^ \t\r\n])*
elm     ^element
prp     ^property
end     ^end_header{crlf}
num     [0-9][0-9]*
sig     [+-]{num}
flt     [+-]?({num}\.[0-9]*|[0-9]*\.{num})([eEdD][+-]?{num})?
id      [a-zA-Z_][a-zA-Z0-9_]*
str     \"([^"\n\\]|\\.)*\"
%%
{ply}               { RETURN(PLY); }
{fmt}               { RETURN(FORMAT); }
{com}               { BEGIN(TEXT); RETURN(COMMENT); }
{oi}                { BEGIN(TEXT); RETURN(OBJECT_INFO); }
<TEXT>{txt}         { BEGIN(INITIAL); RETURN(TEXT); }
{num}               { RETURN(UNSLIT); }
{sig}               { RETURN(SIGLIT); }
{flt}               { RETURN(FLTLIT); }
{str}               { RETURN(STRLIT); }
{elm}               { RETURN(ELEMENT); }
{prp}               { RETURN(PROPERTY); }
{end}               { RETURN(END_HEADER); }
{id}                { RETURN(IDENT); }
{sp}                ;
{crlf}              { RETURN(CRLF); }
.                   { RETURN(SYMBOL); }
%%

#if DEBUG
int main()
{
    yylex();
}
#endif 
