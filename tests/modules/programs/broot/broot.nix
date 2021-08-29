{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.broot = {
      enable = true;
      modal = true;
    };

    nixpkgs.overlays =
      [ (self: super: { broot = pkgs.writeScriptBin "dummy" ""; }) ];

    nmt.script = ''
      assertFileExists home-files/.config/broot/conf.toml
      assertFileContent home-files/.config/broot/conf.toml ${
        pkgs.writeText "broot.expected" ''
          modal = true

          [[verbs]]
          execution = ":parent"
          invocation = "p"

          [[verbs]]
          execution = "$EDITOR {file}"
          invocation = "edit"
          shortcut = "e"

          [[verbs]]
          execution = "$EDITOR {directory}/{subpath}"
          invocation = "create {subpath}"

          [[verbs]]
          execution = "less {file}"
          invocation = "view"

          [skin]
        ''
      }
    '';
  };
}
