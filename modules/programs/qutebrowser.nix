{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.qutebrowser;

  formatLine = o: n: v:
    let
      formatValue = v:
        if builtins.isNull v then
          "None"
        else if builtins.isBool v then
          (if v then "True" else "False")
        else if builtins.isString v then
          ''"${v}"''
        else if builtins.isList v then
          "[${concatStringsSep ", " (map formatValue v)}]"
        else
          builtins.toString v;
    in if builtins.isAttrs v then
      concatStringsSep "\n" (mapAttrsToList (formatLine "${o}${n}.") v)
    else
      "${o}${n} = ${formatValue v}";

  formatDictLine = o: n: v: ''${o}['${n}'] = "${v}"'';

  formatKeyBindings = m: b:
    let
      formatKeyBinding = m: k: c:
        ''config.bind("${k}", "${escape [ ''"'' ] c}", mode="${m}")'';
    in concatStringsSep "\n" (mapAttrsToList (formatKeyBinding m) b);

in {
  options.programs.qutebrowser = {
    enable = mkEnableOption "qutebrowser";

    package = mkOption {
      type = types.package;
      default = pkgs.qutebrowser;
      defaultText = literalExample "pkgs.qutebrowser";
      description = "Qutebrowser package to install.";
    };

    aliases = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Aliases for commands.
      '';
    };

    loadAutoconfig = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Load settings configured via the GUI.
      '';
    };

    searchEngines = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Search engines that can be used via the address bar. Maps a search
        engine name (such as <literal>DEFAULT</literal>, or
        <literal>ddg</literal>) to a URL with a <literal>{}</literal>
        placeholder. The placeholder will be replaced by the search term, use
        <literal>{{</literal> and <literal>}}</literal> for literal
        <literal>{/}</literal> signs. The search engine named
        <literal>DEFAULT</literal> is used when
        <literal>url.auto_search</literal> is turned on and something else than
        a URL was entered to be opened. Other search engines can be used by
        prepending the search engine name to the search term, for example
        <literal>:open google qutebrowser</literal>.
      '';
      example = literalExample ''
        {
          w = "https://en.wikipedia.org/wiki/Special:Search?search={}&go=Go&ns0=1";
          aw = "https://wiki.archlinux.org/?search={}";
          nw = "https://nixos.wiki/index.php?search={}";
          g = "https://www.google.com/search?hl=en&q={}";
        }
      '';
    };

    settings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = ''
        Options to add to qutebrowser <filename>config.py</filename> file.
        See <link xlink:href="https://qutebrowser.org/doc/help/settings.html"/>
        for options.
      '';
      example = literalExample ''
        {
          colors = {
            hints = {
              bg = "#000000";
              fg = "#ffffff";
            };
            tabs.bar.bg = "#000000";
          };
          tabs.tabs_are_windows = true;
        }
      '';
    };

    keyMappings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        This setting can be used to map keys to other keys. When the key used
        as dictionary-key is pressed, the binding for the key used as
        dictionary-value is invoked instead. This is useful for global
        remappings of keys, for example to map Ctrl-[ to Escape. Note that when
        a key is bound (via <literal>bindings.default</literal> or
        <literal>bindings.commands</literal>), the mapping is ignored.
      '';
    };

    enableDefaultBindings = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Disable to prevent loading default key bindings.
      '';
    };

    keyBindings = mkOption {
      type = types.attrsOf (types.attrsOf types.str);
      default = { };
      description = ''
        Key bindings mapping keys to commands in different modes. This setting
        is a dictionary containing mode names and dictionaries mapping keys to
        commands: <literal>{mode: {key: command}}</literal> If you want to map
        a key to another key, check the <literal>keyMappings</literal> setting
        instead. For modifiers, you can use either <literal>-</literal> or
        <literal>+</literal> as delimiters, and these names:

        <itemizedlist>
          <listitem><para>
            Control: <literal>Control</literal>, <literal>Ctrl</literal>
          </para></listitem>
          <listitem><para>
            Meta: <literal>Meta</literal>, <literal>Windows</literal>,
            <literal>Mod4</literal>
          </para></listitem>
          <listitem><para>
            Alt: <literal>Alt</literal>, <literal>Mod1</literal>
          </para></listitem>
          <listitem><para>
            Shift: <literal>Shift</literal>
          </para></listitem>
        </itemizedlist>

        For simple keys (no <literal>&lt;&gt;</literal>-signs), a capital
        letter means the key is pressed with Shift. For special keys (with
        <literal>&lt;&gt;</literal>-signs), you need to explicitly add
        <literal>Shift-</literal> to match a key pressed with shift. If you
        want a binding to do nothing, bind it to the <literal>nop</literal>
        command. If you want a default binding to be passed through to the
        website, bind it to null. Note that some commands which are only useful
        for bindings (but not used interactively) are hidden from the command
        completion. See <literal>:</literal>help for a full list of available
        commands. The following modes are available:

        <variablelist>
          <varlistentry>
            <term><literal>normal</literal></term>
            <listitem><para>
              Default mode, where most commands are invoked.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>insert</literal></term>
            <listitem><para>
              Entered when an input field is focused on a website, or by
              pressing i in normal mode. Passes through almost all keypresses
              to the website, but has some bindings like
              <literal>&lt;Ctrl-e&gt;</literal> to open an external editor.
              Note that single keys can’t be bound in this mode.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>hint</literal></term>
            <listitem><para>
              Entered when f is pressed to select links with the keyboard. Note
              that single keys can’t be bound in this mode.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>passthrough</literal></term>
            <listitem><para>
              Similar to insert mode, but passes through all keypresses except
              <literal>&lt;Escape&gt;</literal> to leave the mode. It might be
              useful to bind <literal>&lt;Escape&gt;</literal> to some other
              key in this mode if you want to be able to send an Escape key to
              the website as well. Note that single keys can’t be bound in this
              mode.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>command</literal></term>
            <listitem><para>
              Entered when pressing the : key in order to enter a command. Note
              that single keys can’t be bound in this mode.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>prompt</literal></term>
            <listitem><para>
              Entered when there’s a prompt to display, like for download
              locations or when invoked from JavaScript.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>yesno</literal></term>
            <listitem><para>
              Entered when there’s a yes/no prompt displayed.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>caret</literal></term>
            <listitem><para>
              Entered when pressing the v mode, used to select text using the
              keyboard.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>register</literal></term>
            <listitem><para>
              Entered when qutebrowser is waiting for a register name/key for
              commands like <literal>:set-mark</literal>.
            </para></listitem>
          </varlistentry>
        </variablelist>
      '';
      example = literalExample ''
        {
          normal = {
            "<Ctrl-v>" = "spawn mpv {url}";
            ",p" = "spawn --userscript qute-pass";
            ",l" = '''config-cycle spellcheck.languages ["en-GB"] ["en-US"]''';
          };
          prompt = {
            "<Ctrl-y>" = "prompt-yes";
          };
        }
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra lines added to qutebrowser <filename>config.py</filename> file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."qutebrowser/config.py".text = concatStringsSep "\n" ([ ]
      ++ [
        "${if cfg.loadAutoconfig then
          "config.load_autoconfig()"
        else
          "config.load_autoconfig(False)"}"
      ] ++ mapAttrsToList (formatLine "c.") cfg.settings
      ++ mapAttrsToList (formatDictLine "c.aliases") cfg.aliases
      ++ mapAttrsToList (formatDictLine "c.url.searchengines") cfg.searchEngines
      ++ mapAttrsToList (formatDictLine "c.bindings.key_mappings")
      cfg.keyMappings
      ++ optional (!cfg.enableDefaultBindings) "c.bindings.default = {}"
      ++ mapAttrsToList formatKeyBindings cfg.keyBindings
      ++ optional (cfg.extraConfig != "") cfg.extraConfig);
  };
}
