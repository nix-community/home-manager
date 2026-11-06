{ config, pkgs, ... }:
{
  time = "2026-03-28T16:16:08+00:00";
  condition = true;
  message = ''
    A new module is available: `programs.telegram`.

    Telegram is a popular instant messaging application.
    The module allows configuring telegram keybindings and
    autostarting telegram via systemd.
  '';
}
