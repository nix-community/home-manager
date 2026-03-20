{
  pkgs,
  config,
  lib,
  options,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkIf
    maintainers
    ;
  cfg = config.programs.mergiraf;
in
{
  meta.maintainers = [ maintainers.bobvanderlinden ];

  options = {
    programs.mergiraf = {
      enable = mkEnableOption "mergiraf";

      package = mkPackageOption pkgs "mergiraf" { };

      enableGitIntegration = lib.mkOption {
        type = lib.types.bool;
        default = lib.versionOlder config.home.stateVersion "26.05";
        defaultText = ''lib.versionOlder config.home.stateVersion "26.05"'';
        description = ''
          Whether to enable git integration for mergiraf.

          When enabled, mergiraf will be configured as git's merge driver.
        '';
      };

      enableJujutsuIntegration = lib.mkOption {
        type = lib.types.bool;
        default = lib.versionOlder config.home.stateVersion "26.05";
        defaultText = ''lib.versionOlder config.home.stateVersion "26.05"'';
        description = ''
          Whether to enable jujutsu integration for mergiraf.

          When enabled, mergiraf will be configured as jujutsus's merge tool.
        '';
      };
    };
  };

  config = lib.mkMerge [
    {
      warnings =
        lib.optionals
          (
            cfg.enable
            && config.programs.git.enable
            && !lib.versionAtLeast config.home.stateVersion "26.05"
            && options.programs.mergiraf.enableGitIntegration.highestPrio >= 1500
          )
          [
            ''
              The default value of `programs.mergiraf.enableGitIntegration` will change in future versions.
              You are currently using the legacy default (true) because `home.stateVersion` is less than "26.05".
              To silence this warning set:
                programs.mergiraf.enableGitIntegration = true;
            ''
          ]
        ++
          lib.optionals
            (
              cfg.enable
              && config.programs.jujutsu.enable
              && !lib.versionAtLeast config.home.stateVersion "26.05"
              && options.programs.mergiraf.enableJujutsuIntegration.highestPrio >= 1500
            )
            [
              ''
                The default value of `programs.mergiraf.enableJujutsuIntegration` will change in future versions.
                You are currently using the legacy default (true) because `home.stateVersion` is less than "26.05".
                To silence this warning set:
                  programs.mergiraf.enableJujutsuIntegration = true;
              ''
            ];
    }

    (mkIf cfg.enable {
      home.packages = [ cfg.package ];
    })

    (mkIf (cfg.enable && cfg.enableGitIntegration) {
      programs = {
        git = {
          attributes = [ "* merge=mergiraf" ];
          settings = {
            merge = {
              mergiraf = {
                name = "mergiraf";
                driver = "${lib.getExe cfg.package} merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
              };
              conflictStyle = "diff3";
            };
          };
        };
      };
    })

    (mkIf (cfg.enable && cfg.enableJujutsuIntegration) {
      programs = {
        jujutsu = {
          settings = {
            ui = {
              # Rely on the built-in configuration
              merge-editor = "mergiraf";
            };
            # Explicitly set the path to the package
            merge-tools = {
              mergiraf = {
                program = lib.getExe cfg.package;
              };
            };
          };
        };
      };
    })
  ];
}
