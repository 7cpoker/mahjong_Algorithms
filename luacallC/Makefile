CC ?= gcc  
CFLAGS = -g -O2 -Wall -I$(LUA_INC)  
SHARED := -fPIC --shared  

TARGET = mylib.so  
LUA_CLIB_PATH = ./


#引入lua头文件(根据你安装Lua库时的目录而定)

LUA_INC ?= /samba/secured/workspace/mj_fuzhou/haju/dependencies/skynet/3rd/lua

start: $(TARGET)  

$(TARGET) : ./mylib.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@  

clean:  
	rm -fr $(TARGET)  

$(LUA_CLIB_PATH) :  
	mkdir $(LUA_CLIB_PATH)
