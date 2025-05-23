{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    optional
    optionalAttrs
    nameValuePair
    mapAttrs'
    filterAttrs
    attrNames
    concatStringsSep
    toLower
    listToAttrs
    getExe
    ;
  cfg = config.programs.lutris;
  settingsFormat = pkgs.formats.yaml { };
in
{
  options.programs.lutris = {
    enable = mkEnableOption "lutris.";
    package = lib.mkPackageOption pkgs "lutris" { };
    steamPackage = mkOption {
      default = null;
      example = "pkgs.steam or osConfig.programs.steam.package";
      description = ''
        This must be the same you use for your system, or two instances will conflict,
        for example, if you configure steam through the nixos module, a good value is "osConfig.programs.steam.package"
      '';
      type = types.nullOr types.package;
    };
    extraPackages = mkOption {
      default = [ ];
      example = "with pkgs; [mangohud winetricks gamescope gamemode umu-launcher]";
      description = ''
        List of packages to pass as extraPkgs to lutris.
        Please note runners are not detected properly this way, use a proper option for those.
      '';
      type = types.listOf types.package;
    };
    protonPackages = mkOption {
      default = [ ];
      example = "[ pkgs.proton-ge-bin ]";
      description = ''
        List of proton packages to be added for lutris to use with umu-launcher.
      '';
      type = types.listOf types.package;
    };
    winePackages = mkOption {
      default = [ ];
      example = "[ pkgs.wineWow64Packages.full ]";
      description = ''
        List of wine packages to be added for lutris to use.
      '';
      type = types.listOf types.package;
    };
    runners = mkOption {
      default = { };
      example = ''
        runners = {
          cemu.package = pkgs.cemu;
          pcsx2.config = {
            system.disable_screen_saver = true;
            runner.runner_executable = "$\{pkgs.pcsx2}/bin/pcsx2-qt";
          };
        };
      '';
      description = ''
        Attribute set of Lutris runners along with their configurations.
        Each runner must be named exactly as lutris expects on `lutris --list-runners`.
        Note that runners added here won't be configurable through Lutris using the GUI.
      '';
      type = types.attrsOf (
        types.submodule {
          options = {
            package = mkOption {
              default = null;
              example = "pkgs.cemu";
              description = ''
                The package to use for this runner, nix will try to find the executable for this package.
                A more specific path can be set by using settings.runner.runner_executable instead.
              '';
              type = types.nullOr types.package;
            };
            settings = mkOption {
              default = { };
              description = ''
                Settings passed directly to lutris for this runner's config at XDG_CONFIG/lutris/runners.
              '';
              type = types.submodule {
                options = {
                  runner = mkOption {
                    default = { };
                    description = ''
                      Runner specific options.
                      For references, you must look for the file of said runner on lutris' source code.
                    '';
                    type = types.submodule {
                      freeformType = settingsFormat.type;
                      options = {
                        runner_executable = mkOption {
                          type = types.either types.str types.path;
                          default = "";
                          description = ''
                            Specific option to point to a runner executable directly, don't set runner.package if you set this.
                          '';
                        };
                      };
                    };
                  };
                  system = mkOption {
                    default = { };
                    description = ''
                      Lutris system options for this runner.
                      Reference for system options:
                      https://github.com/lutris/lutris/blob/master/lutris/sysoptions.py#L78
                    '';
                    type = types.submodule { freeformType = settingsFormat.type; };
                  };
                };
              };
            };
          };
        }
      );
    };
  };
  meta.maintainers = [ lib.hm.maintainers.bikku ];
  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.lutris" pkgs lib.platforms.linux)
    ];
    warnings =
      let
        redundantRunners = attrNames (
          filterAttrs (
            _: runner_config:
            runner_config.package != null && runner_config.settings.runner.runner_executable != ""
          ) cfg.runners
        );
      in
      mkIf (redundantRunners != [ ]) [
        ''
          Under programs.lutris.runners, the following lutris runners had both a
          <runner>.package and <runner>.settings.runner.runner_executable options set:
            - ${concatStringsSep ", " redundantRunners}
          Note that runner_executable overrides package, setting both is pointless.
        ''
      ];
    home.packages =
      let
        lutris-overrides = {
          # This only adds pkgs.steam to the extraPkgs, I see no reason to ever enable it.
          steamSupport = false;
          extraPkgs = (prev: cfg.extraPackages ++ optional (cfg.steamPackage != null) cfg.steamPackage);
        };
      in
      [ (cfg.package.override lutris-overrides) ];

    xdg.configFile =
      let
        buildRunnerConfig = (
          runner_name: runner_config:
          {
            "${runner_name}" =
              (optionalAttrs (runner_config.settings.runner != { }) runner_config.settings.runner)
              // (optionalAttrs
                (runner_config.package != null && runner_config.settings.runner.runner_executable == "")
                {
                  runner_executable = getExe runner_config.package;
                }
              );
          }
          // optionalAttrs (runner_config.settings.system != { }) {
            system = runner_config.settings.system;
          }
        );
      in
      mapAttrs' (
        runner_name: runner_config:
        nameValuePair "lutris/runners/${runner_name}.yml" {
          source = settingsFormat.generate "${runner_name}.yml" (buildRunnerConfig runner_name runner_config);
        }
      ) cfg.runners;

    xdg.dataFile =
      let
        buildWineLink =
          type: packages:
          map (
            # lutris seems to not detect wine/proton if the name has some caps
            package:
            (nameValuePair "lutris/runners/${type}/${toLower package.name}" {
              source = package;
            })
          ) packages;
        steamcompattools = map (proton: proton.steamcompattool) cfg.protonPackages;
      in
      listToAttrs (buildWineLink "wine" cfg.winePackages ++ buildWineLink "proton" steamcompattools);
  };
}
