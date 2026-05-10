{ config, ... }:

{
  programs.t3code = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    mutableUserSettings = false;
    mutableKeybindings = false;
    mutableClientSettings = false;
    userSettings = {
      enableAssistantStreaming = true;
      providerInstances.codex = {
        driver = "codex";
        enabled = true;
        config = {
          enabled = true;
          binaryPath = "codex";
          homePath = "";
          shadowHomePath = "";
          customModels = [ ];
        };
      };
    };
    keybindings = [
      {
        key = "mod+d";
        command = "terminal.split";
        when = "terminalFocus";
      }
      {
        key = "mod+d";
        command = "diff.toggle";
        when = "!terminalFocus";
      }
    ];
    clientSettings = {
      settings = {
        favorites = [
          {
            provider = "codex";
            model = "gpt-5.5";
          }
        ];
        sidebarProjectGroupingMode = "repository";
        timestampFormat = "locale";
      };
    };
  };

  nmt.script =
    let
      expectedSettings = builtins.toFile "expected-settings.json" ''
        {
          "enableAssistantStreaming": true,
          "providerInstances": {
            "codex": {
              "config": {
                "binaryPath": "codex",
                "customModels": [],
                "enabled": true,
                "homePath": "",
                "shadowHomePath": ""
              },
              "driver": "codex",
              "enabled": true
            }
          }
        }
      '';

      expectedKeybindings = builtins.toFile "expected-keybindings.json" ''
        [
          {
            "command": "terminal.split",
            "key": "mod+d",
            "when": "terminalFocus"
          },
          {
            "command": "diff.toggle",
            "key": "mod+d",
            "when": "!terminalFocus"
          }
        ]
      '';

      expectedClientSettings = builtins.toFile "expected-client-settings.json" ''
        {
          "settings": {
            "favorites": [
              {
                "model": "gpt-5.5",
                "provider": "codex"
              }
            ],
            "sidebarProjectGroupingMode": "repository",
            "timestampFormat": "locale"
          }
        }
      '';
    in
    ''
      assertFileExists "home-files/.t3/userdata/settings.json"
      assertFileContent "home-files/.t3/userdata/settings.json" "${expectedSettings}"

      assertFileExists "home-files/.t3/userdata/keybindings.json"
      assertFileContent "home-files/.t3/userdata/keybindings.json" "${expectedKeybindings}"

      assertFileExists "home-files/.t3/userdata/client-settings.json"
      assertFileContent "home-files/.t3/userdata/client-settings.json" "${expectedClientSettings}"
    '';
}
