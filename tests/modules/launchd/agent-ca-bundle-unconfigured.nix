{
  _module.args.darwinConfig = {
    environment.variables = { };
  };

  launchd.agents.ca-unconfigured = {
    enable = true;
    config.ProgramArguments = [ "/usr/bin/env" ];
  };

  nmt.script = ''
    assertFileContent LaunchAgents/org.nix-community.home.ca-unconfigured.plist ${./expected-ca-unconfigured.plist}
  '';
}
