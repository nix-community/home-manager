{ ... }:

{
  programs = {
    atuin = {
      enable = true;
      enableBashIntegration = false;
      enableZshIntegration = false;
    };
    bash.enable = true;
    zsh.enable = true;
  };

  test.stubs = {
    atuin = { };
    bash-preexec = { };
  };

  nmt.script = ''
    assertFileNotRegex home-files/.zshrc '@atuin@ init zsh'
    assertFileNotRegex home-files/.bashrc '@atuin@ init bash'
  '';
}
