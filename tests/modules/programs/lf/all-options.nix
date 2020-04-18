{ config, lib, pkgs, ... }:

with lib;

let
  pvScript = builtins.toFile "pv.sh" "cat $1";
  expected = builtins.toFile "settings-expected" ''
    set icons
    set noignorecase
    set ratios "2:2:3"
    set tabstop 4

    cmd added :echo "foo"
    cmd multiline :{{
      push gg
      echo "bar"
      push i
    }}
    cmd removed

    map aa should-be-added
    map ab

    cmap <c-a> should-be-added
    cmap <c-b>

    set previewer ${pvScript}
    map i ${"$"}${pvScript} "$f" | less -R



    # More config...

  '';
in {
  config = {
    programs.lf = {
      enable = true;

      cmdKeybindings = {
        "<c-a>" = "should-be-added";
        "<c-b>" = null;
      };

      commands = {
        added = '':echo "foo"'';
        removed = null;
        multiline = ''
          :{{
            push gg
            echo "bar"
            push i
          }}'';
      };

      extraConfig = ''
        # More config...
      '';

      keybindings = {
        aa = "should-be-added";
        ab = null;
      };

      previewer = {
        keybinding = "i";
        source = pvScript;
      };

      settings = {
        ignorecase = false;
        icons = true;
        tabstop = 4;
        ratios = "2:2:3";
      };
    };

    nixpkgs.overlays =
      [ (self: super: { lf = pkgs.writeScriptBin "dummy-lf" ""; }) ];

    nmt.script = ''
      assertFileExists home-files/.config/lf/lfrc
      assertFileContent home-files/.config/lf/lfrc ${expected}
    '';
  };
}
