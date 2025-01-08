{ ... }:

{
  programs.vim-vint = {
    enable = true;
    settings = {
      cmdargs = {
        severity = "error";
        color = true;
        env = { neovim = true; };
      };
      policies = {
        ProhibitEqualTildeOperator.enabled = false;
        ProhibitUsingUndeclaredVariable.enabled = false;
        ProhibitAbbreviationOption.enabled = false;
        ProhibitImplicitScopeVariable.enabled = false;
        ProhibitSetNoCompatible.enabled = false;
      };
    };
  };

  test.stubs = { vim-vint = { }; };

  nmt.script = ''
    assertFileContent home-files/.config/.vintrc.yaml ${
      ./basic-configuration.yaml
    }
  '';
}
