{config, lib, pkgs, ...}:

with lib;

let

  cfg = config.services.sxhkd;

  keybindingsStr = concatStringsSep "\n" (
    mapAttrsToList (hotkey: command:
      optionalString (command != null) ''
        ${hotkey}
          ${command}
      ''
    )
    cfg.keybindings
  );

in

{
  options.services.sxhkd = {
    enable = mkEnableOption "simple X hotkey daemon";

    keybindings = mkOption {
      type = types.attrsOf (types.nullOr types.str);
      default = {};
      description = "An attribute set that assigns hotkeys to commands.";
      example = literalExample ''
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
      example = literalExample ''
        super + {_,shift +} {1-9,0}
          i3-msg {workspace,move container to workspace} {1-10}
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.sxhkd ];

    xdg.configFile."sxhkd/sxhkdrc".text = concatStringsSep "\n" [
      keybindingsStr
      cfg.extraConfig
    ];

    systemd.user.services.sxhkd = {
      Unit = {
        Description = "simple X hotkey daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.sxhkd}/bin/sxhkd";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
