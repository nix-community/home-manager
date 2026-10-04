{
  config,
  pkgs,
  ...
}:
let
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/alistral"
    else
      ".config/alistral";
  file = config.home.file."${configDir}/config.json";
  cleanup = config.home.activation.alistralImmutableSettings;
  expectedTarget =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${configDir}/config.json"
    else
      "custom-config/alistral/config.json";
in
{
  xdg.configHome = "${config.home.homeDirectory}/custom-config";
  programs.alistral = {
    enable = true;
    settings = {
      default_user = "spanish_inquisition";
      listenbrainz_url = "https://api.listenbrainz.org/1/";
      musicbrainz_url = "http://musicbrainz.org/ws/2";
    };
  };
  home.file."${configDir}/config.json".enable = false;

  assertions = [
    {
      assertion = !config.programs.alistral.mutableSettings;
      message = "Alistral settings must default to immutable settings.";
    }
    {
      assertion = !(config.home.activation ? alistralMutableSettings);
      message = "Immutable alistral settings must not register mutable activation.";
    }
    {
      assertion = cleanup.after == [ "writeBoundary" ];
      message = "Immutable cleanup must run after writeBoundary.";
    }
    {
      assertion = cleanup.before == [ "linkGeneration" ];
      message = "Immutable cleanup must run before linkGeneration.";
    }
    {
      assertion = !file.enable;
      message = "The disabled alistral settings file must remain disabled.";
    }
    {
      assertion = cleanup.data == "";
      message = "Disabled alistral settings files must not create cleanup commands.";
    }
    {
      assertion = file.target == expectedTarget;
      message = "Immutable alistral settings must use the configured file target.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/${expectedTarget}"
  '';
}
