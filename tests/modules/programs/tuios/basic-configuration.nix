{ config, pkgs, ... }:
let
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin && !config.xdg.enable then
      "Library/Application Support"
    else
      ".config";
in
{
  programs.tuios = {
    enable = true;
    settings = {
      appearance.theme = "catppuccin_mocha";
      keybindings.preset = "tmux";
      startup = {
        tiled = true;
        start_in_terminal_mode = true;
      };
    };
  };

  assertions = [
    {
      assertion =
        builtins.elem pkgs.tuios config.home.packages == (config.programs.tuios.package != null);
      message = "TUIOS is installed exactly when a package is configured.";
    }
  ];

  nmt.script = ''
    assertFileContent "home-files/${configDir}/tuios/config.d/10-home-manager.toml" \
      ${./expected-config.toml}
    assertPathNotExists "home-files/${configDir}/tuios/config.toml"
  '';
}
