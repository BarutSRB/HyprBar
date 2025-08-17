CFLAGS = -std=c99 -Wall -fvisibility=hidden -mmacosx-version-min=10.13
ODIR = bin
SRC = ram_load.c

ram_load: $(SRC)
	mkdir -p $(ODIR)
	clang $(CFLAGS) -O3 $^ -o $(ODIR)/ram_load

.PHONY: clean

clean:
	rm -rf $(ODIR)