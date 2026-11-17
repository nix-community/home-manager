{pkgs, config, ...}:

{
  wayland.windowManager.mango = {
    enable = true;
    systemd.enable = false;
    checkConfig = false;
    settings = {
      blur = 0;
      bind = [
        "SUPER,r,reload_config"
        "SUPER,Return,spawn,footclient"
      ];
      animation.type.open = "zoom";
    };
  };
  nmt.script = ''
    config=home-files/.config/mango/config.conf
    assertFileExists $config
    assertFileContains $config "blur = 0"
    assertFileContains $config "bind = SUPER,r,reload_config"
    assertFileContains $config "bind = SUPER,Return,spawn,footclient"
    assertFileContains $config "animation_type_open = zoom"
  '';
}
