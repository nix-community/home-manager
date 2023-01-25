{ ... }:

{
  home.file."disabled" = {
    enable = false;
    text = ''
      This file should not exist
    '';
  };

  nmt.script = ''
    assertPathNotExists home-files/disabled
  '';
}
