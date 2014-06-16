
#dmd cversion.d cversion.def sqlucode.d sqlext.d sqltypes.d odbcinst.d -m64 -shared -g -version=UNICODE -Luser32.lib

CC = dmd

LIB_PATH = \"C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin\amd64\ \"
LIB_FLAGS = -Luser32.lib # -L-LIBPATH:"$(LIB_PATH)" -v

CFLAGS = -c
FLAGS = -g -version=UNICODE -m64

OBJS = driver.prod.obj odbcinst.prod.obj sql.prod.obj sqlext.prod.obj sqltypes.prod.obj sqlucode.prod.obj
TEST_OBJS = driver.unit.obj odbcinst.unit.obj sql.unit.obj sqlext.unit.obj sqltypes.unit.obj sqlucode.unit.obj

PROGRAM = ODBCDRV1.dll
TEST_PROGRAM = unittests

.PHONY: default
default: $(PROGRAM) $(TEST_PROGRAM)

$(PROGRAM): $(OBJS)
	$(CC) $(LIB_FLAGS) $(FLAGS) $(OBJS) -shared driver.def

$(TEST_PROGRAM): $(TEST_OBJS)
	$(CC) $(LIB_FLAGS) $(FLAGS) $(TEST_OBJS) -of$(TEST_PROGRAM)

%.prod.obj: %.d
	$(CC) $(CFLAGS) $(FLAGS) -shared $< -of$@

%.unit.obj: %.d
	$(CC) $(CFLAGS) $(FLAGS) -unittest $< -of$@

.PHONY: copy
copy:
	cp $(PROGRAM) C:\\TEMP\\$(PROGRAM); rm C:\\Users\\markisaa\\Desktop\\SQL.LOG;

.PHONY: clean
clean:
	rm -f *.obj *.exp *.lib *.ilk *.pdb $(PROGRAM) $(TEST_PROGRAM)
