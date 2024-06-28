{ config, pkgs, ... }:

{
  config = {
    programs.neovim = {
      enable = true;
      extraConfig = ''
        set sw=4
      '';
      extraLuaConfig = ''
        vim.opt.expandtab = false
      '';
      plugins = [{
        plugin = pkgs.emptyDirectory;
        type = "lua";
        config = ''
          vim.g.test_plugin2 = 1
        '';
      }];
    };

    nmt.script = ''
      initLua="$TESTED/home-files/.config/nvim/init.lua"
      initLuaNormalized="$(normalizeStorePaths "$initLua")"
      assertFileExists "$initLua"
      assertFileContent "$initLuaNormalized" "${./multiple-rc-sources.expected}"
    '';
  };
}

