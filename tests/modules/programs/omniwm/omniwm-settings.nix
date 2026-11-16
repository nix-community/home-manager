{ config, pkgs, ... }:
let
  hmPkgs = pkgs.extend (
    _self: _super: {
      omniwm = config.lib.test.mkStubPackage {
        name = "omniwm";
        buildScript = ''
          mkdir -p $out/Applications/OmniWM.app/Contents/MacOS
          touch $out/Applications/OmniWM.app/Contents/MacOS/OmniWM
          chmod 755 $out/Applications/OmniWM.app/Contents/MacOS/OmniWM
        '';
      };
    }
  );
in
{
  xdg.enable = true;

  programs.omniwm = {
    enable = true;
    package = hmPkgs.omniwm;

    launchd.enable = true;

    settings = {
      appearance.mode = "dark";
      general = {
        defaultLayoutType = "niri";
        updateChecksEnabled = false;
      };
      gaps.size = 8.0;
      borders = {
        enabled = true;
        width = 2.0;
        color = {
          alpha = 1.0;
          blue = 0.69;
          green = 0.7;
          red = 0.7;
        };
      };
      hotkeys = [
        {
          binding = "Control+1";
          id = "switchWorkspace.0";
        }
      ];
      appRules = [
        {
          bundleId = "com.apple.Safari";
          id = "81426D13-C1A5-475E-AFBC-00BBA05042D0";
          minHeight = 220.0;
          minWidth = 574.0;
        }
      ];
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/omniwm/settings.toml"
    assertFileContent "home-files/.config/omniwm/settings.toml" ${./omniwm-settings-expected.toml}

    serviceFile=$(normalizeStorePaths LaunchAgents/org.nix-community.home.omniwm.plist)
    assertFileExists $serviceFile
    assertFileContent "$serviceFile" ${./omniwm-service-expected.plist}
  '';
}
