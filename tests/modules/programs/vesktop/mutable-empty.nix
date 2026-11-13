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
    enable = true;
    package = null;
    mutableSettings = true;
    vencord = {
      extraQuickCss = "body { color: red; }";
    };
  };

  assertions = [
    {
      assertion = config.home.activation.vesktopSettings.data == "";
      message = "Empty mixed-ownership settings must not generate mutable writes.";
    }
    {
      assertion =
        config.programs.vesktop.mutableSettings && !config.programs.vesktop.vencord.mutableSettings;
      message = "Empty settings must preserve independent ownership modes.";
    }
    {
      assertion = !(config.home.activation ? vesktopImmutableSettings);
      message = "Vesktop immutable cleanup must follow configured, enabled immutable files.";
    }
    {
      assertion = lib.all (package: !(lib.hasInfix "vesktop" (lib.getName package))) config.home.packages;
      message = "A null Vesktop package must not be installed.";
    }
    {
      assertion = (config.home.activation ? vesktopSettings);
      message = "Vesktop activation must follow module enablement.";
    }
    {
      assertion = config.home.activation.vesktopSettings.after == [ "linkGeneration" ];
      message = "Vesktop mutable activation must follow link generation.";
    }
  ];
  nmt.script = ''
    assertPathNotExists "home-files/${relativeDir}/settings.json"
    assertPathNotExists "home-files/${relativeDir}/settings/settings.json"
    assertFileContains "home-files/${relativeDir}/settings/quickCss.css" "body { color: red; }"
  '';
}
