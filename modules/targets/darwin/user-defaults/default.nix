{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.targets.darwin;

  mkActivationCmds =
    isLocal: settings:
    let
      toDefaultsFile = domain: attrs: pkgs.writeText "${domain}.plist" (lib.generators.toPlist { } attrs);

      cliFlags = lib.optionalString isLocal "-currentHost";

      toActivationCmd =
        domain: attrs:
        "run /usr/bin/defaults ${cliFlags} import ${lib.escapeShellArg domain} ${toDefaultsFile domain attrs}";

      nonNullDefaults = lib.mapAttrs (domain: attrs: (lib.filterAttrs (n: v: v != null) attrs)) settings;

      writableDefaults = lib.filterAttrs (domain: attrs: attrs != { }) nonNullDefaults;
    in
    lib.mapAttrsToList toActivationCmd writableDefaults;

  defaultsCmds = mkActivationCmds false cfg.defaults;
  currentHostDefaultsCmds = mkActivationCmds true cfg.currentHostDefaults;

  activationCmds = defaultsCmds ++ currentHostDefaultsCmds;
in
{
  meta.maintainers = [ lib.maintainers.midchildan ];

  options.targets.darwin.defaults = lib.mkOption {
    type = lib.types.submodule ./opts-allhosts.nix;
    default = { };
    example = {
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
    };
    description = ''
      Set macOS user defaults. Values set to `null` are
      ignored.

      ::: {.warning}
      Some settings might require a re-login to take effect.
      :::

      ::: {.warning}
      Some settings are only read from
      {option}`targets.darwin.currentHostDefaults`.
      :::
    '';
  };

  options.targets.darwin.currentHostDefaults = lib.mkOption {
    type = lib.types.submodule ./opts-currenthost.nix;
    default = { };
    example = {
      "com.apple.controlcenter" = {
        BatteryShowPercentage = true;
      };
    };
    description = ''
      Set macOS user defaults. Unlike {option}`targets.darwin.defaults`,
      the preferences will only be applied to the currently logged-in host. This
      distinction is important for networked accounts.

      Values set to `null` are ignored.

      ::: {.warning}
      Some settings might require a re-login to take effect.
      :::
    '';
  };

  config = lib.mkIf (activationCmds != [ ]) {
    assertions = [
      (lib.hm.assertions.assertPlatform "targets.darwin.defaults" pkgs lib.platforms.darwin)
    ];

    warnings =
      let
        batteryOptionName = ''targets.darwin.currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage'';
        batteryPercentage = lib.attrByPath [
          "com.apple.menuextra.battery"
          "ShowPercent"
        ] null cfg.defaults;
        webkitDevExtras = lib.attrByPath [
          "com.apple.Safari"
          "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled"
        ] null cfg.defaults;
      in
      lib.optional (batteryPercentage != null) ''
        The option 'com.apple.menuextra.battery.ShowPercent' no longer works on
        macOS 11 and later. Instead, use '${batteryOptionName}'.
      ''
      ++ lib.optional (webkitDevExtras != null) ''
        The option 'com.apple.Safari.com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled'
        is no longer present in recent versions of Safari.
      '';

    home.activation.setDarwinDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      verboseEcho "Configuring macOS user defaults"
      ${lib.concatStringsSep "\n" activationCmds}
    '';
  };
}
