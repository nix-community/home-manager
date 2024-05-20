{ config, lib, pkgs, ... }:

let

  cfg = config.programs.zk;
  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ lib.hm.maintainers.silmarp ];

  options.programs.zk = {
    enable = lib.mkEnableOption "zk";

    package = lib.mkPackageOption pkgs "zk" { };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
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
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/zk/config.toml`.

        See <https://github.com/mickael-menu/zk/blob/main/docs/config.md> for
        available options and documentation.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."zk/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "config.toml" cfg.settings;
    };
  };
}
