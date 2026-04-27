{ config, pkgs, ... }:
{
  asserts = {
    awwwInstalled = state: {
      assertion = config.services.awww.enable == state;
      message = "Expected service awww to be ${if state then "enabled" else "disabled"}.";
    };
    packageInstalled = packageName: state: {
      assertion = (builtins.elem pkgs.${packageName} config.home.packages) == state;
      message = "Expected the ${packageName} package to ${if state then "" else "not"} be installed.";
    };
  };
}
