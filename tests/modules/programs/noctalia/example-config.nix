{
  programs.noctalia = {
    enable = true;
    validateConfig = false;
    settings = {
      audio = {
        enable_sounds = true;
      };
      bar = {
        default = {
          background_opacity = 0.8;
          capsule = true;
          capsule_border = "outline";
          font_family = "JetBrainsMono Nerd Font Mono";
          position = "top";
        };
      };
      desktop_widgets = {
        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
        };
        schema_version = 2;
        widget = { };
        widget_order = [ ];
      };
    };
  };

  nmt.script = ''
    local configFile="home-files/.config/noctalia/config.toml"
    assertFileExists $configFile
    assertFileContent $configFile ${./expected-example-config.toml}
  '';
}
