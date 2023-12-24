{ config, lib, ... }:

{
  options.programs.installPackages = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to install packages for configured programs by default";
  };

  config = {};
}
