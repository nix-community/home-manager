{
  programs.radicle.enable = true;

  nmt.script = ''
    assertFileContent \
      home-files/.radicle/config.json \
      ${./basic-configuration.json}
  '';
}
