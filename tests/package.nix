{
  flake,
  python3,
  writeShellScriptBin,
}:
writeShellScriptBin "tests" ''
  exec ${python3}/bin/python3 ${flake}/tests/tests.py "$@"
''
