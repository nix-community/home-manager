# allows configuring code snippets
# these are parsed by the parent module (for now)
{
  lib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption;
in
{

  _class = "homeManager.vscodeProfile";

  options = {

    languageSnippets = mkOption {
      type = types.json;
      default = { };
      example = {
        haskell = {
          fixme = {
            prefix = [ "fixme" ];
            body = [ "$LINE_COMMENT FIXME: $0" ];
            description = "Insert a FIXME remark";
          };
        };
      };
      description = "Defines user snippets for different languages.";
    };

    globalSnippets = mkOption {
      type = types.json;
      default = { };
      example = {
        fixme = {
          prefix = [ "fixme" ];
          body = [ "$LINE_COMMENT FIXME: $0" ];
          description = "Insert a FIXME remark";
        };
      };
      description = "Defines global user snippets.";
    };

  };

}
