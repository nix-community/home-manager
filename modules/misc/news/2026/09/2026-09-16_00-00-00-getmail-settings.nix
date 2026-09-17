{ config, ... }:
{
  time = "2026-09-16T00:00:00+00:00";
  condition = builtins.any (account: account.enable && account.getmail.enable) (
    builtins.attrValues config.accounts.email.accounts
  );
  message = ''
    Getmail account configuration now supports native settings through
    `accounts.email.accounts.<name>.getmail.settings`. Existing modeled
    options remain supported.
  '';
}
