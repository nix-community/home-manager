{ config, ... }:

{
  programs.t3code = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
  };

  nmt.script =
    assert !(config.home.activation ? t3codeImmutableConfig);
    assert !(config.home.activation ? t3codeSettingsActivation);
    assert !(config.home.activation ? t3codeKeybindingsActivation);
    assert !(config.home.activation ? t3codeClientSettingsActivation);
    ''
      assertPathNotExists "home-files/.t3/userdata/settings.json"
      assertPathNotExists "home-files/.t3/userdata/keybindings.json"
      assertPathNotExists "home-files/.t3/userdata/client-settings.json"
    '';
}
