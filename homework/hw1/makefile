
a.out: sh.c
	gcc sh.c;

test: a.out	
	./a.out < test.sh;

.PHONY: clean
clean:
	rm a.out;