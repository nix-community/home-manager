{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.services.local-ai;
  settingsPath = "local/config.yml";
in {
  meta.maintainers = [ hm.maintainers.ipsavitsky ];

  options.services.local-ai = {
    enable =
      mkEnableOption "LocalAI is the free, Open Source OpenAI alternative.";

    extraArgs = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra arguments to pass to local-ai";
    };

    package = mkPackageOption pkgs "local-ai" { };

    port = mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to set up local-ai with";
    };

    settings = lib.mkOption {
      inherit (pkgs.formats.yaml { }) type;

      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/${settingsPath}`.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [{
    systemd.user.services.local-ai = {
      Service = {
        ExecStart = lib.escapeShellArgs ([
          (lib.getExe cfg.package)
          "--address"
          ":${toString cfg.port}"
          "--debug"
        ] ++ cfg.extraArgs);

        RuntimeDirectory = "local-ai";
        WorkingDirectory = "%t/local-ai";
      };
    };

    xdg.configFile.${settingsPath}.text = builtins.toJSON cfg.settings;
  }]);
}
