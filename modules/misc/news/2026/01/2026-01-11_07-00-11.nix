{ pkgs, ... }:
{
  time = "2026-01-11T04:00:11+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new option is available: `systemd.user.packages`.

    This option is the Home Manager equivalent of NixOS’s `systemd.packages`
    option and provides a way to specify packages providing systemd user units.

    This option is similar to `dbus.packages`.
  '';
}
