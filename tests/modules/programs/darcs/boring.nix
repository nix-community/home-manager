{ pkgs, ... }:

{
  config = {
    programs.darcs = {
      enable = true;
      boring = [ "^.idea$" ".iml$" "^.stack-work$" ];
    };

    nmt.script = ''
      assertFileContent home-files/.darcs/boring ${./boring-expected.txt}
    '';
  };
}
