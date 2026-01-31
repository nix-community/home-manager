{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    types
    literalExpression
    ;

  cfg = config.programs.fresh-editor;
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.maintainers; [ drupol ];
  options.programs.fresh-editor = {
    enable = mkEnableOption "fresh-editor";
    package = mkPackageOption pkgs "fresh-editor" { nullable = true; };
    extraPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = literalExpression "[ pkgs.rust-analyzer ]";
      description = "Extra package to add to fresh";
    };
    defaultEditor = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to configure {command}`fresh` as the default
        editor using the {env}`EDITOR` and {env}`VISUAL`
        environment variables.
      '';
    };
    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        version = 1;
        theme = "dark";
        editor = {
          tab_size = 4;
          line_numbers = true;
        };
      };
      description = ''
        Configuration settings for fresh-editor. Find more configuration options in the user guide at:
        <https://github.com/sinelaw/fresh/blob/master/docs/USER_GUIDE.md>
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      if cfg.extraPackages != [ ] then
        [
          (pkgs.symlinkJoin {
            name = "${lib.getName cfg.package}-wrapped-${lib.getVersion cfg.package}";
            paths = [ cfg.package ];
            preferLocalBuild = true;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/fresh \
                --suffix PATH : ${lib.makeBinPath cfg.extraPackages}
            '';
          })
        ]
      else
        [ cfg.package ];

    home.sessionVariables = mkIf cfg.defaultEditor {
      EDITOR = "fresh";
      VISUAL = "fresh";
    };

    xdg.configFile."fresh/config.json" = mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "config.json" cfg.settings;
    };
  };
}
