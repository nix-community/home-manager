{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.ne;

  autoPrefFiles =
    let
      autoprefs =
        cfg.automaticPreferences
        // lib.optionalAttrs (cfg.defaultPreferences != "") {
          ".default" = cfg.defaultPreferences;
        };

      gen =
        fileExtension: configText:
        lib.nameValuePair ".ne/${fileExtension}#ap" {
          text = configText;
        }; # Generates [path].text format expected by home.file.
    in
    lib.mapAttrs' gen autoprefs;

in
{
  meta.maintainers = [ lib.hm.maintainers.cwyc ];

  options.programs.ne = {
    enable = lib.mkEnableOption "ne";

    package = lib.mkPackageOption pkgs "ne" { nullable = true; };

    keybindings = mkOption {
      type = types.lines;
      default = "";
      example = ''
        KEY 7f BS
        SEQ "\x1b[1;5D" 7f
      '';
      description = ''
        Keybinding file for ne.
      '';
    };

    defaultPreferences = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Default preferences for ne.

        Equivalent to `programs.ne.automaticPreferences.".default"`.
      '';
    };

    automaticPreferences = mkOption {
      type = types.attrsOf types.lines;
      default = { };
      example = lib.literalExpression ''
        {
          nix = '''
            TAB 0
            TS 2
          ''';
          js = '''
            TS 4
          ''';
        }
      '';
      description = ''
        Automatic preferences files for ne.
      '';
    };

    menus = mkOption {
      type = types.lines;
      default = "";
      description = "Menu configuration file for ne.";
    };

    virtualExtensions = mkOption {
      type = types.lines;
      default = "";
      example = ''
        sh   1  ^#!\s*/.*\b(bash|sh|ksh|zsh)\s*
        csh  1  ^#!\s*/.*\b(csh|tcsh)\s*
      '';
      description = "Virtual extensions configuration file for ne.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file = {
      ".ne/.keys" = mkIf (cfg.keybindings != "") { text = cfg.keybindings; };
      ".ne/.extensions" = mkIf (cfg.virtualExtensions != "") { text = cfg.virtualExtensions; };
      ".ne/.menus" = mkIf (cfg.menus != "") { text = cfg.menus; };
    } // autoPrefFiles;
  };
}
