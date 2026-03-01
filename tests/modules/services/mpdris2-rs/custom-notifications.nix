{
  services.mpdris2-rs = {
    enable = true;
    notifications = {
      enable = true;
      summary = "%artist% - %album%";
      summaryPaused = "%artist% - %album% (paused)";
      body = "%title% (%elapsed%/%duration%)";
      bodyPaused = "%title% (%elapsed%/%duration%) (paused)";
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/mpdris2-rs.service
    assertFileContent "$serviceFile" ${./custom-notifications.service}
  '';
}
