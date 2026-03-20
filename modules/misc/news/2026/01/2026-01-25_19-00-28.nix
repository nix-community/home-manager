{ config, ... }:
{
  time = "2026-01-25T18:00:28+00:00";
  condition = config.programs.neovim.enable;
  message = ''
    The neovim module now exposes programs.neovim.extraLuaPackages via init.lua instead of wrapper arguments.
    This makes for a better out of the box experience, closer to what users can expect on other distributions, i.e., you
    can now run any neovim derivatives (neovide, neovim-qt etc) without wrapping.

    If you used home-manager only to install plugins, the newly generated init.lua might conflict with yours.
    You can ignore the generated init.lua with
    `xdg.configFile."nvim/init.lua".enable = false` but `extraLuaPackages` will become ineffective.
    You can still refer to its generated content via:
        xdg.configFile."nvim/lua/hm-generated.lua".text = config.programs.neovim.initLua;
      and in your manual init.lua `require'hm-generated'`

    For more details, see:
    - https://github.com/nix-community/home-manager/pull/8586
    - https://github.com/nix-community/home-manager/pull/8606 and its linked comments for more details/solutions.
  '';
}
