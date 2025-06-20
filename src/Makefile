CC = gcc
LEX = flex
YACC = bison

CFLAGS = -g
LDFLAGS = -lfl
YACCFLAGS = -vd

OBJECTS = lex.yy.o subc.tab.o symbol.o

all: subc

subc: $(OBJECTS)
	$(CC) -o subc $(OBJECTS) $(CFLAGS) $(LDFLAGS)

subc.tab.o: subc.tab.c subc.h symbol.h
	$(CC) -c $(CFLAGS) subc.tab.c

lex.yy.o: lex.yy.c subc.tab.h subc.h symbol.h
	$(CC) -c $(CFLAGS) lex.yy.c

symbol.o: symbol.c symbol.h
	$(CC) -c $(CFLAGS) symbol.c

lex.yy.c: subc.l
	$(LEX) subc.l

subc.tab.c subc.tab.h: subc.y
	$(YACC) $(YACCFLAGS) subc.y

clean:
	rm -f *.o lex.yy.c subc.tab.c subc.tab.h subc.output subc