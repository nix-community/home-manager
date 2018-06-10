{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.neomutt;

  sidebarModule = types.submodule ({ config, ...}: {
    options = {
      enable = mkEnableOption "sidebar support";

      width = mkOption {
        type = types.int;
        default = 22;
        description = "Width of the sidebar";
      };

      shortPath = mkOption {
        type = types.bool;
        default = true;
        description = ''
          By default sidebar shows the full path of the mailbox, but with this
          enabled only the relative name is shown.
        '';
      };

      format = mkOption {
        type = types.string;
        default = "%B%?F? [%F]?%* %?N?%N/?%S";
        description = "Sidebar format. Check neomutt documentation for details.";
      };
    };
  });

  bindModule = types.submodule ({ config, ...}: {
    options = {
      map = mkOption {
        type = types.enum [
          "alias"
          "attach"
          "browser"
          "compose"
          "editor"
          "generic"
          "index"
          "mix"
          "pager"
          "pgp"
          "postpone"
          "query"
          "smime"
        ];
        default = "index";
        description = "Select the menu to bind the command to.";
      };

      key = mkOption {
        type = types.string;
        example = "<left>";
        description = "The key to bind.";
      };

      action = mkOption {
        type = types.string;
        example = "<enter-command>toggle sidebar_visible<enter><refresh>";
        description = "Specify the action to take.";
      };
    };
  });

  imapModule = types.submodule ({ config, ...}: {
    options = {
      enable = mkEnableOption "the IMAP support";

      user = mkOption {
        type = types.string;
        default = "";
        description = "IMAP username.";
      };

      password = mkOption {
        type = types.nullOr types.string;
        default = null;
        example = "`${pkgs.gnupg}/bin/gpg --decrypt passfile.gpg`";
        description = ''
          IMAP password. Because these configuration files are kept in the nix
          store unencrypted, it is recommended to use some kind of a password
          command.
        '';
      };

      idle = mkOption {
        type = types.bool;
        default = false;
        description = "If set, neomutt will attempt to use the IDLE extension.";
      };

      url = mkOption {
        type = types.string;
        default = "";
        example = "mail.gmail.com";
        description = "IMAP address without the <literal>imaps://</literal>.";
      };
    };
  });

  smtpModule = types.submodule ({ config, ...}: {
    options = {
      enable = mkEnableOption "the SMTP support";

      user = mkOption {
        type = types.string;
        default = "";
        description = "SMTP username.";
      };

      password = mkOption {
        type = types.nullOr types.string;
        default = null;
        example = "`${pkgs.gnupg}/bin/gpg --decrypt passfile.gpg`";
        description = ''
          SMTP password. Because these configuration files are kept in the nix
          store unencrypted, I recommend using some kind of a password command.
        '';
      };

      url = mkOption {
        type = types.string;
        default = "";
        example = "smtp.gmail.com";
        description = "SMTP address without the <literal>smtps://</literal>.";
      };
    };
  });

in

{
  options = {
    programs.neomutt = {
      enable = mkEnableOption "the neomutt mail client";

      from = mkOption {
        type = types.string;
        default = "John Doe <john.doe@example.com>";
        description = "The 'From:' address.";
      };

      imap = mkOption {
        type = imapModule;
        default = {};
        description = "IMAP configuration.";
      };

      smtp = mkOption {
        type = smtpModule;
        default = {};
        description = "SMTP configuration.";
      };

      spool = mkOption {
        type = types.string;
        default = "~/Mail/";
        example = "INBOX";
        description = ''
          Mutt spool directory (maildir). When using IMAP, this will be
          appended to the end.
        '';
      };

      folder = mkOption {
        type = types.nullOr types.string;
        default = null;
        example = "imap.gmail.com";
        description = ''
          Default location for your mailboxes. If null it is derived from your
          spoolfile and imap.
        '';
      };

      gpg = mkOption {
        type = types.bool;
        default = false;
        description = "Enable gpg support.";
      };

      sidebar = mkOption {
        type = sidebarModule;
        default = {};
        description = "Options related to the sidebar.";
      };

      binds = mkOption {
        type = types.listOf bindModule;
        default = [];
        description = "List of keybindings.";
      };

      macros = mkOption {
        # I'm sharing the definition of bind, because the fields are pretty
        # much the same
        type = types.listOf bindModule;
        default = [];
        description = "List of macros.";
      };

      sort = mkOption {
        type = types.enum [
          "date"
          "date-received"
          "from"
          "mailbox-order"
          "score"
          "size"
          "spam"
          "subject"
          "threads"
          "to"
        ];
        default = "threads";
        description = "Sorting method on messages.";
      };

      mailboxes = mkOption {
        type = types.listOf types.string;
        default = [];
        example = ["+github" "+Lists/nix" "+Lists/haskell-cafe"];
        description = ''
          A list of mailboxes. If you prepend the path with
          <literal>+</literal> the path will be considered to be after the
          current folder.
        '';
      };

      checkStatsInterval = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 60;
        description = "Enable and set the interval of automatic mail check.";
      };

      editor = mkOption {
        type = types.string;
        default = "$EDITOR";
        example = "${pkgs.nano}/bin/nano";
        description = "Select the editor used for writing mail.";
      };

      theme = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to theme file. Warning this can contain any muttrc
          configuration, including system calls.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration appended to the end.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.neomutt ];
    xdg.configFile."neomutt/muttrc".text =
      let
        yesno = x: if x then "yes" else "no";
        gpgSection = ''
          set crypt_use_gpgme = yes
          set crypt_autosign = yes
          set pgp_use_gpg_agent = yes
        '';
        sidebarSection = ''
          # Sidebar
          set sidebar_visible = yes
          set sidebar_short_path = ${yesno cfg.sidebar.shortPath}
          set sidebar_width = ${toString cfg.sidebar.width}
          set sidebar_format = '${cfg.sidebar.format}'
        '';
        spoolSection = ''
          set spoolfile = "${cfg.spool}"
          set folder = "${if cfg.folder != null then cfg.folder else cfg.spool}"
        '';
        imapSection = ''
          set spoolfile = "imaps://${cfg.imap.url}/${cfg.spool}";
          set folder = "${if cfg.folder != null then cfg.folder else "imaps://${cfg.imap.url}"}"
          set imap_user = "${cfg.imap.user}"
          ${optionalString (cfg.imap.password != null) "set imap_pass = \"${cfg.imap.password}\""}
          set imap_idle = ${yesno cfg.imap.idle}
        '';
        # Have been verified to work with gmail, but this is a bit finicky section
        smtpSection = ''
          set smtp_url = smtps://${cfg.smtp.user}@${cfg.smtp.url}:465
          ${optionalString (cfg.smtp.password != null) "set smtp_pass = \"${cfg.smtp.password}\""}
        '';
        bindSection = concatStringsSep "\n" (map (bind: "bind ${bind.map} ${bind.key} \"${bind.action}\"") cfg.binds);
        macroSection = concatStringsSep "\n" (map (bind: "macro ${bind.map} ${bind.key} \"${bind.action}\"") cfg.macros);
        mailboxesSection = concatStringsSep "\n" (map (mbox: "mailboxes ${mbox}") cfg.mailboxes);
        mailCheckSection = ''
          set mail_check_stats
          set mail_check_stats_interval = ${toString cfg.checkStatsInterval}
        '';

      in

      # Some defaults are left unconfigurable
      ''
        set from = "${cfg.from}"
        set mbox_type = Maildir
        set sort = "${cfg.sort}"

        set editor = "${cfg.editor}"

        ${if cfg.imap.enable then imapSection else spoolSection}
        ${optionalString cfg.smtp.enable smtpSection}

        ${optionalString cfg.gpg gpgSection}

        ${optionalString (cfg.checkStatsInterval != null) mailCheckSection}

        set implicit_autoview = yes

        alternative_order text/enriched text/plain text

        set header_cache = "${config.xdg.cacheHome}/neomutt/cache/"
        set message_cachedir = "${config.xdg.cacheHome}/neomutt/message_cache/"

        set delete = yes

        # Binds and macros
        ${bindSection}
        ${macroSection}

        ${optionalString cfg.sidebar.enable sidebarSection}

        ${optionalString (cfg.theme != null) "source ${cfg.theme}"}

        ${mailboxesSection}

        # Extra configuration
        ${cfg.extraConfig}
      '';
  };
}
