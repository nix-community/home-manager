{ config, pkgs, ... }:

{
  config = {
    programs.swayr = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      systemd.enable = true;
      settings = {
        menu = {
          executable = "wofi";
          args = [
            "--show=dmenu"
            "--allow-markup"
            "--allow-images"
            "--insensitive"
            "--cache-file=/dev/null"
            "--parse-search"
            "--height=40%"
            "--prompt={prompt}"
          ];
        };

        format = {
          output_format = ''
            {indent}<b>Output {name}</b>    <span alpha="20000">({id})</span>'';
          workspace_format = ''
            {indent}<b>Workspace {name} [{layout}]</b> on output {output_name}    <span alpha="20000">({id})</span>'';
          container_format = ''
            {indent}<b>Container [{layout}]</b> <i>{marks}</i> on workspace {workspace_name}    <span alpha="20000">({id})</span>'';
          window_format = ''
            img:{app_icon}:text:{indent}<i>{app_name}</i> — {urgency_start}<b>“{title}”</b>{urgency_end} <i>{marks}</i> on workspace {workspace_name} / {output_name}    <span alpha="20000">({id})</span>'';
          indent = "    ";
          urgency_start = ''<span background="darkred" foreground="yellow">'';
          urgency_end = "</span>";
          html_escape = true;
        };

        layout = {
          auto_tile = false;
          auto_tile_min_window_width_per_output_width = [
            [ 800 400 ]
            [ 1024 500 ]
            [ 1280 600 ]
            [ 1400 680 ]
            [ 1440 700 ]
            [ 1600 780 ]
            [ 1680 780 ]
            [ 1920 920 ]
            [ 2048 980 ]
            [ 2560 1000 ]
            [ 3440 1200 ]
            [ 3840 1280 ]
            [ 4096 1400 ]
            [ 4480 1600 ]
            [ 7680 2400 ]
          ];
        };

        focus = { lockin_delay = 750; };

        misc = { seq_inhibit = false; };
      };
      extraConfig = ''
        [extra]
        foo = "\ubar"
      '';
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/swayrd.service

      assertFileExists $serviceFile
      assertFileRegex $serviceFile 'ExecStart=.*/bin/swayrd'
      assertFileRegex $serviceFile 'Environment=RUST_BACKTRACE=1'

      assertFileExists home-files/.config/swayr/config.toml
      assertFileContent home-files/.config/swayr/config.toml \
          ${./basic-configuration.toml}
    '';
  };
}
