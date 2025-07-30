local env = require("lenv")

-- Example 1: Parse content directly
print("=== Example 1: Parse content directly ===")
local content = [[
# Database configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp
DB_USER=admin
DB_PASSWORD="secret password"

# Application settings
APP_ENV=development
DEBUG=true
]]

local parsed, warnings = env.parse(content)
if parsed then
    print("Parsed variables:")
    for key, value in pairs(parsed) do
        print(string.format("  %s = %s", key, value))
    end

    if #warnings > 0 then
        print("Warnings:")
        for _, warning in ipairs(warnings or {}) do
            print("  " .. warning)
        end
    end
else
    if warnings and warnings[1] then
        print("Parse failed:", warnings[1])
    else
        print("Parse failed: unknown error")
    end
end

print()

-- Example 2: Load from file and generate script
print("=== Example 2: Load from file and export ===")

-- First, create a sample .env file
local sample_env_content = [[
# Sample environment file
API_KEY=your-secret-api-key
API_URL=https://api.example.com
TIMEOUT=30
RETRIES=3
LOG_LEVEL=info
]]

local file = io.open("sample.env", "w")
if file then
    file:write(sample_env_content)
end
if file then
    file:close()
end

-- Load and export
local count, errors, outputs = env.load_and_export("sample.env", {
    script_file = "set_environment"
})

print(string.format("Processed %d variables", count))

if #errors > 0 then
    print("Errors:")
    for _, error in ipairs(errors) do
        print("  " .. error)
    end
end

-- Print usage instructions
env.print_usage(outputs)

-- Clean up sample file
os.remove("sample.env")

print()

-- Example 3: Handle variable expansion
print("=== Example 3: Variable expansion ===")
local expansion_content = [[
BASE_PATH=/home/user
PROJECT_PATH=${BASE_PATH}/myproject
LOG_PATH=${PROJECT_PATH}/logs
DATA_PATH=${PROJECT_PATH}/data
]]

local expanded = env.parse(expansion_content)
print("Variables with expansion:")
if expanded then
    for key, value in pairs(expanded) do
        print(string.format("  %s = %s", key, value))
    end
end

print()

-- Example 4: Error handling
print("=== Example 4: Error handling ===")
local problematic_content = [[
VALID_KEY=good_value
123_INVALID_KEY=bad_key
ANOTHER-INVALID=also_bad
GOOD_KEY=another_good_value
MALFORMED LINE WITHOUT EQUALS
]]

local result, warnings = env.parse(problematic_content)
print("Valid variables parsed:")
if result then
    for key, value in pairs(result) do
        print(string.format("  %s = %s", key, value))
    end
end

print("Warnings encountered:")
if warnings then
    for _, warning in ipairs(warnings) do
        print("  " .. warning)
    end
end

print()

-- Example 5: Export with different options
print("=== Example 5: Export options ===")
local test_vars = {
    DATABASE_URL = "postgresql://user:pass@localhost/db",
    REDIS_URL = "redis://localhost:6379",
    SECRET_KEY = "super-secret-key"
}

-- Generate script content only
local count, errors, outputs = env.export(test_vars)
print("Generated script content:")
print(outputs.script_content)

print()
print("Manual instructions:")
for _, instruction in ipairs(outputs.instructions) do
    print("  " .. instruction)
end

print()

-- Example 6: Comprehensive workflow
print("=== Example 6: Complete workflow ===")

-- Create a more complex .env file
local complex_env = [[
# Production configuration
NODE_ENV=production
PORT=3000

# Database
DATABASE_URL="postgresql://user:password@localhost:5432/myapp"
DB_POOL_SIZE=10

# Redis
REDIS_URL=redis://localhost:6379
REDIS_TTL=3600

# Security
JWT_SECRET="my-jwt-secret-key"
BCRYPT_ROUNDS=10

# External APIs
STRIPE_KEY="sk_live_xxxxxxxxxxxx"
SENDGRID_API_KEY="SG.xxxxxxxxxxxxxxxxxx"

# Paths and URLs
BASE_URL=https://myapp.com
UPLOAD_PATH=/var/uploads
LOG_PATH=/var/log/myapp

# Feature flags
ENABLE_LOGGING=true
ENABLE_METRICS=false
DEBUG_MODE=false
]]

-- Write to file
local prod_file = io.open("production.env", "w")
if prod_file then
    prod_file:write(complex_env)
end
if prod_file then
    prod_file:close()
end

-- Load and process
local prod_vars, load_errors = env.load("production.env")
if prod_vars then
    print(string.format("Loaded %d production variables",
        (function()
            local count = 0; for _ in pairs(prod_vars) do count = count + 1 end
            return count
        end)()))

    -- Export with script generation
    local export_count, export_errors, export_outputs = env.export(prod_vars, {
        script_file = "production_env",
    })

    print(string.format("Generated export script with %d variables", export_count))

    if export_outputs.script_file then
        print("Script saved to:", export_outputs.script_file)
        print("To apply: source " .. export_outputs.script_file)
    end

    -- Display any errors
    if #export_errors > 0 then
        print("Export errors:")
        for _, error in ipairs(export_errors) do
            print("  " .. error)
        end
    end
else
    print("Failed to load production.env:", load_errors)
end

-- Clean up
os.remove("production.env")
if io.open("production_env.sh", "r") then
    os.remove("production_env.sh")
end
if io.open("production_env.bat", "r") then
    os.remove("production_env.bat")
end

print("\n=== Examples completed ===")
