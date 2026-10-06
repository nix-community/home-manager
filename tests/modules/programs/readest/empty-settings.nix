{ config, ... }:

{
  programs.readest = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "readest"; };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/com.bilingify.readest/settings.json
    assertFileNotRegex activate 'com\.bilingify\.readest/settings\.json'
  '';
}
