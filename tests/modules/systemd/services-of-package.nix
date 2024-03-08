{ pkgs, ... }:

let
  pkg = pkgs.xdg-desktop-portal-gtk;
  expectedService = pkgs.lib.readFile
    "${pkgs.xdg-desktop-portal-gtk}/share/systemd/user/xdg-desktop-portal-gtk.service";
in {
  systemd.user.servicesOfPackages = [ pkg ];

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/xdg-desktop-portal-gtk.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile \
      '${pkgs.writeText "expected" expectedService}'
  '';
}
