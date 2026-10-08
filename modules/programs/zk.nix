{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.zk;
  tomlFormat = pkgs.formats.toml { };
  notebookDir = lib.attrByPath [ "notebook" "dir" ] null cfg.settings;
in
{
  meta.maintainers = [ lib.hm.maintainers.silmarp ];

  options.programs.zk = {
    enable = lib.mkEnableOption "zk";

    package = lib.mkPackageOption pkgs "zk" { nullable = true; };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        note = {
          language = "en";
          default-title = "Untitled";
          filename = "{{id}}-{{slug title}}";
          extension = "md";
          template = "default.md";
          id-charset = "alphanum";
          id-length = 4;
          id-case = "lower";
        };
        extra = {
          author = "Mickaël";
        };
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/zk/config.toml`.

        See <https://github.com/mickael-menu/zk/blob/main/docs/config.md> for
        available options and documentation.
      '';
    };

    exportNotebookDir = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to export {env}`ZK_NOTEBOOK_DIR` from
        {option}`programs.zk.settings.notebook.dir`.

        zk reads the default notebook from its configuration file, so this is
        only needed for programs that read the environment variable directly,
        such as editor plugins started outside a notebook directory.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.exportNotebookDir -> notebookDir != null;
        message = "programs.zk.exportNotebookDir requires programs.zk.settings.notebook.dir.";
      }
      {
        # The exported value is written to a double-quoted shell assignment, so
        # the shell never expands a leading tilde.
        assertion = cfg.exportNotebookDir -> !(lib.hasPrefix "~" (toString notebookDir));
        message = ''
          programs.zk.settings.notebook.dir must be an absolute path when
          programs.zk.exportNotebookDir is enabled.
        '';
      }
    ];
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.sessionVariables = lib.mkIf cfg.exportNotebookDir {
      ZK_NOTEBOOK_DIR = notebookDir;
    };

    xdg.configFile."zk/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "config.toml" cfg.settings;
    };
  };
}
