{
  programs = {
    zellij = {
      enable = true;

      settings = {
        default_layout = "welcome";
      };
      # No extraConfig
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
  '';
}
