{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.parcellite;

in
{
  meta.maintainers = [ lib.maintainers.gleber ];

  options.services.parcellite = {
    enable = lib.mkEnableOption "Parcellite";

    extraOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--no-icon" ];
      description = ''
        Command line arguments passed to Parcellite.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.parcellite;
      defaultText = lib.literalExpression "pkgs.parcellite";
      example = lib.literalExpression "pkgs.clipit";
      description = "Parcellite derivation to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.parcellite" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.parcellite = {
      Unit = {
        Description = "Lightweight GTK+ clipboard manager";
        Requires = [ "tray.target" ];
        After = [
          "graphical-session.target"
          "tray.target"
        ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/${cfg.package.pname} ${lib.escapeShellArgs cfg.extraOptions}";
        Restart = "on-abort";
      };
    };
  };
}
