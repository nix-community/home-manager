{ ... }:
{
  programs.atool = {
    enable = true;
    package = null;
    settings = {
      path_unrar = "unrar-free";
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.atoolrc"
    assertFileContains "home-files/.atoolrc" "path_unrar unrar-free"
  '';
}
