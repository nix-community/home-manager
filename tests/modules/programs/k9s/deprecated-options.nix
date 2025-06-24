{ lib, options, ... }:

{
  programs.k9s = {
    enable = true;
    skin = {
      k9s = {
        body = {
          fgColor = "dodgerblue";
          bgColor = "#ffffff";
          logoColor = "#0000ff";
        };
        info = {
          fgColor = "lightskyblue";
          sectionColor = "steelblue";
        };
      };
    };
    hotkey = {
      shift-0 = {
        shortCut = "Shift-0";
        description = "Viewing pods";
        command = "pods";
      };
    };
    plugin = {
      fred = {
        shortCut = "Ctrl-L";
        description = "Pod logs";
        scopes = [ "po" ];
        command = "kubectl";
        background = false;
        args = [
          "logs"
          "-f"
          "$NAME"
          "-n"
          "$NAMESPACE"
          "--context"
          "$CLUSTER"
        ];
      };
    };
    views = {
      k9s.views = {
        "v1/services" = {
          columns = [
            "NAME"
            "TYPE"
          ];
        };
      };
      "v1/pods" = {
        columns = [
          "AGE"
          "NAMESPACE"
          "NAME"
          "IP"
          "NODE"
          "STATUS"
          "READY"
        ];
      };
    };
  };

  test.asserts.warnings.enable = true;
  test.asserts.warnings.expected = [
    "The option `programs.k9s.plugin' defined in ${lib.showFiles options.programs.k9s.plugin.files} has been renamed to `programs.k9s.plugins'."
    "The option `programs.k9s.hotkey' defined in ${lib.showFiles options.programs.k9s.hotkey.files} has been renamed to `programs.k9s.hotKeys'."
    "The option `programs.k9s.skin' defined in ${lib.showFiles options.programs.k9s.skin.files} has been renamed to `programs.k9s.skins.skin'."
    "Nested 'k9s.views' structure in programs.k9s.views is deprecated, move the contents directly under programs.k9s.views"
  ];
  nmt.script = ''
    assertFileExists home-files/.config/k9s/skins/skin.yaml
    assertFileContent \
      home-files/.config/k9s/skins/skin.yaml \
      ${./example-skin-expected.yaml}
  '';
}
