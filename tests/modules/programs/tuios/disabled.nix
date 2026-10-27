{ config, pkgs, ... }:
{
  programs.tuios = {
    enable = false;
    settings.appearance.theme = "catppuccin_mocha";
  };

  assertions = [
    {
      assertion = !(builtins.elem pkgs.tuios config.home.packages);
      message = "Disabled TUIOS is not installed.";
    }
  ];

  nmt.script = ''
    assertPathNotExists home-path/bin/tuios
    assertPathNotExists home-files/.config/tuios
    assertPathNotExists "home-files/Library/Application Support/tuios"
  '';
}
