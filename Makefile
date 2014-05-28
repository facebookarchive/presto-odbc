
CC = dmd

LIB_FLAGS = -L-lphobos2 -L-lcurl

CFLAGS = -c
FLAGS = -g

OBJS = statementclient.o queryresults.o mockcurl.o util.o json.o

PROGRAM = odbc

default: $(PROGRAM)

$(PROGRAM): main.d $(OBJS)
	$(CC) $(LIB_FLAGS) $(FLAGS) $(OBJS) main.d -of$(PROGRAM)

statementclient.o: statementclient.d
	$(CC) $(CFLAGS) $(FLAGS) statementclient.d

queryresults.o: queryresults.d
	$(CC) $(CFLAGS) $(FLAGS) queryresults.d

mockcurl.o: mockcurl.d
	$(CC) $(CFLAGS) $(FLAGS) mockcurl.d

util.o: util.d
	$(CC) $(CFLAGS) $(FLAGS) util.d

json.o: json.d
	$(CC) $(CFLAGS) $(FLAGS) json.d

clean:
	rm -rf *.o *~ $(PROGRAM)
