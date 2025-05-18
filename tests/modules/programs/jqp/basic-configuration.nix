{
  programs = {
    jqp = {
      enable = true;
      settings = {
        theme.name = "catppuccin-frappe";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.jqp.yaml
    assertFileContent home-files/.jqp.yaml \
        ${./basic-configuration.yaml}
  '';
}
