--- Cross-platform .env file parser for Lua

-- lenv.lua - Cross-platform .env file parser for Lua




local lenv = {}
lenv._VERSION = "0.1.0"
lenv._DESCRIPTION = "Cross-platform .env file parser for Lua"

--- Detect the current operating system.
-- @return sreing "windows", "unix", or "unknown"
local function detect_os()
    local path_sep = package.config:sub(1, 1)
    if path_sep == '\\' then
        return 'windows'
    elseif path_sep == '/' then
        return 'unix'
    else
        return 'unknown'
    end
end

--- Escape a string value for shell usage.
---@param value string The value to escape.
---@param os_type string The operating system type
---@return string the escaped value
local function esc_val(value, os_type)
    if os_type == "windows" then
        return '"' .. value:gsub('"', '""') .. '"'
    else
        return "'" .. value:gsub("'", "'\"'\"'") .. "'"
    end
end

--- Validate an environment variable key
---@param key string The key to validate.
---@return boolean True if the key is valid, false otherwise
local function is_valid_key(key)
    return key and key:match("^[A-Za-z_][A-Za-z0-9_]*$") ~= nil
end

--- Parse .env file content into a table
---@param content string|nil The raw content of the .env file.
---@return table|nil A table of key-value pairs.
---@return table|nil an Array of parsing warnings/errors
function lenv.parse(content)
    if type(content) ~= "string" then
        return nil, { "Content must be a string" }
    end

    local result = {}
    local warnings = {}
    local line_number = 0

    -- Normalize all line endings to \n
    content = content:gsub("\r\n", "\n"):gsub("\r", "\n")
    for line in (content .. "\n"):gmatch("(.-)\n") do
        line_number = line_number + 1

        -- Trim whitespace
        line = line:match("^%s*(.-)%s*$")

        -- Skip empty lines and comments
        if line ~= "" and not line:match("^#") then
            local key, value = line:match("^([^=]+)=(.*)$")

            if key then
                key = key:match("^%s*(.-)%s*$")
                value = value or ""

                -- Only add non-empty, valid keys
                if not (key and key ~= "" and is_valid_key(key)) then
                    table.insert(warnings, string.format("Line %d: Invalid key format '%s'", line_number, key))
                else
                    -- Handle quoted values
                    if value:match('^".*"$') then
                        -- Remove double quotes and handle escape sequences
                        value = value:sub(2, -2):gsub('\\(.)', function(c)
                            if c == 'n' then
                                return '\n'
                            elseif c == 't' then
                                return '\t'
                            elseif c == 'r' then
                                return '\r'
                            elseif c == '\\' then
                                return '\\'
                            elseif c == '"' then
                                return '"'
                            else
                                return '\\' .. c
                            end
                        end)
                    elseif value:match("^'.*'$") then
                        -- Remove single quotes (no escape processing)
                        value = value:sub(2, -2)
                    end

                    -- Handle variable expansion (basic ${VAR} syntax format)
                    value = value:gsub("%${([A-Za-z_][A-Za-z0-9_]*)}", function(var_name)
                        return result[var_name] or os.getenv(var_name) or ""
                    end)
                    result[key] = value
                end
            else
                table.insert(warnings, string.format("Line %d: Invalid format '%s'", line_number, line))
            end
        end
    end
    return result, warnings
end

--- Load and parse a .env file
---@param filepath string|nil Path to the .env file.
---@return table|nil Parsed environment variables or a nil if an error occurred.
---@return string|table Error message or or warnings array
function lenv.load(filepath)
    if type(filepath) ~= "string" then
        return nil, "Filepath must be a string"
    end

    local file, err = io.open(filepath, "r")
    if not file then
        return nil, "Could not open file '" .. filepath .. "': " .. (err or "unknown error")
    end

    local content = file:read("*all")
    file:close()

    if not content then
        return nil, "Could not read file content from '" .. filepath .. "'"
    end

    local parsed, warnings = lenv.parse(content)
    if not parsed then
        -- lenv.parse returns nil, {errors} on failure
        return nil, warnings or "Unknown parse error"
    end
    return parsed, warnings or {}
end

--- Export environment variables (using the most practical approach)
--- This function generates shell scripts and instructions since lua cannot directly modify the parent shell's environment variables
---@param parsed_env table|any The parsed environment variables
---@param options table|nil Options for enxport behavior
---@return number Number of successfully exported/processed variables
---@return table Array of error messages
---@return table Additional outputs (scripts, instructions, etc.)
---@usage local count, errors, outputs = lenv..export(parsed, {script_file = "set_env.sh"})
function lenv.export(parsed_env, options)
    if type(parsed_env) ~= "table" then
        return 0, { "parsed_env must be a table" }, {}
    end

    options = options or {}
    local success_count = 0
    local errors = {}
    local outputs = {}
    local os_type = detect_os()

    -- Collect valid variables
    local valid_vars = {}
    for key, value in pairs(parsed_env) do
        if is_valid_key(key) then
            valid_vars[key] = tostring(value)
            success_count = success_count + 1
        else
            table.insert(errors, "Invalid key format: " .. tostring(key))
        end
    end

    local script_lines = {}

    if options.mode == "eval" then
        -- Eval mode: print export/set lines for shell eval integration
        local eval_lines = {}
        if os_type == "windows" then
            for key, value in pairs(valid_vars) do
                table.insert(eval_lines, string.format("set %s=%s", key, value))
            end
        else
            for key, value in pairs(valid_vars) do
                table.insert(eval_lines, string.format("export %s=%s", key, esc_val(value, "unix")))
            end
        end
        outputs.eval_content = table.concat(eval_lines, "\n")
        print(outputs.eval_content)
        return success_count, errors, outputs
    end

    if os_type == "windows" then
        table.insert(script_lines, "@echo off")
        table.insert(script_lines, "REM Generated by lenv v" .. lenv._VERSION)
        table.insert(script_lines, "")

        for key, value in pairs(valid_vars) do
            if options.persistent then
                table.insert(script_lines, string.format("setx %s %s", key, esc_val(value, "windows")))
            else
                table.insert(script_lines, string.format("set %s=%s", key, value))
            end
        end
        outputs.script_extension = ".bat"
    else
        table.insert(script_lines, "#!/bin/sh")
        table.insert(script_lines, "# Generated by lenv v" .. lenv._VERSION)
        table.insert(script_lines, "")

        for key, value in pairs(valid_vars) do
            table.insert(script_lines, string.format("export %s=%s", key, esc_val(value, "unix")))
        end
        outputs.script_extension = ".sh"
    end
    outputs.script_content = table.concat(script_lines, "\n")

    -- Generate manual instructions
    outputs.instructions = {}
    for key, value in pairs(valid_vars) do
        if os_type == "windows" then
            table.insert(outputs.instructions, string.format("set %s=%s", key, value))
        else
            table.insert(outputs.instructions, string.format("export %s=%s", key, esc_val(value, "unix")))
        end
    end

    -- Write the script to a file if requested
    if options.script_file then
        local filename = options.script_file

        if not filename:match("%.[^.]*$") then
            filename = filename .. outputs.script_extension
        end

        local file, write_err = io.open(filename, "w")
        if file then
            file:write(outputs.script_content)
            file:close()
            outputs.script_file = filename

            -- Make executable if on Unix-like systems
            if os_type == "unix" then
                os.execute("chmod +x " .. filename)
            end
        else
            table.insert(errors, "Could not write script file '" .. filename .. "': " .. (write_err or "unknown error"))
        end
    end

    return success_count, errors, outputs
end

--- Print usage instructions for exported variables
-- @param outputs table The outputs from lenv.export()
-- @param options table Display options
function lenv.print_usage(outputs, options)
    options = options or {}
    local os_type = detect_os()

    if outputs.script_file then
        print("Environment script generated: " .. outputs.script_file)
        print("")
        print("To apply these environment variables, run:")
        if os_type == "windows" then
            print("  " .. outputs.script_file)
        else
            print("  source " .. outputs.script_file)
        end
        print("")
    elseif outputs.script_content then
        print("To apply these environment variables, save the following to a script file and run it:")
        print("")
        if os_type == "windows" then
            print("Save as .bat file and run:")
        else
            print("Save as .sh file and run with: source filename.sh")
        end
        print("")
        if not options.no_script_output then
            print(outputs.script_content)
        end
    end

    if outputs.instructions and #outputs.instructions > 0 and not options.no_manual_instructions then
        print("Or run these commands manually:")
        for _, instruction in ipairs(outputs.instructions) do
            print("  " .. instruction)
        end
        print("")
    end
end

--- Convenience function to load and export in one step
---@param filepath string Path to the .env file
---@param options table|nil Export options
---@return number Number of successfully processed variables
---@return table Array of error messages
---@return table Additional outputs
---@usage local count, errors, outputs = lenv.load_and_export(".env", {script_file = "set_env"})
function lenv.load_and_export(filepath, options)
    local parsed, load_errors = lenv.load(filepath)

    if not parsed then
        return 0, { load_errors }, {}
    end

    local count, export_errors, outputs = lenv.export(parsed, options)

    -- Combine any load warnings with export errors
    local all_errors = {}
    if type(load_errors) == "table" then
        for _, warning in ipairs(load_errors) do
            table.insert(all_errors, "Parse warning: " .. warning)
        end
    end
    for _, error in ipairs(export_errors) do
        table.insert(all_errors, error)
    end

    return count, all_errors, outputs
end

return lenv
