{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.pet;

  format = pkgs.formats.toml {};

  snippetType = types.submodule {
    options = {
      description = mkOption {
        type = types.str;
        default = "";
        example = "Show expiration date of SSL certificate";
        description = ''
          description of the snippet
        '';
      };

      command = mkOption {
        type = types.str;
        default = "";
        example = "echo | openssl s_client -connect example.com:443 2>/dev/null |openssl x509 -dates -noout";
        description = ''
          the command
        '';
      };

      output = mkOption {
        type = types.str;
        default = "";
        example = ''
          notBefore=Nov  3 00:00:00 2015 GMT
          notAfter=Nov 28 12:00:00 2018 GMT
        '';
        description = ''
          example output of the command
        '';
      };
    };
  };

in

{
  options.programs.pet = {
    enable = mkEnableOption "pet";

    settings = mkOption {
      type = format.type;
      default = {};
      description = ''
        Settings written to config.toml. See the pet docs for details.
      '';
    };

    selectcmdPackage = mkOption {
      type = types.package;
      default = pkgs.fzf;
      description = ''
        A package needed for the <varname>settings.selectcmd</varname>
      '';
    };

    snippets = mkOption {
      type = types.listOf snippetType;
      default = [];
      description = ''
        The snippets
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.pet.settings = {
      selectcmd = mkDefault "fzf";
      snippetfile = config.xdg.configHome + "/pet/snippet.toml";
    };

    home.packages = [ pkgs.pet cfg.selectcmdPackage ];
    xdg.configFile."pet/config.toml".source = format.generate "config.toml" { General = cfg.settings; };
    xdg.configFile."pet/snippet.toml".source = format.generate "snippet.toml" { snippets = cfg.snippets; };
  };
}
