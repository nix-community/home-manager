{ config, pkgs, options, lib, ... }:

{
  config = {
    services.screen-locker = {
      enable = true;
      inactiveInterval = 5;
      lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c AA0000";
      xssLockExtraOptions = [ "-test" ];
      xautolockExtraOptions = [ "-test" ];
      enableDetectSleep = true;
    };

    test.stubs.i3lock = { };
    test.stubs.xss-lock = { };

    # Use the same verification script as the basic configuration. The result
    # with the old options should be identical.
    nmt.script = (import ./basic-configuration.nix {
      inherit config pkgs;
    }).config.nmt.script;

    test.asserts.warnings.expected = with lib;
      let
        renamed = {
          xssLockExtraOptions = "xss-lock.extraOptions";
          xautolockExtraOptions = "xautolock.extraOptions";
          enableDetectSleep = "xautolock.detectSleep";
        };
      in mapAttrsToList (old: new:
        builtins.replaceStrings [ "\n" ] [ " " ] ''
          The option `services.screen-locker.${old}' defined in
          ${showFiles options.services.screen-locker.${old}.files}
          has been renamed to `services.screen-locker.${new}'.'') renamed;
  };
}
