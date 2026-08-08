{
  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    environmentVariables = {
      CARAPACE_MATCH = "1";
      CARAPACE_EXCLUDES = "wt";
    };
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

  nmt.script = ''
    # The binary is wrapped via makeWrapper, which renames the original to
    # .carapace-wrapped and installs the wrapper script in its place.
    assertFileExists home-path/bin/.carapace-wrapped
    assertFileRegex home-path/bin/carapace "export CARAPACE_MATCH='1'"
    assertFileRegex home-path/bin/carapace "export CARAPACE_EXCLUDES='wt'"
  '';
}
