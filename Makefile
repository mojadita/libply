# PLY geometry file filters

COPTIONS = -g
CP_FLAGS = 
CFLAGS = -I. $(COPTIONS) $(CP_FLAGS)
LIBS = -lm
RM ?= rm -f
YACC = bison
TOCLEAN?=
OBJS?=

TARGETS= ply2ascii ply2binary xformply ply2iv sphereply \
		 platoply boundply obj2ply flipply normalsply headply \
		 ply_lex ply_parse

all: $(TARGETS)
TOCLEAN+=$(TARGETS)
clean:
	$(RM) $(TOCLEAN)

common_objs = ply.o
OBJS+=$(common_objs)
$(common_objs): ply.h

ply_lex_objs = ply_lex_d.o
$(ply_lex_objs): ply_lex.h ply_parse.h ply.h
ply_lex_libs = -ll

ply_lex_d.o: ply_lex.c ply_parse.h ply.h
	$(CC) $(CFLAGS) -DDEBUG=1 -c ply_lex.c -o $@ 
TOCLEAN += ply_lex.c

ply_parse.h ply_parse.c ply_parse.lst: ply_parse.y
	$(YACC) $(YFLAGS) --defines=ply_parse.h -o ply_parse.c --report=all \
		--report-file=ply_parse.lst ply_parse.y
TOCLEAN += ply_parse.h ply_parse.c ply_parse.lst

ply_parse_objs = ply_parse_d.o ply_lex_d.o
$(ply_parse_objs): ply.h ply_parse.h ply_lex.h
ply_parse_libs = -ly

ply_parse_d.o: ply_parse.c
	$(CC) $(CFLAGS) -DDEBUG=1 -o $@ -c ply_parse.c

headply_objs = headply.o
flipply_objs = flipply.o
normalsply_objs = normalsply.o
obj2ply_objs = obj2ply.o
boundply_objs = boundply.o
platoply_objs = platoply.o
sphereply_objs = sphereply.o
ply2iv_objs = ply2iv.o
xformply_objs = xformply.o
ply2ascii_objs = convertply_a.o
ply2binary_objs = convertply_b.o

convertply_a.o: convertply.c ply.h
	$(CC) $(CFLAGS) -o $@ -DWRITE_BINARY=0 -c convertply.c 
convertply_b.o: convertply.c ply.h
	$(CC) $(CFLAGS) -o $@ -DWRITE_BINARY=1 -c convertply.c 

.for tgt in $(TARGETS)
$(tgt): $($(tgt)_objs) $(common_objs)
	$(CC) $(LDFLAGS) -o $(tgt) $($(tgt)_objs) $(common_objs) $($(tgt)_libs) $(LIBS)
OBJS += $($(tgt)_objs)
.endfor

OBJS+=$(common_objs)
TOCLEAN+=$(OBJS)

$(OBJS): ply.h
