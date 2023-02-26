{ config, pkgs, ... }:

{
  services.picom = {
    enable = true;
    fade = true;
    fadeDelta = 5;
    fadeSteps = [ 4.0e-2 4.0e-2 ];
    fadeExclude =
      [ "window_type *= 'menu'" "name ~= 'Firefox$'" "focused = 1" ];
    shadow = true;
    shadowOffsets = [ (-10) (-15) ];
    shadowOpacity = 0.8;
    shadowExclude =
      [ "window_type *= 'menu'" "name ~= 'Firefox$'" "focused = 1" ];
    backend = "xrender";
    vSync = true;
    settings = {
      "unredir-if-possible" = true;
      "dbe" = true;
    };
    extraArgs = [ "--legacy-backends" ];
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
