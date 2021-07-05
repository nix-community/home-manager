{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.pet = {
      enable = true;
      selectcmdPackage = pkgs.writeScriptBin "pet-cmd" "" // {
        outPath = "@pet-cmd@";
      };
      snippets = [{
        description = "git: search full history for regex";
        command = "git log -p -G <regex>";
        tag = [ "git" "regex" ];
      }];
    };

    nixpkgs.overlays = [
      (self: super: {
        pet = pkgs.writeScriptBin "pet" "" // { outPath = "@pet@"; };
      })
    ];

    nmt.script = ''
      assertFileContent home-files/.config/pet/snippet.toml ${./snippet.toml}
    '';
  };
}
