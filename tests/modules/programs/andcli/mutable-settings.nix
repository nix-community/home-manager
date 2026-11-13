{
  config,
  lib,
  pkgs,
  ...
}:
let
  relativePath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/andcli/config.yaml"
    else
      "custom-config/andcli/config.yaml";
in
{
  programs.andcli = {
    enable = true;
    mutableSettings = true;
    package = null;
    settings.options.show_tokens = false;
  };
  xdg.configHome = "${config.home.homeDirectory}/custom-config";

  assertions = [
    {
      assertion = config.home.activation.andcliMutableSettings.after == [ "linkGeneration" ];
      message = "Mutable andcli settings must run after linkGeneration.";
    }
    {
      assertion = !(config.home.activation ? andcliImmutableSettings);
      message = "Mutable andcli settings must not create immutable cleanup.";
    }
    {
      assertion = !(lib.any (package: lib.getName package == "andcli") config.home.packages);
      message = "A null andcli package must not be installed.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/${relativePath}"
    assertFileContains activate "${config.home.homeDirectory}/${relativePath}"
    input0="$(grep -o '/nix/store/[^ ]*-andcli-config.yaml' "$TESTED/activate")" \
      || fail "andcli config.yaml input is missing from activation"
    assertFileContent "$input0" ${./mutable-expected.yaml}
  '';
}
