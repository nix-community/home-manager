{ lib, pkgs, ... }:

let
  # Define the systemd service type
  quadletInternalType = lib.types.submodule {
    options = {

      assertions = lib.mkOption {
        type = with lib.types; listOf unspecified;
        default = [ ];
        description = "List of Nix type assertions.";
      };

      resourceType = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "The type of the podman Quadlet resource.";
      };

      serviceName = lib.mkOption {
        type = lib.types.str;
        description = "The name of the systemd service.";
      };

      source = lib.mkOption {
        type = lib.types.str;
        description = "The quadlet source file content.";
      };

    };
  };
in {
  options.services.podman = {
    internal.quadlet-definitions = lib.mkOption {
      type = lib.types.listOf quadletInternalType;
      default = { };
      description = "List of quadlet source file content and service names.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.podman;
      description = "The podman package to use.";
    };
    enableTypeChecks = lib.mkEnableOption ''
      Enable type checks for podman quadlets.
    '';
  };
}
