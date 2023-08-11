{ config, lib, pkgs, ... }:

let
  cfg = config.virtualisation.containers;

  inherit (lib) mkOption types;

  toml = pkgs.formats.toml { };
in {
  meta.maintainers = [ lib.maintainers.michaelCTS ];

  options.virtualisation.containers = {
    enable = lib.mkEnableOption "the common containers configuration module";

    ociSeccompBpfHook.enable = lib.mkEnableOption "the OCI seccomp BPF hook";

    registries = {
      search = mkOption {
        type = types.listOf types.str;
        default = [ "docker.io" "quay.io" ];
        description = ''
          List of repositories to search.
        '';
      };

      insecure = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          List of insecure repositories.
        '';
      };

      block = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          List of blocked repositories.
        '';
      };
    };

    policy = mkOption {
      type = types.attrs;
      default = { };
      example = lib.literalExpression ''
        {
          default = [ { type = "insecureAcceptAnything"; } ];
          transports = {
            docker-daemon = {
              "" = [ { type = "insecureAcceptAnything"; } ];
            };
          };
        }
      '';
      description = ''
        Signature verification policy file.
        If this option is empty the default policy file from
        `skopeo` will be used.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."containers/registries.conf".source =
      toml.generate "registries.conf" {
        registries = lib.mapAttrs (n: v: { registries = v; }) cfg.registries;
      };

    xdg.configFile."containers/policy.json".source = if cfg.policy != { } then
      pkgs.writeText "policy.json" (builtins.toJSON cfg.policy)
    else
      "${pkgs.skopeo.src}/default-policy.json";
  };

}
