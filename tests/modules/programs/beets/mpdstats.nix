{ config, ... }:

{
  home.stateVersion = "23.05";

  services.mpd = {
    enable = true;
    musicDirectory = "/my/music/dir";
    network.port = 4242;
  };

  programs.beets = {
    enable = true;
    mpdIntegration.enableStats = true;
  };

  test.stubs = {
    beets = { };
    mpd = { };
  };

  nmt.script = ''
    assertFileExists home-files/.config/beets/config.yaml
    assertFileContent \
      home-files/.config/beets/config.yaml \
      ${./mpdstats-expected.yaml}

    assertFileExists home-files/.config/systemd/user/beets-mpdstats.service
    assertFileContent \
      home-files/.config/systemd/user/beets-mpdstats.service \
      ${./mpdstats-expected.service}
  '';
}
