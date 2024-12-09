{ ... }:

{
  programs.atuin.enable = true;

  test.stubs = {
    atuin = { name = "atuin"; };
    bash-preexec = { };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/atuin/config.toml
  '';
}
