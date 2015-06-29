# makefile for aes library for Lua

# change these to reflect your Lua installation
LUA= /usr
LUAINC= $(LUA)/include/lua5.1
LUALIB= $(LUA)/lib
LUABIN= $(LUA)/bin
MYNAME= lfcgi
# no need to change anything below here
CFLAGS= $(INCS) $(DEFS) $(WARN) -O2 -march=i486 -mtune=generic -pipe
LDFLAGS= 
WARN= #-ansi -pedantic -Wall
INCS= -I$(LUAINC) 

MYLIB= $(MYNAME)
T= $(MYLIB).so
OBJS= $(MYLIB).o
LIBS= -lfcgi 
CC=gcc

all:	so

o:	$(MYLIB).o

so:	$T

$T:	$(OBJS) 
	$(CC) -o $@ -shared $(OBJS) $(LIBS) $(LDFLAGS)
	strip $@

clean:
	rm -f $(OBJS) $T core core.* a.out 

doc:
	@echo "$(MYNAME) library:"
	@fgrep '/**' $(MYLIB).c | cut -f2 -d/ | tr -d '*' | sort | column

