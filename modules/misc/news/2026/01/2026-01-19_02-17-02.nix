{ config, ... }:
{
  time = "2026-01-19T01:17:02+00:00";
  condition = config.programs.neovim.enable;
  message = ''
    The neovim module now symlinks its plugins into xdg.dataFile."nvim/site/pack/hm" ( ~/.local/share/nvim) instead of modifying the runtimepath via wrapper arguments.
  '';
}
