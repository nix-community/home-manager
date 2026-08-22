{
  programs.sqlite = {
    enable = true;
    mode = "box";
    separator = {
      column = " | ";
      row = "\\n\\n";
    };
    prompt = {
      main = "> ";
      continue = "..> ";
    };
    extraConfig = ''
      .help
    '';
  };

  nmt.script =
    let
      configFile = "home-files/.config/sqlite3/sqliterc";
    in
    ''
      assertFileExists "${configFile}"
      assertFileContent "${configFile}" ${./basic-configuration-expected}
    '';
}
