{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.lsd;

  yamlFormat = pkgs.formats.yaml { };
in
{
  imports =
    let
      msg = ''
        'programs.lsd.enableAliases' has been deprecated and replaced with integration
        options per shell, for example, 'programs.lsd.enableBashIntegration'.

        Note, the default for these options is 'true' so if you want to enable the
        aliases you can simply remove 'programs.lsd.enableAliases' from your
        configuration.'';
    in
    [ (lib.mkRemovedOptionModule [ "programs" "lsd" "enableAliases" ] msg) ];

  meta.maintainers = [ ];

  options.programs.lsd = {
    enable = lib.mkEnableOption "lsd";

    package = lib.mkPackageOption pkgs "lsd" { nullable = true; };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      example = {
        date = "relative";
        ignore-globs = [
          ".git"
          ".hg"
        ];
      };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/lsd/config.yaml`. See
        <https://github.com/Peltoche/lsd#config-file-content>
        for supported values.
      '';
    };

    colors = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      example = {
        size = {
          none = "grey";
          small = "yellow";
          large = "dark_yellow";
        };
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/lsd/colors.yaml`. See
        <https://github.com/lsd-rs/lsd/tree/v1.0.0#color-theme-file-content> for
        supported colors.

        If this option is non-empty then the `color.theme` option is
        automatically set to `"custom"`.
      '';
    };

    icons = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      example = {
        name = {
          ".trash" = "";
          ".cargo" = "";
        };
        extension = {
          "go" = "";
          "hs" = "";
        };
        filetype = {
          "dir" = "📂";
          "file" = "📄";
        };
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/lsd/icons.yaml`. See
        <https://github.com/lsd-rs/lsd?tab=readme-ov-file#icon-theme-file-content> for
        details.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    programs =
      let
        aliases = {
          ls = "${pkgs.lsd}/bin/lsd";
          ll = "${pkgs.lsd}/bin/lsd -l";
          la = "${pkgs.lsd}/bin/lsd -A";
          lt = "${pkgs.lsd}/bin/lsd --tree";
          lla = "${pkgs.lsd}/bin/lsd -lA";
          llt = "${pkgs.lsd}/bin/lsd -l --tree";
        };
      in
      {
        bash.shellAliases = lib.mkIf cfg.enableBashIntegration aliases;

        fish = lib.mkMerge [
          (lib.mkIf (!config.programs.fish.preferAbbrs) {
            shellAliases = lib.mkIf cfg.enableFishIntegration aliases;
          })

          (lib.mkIf config.programs.fish.preferAbbrs {
            shellAbbrs = lib.mkIf cfg.enableFishIntegration aliases;
          })
        ];

        lsd = lib.mkIf (cfg.colors != { }) { settings.color.theme = "custom"; };

        zsh.shellAliases = lib.mkIf cfg.enableZshIntegration aliases;
      };

    xdg.configFile = {
      "lsd/colors.yaml" = lib.mkIf (cfg.colors != { }) {
        source = yamlFormat.generate "lsd-colors" cfg.colors;
      };

      "lsd/config.yaml" = lib.mkIf (cfg.settings != { }) {
        source = yamlFormat.generate "lsd-config" cfg.settings;
      };

      "lsd/icons.yaml" = lib.mkIf (cfg.icons != { }) {
        source = yamlFormat.generate "lsd-icons" cfg.icons;
      };
    };
  };
}
