{ lib, ... }:
{
  programs.astroid = {
    enable = true;
    package = null;
    externalEditor = lib.mkIf false "disabled";
    extraConfig = lib.mkIf false { editor.cmd = "disabled"; };
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertPathNotExists home-files/.config/astroid/config
  '';
}
