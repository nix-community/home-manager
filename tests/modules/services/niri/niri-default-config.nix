{ pkgs, ... }:

{
  wayland.windowManager.niri = {
    enable = true;
    checkConfig = false;
    portalPackage = null;
    systemd.enable = false;
    xwaylandSatellitePackage = null;

    enableDefaultConfig = true;
    settings.prefer-no-csd = { };
  };

  test.stubs.niri = {
    outPath = null;
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/niri
    '';
    extraAttrs = {
      src = pkgs.runCommand "niri-stub-source" { } ''
        mkdir -p $out/resources
        touch $out/resources/default-config.kdl
      '';
    };
  };

  nmt.script = ''
    niriConfig=home-files/.config/niri/config.kdl

    assertFileExists "$niriConfig"
    assertFileContent "$(normalizeStorePaths "$niriConfig")" "${./niri-default-config-expected.kdl}"
  '';
}
