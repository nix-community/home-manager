{
  programs.todoman = {
    enable = true;
    glob = "*/*";
    extraConfig = ''
      date_format = "%d.%m.%Y"
      default_list = "test"
    '';
  };

  accounts.calendar.basePath = "base/path/calendar";

  test.stubs = { todoman = { }; };

  nmt.script = ''
    configFile=home-files/.config/todoman/config.py
    assertFileExists $configFile
    assertFileContent $configFile ${./todoman-config-expected}
  '';
}

