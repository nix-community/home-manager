{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.hexchat;

  channelOptions = with types;
    submodule {
      options = {
        autoconnect = mkOption {
          type = nullOr bool;
          default = false;
          description = "Autoconnect to network.";
        };

        connectToSelectedServerOnly = mkOption {
          type = nullOr bool;
          default = true;
          description = "Connect to selected server only.";
        };

        bypassProxy = mkOption {
          type = nullOr bool;
          default = true;
          description = "Bypass proxy.";
        };

        forceSSL = mkOption {
          type = nullOr bool;
          default = false;
          description = "Use SSL for all servers.";
        };

        acceptInvalidSSLCertificates = mkOption {
          type = nullOr bool;
          default = false;
          description = "Accept invalid SSL certificates.";
        };

        useGlobalUserInformation = mkOption {
          type = nullOr bool;
          default = false;
          description = "Use global user information.";
        };
      };
    };

  modChannelOption = with types;
    submodule {
      options = {
        autojoin = mkOption {
          type = listOf str;
          default = [ ];
          example = [ "#home-manager" "#linux" "#nix" ];
          description = "Channels list to autojoin on connecting to server.";
        };

        charset = mkOption {
          type = nullOr str;
          default = null;
          example = "UTF-8 (Unicode)";
          description = "Character set.";
        };

        commands = mkOption {
          type = listOf str;
          default = [ ];
          example = literalExpression ''[ "ECHO Greetings fellow Nixer! ]'';
          description = "Commands to be executed on connecting to server.";
        };

        loginMethod = mkOption {
          type = nullOr (enum (attrNames loginMethodMap));
          default = null;
          description = ''
            The login method. The allowed options are:
            <variablelist>
              <varlistentry>
                <term><literal>null</literal></term>
                <listitem><para>Default</para></listitem>
              </varlistentry>
              <varlistentry>
                <term><literal>"nickServMsg"</literal></term>
                <listitem><para>NickServ (/MSG NickServ + password)</para></listitem>
              </varlistentry>
              <varlistentry>
                <term><literal>"nickServ"</literal></term>
                <listitem><para>NickServ (/NICKSERV + password)</para></listitem>
              </varlistentry>
              <varlistentry>
                <term><literal>"challengeAuth"</literal></term>
                <listitem><para>Challenge Auth (username + password)</para></listitem>
              </varlistentry>
              <varlistentry>
                <term><literal>"sasl"</literal></term>
                <listitem><para>SASL (username + password)</para></listitem>
              </varlistentry>
              <varlistentry>
                <term><literal>"serverPassword"</literal></term>
                <listitem><para>Server password (/PASS password)</para></listitem>
              </varlistentry>
              <varlistentry>
                <term><literal>"saslExternal"</literal></term>
                <listitem><para>SASL EXTERNAL (cert)</para></listitem>
              </varlistentry>
              <varlistentry>
                <term><literal>"customCommands"</literal></term>
                <listitem>
                  <para>Use "commands" field for auth. For example
                  <programlisting language="nix">
            commands = [ "/msg NickServ IDENTIFY my_password" ]
            </programlisting>
                  </para>
                </listitem>
              </varlistentry>
            </variablelist>
          '';
        };

        nickname = mkOption {
          type = nullOr str;
          default = null;
          description = "Primary nickname.";
        };

        nickname2 = mkOption {
          type = nullOr str;
          default = null;
          description = "Secondary nickname.";
        };

        options = mkOption {
          type = nullOr channelOptions;
          default = null;
          example = {
            autoconnect = true;
            useGlobalUserInformation = true;
          };
          description = "Channel options.";
        };

        password = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            Password to use. Note this password will be readable by all user's
            in the Nix store.
          '';
        };

        realName = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            Real name. Is used to populate the real name field that appears when
            someone uses the <literal>WHOIS</literal> command on your nick.
          '';
        };

        userName = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            User name. Part of your <literal>user@host</literal> hostmask that
            appears to other on IRC.
          '';
        };

        servers = mkOption {
          type = listOf str;
          default = [ ];
          example = [ "chat.freenode.net" "irc.freenode.net" ];
          description = "IRC Server Address List.";
        };
      };
    };

  transformField = k: v: if (v != null) then "${k}=${v}" else null;

  listChar = c: l:
    if l != [ ] then concatMapStringsSep "\n" (transformField c) l else null;

  computeFieldsValue = channel:
    let
      ifTrue = p: n: if p then n else 0;
      result = with channel.options;
        foldl' (a: b: a + b) 0 [
          (ifTrue (!connectToSelectedServerOnly) 1)
          (ifTrue useGlobalUserInformation 2)
          (ifTrue forceSSL 4)
          (ifTrue autoconnect 8)
          (ifTrue (!bypassProxy) 16)
          (ifTrue acceptInvalidSSLCertificates 32)
        ];
    in toString (if channel.options == null then 0 else result);

  loginMethodMap = {
    nickServMsg = 1;
    nickServ = 2;
    challengeAuth = 4;
    sasl = 6;
    serverPassword = 7;
    customCommands = 9;
    saslExternal = 10;
  };

  loginMethod = channel:
    transformField "L" (optionalString (channel.loginMethod != null)
      (toString loginMethodMap.${channel.loginMethod}));

  # Note: Missing option `D=`.
  transformChannel = channelName:
    let channel = cfg.channels.${channelName};
    in concatStringsSep "\n" (filter (v: v != null) [
      "" # leave a space between one server and another
      (transformField "N" channelName)
      (loginMethod channel)
      (transformField "E" channel.charset)
      (transformField "F" (computeFieldsValue channel))
      (transformField "I" channel.nickname)
      (transformField "i" channel.nickname2)
      (transformField "R" channel.realName)
      (transformField "U" channel.userName)
      (transformField "P" channel.password)
      (listChar "S" channel.servers)
      (listChar "J" channel.autojoin)
      (listChar "C" channel.commands)
    ]);

in {
  meta.maintainers = with maintainers; [ superherointj thiagokokada ];

  options.programs.hexchat = with types; {
    enable = mkEnableOption "HexChat, a graphical IRC client";

    channels = mkOption {
      type = attrsOf modChannelOption;
      default = { };
      example = literalExpression ''
        {
          freenode = {
            autojoin = [
              "#home-manager"
              "#linux"
              "#nixos"
            ];
            charset = "UTF-8 (Unicode)";
            commands = [
              "ECHO Buzz Lightyear sent you a message: 'To Infinity... and Beyond!'"
            ];
            loginMethod = sasl;
            nickname = "my_nickname";
            nickname2 = "my_secondchoice";
            options = {
              acceptInvalidSSLCertificates = false;
              autoconnect = true;
              bypassProxy = true;
              connectToSelectedServerOnly = true;
              useGlobalUserInformation = false;
              forceSSL = false;
            };
            password = "my_password";
            realName = "my_realname";
            servers = [
              "chat.freenode.net"
              "irc.freenode.net"
            ];
            userName = "my_username";
          };
        }'';
      description = ''
        Configures <filename>~/.config/hexchat/servlist.conf</filename>.
      '';
    };

    settings = mkOption {
      default = null;
      type = nullOr (attrsOf str);
      example = literalExpression ''
        {
          irc_nick1 = "mynick";
          irc_username = "bob";
          irc_realname = "Bart Simpson";
          text_font = "Monospace 14";
        };
      '';
      description = ''
        Configuration for <filename>~/.config/hexchat/hexchat.conf</filename>, see
        <link xlink:href="https://hexchat.readthedocs.io/en/latest/settings.html#list-of-settings"/>
        for supported values.
      '';
    };

    overwriteConfigFiles = mkOption {
      type = nullOr bool;
      default = false;
      description = ''
        Enables overwriting HexChat configuration files
        (<filename>hexchat.conf</filename>, <filename>servlist.conf</filename>).
        Any existing HexChat configuration will be lost. Certify to back-up any
        previous configuration before enabling this.
        </para><para>
        Enabling this setting is recommended, because everytime HexChat
        application is closed it overwrites Nix/Home Manager provided
        configuration files, causing:
        <orderedlist numeration="arabic">
          <listitem><para>
            Nix/Home Manager provided configuration to be out of sync with
            actual active HexChat configuration.
          </para></listitem>
          <listitem><para>
            Blocking Nix/Home Manager updates until configuration files are
            manually removed.
          </para></listitem>
        </orderedlist>
      '';
    };

    theme = mkOption {
      type = nullOr package;
      default = null;
      example = literalExpression ''
        source = pkgs.fetchzip {
          url = "https://dl.hexchat.net/themes/Monokai.hct#Monokai.zip";
          sha256 = "sha256-WCdgEr8PwKSZvBMs0fN7E2gOjNM0c2DscZGSKSmdID0=";
          stripRoot = false;
        };
      '';
      description = ''
        Theme package for HexChat. Expects a derivation containing decompressed
        theme files. Note, <literal>.hct</literal> files are actually ZIP files,
        as seen in example.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "programs.hexchat" pkgs platforms.linux)
    ];

    home.packages = [ pkgs.hexchat ];

    xdg.configFile."hexchat" = mkIf (cfg.theme != null) {
      source = cfg.theme;
      recursive = true;
    };

    xdg.configFile."hexchat/hexchat.conf" = mkIf (cfg.settings != null) {
      force = cfg.overwriteConfigFiles;
      text = concatMapStringsSep "\n" (x: x + " = " + cfg.settings.${x})
        (attrNames cfg.settings);
    };

    xdg.configFile."hexchat/servlist.conf" = mkIf (cfg.channels != { }) {
      force = cfg.overwriteConfigFiles;
      # Final line breaks is required to avoid cropping last field value.
      text = concatMapStringsSep "\n" transformChannel (attrNames cfg.channels)
        + "\n\n";
    };
  };
}
