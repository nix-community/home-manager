{
  lib,
  pkgs,
  config,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  cfg = config.programs.television;
in
{
  meta.maintainers = [ lib.maintainers.awwpotato ];

  options.programs.television = {
    enable = lib.mkEnableOption "television";
    package = lib.mkPackageOption pkgs "television" { nullable = true; };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/television/config.toml`.
        See <https://github.com/alexpasmantier/television/blob/main/.config/config.toml>
        for the full list of options.
      '';
      example = lib.literalExpression ''
        {
          tick_rate = 50;
          ui = {
            use_nerd_font_icons = true;
            ui_scale = 120;
            show_preview_panel = false;
          };
          keybindings = {
            quit = [ "esc" "ctrl-c" ];
          };
        }
      '';
    };

    channels = lib.mkOption {
      type = lib.types.attrsOf tomlFormat.type;
      default = { };
      description = ''
        Each set of channels are written to
        {file}`$XDG_CONFIG_HOME/television/NAME-channels.toml`

        See <https://github.com/alexpasmantier/television/blob/main/docs/channels.md>
        for options
      '';
      example = lib.literalExpression ''
        {
          my-custom = {
            cable_channel = [
              {
                name = "git-log";
                source_command = "git log --oneline --date=short --pretty=\"format:%h %s %an %cd\" \"$@\"";
                preview_command = "git show -p --stat --pretty=fuller --color=always {0}";
              }
              {
                name = "git-log";
                source_command = "git log --oneline --date=short --pretty=\"format:%h %s %an %cd\" \"$@\"";
                preview_command = "git show -p --stat --pretty=fuller --color=always {0}";
              }
            ];
          };
        }
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };
    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = lib.mkMerge [
      {
        "television/config.toml" = lib.mkIf (cfg.settings != { }) {
          source = tomlFormat.generate "config.toml" cfg.settings;
        };
      }
      (lib.mapAttrs' (
        name: value:
        lib.nameValuePair "television/${name}-channels.toml" {
          source = tomlFormat.generate "television-${name}-channels" value;
        }
      ) cfg.channels)
    ];

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
      eval "$(${lib.getExe cfg.package} init bash)"
    '';
    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
      eval "$(${lib.getExe cfg.package} init zsh)"
    '';
    programs.fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
      ${lib.getExe cfg.package} init fish | source
    '';
  };
}
