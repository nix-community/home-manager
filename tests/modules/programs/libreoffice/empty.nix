{
  programs.libreoffice = {
    enable = true;
    package = null;
    settings = { };
  };

  nmt.script = ''
    assertPathNotExists "home-files/.config/libreoffice/4/user/registrymodifications.xcu"
  '';
}
