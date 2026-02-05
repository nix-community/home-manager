{ config, ... }:
{
  time = "2026-02-05T03:02:20+00:00";
  condition = config.xdg.userDirs.enable;
  message = ''
    The `xdg.userDirs` module now supports non-Linux platforms.

    The `xdg.userDirs.package` option is now available. Set it to `null`
    to prevent Home Manager from installing `xdg-user-dirs`.

    The `xdg.userDirs.extraConfig` option no longer recommends keys of the
    form `XDG_<name>_DIR`; use just `<name>` instead (e.g. `DESKTOP`).
    The old form is deprecated and will emit a warning.

    The `xdg.userDirs.setSessionVariables` option was added to control
    whether XDG user directory environment variables like `XDG_DESKTOP_DIR` are
    set. It now defaults to `false` for `home.stateVersion` 26.05 and later.
  '';
}
