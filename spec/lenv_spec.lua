---@diagnostic disable: undefined-global, undefined-field, need-check-nil
local env = require("lenv")
-- local env = require("src.lenv")

describe("env parser", function()
    describe("parse function", function()
        it("should parse basic key-value pairs", function()
            local result, warnings = env.parse("KEY=value\nANOTHER=test")
            assert.are.equal("value", result.KEY)
            assert.are.equal("test", result.ANOTHER)
            assert.are.equal(0, #warnings)
        end)

        it("should handle empty values", function()
            local result = env.parse("EMPTY=\nALSO_EMPTY=")
            assert.are.equal("", result.EMPTY)
            assert.are.equal("", result.ALSO_EMPTY)
        end)

        it("should handle quoted values", function()
            local result = env.parse('QUOTED="hello world"\nSINGLE=\'single quotes\'')
            assert.are.equal("hello world", result.QUOTED)
            assert.are.equal("single quotes", result.SINGLE)
        end)

        it("should handle escape sequences in double quotes", function()
            local result = env.parse('ESCAPED="line1\\nline2\\ttab"')
            assert.are.equal("line1\nline2\ttab", result.ESCAPED)
        end)

        it("should skip comments and empty lines", function()
            local content = [[
# This is a comment
KEY=value

# Another comment
ANOTHER=test
            ]]
            local result = env.parse(content)
            assert.are.equal("value", result.KEY)
            assert.are.equal("test", result.ANOTHER)
            assert.is_nil(result["# This is a comment"])
        end)

        it("should handle variable expansion", function()
            local content = [[
BASE_PATH=/home/user
FULL_PATH=${BASE_PATH}/projects
            ]]
            local result = env.parse(content)
            assert.are.equal("/home/user", result.BASE_PATH)
            assert.are.equal("/home/user/projects", result.FULL_PATH)
        end)

        it("should handle different line endings", function()
            local result = env.parse("KEY1=value1\rKEY2=value2\r\nKEY3=value3\nKEY4=value4")
            assert.are.equal("value1", result.KEY1)
            assert.are.equal("value2", result.KEY2)
            assert.are.equal("value3", result.KEY3)
            assert.are.equal("value4", result.KEY4)
        end)

        it("should reject invalid key formats", function()
            local result, warnings = env.parse("123INVALID=value\n-ALSO-INVALID=test\nVALID_KEY=good")
            assert.is_nil(result["123INVALID"])
            assert.is_nil(result["-ALSO-INVALID"])
            assert.are.equal("good", result.VALID_KEY)
            assert.are.equal(2, #warnings)
        end)

        it("should handle malformed lines", function()
            local result, warnings = env.parse("VALID=good\nINVALID LINE WITHOUT EQUALS\nALSO_VALID=test")
            assert.are.equal("good", result.VALID)
            assert.are.equal("test", result.ALSO_VALID)
            assert.are.equal(1, #warnings)
            assert.matches("Invalid format", warnings[1])
        end)

        it("should handle nil input", function()
            local result, warnings = env.parse(nil)
            assert.is_nil(result)
            assert.are.equal(1, #warnings)
            assert.matches("Content must be a string", warnings[1])
        end)
    end)

    describe("load function", function()
        it("should handle non-existent files", function()
            local result, err = env.load("nonexistent.env")
            assert.is_nil(result)
            assert.matches("Could not open file", err)
        end)

        it("should handle invalid filepath types", function()
            local result, err = env.load(nil)
            assert.is_nil(result)
            assert.matches("Filepath must be a string", err)
        end)
    end)

    describe("export function", function()
        local test_env = {
            TEST_KEY = "test_value",
            ANOTHER_KEY = "another value with spaces",
            NUMERIC_VALUE = "12345"
        }

        it("should generate script content", function()
            local count, errors, outputs = env.export(test_env)
            assert.are.equal(3, count)
            assert.are.equal(0, #errors)
            assert.is_not_nil(outputs.script_content)
            assert.matches("TEST_KEY", outputs.script_content)
        end)

        it("should generate instructions", function()
            local count, errors, outputs = env.export(test_env)
            assert.is_not_nil(outputs.instructions)
            assert.are.equal(3, #outputs.instructions)
        end)

        it("should reject invalid keys", function()
            local invalid_env = {
                ["123INVALID"] = "value",
                VALID_KEY = "value"
            }
            local count, errors, outputs = env.export(invalid_env)
            assert.are.equal(1, count)
            assert.are.equal(1, #errors)
            assert.matches("Invalid key format", errors[1])
        end)

        it("should handle non-table input", function()
            local count, errors, outputs = env.export("not a table")
            assert.are.equal(0, count)
            assert.are.equal(1, #errors)
            assert.matches("parsed_env must be a table", errors[1])
        end)

        it("should detect appropriate script extension", function()
            local count, errors, outputs = env.export(test_env)
            assert.is_not_nil(outputs.script_extension)
            assert.is_true(outputs.script_extension == ".sh" or outputs.script_extension == ".bat")
        end)
    end)

    describe("load_and_export function", function()
        it("should handle file loading errors gracefully", function()
            local count, errors, outputs = env.load_and_export("nonexistent.env")
            assert.are.equal(0, count)
            assert.are.equal(1, #errors)
            assert.matches("Could not open file", errors[1])
        end)
    end)

    describe("integration tests", function()
        it("should handle a complete .env file workflow", function()
            local content = [[
# Database configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp
DB_USER=admin
DB_PASSWORD="secret password with spaces"

# App configuration
APP_ENV=development
DEBUG=true
LOG_LEVEL=debug

# Paths
BASE_PATH=/var/www
UPLOAD_PATH=${BASE_PATH}/uploads
            ]]

            local parsed, warnings = env.parse(content)
            assert.is_not_nil(parsed)
            assert.are.equal("localhost", parsed.DB_HOST)
            assert.are.equal("5432", parsed.DB_PORT)
            assert.are.equal("secret password with spaces", parsed.DB_PASSWORD)
            assert.are.equal("/var/www/uploads", parsed.UPLOAD_PATH)

            local count, errors, outputs = env.export(parsed)
            assert.are.equal(10, count)
            assert.are.equal(0, #errors)
            assert.is_not_nil(outputs.script_content)
            assert.matches("DB_HOST", outputs.script_content)
            assert.matches("UPLOAD_PATH", outputs.script_content)
        end)
    end)
end)
