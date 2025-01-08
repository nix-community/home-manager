{ pkgs, ... }:

{
  config = {
    xdg.enable = true;

    programs.helm = {
      enable = true;

      plugins.diff = "${pkgs.kubernetes-helmPlugins.helm-diff}/helm-diff";
    };

    test.stubs.kubernetes-helm = { };

    nmt.script = ''
      assertFileExists home-files/.local/share/helm/plugins/diff/bin/diff
      assertFileExists home-files/.local/share/helm/plugins/diff/plugin.yaml

      assertFileContains home-files/.local/share/helm/plugins/diff/plugin.yaml \
        'command: "$HELM_PLUGIN_DIR/bin/diff"'
    '';
  };
}
