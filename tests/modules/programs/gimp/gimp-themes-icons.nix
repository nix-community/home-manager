{ config, pkgs, ... }:
# Covers directory-source options: themes and icons.
# Each value is a store-path directory; home-manager installs it as a symlink.
{
  home.enableNixpkgsReleaseCheck = false;

  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      version = "3.0.8";
    };

    themes."MyDark" = pkgs.runCommand "fake-theme" { } ''
      mkdir -p "$out/gtk-3.0"
      echo '* { color: black; }' > "$out/gtk-3.0/gtk.css"
    '';

    icons."Papirus" = pkgs.runCommand "fake-icons" { } ''
      mkdir -p "$out"
      printf '[Icon Theme]\nName=Papirus\n' > "$out/index.theme"
    '';
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
      # Themes/icons are symlinks to directories; assertFileExists (-f) won't match.
      # Check a regular file inside each directory to verify the link and contents.
      assertFileExists "${configDir}/themes/MyDark/gtk-3.0/gtk.css"
      assertFileExists "${configDir}/icons/Papirus/index.theme"
    '';
}
