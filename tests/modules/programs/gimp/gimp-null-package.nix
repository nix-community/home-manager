{ pkgs, ... }:
# package = null is valid: config files are still written, home.packages is empty.
# configVersion falls back to "3.0" since there is no package to derive it from.
{
  home.enableNixpkgsReleaseCheck = false;

  programs.gimp = {
    enable = true;
    package = null;
    settings.single-window-mode = true;
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
      assertFileExists "${configDir}/gimprc"
      assertFileRegex "${configDir}/gimprc" "(single-window-mode yes)"
    '';
}
