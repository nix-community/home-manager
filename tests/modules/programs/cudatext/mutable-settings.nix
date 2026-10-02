{
  config,
  lib,
  pkgs,
  ...
}:
let
  settingsPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/CudaText/settings"
    else
      "custom-config/cudatext/settings";
in
{
  programs.cudatext = {
    enable = true;
    package = null;
    mutableSettings = true;
    userSettings = {
      numbers_style = 2;
    };
    hotkeys."153".s1 = [ "End" ];
    lexerSettings.Python.numbers_style = 1;
    lexerHotkeys.Python."153".s1 = [ "Home" ];
  };
  xdg.configHome = "${config.home.homeDirectory}/custom-config";
  assertions = [
    {
      assertion = config.home.activation.cudatextSettings.after == [ "linkGeneration" ];
      message = "Mutable cudatext settings must run after linkGeneration.";
    }
    {
      assertion = !(config.home.activation ? cudatextImmutableSettings);
      message = "Mutable cudatext settings must not create immutable cleanup.";
    }
    {
      assertion = !(lib.any (package: lib.getName package == "cudatext") config.home.packages);
      message = "A null cudatext package must not be installed.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/${settingsPath}/user.json"
    assertFileContains activate "${config.home.homeDirectory}/${settingsPath}/user.json"
    input0="$(grep -o '/nix/store/[^ ]*-cudatext-user.json' "$TESTED/activate")" \
      || fail "cudatext user.json input is missing from activation"
    assertFileContent "$input0" ${./mutable-user-expected.json}
    assertPathNotExists "home-files/${settingsPath}/keys.json"
    assertFileContains activate "${config.home.homeDirectory}/${settingsPath}/keys.json"
    input1="$(grep -o '/nix/store/[^ ]*-cudatext-keys.json' "$TESTED/activate")" \
      || fail "cudatext keys.json input is missing from activation"
    assertFileContent "$input1" ${./mutable-keys-expected.json}
    assertPathNotExists "home-files/${settingsPath}/lexer Python.json"
    assertFileContains activate "${config.home.homeDirectory}/${settingsPath}/lexer Python.json"
    input2="$(grep -o '/nix/store/[^ ]*-cudatext-lexer-Python' "$TESTED/activate")" \
      || fail "cudatext lexer Python.json input is missing from activation"
    assertFileContent "$input2" ${./mutable-lexer-expected.json}
    assertPathNotExists "home-files/${settingsPath}/keys lexer Python.json"
    assertFileContains activate "${config.home.homeDirectory}/${settingsPath}/keys lexer Python.json"
    input3="$(grep -o '/nix/store/[^ ]*-cudatext-lexer-keys-Python' "$TESTED/activate")" \
      || fail "cudatext keys lexer Python.json input is missing from activation"
    assertFileContent "$input3" ${./mutable-lexer-keys-expected.json}
  '';
}
