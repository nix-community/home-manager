{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.targets.darwin;

  mkActivationCmds = isLocal: settings:
    let
      toDefaultsFile = domain: attrs:
        pkgs.writeText "${domain}.plist" (lib.generators.toPlist { } attrs);

      cliFlags = lib.optionalString isLocal "-currentHost";

      toActivationCmd = domain: attrs:
        "$DRY_RUN_CMD /usr/bin/defaults ${cliFlags} import ${
          escapeShellArg domain
        } ${toDefaultsFile domain attrs}";

      nonNullDefaults =
        mapAttrs (domain: attrs: (filterAttrs (n: v: v != null) attrs))
        settings;

      writableDefaults =
        filterAttrs (domain: attrs: attrs != { }) nonNullDefaults;
    in mapAttrsToList toActivationCmd writableDefaults;

  defaultsCmds = mkActivationCmds false cfg.defaults;
  currentHostDefaultsCmds = mkActivationCmds true cfg.currentHostDefaults;

  activationCmds = defaultsCmds ++ currentHostDefaultsCmds;
in {
  meta.maintainers = [ maintainers.midchildan ];

  options.targets.darwin.defaults = mkOption {
    type = types.submodule ./opts-allhosts.nix;
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

  options.targets.darwin.currentHostDefaults = mkOption {
    type = types.submodule ./opts-currenthost.nix;
    default = { };
    example = {
      "com.apple.controlcenter" = { BatteryShowPercentage = true; };
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

  config = mkIf (activationCmds != [ ]) {
    assertions = [
      (hm.assertions.assertPlatform "targets.darwin.defaults" pkgs
        platforms.darwin)
    ];

    warnings = let
      batteryOptionName = ''
        targets.darwin.currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage'';
      batteryPercentage =
        attrByPath [ "com.apple.menuextra.battery" "ShowPercent" ] null
        cfg.defaults;
      webkitDevExtras = attrByPath [
        "com.apple.Safari"
        "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled"
      ] null cfg.defaults;
    in optional (batteryPercentage != null) ''
      The option 'com.apple.menuextra.battery.ShowPercent' no longer works on
      macOS 11 and later. Instead, use '${batteryOptionName}'.
    '' ++ optional (webkitDevExtras != null) ''
      The option 'com.apple.Safari.com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled'
      is no longer present in recent versions of Safari.
    '';

    home.activation.setDarwinDefaults = hm.dag.entryAfter [ "writeBoundary" ] ''
      $VERBOSE_ECHO "Configuring macOS user defaults"
      ${concatStringsSep "\n" activationCmds}
    '';
  };
}
