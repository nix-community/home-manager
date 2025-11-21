{
  programs.zsh.zsh-abbr = {
    enable = true;
    abbreviations = {
      ga = "git add";
    };
  };

  test.stubs = {
    zsh-abbr = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/share/zsh-abbr/runcoms
      '';
    };
  };
  nmt.script = ''
    abbreviations=home-files/.config/zsh-abbr/user-abbreviations

    assertFileExists $abbreviations
    assertFileContains $abbreviations "abbr ga='git add'"
  '';
}
