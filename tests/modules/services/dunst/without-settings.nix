{ config, ... }:
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
  };

  nmt.script = ''
    configFile=home-files/.config/dunst/dunstrc
    serviceFile=home-files/.config/systemd/user/dunst.service

    assertFileExists $configFile
    assertFileContent $configFile ${./without-settings-expected.ini}

    assertFileExists $serviceFile
    assertFileContent \
      $(normalizeStorePaths $serviceFile) \
      ${builtins.toFile "expected.service" ''
        [Service]
        BusName=org.freedesktop.Notifications
        Environment=
        ExecReload=/nix/store/00000000000000000000000000000000-dunst/bin/dunstctl reload
        ExecStart=/nix/store/00000000000000000000000000000000-dunst/bin/dunst
        Type=dbus

        [Unit]
        After=graphical-session.target
        Description=Dunst notification daemon
        PartOf=graphical-session.target
        X-Reload-Triggers=/nix/store/00000000000000000000000000000000-hm_dunstdunstrc
      ''}
  '';
}
