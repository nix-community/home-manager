{ config, pkgs, lib, ... }:
with builtins // lib;
let
  cfg = config.programs.rust.rustfmt;
  tomlFormat = pkgs.formats.toml { };
in {
  options.programs.rust.rustfmt = {
    enable = mkEnableOption "rustfmt, the Rust formatter";
    package =
      mkPackageOption config.programs.rust.toolchainPackages "rustfmt" { };
    settings = mkOption {
      type = types.nullOr tomlFormat.type;
      description = ''
        Configuration written to <code>$XDG_CONFIG_HOME/rustfmt/rustfmt.toml</code>.
        If set to <code>null</code>, no file will be generated.
      '';
      default = null;
      defaultText = literalExpression "null";
      example = literalExpression ''
        {
          indent_style = "Block";
          reorder_imports = false;
        }
      '';
    };
  };
  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."rustfmt/rustfmt.toml" = mkIf (cfg.settings != null) {
      source = tomlFormat.generate "rustfmt-config" cfg.settings;
    };
  };
}
