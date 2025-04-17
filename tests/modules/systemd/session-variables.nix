{ config, pkgs, ... }:

{
  systemd.user.sessionVariables = {
    V_int = 1;
    V_str = "2";
  };

  nmt.script = ''
    envFile=home-files/.config/environment.d/10-home-manager.conf
    assertFileExists $envFile
    assertFileContent $envFile ${pkgs.writeText "expected" ''
      LOCALE_ARCHIVE_2_27=${config.i18n.glibcLocales}/lib/locale/locale-archive
      V_int=1
      V_str=2
      XDG_CACHE_HOME=''${HOME}/.cache
      XDG_CONFIG_HOME=''${HOME}/.config
      XDG_DATA_HOME=''${HOME}/.local/share
      XDG_STATE_HOME=''${HOME}/.local/state
    ''}
  '';
}
