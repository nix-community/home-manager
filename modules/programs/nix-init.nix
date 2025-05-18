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
  meta.maintainers = [ lib.maintainers.awwpotato ];

  options.programs.nix-init = {
    enable = lib.mkEnableOption "nix-init";
    package = lib.mkPackageOption pkgs "nix-init" { nullable = true; };
    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          maintainers = [
            "figsoda"
          ];
          nixpkgs = "<nixpkgs>";
          commit = true;
          access-tokens = {
            github.com = "ghp_blahblahblah...";
            gitlab.com = {
              command = [
                "secret-tool"
                "or"
                "whatever"
                "you"
                "use"
              ];
            };
            gitlab.gnome.org = {
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
