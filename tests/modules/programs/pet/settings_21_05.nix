{ config, lib, pkgs, ... }:

with lib;

{
  home.stateVersion = "21.05";
  programs.pet = {
    enable = true;
    selectcmdPackage = config.lib.test.mkStubPackage { };
    settings.editor = "nvim";
  };

  test.stubs.pet = { };

  nmt.script = ''
    assertFileContent home-files/.config/pet/config.toml \
      ${
        builtins.toFile "pet-settings.toml" ''
          [General]
          editor = "nvim"
          selectcmd = "fzf"
          snippetfile = "/home/hm-user/.config/pet/snippet.toml"
        ''
      }
  '';
}
