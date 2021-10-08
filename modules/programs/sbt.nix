{ config, lib, pkgs, ... }:

with lib;

let

  renderPlugin = plugin: ''
    addSbtPlugin("${plugin.org}" % "${plugin.artifact}" % "${plugin.version}")
  '';

  renderCredential = cred: ''
    credentials += Credentials("${cred.realm}", "${cred.host}", "${cred.user}", "${cred.passwordCommand}".lazyLines.mkString("\n"))
  '';

  renderCredentials = creds: ''
    import scala.sys.process._
    ${concatStrings (map renderCredential creds)}'';

  sbtTypes = {
    plugin = types.submodule {
      options = {
        org = mkOption {
          type = types.str;
          description = "The organization the artifact is published under.";
        };

        artifact = mkOption {
          type = types.str;
          description = "The name of the artifact.";
        };

        version = mkOption {
          type = types.str;
          description = "The version of the plugin.";
        };
      };
    };

    credential = types.submodule {
      options = {
        realm = mkOption {
          type = types.str;
          description = "The realm of the repository you're authenticating to.";
        };

        host = mkOption {
          type = types.str;
          description =
            "The hostname of the repository you're authenticating to.";
        };

        user = mkOption {
          type = types.str;
          description = "The user you're using to authenticate.";
        };

        passwordCommand = mkOption {
          type = types.str;
          description = ''
            The command that provides the password or authentication token for
            the repository.
          '';
        };
      };
    };
  };

  cfg = config.programs.sbt;

in {
  meta.maintainers = [ maintainers.kubukoz ];

  options.programs.sbt = {
    enable = mkEnableOption "sbt";

    package = mkOption {
      type = types.package;
      default = pkgs.sbt;
      defaultText = literalExpression "pkgs.sbt";
      description = "The package with sbt to be installed.";
    };

    baseConfigPath = mkOption {
      type = types.str;
      default = ".sbt/1.0";
      description = "Where the plugins and credentials should be located.";
    };

    plugins = mkOption {
      type = types.listOf (sbtTypes.plugin);
      default = [ ];
      example = literalExpression ''
        [
          {
            org = "net.virtual-void";
            artifact = "sbt-dependency-graph";
            version = "0.10.0-RC1";
          }
          {
            org = "com.dwijnand";
            artifact = "sbt-project-graph";
            version = "0.4.0";
          }
        ]
      '';
      description = ''
        A list of plugins to place in the sbt configuration directory.
      '';
    };

    credentials = mkOption {
      type = types.listOf (sbtTypes.credential);
      default = [ ];
      example = literalExpression ''
        [{
          realm = "Sonatype Nexus Repository Manager";
          host = "example.com";
          user = "user";
          passwordCommand = "pass show sbt/user@example.com";
        }]
      '';
      description = ''
        A list of credentials to define in the sbt configuration directory.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    { home.packages = [ cfg.package ]; }

    (mkIf (cfg.plugins != [ ]) {
      home.file."${cfg.baseConfigPath}/plugins/plugins.sbt".text =
        concatStrings (map renderPlugin cfg.plugins);
    })

    (mkIf (cfg.credentials != [ ]) {
      home.file."${cfg.baseConfigPath}/credentials.sbt".text =
        renderCredentials cfg.credentials;
    })
  ]);
}
