#include <lua.h>
#include <lauxlib.h>
#include <stdio.h>

static int mtest1(lua_State * L){
	printf("========= mtest1\n");
	return 0;
}

static int mtest2(lua_State * L){
	int num = luaL_checkinteger(L,1);
	printf("========= mtest2 ;num = %d \n",num);
	return 0;
}

int luaopen_mylib(lua_State * L){
	luaL_Reg l[] = {
		{"test1",mtest1},
		{"test2",mtest2},
		{NULL,NULL}
	};

	luaL_newlib(L,l);
	return 1;
}