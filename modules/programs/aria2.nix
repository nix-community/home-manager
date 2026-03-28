{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.aria2;

  keyValueFormat = pkgs.formats.keyValue { };
in
{
  meta.maintainers = [ lib.maintainers.justinlovinger ];

  imports = [
    (lib.mkRemovedOptionModule [
      "programs"
      "aria2"
      "extraConfig"
    ] "This option has been removed. Please use 'programs.aria2.settings' instead.")
  ];

  options.programs.aria2 = {
    enable = lib.mkEnableOption "aria2";

    package = lib.mkPackageOption pkgs "aria2" { nullable = true; };

    settings = lib.mkOption {
      type = keyValueFormat.type;
      default = { };
      description = ''
        Options to add to {file}`aria2.conf` file.
        See
        {manpage}`aria2c(1)`
        for options.
      '';
      example = lib.literalExpression ''
        {
          listen-port = 60000;
          dht-listen-port = 60000;
          seed-ratio = 1.0;
          max-upload-limit = "50K";
          ftp-pasv = true;
        }
      '';
    };

    systemd = {
      enable = lib.mkEnableOption "Aria2 systemd integration";

      targets = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ "default.target" ];
        example = [ "graphical-session.target" ];
        description = ''
          Systemd targets that will start the aria2c user service.

          Note: if `programs.aria2.settings.input-file` is set but
          the file doesn't exist, then the aria2 service will fail.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."aria2/aria2.conf" = lib.mkIf (cfg.settings != { }) {
      source = keyValueFormat.generate "aria2.conf" cfg.settings;
    };

    systemd.user.services.aria2 = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Aria2c daemon";
        Documentation = "man:aria2c(1)";
        PartOf = cfg.systemd.targets;
        After = cfg.systemd.targets;
        X-Restart-Triggers = lib.mkIf (cfg.settings != { }) [
          "${config.xdg.configFile."aria2/aria2.conf".source}"
        ];
      };

      Service = {
        ExecStart = "${lib.getExe cfg.package} --enable-rpc";
        Restart = "on-failure";
      };

      Install.WantedBy = cfg.systemd.targets;
    };
  };
}
