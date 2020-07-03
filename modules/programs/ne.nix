{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.ne;

  autoPrefFiles = let
    autoprefs = cfg.automaticPreferences
      // optionalAttrs (cfg.defaultPreferences != "") {
        ".default" = cfg.defaultPreferences;
      };

    gen = fileExtension: configText:
      nameValuePair ".ne/${fileExtension}#ap" {
        text = configText;
      }; # Generates [path].text format expected by home.file.
  in mapAttrs' gen autoprefs;

in {
  meta.maintainers = [ hm.maintainers.cwyc ];

  options.programs.ne = {
    enable = mkEnableOption "ne";

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
        </para><para>
        Equivalent to <literal>programs.ne.automaticPreferences.".default"</literal>.
      '';
    };

    automaticPreferences = mkOption {
      type = types.attrsOf types.lines;
      default = { };
      example = literalExample ''
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
    home.packages = [ pkgs.ne ];

    home.file = {
      ".ne/.keys" = mkIf (cfg.keybindings != "") { text = cfg.keybindings; };
      ".ne/.extensions" =
        mkIf (cfg.virtualExtensions != "") { text = cfg.virtualExtensions; };
      ".ne/.menus" = mkIf (cfg.menus != "") { text = cfg.menus; };
    } // autoPrefFiles;
  };
}
