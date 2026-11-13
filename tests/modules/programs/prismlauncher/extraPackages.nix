{ config, ... }:
{
  programs.prismlauncher = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    extraPackages = [ (config.lib.test.mkStubPackage { }) ];
  };
}
