
CC = dmd

LIB_FLAGS = -L-lphobos2 -L-lcurl

CFLAGS = -c
FLAGS = -g

OBJS = main.prod.o statementclient.prod.o queryresults.prod.o mockcurl.prod.o util.prod.o json.prod.o
TEST_OBJS = main.unit.o statementclient.unit.o queryresults.unit.o mockcurl.unit.o util.unit.o json.unit.o

PROGRAM = odbc
TEST_PROGRAM = unittests

.PHONY: default
default: $(PROGRAM) $(TEST_PROGRAM)

$(PROGRAM): $(OBJS)
	$(CC) $(LIB_FLAGS) $(FLAGS) $(OBJS) -of$(PROGRAM)

$(TEST_PROGRAM): $(TEST_OBJS)
	$(CC) $(LIB_FLAGS) $(FLAGS) $(TEST_OBJS) -of$(TEST_PROGRAM)

%.prod.o: %.d
	$(CC) $(CFLAGS) $(FLAGS) $< -of$@

%.unit.o: %.d
	$(CC) $(CFLAGS) $(FLAGS) -unittest $< -of$@

.PHONY: clean
clean:
	rm f *.o $(PROGRAM) $(TEST_PROGRAM)
