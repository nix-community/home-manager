{ config, pkgs, ... }:

{
  services.mopidy = {
    enable = true;
    extensionPackages = [ pkgs.mopidy-local ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/mopidy.service
    assertFileExists home-files/.config/systemd/user/mopidy-scan.service
  '';
}
