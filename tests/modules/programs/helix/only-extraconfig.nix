{ config, ... }:
{
  programs.helix = {
    enable = true;
    extraConfig = ''
      [editor]
      auto-pairs = false
    '';
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/helix/config.toml \
      ${./only-extraconfig-expected.toml}
  '';
}
