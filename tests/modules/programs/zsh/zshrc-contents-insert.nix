{
  programs.zsh = {
    enable = true;
    initContent = ''
      # Custom contents
      echo "Custom contents"
    '';
  };

  nmt.script = ''
    assertFileContains home-files/.zshrc $'# Custom contents\necho "Custom contents"'
  '';
}
