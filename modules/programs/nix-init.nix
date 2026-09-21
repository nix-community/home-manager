{
  lib,
  pkgs,
  config,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  cfg = config.programs.nix-init;
in
{
  meta.maintainers = [ lib.maintainers.da157 ];

  options.programs.nix-init = {
    enable = lib.mkEnableOption "nix-init";
    package = lib.mkPackageOption pkgs "nix-init" { nullable = true; };
    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          maintainers = [
            "figsoda"
          ];
          nixpkgs = "<nixpkgs>";
          commit = true;
          access-tokens = {
            "github.com" = {
              file = "/path/to/github/token";
            };
            "gitlab.com" = {
              command = [
                "secret-tool"
                "or"
                "whatever"
                "you"
                "use"
              ];
            };
            "gitlab.gnome.org" = {
              file = "/path/to/api/token";
            };
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/nix-init/config.toml`.
        See <https://github.com/nix-community/nix-init#configuration> for the full list
        of options.

        These settings are stored in the world-readable Nix store. For
        `access-tokens`, use a `command` or a `file` entry to retrieve the
        token at runtime instead of putting a literal token in this option.
        Specify token file paths as strings, as in the example, so Nix does
        not copy the token file into the store.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."nix-init/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "config.toml" cfg.settings;
    };
  };
}
