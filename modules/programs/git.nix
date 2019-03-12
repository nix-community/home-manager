{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.git;

  # create [section "subsection"] keys from "section.subsection" attrset names
  mkSectionName = name:
    let
      containsQuote = strings.hasInfix ''"'' name;
      sections = splitString "." name;
      section = head sections;
      subsections = tail sections;
      subsection = concatStringsSep "." subsections;
    in
      if containsQuote || subsections == []
      then name
      else "${section} \"${subsection}\"";

  # generation for multiple ini values
  mkKeyValue = k: v:
    let
      mkKeyValue = generators.mkKeyValueDefault {} "=" k;
    in
      concatStringsSep "\n" (map mkKeyValue (toList v));

  # converts { a.b.c = 5; } to { "a.b".c = 5; } for toINI
  gitFlattenAttrs =
    let
      recurse = path: value:
        if isAttrs value then
          mapAttrsToList (name: value: recurse ([name] ++ path) value) value
        else if length path > 1 then
          { ${concatStringsSep "." (reverseList (tail path))}.${head path} = value; }
        else
          { ${head path} = value; };
    in
      attrs: foldl recursiveUpdate {} (flatten (recurse [] attrs));

  gitToIni = attrs:
    let
      toIni = generators.toINI { inherit mkKeyValue mkSectionName; };
    in
      toIni (gitFlattenAttrs attrs);

  gitIniType = with types;
    let
      primitiveType = either str (either bool int);
      multipleType = either primitiveType (listOf primitiveType);
      sectionType = attrsOf multipleType;
      supersectionType = attrsOf (either multipleType sectionType);
    in
      attrsOf supersectionType;

  signModule = types.submodule {
    options = {
      key = mkOption {
        type = types.str;
        description = "The default GPG signing key fingerprint.";
      };

      signByDefault = mkOption {
        type = types.bool;
        default = false;
        description = "Whether commits should be signed by default.";
      };

      gpgPath = mkOption {
        type = types.str;
        default = "${pkgs.gnupg}/bin/gpg2";
        defaultText = "\${pkgs.gnupg}/bin/gpg2";
        description = "Path to GnuPG binary to use.";
      };
    };
  };

  includeModule = types.submodule ({ config, ... }: {
    options = {
      condition = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Include this configuration only when <varname>condition</varname>
          matches. Allowed conditions are described in
          <citerefentry>
            <refentrytitle>git-config</refentrytitle>
            <manvolnum>1</manvolnum>
          </citerefentry>.
        '';
      };

      path = mkOption {
        type = with types; either str path;
        description = "Path of the configuration file to include.";
      };

      contents = mkOption {
        type = types.attrs;
        default = {};
        description = ''
          Configuration to include. If empty then a path must be given.
        '';
      };
    };

    config.path = mkIf (config.contents != {}) (
      mkDefault (pkgs.writeText "contents" (gitToIni config.contents))
    );
  });

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.git = {
      enable = mkEnableOption "Git";

      package = mkOption {
        type = types.package;
        default = pkgs.git;
        defaultText = "pkgs.git";
        description = ''
          Git package to install. Use <varname>pkgs.gitAndTools.gitFull</varname>
          to gain access to <command>git send-email</command> for instance.
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
        default = {};
        example = { co = "checkout"; };
        description = "Git aliases to define.";
      };

      signing = mkOption {
        type = types.nullOr signModule;
        default = null;
        description = "Options related to signing commits using GnuPG.";
      };

      extraConfig = mkOption {
        type = types.either types.lines gitIniType;
        default = {};
        example = {
          core = { whitespace = "trailing-space,space-before-tab"; };
          url."ssh://git@host".insteadOf = "otherhost";
        };
        description = "Additional configuration to add.";
      };

      iniContent = mkOption {
        type = gitIniType;
        internal = true;
      };

      ignores = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "*~" "*.swp" ];
        description = "List of paths that should be globally ignored.";
      };

      includes = mkOption {
        type = types.listOf includeModule;
        default = [];
        example = literalExample ''
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
            This requires a manual <command>git lfs pull</command>
            every time a new commit is checked out on your repository.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable (
    mkMerge [
      {
        home.packages = [ cfg.package ];

        programs.git.iniContent.user = {
          name = mkIf (cfg.userName != null) cfg.userName;
          email = mkIf (cfg.userEmail != null) cfg.userEmail;
        };

        xdg.configFile = {
          "git/config".text = gitToIni cfg.iniContent;

          "git/ignore" = mkIf (cfg.ignores != []) {
            text = concatStringsSep "\n" cfg.ignores + "\n";
          };
        };
      }

      {
        programs.git.iniContent =
          let
            hasSmtp = name: account: account.smtp != null;

            genIdentity = name: account: with account;
              nameValuePair "sendemail.${name}" ({
                smtpEncryption = if smtp.tls.enable then "tls" else "";
                smtpServer = smtp.host;
                smtpUser = userName;
                from = address;
              }
              // optionalAttrs (smtp.port != null) {
                smtpServerPort = smtp.port;
              });
          in
            mapAttrs' genIdentity
              (filterAttrs hasSmtp config.accounts.email.accounts);
      }

      (mkIf (cfg.signing != null) {
        programs.git.iniContent = {
          user.signingKey = cfg.signing.key;
          commit.gpgSign = cfg.signing.signByDefault;
          gpg.program = cfg.signing.gpgPath;
        };
      })

      (mkIf (cfg.aliases != {}) {
        programs.git.iniContent.alias = cfg.aliases;
      })

      (mkIf (lib.isAttrs cfg.extraConfig) {
        programs.git.iniContent = cfg.extraConfig;
      })

      (mkIf (lib.isString cfg.extraConfig) {
        xdg.configFile."git/config".text = cfg.extraConfig;
      })

      (mkIf (cfg.includes != []) {
        xdg.configFile."git/config".text =
          let
            include = i: with i;
              if condition != null
              then { includeIf.${condition}.path = "${path}"; }
              else { include.path = "${path}"; };
          in
            mkAfter
            (concatStringsSep "\n"
            (map gitToIni
            (map include cfg.includes)));
      })

      (mkIf cfg.lfs.enable {
        home.packages = [ pkgs.git-lfs ];

        programs.git.iniContent.filter.lfs =
          let
            skipArg = optional cfg.lfs.skipSmudge "--skip";
          in
            {
              clean = "git-lfs clean -- %f";
              process = concatStringsSep " " (
                [ "git-lfs" "filter-process" ] ++ skipArg
              );
              required = true;
              smudge = concatStringsSep " " (
                [ "git-lfs" "smudge" ] ++ skipArg ++ [ "--" "%f" ]
              );
            };
      })
    ]
  );
}
