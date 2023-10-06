{ ... }:

{
  programs = {
    thefuck.enable = true;
    thefuck.enableBashIntegration = false;
    thefuck.enableFishIntegration = false;
    thefuck.enableZshIntegration = false;
    bash.enable = true;
    zsh.enable = true;
  };

  test.stubs.thefuck = { };

  nmt.script = ''
    assertFileNotRegex home-files/.bashrc '@thefuck@/bin/thefuck'
    assertFileNotExists home-files/.config/fish/functions/fuck.fish
    assertFileNotRegex home-files/.zshrc '@thefuck@/bin/thefuck'
  '';
}
