{
  lib,
  pkgs,
  config,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  cfg = config.programs.nvchecker;
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/nvchecker"
    else
      "${config.xdg.configHome}/nvchecker";
in
{
  meta.maintainers = [ lib.maintainers.mdaniels5757 ];
  options.programs.nvchecker = {
    enable = lib.mkEnableOption "nvchecker";
    package = lib.mkPackageOption pkgs "nvchecker" { nullable = true; };
    settings =
      let
        envDocs = ''
          Environment variables and `~` are expanded,
          and relative paths are relative to
          {file}`''${config.home.homeDirectory}/Library/Application Support/nvchecker/nvchecker/` (on Darwin)
          or {file}`''${config.xdg.configHome}/nvchecker/` (otherwise).
        '';
      in
      lib.mkOption {
        type = lib.types.submodule {
          freeformType = tomlFormat.type;
          options.__config__ = lib.mkOption {
            type = lib.types.submodule {
              freeformType = tomlFormat.type;
              options = {
                oldver = lib.mkOption {
                  # doesn't matter if absolute/relative or (not) in store
                  type = lib.types.pathWith { };
                  default = "old_ver.json";
                  description = ''
                    The file to store 'old' (i.e. installed) version information in.

                    ${envDocs}
                  '';
                };
                newver = lib.mkOption {
                  # doesn't matter if absolute/relative or (not) in store
                  type = lib.types.pathWith { };
                  default = "new_ver.json";
                  description = ''
                    The file to store 'new' (i.e. available) versions in.

                    ${envDocs}
                  '';
                };
              };
            };
            default = { };
            defaultText = lib.literalExpression ''
              {
                oldver = "old_ver.json";
                newver = "new_ver.json";
              };
            '';
            description = ''
              See <https://nvchecker.readthedocs.io/en/stable/usage.html#configuration-files>.

              ${envDocs}
            '';
          };
        };
        default = { };
        defaultText = lib.literalExpression ''
          __config__ = {
            oldver = "old_ver.json";
            newver = "new_ver.json";
          };
        '';
        example = lib.literalExpression ''
          {
            __config__ = {
              oldver = "my_custom_oldver.json";
              newver = "~/seperately_placed_newver.json";
              keyfile = "keyfile.toml";
            };

            nvchecker = {
              source = "github";
              github = "lilydjwg/nvchecker";
            };
          }
        '';
        description = ''
          Configuration written to
          {file}`$HOME/Library/Application Support/nvchecker/nvchecker.toml` (on Darwin) or
          {file}`$XDG_CONFIG_HOME/nvchecker/nvchecker.toml` (otherwise).
          See <https://nvchecker.readthedocs.io/en/stable/usage.html#configuration-files>
          for the full list of options.

          ${envDocs}
        '';
      };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file."${configDir}/nvchecker.toml".source = lib.mkIf (cfg.settings != { }) (
      tomlFormat.generate "nvchecker.toml" cfg.settings
    );
  };
}
