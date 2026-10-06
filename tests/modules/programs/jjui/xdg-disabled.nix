{
  programs.jjui = {
    enable = true;
    configLua = "function setup(config) end";
  };

  xdg = {
    enable = false;
    configHome = "/home/hm-user/custom-xdg";
  };

  nmt.script = ''
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      '^export XDG_CONFIG_HOME='
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export JJUI_CONFIG_DIR="/home/hm-user/custom-xdg/jjui"'
    assertFileExists home-files/custom-xdg/jjui/config.lua
    assertPathNotExists home-files/custom-xdg/jjui/config.toml
  '';
}
