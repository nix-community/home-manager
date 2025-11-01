{
  programs = {
    zellij = {
      enable = true;

      # No `settings`
      extraConfig = ''
        This_could_have_been_json {
        }
      '';
    };
  };

  test.stubs = {
    zellij = { };
  };

  nmt.script = ''
    assertFileExists home-files/.config/zellij/config.kdl

    assertFileContains \
      home-files/.config/zellij/config.kdl \
      '// extraConfig'

    assertFileContains \
      home-files/.config/zellij/config.kdl \
      'This_could_have_been_json'
  '';
}
