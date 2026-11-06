{ config, ... }:
{
  programs.mitos = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "mitos"; };
    extraConfig = ''
      [editor.auto-pairs]
      enable = false
    '';
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/mitos/config.toml \
      ${./only-extraconfig-expected.toml}
  '';
}
