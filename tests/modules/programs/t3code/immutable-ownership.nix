{ config, lib, ... }:

{
  programs.t3code = {
    enable = true;
    package = null;
    mutableUserSettings = false;
    mutableKeybindings = false;
    mutableClientSettings = false;
    userSettings.enableAssistantStreaming = true;
    keybindings = [
      {
        key = "mod+j";
        command = "terminal.toggle";
      }
    ];
    clientSettings.settings.timestampFormat = "locale";
  };

  home.file = {
    ".t3/userdata/settings.json".enable = false;
    ".t3/userdata/keybindings.json".target = ".t3/custom/keybindings.json";
    ".t3/userdata/client-settings.json".source = lib.mkForce (
      builtins.toFile "custom-client-settings.json" "{}"
    );
  };

  nmt.script =
    let
      cleanup = config.home.activation.t3codeImmutableConfig;
      expectedCleanup =
        lib.concatMapStrings
          (
            name:
            lib.hm.generators.mkImpureConfigCleanup {
              file = config.home.file.".t3/userdata/${name}.json";
            }
          )
          [
            "client-settings"
            "keybindings"
          ];
    in
    assert cleanup.before == [ "linkGeneration" ];
    assert cleanup.after == [ "writeBoundary" ];
    assert cleanup.data == expectedCleanup;
    assert !(lib.hasInfix "userdata/settings.json" cleanup.data);
    assert lib.hasInfix ".t3/custom/keybindings.json" cleanup.data;
    ''
      assertPathNotExists "home-files/.t3/userdata/settings.json"
      assertPathNotExists "home-files/.t3/userdata/keybindings.json"
      assertFileExists "home-files/.t3/custom/keybindings.json"
      assertFileContent "home-files/.t3/userdata/client-settings.json" "${
        config.home.file.".t3/userdata/client-settings.json".source
      }"
    '';
}
