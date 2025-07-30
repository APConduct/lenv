# lenv

A cross-platform `.env` file parser and environment loader for Lua.

- **Parse** and **load** environment variables from `.env` files.
- **Export** variables for use in your shell or scripts.
- **Works on Unix and Windows.**

---

## Quickstart

### In Lua code

```lua
local env = require("lenv")
local parsed, warnings = env.load(".env")
print(parsed.MY_KEY)
```

### In your shell (Unix)

```sh
eval "$(lua lenv/cli.lua .env)"
```

### In your shell (Windows Command Prompt)

```bat
for /f "delims=" %a in ('lua lenv/cli.lua path\to\.env') do @%a
```

### Add a shell function for convenience

Add to your `~/.bashrc` or `~/.zshrc`:

```sh
loadenv() { eval "$(lua /full/path/to/lenv/cli.lua "$@")"; }
```

---

## More Usage & Documentation

See the full usage guide in [`docs/USAGE.md`](docs/USAGE.md) for advanced workflows, script generation, and more examples.

---

## Features

- Parse `.env` files with variable expansion, quoting, and comments
- Export variables as shell scripts or for direct shell integration
- Cross-platform: works on Unix and Windows
- CLI and Lua API

---

## Contributing

Pull requests and issues are welcome!