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

  options.targets.darwin = {
    defaults = mkOption {
      type = types.submoduleWith { modules = cfg.defaultsSchema; };
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

    defaultsSchema = mkOption {
      type = with types; listOf anything;
      default = [ ];
      example = [
        ({ ... }: { option."org.nixos.foo".enable = mkEnableOption "foo"; })
      ];
      description = ''
        A list of modules to use for defining the option type
        <option>targets.darwin.defaults</option>. This can be used to add
        additional descriptions and type information to individual suboptions as
        well as make the suboptions <literal>mkOverride</literal>-able.

        The modules can be an attribute set, a function returning an attribute
        set, or a path to a file containing such a value.
      '';
    };
  };

  config = mkIf isDarwin {
    targets.darwin.defaultsSchema = [ ./options.nix ];

    home.activation = mkIf (cfg.defaults != { }) {
      setDarwinDefaults = hm.dag.entryAfter [ "writeBoundary" ] ''
        $VERBOSE_ECHO "Configuring macOS user defaults"
        ${concatStringsSep "\n" activationCmds}
      '';
    };
  };
}
