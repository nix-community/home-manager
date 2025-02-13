{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    nmt.script = let
      dir = if (pkgs.stdenv.isDarwin && !config.xdg.enable) then
        "home-files/Library/Preferences/aerc"
      else
        "home-files/.config/aerc";
    in ''
      assertFileContent   ${dir}/accounts.conf     ${./extraAccounts.expected}
      assertFileContent   ${dir}/binds.conf        ${./extraBinds.expected}
      assertFileContent   ${dir}/aerc.conf         ${./extraConfig.expected}
      assertFileContent   ${dir}/templates/bar     ${./templates.expected}
      assertFileContent   ${dir}/templates/foo     ${./templates.expected}
      assertFileContent   ${dir}/stylesets/default ${./stylesets.expected}
      assertFileContent   ${dir}/stylesets/asLines ${./stylesets.expected}
    '';

    programs.aerc = {
      enable = true;

      extraAccounts = {
        Test1 = {
          source = "maildir:///dev/null";
          enable-folders-sort = true;
          folders = [ "INBOX" "SENT" "JUNK" ];
        };
        Test2 = { pgp-key-id = 42; };
      };

      extraBinds = {
        global = {
          "<C-p>" = ":prev-tab<Enter>";
          "<C-n>" = ":next-tab<Enter>";
          "<C-t>" = ":term<Enter>";
        };
        messages = {
          q = ":quit<Enter>";
          j = ":next<Enter>";
        };
        "compose::editor" = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
          "<C-k>" = ":prev-field<Enter>";
        };
      };

      extraConfig = {
        general.unsafe-accounts-conf = true;
        ui = {
          index-format = null;
          sort = "-r date";
          spinner = [ true 2 3.4 "5" ];
          sidebar-width = 42;
          mouse-enabled = false;
          test-float = 1337.42;
        };
        "ui:account=Test" = { sidebar-width = 1337; };
      };

      stylesets = {
        asLines = ''
          *.default = true
          *.selected.reverse = toggle
          *error.bold = true
          error.fg = red
          header.bold = true
          title.reverse = true
        '';
        default = {
          "*.default" = "true";
          "*error.bold" = "true";
          "error.fg" = "red";
          "header.bold" = "true";
          "*.selected.reverse" = "toggle";
          "title.reverse" = "true";
        };
      };

      templates = rec {
        foo = ''
          X-Mailer: aerc {{version}}

          Just a test.
        '';
        bar = foo;
      };
    };

    accounts.email.accounts = let
      basics = {
        aerc = { enable = true; };
        realName = "Foo Bar";
        auth.userName = "foobar";
        address = "addr@mail.invalid";
        folders = {
          drafts = "";
          inbox = "";
          sent = "";
          trash = "";
        };
      };
    in {
      primary = recursiveUpdate basics {
        primary = true;
        imap = {
          host = "imap.host.invalid";
          port = 1337;
          tls.enable = true;
          tls.useStartTls = true;
        };
      };
      a_imap-nopasscmd-tls-starttls-folders = recursiveUpdate basics {
        imap = {
          host = "imap.host.invalid";
          port = 1337;
          tls.enable = true;
          tls.useStartTls = true;
        };
        folders = {
          drafts = "aercDrafts";
          inbox = "aercInbox";
          sent = "aercSent";
        };
      };
      b_imap-passcmd-tls-nostarttls-extraAccounts = recursiveUpdate basics {
        auth.passwordCommand = "echo PaSsWorD!";
        imap = {
          host = "imap.host.invalid";
          port = 1337;
          tls.enable = true;
          tls.useStartTls = false;
        };
        aerc = {
          enable = true;
          extraAccounts = { connection-timeout = "42s"; };
        };
      };
      c_imap-passcmd-notls-nostarttls-extraConfig = recursiveUpdate basics {
        auth.passwordCommand = "echo PaSsWorD!";
        aerc = {
          enable = true;
          extraConfig = { ui.index-format = "%42.1337n"; };
        };
        imap = {
          host = "imap.host.invalid";
          port = 1337;
          tls.enable = false;
          tls.useStartTls = false;
        };
      };
      d_imap-passcmd-notls-starttls-extraBinds = recursiveUpdate basics {
        auth.passwordCommand = "echo PaSsWorD!";
        imap = {
          host = "imap.host.invalid";
          port = 1337;
          tls.enable = false;
          tls.useStartTls = true;
        };
        aerc = {
          enable = true;
          extraBinds = { messages = { d = ":move Trash<Enter>"; }; };
        };
      };
      e_smtp-nopasscmd-tls-starttls = recursiveUpdate basics {
        smtp = {
          host = "smtp.host.invalid";
          port = 42;
          tls.enable = true;
          tls.useStartTls = true;
        };
      };
      f_smtp-passcmd-tls-nostarttls = recursiveUpdate basics {
        auth.passwordCommand = "echo PaSsWorD!";
        smtp = {
          host = "smtp.host.invalid";
          port = 42;
          tls.enable = true;
          tls.useStartTls = false;
        };
      };
      g_smtp-passcmd-notls-nostarttls = recursiveUpdate basics {
        auth.passwordCommand = "echo PaSsWorD!";
        smtp = {
          host = "smtp.host.invalid";
          port = 42;
          tls.enable = false;
          tls.useStartTls = false;
        };
      };
      h_smtp-passcmd-notls-starttls = recursiveUpdate basics {
        auth.passwordCommand = "echo PaSsWorD!";
        smtp = {
          host = "smtp.host.invalid";
          port = 42;
          tls.enable = false;
          tls.useStartTls = true;
        };
      };
      i1_maildir-mbsync = recursiveUpdate basics { mbsync.enable = true; };
      i2_maildirpp-mbsync = recursiveUpdate basics {
        mbsync.enable = true;
        mbsync.subFolders = "Maildir++";
      };
      i3_maildir_flatten-mbsync = recursiveUpdate basics {
        mbsync.enable = true;
        mbsync.subFolders = "Maildir++";
        mbsync.flatten = ".";
      };
      j_maildir-offlineimap =
        recursiveUpdate basics { offlineimap.enable = true; };
      k_notEnabled = recursiveUpdate basics { aerc.enable = false; };
      l_smtp-auth-none = recursiveUpdate basics {
        smtp = {
          host = "smtp.host.invalid";
          port = 42;
        };
        aerc = {
          enable = true;
          smtpAuth = "none";
        };
      };
      m_smtp-auth-plain = recursiveUpdate basics {
        smtp = {
          host = "smtp.host.invalid";
          port = 42;
        };
        aerc = {
          enable = true;
          smtpAuth = "plain";
        };
      };
      n_smtp-auth-login = recursiveUpdate basics {
        smtp = {
          host = "smtp.host.invalid";
          port = 42;
        };
        aerc = {
          enable = true;
          smtpAuth = "login";
        };
      };
      o_msmtp = recursiveUpdate basics { msmtp = { enable = true; }; };
      p_overwrite_defaults = recursiveUpdate basics {
        smtp.host = "should.be.overwritten.invalid";
        imap.host = "should.be.overwritten.invalid";
        aerc = {
          enable = true;
          extraAccounts = {
            from = "test <test@email.invalid>";
            outgoing =
              "imap+plain://intentionallyWrong:PaSsWorD@smtp.host.invalid:1337";
            source =
              "smtp+plain://intentionallyWrong:PaSsWorD@smtp.host.invalid:1337";
            postpone = "dRaFts";
          };
        };
      };
    };
  };
}
