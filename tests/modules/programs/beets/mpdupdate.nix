{ config, ... }:

{
  home.stateVersion = "23.05";

  programs.beets = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@beets@"; };
    mpdIntegration.enableUpdate = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/beets/config.yaml
    assertFileContent \
      home-files/.config/beets/config.yaml \
      ${./mpdupdate-expected.yaml}
  '';
}
