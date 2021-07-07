{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.targets.darwin;

  toDefaultsFile = domain: attrs:
    pkgs.writeText "${domain}.plist" (lib.generators.toPlist { } attrs);

  toActivationCmd = domain: attrs:
    "$DRY_RUN_CMD defaults import ${escapeShellArg domain} ${
      toDefaultsFile domain attrs
    }";

  nonNullDefaults =
    mapAttrs (domain: attrs: (filterAttrs (n: v: v != null) attrs))
    cfg.defaults;
  writableDefaults = filterAttrs (domain: attrs: attrs != { }) nonNullDefaults;
  activationCmds = mapAttrsToList toActivationCmd writableDefaults;
in {
  imports = [ ./fonts.nix ./keybindings.nix ./linkapps.nix ./search.nix ];

  options.targets.darwin.defaults = mkOption {
    type = types.submodule ./options.nix;
    default = { };
    example = {
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
    };
    description = ''
      Set macOS user defaults. Values set to <literal>null</literal> are
      ignored.

      <warning>
        <para>
          Some settings might require a re-login to take effect.
        </para>
      </warning>
    '';
  };

  config = mkIf (activationCmds != [ ]) {
    assertions = [
      (hm.assertions.assertPlatform "targets.darwin.defaults" pkgs
        platforms.darwin)
    ];

    home.activation.setDarwinDefaults = hm.dag.entryAfter [ "writeBoundary" ] ''
      $VERBOSE_ECHO "Configuring macOS user defaults"
      ${concatStringsSep "\n" activationCmds}
    '';
  };
}
