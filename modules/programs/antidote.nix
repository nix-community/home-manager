{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.zsh.antidote;

  zPluginStr = (pluginNames:
    optionalString (pluginNames != [ ]) "${concatStrings (map (name: ''
      ${name}
    '') pluginNames)}");

  parseHashId = path:
    elemAt (builtins.match "${builtins.storeDir}/([a-zA-Z0-9]+)-.*" path) 0;
in {
  meta.maintainers = [ maintainers.hitsmaxft ];

  options.programs.zsh.antidote = {
    enable = mkEnableOption "antidote - a zsh plugin manager";

    plugins = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "zsh-users/zsh-autosuggestions" ];
      description = "List of antidote plugins.";
    };

    useFriendlyNames = mkEnableOption "friendly names";

    package = mkPackageOption pkgs "antidote" { };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    programs.zsh.initExtraBeforeCompInit = let
      configFiles = pkgs.runCommand "hm_antidote-files" { } ''
        echo "${zPluginStr cfg.plugins}" > $out
      '';
      hashId = parseHashId "${configFiles}";
    in ''
      ## home-manager/antidote begin :
      source ${cfg.package}/share/antidote/antidote.zsh
      ${optionalString cfg.useFriendlyNames
      "zstyle ':antidote:bundle' use-friendly-names 'yes'"}

      bundlefile=${configFiles}
      zstyle ':antidote:bundle' file $bundlefile
      staticfile=/tmp/tmp_hm_zsh_plugins.zsh-${hashId}
      zstyle ':antidote:static' file $staticfile

      antidote load $bundlefile $staticfile

      ## home-manager/antidote end
    '';
  };
}
