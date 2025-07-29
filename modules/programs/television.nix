{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    hm
    literalExpression
    maintainers
    mapAttrs'
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    nameValuePair
    ;

  inherit (lib.types)
    attrsOf
    ;

  cfg = config.programs.television;
  settingsFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with maintainers; [
    awwpotato
    PopeRigby
  ];

  options.programs.television = {
    enable = mkEnableOption "television";
    package = mkPackageOption pkgs "television" { nullable = true; };
    settings = mkOption {
      type = settingsFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/television/config.toml`.
        See <https://github.com/alexpasmantier/television/blob/main/.config/config.toml>
        for the full list of options.
      '';
      example = literalExpression ''
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
    channels = mkOption {
      type = attrsOf settingsFormat.type;
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
    enableBashIntegration = hm.shell.mkBashIntegrationOption { inherit config; };
    enableZshIntegration = hm.shell.mkZshIntegrationOption { inherit config; };
    enableFishIntegration = hm.shell.mkFishIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = mkMerge [
      {
        "television/config.toml" = mkIf (cfg.settings != { }) {
          source = settingsFormat.generate "config.toml" cfg.settings;
        };
      }
      (mapAttrs' (
        name: value:
        nameValuePair "television/cable/${name}.toml" {
          source = settingsFormat.generate "${name}-channel" value;
        }
      ) cfg.channels)
    ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${getExe cfg.package} init bash)"
    '';
    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      eval "$(${getExe cfg.package} init zsh)"
    '';
    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
      ${getExe cfg.package} init fish | source
    '';
  };
}
