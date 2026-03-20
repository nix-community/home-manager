{
  programs.wofi = {
    enable = true;
    style = ./basic-style.css;
  };

  nmt.script = ''
    assertFileExists home-files/.config/wofi/style.css
    assertFileContent home-files/.config/wofi/style.css \
    ${./basic-style.css}
  '';
}
