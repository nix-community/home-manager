{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg.enable = true;

  programs.herdr.core = {
    enable = false;
    settings.shell = [ "nu" ];
  };

  assertions = [
    {
      assertion = !(lib.elem pkgs.herdr-core config.home.packages);
      message = "Disabled herdr-core must not install a package.";
    }
  ];

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertPathNotExists "home-files/.config/herdr-core/config.toml"
  '';
}
