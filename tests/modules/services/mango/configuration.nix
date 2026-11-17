_:

{
  wayland.windowManager.mango = {
    enable = true;
    systemd.enable = false;
    settings = {
      blur = 0;
      bind = [
        "SUPER,r,reload_config"
        "SUPER,space,spawn,fuzzel"
        "SUPER,Return,spawn,footclient"
        "SUPER,m,quit"
        "SUPER,Tab,focusstack,next"
      ];
      focus_color = "0xa2a2a2ee";
    };
  };
  nmt.script = ''
    assertFileExists home-files/.config/mango/config.conf
  '';
}
