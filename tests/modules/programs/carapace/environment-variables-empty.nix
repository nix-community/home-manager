# With no environment variables (and `ignoreCase` off) the binary must NOT be
# wrapped.
{
  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
  };

  test.stubs.carapace = {
    name = "carapace";
    # Keep a real store path so the (unwrapped) stub is buildable in home-path.
    outPath = null;
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/carapace
      chmod +x $out/bin/carapace
    '';
  };

  nmt.script = ''
    assertPathNotExists home-path/bin/.carapace-wrapped
  '';
}
