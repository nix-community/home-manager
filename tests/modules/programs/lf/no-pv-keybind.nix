let
  pvScript = builtins.toFile "pv.sh" "cat $1";
  expected = builtins.toFile "settings-expected" ''








    set previewer ${pvScript}



    # More config...

  '';
in {
  programs.lf = {
    enable = true;

    extraConfig = ''
      # More config...
    '';

    previewer = { source = pvScript; };
  };

  nmt.script = ''
    assertFileExists home-files/.config/lf/lfrc
    assertFileContent home-files/.config/lf/lfrc ${expected}
  '';
}
