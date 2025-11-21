{ config, ... }:

{
  home.stateVersion = "23.05";

  programs.beets = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@beets@"; };
    mpdIntegration = {
      enableStats = true;
      host = "10.0.0.42";
      port = 6601;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/beets/config.yaml
    assertFileContent \
      home-files/.config/beets/config.yaml \
      ${./mpdstats-external-expected.yaml}

    assertFileExists home-files/.config/systemd/user/beets-mpdstats.service
    assertFileContent \
      home-files/.config/systemd/user/beets-mpdstats.service \
      ${./mpdstats-external-expected.service}
  '';
}
