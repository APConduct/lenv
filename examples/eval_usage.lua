local env = require("lenv")

-- Example: Using eval mode to output shell commands for environment variables

-- Load .env file (default: .env in current directory)
local filepath = arg[1] or ".env"
local parsed, warnings = env.load(filepath)

if not parsed then
    io.stderr:write("Failed to load env file: " .. tostring(warnings and warnings[1] or "unknown error") .. "\n")
    os.exit(1)
end

-- Print warnings, if any
if warnings and #warnings > 0 then
    io.stderr:write("Warnings while parsing .env file:\n")
    for _, warning in ipairs(type(warnings) == "table" and warnings or {}) do
        io.stderr:write("  " .. warning .. "\n")
    end
end

-- Export in eval mode: prints export/set lines to stdout
env.export(parsed, { mode = "eval" })

--[[
USAGE:

# On Unix shells (bash, zsh, etc):
eval "$(lua lenv/examples/eval_usage.lua path/to/.env)"

# On Windows Command Prompt:
for /f "delims=" %a in ('lua lenv/examples/eval_usage.lua path\to\.env') do @%a

# If you omit the path, it defaults to ".env" in the current directory.
]]
