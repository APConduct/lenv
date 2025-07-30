-- lenv/cli.lua
-- CLI wrapper for lenv: prints export/set lines for shell eval integration

local env = require("lenv.src.lenv")

-- Usage: lua lenv/cli.lua [path/to/.env]
local filepath = arg[1] or ".env"

local parsed, warnings = env.load(filepath)
if not parsed then
    io.stderr:write("Failed to load env file: " .. tostring(warnings and warnings[1] or "unknown error") .. "\n")
    os.exit(1)
end

-- Optionally print warnings to stderr
if warnings and #warnings > 0 then
    if type(warnings) == "table" then
        for _, warning in ipairs(warnings) do
            io.stderr:write("Warning: " .. warning .. "\n")
        end
    end
end

-- Print export/set lines for shell integration
env.export(parsed, { mode = "eval" })

--[[
Example usage:

# In bash/zsh/fish (Unix):
eval "$(lua lenv/cli.lua path/to/.env)"

# In Windows Command Prompt:
for /f "delims=" %a in ('lua lenv/cli.lua path\to\.env') do @%a

# If your .env is in the current directory, just:
eval "$(lua lenv/cli.lua)"
]]
