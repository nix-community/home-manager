local M = {}

function M.setup(primary, config)
  config.ui = config.ui or {}
  config.ui.colors = config.ui.colors or {}

  config.ui.colors.title = { fg = primary, bold = true }
end

return M
