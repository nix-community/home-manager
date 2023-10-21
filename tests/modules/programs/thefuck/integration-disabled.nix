{ ... }:

{
  programs = {
    thefuck.enable = true;
    thefuck.enableBashIntegration = false;
    thefuck.enableZshIntegration = false;
    bash.enable = true;
    zsh.enable = true;
  };

  test.stubs.thefuck = { };

  nmt.script = ''
    assertFileNotRegex home-files/.bashrc '@thefuck@/bin/thefuck'
    assertFileNotRegex home-files/.zshrc '@thefuck@/bin/thefuck'
  '';
}
