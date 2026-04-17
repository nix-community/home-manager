{ config, ... }:
{
  time = "2026-04-17T15:00:13+00:00";
  condition = config.programs.neovim.enable;
  message = ''
    The module `programs.neovim` now writes to
    {file}`$XDG_CONFIG_HOME/nvim/init.lua` by default.

    If you want to manage {file}`$XDG_CONFIG_HOME/nvim/init.lua` yourself, you
    can set {option}`programs.neovim.sideloadInitLua` to `true` to load the
    content of {option}`programs.neovim.initLua` through neovim wrapper
    arguments instead.
  '';
}
