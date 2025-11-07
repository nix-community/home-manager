{
  programs.atuin.enable = true;

  # Config file should exist and be empty
  nmt.script =
    let
      configFile = "home-files/.config/atuin/config.toml";
    in
    ''
      assertFileExists ${configFile}
      assertFileNotRegex ${configFile} '.*'
    '';
}
