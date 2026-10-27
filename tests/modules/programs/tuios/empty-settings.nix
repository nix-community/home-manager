{ config, pkgs, ... }:
{
  programs.tuios.enable = true;

  assertions = [
    {
      assertion = builtins.elem pkgs.tuios config.home.packages;
      message = "TUIOS is installed even with empty settings.";
    }
  ];

  nmt.script = ''
    assertPathNotExists home-files/.config/tuios
    assertPathNotExists "home-files/Library/Application Support/tuios"
  '';
}
