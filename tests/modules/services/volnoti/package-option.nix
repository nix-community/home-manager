{ config, lib, pkgs, ... }:

with lib;

{
  services.volnoti = {
    enable = true;
    package = pkgs.writeShellScriptBin "fake-volnoti" ''
      true
    '';
  };

  home.stateVersion = "24.05";

  test.stubs.volnoti = { };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/volnoti.service
    assertFileExists $serviceFile

    assertFileContains $serviceFile \
      'ExecStart=${lib.getExe config.services.volnoti.package}'

    assertFileContains $serviceFile \
      'WantedBy=graphical-session.target'
  '';
}
