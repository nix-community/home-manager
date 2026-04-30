_:

{
  programs.depot-tools = {
    enable = true;
    environment.DEPOT_TOOLS_METRICS = "0";
  };

  test.stubs.depot-tools = { };

  nmt.script = ''
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh 'DEPOT_TOOLS_METRICS="0"'
  '';
}
