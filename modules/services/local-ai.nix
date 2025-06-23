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

      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/${settingsPath}`.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        systemd.user.services.local-ai = {
          Service = {
            ExecStart = lib.escapeShellArgs (
              [
                (lib.getExe cfg.package)
              ]
              ++ cfg.extraArgs
            );

            RuntimeDirectory = "local-ai";
            WorkingDirectory = "%t/local-ai";
          };
        };

        xdg.configFile.${settingsPath}.text = lib.generators.toYAML { } cfg.settings;
      }
    ]
  );
}
