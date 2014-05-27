
CC = dmd

LIB_FLAGS = -L-lphobos2 -L-lcurl

CFLAGS = -c
FLAGS = -g

OBJS = queryresults.o util.o json.o

PROGRAM = odbc

default: $(PROGRAM)

$(PROGRAM): main.d $(OBJS)
	$(CC) $(LIB_FLAGS) $(FLAGS) $(OBJS) main.d -of$(PROGRAM)

queryresults.o: queryresults.d
	$(CC) $(CFLAGS) $(FLAGS) queryresults.d

util.o: util.d
	$(CC) $(CFLAGS) $(FLAGS) util.d

json.o: json.d
	$(CC) $(CFLAGS) $(FLAGS) json.d

clean:
	rm -rf *.o *~ $(PROGRAM)
