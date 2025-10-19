{
  programs = {
    zellij = {
      enable = true;

      settings = {
        default_layout = "welcome";
      };
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
      'default_layout "welcome"'

    assertFileContains \
      home-files/.config/zellij/config.kdl \
      '// extraConfig'

    assertFileContains \
      home-files/.config/zellij/config.kdl \
      'This_could_have_been_json'
  '';
}
