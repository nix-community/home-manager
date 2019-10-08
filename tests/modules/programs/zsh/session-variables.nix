{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.zsh = {
      enable = true;

      sessionVariables = {
        V1 = "v1";
        V2 = "v2-${config.programs.zsh.sessionVariables.V1}";
      };
    };

    nixpkgs.overlays = [
      (self: super: {
        zsh = pkgs.writeScriptBin "dummy-zsh" "";
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.zshrc
      assertFileRegex home-files/.zshrc 'export V1="v1"'
      assertFileRegex home-files/.zshrc 'export V2="v2-v1"'
    '';
  };
}
