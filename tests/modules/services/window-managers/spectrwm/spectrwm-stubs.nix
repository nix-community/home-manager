{ config, lib, ... }: {
  # Avoid unnecessary downloads in CI jobs and/or make out paths constant, i.e.,
  # not containing hashes, version numbers etc.
  test.stubs = { spectrwm = { }; };

  nixpkgs.overlays = [
    (_final: _prev: {
      dbus = config.lib.test.mkStubPackage { name = "dbus"; };
      systemd =
        lib.makeOverridable (_attrs: config.lib.test.mkStubPackage { }) { };
    })
  ];
}
