{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption types;

  cfg = config.programs.pet;

  format = pkgs.formats.toml { };

  snippetType = types.submodule {
    options = {
      description = mkOption {
        type = types.str;
        default = "";
        example = "Count the number of commits in the current branch";
        description = ''
          Description of the snippet.
        '';
      };

      command = mkOption {
        type = types.str;
        default = "";
        example = "git rev-list --count HEAD";
        description = ''
          The command.
        '';
      };

      output = mkOption {
        type = types.str;
        default = "";
        example = "473";
        description = ''
          Example output of the command.
        '';
      };

      tag = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = lib.literalExpression ''["git" "nixpkgs"]'';
        description = ''
          List of tags attached to the command.
        '';
      };
    };
  };

in {
  options.programs.pet = {
    enable = lib.mkEnableOption "pet";

    settings = mkOption {
      type = format.type;
      default = { };
      description = ''
        Settings written to {file}`config.toml`. See the pet
        documentation for details.
      '';
    };

    selectcmdPackage = mkOption {
      type = types.package;
      default = pkgs.fzf;
      defaultText = lib.literalExpression "pkgs.fzf";
      description = ''
        The package needed for the {var}`settings.selectcmd`.
      '';
    };

    snippets = mkOption {
      type = types.listOf snippetType;
      default = [ ];
      description = ''
        The snippets.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.pet.settings = let
      defaultGeneral = {
        selectcmd = lib.mkDefault "fzf";
        snippetfile = config.xdg.configHome + "/pet/snippet.toml";
      };
    in if lib.versionAtLeast config.home.stateVersion "21.11" then {
      General = defaultGeneral;
    } else
      defaultGeneral;

    home.packages = [ pkgs.pet cfg.selectcmdPackage ];

    xdg.configFile = {
      "pet/config.toml".source = format.generate "config.toml"
        (if lib.versionAtLeast config.home.stateVersion "21.11" then
          cfg.settings
        else {
          General = cfg.settings;
        });
      "pet/snippet.toml" = lib.mkIf (cfg.snippets != [ ]) {
        source = format.generate "snippet.toml" { snippets = cfg.snippets; };
      };
    };
  };
}
