{ config, ... }:

let stubPackage = config.lib.test.mkStubPackage { };

in {
  services.activitywatch = {
    enable = true;
    settings = {
      port = 3012;
      custom_static = { custom-watcher = stubPackage; };
    };
    watchers = {
      # These are basically examples of a real world usage.
      aw-watcher-afk.package = stubPackage;
      aw-watcher-window.package = stubPackage;

      custom-watcher = {
        package = stubPackage;
        settings = {
          foo = "bar";
          baz = 8;
        };
        settingsFilename = "config.toml";
      };

      another-custom-watcher = {
        package = stubPackage;
        settings = {
          hello = "there";
          world = "plan";
        };
      };
    };
  };

  nmt.script = ''
    # Basic check for the bare setup.
    assertFileExists home-files/.config/systemd/user/activitywatch.service
    assertFileExists home-files/.config/systemd/user/activitywatch.target

    # Basic check for the watchers setup.
    assertFileExists home-files/.config/systemd/user/activitywatch-watcher-aw-watcher-afk.service
    assertFileExists home-files/.config/systemd/user/activitywatch-watcher-aw-watcher-window.service

    # Checking for the generated configurations (and the ones that is not
    # supposed to exist).
    assertFileExists home-files/.config/activitywatch/aw-server-rust/config.toml
    assertFileExists home-files/.config/activitywatch/custom-watcher/config.toml
    assertFileExists home-files/.config/activitywatch/another-custom-watcher/another-custom-watcher.toml
    assertPathNotExists home-files/.config/activitywatch/aw-watcher-afk/aw-watcher-afk.toml
    assertPathNotExists home-files/.config/activitywatch/aw-watcher-window/aw-watcher-window.toml
  '';
}
