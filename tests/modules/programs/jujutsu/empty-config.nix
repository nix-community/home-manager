{ ... }:

{
  programs.jujutsu.enable = true;

  test.stubs.jujutsu = { };

  nmt.script = ''
    assertPathNotExists home-files/.config/jj/config.toml
    assertPathNotExists "home-files/Library/Application Support/jj/config.toml"
  '';
}
