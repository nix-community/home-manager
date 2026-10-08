{ config, lib, ... }:
let
  inherit (config.lib.test) mkStubPackage;
in
{
  services.dunst = {
    enable = true;
    package = mkStubPackage {
      name = "dunst";
      buildScript = ''
        mkdir -p $out/share/dbus-1/services
        echo test > $out/share/dbus-1/services/org.knopwob.dunst.service
      '';
    };
    settings = {
      global = {
        timeout = 30;
        font = "Droid Sans 9";
        icon_path = lib.mkForce "/run/current-system/sw/share/icons/hicolor/32x32/status:/run/current-system/sw/share/icons/hicolor/32x32/devices";
      };

      bgtvolctl = lib.hm.dag.entryAfter [ "global" ] {
        appname = "bgtvolctl";
        timeout = 1;
      };

      urgency_critical = lib.hm.dag.entryAfter [ "bgtvolctl" ] {
        background = "#c33";
      };
    };
  };

  nmt.script = ''
    configFile=home-files/.config/dunst/dunstrc

    assertFileExists $configFile
    assertFileContent $configFile ${./with-ordered-settings-expected.ini}
  '';
}
