{ ... }: {
  programs = {
    pay-respects.enable = true;
    pay-respects.enableBashIntegration = false;
    pay-respects.enableFishIntegration = false;
    pay-respects.enableZshIntegration = false;
    pay-respects.enableNushellIntegration = false;
    bash.enable = true;
    zsh.enable = true;
    fish.enable = true;
    nushell.enable = true;
  };

  test.stubs.pay-respects = { };

  nmt.script = ''
    assertFileNotRegex home-files/.bashrc '@pay-respects@/bin/dummy'
    assertFileNotRegex home-files/.zshrc '@pay-respects@/bin/dummy'
    assertFileNotRegex home-files/.config/fish/config.fish '@pay-respects@/bin/dummy'
    assertFileNotRegex home-files/.config/nushell/config.nu '@pay-respects@/bin/dummy'
  '';
}
