{
  programs = {
    pay-respects.enable = true;
    bash.enable = true;
    zsh.enable = true;
    fish.enable = true;
    nushell.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@pay-respects@/bin/pay-respects bash --alias)"'

    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@pay-respects@/bin/pay-respects zsh --alias)"'

    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      '@pay-respects@/bin/pay-respects fish --alias | source'

    assertFileExists home-files/.config/nushell/config.nu
    assertFileContains \
      home-files/.config/nushell/config.nu \
      '@pay-respects@/bin/pay-respects nushell --alias [<alias>]'
  '';
}
