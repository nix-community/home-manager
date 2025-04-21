{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    literalExpression
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    mkOptionDefault
    mkPackageOption
    types
    ;

  cfg = config.programs.git;

  gitIniType =
    with types;
    let
      primitiveType = either str (either bool int);
      multipleType = either primitiveType (listOf primitiveType);
      sectionType = attrsOf multipleType;
      supersectionType = attrsOf (either multipleType sectionType);
    in
    attrsOf supersectionType;

  includeModule = types.submodule (
    { config, ... }:
    {
      options = {
        condition = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Include this configuration only when {var}`condition`
            matches. Allowed conditions are described in
            {manpage}`git-config(1)`.
          '';
        };

        path = mkOption {
          type = with types; either str path;
          description = "Path of the configuration file to include.";
        };

        contents = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          example = literalExpression ''
            {
              user = {
                email = "bob@work.example.com";
                name = "Bob Work";
                signingKey = "1A2B3C4D5E6F7G8H";
              };
              commit = {
                gpgSign = true;
              };
            };
          '';
          description = ''
            Configuration to include. If empty then a path must be given.

            This follows the configuration structure as described in
            {manpage}`git-config(1)`.
          '';
        };

        contentSuffix = mkOption {
          type = types.str;
          default = "gitconfig";
          description = ''
            Nix store name for the git configuration text file,
            when generating the configuration text from nix options.
          '';

        };
      };
      config.path = mkIf (config.contents != { }) (
        mkDefault (
          pkgs.writeText (lib.hm.strings.storeFileName config.contentSuffix) (
            lib.generators.toGitINI config.contents
          )
        )
      );
    }
  );

in
{
  meta.maintainers = with lib.maintainers; [
    khaneliman
    rycee
  ];

  options = {
    programs.git = {
      enable = mkEnableOption "Git";

      package = lib.mkPackageOption pkgs "git" {
        example = "pkgs.gitFull";
        extraDescription = ''
          Use {var}`pkgs.gitFull`
          to gain access to {command}`git send-email` for instance.
        '';
      };

      userName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Default user name to use.";
      };

      userEmail = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Default user email to use.";
      };

      aliases = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          co = "checkout";
        };
        description = "Git aliases to define.";
      };

      signing = {
        key = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            The default signing key fingerprint.

            Set to `null` to let the signer decide what signing key
            to use depending on commit’s author.
          '';
        };

        format = mkOption {
          type = types.nullOr (
            types.enum [
              "openpgp"
              "ssh"
              "x509"
            ]
          );
          defaultText = literalExpression ''
            "openpgp" for state version < 25.05,
            undefined for state version ≥ 25.05
          '';
          description = ''
            The signing method to use when signing commits and tags.
            Valid values are `openpgp` (OpenPGP/GnuPG), `ssh` (SSH), and `x509` (X.509 certificates).
          '';
        };

        signByDefault = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether commits and tags should be signed by default.";
        };

        signer = mkOption {
          type = types.nullOr types.str;
          description = "Path to signer binary to use.";
        };
      };

      extraConfig = mkOption {
        type = types.either types.lines gitIniType;
        default = { };
        example = {
          core = {
            whitespace = "trailing-space,space-before-tab";
          };
          url."ssh://git@host".insteadOf = "otherhost";
        };
        description = ''
          Additional configuration to add. The use of string values is
          deprecated and will be removed in the future.
        '';
      };

      hooks = mkOption {
        type = types.attrsOf types.path;
        default = { };
        example = literalExpression ''
          {
            pre-commit = ./pre-commit-script;
          }
        '';
        description = ''
          Configuration helper for Git hooks.
          See <https://git-scm.com/docs/githooks>
          for reference.
        '';
      };

      iniContent = mkOption {
        type = gitIniType;
        internal = true;
      };

      ignores = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "*~"
          "*.swp"
        ];
        description = "List of paths that should be globally ignored.";
      };

      attributes = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "*.pdf diff=pdf" ];
        description = "List of defining attributes set globally.";
      };

      includes = mkOption {
        type = types.listOf includeModule;
        default = [ ];
        example = literalExpression ''
          [
            { path = "~/path/to/config.inc"; }
            {
              path = "~/path/to/conditional.inc";
              condition = "gitdir:~/src/dir";
            }
          ]
        '';
        description = "List of configuration files to include.";
      };

      lfs = {
        enable = mkEnableOption "Git Large File Storage";

        skipSmudge = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Skip automatic downloading of objects on clone or pull.
            This requires a manual {command}`git lfs pull`
            every time a new commit is checked out on your repository.
          '';
        };
      };

      maintenance = {
        enable = mkEnableOption "" // {
          description = ''
            Enable the automatic {command}`git maintenance`.

            If you have SSH remotes, set {option}`programs.git.package` to a
            git version with SSH support (eg: `pkgs.gitFull`).

            See <https://git-scm.com/docs/git-maintenance>.
          '';
        };

        repositories = mkOption {
          type = with types; listOf str;
          default = [ ];
          description = ''
            Repositories on which {command}`git maintenance` should run.

            Should be a list of absolute paths.
          '';
        };

        timers = mkOption {
          type = types.attrsOf types.str;
          default = {
            hourly = "*-*-* 1..23:53:00";
            daily = "Tue..Sun *-*-* 0:53:00";
            weekly = "Mon 0:53:00";
          };
          description = ''
            Systemd timers to create for scheduled {command}`git maintenance`.

            Key is passed to `--schedule` argument in {command}`git maintenance run`
            and value is passed to `Timer.OnCalendar` in `systemd.user.timers`.
          '';
        };
      };

      diff-highlight = {
        enable = mkEnableOption "" // {
          description = ''
            Enable the contrib {command}`diff-highlight` syntax highlighter.
            See <https://github.com/git/git/blob/master/contrib/diff-highlight/README>,
          '';
        };

        pagerOpts = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [
            "--tabs=4"
            "-RFX"
          ];
          description = ''
            Arguments to be passed to {command}`less`.
          '';
        };
      };

      difftastic = {
        enable = mkEnableOption "" // {
          description = ''
            Enable the {command}`difftastic` syntax highlighter.
            See <https://github.com/Wilfred/difftastic>.
          '';
        };

        package = mkPackageOption pkgs "difftastic" { };

        enableAsDifftool = mkEnableOption "" // {
          description = ''
            Enable the {command}`difftastic` syntax highlighter as a git difftool.
            See <https://github.com/Wilfred/difftastic>.
          '';
        };

        background = mkOption {
          type = types.enum [
            "light"
            "dark"
          ];
          default = "light";
          example = "dark";
          description = ''
            Determines whether difftastic should use the lighter or darker colors
            for syntax highlighting.
          '';
        };

        color = mkOption {
          type = types.enum [
            "always"
            "auto"
            "never"
          ];
          default = "auto";
          example = "always";
          description = ''
            Determines when difftastic should color its output.
          '';
        };

        display = mkOption {
          type = types.enum [
            "side-by-side"
            "side-by-side-show-both"
            "inline"
          ];
          default = "side-by-side";
          example = "inline";
          description = ''
            Determines how the output displays - in one column or two columns.
          '';
        };
      };

      delta = {
        enable = mkEnableOption "" // {
          description = ''
            Whether to enable the {command}`delta` syntax highlighter.
            See <https://github.com/dandavison/delta>.
          '';
        };

        package = mkPackageOption pkgs "delta" { };

        options = mkOption {
          type =
            with types;
            let
              primitiveType = either str (either bool int);
              sectionType = attrsOf primitiveType;
            in
            attrsOf (either primitiveType sectionType);
          default = { };
          example = {
            features = "decorations";
            whitespace-error-style = "22 reverse";
            decorations = {
              commit-decoration-style = "bold yellow box ul";
              file-style = "bold yellow ul";
              file-decoration-style = "none";
            };
          };
          description = ''
            Options to configure delta.
          '';
        };
      };

      diff-so-fancy = {
        enable = mkEnableOption "" // {
          description = ''
            Enable the {command}`diff-so-fancy` diff colorizer.
            See <https://github.com/so-fancy/diff-so-fancy>.
          '';
        };

        pagerOpts = mkOption {
          type = types.listOf types.str;
          default = [
            "--tabs=4"
            "-RFX"
          ];
          description = ''
            Arguments to be passed to {command}`less`.
          '';
        };

        markEmptyLines = mkOption {
          type = types.bool;
          default = true;
          example = false;
          description = ''
            Whether the first block of an empty line should be colored.
          '';
        };

        changeHunkIndicators = mkOption {
          type = types.bool;
          default = true;
          example = false;
          description = ''
            Simplify git header chunks to a more human readable format.
          '';
        };

        stripLeadingSymbols = mkOption {
          type = types.bool;
          default = true;
          example = false;
          description = ''
            Whether the `+` or `-` at
            line-start should be removed.
          '';
        };

        useUnicodeRuler = mkOption {
          type = types.bool;
          default = true;
          example = false;
          description = ''
            By default, the separator for the file header uses Unicode
            line-drawing characters. If this is causing output errors on
            your terminal, set this to false to use ASCII characters instead.
          '';
        };

        rulerWidth = mkOption {
          type = types.nullOr types.int;
          default = null;
          example = false;
          description = ''
            By default, the separator for the file header spans the full
            width of the terminal. Use this setting to set the width of
            the file header manually.
          '';
        };
      };

      riff = {
        enable = mkEnableOption "" // {
          description = ''
            Enable the <command>riff</command> diff highlighter.
            See <link xlink:href="https://github.com/walles/riff" />.
          '';
        };

        package = mkPackageOption pkgs "riffdiff" { };

        commandLineOptions = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = literalExpression ''[ "--no-adds-only-special" ]'';
          apply = lib.concatStringsSep " ";
          description = ''
            Command line arguments to include in the <command>RIFF</command> environment variable.

            Run <command>riff --help</command> for a full list of options
          '';
        };
      };
    };
  };

  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "git" "signing" "gpgPath" ]
      [
        "programs"
        "git"
        "signing"
        "signer"
      ]
    )
  ];

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [ cfg.package ];

        assertions = [
          {
            assertion =
              let
                enabled = [
                  cfg.delta.enable
                  cfg.diff-so-fancy.enable
                  cfg.difftastic.enable
                  cfg.diff-highlight.enable
                  cfg.riff.enable
                ];
              in
              lib.count lib.id enabled <= 1;
            message = "Only one of 'programs.git.delta.enable' or 'programs.git.difftastic.enable' or 'programs.git.diff-so-fancy.enable' or 'programs.git.diff-highlight' can be set to true at the same time.";
          }
        ];

        programs.git.iniContent.user = {
          name = mkIf (cfg.userName != null) cfg.userName;
          email = mkIf (cfg.userEmail != null) cfg.userEmail;
        };

        xdg.configFile = {
          "git/config".text = lib.generators.toGitINI cfg.iniContent;

          "git/ignore" = mkIf (cfg.ignores != [ ]) {
            text = concatStringsSep "\n" cfg.ignores + "\n";
          };

          "git/attributes" = mkIf (cfg.attributes != [ ]) {
            text = concatStringsSep "\n" cfg.attributes + "\n";
          };
        };
      }

      {
        programs.git.iniContent =
          let
            hasSmtp = name: account: account.smtp != null;

            genIdentity =
              name: account:
              let
                inherit (account)
                  address
                  realName
                  smtp
                  userName
                  ;
              in
              lib.nameValuePair "sendemail.${name}" (
                if account.msmtp.enable then
                  {
                    sendmailCmd = "${pkgs.msmtp}/bin/msmtp";
                    envelopeSender = "auto";
                    from = "${realName} <${address}>";
                  }
                else
                  {
                    smtpEncryption =
                      if smtp.tls.enable then
                        (if smtp.tls.useStartTls || lib.versionOlder config.home.stateVersion "20.09" then "tls" else "ssl")
                      else
                        "";
                    smtpSslCertPath = mkIf smtp.tls.enable (toString smtp.tls.certificatesFile);
                    smtpServer = smtp.host;
                    smtpUser = userName;
                    from = "${realName} <${address}>";
                  }
                  // lib.optionalAttrs (smtp.port != null) {
                    smtpServerPort = smtp.port;
                  }
              );
          in
          lib.mapAttrs' genIdentity (lib.filterAttrs hasSmtp config.accounts.email.accounts);
      }

      (mkIf (cfg.signing != { }) {
        programs.git = {
          signing = {
            format =
              if (lib.versionOlder config.home.stateVersion "25.05") then
                (mkOptionDefault "openpgp")
              else
                (mkOptionDefault null);
            signer =
              let
                defaultSigners = {
                  openpgp = lib.getExe config.programs.gpg.package;
                  ssh = lib.getExe' pkgs.openssh "ssh-keygen";
                  x509 = lib.getExe' config.programs.gpg.package "gpgsm";
                };
              in
              mkIf (cfg.signing.format != null) (mkOptionDefault defaultSigners.${cfg.signing.format});
          };

          iniContent = lib.mkMerge [
            (mkIf (cfg.signing.key != null) {
              user.signingKey = mkDefault cfg.signing.key;
            })
            (mkIf (cfg.signing.signByDefault != null) {
              commit.gpgSign = mkDefault cfg.signing.signByDefault;
              tag.gpgSign = mkDefault cfg.signing.signByDefault;
            })
            (mkIf (cfg.signing.format != null) {
              gpg = {
                format = mkDefault cfg.signing.format;
                ${cfg.signing.format}.program = mkDefault cfg.signing.signer;
              };
            })
          ];
        };
      })

      (mkIf (cfg.hooks != { }) {
        programs.git.iniContent = {
          core.hooksPath =
            let
              entries = lib.mapAttrsToList (name: path: { inherit name path; }) cfg.hooks;
            in
            toString (pkgs.linkFarm "git-hooks" entries);
        };
      })

      (mkIf (cfg.aliases != { }) { programs.git.iniContent.alias = cfg.aliases; })

      (mkIf (lib.isAttrs cfg.extraConfig) {
        programs.git.iniContent = cfg.extraConfig;
      })

      (mkIf (lib.isString cfg.extraConfig) {
        warnings = [
          ''
            Using programs.git.extraConfig as a string option is
            deprecated and will be removed in the future. Please
            change to using it as an attribute set instead.
          ''
        ];

        xdg.configFile."git/config".text = cfg.extraConfig;
      })

      (mkIf (cfg.includes != [ ]) {
        xdg.configFile."git/config".text =
          let
            include =
              i:
              with i;
              if condition != null then
                {
                  includeIf.${condition}.path = "${path}";
                }
              else
                {
                  include.path = "${path}";
                };
          in
          lib.mkAfter (concatStringsSep "\n" (map lib.generators.toGitINI (map include cfg.includes)));
      })

      (mkIf cfg.lfs.enable {
        home.packages = [ pkgs.git-lfs ];

        programs.git.iniContent.filter.lfs =
          let
            skipArg = lib.optional cfg.lfs.skipSmudge "--skip";
          in
          {
            clean = "git-lfs clean -- %f";
            process = concatStringsSep " " (
              [
                "git-lfs"
                "filter-process"
              ]
              ++ skipArg
            );
            required = true;
            smudge = concatStringsSep " " (
              [
                "git-lfs"
                "smudge"
              ]
              ++ skipArg
              ++ [
                "--"
                "%f"
              ]
            );
          };
      })

      (mkIf cfg.maintenance.enable {
        programs.git.iniContent.maintenance.repo = cfg.maintenance.repositories;

        systemd.user.services."git-maintenance@" = {
          Unit = {
            Description = "Optimize Git repositories data";
            Documentation = [ "man:git-maintenance(1)" ];
          };

          Service = {
            Type = "oneshot";
            ExecStart =
              let
                exe = lib.getExe cfg.package;
              in
              ''
                "${exe}" for-each-repo --keep-going --config=maintenance.repo maintenance run --schedule=%i
              '';
            LockPersonality = "yes";
            MemoryDenyWriteExecute = "yes";
            NoNewPrivileges = "yes";
            RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6 AF_VSOCK";
            RestrictNamespaces = "yes";
            RestrictRealtime = "yes";
            RestrictSUIDSGID = "yes";
            SystemCallArchitectures = "native";
            SystemCallFilter = "@system-service";
          };
        };

        systemd.user.timers =
          let
            toSystemdTimer =
              name: time:
              lib.attrsets.nameValuePair "git-maintenance@${name}" {
                Unit.Description = "Optimize Git repositories data";

                Timer = {
                  OnCalendar = time;
                  Persistent = true;
                };

                Install.WantedBy = [ "timers.target" ];
              };
          in
          lib.attrsets.mapAttrs' toSystemdTimer cfg.maintenance.timers;

        launchd.agents =
          let
            baseArguments = [
              "${lib.getExe cfg.package}"
              "for-each-repo"
              "--keep-going"
              "--config=maintenance.repo"
              "maintenance"
              "run"
            ];
          in
          {
            "git-maintenance-hourly" = {
              enable = true;
              config = {
                ProgramArguments = baseArguments ++ [ "--schedule=hourly" ];
                StartCalendarInterval = map (hour: {
                  Hour = hour;
                  Minute = 53;
                }) (lib.range 1 23);
              };
            };
            "git-maintenance-daily" = {
              enable = true;
              config = {
                ProgramArguments = baseArguments ++ [ "--schedule=daily" ];
                StartCalendarInterval = map (weekday: {
                  Weekday = weekday;
                  Hour = 0;
                  Minute = 53;
                }) (lib.range 1 6);
              };
            };
            "git-maintenance-weekly" = {
              enable = true;
              config = {
                ProgramArguments = baseArguments ++ [ "--schedule=weekly" ];
                StartCalendarInterval = [
                  {
                    Weekday = 0;
                    Hour = 0;
                    Minute = 53;
                  }
                ];
              };
            };
          };
      })

      (mkIf cfg.diff-highlight.enable {
        programs.git.iniContent =
          let
            dhCommand = "${cfg.package}/share/git/contrib/diff-highlight/diff-highlight";
          in
          {
            core.pager = "${dhCommand} | ${lib.getExe pkgs.less} ${lib.escapeShellArgs cfg.diff-highlight.pagerOpts}";
            interactive.diffFilter = dhCommand;
          };
      })

      (
        let
          difftCommand = concatStringsSep " " [
            "${lib.getExe cfg.difftastic.package}"
            "--color ${cfg.difftastic.color}"
            "--background ${cfg.difftastic.background}"
            "--display ${cfg.difftastic.display}"
          ];
        in
        (lib.mkMerge [
          (mkIf cfg.difftastic.enable {
            home.packages = [ cfg.difftastic.package ];
            programs.git.iniContent = {
              diff.external = difftCommand;
            };
          })
          (mkIf cfg.difftastic.enableAsDifftool {
            home.packages = [ cfg.difftastic.package ];
            programs.git.iniContent = {
              diff = {
                tool = lib.mkDefault "difftastic";
              };
              difftool = {
                difftastic = {
                  cmd = "${difftCommand} $LOCAL $REMOTE";
                };
              };
            };
          })
        ])
      )

      (
        let
          deltaPackage = cfg.delta.package;
          deltaCommand = "${deltaPackage}/bin/delta";
        in
        mkIf cfg.delta.enable {
          home.packages = [ deltaPackage ];

          programs.git.iniContent = {
            core.pager = deltaCommand;
            interactive.diffFilter = "${deltaCommand} --color-only";
            delta = cfg.delta.options;
          };
        }
      )

      (mkIf cfg.diff-so-fancy.enable {
        home.packages = [ pkgs.diff-so-fancy ];

        programs.git.iniContent =
          let
            dsfCommand = "${pkgs.diff-so-fancy}/bin/diff-so-fancy";
          in
          {
            core.pager = "${dsfCommand} | ${pkgs.less}/bin/less ${lib.escapeShellArgs cfg.diff-so-fancy.pagerOpts}";
            interactive.diffFilter = "${dsfCommand} --patch";
            diff-so-fancy = {
              markEmptyLines = cfg.diff-so-fancy.markEmptyLines;
              changeHunkIndicators = cfg.diff-so-fancy.changeHunkIndicators;
              stripLeadingSymbols = cfg.diff-so-fancy.stripLeadingSymbols;
              useUnicodeRuler = cfg.diff-so-fancy.useUnicodeRuler;
              rulerWidth = mkIf (cfg.diff-so-fancy.rulerWidth != null) (cfg.diff-so-fancy.rulerWidth);
            };
          };
      })

      (
        let
          riffExe = baseNameOf (lib.getExe cfg.riff.package);
        in
        mkIf cfg.riff.enable {
          home.packages = [ cfg.riff.package ];

          # https://github.com/walles/riff/blob/b17e6f17ce807c8652bc59cd46758661d23ce358/README.md#usage
          programs.git.iniContent = {
            pager = {
              diff = riffExe;
              log = riffExe;
              show = riffExe;
            };

            interactive.diffFilter = "${riffExe} --color=on";
          };
        }
      )

      (mkIf (cfg.riff.enable && cfg.riff.commandLineOptions != "") {
        home.sessionVariables.RIFF = cfg.riff.commandLineOptions;
      })
    ]
  );
}
