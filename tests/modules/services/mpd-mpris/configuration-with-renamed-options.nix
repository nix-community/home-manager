{ lib, options, ... }:

let
  renamedWarning =
    name:
    "The option `services.mpd-mpris.mpd.${name}' defined in ${
      lib.showFiles options.services.mpd-mpris.mpd.${name}.files
    } has been renamed to `services.mpd-mpris.settings.${name}'.";
in
{
  services.mpd-mpris = {
    enable = true;
    mpd = {
      network = "tcp";
      host = "example.com";
      port = 1234;
    };
  };

  test.asserts.warnings.expected = map renamedWarning [
    "port"
    "host"
    "network"
  ];

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/mpd-mpris.service
    assertFileContent "$serviceFile" ${./configuration-with-renamed-options.service}
  '';
}
