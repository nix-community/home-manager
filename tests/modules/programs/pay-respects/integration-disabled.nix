{
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

  nmt.script = ''
    assertFileNotRegex home-files/.bashrc '@pay-respects@/bin/pay-respects'
    assertFileNotRegex home-files/.zshrc '@pay-respects@/bin/pay-respects'
    assertFileNotRegex home-files/.config/fish/config.fish '@pay-respects@/bin/pay-respects'
    assertFileNotRegex home-files/.config/nushell/config.nu '@pay-respects@/bin/pay-respects'
  '';
}
