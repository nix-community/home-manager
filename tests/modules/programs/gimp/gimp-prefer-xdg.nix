{ config, ... }:
# home.preferXdgDirectories = true forces XDG paths even on macOS,
# overriding the default Library/Application Support placement on Darwin.
{
  home.enableNixpkgsReleaseCheck = false;
  home.preferXdgDirectories = true;

  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      version = "3.0.8";
    };

    settings.single-window-mode = true;
  };

  nmt.script = ''
    assertFileExists "home-files/.config/GIMP/3.0/gimprc"
    assertFileRegex "home-files/.config/GIMP/3.0/gimprc" "(single-window-mode yes)"
    assertPathNotExists "home-files/Library/Application Support/GIMP/3.0/gimprc"
  '';
}
