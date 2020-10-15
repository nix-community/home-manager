{ config, lib, pkgs, ... }:

{
  config = {
    programs.gh = {
      enable = true;
      aliases = { co = "pr checkout"; };
      editor = "vim";
    };

    nixpkgs.overlays = [
      (self: super: {
        gitAndTools = super.gitAndTools // {
          gh = pkgs.writeScriptBin "dummy-gh" "";
        };
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/gh/config.yml
      assertFileContent home-files/.config/gh/config.yml ${
        builtins.toFile "config-file.yml" ''
          {"aliases":{"co":"pr checkout"},"editor":"vim","gitProtocol":"https"}''
      }
    '';
  };
}
