{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.fusuma;

  yamlFormat = pkgs.formats.yaml { };

  configJson = pkgs.writeText "config.json" (builtins.toJSON cfg.settings);

  configYamlRaw = pkgs.runCommand "config.yaml.raw" { } ''
    ${pkgs.remarshal}/bin/json2yaml -i ${configJson} -o $out;
  '';

  # convert keys into literal numbers where necessary,
  # fusuma does not support string type finger count.
  strToInt = pkgs.writers.writePython3 "str2int" {
    libraries = [ pkgs.python3Packages.pyyaml ];
  } ''
    import yaml
    from yaml import FullLoader


    def str2int(config):
        if type(config) is not dict:
            return

        for key in list(config):
            if type(config[key]) is dict and key.isdigit():
                t = config[key]
                del config[key]
                config[int(key)] = t
            else:
                str2int(config[key])


    if __name__ == '__main__':
        path = "${configYamlRaw}"
        with open(path) as f:
            config = yaml.load(f, Loader=FullLoader)
            str2int(config)
            print(yaml.dump(config))
  '';

  configYaml = pkgs.stdenv.mkDerivation {
    name = "config.yaml";
    buildCommand = ''
      ${strToInt} > $out
    '';
  };

  makeBinPath = packages:
    foldl (a: b: if a == "" then b else "${a}:${b}") ""
    (map (pkg: "${pkg}/bin") packages);

in {
  meta.maintainers = [ hm.maintainers.iosmanthus ];

  options.services.fusuma = {
    enable = mkEnableOption
      "the fusuma systemd service to automatically enable touchpad gesture";

    package = mkOption {
      type = types.package;
      default = pkgs.fusuma;
      defaultText = literalExpression "pkgs.fusuma";
      description = "Package providing {command}`fusuma`.";
    };

    settings = mkOption {
      type = yamlFormat.type;
      example = literalExpression ''
        {
          threshold = {
            swipe = 0.1;
          };
          interval = {
            swipe = 0.7;
          };
          swipe = {
            "3" = {
              left = {
                # GNOME: Switch to left workspace
                command = "xdotool key ctrl+alt+Right";
              };
            };
          };
        };
      '';
      description = ''
        YAML config that will override the default fusuma configuration.
      '';
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [ coreutils ];
      defaultText = literalExpression "pkgs.coreutils";
      example = literalExpression ''
        with pkgs; [ coreutils xdotool ];
      '';
      description = ''
        Extra packages needs to bring to the scope of fusuma service.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.fusuma" pkgs
        lib.platforms.linux)
    ];

    xdg.configFile."fusuma/config.yaml".source = configYaml;

    systemd.user.services.fusuma = {
      Unit = {
        Description = "Fusuma services";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Environment = with pkgs; "PATH=${makeBinPath cfg.extraPackages}";
        ExecStart =
          "${cfg.package}/bin/fusuma -c ${config.xdg.configHome}/fusuma/config.yaml";
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
