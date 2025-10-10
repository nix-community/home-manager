{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.services.local-ai;
  settingsPath = "local/config.yml";
in
{
  meta.maintainers = [ lib.hm.maintainers.ipsavitsky ];

  options.services.local-ai = {
    enable = lib.mkEnableOption "LocalAI is the free, Open Source OpenAI alternative.";

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments to pass to local-ai";
    };

    package = lib.mkPackageOption pkgs "local-ai" { };

    settings = lib.mkOption {
      inherit (pkgs.formats.yaml { }) type;

      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/${settingsPath}`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.local-ai = {
      Unit = {
        Description = "Server for local large language models";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    xdg.configFile.${settingsPath}.text = lib.generators.toYAML { } cfg.settings;
  };
}
