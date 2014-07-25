VS_HOME = C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC
LIBCURL = /cygdrive/c/D/dmd2/windows/bin64/libcurl.dll
TEMP = /cygdrive/c/temp
LOGFILE = $(TEMP)/presto_odbc.log

DC = LINKCMD64="$(VS_HOME)\bin\link.exe" dmd
CFLAGS = -c
FLAGS = -g -version=UNICODE -m64 -Luser32.lib
LIB_FLAGS = -Luser32.lib

SQL_MODULES = odbcinst sql sqlext sqltypes sqlucode
MODULES = driver handles bindings columnresults tableinfo prestoresults typeinfo getinfo util $(SQL_MODULES)
DAPI_MODULES = statementclient queryresults prestoerrors mockcurl util json

PROGRAM = presto.dll
TEST_PROGRAM = unittests

.PHONY: all driver tests copy logdiff clean

all: driver

driver:
	$(DC) $(LIB_FLAGS) $(FLAGS) $(MODULES) $(addprefix ../dapi/, $(DAPI_MODULES)) -shared -of$(PROGRAM)

tests:
	$(DC) -unittest $(LIB_FLAGS) $(FLAGS) $(MODULES) $(addprefix ../dapi/, $(DAPI_MODULES)) -of$(TEST_PROGRAM)

copy:
	mkdir -p $(TEMP)
	cp $(PROGRAM) $(TEMP)/$(PROGRAM)
	cp $(LIBCURL) $(TEMP)/
	rm -f $(TEMP)/SQL.LOG
	if [ -f $(LOGFILE) ]; then mv $(LOGFILE) $(LOGFILE).old; fi

logdiff:
	sdiff --text $(LOGFILE) $(LOGFILE).old

clean:
	rm -f *.obj *.exp *.lib *.ilk *.pdb $(PROGRAM) $(TEST_PROGRAM)
