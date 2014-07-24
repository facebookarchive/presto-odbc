
DC = dmd

ifeq ($(OS),Windows_NT)
	LIB_FLAGS = -Lcurl.lib
	OBJ_SUFFIX = obj
else
	LIB_FLAGS = -L-lphobos2 -L-lcurl
	OBJ_SUFFIX = o
endif

CFLAGS = -c
FLAGS = -g -m64

MODULES = main statementclient queryresults prestoerrors mockcurl util json

PROGRAM = odbc
TEST_PROGRAM = unittests

.PHONY: all
all: inone

.PHONY: inone
inone:
	$(DC) $(LIB_FLAGS) $(FLAGS) $(MODULES) -of$(PROGRAM)

.PHONY: testsinone
testsinone:
	$(DC) -unittest $(LIB_FLAGS) $(FLAGS) $(MODULES) -of$(TEST_PROGRAM)

.PHONY: clean
clean:
	rm -f *.$(OBJ_SUFFIX) $(PROGRAM) $(TEST_PROGRAM) *.ilk *.pdb
