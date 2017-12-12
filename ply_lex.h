/* ply_lex.h --- definitions for the lexical scanner.
 * Author: Luis Colorado <luiscoloradourcola@gmail.com>
 * Date: Wed Dec  6 15:52:36 EET 2017
 */
#ifndef _PLY_LEX_H
#define _PLY_LEX_H

typedef struct PlyToken PlyToken;

struct PlyToken {
    int          t_line;    /* line where this token was found */
    char        *t_raw;     /* raw token string */
    int          t_type;    /* token type (from parser) */
    int          t_nref;    /* number of references to this token */
    PlyToken    *t_prev;    /* double linked list */
    PlyToken    *t_next;    /* '' */
    union {
        char            *ident;
        unsigned long    unslit;
        signed long      siglit;
        double           fltlit;
        char            *strlit;
        char            *text;
        char             symbol;
    }            t_val;
};

typedef struct PlyTokenList PlyTokenList;

struct PlyTokenList {
    int         tl_lineno;
    size_t      tl_size;
    PlyToken   *tl_first;
    PlyToken   *tl_last;
};

int yylex();

#define ply_malloc(p) plymalloc(p, __FILE__, __LINE__, __func__)
#define ply_strdup(p) plystrdup(p, __FILE__, __LINE__, __func__)
#define ply_strfree(p) plystrfree(p, __FILE__, __LINE__, __func__)
#define ply_free(p) plyfree(p, __FILE__, __LINE__, __func__)
void *plymalloc(size_t sz, const char* file, const int line, const char*func);
char *plystrdup(const char*old, const char* file, const int line, const char*func);
void  plyfree(void* ptr, const char* file, const int line, const char*func);
void  plystrfree(char* ptr, const char* file, const int line, const char*func);

#endif /* _PLY_LEX_H */
