%{
/* ply_lex.l --- scanner for the header of a ply file.
 * Author: Luis Colorado <luiscoloradourcola@gmail.com>
 * Date: Tue Dec  5 11:44:07 EET 2017
 */

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#include "ply.h"
#include "ply_lex.h"
#include "ply_parse.h"

#ifndef DEBUG
#define DEBUG 0
#endif

#if DEBUG
#define F(fmt) __FILE__":%d:%s:" fmt, __LINE__, __func__
#define SYMBOL  (0)
#define RETURN(tok) do { \
        if (!tok) \
            printf(F("\033[1;37m[\033[36mEOF\033[37m]\033[m\n"));  \
        else if (isprint(tok) || isspace(tok))  \
            printf(F("\033[1;37m[\033[36mSYMBOL\033[37m]'\033[31m%c\033[37m'\033[m\n"), tok); \
        else if (tok < 32 || tok == 127) \
            printf(F("\033[1;37m[\033[36mSYMBOL\033[37m]<%02x\033[37m>\033[m\n"), tok); \
        else switch(tok) { \
        case CRLF: printf(F("\033[1;37m[\033[36mCRLF\033[37m]\033[m\n")); break; \
        case PLY: printf(F("\033[1;37m<<\033[36mPLY\033[37m>>\033[m\n")); break; \
        case END_HEADER: printf(F("\033[1;37m<<\033[36mEND_HEADER\033[37m>>\033[m\n\n")); break; \
        default: printf(F("\033[1;37m[\033[36m" #tok "\033[37m]<\033[31m%s\033[37m>\033[m\n"), yytext); break; \
        } /* switch */ \
    } while(0)

#else
#define SYMBOL  (yytext[0])
#define RETURN(par) do {                                       \
        yylval.tok = new_token(&ply_token_list, (par), yytext);\
        return (par);                                          \
    } while (0)
#endif

static PlyTokenList ply_token_list = {
    .tl_lineno = 1,
    .tl_size = 0,
    .tl_first = NULL,
    .tl_last = NULL,
};

PlyToken *new_token(PlyTokenList *the_list, int tok_type, char *raw);
void unescape(char *s1);
void free_token(PlyToken *the_token);

%}

%option noyywrap

%x hdr
%x txt
%x lst
%x bdy
%x err

crlf    \r?[\n\f\v]
sp      [ \t]+
ply     ^ply{crlf}
fmt     ^format
com     ^comment
oi      ^obj_info
txt     [^ \t\v\f\r\n]([ \t]*[^ \t\v\f\r\n])*
elm     ^element
prp     ^property
end     ^end_header{crlf}
num     [0-9][0-9]*
sig     [+-]{num}
flt     [+-]?({num}\.[0-9]*|[0-9]*\.{num})([eEdD][+-]?{num})?
id      [a-zA-Z_][a-zA-Z0-9_]*
lst     "list"
str     \"([^"\n\\]|\\.)*\"
%%
<INITIAL>{ply}      { BEGIN(hdr);       RETURN(PLY); }
<hdr>{fmt}          {                   RETURN(FORMAT); }
<hdr>{com}          { BEGIN(txt);       RETURN(COMMENT); }
<hdr>{oi}           { BEGIN(txt);       RETURN(OBJ_INFO); }
<txt>{txt}          { BEGIN(hdr);       RETURN(TEXT); }
<hdr,bdy>{num}      {                   RETURN(UNSLIT); }
<hdr,bdy>{sig}      {                   RETURN(SIGLIT); }
<hdr,bdy>{flt}      {                   RETURN(FLTLIT); }
<hdr,bdy>{str}      {                   RETURN(STRLIT); }
<hdr>{elm}          {                   RETURN(ELEMENT); }
<hdr>{prp}          { BEGIN(lst);       RETURN(PROPERTY); }
<lst>{lst}          { BEGIN(hdr);       RETURN(LIST); }
<hdr,lst>{id}       { BEGIN(hdr);       RETURN(IDENT); }
<hdr>{end}          { BEGIN(bdy);       RETURN(END_HEADER); }
<hdr,bdy,lst,txt>{sp}   ; /* ignored */
<hdr,bdy>{crlf}     {                   RETURN(CRLF); }
<INITIAL>.          { BEGIN(err);       RETURN(0); }
<err>.              {                   RETURN(0); }
<hdr,bdy>.          {                   RETURN(SYMBOL); }
%%

#if DEBUG
int main()
{
    yylex();
}
#endif 

PlyToken *
new_token(
        PlyTokenList *list,
        int tok_type,
        char *raw)
{
    int res;

    PlyToken *result = malloc(sizeof *result);
    assert(result != NULL);
    result->t_line = list->tl_lineno;
    result->t_raw = strdup(raw);
    result->t_type = tok_type;
    result->t_nref = 1;
    switch(tok_type) {
    case FORMAT: case COMMENT: case OBJ_INFO:
    case ELEMENT: case PROPERTY: case LIST:
        break;

    case PLY: case CRLF: case END_HEADER:
        list->tl_lineno++;
        break;

    case TEXT:
        result->t_val.text = strdup(raw);
        break;

    case UNSLIT:
        res = sscanf(raw, "%lu", &result->t_val.unslit);
        assert(res == 1);
        break;
    
    case SIGLIT:
        res = sscanf(raw, "%ld", &result->t_val.siglit);
        assert(res == 1);
        break;

    case FLTLIT:
        res = sscanf(raw, "%lg", &result->t_val.fltlit);
        assert(res == 1);
        break;

    case STRLIT:
        result->t_val.strlit = strdup(raw);
        unescape(result->t_val.strlit);
        break;

    } /* switch */

    /* link */
    result->t_prev = list->tl_last;
    if (!list->tl_last)
        list->tl_first = result;
    list->tl_last = result;
    result->t_next = NULL;

} /* new_token */

void free_token(PlyToken *tok)
{
    assert(tok->t_nref > 0);
    tok->t_nref--;
    if (tok->t_nref == 0) {
        free(tok->t_raw);
        switch(tok->t_type) {
        case IDENT: free(tok->t_val.ident);
        case STRLIT: free(tok->t_val.strlit);
        case TEXT: free(tok->t_val.text);
        } /* switch */
    }
    free(tok);
} /* free_token */

void
unescape(char *s1)
{
    char delim = *s1;
    char *s2 = 0;
}
