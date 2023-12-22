{lib, ...}:

let
  # Define the type which the systemd services will be derived from
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
    };
  }; 
in {
  options.internal.podman-quadlet-definitions = lib.mkOption {
    type = lib.types.listOf quadletInternalType;
    default = {};
    description = "List of quadlet source file content and service names.";
  };
}