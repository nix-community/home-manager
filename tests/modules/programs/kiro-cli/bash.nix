{
  programs = {
    kiro-cli.enable = true;
    bash.enable = true;
  };

  test.stubs.kiro-cli = {
    name = "kiro-cli";
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains home-files/.bashrc \
      'eval "$(@kiro-cli@/bin/kiro-cli init bash pre)"'
    assertFileContains home-files/.bashrc \
      'eval "$(@kiro-cli@/bin/kiro-cli init bash post)"'

    preLine=$(grep -n 'init bash pre' $TESTED/home-files/.bashrc | head -n1 | cut -d: -f1)
    postLine=$(grep -n 'init bash post' $TESTED/home-files/.bashrc | head -n1 | cut -d: -f1)
    if [[ "$preLine" -ge "$postLine" ]]; then
      fail "kiro-cli 'pre' snippet (line $preLine) must appear before 'post' snippet (line $postLine) in .bashrc"
    fi
  '';
}
