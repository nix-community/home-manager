{ config, ... }:

{
  programs.t3code = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
  };

  nmt.script = ''
    assertPathNotExists "home-files/.t3/userdata/settings.json"
    assertPathNotExists "home-files/.t3/userdata/keybindings.json"
    assertPathNotExists "home-files/.t3/userdata/client-settings.json"
  '';
}
