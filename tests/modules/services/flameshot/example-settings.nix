{ lib, pkgs, ... }:

{
  services.flameshot = {
    enable = true;

    settings = {
      General = {
        disabledTrayIcon = true;
        showStartupLaunchMessage = false;
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/flameshot/flameshot.ini \
      ${builtins.toFile "expected.ini" ''
        [General]
        disabledTrayIcon=true
        showStartupLaunchMessage=false
      ''}
  ''
  + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
    assertFileContent \
      "$(normalizeStorePaths LaunchAgentRestartTriggers/org.nix-community.home.flameshot.json)" \
      ${./expected-restart-triggers.json}
  '';
}
