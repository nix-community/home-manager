{
  programs.zsh = {
    enable = true;
    initExtra = ''
      # Custom contents
      echo "Custom contents"
    '';
  };

  nmt.script = ''
    assertFileContains home-files/.zshrc $'# Custom contents\necho "Custom contents"'
  '';
}
