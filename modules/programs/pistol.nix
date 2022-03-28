{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.pistol;

  configFile =
    concatStringsSep "\n" (mapAttrsToList (k: v: "${k} ${v}") cfg.config);

in {
  meta.maintainers = [ hm.maintainers.mtoohey ];

  options.programs.pistol = {
    enable = mkEnableOption ''
      Pistol, a general purpose file previewer designed for terminal file
      managers'';

    config = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = literalExpression ''
        {
          "text/*" = "bat --paging=never --color=always %pistol-filename%";
          "inode/directory" = "ls -l --color %pistol-filename%";
        }
      '';
      description = ''
        Pistol configuration written to
        <filename>$XDG_CONFIG_HOME/pistol/pistol.conf</filename>.
      '';
    };

  };

  config = mkIf cfg.enable (mkMerge [
    { home.packages = [ pkgs.pistol ]; }

    (mkIf (cfg.config != { } && pkgs.stdenv.hostPlatform.isDarwin) {
      home.file."Library/Application Support/pistol/pistol.conf".text =
        configFile;
    })

    (mkIf (cfg.config != { } && !pkgs.stdenv.hostPlatform.isDarwin) {
      xdg.configFile."pistol/pistol.conf".text = configFile;
    })
  ]);
}
