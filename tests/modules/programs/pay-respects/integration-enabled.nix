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
      'eval "$(@pay-respects@/bin/dummy bash --alias)"'

    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@pay-respects@/bin/dummy zsh --alias)"'

    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      '@pay-respects@/bin/dummy fish --alias | source'

    assertFileExists home-files/.config/nushell/config.nu
    assertFileContains \
      home-files/.config/nushell/config.nu \
      '@pay-respects@/bin/dummy nushell --alias [<alias>]'
  '';
}
