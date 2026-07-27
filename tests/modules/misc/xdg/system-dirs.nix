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
        '__hm_entry="/etc/xdg"'
      assertFileContains $sessionVarsFile \
        '__hm_entry="/foo/bar"'
      assertFileContains $sessionVarsFile \
        '__hm_cur="''${XDG_CONFIG_DIRS-}"'
      assertFileContains $sessionVarsFile \
        '  __hm_cur="$__hm_add''${__hm_cur:+:}$__hm_cur"'
      assertFileContains $sessionVarsFile \
        'export XDG_CONFIG_DIRS="$__hm_cur"'
      assertFileContains $sessionVarsFile \
        '__hm_entry="/usr/local/share"'
      assertFileContains $sessionVarsFile \
        '__hm_entry="/usr/share"'
      assertFileContains $sessionVarsFile \
        '__hm_entry="/baz/quux"'
      assertFileContains $sessionVarsFile \
        '__hm_cur="''${XDG_DATA_DIRS-}"'
      assertFileContains $sessionVarsFile \
        'export XDG_DATA_DIRS="$__hm_cur"'
      # Each value must be prepended, not appended. Checked inside that
      # variable's own merge block: on Darwin the terminfo fallback adds a
      # genuine append block elsewhere in the same file.
      grep -B 3 -F 'export XDG_CONFIG_DIRS="$__hm_cur"' "$TESTED/$sessionVarsFile" \
        | grep -qF '__hm_cur="$__hm_add' \
        || fail 'XDG_CONFIG_DIRS must be prepended, not appended'
      grep -B 3 -F 'export XDG_DATA_DIRS="$__hm_cur"' "$TESTED/$sessionVarsFile" \
        | grep -qF '__hm_cur="$__hm_add' \
        || fail 'XDG_DATA_DIRS must be prepended, not appended'
    '';
  };
}
