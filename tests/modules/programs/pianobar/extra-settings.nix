{
  programs.pianobar = {
    enable = true;
    settings = {
      act_help = "h";
      act_history = "?";
      at_icon = "@";
      audio_pipe = "/path/to/fifo";
      audio_quality = "low";
      autoselect = "{1,0}";
      autostart_station = "123456";
      bind_to = "{if!tunX,host!127.0.0.1}";
      buffer_seconds = "5";
      ca_bundle = "/etc/ssl/certs/ca-certificates.crt";
      control_proxy = "http://user:password@host:port/";
      event_command = "/home/user/.config/pianobar/eventcmd";
      fifo = "/home/user/.config/pianobar/cmd";
      format_list_song = "%i) %a - %t%r";
      format_msg_none = "%s";
      gain_mul = "1.0";
      history = "5";
      host = "tuner.pandora.com";
      love_icon = "<3";
      max_retry = "3";
      password_command = "cat /run/secrets/pianobar/groovy-tunes";
      proxy = "http://user:password@host:port/";
      sample_rate = "0";
      sort = "{name_az, name_za, quickmix_01_name_az, quickmix_01_name_za, quickmix_10_name_az, quickmix_10_name_za}";
      timeout = "30";
      tired_icon = "zZ";
      tls_port = "443";
      user = "groovy-tunes@example.com";
      volume = "30";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/pianobar/config
    assertFileContent home-files/.config/pianobar/config \
    ${./extra-settings.conf}
  '';
}
