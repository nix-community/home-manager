{
  programs.fresh-editor = {
    enable = true;
    settings = builtins.fromJSON (builtins.readFile ./config.json);
  };

  nmt.script = ''
    assertFileContent home-files/.config/fresh/config.json ${./config.json}
    assertPathNotExists home-files/.config/fresh/config_linux.json
    assertPathNotExists home-files/.config/fresh/config_macos.json
  '';
}
