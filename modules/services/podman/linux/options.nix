{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf mkOption;
  assertions = import ../assertions.nix { inherit lib; };

  cfg = config.services.podman;

  # Define the systemd service type
  quadletInternalType = lib.types.submodule {
    options = {
      assertions = mkOption {
        type = with lib.types; listOf unspecified;
        default = [ ];
        internal = true;
        description = "List of Nix type assertions.";
      };

      dependencies = mkOption {
        type = with lib.types; listOf package;
        default = [ ];
        internal = true;
        description = "List of systemd service dependencies.";
      };

      resourceType = mkOption {
        type = lib.types.str;
        default = "";
        internal = true;
        description = "The type of the podman Quadlet resource.";
      };

      serviceName = mkOption {
        type = lib.types.str;
        internal = true;
        description = "The name of the systemd service.";
      };

      source = mkOption {
        type = lib.types.str;
        internal = true;
        description = "The quadlet source file content.";
      };
    };
  };
in
{
  options.services.podman = {
    internal = {
      quadletDefinitions = mkOption {
        type = lib.types.listOf quadletInternalType;
        default = { };
        internal = true;
        description = "List of quadlet source file content and service names.";
      };
      builtQuadlets = mkOption {
        type = with lib.types; attrsOf package;
        default = { };
        internal = true;
        description = "All built quadlets.";
      };
    };

    enableTypeChecks = mkEnableOption "type checks for podman quadlets";
  };
  config = mkIf cfg.enable {
    assertions = [
      (assertions.assertPlatform "services.podman.enableTypeChecks" config pkgs lib.platforms.linux)
    ];
  };
}
