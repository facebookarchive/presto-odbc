
DC = dmd

LIB_PATH = \"C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin\amd64\ \"
LIB_FLAGS = -Luser32.lib

CFLAGS = -c
FLAGS = -g -version=UNICODE -m64

SQL_MODULES = odbcinst sql sqlext sqltypes sqlucode
MODULES = driver handles bindings columnresults tableinfo prestoresults typeinfo getinfo util $(SQL_MODULES)
DAPI_MODULES = statementclient queryresults mockcurl util json

PROGRAM = presto.dll
TEST_PROGRAM = unittests

.PHONY: all
all: inone

.PHONY: inone
inone:
	$(DC) $(LIB_FLAGS) $(FLAGS) $(MODULES) $(addprefix ../dapi/, $(DAPI_MODULES)) -shared driver.def

.PHONY: testsinone
testsinone:
	$(DC) -unittest $(LIB_FLAGS) $(FLAGS) $(MODULES) $(addprefix ../dapi/, $(DAPI_MODULES)) -of$(TEST_PROGRAM)

.PHONY: copy
copy:
	cp $(PROGRAM) /cygdrive/c/temp/$(PROGRAM)
	rm -f /cygdrive/c/temp/SQL.LOG
	mv -f /cygdrive/c/temp/presto_odbc.log /cygdrive/c/temp/presto_odbc.last.log

.PHONY: logdiff
logdiff:
	sdiff --text /cygdrive/c/temp/presto_odbc.log /cygdrive/c/temp/presto_odbc.last.log

.PHONY: clean
clean:
	rm -f *.obj *.exp *.lib *.ilk *.pdb $(PROGRAM) $(TEST_PROGRAM)
