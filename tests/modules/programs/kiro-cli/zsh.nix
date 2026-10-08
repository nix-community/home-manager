{
  programs = {
    kiro-cli.enable = true;
    zsh.enable = true;
  };

  test.stubs.kiro-cli = {
    name = "kiro-cli";
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains home-files/.zshrc \
      'eval "$(@kiro-cli@/bin/kiro-cli init zsh pre)"'
    assertFileContains home-files/.zshrc \
      'eval "$(@kiro-cli@/bin/kiro-cli init zsh post)"'

    preLine=$(grep -n 'init zsh pre' $TESTED/home-files/.zshrc | head -n1 | cut -d: -f1)
    postLine=$(grep -n 'init zsh post' $TESTED/home-files/.zshrc | head -n1 | cut -d: -f1)
    if [[ "$preLine" -ge "$postLine" ]]; then
      fail "kiro-cli 'pre' snippet (line $preLine) must appear before 'post' snippet (line $postLine) in .zshrc"
    fi
  '';
}
