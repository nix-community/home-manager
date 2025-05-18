{
  programs = {
    carapace.enable = true;
    zsh.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileRegex home-files/.zshrc \
      'source <(@carapace@/bin/carapace _carapace zsh)'
  '';
}
