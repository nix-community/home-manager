# Regression test: the deprecated `ignoreCase` option must keep working as a
# shorthand for `environmentVariables.CARAPACE_MATCH = "1"`, and using it must
# emit a deprecation warning.
{
  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    ignoreCase = true;
  };

  test.stubs.carapace = {
    name = "carapace";
    # Keep a real store path so the wrapping `symlinkJoin` can build the stub.
    outPath = null;
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/carapace
      chmod +x $out/bin/carapace
    '';
  };

  test.asserts.warnings.expected = [
    ''
      `programs.carapace.ignoreCase' is deprecated and will be removed in a
      future release. Please use `programs.carapace.environmentVariables.CARAPACE_MATCH'
      (set to "1") instead.
    ''
  ];

  nmt.script = ''
    assertFileExists home-path/bin/.carapace-wrapped
    assertFileRegex home-path/bin/carapace "export CARAPACE_MATCH='1'"
  '';
}
