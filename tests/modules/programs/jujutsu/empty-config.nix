{ ... }:

{
  programs.jujutsu.enable = true;

  test.stubs.jujutsu = { };

  nmt.script = ''
    assertPathNotExists home-files/.jjconfig.toml
  '';
}
