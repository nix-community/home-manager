{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.gitui;

in {
  meta.maintainers = [ hm.maintainers.mifom ];

  options.programs.gitui = {
    enable =
      mkEnableOption "gitui, blazing fast terminal-ui for git written in rust";

    package = mkOption {
      type = types.package;
      default = pkgs.gitui;
      defaultText = "pkgs.gitui";
      description = "The package to use.";
    };

    keyConfig = mkOption {
      type = types.either types.path types.lines;
      default = "";
      example = ''
        exit: Some(( code: Char('c'), modifiers: ( bits: 2,),)),
        quit: Some(( code: Char('q'), modifiers: ( bits: 0,),)),
        exit_popup: Some(( code: Esc, modifiers: ( bits: 0,),)),
      '';
      description = ''
        Key config in Ron file format. This is written to
        <filename>$XDG_CONFIG_HOME/gitui/key_config.ron</filename>.
      '';
    };

    theme = mkOption {
      type = types.either types.path types.lines;
      default = ''
        (
          selected_tab: Reset,
          command_fg: White,
          selection_bg: Blue,
          selection_fg: White,
          cmdbar_bg: Blue,
          cmdbar_extra_lines_bg: Blue,
          disabled_fg: DarkGray,
          diff_line_add: Green,
          diff_line_delete: Red,
          diff_file_added: LightGreen,
          diff_file_removed: LightRed,
          diff_file_moved: LightMagenta,
          diff_file_modified: Yellow,
          commit_hash: Magenta,
          commit_time: LightCyan,
          commit_author: Green,
          danger_fg: Red,
          push_gauge_bg: Blue,
          push_gauge_fg: Reset,
          tag_fg: LightMagenta,
          branch_fg: LightYellow,
        )
      '';
      description = ''
        Theme in Ron file format. This is written to
        <filename>$XDG_CONFIG_HOME/gitui/theme.ron</filename>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."gitui/theme.ron".source =
      if builtins.isPath cfg.theme || lib.isStorePath cfg.theme then
        cfg.theme
      else
        pkgs.writeText "gitui-theme.ron" cfg.theme;

    xdg.configFile."gitui/key_bindings.ron".source =
      if builtins.isPath cfg.keyConfig || lib.isStorePath cfg.keyConfig then
        cfg.keyConfig
      else
        pkgs.writeText "gitui-key-config.ron" cfg.keyConfig;
  };
}
