package = "lenv"
version = "0.1.0-1"
source = {
   url = "git+https://github.com/APConduct/lenv.git",
   tag = "v0.1.0"
}
description = {
   summary = "Cross-platform .env file parser and loader for Lua",
   homepage = "https://github.com/APConduct/lenv",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["lenv"] = "lenv/init.lua",
      ["lenv.src.lenv"] = "lenv/src/lenv.lua"
   },
   install = {
      bin = {
         ["lenv"] = "lenv/cli.lua"
      }
   }
}
