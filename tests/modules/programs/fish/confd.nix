{
  programs.fish = {
    enable = true;

    confD."foo".text = ''
      # foo fish file
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/fish/conf.d/foo.fish
    assertFileRegex home-files/.config/fish/conf.d/foo.fish '# foo fish file'
  '';
}
