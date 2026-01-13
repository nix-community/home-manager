{
  pkgs,
  config,
  lib,
  ...
}:

let
  inherit (lib) types;
  cfg = config.services.local-ai;
in
{
  meta.maintainers = [ lib.maintainers.ipsavitsky ];

  options.services.local-ai = {
    enable = lib.mkEnableOption "LocalAI is the free, Open Source OpenAI alternative.";

    package = lib.mkPackageOption pkgs "local-ai" { };

    environment = lib.mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Additional environment passed to local-ai service. Used to configure local-ai

        See <https://localai.io/basics> for available options.
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
        Environment = lib.mapAttrsToList (key: val: "${key}=${val}") cfg.environment;
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
