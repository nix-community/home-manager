{ pkgs, ... }: {
  home.enableNixpkgsReleaseCheck = false;

  programs.bumblebee-status = {
    enable = true;
    plugins = [
      {
        name = "pulsein";
        alias = "micro";
        parameters.left-click = "nix run nixpkgs#pavucontrol";
      }
      {
        name = "pulseout";
        parameters.left-click = "nix run nixpkgs#pavucontrol";
      }
      {
        name = "playerctl";
        autohide = true;
      }
      {
        name = "battery";
        errorhide = true;
        autohide = true;
      }
      { name = "time"; }
      { name = "arandr"; }
      {
        name = "xkcd";
        autohide = true;
      }
      { name = "system"; }
    ];
    theme = "default";
    interval = 1;
  };

  test.stubs.bumblebee-status = { };

  nmt.script = ''
    assertFileExists home-files/.config/bumblebee-status/config
    assertFileContent home-files/.config/bumblebee-status/config ${
      ./expected.ini
    }
  '';
}
