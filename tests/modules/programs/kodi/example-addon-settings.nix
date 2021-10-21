{ config, ... }:

{
  programs.kodi = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    addonSettings = {
      "service.xbmc.versioncheck".versioncheck_enable = "false";
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.kodi/userdata/addon_data/service.xbmc.versioncheck/settings.xml \
      ${./example-addon-settings-expected.xml}
  '';
}
