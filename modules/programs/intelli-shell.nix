{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  inherit (lib.hm.shell)
    mkBashIntegrationOption
    mkZshIntegrationOption
    mkFishIntegrationOption
    mkNushellIntegrationOption
    ;

  cfg = config.programs.intelli-shell;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.intelli-shell = {
    enable = mkEnableOption "intelli-shell";
    package = mkPackageOption pkgs "intelli-shell" { nullable = true; };
    enableBashIntegration = mkBashIntegrationOption { inherit config; };
    enableZshIntegration = mkZshIntegrationOption { inherit config; };
    enableFishIntegration = mkFishIntegrationOption { inherit config; };
    enableNushellIntegration = mkNushellIntegrationOption { inherit config; };
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        data_dir = "/home/myuser/my/custom/datadir";
        check_updates = false;
        logs.enabled = false;
        theme = {
          primary = "default";
          secondary = "dim";
          accent = "yellow";
          comment = "italic green";
          error = "dark red";
          highlight = "darkgrey";
          highlight_symbol = "» ";
          highlight_primary = "default";
          highlight_secondary = "default";
          highlight_accent = "yellow";
          highlight_comment = "italic green";
        };
      };
      description = ''
        Configuration settings for intelli-shell. You can see all the available options here:
        <https://github.com/lasantosr/intelli-shell/blob/main/default_config.toml>.
      '';
    };

    shellHotkeys = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = {
        search_hotkey = "\\\\C-t";
        bookmark_hotkey = "\\\\C-b";
        variable_hotkey = "\\\\C-a";
        fix_hotkey = "\\\\C-p";
        skip_esc_bind = "\\\\C-q";
      };
      description = ''
        Settings for customizing the keybinding to integrate your shell with intelli-shell. You can see the details
        here: <https://lasantosr.github.io/intelli-shell/guide/installation.html#customizing-shell-integration>.
      '';
    };
  };

  config =
    let
      configPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/org.IntelliShell.Intelli-Shell"
        else
          ".config/intelli-shell";
    in
    mkIf cfg.enable {
      home = {
        packages = mkIf (cfg.package != null) [ cfg.package ];
        file."${configPath}/config.toml" = mkIf (cfg.settings != { }) {
          source = tomlFormat.generate "intelli-shell-config" cfg.settings;
        };
        sessionVariables = mkIf (cfg.shellHotkeys != { }) (
          lib.mapAttrs' (k: v: lib.nameValuePair "INTELLI_${lib.toUpper k}" v) cfg.shellHotkeys
        );
      };
      programs = {
        bash.initExtra = mkIf cfg.enableBashIntegration ''eval "$(intelli-shell init bash)"'';
        zsh.initContent = mkIf cfg.enableZshIntegration ''eval "$(intelli-shell init zsh)"'';
        fish.interactiveShellInit = mkIf cfg.enableFishIntegration "intelli-shell init fish | source";
        nushell.extraConfig = mkIf cfg.enableNushellIntegration ''
          mkdir ($nu.data-dir | path join "vendor/autoload")
          intelli-shell init nushell | save -f ($nu.data-dir | path join "vendor/autoload/intelli-shell.nu")
        '';
      };
    };
}
