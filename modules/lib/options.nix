{ lib }:
{
  mkInstallOptionWithDefault =
    default: name: lib.mkOption {
      inherit default;
      type = lib.types.bool;
      example = true;
      description = "Whether to install package ${name}";
    };
}
