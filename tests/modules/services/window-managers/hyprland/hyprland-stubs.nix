{ config, lib, ... }: {
  # Avoid unnecessary downloads in CI jobs and/or make out paths constant, i.e.,
  # not containing hashes, version numbers etc.
  test.stubs = {
    xdg-desktop-portal = { };
    xwayland = { };
  };

  nixpkgs.overlays = [
    (_final: _prev: {
      dbus = config.lib.test.mkStubPackage { name = "dbus"; };
      hyprland = lib.makeOverridable
        (attrs: config.lib.test.mkStubPackage { name = "hyprland"; }) { };
      xdg-desktop-portal-hyprland = lib.makeOverridable (_:
        config.lib.test.mkStubPackage { name = "xdg-desktop-portal-hyprland"; })
        { };
      systemd =
        lib.makeOverridable (_attrs: config.lib.test.mkStubPackage { }) { };
    })
  ];
}
