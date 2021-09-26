{ config, lib, pkgs, ... }:

with lib;

let

  # Samples taken from the ne manual.
  keybindings = ''
    SEQ  "\x1b[1;5D"  14A
    KEY  14A          HELP
  '';

  menus = ''
    MENU "File"
    ITEM "Open...     ^O" Open
    ITEM "Close         " Close
    ITEM "DoIt          " Macro DoIt
  '';

  virtualExtensions = ''
    sh   1  ^#!\s*/.*\b(bash|sh|ksh|zsh)\s*
    csh  1  ^#!\s*/.*\b(csh|tcsh)\s*
    pl   1  ^#!\s*/.*\bperl\b
    py   1  ^#!\s*/.*\bpython[0-9]*\s*
    rb   1  ^#!\s*/.*\bruby\s*
    xml  1  ^<\?xml
  '';

  automaticPreferences = {
    nix = ''
      TAB 0
      TS 2
    '';
    js = ''
      TS 4
    '';
  };

  checkFile = filename: contents: ''
    assertFileExists home-files/.ne/${filename}
    assertFileContent home-files/.ne/${filename} ${
      builtins.toFile "checkFile" contents
    }
  '';

in {
  config = {
    programs.ne = {
      enable = true;
      inherit keybindings;
      inherit menus;
      inherit virtualExtensions;
      inherit automaticPreferences;
    };

    test.stubs.ne = { };

    nmt = {
      description = "Check that configuration files are correctly written";
      script = concatStringsSep "\n" [
        (checkFile ".keys" keybindings)
        (checkFile ".extensions" virtualExtensions)
        (checkFile ".menus" menus)

        # Generates a check command for each entry in automaticPreferences.
        (concatStringsSep "\n" (mapAttrsToList
          (extension: contents: checkFile "${extension}#ap" contents)
          automaticPreferences))
      ];
    };
  };
}
