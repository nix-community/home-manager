{ config, ... }:
{
  programs.television = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "television"; };
    extraPackages = [ ];

    settings = {
      ui.theme = "default";
    };

    themes.default = {
      border_fg = "bright-black";
      text_fg = "bright-blue";
      dimmed_text_fg = "white";
      input_text_fg = "bright-red";
      result_count_fg = "bright-red";
      result_name_fg = "bright-blue";
      result_line_number_fg = "bright-yellow";
      result_value_fg = "white";
      selection_fg = "bright-green";
      selection_bg = "bright-black";
      match_fg = "bright-red";
      preview_title_fg = "bright-magenta";
      channel_mode_fg = "black";
      channel_mode_bg = "green";
      remote_control_mode_fg = "black";
      remote_control_mode_bg = "yellow";
      action_picker_mode_fg = "black";
      action_picker_mode_bg = "magenta";
      send_to_channel_mode_fg = "cyan";
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/television/themes/default.toml \
      ${./themes-config-expected.toml}
  '';
}
