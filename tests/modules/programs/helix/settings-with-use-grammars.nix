{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.helix = {
      enable = true;

      languages = [{
        name = "rust";
        auto-format = false;
      }];

      grammars = [{
        name = "lalrpop";
        source = {
          git = "https://github.com/traxys/tree-sitter-lalrpop";
          rev = "7744b56f03ac1e5643fad23c9dd90837fe97291e";
        };
      }];

      use-grammars = { except = [ "yaml" "json" ]; };
    };

    test.stubs.helix = { };

    nmt.script = ''
      assertFileContent \
        home-files/.config/helix/languages.toml \
        ${./languages-expected-use-grammars.toml}
    '';
  };
}
