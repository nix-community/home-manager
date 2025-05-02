{
  services.clipcat = {
    enable = true;
    daemonSettings = {
      daemonize = true;
      max_history = 50;
      history_file_path = "/home/<username>/.cache/clipcat/clipcatd-history";
      pid_file = "/run/user/<user-id>/clipcatd.pid";
      primary_threshold_ms = 5000;
      log = {
        file_path = "/path/to/log/file";
        emit_journald = true;
        emit_stdout = false;
        emit_stderr = false;
        level = "INFO";
      };
    };

    ctlSettings = {
      server_endpoint = "/run/user/<user-id>/clipcat/grpc.sock";
      log = {
        file_path = "/path/to/log/file";
        emit_journald = true;
        emit_stdout = false;
        emit_stderr = false;
        level = "INFO";
      };
    };

    menuSettings = {
      server_endpoint = "/run/user/<user-id>/clipcat/grpc.sock";
      finder = "rofi";
      rofi = {
        line_length = 100;
        menu_length = 30;
        menu_prompt = "Clipcat";
        extra_arguments = [
          "-mesg"
          "Please select a clip"
        ];
      };
      dmenu = {
        line_length = 100;
        menu_length = 30;
        menu_prompt = "Clipcat";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/clipcat/clipcatd.toml
    assertFileExists home-files/.config/clipcat/clipcatctl.toml
    assertFileExists home-files/.config/clipcat/clipcat-menu.toml

    assertFileContent home-files/.config/clipcat/clipcatd.toml \
    ${./cfg/daemon.toml}

    assertFileContent home-files/.config/clipcat/clipcatctl.toml \
    ${./cfg/ctl.toml}

    assertFileContent home-files/.config/clipcat/clipcat-menu.toml \
    ${./cfg/menu.toml}

  '';
}
