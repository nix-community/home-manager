# `ignoreCase` and `environmentVariables.CARAPACE_MATCH` are mutually
# exclusive; setting both must trip the assertion.
{
  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    ignoreCase = true;
    environmentVariables.CARAPACE_MATCH = "1";
  };

  test.stubs.carapace = {
    name = "carapace";
    outPath = null;
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/carapace
      chmod +x $out/bin/carapace
    '';
  };

  # `ignoreCase` also emits the deprecation warning; this test focuses on the
  # mutual-exclusion assertion, so disable the warning check.
  test.asserts.warnings.enable = false;

  test.asserts.assertions.expected = [
    ''
      `programs.carapace.ignoreCase' must not be used together with
      `programs.carapace.environmentVariables.CARAPACE_MATCH' because
      `ignoreCase' is a deprecated shorthand for
      `environmentVariables.CARAPACE_MATCH = "1"'. Please set only one.
    ''
  ];
}
