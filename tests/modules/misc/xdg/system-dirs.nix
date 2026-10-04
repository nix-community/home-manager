{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = {
    xdg.systemDirs.config = [
      "/etc/xdg"
      "/foo/bar"
    ];
    xdg.systemDirs.data = [
      "/usr/local/share"
      "/usr/share"
      "/baz/quux"
    ];
    home.sessionVariables.XDG_CONFIG_DIRS = "/plain-config";
    home.sessionSearchVariables.XDG_CONFIG_DIRS = [ "/existing-config" ];
    home.sessionSearchVariables.XDG_DATA_DIRS = lib.mkForce [ "/forced-data" ];

    nmt.script = ''
      envFile=home-files/.config/environment.d/10-home-manager.conf
      assertFileExists $envFile
      assertFileContent $envFile ${pkgs.writeText "expected" ''
        LOCALE_ARCHIVE_2_27=${config.i18n.glibcLocales}/lib/locale/locale-archive
        XDG_BIN_HOME=/home/hm-user/.local/bin
        XDG_CACHE_HOME=/home/hm-user/.cache
        XDG_CONFIG_DIRS=/etc/xdg:/foo/bar''${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}
        XDG_CONFIG_HOME=/home/hm-user/.config
        XDG_DATA_DIRS=/usr/local/share:/usr/share:/baz/quux''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}
        XDG_DATA_HOME=/home/hm-user/.local/share
        XDG_STATE_HOME=/home/hm-user/.local/state
      ''}

      sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
      assertFileExists $sessionVarsFile
      assertFileContains $sessionVarsFile \
        'export XDG_CONFIG_DIRS="/plain-config"'

      (
        XDG_CONFIG_DIRS=/inherited-config
        XDG_DATA_DIRS=/inherited-data
        unset __HM_SESS_VARS_SOURCED __HM_SESS_VARS_MERGED
        . "$TESTED/$sessionVarsFile"
        [ "$XDG_CONFIG_DIRS" = "/existing-config:/etc/xdg:/foo/bar:/plain-config" ] \
          || { echo "XDG_CONFIG_DIRS: $XDG_CONFIG_DIRS"; exit 1; }
        [ "$XDG_DATA_DIRS" = "/forced-data:/inherited-data" ] \
          || { echo "XDG_DATA_DIRS: $XDG_DATA_DIRS"; exit 1; }
      ) || fail "XDG search variable precedence was not preserved"
    '';
  };
}
