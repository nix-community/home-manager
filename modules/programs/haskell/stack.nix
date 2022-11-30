{ config, pkgs, lib, ... }:
with builtins // lib;
let
  cfg = config.programs.haskell.stack;
  yamlFormat = pkgs.formats.yaml { };
in {
  options.programs.haskell.stack = {
    enable = mkEnableOption "the Haskell Tool Stack";
    package = mkPackageOption pkgs "Stack" { default = [ "stack" ]; };
    settings = mkOption {
      type = types.nullOr yamlFormat.type;
      description = ''
        Configuration written to <code>.stack/config.yaml</code>.
        If set to <code>null</code>, no file will be generated.
      '';
      default = null;
      defaultText = literalExpression "null";
      example = literalExpression ''
        {
          color = "never";
        }
      '';
    };
  };
  config.home = mkIf cfg.enable {
    packages = mkIf cfg.enable [ cfg.package ];
    file.".stack/config.yaml" = mkIf (cfg.settings != null) {
      source = yamlFormat.generate "stack-config" cfg.settings;
    };
  };
}
