# lenv Usage Guide

This guide covers the recommended ways to use the `lenv` Lua package for both programmatic (Lua) and shell-based workflows, including ergonomic shell integration.

---

## 1. Using `lenv` in Lua Code

You can use `lenv` directly in your Lua scripts to parse, load, and export environment variables.

```lua
local env = require("lenv")

-- Parse .env content from a string
local parsed, warnings = env.parse([[
FOO=bar
HELLO=world
]])

-- Load from a .env file
local parsed, warnings = env.load(".env")

-- Use parsed variables in your Lua code
print(parsed.FOO)  -- prints 'bar'
```

---

## 2. Shell Integration: Setting Environment Variables in Your Shell

### a. One-off Usage with `eval`

You can use the CLI wrapper to set environment variables in your current shell session:

```sh
eval "$(lua lenv/cli.lua path/to/.env)"
```

- This will load variables from the specified `.env` file and set them in your current shell.
- If you omit the path, it defaults to `.env` in the current directory:
  ```sh
  eval "$(lua lenv/cli.lua)"
  ```

#### On Windows (Command Prompt):

```bat
for /f "delims=" %a in ('lua lenv/cli.lua path\to\.env') do @%a
```

---

### b. Ergonomic Shell Function

For convenience, add this function to your `~/.bashrc`, `~/.zshrc`, or equivalent:

```sh
loadenv() { eval "$(lua /full/path/to/lenv/cli.lua "$@")"; }
```

Now you can simply run:

```sh
loadenv .env
```
or just
```sh
loadenv
```
to load environment variables into your current shell session.

---

## 3. Generating Scripts for Sourcing

You can use `lenv` to generate a shell script that can be sourced:

```lua
local env = require("lenv")
local parsed = env.load(".env")
env.export(parsed, { script_file = "set_environment" })
```

Then, in your shell:

```sh
source set_environment.sh
```

Or on Windows:

```bat
call set_environment.bat
```

---

## 4. Example: Complete Workflow

**Lua script (`examples/eval_usage.lua`):**

```lua
local env = require("lenv")
local parsed, warnings = env.load(".env")
if not parsed then
    io.stderr:write("Failed to load .env: " .. tostring(warnings and warnings[1] or "unknown error") .. "\\n")
    os.exit(1)
end
env.export(parsed, { mode = "eval" })
```

**Shell usage:**

```sh
eval "$(lua examples/eval_usage.lua)"
```

---

## 5. Notes and Limitations

- **Why use `eval` or `source`?**  
  Due to OS process isolation, a Lua script (or any child process) cannot modify the parent shell's environment directly. Using `eval` or `source` is the only portable way to set environment variables in your current shell session.
- **Persistent variables on Windows:**  
  You can use the `setx` option in `lenv.export` to set persistent environment variables, but this does not affect the current shell session—only new ones.

---

## 6. Advanced: CLI Options

You can extend `lenv/cli.lua` to support additional options, such as:
- Generating scripts (`--script`)
- Printing only specific variables
- Showing help (`--help`)

---

## 7. Summary Table

| Use Case                | How to Use                                   | Notes                       |
|-------------------------|----------------------------------------------|-----------------------------|
| In Lua code             | `require('lenv').load('.env')`               | For Lua scripts/programs    |
| In shell (one-off)      | `eval "$(lua lenv/cli.lua .env)"`            | For current shell session   |
| In shell (convenience)  | `loadenv .env` (with shell function/alias)   | Add function to .bashrc     |
| Generate script         | Use `export` with script options             | For `source`/`setx` usage   |

---

For more examples, see the `examples/` directory in this project.

Happy env loading!