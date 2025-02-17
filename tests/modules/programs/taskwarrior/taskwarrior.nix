{
  programs.taskwarrior = {
    enable = true;
    colorTheme = "dark-violets-256";
    dataLocation = "/some/data/location";
    config = {
      urgency.user.tag.next.coefficient = 42.42;
      urgency.blocked.coefficient = -42;
    };
    extraConfig = ''
      include /my/stuff
      urgency.user.tag.test.coefficient=-42.42
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/task/home-manager-taskrc
    assertFileContent home-files/.config/task/home-manager-taskrc ${
      builtins.toFile "taskwarrior.home-conf.expected" ''
        data.location=/some/data/location
        include dark-violets-256.theme

        urgency.blocked.coefficient=-42
        urgency.user.tag.next.coefficient=42.420000

        include /my/stuff
        urgency.user.tag.test.coefficient=-42.42

      ''
    }
  '';
}
