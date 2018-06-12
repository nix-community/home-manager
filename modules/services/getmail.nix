{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.getmail;

  retrieverModule = types.submodule ({config,...}: {
    options = {
      type = mkOption {
        type = types.enum [
          "SimplePOP3Retriever"
          "SimplePOP3SSLRetriever"
          "SimpleIMAPRetriever"
          "SimpleIMAPSSLRetriever"
        ];
        default = "SimpleIMAPSSLRetriever";
        description = "Type of the retriever.";
      };

      server = mkOption {
        type = types.string;
        default = "";
        description = "The remote server.";
      };

      username = mkOption {
        type = types.string;
        default = "";
        description = "The server username.";
      };

      password = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = ''
          The server password. Note that the passwords are stored clear in the
          nix store, so it is recommended to not use this field, but instead
          either leave empty or use <literal>passwordCommand</literal> instead.
        '';
      };

      passwordCommand = mkOption {
        type = types.nullOr (types.listOf types.string);
        default = null;
        example = ["${pkgs.gnupg}/bin/gpg" "--decrypt" "file.gpg"];
        description = ''
          The server password. With this the password is retrieved with the
          given command. The list value is given escaped to the implementation.
        '';
      };

      mailboxes = mkOption {
        type = types.listOf types.string;
        default = [];
        description = "A list of mailboxes";
      };
    };
  });

  destinationModule = types.submodule ({config,...}: {
    options = {
      type = mkOption {
        type = types.enum [
          "MDA_external"
          "Maildir"
        ];
        default = "Maildir";
        description = "Destination type.";
      };

      path = mkOption {
        type = types.string;
        default = "$HOME/Mail";
        example = "${pkgs.procmail}/bin/procmail";
        description = ''
          The destination path. For <literal>Maildir</literal> it's the file
          path and for <literal>MDA_external</literal> it's the destination
          application.
        '';
      };
    };
  });

  optionsModule = types.submodule ({config,...}: {
    options = {
      delete = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable if you want to delete read messages from the server. Most
          users should either enable <literal>delete</literal> or disable
          <literal>readAll</literal>.
        '';
      };

      readAll = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable if you want to fetch all, even the read messages from the
          server. Most users should either enable <literal>delete</literal> or
          disable <literal>readAll</literal>.
        '';
      };
    };
  });

in

{
  options = {
    programs.getmail = {
      enable = mkEnableOption "Enable getmail";

      retriever = mkOption {
        type = retrieverModule;
        default = {};
        description = "The server section.";
      };

      destination = mkOption {
        type = destinationModule;
        default = {};
        description = "The destination section.";
      };

      options = mkOption {
        type = optionsModule;
        default = {};
        description = "The options section.";
      };

      frequency = mkOption {
        type = types.string;
        default = "*:0/15";
        example = "hourly";
        description = ''
          The refresh frequency. Check <literal>man systemd.time</literal> for
          more information on the syntax.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.file.".getmail/getmailrc".text =
    let
      quoted = x: "\"${escape ["\""] x}\"";

      passwordCommand = concatStringsSep ", " (map quoted cfg.retriever.passwordCommand);

      password = if cfg.retriever.passwordCommand != null
        then "password_command = (${passwordCommand})"
        else optionalString (cfg.retriever.password != null) "password = \"${quoted cfg.retriever.password}\"";
      mailboxInner = concatStringsSep ", " (
        map quoted cfg.retriever.mailboxes);

      mailboxes = "(${mailboxInner})";

      in

    ''
      [retriever]
      type = ${cfg.retriever.type}
      server = ${cfg.retriever.server}
      username = ${cfg.retriever.username}
      ${password}
      mailboxes = ${mailboxes}

      [destination]
      type = ${cfg.destination.type}
      path = ${cfg.destination.path}

      [options]
      delete = ${toString cfg.options.delete}
      read_all = ${toString cfg.options.readAll}
    '';

    systemd.user.services.getmail = {
      Unit = {
        Description = "getmail email fetcher";
        PartOf = ["network-online.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.getmail}/bin/getmail";
      };
    };

    systemd.user.timers.getmail = {
      Unit = {
        Description = "getmail email fetcher";
      };
      Timer = {
        OnCalendar = "${cfg.frequency}";
        Unit = "getmail.service";
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
