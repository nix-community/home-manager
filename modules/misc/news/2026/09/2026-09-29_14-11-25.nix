{ config, ... }:
{
  time = "2026-09-29T18:11:25+00:00";
  condition = config.programs.thunderbird.enable;
  message = ''
    Thunderbird now supports LDAP directory configuration through
    `programs.thunderbird.profiles.<name>.directories` as well as setting an account default with
    `accounts.email.accounts.<name>.thunderbird.directory`.
  '';
}
