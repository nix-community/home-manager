{ config, ... }:
{
  time = "2026-04-01T20:28:19+00:00";
  condition = config.programs.neovim.enable;
  # if behavior changed, explain how to restore previous behavior.
  message = ''
    We are changing neovim plugin "config" default type from `viml` to `lua`.

    When the option was introduced neovim lua support was not as popular or robust as in 0.12.
    Lua configuration seems to be the most popular these days so starting from 26.05, neovim default
    plugin "config" is assumed to be written as lua instead of viml.

    You may see the following warning:

    evaluation warning: The default value of `programs.neovim.plugins.PLUGIN.type` has changed from `"viml"` to `"lua"`.
                    You are currently using the legacy default (`"viml"`) because `home.stateVersion` is less than "26.05".
                    To silence this warning and keep legacy behavior, set:
                      programs.neovim.plugins.PLUGIN.type = "viml";
                    To adopt the new default behavior, set:
                      programs.neovim.plugins.PLUGIN.type = "lua";

    which can be triggered for instance by:

      programs.neovim.plugins = [
          { plugin = vimPlugins.fugitive-vim; config = "# some viml"; }
      ];

    Fix it with:

      programs.neovim.plugins = [
          { plugin = vimPlugins.fugitive-vim; config = "# some viml"; type = "viml"; }
      ];
  '';
}
