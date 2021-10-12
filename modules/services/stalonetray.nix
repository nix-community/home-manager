{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.stalonetray;

in {
  options = {
    services.stalonetray = {
      enable = mkEnableOption "Stalonetray system tray";

      package = mkOption {
        default = pkgs.stalonetray;
        defaultText = literalExpression "pkgs.stalonetray";
        type = types.package;
        example = literalExpression "pkgs.stalonetray";
        description = "The package to use for the Stalonetray binary.";
      };

      config = mkOption {
        type = with types; attrsOf (nullOr (either str (either bool int)));
        description = ''
          Stalonetray configuration as a set of attributes.
        '';
        default = { };
        example = {
          geometry = "3x1-600+0";
          decorations = null;
          icon_size = 30;
          sticky = true;
          background = "#cccccc";
        };
      };

      extraConfig = mkOption {
        type = types.lines;
        description = "Additional configuration lines for stalonetrayrc.";
        default = "";
        example = ''
          geometry 3x1-600+0
          decorations none
          icon_size 30
          sticky true
          background "#cccccc"
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];

      systemd.user.services.stalonetray = {
        Unit = {
          Description = "Stalonetray system tray";
          PartOf = [ "tray.target" ];
        };

        Install = { WantedBy = [ "tray.target" ]; };

        Service = {
          ExecStart = "${cfg.package}/bin/stalonetray";
          Restart = "on-failure";
        };
      };
    }

    (mkIf (cfg.config != { }) {
      home.file.".stalonetrayrc".text = let
        valueToString = v:
          if isBool v then
            (if v then "true" else "false")
          else if (v == null) then
            "none"
          else
            ''"${toString v}"'';
      in concatStrings (mapAttrsToList (k: v: ''
        ${k} ${valueToString v}
      '') cfg.config);
    })

    (mkIf (cfg.extraConfig != "") {
      home.file.".stalonetrayrc".text = cfg.extraConfig;
    })
  ]);
}
