{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.gradle;
  defaultHomeDirectory = ".gradle";
  settingsFormat = pkgs.formats.javaProperties { };

  initScript = types.submodule ({ name, config, ... }: {
    options = {
      text = mkOption {
        type = types.nullOr types.lines;
        default = null;
        description = ''
          Text of the init script file. if this option is null
          then `source` must be set.
        '';
      };

      source = mkOption {
        type = types.path;
        description = ''
          Path of the init script file. If
          `text` is non-null then this option will automatically point
          to a file containing that text.
        '';
      };
    };

    config.source = mkIf (config.text != null) (mkDefault (pkgs.writeTextFile {
      inherit (config) text;
      name = hm.strings.storeFileName name;
    }));
  });
in {
  meta.maintainers = [ hm.maintainers.britter ];

  options.programs.gradle = {
    enable = mkEnableOption "Gradle Build Tool";

    home = mkOption {
      type = types.str;
      default = defaultHomeDirectory;
      description = ''
        The Gradle home directory, relative to [](#opt-home.homeDirectory).

        If set, the {env}`GRADLE_USER_HOME` environment variable will be
        set accordingly. Defaults to {file}`.gradle`.
      '';
    };

    package = mkPackageOption pkgs "gradle" { example = "pkgs.gradle_7"; };

    settings = mkOption {
      type = types.submodule { freeformType = settingsFormat.type; };
      default = { };
      example = literalExpression ''
        {
          "org.gradle.caching" = true;
          "org.gradle.parallel" = true;
          "org.gradle.jvmargs" = "-XX:MaxMetaspaceSize=384m";
          "org.gradle.home" = pkgs.jdk17;
        };
      '';
      description = ''
        Key value pairs to write to {file}`gradle.properties` in the Gradle
        home directory.
      '';
    };

    initScripts = mkOption {
      type = with types; attrsOf initScript;
      default = { };
      example = literalExpression ''
        {
          "maven-local.gradle".text = '''
              allProject {
                repositories {
                  mavenLocal()
                }
              }
          ''';
          "another.init.gradle.kts".source = ./another.init.gradle.kts;
        }
      '';
      description = ''
        Definition of init scripts to link into the Gradle home directory.

        For more information about init scripts, including naming conventions
        see https://docs.gradle.org/current/userguide/init_scripts.html.
      '';
    };
  };

  config = let gradleHome = "${config.home.homeDirectory}/${cfg.home}";
  in mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file = mkMerge ([{
      "${cfg.home}/gradle.properties" = mkIf (cfg.settings != { }) {
        source = settingsFormat.generate "gradle.properties" cfg.settings;
      };
    }]
      ++ mapAttrsToList (k: v: { "${cfg.home}/init.d/${k}".source = v.source; })
      cfg.initScripts);

    home.sessionVariables = mkIf (cfg.home != defaultHomeDirectory) {
      GRADLE_USER_HOME = gradleHome;
    };
  };
}
