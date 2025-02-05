{
  services.syncthing.tray = true;

  test.asserts.warnings.expected = [
    "Specifying 'services.syncthing.tray' as a boolean is deprecated, set 'services.syncthing.tray.enable' instead. See https://github.com/nix-community/home-manager/pull/1257."
  ];

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/syncthingtray.service
  '';
}
