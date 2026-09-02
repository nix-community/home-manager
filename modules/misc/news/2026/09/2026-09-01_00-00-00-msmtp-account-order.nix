{ config, ... }:
{
  time = "2026-09-01T00:00:00+00:00";
  condition = config.programs.msmtp.enable;
  message = ''
    The `programs.msmtp.accountOrder` option controls the order of enabled
    accounts in the generated msmtp configuration. Listed accounts are written
    first, and unlisted accounts follow in their attribute-set order.
  '';
}
