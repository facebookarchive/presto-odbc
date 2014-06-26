
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

MODULES = main statementclient queryresults mockcurl util json
OBJS = $(addsuffix .prod.$(OBJ_SUFFIX), $(MODULES))
TEST_OBJS = $(addsuffix .unit.$(OBJ_SUFFIX), $(MODULES))

PROGRAM = odbc
TEST_PROGRAM = unittests

.PHONY: default
default: $(PROGRAM) $(TEST_PROGRAM)

$(PROGRAM): $(OBJS)
	$(DC) $(LIB_FLAGS) $(FLAGS) $(OBJS) -of$(PROGRAM)

$(TEST_PROGRAM): $(TEST_OBJS)
	$(DC) $(LIB_FLAGS) $(FLAGS) $(TEST_OBJS) -of$(TEST_PROGRAM)

%.prod.$(OBJ_SUFFIX): %.d
	$(DC) $(CFLAGS) $(FLAGS) $< -of$@

%.unit.$(OBJ_SUFFIX): %.d
	$(DC) $(CFLAGS) $(FLAGS) -unittest $< -of$@

.PHONY: clean
clean:
	rm -f *.$(OBJ_SUFFIX) $(PROGRAM) $(TEST_PROGRAM) *.ilk *.pdb
