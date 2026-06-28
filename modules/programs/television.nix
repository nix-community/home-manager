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
    PopeRigby
    csanthiago
  ];

  options.programs.television = {
    enable = lib.mkEnableOption "television";
    package = lib.mkPackageOption pkgs "television" { nullable = true; };

    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = with pkgs; [
        fd
        bat
        ripgrep
      ];
      defaultText = lib.literalExpression "with pkgs; [ fd bat ripgrep ]";
      example = lib.literalExpression "with pkgs; [ eza ]";
      description = ''
        Extra packages available to television.
      '';
    };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/television/config.toml`.
        See <https://github.com/alexpasmantier/television/blob/main/.config/config.toml>
        for the full list of options.
      '';
      example = {
        tick_rate = 50;
        ui = {
          use_nerd_font_icons = true;
          ui_scale = 120;
          show_preview_panel = false;
        };
        keybindings = {
          quit = [
            "esc"
            "ctrl-c"
          ];
        };
      };
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

    themes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          tomlFormat.type
          lib.types.lines
          lib.types.path
        ]
      );
      default = { };
      example = {
        default = {
          border_fg = "bright-black";
          text_fg = "bright-blue";
          dimmed_text_fg = "white";
          input_text_fg = "bright-red";
          result_count_fg = "bright-red";
          result_name_fg = "bright-blue";
          result_line_number_fg = "bright-yellow";
          result_value_fg = "white";
          selection_fg = "bright-green";
          selection_bg = "bright-black";
          match_fg = "bright-red";
          preview_title_fg = "bright-magenta";
          channel_mode_fg = "black";
          channel_mode_bg = "green";
          remote_control_mode_fg = "black";
          remote_control_mode_bg = "yellow";
          action_picker_mode_fg = "black";
          action_picker_mode_bg = "magenta";
          send_to_channel_mode_fg = "cyan";
        };
      };
      description = ''
        Each theme is written to
        {file}`$XDG_CONFIG_HOME/television/themes/NAME.toml`.

        See <https://alexpasmantier.github.io/television/user-guide/themes>
        for more information.
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };
    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };
    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) (
      if cfg.extraPackages != [ ] then
        [
          (pkgs.symlinkJoin {
            name = "${lib.getName cfg.package}-wrapped-${lib.getVersion cfg.package}";
            paths = [ cfg.package ];
            preferLocalBuild = true;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/tv \
                --suffix PATH : ${lib.makeBinPath cfg.extraPackages}
            '';
          })
        ]
      else
        [ cfg.package ]
    );

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
      (lib.mapAttrs' (
        name: value:
        lib.nameValuePair "television/themes/${name}.toml" {
          source =
            if lib.isString value then
              pkgs.writeText "television-theme-${name}" value
            else if lib.hm.strings.isPathLike value then
              value
            else
              tomlFormat.generate "television-theme-${name}" value;
        }
      ) cfg.themes)
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
    programs.nushell = lib.mkIf cfg.enableNushellIntegration {
      extraConfig = "source ${cfg.package}/share/television/completion.nu";
    };
  };
}
