{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.neomutt = {
      enable = true;

      binds = [{
        action = "complete-query";
        key = "<Tab>";
        map = [ ];
      }];

      macros = [{
        action = "<change-folder>?<change-dir><home>^K=<enter><tab>";
        key = "c";
        map = [ ];
      }];
    };

    test.asserts.assertions.expected = [
      "The 'programs.neomutt.(binds|macros).map' list must contain at least one element."
    ];
  };
}
