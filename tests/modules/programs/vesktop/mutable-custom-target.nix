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
  fileDir =
    if pkgs.stdenv.hostPlatform.isDarwin then relativeDir else "${config.xdg.configHome}/vesktop";
in
{
  xdg.configHome = "${config.home.homeDirectory}/custom-config";
  programs.vesktop = {
    enable = true;
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
  home.file = {
    "${fileDir}/settings.json".target = "redirected/vesktop.json";
    "${fileDir}/settings/settings.json".target = "/outside-home/vencord.json";
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
      assertion = (config.home.activation ? vesktopSettings);
      message = "Vesktop activation must follow module enablement.";
    }
    {
      assertion = config.home.activation.vesktopSettings.after == [ "linkGeneration" ];
      message = "Vesktop mutable activation must follow link generation.";
    }
    {
      assertion = !config.home.file."${fileDir}/settings.json".enable;
      message = "Mutable Vesktop settings must not own a symlink.";
    }
    {
      assertion = !config.home.file."${fileDir}/settings/settings.json".enable;
      message = "Mutable Vencord settings must not own a symlink.";
    }
  ];
  nmt.script = ''
    assertFileContains "home-files/${relativeDir}/settings/quickCss.css" "body { color: red; }"
    assertPathNotExists "home-files/redirected/vesktop.json"
    assertPathNotExists "home-files/${relativeDir}/settings.json"
    assertPathNotExists "home-files/${relativeDir}/settings/settings.json"
    assertFileContains activate '${config.home.homeDirectory}/redirected/vesktop.json'
    assertFileContains activate '/outside-home/vencord.json'
    settings="$(grep -o '/nix/store/[^ ]*-vesktop-settings.json' "$TESTED/activate" | head -n1)" \
      || fail "settings input is missing from activation"
    assertFileContent "$settings" ${./settings-expected.json}
    vencord="$(grep -o '/nix/store/[^ ]*-vesktop-settings.json' "$TESTED/activate" | tail -n1)" \
      || fail "vencord input is missing from activation"
    assertFileContent "$vencord" ${./vencord-expected.json}
  '';
}
