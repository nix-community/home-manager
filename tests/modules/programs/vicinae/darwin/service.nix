{
  config,
  pkgs,
  ...
}:

let
  mkExtensionStub =
    name:
    pkgs.runCommandLocal name { } ''
      mkdir -p $out
      echo '{}' > $out/package.json
    '';
in
{
  programs.vicinae = {
    enable = true;
    service.enable = true;
    package = config.lib.test.mkStubPackage {
      name = "vicinae";
      version = "0.21.0";
      outPath = "@vicinae@";
    };
    enableFirefoxIntegration = false;

    settings.font.normal.size = 12;

    themes.catppuccin-mocha.meta = {
      version = 1;
      name = "Catppuccin Mocha";
      inherits = "vicinae-dark";
    };

    extensions = [ (mkExtensionStub "test-extension") ];
  };

  nmt.script = ''
    assertFileContent "home-files/.config/vicinae/settings.json" ${../read-only-layer.json}
    assertFileExists "home-files/.local/share/vicinae/themes/catppuccin-mocha.toml"
    assertFileExists "home-files/.local/share/vicinae/extensions/test-extension/package.json"

    serviceFile=LaunchAgents/org.nix-community.home.vicinae.plist
    assertFileExists $serviceFile
    assertFileContent $serviceFile ${./agent.plist}
  '';
}
