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
        Additional environment variables for the local-ai service.

        These variables are written to the world-readable Nix store as
        `Environment=` lines in the systemd unit, so avoid putting secrets
        such as `LOCALAI_API_KEY` here. You can set
        `systemd.user.services.local-ai.Service.EnvironmentFile` to a file
        outside the store instead.

        See <https://localai.io/docs/reference/cli-reference/> for available options.
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
