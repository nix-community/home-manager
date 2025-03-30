{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression mkOption types;

  cfg = config.programs.boxxy;

  configPath = "${config.xdg.configHome}/boxxy/boxxy.yaml";
  settingsFormat = pkgs.formats.yaml { };

  boxxyRulesOpts = types.submodule {
    freeformType = settingsFormat.type;

    options = {
      name = mkOption {
        type = types.str;
        description = ''
          Unique identifier of the boxxy rule. This can be any single-line string.
        '';
      };

      target = mkOption {
        type = types.str;
        default = "";
        example = "~/.ssh";
        description = ''
          What directory/file to redirect.
        '';
      };

      rewrite = mkOption {
        type = types.str;
        default = "";
        example = literalExpression ''"''${config.xdg.configHome}/ssh"'';
        description = ''
          Where that file/directory should be rewritten to.
        '';
      };

      mode = mkOption {
        type = types.enum [ "file" "directory" ];
        default = "directory";
        description = ''
          Does the current path redirect a file or a directory?
        '';
      };

      only = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = literalExpression ''
          [
            "bash"
            "/usr/bin/sh"
          ]
        '';
        description = ''
          Apply redirection ONLY to specified executable names.
        '';
      };

      context = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "/home/example/Projects/my-project" ];
        description = ''
          Apply redirection ONLY when in a certain directory.
        '';
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = literalExpression ''
          {
            MY_ENV_VAR = "my_env_var_value";
          }
        '';
        description = ''
          Give certain environment variables for said match.
        '';
      };
    };
  };
in {
  options.programs.boxxy = {
    enable = lib.mkEnableOption "boxxy: Boxes in badly behaving applications";

    package = lib.mkPackageOption pkgs "boxxy" { nullable = true; };

    rules = mkOption {
      type = types.listOf boxxyRulesOpts;
      default = [ ];
      description = "List of boxxy rules";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.boxxy" pkgs
        lib.platforms.linux)
    ];

    home.file = lib.mkIf (cfg.rules != [ ]) {
      "${configPath}".source =
        settingsFormat.generate "boxxy-config.yaml" { rules = cfg.rules; };
    };

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
  };

  meta.maintainers = with lib.hm.maintainers; [ nikp123 ];
}

