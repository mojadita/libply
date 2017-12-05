# PLY geometry file filters

COPTIONS = -g
CP_FLAGS = 
CFLAGS = -I. $(COPTIONS) $(CP_FLAGS)
LIBS = -lm
RM ?= rm -f
TOCLEAN?=
OBJS?=

TARGETS= ply2ascii ply2binary xformply ply2iv sphereply \
		 platoply boundply obj2ply flipply normalsply headply ply_lex

all: $(TARGETS)
TOCLEAN+=$(TARGETS)
clean:
	$(RM) $(TOCLEAN)

common_objs = ply.o
OBJS+=$(common_objs)

ply_lex_objs = ply_lex_d.o
ply_lex: $(ply_lex_objs)
	$(CC) $(LDFLAGS) -o $@ $($@_objs) $(common_objs) $(LIBS)

ply_lex_d.o: ply_lex.c ply.h
	$(CC) $(CFLAGS) -DDEBUG=1 -c ply_lex.c -o $@ 


headply_objs = headply.o
OBJS+=$(headply_objs)
headply: $(headply_objs) $(common_objs)
	$(CC) $(LDFLAGS) -o $@ $($@_objs) $(common_objs) $(LIBS)

flipply_objs = flipply.o
OBJS+=$(flipply_objs)
flipply: $(flipply_objs) $(common_objs)
	$(CC) $(LDFLAGS) -o $@ $($@_objs) $(common_objs) $(LIBS)

normalsply_objs = normalsply.o
OBJS+=$(normalsply_objs)
normalsply: $(normalsply_objs) $(common_objs)
	$(CC) $(LDFLAGS) -o $@ $($@_objs) $(common_objs) $(LIBS)

obj2ply_objs = obj2ply.o
OBJS+=$(obj2ply_objs)
obj2ply: $(obj2ply_objs) $(common_objs)
	$(CC) $(LDFLAGS) -o $@ $($@_objs) $(common_objs) $(LIBS)

boundply_objs = boundply.o
OBJS+=$(boundply_objs)
boundply: $(boundply_objs) $(common_objs)
	$(CC) $(LDFLAGS) -o $@ $($@_objs) $(common_objs) $(LIBS)

platoply_objs = platoply.o
OBJS+=$(platoply_objs)
platoply: $(platoply_objs) $(common_objs)
	$(CC) $(LDFLAGS) -o $@ $($@_objs) $(common_objs) $(LIBS)

sphereply_objs = sphereply.o
OBJS+=$(sphereply_objs)
sphereply: $(sphereply_objs) $(common_objs)
	$(CC) $(LDFLAGS) -o $@ $($@_objs) $(common_objs) $(LIBS)

ply2iv_objs = ply2iv.o
OBJS+=$(ply2iv_objs)
ply2iv: $(ply2iv_objs) $(common_objs)
	$(CC) $(LDFLAGS) -o $@ $($@_objs) $(common_objs) $(LIBS)

xformply_objs = xformply.o
OBJS+=$(xformply_objs)
xformply: $(xformply_objs) $(common_objs)
	$(CC) $(LDFLAGS) -o $@ $($@_objs) $(common_objs) $(LIBS)

ply2ascii_objs = convertply_a.o
OBJS+=$(ply2ascii_objs)
ply2ascii: $(ply2ascii_objs) $(common_objs)
	$(CC) $(LDFLAGS) -o $@ $($@_objs) $(common_objs) $(LIBS)

ply2binary_objs = convertply_b.o
OBJS+=$(ply2binary_objs)
ply2binary: $(ply2binary_objs) $(common_objs)
	$(CC) $(LDFLAGS) -o $@ $($@_objs) $(common_objs) $(LIBS)

convertply_a.o: convertply.c ply.h
	$(CC) $(CFLAGS) -o $@ -DWRITE_ASCII=1 -c convertply.c
convertply_b.o: convertply.c ply.h
	$(CC) $(CFLAGS) -o $@ -DWRITE_BINARY=1 -c convertply.c 

OBJS+=$(common_objs)
TOCLEAN+=$(OBJS)
$(OBJS): ply.h
