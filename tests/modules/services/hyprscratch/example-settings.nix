{
  # This is not a working example
  services.hyprscratch = {
    enable = true;
    settings = {
      daemon_options = "clean";
      global_options = "special";
      global_rules = "size 90% 90%";

      name = {
        command = "command";

        title = "title";
        class = "class";

        options = "option1 option2 option3";
        rules = "rule1;rule2;rule3";
      };
    };
  };

  nmt.script =
    let
      configFile = "home-files/.config/hypr/hyprscratch.conf";
    in
    ''
      assertFileExists "${configFile}"
      assertFileContent "${configFile}" ${./example-settings.conf}
    '';
}
