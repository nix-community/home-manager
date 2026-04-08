{
  programs.atool = {
    enable = true;
    settings = {
      path_unrar = "unrar-free";
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.atoolrc"
    assertFileContains "home-files/.atoolrc" "path_unrar unrar-free"
  '';
}
