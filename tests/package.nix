{
  flake,
  python3,
  writeShellApplication,
}:
writeShellApplication {
  name = "tests";
  runtimeInputs = [
    python3
  ];
  text = ''
    exec python3 ${flake}/tests/tests.py "$@"
  '';
}
