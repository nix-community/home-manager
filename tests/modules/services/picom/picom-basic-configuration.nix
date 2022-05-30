{ config, pkgs, ... }:

{
  services.picom = {
    enable = true;
    fade = true;
    fadeDelta = 5;
    fadeSteps = [ "0.04" "0.04" ];
    fadeExclude =
      [ "window_type *= 'menu'" "name ~= 'Firefox$'" "focused = 1" ];
    shadow = true;
    shadowOffsets = [ (-10) (-15) ];
    shadowOpacity = "0.8";
    shadowExclude =
      [ "window_type *= 'menu'" "name ~= 'Firefox$'" "focused = 1" ];
    backend = "xrender";
    vSync = true;
    extraOptions = ''
      unredir-if-possible = true;
      dbe = true;
    '';
    experimentalBackends = true;
  };

  test.stubs.picom = { };

  nmt.script = ''
    assertFileContent \
        home-files/.config/picom/picom.conf \
        ${./picom-basic-configuration-expected.conf}

    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/picom.service)
    assertFileContent \
        "$serviceFile" \
        ${./picom-basic-configuration-expected.service}
  '';
}
