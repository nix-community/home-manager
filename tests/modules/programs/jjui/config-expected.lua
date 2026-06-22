local foo = require("plugins.foo")
local bar = require("plugins.bar")

function setup(config)
  foo.setup("#5B8DEF", config)
  bar.setup("#5B8DEF", config)

  config.action("show diff in diffnav", function()
    local change_id = context.change_id()
    if not change_id or change_id == "" then
      flash({ text = "No revision selected", error = true })
      return
    end

    exec_shell(string.format("jj diff -r %q --git --color always | diffnav", change_id))
  end, { desc = "show diff in diffnav", key = "ctrl+d", scope = "revisions" })
end
