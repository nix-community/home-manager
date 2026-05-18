{ config, ... }:
{
  time = "2026-05-18T17:00:00+00:00";
  condition = config.programs.zsh.enable;
  message = ''
    The `programs.zsh` module now sources Home Manager session variables from
    `.zprofile` for login shells. Non-login shells continue to source them from
    `.zshenv`.

    This keeps `home.sessionPath` entries from being overwritten or reordered
    by system login startup files such as NixOS' `/etc/zprofile` or macOS'
    `path_helper`.
  '';
}
