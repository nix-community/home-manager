{ config, pkgs, ... }:
# Covers the two path-only content options:
#   fonts  — listOf path; filename derived from baseNameOf
#   plugins — attrsOf path; supports subdirectory keys ("name/name")
{
  home.enableNixpkgsReleaseCheck = false;

  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      version = "3.0.8";
    };

    # Font must live inside a package dir so baseNameOf gives a clean name
    # (no store hash prefix) for the xdg.configFile key.
    fonts =
      let
        fakeFont = pkgs.runCommand "fake-inter" { } ''
          mkdir -p "$out"
          printf 'fake ttf' > "$out/Inter-Regular.ttf"
        '';
      in
      [ "${fakeFont}/Inter-Regular.ttf" ];

    plugins."my-plugin/my-plugin" = builtins.toFile "my-plugin" "#!/bin/sh\necho hello";
  };

  nmt.script =
    let
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "home-files/Library/Application Support/GIMP/3.0"
        else
          "home-files/.config/GIMP/3.0";
    in
    ''
      assertFileExists "${configDir}/fonts/Inter-Regular.ttf"
      assertFileExists "${configDir}/plug-ins/my-plugin/my-plugin"
    '';
}
