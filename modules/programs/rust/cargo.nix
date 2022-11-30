{ config, pkgs, lib, ... }:
with builtins // lib;
let
  cfg = config.programs.rust.cargo;
  tomlFormat = pkgs.formats.toml { };
in {
  options.programs.rust.cargo = {
    enable = mkEnableOption "cargo, the Rust build system";
    package =
      mkPackageOption config.programs.rust.toolchainPackages "cargo" { };
    settings = mkOption {
      type = types.nullOr tomlFormat.type;
      description = ''
        Configuration written to <code>$HOME/.cargo/config.toml</code>.
        If set to <code>null</code>, no file will be generated.
      '';
      default = null;
      defaultText = literalExpression "null";
      example = literalExpression ''
        {
          cargo-new.vcs = "pijul";
        }
      '';
    };
  };
  config.home = mkIf cfg.enable {
    packages = [ cfg.package ];
    file.".cargo/config.toml" = mkIf (cfg.settings != null) {
      source = tomlFormat.generate "cargo-config" cfg.settings;
    };
  };
}
