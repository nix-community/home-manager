{ pkgs, lib, ... }:

{
  config = {
    xdg.enable = lib.mkForce false;

    programs.helm = {
      enable = true;

      plugins.unittest =
        "${pkgs.kubernetes-helmPlugins.helm-unittest}/helm-unittest";
    };

    test.stubs.kubernetes-helm = { };

    nmt.script = let
      helmPluginsDir = if !pkgs.stdenv.isDarwin then
        ".local/share/helm/plugins"
      else
        "Library/helm/plugins";
    in ''
      assertFileExists home-files/${helmPluginsDir}/unittest/untt
      assertFileExists home-files/${helmPluginsDir}/unittest/plugin.yaml

      assertFileContains home-files/${helmPluginsDir}/unittest/plugin.yaml \
        'command: "$HELM_PLUGIN_DIR/untt"'
    '';
  };
}
