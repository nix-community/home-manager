{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.programs.ntfy-sh;
  yamlFormat = pkgs.formats.yaml { };
in
with lib;
{
  options.programs.ntfy-sh = {
    enable = mkEnableOption "ntfy-sh";
    enableUserService = mkEnableOption "ntfy-sh user service";

    package = mkPackageOption pkgs "ntfy-sh" { };

    configFilePath = mkOption {
      type = types.path;
      default = "${config.xdg.configHome}/ntfy/client.yml";
      defaultText = literalExpression ''"''${config.xdg.configHome}/ntfy/client.yml"'';
      description = "Path where the configuration file is placed.";
    };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      description = "Configuration for the ntfy binary";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.ntfy-sh = {
      enable = true;
      target = cfg.configFilePath;

      onChange = ''
        systemctl --user restart ntfy-sh-client
      '';

      source = mkIf (cfg.settings != { }) (yamlFormat.generate "ntfy-sh-config" cfg.settings);
    };

    systemd.user.services.ntfy-sh-client = mkIf cfg.enableUserService {
      Unit.Description = "ntfy-sh client service";

      Install.WantedBy = [ "multi-user.target" ];

      Service = {
        Type = "simple";
        Restart = "on-failure";
        ExecStart = ''
          ${cfg.package}/bin/ntfy subscribe --config ${cfg.configFilePath} --from-config
        '';
      };
    };
  };

  meta.maintainers = [ maintainers.matthiasbeyer ];
}
