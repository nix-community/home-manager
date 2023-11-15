{ ... }:

{
  programs.ruff = {
    enable = true;

    settings = {
      line-length = 100;
      per-file-ignores = { "__init__.py" = [ "F401" ]; };
      lint = {
        select = [ "E4" "E7" "E9" "F" ];
        ignore = [ ];
      };
    };
  };

  test.stubs.ruff = { };

  nmt.script = ''
    assertFileExists home-files/.config/ruff/ruff.toml
    assertFileContent home-files/.config/ruff/ruff.toml ${./expected.toml}
  '';
}
