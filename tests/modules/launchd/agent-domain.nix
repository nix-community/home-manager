{
  config = {
    launchd.agents."user-service" = {
      enable = true;
      domain = "user";
      config.ProgramArguments = [
        "/some/command"
      ];
    };

    nmt.script = ''
      serviceFile=LaunchAgents/org.nix-community.home.user-service.plist
      assertFileExists $serviceFile
      assertFileContains $serviceFile '<key>LimitLoadToSessionType</key>'
      assertFileContains $serviceFile '<string>Background</string>'

      domainFile=LaunchAgentDomains/org.nix-community.home.user-service.domain
      assertFileExists $domainFile
      assertFileContent $domainFile ${builtins.toFile "expected-domain" "user\n"}
    '';
  };
}
