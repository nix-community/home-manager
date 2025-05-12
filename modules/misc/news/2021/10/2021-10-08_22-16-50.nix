{ config, pkgs, ... }:

{
  time = "2021-10-08T22:16:50+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux && config.programs.rofi.enable;
  message = ''

    Rofi version '1.7.0' removed many options that were used by the module
    and replaced them with custom themes, which are more flexible and
    powerful.

    You can replicate your old configuration by moving those options to
    'programs.rofi.theme'. Keep in mind that the syntax is different so
    you may need to do some changes.
  '';
}
