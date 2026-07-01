{ config, pkgs, ... }:
# configVersion is auto-derived from the package version via lib.versions.majorMinor.
# A GIMP 3.2.x package → configVersion "3.2" → config lands in GIMP/3.2/.
# Verifies no files leak into the GIMP/3.0/ directory.
{
  home.enableNixpkgsReleaseCheck = false;

  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      version = "3.2.0";
    };

    settings.single-window-mode = true;
  };

  nmt.script =
    let
      base =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "home-files/Library/Application Support/GIMP"
        else
          "home-files/.config/GIMP";
    in
    ''
      assertFileExists "${base}/3.2/gimprc"
      assertFileRegex "${base}/3.2/gimprc" "(single-window-mode yes)"
      assertPathNotExists "${base}/3.0/gimprc"
    '';
}
