static int l_dir (lua_State * L){
	printf("%s\n", "test");
}

static const struct luaL_reg mylib []{

	{ "dir",l_dir },
	{NULL,NULL}
	
};

int luaopen_lib(lua_State * L){
	luaL_newlib(L , "mylib" , 0);
	return 1;
}