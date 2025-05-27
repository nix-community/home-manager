{ pkgs, config, ... }:
let
  inherit (config.lib.test) mkStubPackage;
in
{
  dbus.packages = [
    (mkStubPackage {
      name = "test";
      buildScript = ''
        mkdir -p $out/share/dbus-1/services
        printf '%s' test > $out/share/dbus-1/services/test.service
      '';
    })
  ];

  nmt.script = ''
    serviceFile=home-files/.local/share/dbus-1/services/test.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile "${pkgs.writeText "expected" "test"}"
  '';
}
