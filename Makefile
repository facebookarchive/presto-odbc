VS_HOME = C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC
LIBCURL = /cygdrive/c/D/dmd2/windows/bin64/libcurl.dll
TEMP = /cygdrive/c/temp
LOGFILE = $(TEMP)/presto_odbc.log

MAKE_NSISW_CMD = "/cygdrive/c/Program Files (x86)/NSIS/makensis.exe"
MAKE_NSIS_FLAGS = /V4

DC = LINKCMD64="$(VS_HOME)\bin\link.exe" dmd
CFLAGS = -c
FLAGS = -g -w -version=UNICODE

ifeq ($(OS),Windows_NT)
	INSTALLER_DIR = installer/win
	INSTALLER_SCRIPT = $(INSTALLER_DIR)/installer.nsi
	INSTALLER_OUTPUT = $(INSTALLER_DIR)/*.exe
	
	FLAGS += -m64 -Luser32.lib
	
	PROGRAM = presto.dll
else
	FLAGS += -m32 -fPIC -L-lcurl
	
	PROGRAM = presto.dylib
endif

SOURCES = client/*.d odbc/*.d driver/*.d
TEST_SOURCES = $(SOURCES) test/*.d
TEST_PROGRAM = unittests

.PHONY: all driver tests copy logdiff clean

all: driver tests

driver:
	$(DC) $(FLAGS) $(SOURCES) -shared -of$(PROGRAM)

tests:
	$(DC) -unittest $(FLAGS) $(TEST_SOURCES) -of$(TEST_PROGRAM)

check: tests
	cp $(LIBCURL) .
	chmod 555 $(notdir $(LIBCURL))
	./$(TEST_PROGRAM)

install: driver check
	mkdir -p $(TEMP)
	cp $(PROGRAM) $(TEMP)/$(PROGRAM)
	cp $(LIBCURL) $(TEMP)/
	chmod 555 $(TEMP)/$(notdir $(LIBCURL))
	rm -f $(TEMP)/SQL.LOG
	if [ -f $(LOGFILE) ]; then mv $(LOGFILE) $(LOGFILE).old; fi
	@echo "Install complete"

logdiff:
	sdiff --text $(LOGFILE) $(LOGFILE).old

clean:
	rm -f *.obj *.exp *.lib *.ilk *.pdb $(PROGRAM) $(TEST_PROGRAM)
	rm -f $(INSTALLER_OUTPUT)

installer: driver check
	$(MAKE_NSISW_CMD) $(MAKE_NSIS_FLAGS) $(INSTALLER_SCRIPT)

