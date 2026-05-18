{ pkgs, ... }:
let
  obsPackage = pkgs.runCommand "obs" { passthru = { }; } ''
    mkdir -p $out/bin $out/share/obs/obs-plugins
    printf '#!${pkgs.runtimeShell}\n' > $out/bin/obs
    chmod +x $out/bin/obs
  '';
in
{
  test.asserts.assertions.expected = [
    "programs.obs-studio.profiles attribute names must be safe relative path components."
    "programs.obs-studio.sceneCollections attribute names must be safe relative path components."
    "programs.obs-studio.extraConfigFiles attribute names must be safe relative paths."
    "programs.obs-studio.profiles.*.extraFiles attribute names must be safe relative paths."
    "programs.obs-studio.profiles.*.extraFiles must not override generated OBS profile files."
    "programs.obs-studio.integrations.*.enable requires a matching derivation in pkgs.obs-studio-plugins or an explicit package override."
    "programs.obs-studio.integrations attribute names must be safe relative path components."
    "programs.obs-studio.integrations.*.extraConfigFiles attribute names must be safe relative paths."
    "programs.obs-studio.extraConfigFiles must not override generated integration config files."
    "programs.obs-studio.sceneCollections.Bad.currentScene must reference a declared scene."
    "programs.obs-studio.sceneCollections.Bad.scenes.*.items.*.source must reference a declared source."
    "programs.obs-studio.sceneCollections.Bad.sources.*.settings must not contain RestoreToken unless portal.restoreToken is explicitly set."
  ];

  programs.obs-studio = {
    enable = true;
    package = obsPackage;
    profiles = {
      "../Bad".settings.General.Name = "bad";
      Safe = {
        settings.General.Name = "safe";
        extraFiles = {
          "../escape.ini".text = "bad";
          "basic.ini".text = "collision";
        };
      };
    };
    extraConfigFiles = {
      "bad//path.json".text = "{}";
      "safe-plugin/config.json".text = "{}";
    };
    sceneCollections.Bad = {
      currentScene = "Missing";
      sources.desktop = {
        id = "pipewire-screen-capture-source";
        settings.RestoreToken = "machine-local-token";
      };
      scenes.Main.items = [
        { source = "missing-source"; }
      ];
    };
    sceneCollections."bad/name".raw = { };
    integrations = {
      missing-plugin.enable = true;
      "../plugin".extraConfigFiles."config.json".text = "{}";
      safe-plugin.extraConfigFiles = {
        "/absolute.json".text = "{}";
        "config.json".text = "{}";
      };
    };
  };
}
