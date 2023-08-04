{ ... }:

{
  services.activitywatch.enable = true;

  test.stubs.activitywatch = { };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/activitywatch.service
    assertFileExists home-files/.config/systemd/user/activitywatch.target

    assertPathNotExists home-files/.config/activitywatch/aw-server-rust/config.toml
  '';
}
