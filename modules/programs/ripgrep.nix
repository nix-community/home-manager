{ config, lib, pkgs, ... }:

with lib;

let cfg = config.programs.ripgrep;
in {
  meta.maintainers = [ maintainers.pedorich-n ];

  options = {
    programs.ripgrep = {
      enable = mkEnableOption "Ripgrep";

      package = mkOption {
        type = types.package;
        default = pkgs.ripgrep;
        defaultText = literalExpression "pkgs.ripgrep";
        description =
          "Package containing the <command>ripgrep</command> program.";
      };

      configDir = mkOption {
        type = types.str;
        default = "${config.xdg.configHome}/ripgrep";
        defaultText = literalExpression "\${config.xdg.configHome}/ripgrep";
        description = ''
          Directory where the <filename>ripgreprc</filename> file will be stored (Inside $HOME).
        '';
      };

      config = mkOption {
        type = with types; listOf str;
        default = [ ];
        defaultText = literalExpression "[]";
        example = [ "--max-columns-preview" "--colors=line:style:bold" ];
        description = ''
          List of arguments to pass to ripgrep. Each line is given to ripgrep as a single command line argument verbatim.

          See <link xlink:href="https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#configuration-file"/>
          for an example configuration.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ cfg.package ];

      file."${cfg.configDir}/ripgreprc" = mkIf (cfg.config != [ ]) {
        text = (builtins.concatStringsSep "\n" cfg.config) + "\n";
      };

      sessionVariables = {
        "RIPGREP_CONFIG_PATH" = "${cfg.configDir}/ripgreprc";
      };
    };
  };
}
