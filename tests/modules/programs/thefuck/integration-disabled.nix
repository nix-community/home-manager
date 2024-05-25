{ ... }:

{
  programs = {
    thefuck.enable = true;
    thefuck.enableBashIntegration = false;
    thefuck.enableFishIntegration = false;
    thefuck.enableZshIntegration = false;
    thefuck.enableNushellIntegration = false;
    bash.enable = true;
    zsh.enable = true;
    nushell.enable = true;
  };

  test.stubs.thefuck = { };

  nmt.script = ''
    assertFileNotRegex home-files/.bashrc '@thefuck@/bin/thefuck'
    assertPathNotExists home-files/.config/fish/functions/fuck.fish
    assertFileNotRegex home-files/.zshrc '@thefuck@/bin/thefuck'
    assertFileNotRegex home-files/.config/nushell/config.nu '@thefuck@/bin/thefuck'
  '';
}
