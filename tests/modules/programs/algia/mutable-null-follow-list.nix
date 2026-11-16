{
  config,
  lib,
  pkgs,
  ...
}:
let
  relativePath = "${
    if pkgs.stdenv.hostPlatform.isDarwin then ".config" else "custom-config"
  }/algia/config.json";
  followList = null;
in
{
  xdg.configHome = "${config.home.homeDirectory}/custom-config";
  programs.algia = {
    enable = true;
    mutableSettings = true;
    package = null;
    settings = { inherit followList; };
  };

  assertions = [
    {
      assertion = config.home.activation.algiaMutableSettings.after == [ "linkGeneration" ];
      message = "Mutable algia settings must run after linkGeneration.";
    }
    {
      assertion = !(config.home.activation ? algiaImmutableSettings);
      message = "Mutable algia settings must not create immutable cleanup.";
    }
    {
      assertion = !(lib.any (package: lib.getName package == "algia") config.home.packages);
      message = "A null algia package must not be installed.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/${relativePath}"
    assertFileContains activate "${config.home.homeDirectory}/${relativePath}"
    input0="$(grep -o '/nix/store/[^ ]*-algia-mutable-settings' "$TESTED/activate")" \
      || fail "algia config.json input is missing from activation"
    assertFileContent "$input0" ${./mutable-null-expected.json}
  '';
}
