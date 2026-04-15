{
  programs.macos-terminal = {
    enable = true;

    profiles = {
      Basic.settings = {
        CommandString = "echo test";

        ShowActiveProcessArgumentsInTitle = false;
        ShowTTYNameInTitle = true;

        columnCount = 50;
      };
    };

    preferences = {
      importSettings = false;
      writeFile = true;
    };
  };

  nmt.script =
    let
      plistFile = "home-files/Library/Preferences/com.apple.Terminal.plist";
    in
    ''
      assertFileExists "${plistFile}"
      assertFileContent "${plistFile}" ${./expected-basic-configuration.plist}
    '';
}
