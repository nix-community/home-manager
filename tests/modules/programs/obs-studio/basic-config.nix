{
  config,
  lib,
  pkgs,
  ...
}:
let
  obsPackage = pkgs.runCommand "obs" { passthru = { }; } ''
    mkdir -p $out/bin $out/share/obs/obs-plugins
    printf '#!${pkgs.runtimeShell}\n' > $out/bin/obs
    chmod +x $out/bin/obs
  '';
in
{
  programs.obs-studio = {
    enable = true;
    package = obsPackage;
    plugins = [ (config.lib.test.mkStubPackage { }) ];

    settings = {
      global.General = {
        MaxLogs = 10;
        ProcessPriority = "Normal";
      };
      user.Basic = {
        Profile = "Portable";
        ProfileDir = "Portable";
        SceneCollection = "Streaming";
        SceneCollectionFile = "Streaming.json";
      };
    };

    profiles.Portable = {
      settings = {
        General.Name = "Portable";
        Video = {
          BaseCX = 3440;
          BaseCY = 1440;
          OutputCX = 1920;
          OutputCY = 1080;
          FPSCommon = 60;
        };
      };
      streamEncoder = {
        rate-control = "qvbr";
        qpi = 18;
      };
      recordEncoder.rate-control = "cbr";
      extraFiles."notes.txt".text = "profile note\n";
    };

    sceneCollections.Streaming = {
      currentScene = "Main";
      currentProgramScene = "Main";
      resolution = {
        x = 2100;
        y = 1428;
      };
      quickTransitions = [
        {
          name = "Cut";
          duration = 300;
          id = 1;
          hotkeys = [ ];
          fade_to_black = false;
        }
      ];
      raw.preview_locked = true;

      sources.desktop = {
        id = "pipewire-screen-capture-source";
        uuid = "11111111-2222-3333-4444-555555555555";
        settings.ShowCursor = true;
        portal = {
          restorePolicyAction = "skip";
          restoreMatchRules = [
            { pattern = "project-a"; }
            {
              pattern = "shared-title";
              scope = "any_app";
            }
          ];
        };
        raw = {
          settings = {
            rawSetting = true;
            RestorePolicyAction = 2;
          };
        };
      };

      scenes.Main.items = [
        {
          source = "desktop";
          id = 7;
          scaleRef = {
            x = 3440.0;
            y = 1440.0;
          };
        }
      ];
    };

    extraConfigFiles."obs-websocket/config.json".text = ''
      {"server_port":4455}
    '';
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      activationScript = pkgs.writeScript "obs-studio-activation" config.home.activation.obsStudioConfig.data;
    in
    ''
      export HOME=$TMPDIR/hm-user

      sed "s|@TMPDIR@|$TMPDIR|g" ${activationScript} > $TMPDIR/activate
      run() { "$@"; }
      . $TMPDIR/activate

      configDir="$HOME/.config/obs-studio"
      sceneFile="$configDir/basic/scenes/Streaming.json"
      manifestFile="$HOME/.local/state/home-manager/obs-studio/manifest.json"

      assertFileExists "$configDir/global.ini"
      assertFileContains "$configDir/global.ini" "MaxLogs=10"
      assertFileContains "$configDir/user.ini" "SceneCollection=Streaming"
      assertFileContains "$configDir/basic/profiles/Portable/basic.ini" "BaseCX=3440"
      assertFileContains "$configDir/basic/profiles/Portable/streamEncoder.json" '"rate-control": "qvbr"'
      assertFileContains "$configDir/basic/profiles/Portable/recordEncoder.json" '"rate-control": "cbr"'
      assertFileContent "$configDir/basic/profiles/Portable/notes.txt" ${builtins.toFile "obs-note" "profile note\n"}
      assertFileContains "$configDir/plugin_config/obs-websocket/config.json" '"server_port":4455'
      assertFileExists "$manifestFile"
      ${pkgs.jq}/bin/jq -e '.version == 1' "$manifestFile" >/dev/null
      ${pkgs.jq}/bin/jq -e '.module == "programs.obs-studio"' "$manifestFile" >/dev/null
      ${pkgs.jq}/bin/jq -e '.files[] | select(.path == "global.ini" and .kind == "ini" and .origin == "settings.global")' "$manifestFile" >/dev/null
      ${pkgs.jq}/bin/jq -e '.files[] | select(.path == "basic/profiles/Portable/basic.ini" and .kind == "ini" and .origin == "profiles.Portable.settings")' "$manifestFile" >/dev/null
      ${pkgs.jq}/bin/jq -e '.files[] | select(.path == "basic/scenes/Streaming.json" and .kind == "json" and .origin == "sceneCollections.Streaming")' "$manifestFile" >/dev/null
      ${pkgs.jq}/bin/jq -e '.files[] | select(.path == "plugin_config/obs-websocket/config.json" and .kind == "raw" and .origin == "extraConfigFiles.obs-websocket/config.json")' "$manifestFile" >/dev/null

      assertFileExists "$sceneFile"
      desktop_uuid="$(${pkgs.jq}/bin/jq -r '.sources[] | select(.name == "desktop") | .uuid' "$sceneFile")"
      item_uuid="$(${pkgs.jq}/bin/jq -r '.sources[] | select(.name == "Main") | .settings.items[0].source_uuid' "$sceneFile")"
      test "$desktop_uuid" = "11111111-2222-3333-4444-555555555555"
      test "$item_uuid" = "$desktop_uuid"

      ${pkgs.jq}/bin/jq -e '.preview_locked == true' "$sceneFile" >/dev/null
      ${pkgs.jq}/bin/jq -e '.current_scene == "Main" and .current_program_scene == "Main"' "$sceneFile" >/dev/null
      ${pkgs.jq}/bin/jq -e '.scene_order == [{"name":"Main"}]' "$sceneFile" >/dev/null
      ${pkgs.jq}/bin/jq -e '.sources[] | select(.name == "desktop") | .id == "pipewire-screen-capture-source"' "$sceneFile" >/dev/null
      ${pkgs.jq}/bin/jq -e '.sources[] | select(.name == "desktop") | .settings.RestorePolicyAction == 2' "$sceneFile" >/dev/null
      ${pkgs.jq}/bin/jq -e '.sources[] | select(.name == "desktop") | .settings.RestoreMatchRules == "project-a\nany_app: shared-title"' "$sceneFile" >/dev/null
      ${pkgs.jq}/bin/jq -e '.sources[] | select(.name == "desktop") | .settings.rawSetting == true' "$sceneFile" >/dev/null
      ${pkgs.jq}/bin/jq -e '.sources[] | select(.name == "desktop") | .settings | has("RestoreToken") | not' "$sceneFile" >/dev/null
    '';
}
