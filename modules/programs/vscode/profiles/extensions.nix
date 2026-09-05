# allows specifying extensions
# these are parsed by the parent module (for now)
{
  appName,
  lib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) literalExpression mkOption;
in
{

  _class = "homeManager.vscodeProfile";

  options = {

    extensions = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = literalExpression "[ pkgs.vscode-extensions.bbenoist.nix ]";
      description = ''
        The extensions ${appName} should be started with.
      '';
    };

  };

}
