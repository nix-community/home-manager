{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.pet;

  format = pkgs.formats.toml { };

  snippetType = types.submodule {
    options = {
      description = mkOption {
        type = types.str;
        default = "";
        example = "Count the number of commits in the current branch";
        description = lib.mdDoc ''
          Description of the snippet.
        '';
      };

      command = mkOption {
        type = types.str;
        default = "";
        example = "git rev-list --count HEAD";
        description = lib.mdDoc ''
          The command.
        '';
      };

      output = mkOption {
        type = types.str;
        default = "";
        example = "473";
        description = lib.mdDoc ''
          Example output of the command.
        '';
      };

      tag = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = literalExpression ''["git" "nixpkgs"]'';
        description = lib.mdDoc ''
          List of tags attached to the command.
        '';
      };
    };
  };

in {
  options.programs.pet = {
    enable = mkEnableOption (lib.mdDoc "pet");

    settings = mkOption {
      type = format.type;
      default = { };
      description = lib.mdDoc ''
        Settings written to {file}`config.toml`. See the pet
        documentation for details.
      '';
    };

    selectcmdPackage = mkOption {
      type = types.package;
      default = pkgs.fzf;
      defaultText = literalExpression "pkgs.fzf";
      description = lib.mdDoc ''
        The package needed for the {var}`settings.selectcmd`.
      '';
    };

    snippets = mkOption {
      type = types.listOf snippetType;
      default = [ ];
      description = lib.mdDoc ''
        The snippets.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.pet.settings = let
      defaultGeneral = {
        selectcmd = mkDefault "fzf";
        snippetfile = config.xdg.configHome + "/pet/snippet.toml";
      };
    in if versionAtLeast config.home.stateVersion "21.11" then {
      General = defaultGeneral;
    } else
      defaultGeneral;

    home.packages = [ pkgs.pet cfg.selectcmdPackage ];

    xdg.configFile = {
      "pet/config.toml".source = format.generate "config.toml"
        (if versionAtLeast config.home.stateVersion "21.11" then
          cfg.settings
        else {
          General = cfg.settings;
        });
      "pet/snippet.toml" = mkIf (cfg.snippets != [ ]) {
        source = format.generate "snippet.toml" { snippets = cfg.snippets; };
      };
    };
  };
}
