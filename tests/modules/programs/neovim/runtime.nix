{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.neovim = lib.mkMerge [
      {
        enable = true;
        plugins = with pkgs.vimPlugins; [
          vim-nix
          {
            plugin = vim-commentary;
            runtime = {
              "after/ftplugin/c.vim".text = ''
                " plugin-specific config
                setlocal commentstring=//\ %s
                setlocal comments=://
              '';
            };
          }
        ];
        extraWrapperArgs = let buildDeps = with pkgs; [ stdenv.cc.cc zlib ];
        in [
          "--suffix"
          "LIBRARY_PATH"
          ":"
          "${lib.makeLibraryPath buildDeps}"
          "--suffix"
          "PKG_CONFIG_PATH"
          ":"
          "${lib.makeSearchPathOutput "dev" "lib/pkgconfig" buildDeps}"
        ];
      }
      {
        extraPython3Packages = ps: with ps; [ jedi pynvim ];
        extraLuaPackages = ps: with ps; [ luacheck ];
      }
      {
        extraPython3Packages = with pkgs.python3Packages; [ jedi pynvim ];
        extraLuaPackages = with pkgs.lua51Packages; [ luacheck ];
      }
    ];

    nmt.script = ''
      ftplugin="home-files/.config/nvim/after/ftplugin/c.vim"
      nvimbin="home-path/bin/nvim"
      assertFileExists "$ftplugin"
      assertFileRegex "$nvimbin" 'LIBRARY_PATH'
      assertFileRegex "$nvimbin" 'PKG_CONFIG_PATH'
    '';
  };
}
