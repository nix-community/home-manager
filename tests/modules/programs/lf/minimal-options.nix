{
  programs.lf = { enable = true; };

  nmt.script =
    let expected = builtins.toFile "settings-expected" "\n\n\n\n\n\n\n\n\n\n\n";
    in ''
      assertFileExists home-files/.config/lf/lfrc
      assertFileContent home-files/.config/lf/lfrc ${expected}
    '';
}
