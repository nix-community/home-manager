{ config, ... }:

{
  programs.k9s = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      k9s = {
        refreshRate = 2;
        maxConnRetry = 5;
        enableMouse = true;
        headless = false;
      };
    };
    hotkey = {
      hotKey = {
        shift-0 = {
          shortCut = "Shift-0";
          description = "Viewing pods";
          command = "pods";
        };
      };
    };
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
    aliases = { alias = { pp = "v1/pods"; }; };
    plugin = {
      plugin = {
        fred = {
          shortCut = "Ctrl-L";
          description = "Pod logs";
          scopes = [ "po" ];
          command = "kubectl";
          background = false;
          args =
            [ "logs" "-f" "$NAME" "-n" "$NAMESPACE" "--context" "$CLUSTER" ];
        };
      };
    };
    views = {
      k9s = {
        views = {
          "v1/pods" = {
            columns = [ "AGE" "NAMESPACE" "NAME" "IP" "NODE" "STATUS" "READY" ];
          };
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/k9s/config.yml
    assertFileContent \
      home-files/.config/k9s/config.yml \
      ${./example-config-expected.yml}
    assertFileExists home-files/.config/k9s/skin.yml
    assertFileContent \
      home-files/.config/k9s/skin.yml \
      ${./example-skin-expected.yml}
    assertFileExists home-files/.config/k9s/hotkey.yml
    assertFileContent \
      home-files/.config/k9s/hotkey.yml \
      ${./example-hotkey-expected.yml}
    assertFileExists home-files/.config/k9s/aliases.yml
    assertFileContent \
      home-files/.config/k9s/aliases.yml \
      ${./example-aliases-expected.yml}
    assertFileExists home-files/.config/k9s/plugin.yml
    assertFileContent \
      home-files/.config/k9s/plugin.yml \
      ${./example-plugin-expected.yml}
    assertFileExists home-files/.config/k9s/views.yml
    assertFileContent \
      home-files/.config/k9s/views.yml \
      ${./example-views-expected.yml}
  '';
}
