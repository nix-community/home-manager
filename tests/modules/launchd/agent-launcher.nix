{
  config = {
    launchd.agents."launcher-service" = {
      enable = true;
      waitForNixStore = false;
      config = {
        ProgramArguments = [
          "/some/command"
          "--with-arguments"
          "foo"
        ];
      };
    };

    nmt.script = ''
      serviceFile=LaunchAgents/org.nix-community.home.launcher-service.plist
      assertFileExists $serviceFile

      # The agent should exec a launcher script named after it, so that it
      # is displayed under its own name in Login Items & Extensions
      assertFileRegex $serviceFile '<string>/nix/store/[^<]*/bin/launcher-service</string>'

      # Ensure the agent wasn't started through a shell wrapper.
      assertFileNotRegex $serviceFile '<string>/bin/sh</string>'

      launcher=$(sed -n 's|.*<string>\(/nix/store/[^<]*/bin/launcher-service\)</string>.*|\1|p' \
        "$(_abs $serviceFile)")
      assertFileContains "$launcher" 'exec /some/command --with-arguments foo'
    '';
  };
}
