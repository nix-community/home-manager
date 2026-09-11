{
  services.gromit-mpx = {
    enable = false;
    extraConfig = throw "disabled Gromit-MPX extra configuration was evaluated";
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/gromit-mpx.ini
    assertPathNotExists home-files/.config/gromit-mpx.cfg
    assertPathNotExists home-files/.config/systemd/user/gromit-mpx.service
  '';
}
