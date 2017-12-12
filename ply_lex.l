%{
/* ply_lex.l --- scanner for the header of a ply file.
 * Author: Luis Colorado <luiscoloradourcola@gmail.com>
 * Date: Tue Dec  5 11:44:07 EET 2017
 */

#include <assert.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

#include "ply.h"
#include "ply_lex.h"
#include "ply_parse.h"

#ifndef DEBUG
#define DEBUG 0
#endif

#define F(fmt) __FILE__":%d:%s:" fmt, __LINE__, __func__

#if DEBUG
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
int yylex();

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
str     \"([^"\n]|\"\")*\"
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
<INITIAL>.          { BEGIN(err);       RETURN(TOKERROR); }
<err>.              {                   RETURN(TOKERROR); }
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
    int lineno = list->tl_lineno;

    PlyToken *result = ply_malloc(sizeof *result);
    assert(result != NULL);

    result->t_line = lineno;
    result->t_raw = ply_strdup(raw);
    result->t_type = tok_type;
    result->t_nref = 1;
    result->t_prev = NULL;
    result->t_next = NULL;

    switch(tok_type) {
    case PLY: case CRLF: case END_HEADER:
        list->tl_lineno++;
        break;

    case TEXT:
        result->t_val.text = result->t_raw;
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
        result->t_val.strlit = ply_strdup(raw);
        unescape(result->t_val.strlit);
        break;

    case IDENT:
        result->t_val.ident = result->t_raw;
        break;
    } /* switch */

    /* link */
    result->t_prev = list->tl_last;
    if (list->tl_last == NULL)
        list->tl_first = result;
    list->tl_last = result;
    list->tl_size++;

    PlyToken *q, *p;
    while ((q = list->tl_first) != NULL && q->t_line < lineno) {
        /* unlink */
        p = list->tl_first = q->t_next;
        if (q->t_next) q->t_next->t_prev = NULL;
        else list->tl_last = NULL; /* empty */

        list->tl_size--;
        free_token(q);
    } /* while */

    return result;
        
} /* new_token */

void free_token(PlyToken *tok)
{
    assert(tok->t_nref > 0);
    tok->t_nref--;
    if (tok->t_nref == 0) {
        ply_strfree(tok->t_raw);
        switch(tok->t_type) {
        case STRLIT: ply_strfree(tok->t_val.strlit); break;
        } /* switch */
        ply_free(tok);
    } /* if */
} /* free_token */

void
unescape(char *s1)
{
    char delim = *s1;
    char *s2 = s1+1;
    char c, st = 0;

    while((c = *s2++) != 0) {
        if(st == 0) {
            if (c == delim) {
                st = 1; /* skip */
            } else {
                *s1++ = c; /* copy */
            }
        } else {
            *s1++ = c;
            st = 0;
        } /* else */
    } /* while */
    *s1 = 0;
} /* unescape */

void *plymalloc(size_t sz, const char* file, const int line, const char*func)
{
    void *res = malloc(sz);
    fprintf(stderr,
        F("MALLOC: %p, FILE=%s, LINE=%d, FUNC=%s\n"),
        res, file, line, func);
    return res;
} /* plymalloc */

char *plystrdup(const char*old, const char* file, const int line, const char*func)
{
    char *res = strdup(old);
    fprintf(stderr,
        F("STRDUP: %p, FILE=%s, LINE=%d, FUNC=%s, STRING=%s\n"),
        res, file, line, func, old);
    return res;
} /* plystrdup */

void  plystrfree(char* ptr, const char* file, const int line, const char*func)
{
    fprintf(stderr,
        F("FREE: %p, FILE=%s, LINE=%d, FUNC=%s, STRING=%s\n"),
        ptr, file, line, func, ptr);
    free(ptr);
} /* plystrfree */

void  plyfree(void* ptr, const char* file, const int line, const char*func)
{
    fprintf(stderr,
        F("FREE: %p, FILE=%s, LINE=%d, FUNC=%s\n"),
        ptr, file, line, func);
    free(ptr);
} /* plyfree */
