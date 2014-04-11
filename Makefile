
all:
	gcc cutil.c -o cutil.so -shared -llua -lcurses

clean:
	rm cutil.so

