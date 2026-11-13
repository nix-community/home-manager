{
  config,
  lib,
  pkgs,
  ...
}:
let
  relativePath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/alistral/config.json"
    else
      "custom-config/alistral/config.json";
in
{
  xdg.configHome = "${config.home.homeDirectory}/custom-config";
  programs.alistral = {
    enable = true;
    mutableSettings = true;
    package = null;
    settings.default_user = "test-user";
  };

  assertions = [
    {
      assertion = config.home.activation.alistralMutableSettings.after == [ "linkGeneration" ];
      message = "Mutable alistral settings must run after linkGeneration.";
    }
    {
      assertion = !(config.home.activation ? alistralImmutableSettings);
      message = "Mutable alistral settings must not create immutable cleanup.";
    }
    {
      assertion = !(lib.any (package: lib.getName package == "alistral") config.home.packages);
      message = "A null alistral package must not be installed.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/${relativePath}"
    assertFileContains activate "${config.home.homeDirectory}/${relativePath}"
    assertFileContains activate "dynamic='{\"tokens\":{}}'"
    input0="$(grep -o '/nix/store/[^ ]*-alistral-mutable-settings' "$TESTED/activate")" \
      || fail "alistral config.json input is missing from activation"
    assertFileContent "$input0" ${./mutable-new-expected.json}
  '';
}
