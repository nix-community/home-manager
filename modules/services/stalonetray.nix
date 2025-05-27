{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkIf
    mkOption
    types
    literalExpression
    ;

  cfg = config.services.stalonetray;

in
{
  options = {
    services.stalonetray = {
      enable = lib.mkEnableOption "Stalonetray system tray";

      package = lib.mkPackageOption pkgs "stalonetray" { };

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

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          (lib.hm.assertions.assertPlatform "services.stalonetray" pkgs lib.platforms.linux)
        ];

        home.packages = [ cfg.package ];

        systemd.user.services.stalonetray = {
          Unit = {
            Description = "Stalonetray system tray";
            PartOf = [ "tray.target" ];
          };

          Install = {
            WantedBy = [ "tray.target" ];
          };

          Service = {
            ExecStart = "${cfg.package}/bin/stalonetray";
            Restart = "on-failure";
          };
        };
      }

      (mkIf (cfg.config != { }) {
        xdg.configFile."stalonetrayrc".text =
          let
            valueToString =
              v:
              if lib.isBool v then
                (if v then "true" else "false")
              else if (v == null) then
                "none"
              else
                ''"${toString v}"'';
          in
          lib.concatStrings (
            lib.mapAttrsToList (k: v: ''
              ${k} ${valueToString v}
            '') cfg.config
          );
      })

      (mkIf (cfg.extraConfig != "") {
        xdg.configFile."stalonetrayrc".text = cfg.extraConfig;
      })
    ]
  );
}
