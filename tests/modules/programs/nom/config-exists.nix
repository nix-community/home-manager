{ ... }:
{
  programs.nom = {
    enable = true;
    settings = {
      autoread = true;
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/nom/config.yml"
  '';
}
