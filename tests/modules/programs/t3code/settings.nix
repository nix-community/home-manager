{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.t3code = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
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

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      preexistingSettings = builtins.toFile "preexisting-settings.json" ''
        {
          "enableAssistantStreaming": false,
          "providerInstances": {
            "codex": {
              "driver": "codex",
              "enabled": false,
              "config": {
                "enabled": false,
                "binaryPath": "old-codex",
                "homePath": "",
                "shadowHomePath": "",
                "customModels": []
              }
            },
            "opencode": {
              "driver": "opencode",
              "enabled": true,
              "config": {
                "enabled": true,
                "binaryPath": "opencode",
                "serverUrl": "",
                "serverPassword": "",
                "customModels": []
              }
            }
          }
        }
      '';

      preexistingKeybindings = builtins.toFile "preexisting-keybindings.json" ''
        [
          {
            "key": "mod+d",
            "command": "old.terminalSplit",
            "when": "terminalFocus"
          },
          {
            "key": "mod+d",
            "command": "old.diffToggle",
            "when": "!terminalFocus"
          },
          {
            "key": "mod+j",
            "command": "terminal.toggle"
          }
        ]
      '';

      preexistingClientSettings = builtins.toFile "preexisting-client-settings.json" ''
        {
          "settings": {
            "favorites": [],
            "sidebarProjectGroupingMode": "workspace",
            "timestampFormat": "relative",
            "unmanagedSetting": true
          }
        }
      '';

      expectedSettings = builtins.toFile "expected-settings.json" ''
        {
          "enableAssistantStreaming": true,
          "providerInstances": {
            "codex": {
              "driver": "codex",
              "enabled": true,
              "config": {
                "enabled": true,
                "binaryPath": "codex",
                "homePath": "",
                "shadowHomePath": "",
                "customModels": []
              }
            },
            "opencode": {
              "driver": "opencode",
              "enabled": true,
              "config": {
                "enabled": true,
                "binaryPath": "opencode",
                "serverUrl": "",
                "serverPassword": "",
                "customModels": []
              }
            }
          }
        }
      '';

      expectedKeybindings = builtins.toFile "expected-keybindings.json" ''
        [
          {
            "key": "mod+d",
            "command": "diff.toggle",
            "when": "!terminalFocus"
          },
          {
            "key": "mod+d",
            "command": "terminal.split",
            "when": "terminalFocus"
          },
          {
            "key": "mod+j",
            "command": "terminal.toggle"
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
            "timestampFormat": "locale",
            "unmanagedSetting": true
          }
        }
      '';

      settingsPath = ".t3/userdata/settings.json";
      keybindingsPath = ".t3/userdata/keybindings.json";
      clientSettingsPath = ".t3/userdata/client-settings.json";
      settingsActivation = pkgs.writeScript "settings-activation" config.home.activation.t3codeSettingsActivation.data;
      keybindingsActivation = pkgs.writeScript "keybindings-activation" config.home.activation.t3codeKeybindingsActivation.data;
      clientSettingsActivation = pkgs.writeScript "client-settings-activation" config.home.activation.t3codeClientSettingsActivation.data;
    in
    ''
      export HOME=$TMPDIR/hm-user

      mkdir -p $HOME/.t3/userdata
      cat ${preexistingSettings} > $HOME/${settingsPath}
      cat ${preexistingKeybindings} > $HOME/${keybindingsPath}
      cat ${preexistingClientSettings} > $HOME/${clientSettingsPath}

      substitute ${settingsActivation} $TMPDIR/settings-activate --subst-var TMPDIR
      chmod +x $TMPDIR/settings-activate
      $TMPDIR/settings-activate

      substitute ${keybindingsActivation} $TMPDIR/keybindings-activate --subst-var TMPDIR
      chmod +x $TMPDIR/keybindings-activate
      $TMPDIR/keybindings-activate

      substitute ${clientSettingsActivation} $TMPDIR/client-settings-activate --subst-var TMPDIR
      chmod +x $TMPDIR/client-settings-activate
      $TMPDIR/client-settings-activate

      assertFileContent "$HOME/${settingsPath}" "${expectedSettings}"
      assertFileContent "$HOME/${keybindingsPath}" "${expectedKeybindings}"
      assertFileContent "$HOME/${clientSettingsPath}" "${expectedClientSettings}"

      $TMPDIR/settings-activate
      $TMPDIR/keybindings-activate
      $TMPDIR/client-settings-activate

      assertFileContent "$HOME/${settingsPath}" "${expectedSettings}"
      assertFileContent "$HOME/${keybindingsPath}" "${expectedKeybindings}"
      assertFileContent "$HOME/${clientSettingsPath}" "${expectedClientSettings}"
    '';
}
