local env = require("lenv")

local loaded, err = env.load("./tests/1/.env")

if loaded then
    print("Loaded:\nfoo = " .. loaded.foo, '\nbar = ' .. loaded.bar)
end
