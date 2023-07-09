{ pkgs, ... }:

{
  config = {
    programs.darcs = {
      enable = true;
      author = [
        "Real Person <personal@example.com>"
        "Real Person <corporate@example.com>"
      ];
    };

    nmt.script = ''
      assertFileContent home-files/.darcs/author ${./author-expected.txt}
    '';
  };
}
