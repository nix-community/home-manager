{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.podman;

  # Define the systemd service type
  quadletInternalType = lib.types.submodule {
    options = {
      assertions = lib.mkOption {
        type = with lib.types; listOf unspecified;
        default = [ ];
        internal = true;
        description = "List of Nix type assertions.";
      };

      dependencies = lib.mkOption {
        type = with lib.types; listOf package;
        default = [ ];
        internal = true;
        description = "List of systemd service dependencies.";
      };

      resourceType = lib.mkOption {
        type = lib.types.str;
        default = "";
        internal = true;
        description = "The type of the podman Quadlet resource.";
      };

      serviceName = lib.mkOption {
        type = lib.types.str;
        internal = true;
        description = "The name of the systemd service.";
      };

      source = lib.mkOption {
        type = lib.types.str;
        internal = true;
        description = "The quadlet source file content.";
      };
    };
  };

  # Check if any Linux-specific options are configured
  hasLinuxConfig =
    cfg.containers != { }
    || cfg.builds != { }
    || cfg.images != { }
    || cfg.networks != { }
    || cfg.volumes != { }
    || cfg.enableTypeChecks;
in
{
  options.services.podman = {
    internal = {
      quadletDefinitions = lib.mkOption {
        type = lib.types.listOf quadletInternalType;
        default = { };
        internal = true;
        description = "List of quadlet source file content and service names.";
      };
      builtQuadlets = lib.mkOption {
        type = with lib.types; attrsOf package;
        default = { };
        internal = true;
        description = "All built quadlets.";
      };
    };

    enableTypeChecks = lib.mkEnableOption "type checks for podman quadlets";
  };

  config = lib.mkIf (cfg.enable && hasLinuxConfig) {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = ''
          Podman Linux-specific options (quadlets) are configured, but you are not on a Linux system.
          The following options are only available on Linux:
          - services.podman.containers
          - services.podman.builds
          - services.podman.images
          - services.podman.networks
          - services.podman.volumes
          - services.podman.enableTypeChecks
          - services.podman.autoUpdate

          Please remove these Linux-specific configurations from your home-manager configuration.
        '';
      }
    ];
  };
}
