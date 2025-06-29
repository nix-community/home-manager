{ ... }:

{
  programs.ashell = {
    enable = true;
    settings = { };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/ashell/config.toml
    assertPathNotExists home-files/.config/ashell.yml
  '';
}
