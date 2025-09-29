{ lib, pkgs, ... }:
let
  dummy-theme-plugin = pkgs.runCommandLocal "theme" { } ''
    mkdir -p "$out"/themes
    echo "fish_color_normal 575279" > "$out/themes/dummy-theme-plugin.theme"
  '';

  copied-theme = pkgs.writeText "theme.theme" ''
    fish_color_normal 575279
  '';
in
{
  config = {
    programs.fish = {
      enable = true;
      plugins = [
        {
          name = "foo";
          src = dummy-theme-plugin;
        }
      ];
    };

    # Needed to avoid error with dummy fish package.
    xdg.dataFile."fish/home-manager_generated_completions".source = lib.mkForce (
      builtins.toFile "empty" ""
    );

    nmt = {
      description = "if fish plugin contains themes directory copy the themes";
      script = ''
        assertDirectoryExists home-files/.config/fish/themes
        assertFileExists home-files/.config/fish/themes/dummy-theme-plugin.theme
        assertFileContent home-files/.config/fish/themes/dummy-theme-plugin.theme ${copied-theme}
      '';
    };
  };
}
