{ config, pkgs, ... }:

{
  time = "2021-09-23T17:04:48+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux && config.services.screen-locker.enable;
  message = ''

    'xautolock' is now optional in 'services.screen-locker', and the
    'services.screen-locker' options have been reorganized for clarity.
    See the 'xautolock' and 'xss-lock' options modules in
    'services.screen-locker'.
  '';
}
