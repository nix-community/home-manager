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
      assertFileExists $home_files/.zshrc
      assertFileRegex $home_files/.zshrc 'export V1="v1"'
      assertFileRegex $home_files/.zshrc 'export V2="v2-v1"'
    '';
  };
}
