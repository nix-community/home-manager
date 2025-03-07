let
  defpref = ''
    defined through defaultPreferences
  '';

  autopref = ''
    defined through automaticPreferences
  '';

in {
  programs.ne = {
    enable = true;
    defaultPreferences = defpref;
    automaticPreferences.".default" = autopref;
  };

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
}
