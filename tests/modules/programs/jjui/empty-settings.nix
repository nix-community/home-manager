{
  config = {
    programs.jjui.enable = true;
    xdg.enable = false;

    nmt.script = ''
      assertPathNotExists home-files/.config/jjui
      assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
        '^export JJUI_CONFIG_DIR='
    '';
  };
}
