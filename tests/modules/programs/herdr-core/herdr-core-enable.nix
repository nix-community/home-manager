{ config, lib, ... }:
{
  xdg.enable = true;

  programs.herdr.core = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "herdr-core"; };
  };

  assertions = [
    {
      assertion = lib.elem config.programs.herdr.core.package config.home.packages;
      message = "herdr-core must install the configured package.";
    }
  ];

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertPathNotExists "home-files/.config/herdr-core/config.toml"
  '';
}
