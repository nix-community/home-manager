{
  programs.zsh = {
    enable = true;
    fastSyntaxHighlighting = {
      enable = true;
    };
  };

  nmt.script = ''
    assertFileContains home-files/.zshrc "source @zsh-fast-syntax-highlighting@/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
    assertFileNotRegex home-files/.zshrc "fast-theme"
  '';
}
