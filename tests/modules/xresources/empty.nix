{ ... }:

{
  xresources.properties = { };

  nmt.script = ''
    assertPathNotExists home-files/.Xresources
  '';
}
