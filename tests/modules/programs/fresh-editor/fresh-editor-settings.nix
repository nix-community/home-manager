{
  programs.fresh-editor = {
    enable = true;
    settings = builtins.fromJSON (builtins.readFile ./config.json);
  };

  nmt.script = ''
    assertFileContent home-files/.config/fresh/config.json ${./config.json}
  '';
}
