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

in {
  options.programs.qutebrowser = {
    enable = mkEnableOption "qutebrowser";

    aliases = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Aliases for commands.
      '';
    };

    searchEngines = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Search engines which can be used via the address bar. Maps a search engine name (such as <literal>DEFAULT</literal>, or <literal>ddg</literal>) to a URL with a <literal>{}</literal> placeholder. The placeholder will be replaced by the search term, use <literal>{{</literal> and <literal>}}</literal> for literal <literal>{/}</literal> signs. The search engine named <literal>DEFAULT</literal> is used when <literal>url.auto_search</literal> is turned on and something else than a URL was entered to be opened. Other search engines can be used by prepending the search engine name to the search term, e.g. <literal>:open google qutebrowser</literal>.
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
      type = types.attrs;
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
        This setting can be used to map keys to other keys. When the key used as dictionary-key is pressed, the binding for the key used as dictionary-value is invoked instead. This is useful for global remappings of keys, for example to map Ctrl-[ to Escape. Note that when a key is bound (via <literal>bindings.default</literal> or <literal>bindings.commands</literal>), the mapping is ignored.
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
    home.packages = [ pkgs.qutebrowser ];

    xdg.configFile."qutebrowser/config.py".text = concatStringsSep "\n" ([ ]
      ++ mapAttrsToList (formatLine "c.") cfg.settings
      ++ mapAttrsToList (formatDictLine "c.aliases") cfg.aliases
      ++ mapAttrsToList (formatDictLine "c.url.searchengines") cfg.searchEngines
      ++ mapAttrsToList (formatDictLine "c.bindings.key_mappings")
      cfg.keyMappings ++ optional (cfg.extraConfig != "") cfg.extraConfig);
  };
}
