{
  programs = {
    carapace.enable = true;
    bash.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileRegex home-files/.bashrc \
      'source <(@carapace@/bin/carapace _carapace bash)'
  '';
}
