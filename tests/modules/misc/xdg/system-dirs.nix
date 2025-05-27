{
  config,
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

    nmt.script = ''
      envFile=home-files/.config/environment.d/10-home-manager.conf
      assertFileExists $envFile
      assertFileContent $envFile ${pkgs.writeText "expected" ''
        LOCALE_ARCHIVE_2_27=${config.i18n.glibcLocales}/lib/locale/locale-archive
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
        'export XDG_CONFIG_DIRS="/etc/xdg:/foo/bar''${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}"'
      assertFileContains $sessionVarsFile \
        'export XDG_DATA_DIRS="/usr/local/share:/usr/share:/baz/quux''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"'
    '';
  };
}
