{lib, pkgs, ...}:

let
  # Define the systemd service type
  quadletInternalType = lib.types.submodule {
    options = {
      serviceName = lib.mkOption {
        type = lib.types.str;
        description = "The name of the systemd service.";
      };

      unitType = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "The type of the systemd unit.";
      };

      source = lib.mkOption {
        type = lib.types.str;
        description = "The quadlet source file content.";
      };

      assertions = lib.mkOption {
        type = with lib.types; listOf unspecified;
        default = [];
        description = "List of Nix type assertions.";
      };
    };
  };
in {
  options.internal.podman-quadlet-definitions = lib.mkOption {
    type = lib.types.listOf quadletInternalType;
    default = {};
    description = "List of quadlet source file content and service names.";
  };

  options.services.podman.package = lib.mkOption {
    type = lib.types.package;
    default = pkgs.podman;
    description = "The podman package to use.";
  };
}
