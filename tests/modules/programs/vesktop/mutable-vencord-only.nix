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
  cleanup = config.home.activation.vesktopImmutableSettings;
in
{
  xdg.configHome = "${config.home.homeDirectory}/custom-config";
  programs.vesktop = {
    enable = true;
    package = null;
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
      assertion = !config.programs.vesktop.mutableSettings;
      message = "Vesktop mutability must match the configured mode.";
    }
    {
      assertion = config.home.activation ? vesktopImmutableSettings;
      message = "Vesktop immutable cleanup must follow configured, enabled immutable files.";
    }
    {
      assertion = cleanup.after == [ "writeBoundary" ] && cleanup.before == [ "linkGeneration" ];
      message = "Vesktop immutable cleanup must precede link generation after writeBoundary.";
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
    assertFileContent "home-files/${relativeDir}/settings.json" ${./settings-expected.json}
    assertPathNotExists "home-files/${relativeDir}/settings/settings.json"
    vencord="$(grep -o '/nix/store/[^ ]*-vesktop-settings.json' "$TESTED/activate" | tail -n1)" \
      || fail "vencord input is missing from activation"
    assertFileContent "$vencord" ${./vencord-expected.json}
    assertFileContains "home-files/${relativeDir}/settings/quickCss.css" "body { color: red; }"
  '';
}
