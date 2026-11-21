{
  programs.gtt = {
    enable = true;

    settings = {
      destination = {
        border_color = "red";
        language = {
          apertium = "English";
          bing = "English";
          deepl = "English";
          deeplx = "English";
          google = "English";
          libre = "English";
          reverso = "English";
        };
      };
      hide_below = false;
      osc52 = false;
      source = {
        border_color = "blue";
        language = {
          apertium = "Portuguese";
          bing = "Portuguese (Brazil)";
          deepl = "Portuguese";
          deeplx = "Portuguese";
          google = "Portuguese (Portugal, Brazil)";
          libre = "Portuguese";
          reverso = "Portuguese";
        };
      };
      theme = "gruvbox";
      translator = "Google";
      transparent = false;
    };
  };

  test.stubs.gtt.name = "gtt";

  nmt.script =
    let
      configFile = "home-files/.config/gtt/gtt.yaml";
    in
    ''
      assertFileExists "${configFile}"
      assertFileContent "${configFile}" ${./expected-settings.yaml}
    '';
}
