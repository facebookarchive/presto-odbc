
DC = dmd

LIB_PATH = \"C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin\amd64\ \"
LIB_FLAGS = -Luser32.lib # -L-LIBPATH:"$(LIB_PATH)" -v

CFLAGS = -c
FLAGS = -g -version=UNICODE -m64

MODULES = driver util odbcinst sql sqlext sqltypes sqlucode
OBJS = $(addsuffix .prod.obj, $(MODULES))
TEST_OBJS = $(addsuffix .unit.obj, $(MODULES))

PROGRAM = ODBCDRV1.dll
TEST_PROGRAM = unittests

.PHONY: all
all: $(PROGRAM) $(TEST_PROGRAM)

$(PROGRAM): $(OBJS)
	$(DC) $(LIB_FLAGS) $(FLAGS) $(OBJS) -shared driver.def

$(TEST_PROGRAM): $(TEST_OBJS)
	$(DC) $(LIB_FLAGS) $(FLAGS) $(TEST_OBJS) -of$(TEST_PROGRAM)

%.prod.obj: %.d
	$(DC) $(CFLAGS) $(FLAGS) -shared $< -of$@

%.unit.obj: %.d
	$(DC) $(CFLAGS) $(FLAGS) -unittest $< -of$@

.PHONY: copy
copy:
	cp $(PROGRAM) C:\\TEMP\\$(PROGRAM)
	rm C:\\Users\\markisaa\\Desktop\\SQL.LOG

.PHONY: clean
clean:
	rm -f *.obj *.exp *.lib *.ilk *.pdb $(PROGRAM) $(TEST_PROGRAM)
