
CC = dmd

LIB_FLAGS = -L-lphobos2 -L-lcurl

CFLAGS = -c
FLAGS = -g -unittest

OBJS = main.o statementclient.o queryresults.o mockcurl.o util.o json.o

PROGRAM = odbc

.PHONY: default
default: $(PROGRAM)

$(PROGRAM): $(OBJS)
	$(CC) $(LIB_FLAGS) $(FLAGS) $(OBJS) -of$(PROGRAM)

%.o: %.d
	$(CC) $(CFLAGS) $(FLAGS) $<

.PHONY: clean
clean:
	rm f *.o $(PROGRAM)
