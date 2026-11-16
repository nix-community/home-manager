{
  config,
  lib,
  pkgs,
  ...
}:
let
  relativeDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/vesktop"
    else
      "custom-config/vesktop";
in
{
  xdg.configHome = "${config.home.homeDirectory}/custom-config";
  programs.vesktop = {
    enable = false;
    package = null;
    mutableSettings = true;
    settings = {
      tray = false;
      spellCheckLanguages = [ "en-US" ];
    };
    vencord = {
      mutableSettings = true;
      settings = {
        plugins.FakeNitro.enabled = true;
        enabledThemes = [ ];
      };
      extraQuickCss = "body { color: red; }";
    };
  };

  assertions = [
    {
      assertion = !(config.home.activation ? vesktopImmutableSettings);
      message = "Vesktop immutable cleanup must follow configured, enabled immutable files.";
    }
    {
      assertion = lib.all (package: !(lib.hasInfix "vesktop" (lib.getName package))) config.home.packages;
      message = "A null Vesktop package must not be installed.";
    }
    {
      assertion = !(config.home.activation ? vesktopSettings);
      message = "Vesktop activation must follow module enablement.";
    }
  ];
  nmt.script = ''
    assertPathNotExists "home-files/${relativeDir}/settings.json"
    assertPathNotExists "home-files/${relativeDir}/settings/settings.json"
  '';
}
