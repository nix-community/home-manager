{ config, lib, pkgs, ... }:

with lib;

let
  defpref = ''
    defined through defaultPreferences
  '';

  autopref = ''
    defined through automaticPreferences
  '';

in {
  config = {
    programs.ne = {
      enable = true;
      defaultPreferences = defpref;
      automaticPreferences.".default" = autopref;
    };

    test.stubs.ne = { };

    nmt = {
      description =
        "Check that it gracefully handles the case of both defaultPreferences and automaticPreferences.'.default' being set, defaulting to the former.";
      script = ''
        assertFileExists home-files/.ne/.default#ap
        assertFileContent home-files/.ne/.default#ap ${
          builtins.toFile "defpref" defpref
        }
      '';
    };
  };
}
