{
  programs.jjui = {
    enable = true;
    configDir = "/home/hm-user/custom-jjui";
    configLua = "function setup(config) end";
  };

  nmt.script = ''
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export JJUI_CONFIG_DIR="/home/hm-user/custom-jjui"'
    assertFileContent home-files/custom-jjui/config.lua \
      ${builtins.toFile "jjui-config.lua" "function setup(config) end"}
    assertPathNotExists home-files/custom-jjui/config.toml
  '';
}
