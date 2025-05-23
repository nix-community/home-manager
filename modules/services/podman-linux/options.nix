{ lib, pkgs, ... }:

let
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

    package = lib.mkPackageOption pkgs "podman" { };

    enableTypeChecks = lib.mkEnableOption "type checks for podman quadlets";
  };
}
