-- LuaRocks configuration

rocks_trees = {
   { name = "user", root = home .. "/.luarocks" };
   { name = "system", root = "/home/david/Projects/software/computercraft/.venv" };
}
lua_interpreter = "lua";
variables = {
   LUA_DIR = "/home/david/Projects/software/computercraft/.venv";
   LUA_BINDIR = "/home/david/Projects/software/computercraft/.venv/bin";
}
