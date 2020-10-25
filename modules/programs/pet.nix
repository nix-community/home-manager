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
    };
  };

in {
  options.programs.pet = {
    enable = mkEnableOption "pet";

    settings = mkOption {
      type = format.type;
      default = { };
      description = ''
        Settings written to <filename>config.toml</filename>. See the pet
        documentation for details.
      '';
    };

    selectcmdPackage = mkOption {
      type = types.package;
      default = pkgs.fzf;
      defaultText = literalExample "pkgs.fzf";
      description = ''
        The package needed for the <varname>settings.selectcmd</varname>.
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

  config = mkIf cfg.enable {
    programs.pet.settings = {
      selectcmd = mkDefault "fzf";
      snippetfile = config.xdg.configHome + "/pet/snippet.toml";
    };

    home.packages = [ pkgs.pet cfg.selectcmdPackage ];

    xdg.configFile = {
      "pet/config.toml".source =
        format.generate "config.toml" { General = cfg.settings; };
      "pet/snippet.toml".source =
        format.generate "snippet.toml" { snippets = cfg.snippets; };
    };
  };
}
