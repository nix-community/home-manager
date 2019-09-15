{config, lib, pkgs, ...}:

with lib;

let

  cfg = config.services.sxhkd;

  hotkeybindingsStr = concatStringsSep "\n" (
    mapAttrsToList (hotkey: command:
      optionalString (command != null) ''
        ${hotkey}
          ${command}
      ''
    )
    cfg.hotkeybindings
  );

in

{
  options.services.sxhkd = {
    enable = mkEnableOption "Simple X hotkey daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.sxhkd;
      defaultText = literalExample "pkgs.sxhkd";
      description = "sxhkd package to install.";
      example =  literalExample "pkgs.sxhkd";
    };

    hotkeybindings = mkOption {
      type = types.attrsOf (types.nullOr types.str);
      default = {};
      description = "An attribute set that assigns a hotkey to a command";
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
      description = "Additional configuration to add";
      example = literalExample ''
        super + {_,shift +} {1-9,0}
          i3-msg {workspace,move container to workspace} {1-10}
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."sxhkd/sxhkdrc".text = concatStringsSep "\n" [
      hotkeybindingsStr
      cfg.extraConfig
    ];

    systemd.user.services.sxhkd = {
      Unit = {
        Description = "Simple X hotkey daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Environment = "PATH=" + concatStringsSep ":" [
          "${config.home.profileDirectory}/bin"
          "/run/wrappers/bin"
          "/run/current-system/sw/bin"
        ];
        ExecStart = "${cfg.package}/bin/sxhkd";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
