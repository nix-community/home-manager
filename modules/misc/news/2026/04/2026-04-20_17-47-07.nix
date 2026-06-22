{ pkgs, ... }:
{
  time = "2026-04-20T17:47:07+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    On Darwin, Home Manager now exports `TERMINFO_DIRS` in
    `hm-session-vars.sh` so that terminfo entries from Home Manager-installed
    packages (e.g. `kitty`, `alacritty`) are discoverable. The system path
    `/usr/share/terminfo` is preserved as a fallback.

    `TERM` is also re-exported so the current shell picks up newly available
    terminfo entries.

    To opt out, override `home.sessionVariables.TERMINFO_DIRS` (which is set
    with `lib.mkDefault`).
  '';
}
