package = "lenv"
version = "0.2.0-1"
source = {
   url = "git+https://github.com/APConduct/lenv.git",
   tag = "v0.2.0"
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
   },
   install = {
      bin = {
         ["lenv"] = "lenv/cli.lua"
      }
   }
}
