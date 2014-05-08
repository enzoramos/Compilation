CC=gcc
CFLAGS=-Wall  -g 
LDFLAGS=-Wall -ll
EXEC=s_compilator

all: $(EXEC) clean

$(EXEC): $(EXEC).o lex.yy.o
	gcc  -o $@ $^ $(LDFLAGS)

$(EXEC).c: $(EXEC).y
	bison -d -o $(EXEC).c $(EXEC).y

$(EXEC).h: $(EXEC).c

lex.yy.c: $(EXEC).lex $(EXEC).h
	flex $(EXEC).lex

lex.yy.o:lex.yy.c
	gcc -o $@ -c $<

%.o: %.c
	gcc -o $@ -c $< $(CFLAGS)

clean:
	rm -f *.o lex.yy.c $(EXEC).[ch]
