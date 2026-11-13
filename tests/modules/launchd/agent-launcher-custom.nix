{ pkgs, ... }:
{
  config = {
    launchd.agents."custom-launcher" = {
      enable = true;
      waitForNixStore = false;
      launcher = {
        name = "nix-custom-launcher";
        shell = "${pkgs.bash}/bin/bash";
      };
      config = {
        ProgramArguments = [
          "/some/command"
          "--flag"
        ];
      };
    };

    nmt.script = ''
      serviceFile=LaunchAgents/org.nix-community.home.custom-launcher.plist
      assertFileExists $serviceFile

      # The launcher carries the configured name, not the agent's attribute name.
      assertFileRegex $serviceFile '<string>/nix/store/[^<]*/bin/nix-custom-launcher</string>'
      assertFileNotRegex $serviceFile '/bin/custom-launcher</string>'
      assertFileNotRegex $serviceFile '<string>/bin/sh</string>'

      launcher=$(sed -n 's|.*<string>\(/nix/store/[^<]*/bin/nix-custom-launcher\)</string>.*|\1|p' \
        "$(_abs $serviceFile)")
      # The configured shell is the launcher's interpreter, and the command is exec'd.
      assertFileRegex "$launcher" '^#!.*/bin/bash$'
      assertFileContains "$launcher" 'exec /some/command --flag'
    '';
  };
}
