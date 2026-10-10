{ config, pkgs, ... }:
let
  value = "backslash\\n literal, newline\ncarriage\rreturn";
  escaped = "backslash\\\\n literal, newline\\ncarriage\\rreturn";
  collection = {
    name = "Different display name";
    current_scene = "Main";
    sources = [
      {
        name = "Main";
        id = "scene";
        settings.id_counter = 17;
      }
    ];
    plugin_specific = {
      arbitrary = [
        true
        3
        "text"
      ];
    };
  };
in
{
  programs.obs-studio = {
    enable = true;
    package = pkgs.runCommand "obs" { passthru = { }; } ''
      mkdir -p $out/bin $out/share/obs/obs-plugins
      printf '#!${pkgs.runtimeShell}\n' > $out/bin/obs
      chmod +x $out/bin/obs
    '';
    plugins = [ (config.lib.test.mkStubPackage { }) ];
    settings = {
      global.General = {
        inherit value;
        enabled = true;
        count = 3;
      };
      user.General = { inherit value; };
    };
    profiles.Portable = {
      settings.General = { inherit value; };
      streamEncoder = {
        rate-control = "qvbr";
        qpi = 18;
      };
      recordEncoder.rate-control = "cbr";
      extraFiles."notes.txt".text = "profile note\n";
    };
    sceneCollections.Streaming = collection;
    extraConfigFiles."obs-websocket/config.json".text = ''
      {"server_port":4455}
    '';
  };

  nmt.script = ''
    configDir=home-files/.config/obs-studio
    assertFileContent "$configDir/global.ini" ${builtins.toFile "global-expected" "[General]\ncount=3\nenabled=true\nvalue=${escaped}\n"}
    assertFileContent "$configDir/user.ini" ${builtins.toFile "user-expected" "[General]\nvalue=${escaped}\n"}
    assertFileContent "$configDir/basic/profiles/Portable/basic.ini" ${builtins.toFile "profile-expected" "[General]\nvalue=${escaped}\n"}
    assertFileContains "$configDir/basic/profiles/Portable/streamEncoder.json" '"rate-control": "qvbr"'
    assertFileContains "$configDir/basic/profiles/Portable/recordEncoder.json" '"rate-control": "cbr"'
    assertFileContent "$configDir/basic/profiles/Portable/notes.txt" ${builtins.toFile "obs-note" "profile note\n"}
    assertFileContains "$configDir/plugin_config/obs-websocket/config.json" '"server_port":4455'
    ${pkgs.jq}/bin/jq -e --argjson expected ${pkgs.lib.escapeShellArg (builtins.toJSON collection)} \
      '. == $expected' "$TESTED/$configDir/basic/scenes/Streaming.json"
    test ${if config.xdg.configFile."obs-studio/global.ini".mutable then "true" else "false"} = true
  '';
}
