{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.sxhkd;

  keybindingsStr = concatStringsSep "\n" (mapAttrsToList (hotkey: command:
    optionalString (command != null) ''
      ${hotkey}
        ${command}
    '') cfg.keybindings);

in {
  imports = [
    (mkRemovedOptionModule [ "services" "sxhkd" "extraPath" ]
      "This option is no longer needed and can be removed.")
  ];

  options.services.sxhkd = {
    enable = mkEnableOption "simple X hotkey daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.sxhkd;
      defaultText = "pkgs.sxhkd";
      description =
        "Package containing the <command>sxhkd</command> executable.";
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description =
        "Command line arguments to invoke <command>sxhkd</command> with.";
      example = literalExpression ''[ "-m 1" ]'';
    };

    keybindings = mkOption {
      type = types.attrsOf (types.nullOr types.str);
      default = { };
      description = "An attribute set that assigns hotkeys to commands.";
      example = literalExpression ''
        {
          "super + shift + {r,c}" = "i3-msg {restart,reload}";
          "super + {s,w}"         = "i3-msg {stacking,tabbed}";
        }
      '';
    };

    extraConfig = mkOption {
      default = "";
      type = types.lines;
      description = "Additional configuration to add.";
      example = literalExpression ''
        super + {_,shift +} {1-9,0}
          i3-msg {workspace,move container to workspace} {1-10}
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.sxhkd" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."sxhkd/sxhkdrc".text =
      concatStringsSep "\n" [ keybindingsStr cfg.extraConfig ];

    xsession.initExtra = let
      sxhkdCommand = "${cfg.package}/bin/sxhkd ${toString cfg.extraOptions}";
    in ''
      systemctl --user stop sxhkd.scope 2> /dev/null || true
      systemd-cat -t sxhkd systemd-run --user --scope -u sxhkd ${sxhkdCommand} &
    '';
  };
}
