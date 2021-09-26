{ pkgs, ... }:

{
  config = {
    programs.ncmpcpp.enable = true;

    test.stubs.ncmpcpp = { };

    nmt.script = ''
      assertPathNotExists home-files/.config/ncmpcpp/config

      assertPathNotExists home-files/.config/ncmpcpp/bindings
    '';
  };
}
