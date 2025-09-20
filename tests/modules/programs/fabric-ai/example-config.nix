{
  programs.bash.enable = true;
  programs.zsh.enable = true;
  programs.fabric-ai = {
    enable = true;
    enablePattersAliases = true;
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileExists home-files/.zshrc

    assertFileContent home-files/.bashrc ${./bashrc}
    assertFileContent home-files/.zshrc ${./zshrc}
  '';
}
