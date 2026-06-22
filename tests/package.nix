{
  flake,
  fzf,
  inputOverrides ? { },
  lib,
  python3,
  writeShellApplication,
  writeText,
}:
let
  inputOverridesFile = writeText "home-manager-test-input-overrides.json" (
    builtins.toJSON (lib.mapAttrs (_name: input: input.outPath) inputOverrides)
  );
in
writeShellApplication {
  name = "tests";
  runtimeInputs = [
    python3
    fzf
  ];
  runtimeEnv = {
    # Explicitly enable experimental features, in case someone runs e.g.
    #   nix run .#tests --extra-experimental-features 'nix-command flakes'
    # without enabling them globally.
    HOME_MANAGER_TEST_INPUT_OVERRIDES = inputOverridesFile;
    NIX_CONFIG = ''
      experimental-features = nix-command flakes
    '';
  };
  text = ''
    exec python3 ${flake}/tests/tests.py "$@"
  '';
}
