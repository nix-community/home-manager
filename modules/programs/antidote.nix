{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) escapeShellArg;

  cfg = config.programs.zsh.antidote;

  zPluginStr = (
    pluginNames:
    lib.optionalString (pluginNames != [ ])
      "${lib.concatStrings (
        map (name: ''
          ${name}
        '') pluginNames
      )}"
  );

  parseHashId = path: lib.elemAt (builtins.match "${builtins.storeDir}/([a-zA-Z0-9]+)-.*" path) 0;
in
{
  meta.maintainers = [ lib.maintainers.hitsmaxft ];

  options.programs.zsh.antidote = {
    enable = lib.mkEnableOption "antidote - a zsh plugin manager";

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "zsh-users/zsh-autosuggestions" ];
      description = "List of antidote plugins.";
    };

    useFriendlyNames = lib.mkEnableOption "friendly names";

    package = lib.mkPackageOption pkgs "antidote" { nullable = true; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    programs.zsh.initContent =
      let
        configFiles = pkgs.writeText "hm_antidote-files" (zPluginStr cfg.plugins);
        hashId = parseHashId "${configFiles}";
      in
      (lib.mkOrder 550 ''
        ## home-manager/antidote begin :
        source ${escapeShellArg cfg.package}/share/antidote/antidote.zsh
        ${lib.optionalString cfg.useFriendlyNames "zstyle ':antidote:bundle' use-friendly-names 'yes'"}

        bundlefile=${escapeShellArg configFiles}
        zstyle ':antidote:bundle' file $bundlefile
        staticfile=/tmp/tmp_hm_zsh_plugins.zsh-${escapeShellArg hashId}
        zstyle ':antidote:static' file $staticfile

        antidote load $bundlefile $staticfile

        ## home-manager/antidote end
      '');
  };
}
