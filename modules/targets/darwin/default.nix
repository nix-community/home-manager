{ config, lib, pkgs, ... }:

with lib;

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (lib.strings) escapeShellArg;

  cfg = config.targets.darwin;

  toDefaultsFile = domain: attrs:
    pkgs.writeText "${domain}.plist"
    (lib.generators.toPlist { } (filterAttrs (n: v: v != null) attrs));

  toActivationCmd = domain: attrs:
    "$DRY_RUN_CMD defaults import ${escapeShellArg domain} ${
      toDefaultsFile domain attrs
    }";

  activationCmds = mapAttrsToList toActivationCmd cfg.defaults;
in {
  imports = [ ./keybindings.nix ./linkapps.nix ./search.nix ];

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

  config = mkIf (cfg.defaults != { }) {
    home.activation.setDarwinDefaults = hm.dag.entryAfter [ "writeBoundary" ] ''
      $VERBOSE_ECHO "Configuring macOS user defaults"
      ${concatStringsSep "\n" activationCmds}
    '';
  };
}
