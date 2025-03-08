{ config, ... }: {
  nmt.script = ''
    assertFileContent \
      home-files/.config/vivid/themes/my-awesome-theme.yml \
      ${./themes-expected.yml}
  '';

  programs.vivid = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    themes = {
      my-awesome-theme = {
        colors = {
          black = "#000000";
          red = "#FF0000";
          green = "#00FF00";
          yellow = "#FFFF00";
          blue = "#0000FF";
          purple = "#FF00FF";
          cyan = "#00FFFF";
          orange = "#FFA500";
          white = "#FFFFFF";
          base01 = "#AAAAAA";
        };
        core = {
          "normal_text" = { foreground = "white"; };
          "regular_file" = { foreground = "white"; };
          "reset_to_normal" = { foreground = "orange"; };
          "directory" = { foreground = "purple"; };
          "symlink" = { foreground = "cyan"; };
          "multi_hard_link" = { };
          "fifo" = {
            foreground = "yellow";
            background = "black";
          };
          "socket" = {
            foreground = "blue";
            background = "black";
            font-style = "bold";
          };
          "door" = {
            foreground = "blue";
            background = "black";
            font-style = "bold";
          };
          "block_device" = {
            foreground = "yellow";
            background = "black";
            font-style = "bold";
          };
          "character_device" = {
            foreground = "yellow";
            background = "black";
            font-style = "bold";
          };
          "broken_symlink" = {
            foreground = "red";
            background = "black";
            font-style = "bold";
          };
          "missing_symlink_target" = {
            foreground = "red";
            background = "black";
          };
          "setuid" = {
            foreground = "white";
            background = "red";
          };
          "setgid" = {
            foreground = "black";
            background = "yellow";
          };
          "file_with_capability" = { };
          "sticky_other_writable" = {
            foreground = "black";
            background = "green";
          };
          "other_writable" = {
            foreground = "purple";
            background = "green";
          };
          "sticky" = {
            foreground = "white";
            background = "purple";
          };
          "executable_file" = { foreground = "green"; };
        };
        text = {
          "special" = { foreground = "orange"; };
          "todo" = {
            foreground = "orange";
            font-style = "bold";
          };
          "licenses" = { foreground = "orange"; };
          "configuration" = { foreground = "orange"; };
          "other" = { foreground = "orange"; };
        };
        markup = { foreground = "orange"; };
        programming = { foreground = "orange"; };
        media = {
          "image" = { foreground = "blue"; };
          "audio" = { foreground = "cyan"; };
          "video" = {
            foreground = "orange";
            font-style = "bold";
          };
          "fonts" = { foreground = "orange"; };
          "3d" = { foreground = "blue"; };
        };
        office = { foreground = "orange"; };
        archives = {
          foreground = "red";
          font-style = "bold";
        };
        executable = { foreground = "green"; };
        unimportant = { foreground = "base01"; };
      };
    };
  };
}
