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
  meta.maintainers = with lib.maintainers; [
    da157
    PopeRigby
  ];

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
        {file}`$XDG_CONFIG_HOME/television/cable/NAME.toml`

        See <https://alexpasmantier.github.io/television/docs/Users/channels>
        for options
      '';
      example = {
        git-diff = {
          metadata = {
            name = "git-diff";
            description = "A channel to select files from git diff commands";
            requirements = [ "git" ];
          };
          source = {
            command = "git diff --name-only HEAD";
          };
          preview = {
            command = "git diff HEAD --color=always -- '{}'";
          };
        };
        git-log = {
          metadata = {
            name = "git-log";
            description = "A channel to select from git log entries";
            requirements = [ "git" ];
          };
          source = {
            command = "git log --oneline --date=short --pretty=\"format:%h %s %an %cd\" \"$@\"";
            output = "{split: :0}";
          };
          preview = {
            command = "git show -p --stat --pretty=fuller --color=always '{0}'";
          };
        };
      };

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
        lib.nameValuePair "television/cable/${name}.toml" {
          source = tomlFormat.generate "television-${name}-channels" value;
        }
      ) cfg.channels)
    ];

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
      source ${cfg.package}/share/television/completion.bash
    '';
    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
      source ${cfg.package}/share/television/completion.zsh
    '';
    programs.fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
      source ${cfg.package}/share/television/completion.fish
    '';
  };
}
