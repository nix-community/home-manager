{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.broot = {
      enable = true;
      settings.modal = true;
    };

    nmt.script = ''
      assertFileExists home-files/.config/broot/conf.toml
      assertFileContent home-files/.config/broot/conf.toml ${
        pkgs.writeText "broot.expected" ''
          imports = ["verbs.hjson", {file = "dark-blue-skin.hjson", luma = ["dark", "unknown"]}, {file = "white-skin.hjson", luma = "light"}]
          modal = true
          show_selection_mark = true
          verbs = []

          [skin]
        ''
      }
    '';
  };
}
