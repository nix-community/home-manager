{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.zsh.antidote;

  relToDotDir = file:
    (optionalString (config.programs.zsh.dotDir != null)
      (config.programs.zsh.dotDir + "/")) + file;

  zPluginStr = with lib;
    (pluginNames:
      optionalString (pluginNames != [ ]) "${concatStrings (map (name: ''
        ${name}
      '') pluginNames)}");
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

    home.file."${relToDotDir ".zsh_plugins.txt"}".text = zPluginStr cfg.plugins;

    ### move zsh_plugins.txt
    programs.zsh.initExtraBeforeCompInit = ''
      ## home-manager/antidote begin :
      source ${cfg.package}/antidote.zsh
      ${optionalString cfg.useFriendlyNames
      "zstyle ':antidote:bundle' use-friendly-names 'yes'"}
      bundlefile=${relToDotDir ".zsh_plugins.txt"}
      zstyle ':antidote:bundle' file $bundlefile
      staticfile=${relToDotDir ".zsh_plugins.zsh"}
      zstyle ':antidote:static' file $staticfile
      antidote load $bundlefile $staticfile
      ## home-manager/antidote end
    '';
  };
}
