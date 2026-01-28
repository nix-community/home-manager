{ config, ... }:
{
  time = "2026-01-25T18:00:28+00:00";
  condition = config.programs.neovim.enable;
  message = ''
    The neovim module now exposes programs.neovim.extraLuaPackages via init.lua instead of wrapping arguments. With https://github.com/nix-community/home-manager/pull/8586, this makes it possible to run any neovim derivatives (neovide, neovim-qt etc) without any wrapping.
    If you used home-manager only to install plugins, the generated init.lua might conflict with yours.
    You can ignore the generated init.lua with
    `xdg.configFile."nvim/init.lua".enable = false` but extraLuaPackages will become ineffective. Either make the generated init.lua require your manual configuration or add the wrapping arguments yourself via `programs.neovim.extraWrapperArgs`.
    See https://github.com/nix-community/home-manager/pull/8606 and its linked comments for more details/solutions.
  '';
}
