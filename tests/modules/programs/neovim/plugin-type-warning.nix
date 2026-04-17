{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./stubs.nix ];

  home.stateVersion = "25.11";

  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      {
        plugin = vim-commentary;
      }
      {
        plugin = vim-nix;
        config = ''
          let g:hmLegacyPluginType = 1
        '';
      }
      {
        plugin = unicode-vim;
        type = "lua";
        config = ''
          vim.g.hmExplicitPluginType = 1
        '';
      }
    ];
  };

  test.asserts.warnings.expected = [
    (lib.concatStringsSep "\n" [
      "The default value of `programs.neovim.plugins.PLUGIN.type` has changed from `\"viml\"` to `\"lua\"`."
      "You are currently using the legacy default (`\"viml\"`) because `home.stateVersion` is less than \"26.05\"."
      "To silence this warning and keep legacy behavior, set:"
      "  programs.neovim.plugins.PLUGIN.type = \"viml\";"
      "To adopt the new default behavior, set:"
      "  programs.neovim.plugins.PLUGIN.type = \"lua\";"
      "Triggered by plugin `vim-nix` defined in `plugin-type-warning.nix` at list index 2."
      "Set `type = \"viml\"` or `type = \"lua\"` on that plugin entry to make the config language explicit."
    ])
  ];

  assertions = [
    {
      assertion = lib.hasInfix "let g:hmLegacyPluginType = 1" config.programs.neovim.generatedConfigs.viml;
      message = "Implicit legacy plugin type should still route old-state-version config to viml.";
    }
    {
      assertion = lib.hasInfix "vim.g.hmExplicitPluginType = 1" config.programs.neovim.generatedConfigs.lua;
      message = "Explicit lua plugin type should still route config to lua.";
    }
  ];
}
