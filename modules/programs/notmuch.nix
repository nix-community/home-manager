{ config, lib, pkgs, ... }:

with lib;

let

  dag = config.lib.dag;

  cfg = config.programs.notmuch;

  mkIniKeyValue = key: value:
    let
      tweakVal = v:
        if isString v then v
        else if isList v then concatMapStringsSep ";" tweakVal v
        else if isBool v then toJSON v
        else toString v;
    in
      "${key}=${tweakVal value}";

  notmuchIni =
    recursiveUpdate
      {
        database = {
          path = config.accounts.email.maildirBasePath;
        };
    
        new = {
          ignore = cfg.new.ignore;
          tags = cfg.new.tags;
        };
    
        user =
          let
            accounts =
              filter (a: a.notmuch.enable)
              (attrValues config.accounts.email.accounts);
            primary = filter (a: a.primary) accounts;
            secondaries = filter (a: !a.primary) accounts;
          in {
            name = catAttrs "realName" primary;
            primary_email = catAttrs "address" primary;
            other_email = catAttrs "address" secondaries;
          };
    
        search = {
          exclude_tags = [ "deleted" "spam" ];
        };
      }
      cfg.extraConfig;

in

{
  options = {
    programs.notmuch = {
      enable = mkEnableOption "Notmuch mail indexer";

      new = mkOption {
        type = types.submodule {
          options = {
            ignore = mkOption {
              type = types.listOf types.str;
              default = [];
              description = ''
                A list to specify files and directories that will not be
                searched for messages by <command>notmuch new</command>.
              '';
            };

            tags = mkOption {
              type = types.listOf types.str;
              default = [ "unread" "inbox" ];
              example = [ "new" ];
              description = ''
                A list of tags that will be added to all messages
                incorporated by <command>notmuch new</command>.
              '';
            };
          };
        };
        default = {};
        description = ''
          Options related to email processing performed by
          <command>notmuch new</command>.
        '';
      };

      contactCompletion = mkOption {
        type = types.enum [ "address" "simple" ];
        default = "address";
        apply = val:

          if val == "address" then ''
            ${pkgs.bash}/bin/bash -c "${pkgs.notmuch}/bin/notmuch  address --format=json --output=recipients  date:1Y.."'
            regexp = '\[?{"name": "(?P<name>.*)", "address": "(?P<email>.+)", "name-addr": ".*"}[,\]]?' ''
          else if val == "config" then
            "'${pkgs.notmuch}/bin/notmuch address --format=json date:1Y..'"
          else "";

        description = ''
          A list of tags that will be added to all messages
          incorporated by <command>notmuch new</command>.
        '';
      };

      extraConfig = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = {
          maildir = { synchronize_flags = "True"; };
        };
        description = ''
          Options that should be appended to the notmuch configuration file.
        '';
      };

      hooks = {
        preNew = mkOption {
          type = types.lines;
          default = "";
          example = "mbsync --all";
          description = ''
            Bash statements run before scanning or importing new
            messages into the database.
          '';
        };

        postNew = mkOption {
          type = types.lines;
          default = "";
          example = ''
            notmuch tag +nixos -- tag:new and from:nixos1@discoursemail.com
          '';
          description = ''
            Bash statements run after new messages have been imported
            into the database and initial tags have been applied.
          '';
        };

        postInsert = mkOption {
          type = types.lines;
          default = "";
          description = ''
            Bash statements run after a message has been inserted
            into the database and initial tags have been applied.
          '';
        };
      };
    };

    accounts.email.accounts = mkOption {
      options = [
        {
          notmuch = {
            enable = mkEnableOption "notmuch indexing";
          };
        }
      ];
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = notmuchIni.user.name != [];
        message = "notmuch: Must have a user name set.";
      }
      {
        assertion = notmuchIni.user.primary_email != [];
        message = "notmuch: Must have a user primary email address set.";
      }
    ];

    home.packages = [ pkgs.notmuch ];

    home.sessionVariables = {
      NOTMUCH_CONFIG = "${config.xdg.configHome}/notmuch/notmuchrc";
      NMBGIT = "${config.xdg.dataHome}/notmuch/nmbug";
    };

    xdg.configFile."notmuch/notmuchrc".text =
      let
        toIni = generators.toINI { mkKeyValue = mkIniKeyValue; };
      in
        "# Generated by Home Manager.\n\n"
        + toIni notmuchIni;

    home.file =
      let
        hook = name: cmds:
          {
            target = "${notmuchIni.database.path}/.notmuch/hooks/${name}";
            source = pkgs.writeScript name ''
              #!${pkgs.stdenv.shell}

              export PATH="${pkgs.notmuch}/bin''${PATH:+:}$PATH"
              export NOTMUCH_CONFIG="${config.xdg.configHome}/notmuch/notmuchrc"
              export NMBGIT="${config.xdg.dataHome}/notmuch/nmbug"
    
              ${cmds}
            '';
            executable = true;
          };
      in
        optional (cfg.hooks.preNew != "")
          (hook "pre-new" cfg.hooks.preNew)
        ++
        optional (cfg.hooks.postNew != "")
          (hook "post-new" cfg.hooks.postNew)
        ++
        optional (cfg.hooks.postInsert != "")
          (hook "post-insert" cfg.hooks.postInsert);
  };
}
