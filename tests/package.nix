{
  flake,
  fzf,
  python3,
  writeShellApplication,
}:
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
    NIX_CONFIG = ''
      experimental-features = nix-command flakes
    '';
  };
  text = ''
    exec python3 ${flake}/tests/tests.py "$@"
  '';
}
