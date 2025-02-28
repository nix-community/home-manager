{ config, ... }: {
  programs.ghostty = {
    enable = true;
    # TODO: remove after we automatically stub on darwin
    package = config.lib.test.mkStubPackage { };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/ghostty/config
  '';
}
