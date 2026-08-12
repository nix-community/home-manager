{ config, ... }:
{
  time = "2026-08-12T12:12:58+00:00";
  condition = config.programs.vdirsyncer.enable;
  message = ''
    Vdirsyncer can now treat local calendar and contact storages as read-only.

    Set `accounts.calendar.accounts.<name>.vdirsyncer.localReadOnly` or
    `accounts.contact.accounts.<name>.vdirsyncer.localReadOnly` to configure
    this behavior.
  '';
}
