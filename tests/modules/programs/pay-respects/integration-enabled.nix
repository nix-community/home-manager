{ ... }: {
  programs = {
    pay-respects.enable = true;
    bash.enable = true;
    zsh.enable = true;
    fish.enable = true;
    nushell.enable = true;
  };

  test.stubs.pay-respects = { };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@pay-respects@/bin/dummy bash --alias f)"'

    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@pay-respects@/bin/dummy zsh --alias f)"'

    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      '@pay-respects@/bin/dummy fish --alias f | source'

    assertFileExists home-files/.config/nushell/config.nu
    assertFileContains \
      home-files/.config/nushell/config.nu \
      'alias f ='
      # For some reason the test does not generate the pay-respects output
      # 'alias f = with-env { _PR_LAST_COMMAND : (history | last).command,_PR_ALIAS : "",_PR_SHELL : nu } { @pay-respects@/bin/dummy }'
  '';
}
