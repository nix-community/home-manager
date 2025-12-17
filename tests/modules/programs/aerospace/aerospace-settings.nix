{ config, pkgs, ... }:
let
  hmPkgs = pkgs.extend (
    self: super: {
      aerospace = config.lib.test.mkStubPackage {
        name = "aerospace";
        buildScript = ''
          mkdir -p $out/bin
          touch $out/bin/aerospace
          chmod 755 $out/bin/aerospace
        '';
      };
    }
  );
in
{
  xdg.enable = true;

  programs.aerospace = {
    enable = true;
    package = hmPkgs.aerospace;

    launchd.enable = true;

    settings = {
      gaps = {
        outer.left = 8;
        outer.bottom = 8;
        outer.top = 8;
        outer.right = 8;
      };
      mode.main.binding = {
        alt-enter = ''
          exec-and-forget osascript -e '
                     tell application "Terminal"
                         do script
                         activate
                     end tell'
        '';
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";
      };
      on-window-detected = [
        {
          "if".app-id = "com.apple.finder";
          run = "move-node-to-workspace 9";
        }

        {
          "if" = {
            app-id = "com.apple.systempreferences";
            app-name-regex-substring = "settings";
            window-title-regex-substring = "substring";
            workspace = "workspace-name";
            during-aerospace-startup = true;
          };
          check-further-callbacks = true;
          run = [
            "layout floating"
            "move-node-to-workspace S"
          ];
        }
      ];
    };
  };

  nmt.script = ''
    assertPathNotExists "home-files/.aerospace.toml";
    assertFileExists "home-files/.config/aerospace/aerospace.toml"
    assertFileContent "home-files/.config/aerospace/aerospace.toml" ${./settings-expected.toml}

    serviceFile=$(normalizeStorePaths LaunchAgents/org.nix-community.home.aerospace.plist)
    assertFileExists $serviceFile
    assertFileContent "$serviceFile" ${./aerospace-service-expected.plist}
  '';
}
