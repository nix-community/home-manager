{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.tmux;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.maintainers.britter ];

  options.programs.tmux.tmuxinator = {
    enable = lib.mkEnableOption "tmuxinator";

    package = lib.mkPackageOption pkgs "tmuxinator" { nullable = true; };

    projects = lib.mkOption {
      type = lib.types.attrsOf yamlFormat.type;
      default = { };
      description = ''
        Tmuxinator projects to write to {file}`$HOME/.config/tmuxinator`.
        One project configuration file is generated per attribute.
        See <https://github.com/tmuxinator/tmuxinator> for the project
        configuration format.
      '';
      example = lib.literalExpression ''
        {
          myproject = {
            root = "~/code/myproject";
            windows = [
              {
                editor = {
                  layout = "main-vertical";
                  panes = [
                    { editor = [ "vim" ]; }
                    "guard"
                  ];
                };
              }
              { server = "bundle exec rails s"; }
              { logs = "tail -f log/development.log"; }
            ];
          };
        }
      '';
    };
  };

  config = lib.mkIf (cfg.enable && cfg.tmuxinator.enable) {
    home.packages = lib.mkIf (cfg.tmuxinator.package != null) [ cfg.tmuxinator.package ];

    xdg.configFile = lib.mapAttrs' (
      k: v:
      lib.nameValuePair "tmuxinator/${k}.yml" {
        source = yamlFormat.generate "${k}.yml" v;
      }
    ) cfg.tmuxinator.projects;
  };
}
