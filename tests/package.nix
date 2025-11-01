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
  text = ''
    exec python3 ${flake}/tests/tests.py "$@"
  '';
}
