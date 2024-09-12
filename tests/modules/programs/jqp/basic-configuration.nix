{ config, pkgs, ... }:

{
  programs = {
    jqp.enable = true;
    jqp.config = { theme.name = "catppuccin-frappe"; };
  };

  test.stubs.jqp = { };

  nmt.script = ''
    assertFileExists home-files/.jqp.yaml
    assertFileContent home-files/.jqp.yaml \
        ${./basic-configuration.yaml}
  '';
}
