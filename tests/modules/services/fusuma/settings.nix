{ config, pkgs, ... }:

{
  imports = [ ./fusuma-stubs.nix ];

  services.fusuma = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@fusuma@"; };
    extraPackages = [ pkgs.xdotool ];

    settings = {
      threshold = { swipe = 1; };
      interval = { swipe = 7; };
      swipe = {
        "3" = { left = { command = "xdotool key ctrl+alt+Right"; }; };
        "4" = { left = { command = "xdotool key ctrl+shift+alt+Right"; }; };
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/fusuma/config.yml \
      ${./expected-settings.yaml}
  '';
}
