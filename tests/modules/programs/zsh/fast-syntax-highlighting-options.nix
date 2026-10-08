{
  programs.zsh = {
    enable = true;
    fastSyntaxHighlighting = {
      enable = true;
      theme = "default";
      settings = {
        "chroma-," = "→chroma/-precommand.ch";
        "chroma-comma" = "→chroma/-precommand.ch";
      };
    };
  };

  nmt.script = ''
    assertFileContains home-files/.zshrc "fast-theme -q default"
    assertFileContains home-files/.zshrc "FAST_HIGHLIGHT+=(chroma-, '→chroma/-precommand.ch')"
    assertFileContains home-files/.zshrc "FAST_HIGHLIGHT+=(chroma-comma '→chroma/-precommand.ch')"
  '';
}
