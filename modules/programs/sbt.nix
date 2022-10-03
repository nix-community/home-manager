{ config, lib, pkgs, ... }:

with lib;

let

  renderPlugin = plugin: ''
    addSbtPlugin("${plugin.org}" % "${plugin.artifact}" % "${plugin.version}")
  '';

  renderCredential = cred: ''
    credentials += Credentials("${cred.realm}", "${cred.host}", "${cred.user}", "${cred.passwordCommand}".!!.trim)
  '';

  renderCredentials = creds: ''
    import scala.sys.process._
    ${concatStrings (map renderCredential creds)}'';

  renderRepository = value:
    if isString value then ''
      ${value}
    '' else ''
      ${concatStrings (mapAttrsToList (name: value: "${name}: ${value}") value)}
    '';

  renderRepositories = repos: ''
    [repositories]
    ${concatStrings (map renderRepository cfg.repositories)}'';

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
  imports = [
    (mkRemovedOptionModule [ "programs" "sbt" "baseConfigPath" ]
      "Use programs.sbt.baseUserConfigPath instead, but note that the semantics are slightly different.")
  ];

  meta.maintainers = [ maintainers.kubukoz ];

  options.programs.sbt = {
    enable = mkEnableOption "sbt";

    package = mkOption {
      type = types.package;
      default = pkgs.sbt;
      defaultText = literalExpression "pkgs.sbt";
      description = "The package with sbt to be installed.";
    };

    baseUserConfigPath = mkOption {
      type = types.str;
      default = ".sbt";
      description = ''
        Where the sbt configuration files should be located, relative
        <envar>HOME</envar>.
      '';
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

    repositories = mkOption {
      type = with types;
        listOf
        (either (enum [ "local" "maven-central" "maven-local" ]) (attrsOf str));
      default = [ ];
      example = literalExpression ''
        [
          "local"
          { my-ivy-proxy-releases = "http://repo.company.com/ivy-releases/, [organization]/[module]/(scala_[scalaVersion]/)(sbt_[sbtVersion]/)[revision]/[type]s/[artifact](-[classifier]).[ext]" }
          { my-maven-proxy-releases = "http://repo.company.com/maven-releases/" }
          "maven-central"
        ]
      '';
      description = ''
        A list of repositories to use when resolving dependencies. Defined as a
        list of pre-defined repository or custom repository as a set of name to
        URL. The list will be used populate the <code>~/.sbt/repositories</code>
        file in the order specified.

        </para><para>

        Pre-defined repositories must be one of <code>local</code>,
        <code>maven-local</code>, <code>maven-central</code>.

        </para><para>

        Custom repositories are defined as
        <code language="nix">{ name-of-repo = "https://url.to.repo.com"}</code>.

        </para><para>

        See
        <link xlink:href="https://www.scala-sbt.org/1.x/docs/Launcher-Configuration.html#3.+Repositories+Section"/>
        about this configuration section and
        <link xlink:href="https://www.scala-sbt.org/1.x/docs/Proxy-Repositories.html"/>
        to read about proxy repositories.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    { home.packages = [ cfg.package ]; }

    (mkIf (cfg.plugins != [ ]) {
      home.file."${cfg.baseUserConfigPath}/1.0/plugins/plugins.sbt".text =
        concatStrings (map renderPlugin cfg.plugins);
    })

    (mkIf (cfg.credentials != [ ]) {
      home.file."${cfg.baseUserConfigPath}/1.0/credentials.sbt".text =
        renderCredentials cfg.credentials;
    })

    (mkIf (cfg.repositories != [ ]) {
      home.file."${cfg.baseUserConfigPath}/repositories".text =
        renderRepositories cfg.repositories;
    })
  ]);
}
