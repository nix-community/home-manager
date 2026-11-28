{
  config,
  pkgs,
  ...
}:
let
  settingsPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/me.paolino.zapfast/settings.json"
    else
      "${config.xdg.configHome}/zapfast/settings.json";
in
{
  programs.zapfast = {
    enable = true;
    package = null;
    settings = {
      theme = "dark";
      notifications = true;
      message_sound = "none";
      mention_sound = "none";
    };
  };

  nmt.script =
    assert config.home.activation.zapfastSettings.after == [ "linkGeneration" ];
    ''
      assertPathNotExists home-files/.config/zapfast/settings.json
      assertPathNotExists "home-files/Library/Application Support/me.paolino.zapfast/settings.json"
      assertFileContains activate 'Merging Nix-generated config into ${settingsPath}'

      generated="$(grep -o '/nix/store/[^ ]*-zapfast-settings.json' "$TESTED/activate" | head -n1)"
      assertFileContent "$generated" ${./settings.json}
    '';
}
