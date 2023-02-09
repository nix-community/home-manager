{ config, lib, pkgs, ... }:

let
  inherit (lib)
    types literalExpression isStorePath nameValuePair makeSearchPath;
  inherit (lib.attrsets) mapAttrs';
  inherit (lib.options) mkEnableOption mkPackageOption mkOption;
  inherit (lib.modules) mkIf;

  cfg = config.services.pipewire;

  instanceOpts = with types;
    submodule {
      options = {
        config = mkOption {
          type = either path str;
          default = null;
          example = literalExpression "./compressor.conf";
          description = ''
            Configuration file for the PipeWire instance. See <citerefentry>
            <refentrytitle>pipewire.conf</refentrytitle><manvolnum>5</manvolnum>
            </citerefentry>
          '';
        };
        extraPackages = mkOption {
          type = listOf package;
          default = [ ];
          example = literalExpression "[ pkgs.calf ]";
          description = "Extra packages available to this PipeWire instance.";
        };
      };
    };
in {
  options.services.pipewire = with types; {
    enable = mkEnableOption "pipewire-instances";

    package = mkPackageOption pkgs "pipewire" { };

    instances = mkOption {
      type = attrsOf (instanceOpts);
      default = { };
      example = literalExpression ''
        {
          compressor = {
            config = ./compressor.conf;
            extraPackages = [ pkgs.calf ];
          };
        }
      '';
      description = "Definition of PipeWire instances";
    };
  };
  config = let
    mkPipeWireInstance = name: instance:
      let
        fullName = "pipewire-instance-${name}";
        pwConfig =
          if builtins.isPath instance.config || isStorePath instance.config then
            instance.config
          else
            pkgs.writeText "${fullName}.conf" instance.config;
      in nameValuePair fullName {
        Unit = {
          Description = "PipeWire instance ${name}";
          After = "pipewire.service";
          BindsTo = "pipewire.service";
        };
        Service = {
          Environment = let
            # pipewire-filter-chain allows loading LADSPA and LV2 filters, add them to the search path here
            extraPackages = instance.extraPackages ++ [ cfg.package ];
            bins = makeSearchPath "bin" extraPackages;
            libs = makeSearchPath "lib" extraPackages;
            ladspaLibs = makeSearchPath "lib/ladspa" extraPackages;
            lv2Libs = makeSearchPath "lib/lv2" extraPackages;
          in [
            "PATH=${bins}"
            "LD_LIBRARY_PATH=${libs}"
            "LADSPA_PATH=${ladspaLibs}"
            "LV2_PATH=${lv2Libs}"
          ];
          ExecStart = ''
            ${cfg.package}/bin/pipewire -c ${pwConfig}
          '';
        };
        Install.WantedBy = [ "pipewire.service" ];
      };
  in mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.pipewire" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services = mapAttrs' mkPipeWireInstance cfg.instances;
  };
}
