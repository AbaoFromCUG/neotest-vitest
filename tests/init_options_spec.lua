local async = require("nio").tests
local Tree = require("neotest.types").Tree
require("neotest-vitest-assertions")
A = function(...)
  print(vim.inspect(...))
end

local binary_override = function()
  return "mybinaryoverride"
end
local config_override = function()
  return "./spec/vite.config.ts"
end

describe("build_spec with override", function()
  local raw_tempname
  before_each(function()
    raw_tempname = require("neotest.async").fn.tempname
    require("neotest.async").fn.tempname = function()
      return "/tmp/foo"
    end
  end)
  after_each(function()
    require("neotest.async").fn.tempname = raw_tempname
  end)
  async.it("builds command", function()
    local plugin = require("neotest-vitest")({
      vitestCommand = binary_override,
      vitestConfigFile = config_override,
      env = { override = "override", adapter_override = true },
    })

    local positions = plugin.discover_positions("./spec/basic.test.ts"):to_list()
    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    local spec = plugin.build_spec({ nil, { env = { spec_override = true } }, tree = tree })

    assert.is.truthy(spec)

    local command = spec.command
    assert.is.truthy(command)
    assert.contains(command, binary_override())
    assert.contains(command, "--watch=false")
    assert.contains(command, "--reporter=verbose")
    --[[ assert.contains(command, "--config=" .. config_override()) ]]
    assert.contains(command, "--testNamePattern=.*")
    -- assert.contains(command, "spec/basic.test.ts")
    assert.is.truthy(spec.context.file)
    assert.is.truthy(spec.context.results_path)

    assert.is.same(
      spec.env,
      { override = "override", adapter_override = true, spec_override = true }
    )
  end)
end)
