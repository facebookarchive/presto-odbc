
CC = dmd

LIB_FLAGS = -L-lphobos2 -L-lcurl

CFLAGS = -c
FLAGS = -g

OBJS = json.o

PROGRAM = odbc

default: $(PROGRAM)

$(PROGRAM): main.d json.o
	$(CC) $(LIB_FLAGS) $(FLAGS) $(OBJS) main.d -of$(PROGRAM)

json.o: json.d
	$(CC) $(CFLAGS) $(FLAGS) json.d

clean:
	rm -rf *.o *~ $(PROGRAM)
