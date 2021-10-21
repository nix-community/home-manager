{ config, ... }:

{
  programs.kodi = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = { videolibrary.showemptytvshows = "true"; };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.kodi/userdata/advancedsettings.xml \
      ${./example-settings-expected.xml}
  '';
}
