{
  # derived from
  # https://github.com/sashetophizika/hyprscratch/blob/master/test_configs/test_hyprlang.conf
  services.hyprscratch = {
    enable = true;
    settings = {
      btop = {
        class = "btop";
        command = "kitty --title btop -e btop";
        rules = "size monitor_w*0.85 monitor_h*0.85";
        options = "cover persist sticky shiny lazy show hide poly special tiled";
      };

      "group:one" = {
        nautilus = {
          title = "Loading…";
          command = "nautilus";
          rules = "size monitor_w*0.7 monitor_h*0.8";
        };

        noname = {
          title = "\\\\\"";
          command = "\\\\'";
          options = "cover lazy special";
        };
      };

      "group:two" = {
        name = "btop";

        weierd = {
          class = " a program with ' a weierd ' name";
          command = "a \\\"command with\\\" \\\\'a weierd\\\\' format";
          options = "hide show";
        };
      };
    };
  };

  nmt.script =
    let
      configFile = "home-files/.config/hypr/hyprscratch.conf";
    in
    ''
      assertFileExists "${configFile}"
      assertFileContent "${configFile}" ${./test_hyprlang.conf}
    '';
}
