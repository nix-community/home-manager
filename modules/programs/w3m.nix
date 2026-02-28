{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.w3m;
in
{
  meta.maintainers = with lib.hm.maintainers; [ oneorseveralcats ];

  options.programs.w3m = {
    enable = lib.mkEnableOption "the w3m terminal web browser";

    package = lib.mkPackageOption pkgs "w3m" { nullable = true; };

    homePage = mkOption {
      type = types.str;
      default = "https://duckduckgo.com";
      example = "\${config.xdg.configHome}/w3m/bookmark.html";
      description = "Page w3m opens to if a url isn't provided.";
    };

    w3mImg2Sixel = mkOption {
      type = with types; nullOr str;
      default = "img2sixel";
      example = "img2sixel -d atkinson";
      description = ''
        The executable and arguments that w3m should execute when using libsixel
        as the image backend.
      '';
    };

    bindings = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = {
        "gg" = "BEGIN";
        "C-a" = "LINE_BEGIN";
        "O" =
          ''COMMAND "SET_OPTION dictprompt='GOTO: '; SET_OPTION dictcommand=file:/cgi-bin/opener.cgi ; DICT_WORD"'';
        "\\\"" = "REG_MARK";
        "\";\"" = "MARK_WORD";
        "\\^" = "LINE_BEGIN";
        "M-TAB" = "PREV_LINK";
        "M-C-j" = "SAVE_LINK";
        "DEL" = "CLOSE_TAB";
        "SPC" = "NEXT_PAGE";
        "UP" = "MOVE_UP";
      };
      description = ''
        Keybindings for w3m.

        See <https://git.sr.ht/~rkta/w3m/tree/master/item/doc/README.keymap> for
        documentation.
      '';
    };

    bookmarks = {
      title = mkOption {
        type = types.str;
        default = "Bookmarks";
        description = ''
          Title of the bookmarks page.
        '';
      };

      marks = mkOption {
        type =
          let
            bookmarkType = types.submodule {
              options = {
                name = mkOption {
                  type = types.str;
                  description = ''
                    Display name of bookmark.
                  '';
                };

                url = mkOption {
                  type = types.str;
                  description = ''
                    Destination address of bookmark.
                  '';
                };
              };
            };
          in
          with types;
          attrsOf (listOf bookmarkType);
        default = { };
        example = {
          nix = [
            {
              name = "nixos manual";
              url = "https://nixos.org/manual/nixos/stable/";
            }
            {
              name = "home-manager manual";
              url = "https://nix-community.github.io/home-manager/";
            }
          ];
          archlinux = [
            {
              name = "aur";
              url = "https://aur.archlinux.org/";
            }
            {
              name = "archwiki";
              url = "https://wiki.archlinux.org/title/Main_page";
            }
          ];
        };
        description = ''
          Bookmark file for w3m.
        '';
      };
    };

    cgiBin = mkOption {
      type =
        let
          fileType = types.submodule {
            options = {
              source = mkOption {
                type = with types; nullOr path;
                default = null;
                description = ''
                  Path to script file.
                '';
              };
              text = mkOption {
                type = with types; nullOr lines;
                default = null;
                description = ''
                  Inline content of script file.
                '';
              };
            };
          };
        in
        types.attrsOf fileType;
      default = { };
      example = {
        "search.cgi".text = ''
          #!/usr/bin/env sh

          PREFIX=$(echo "$QUERY_STRING" | cut -d ':' -f1)
          INPUT=$(echo "$QUERY_STRING" | cut -d ':' -f2-)

          case $PREFIX in
            aw) echo "W3m-control: GOTO https://wiki.archlinux.org/index.php?search=$INPUT";;
            ddg) echo "W3m-control: GOTO https://lite.duckduckgo.com/lite/?q=$INPUT";;
          esac

          echo "W3m-control: DELETE_PREVBUF"
        '';
      };
      description = ''
        Scripts located in w3m's cgi-bin directory. For security reasons, w3m can
        only read scripts from here and {file}`''${pkgs.w3m}/libexec/w3m/cgi-bin/`
        (referenceable as $LIB in w3m). The cgi-bin scripts can be written in any
        language and have access to the query provided to them through the
        QUERY_STRING environment variable. A cgi-bin script can send commands
        back to w3m via stdout with the form "W3m-control: <command>".

        See <https://git.sr.ht/~rkta/w3m/tree/master/item/doc/MANUAL.html> for
        more information.

        As of w3m v0.5.5, the option `cgi_bin` isn't defined by default. If you
        want to use any cgi-bin scripts in w3m then set
        `programs.w3m.settings.cgi_bin`.
      '';
    };

    settings = mkOption {
      type = with types; attrsOf (either str int);
      default = { };
      example = {
        cgi_bin = "\${config.xdg.configHome}/w3m/cgi-bin";
        urimethodmap = "\${config.xdg.configHome}/w3m/urimethodmap";
        siteconf_file = "\${config.xdg.configHome}/w3m/siteconf";

        tabstop = 4;
        extbrowser = "firefox";
      };
      description = ''
        Settings for w3m typically set on the OPTIONS page. The best way to
        configure them is setting them in w3m then nixifying the w3m `config`
        file located at either {file}`~/.w3m/config` or
        {file}`~/$XDG_CONFIG_HOME/w3m/config`.
      '';
    };

    siteconf = mkOption {
      type =
        let
          entryType = types.submodule {
            options = {
              url = mkOption {
                type = types.str;
                description = ''
                  The url that the preferences should apply to. Can be of the
                  form `<url>`, `m!<regex>!`, `m@<regex>@`, or `/<regex>/` with trailing
                  optional trailing "i" for case insensitive and "exact" for exact
                  matches.
                '';
              };
              preferences = mkOption {
                type = with types; listOf str;
                description = ''
                  The preferences that w3m can apply to the matched url. Options
                  are: `substitute_url "<destination-url>"`,
                  `url_charset <charset>`, `no_referer_from on|off`,
                  `no_referer_to on|off`, `user_agent "string"`.
                '';
              };
            };
          };
        in
        types.listOf entryType;
      default = [ ];
      example = [
        {
          url = "m!^https://duckduckgo.com/!i";
          preferences = [
            ''substitute_url "https://lite.duckduckgo.com"''
          ];
        }
        {
          url = "m!^https://wikipedia.org/! exact";
          preferences = [
            "url_charset utf-8"
            ''substitute_url "https://eo.wikipedia.org"''
          ];
        }
      ];
      description = ''
        Settings for w3m's siteconf. It allows you to match on a url pattern
        and do various things like url substitutions, site-specific user agent
        settings, specifying charset, and a few others.

        See <https://git.sr.ht/~rkta/w3m/tree/master/item/doc/README.siteconf>
        for documentation and examples.

        As of w3m v0.5.5, siteconf doesn't respect the W3M_DIR environment
        variable, so unless `programs.w3m.settings.siteconf_file` is set,
        `siteconf` will always be at {file}`~/.w3m/siteconf`.
      '';
    };

    urimethodmap = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = {
        ddg = "file:/cgi-bin/search.cgi?%s";
        help = "file:/$LIB/w3mhelp.cgi?%s";
      };
      description = ''
        Settings for w3m's urimethodmap. It allows you to define custom uri
        schemes and map them to scripts. Scripts must be in the directory
        defined in `programs.w3m.settings.cgi_bin`.

        As of w3m v0.5.5, urimethodmap doesn't respect the W3M_DIR environment
        variable, so unless `programs.w3m.settings.urimethodmap` is set,
        `urimethodmap` will always be at {file}`~/.w3m/urimethodmap`.
      '';
    };

    extraPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.rdrview pkgs.libsixel ]";
      description = "Extra packages available to w3m.";
    };
  };

  config =
    let
      w3mDir =
        if config.home.preferXdgDirectories && config.xdg.enable then
          "${config.xdg.configHome}/w3m"
        else
          "${config.home.homeDirectory}/.w3m";

      # the locations that various files should be generated.
      bookmarkFile = "${w3mDir}/bookmark.html";
      configFile = "${w3mDir}/config";
      keymapFile = cfg.settings.keymap_file or "${w3mDir}/keymap";

      # these files currently don't respect the W3M_DIR environment variable so,
      # if not configured in programs.w3m.settings, they're expected to be at
      # ~/.w3m. This will likely be fixed in w3m versions after v0.5.6.
      urimethodmapFile = cfg.settings.urimethodmap or "${config.home.homeDirectory}/.w3m/urimethodmap";
      siteconfFile = cfg.settings.siteconf_file or "${config.home.homeDirectory}/.w3m/siteconf";
      cgiBinDir = cfg.settings.cgi_bin or "${config.home.homeDirectory}/.w3m/cgi-bin";

      # prepends the path of the cgiBinDir to the script name, explicitly generates
      # and replaces any text attribute with equivalent
      # "source = pkgs.writeScript ..."
      cgiScripts = lib.mapAttrs' (
        k: v:
        lib.nameValuePair "${cgiBinDir}/${k}" (
          if (v.text != null) then { source = pkgs.writeScript k v.text; } else v
        )
      ) cfg.cgiBin;

      # used to generate config, keymap, and urimethodmap files
      mkConfig =
        {
          pre ? "",
          sep ? " ",
        }:
        set:
        lib.generators.toKeyValue {
          indent = pre;
          mkKeyValue = lib.generators.mkKeyValueDefault { } sep;
        } set;

      # put at the top of configuration files.
      warningHeader = ''
        # This file was generated by Home Manager and is read-only.

      '';
    in
    mkIf cfg.enable {
      assertions = [
        {
          assertion = (lib.filterAttrs (k: v: !isNull v.text && !isNull v.source) cfg.cgiBin) == { };
          message = "Cannot specify both `.text` and `.source` options for `programs.w3m.cgiBin` scripts.";
        }
      ];

      # wraps w3m to avoid polluting the user environment with its environment
      # variables and extra packages.
      home.packages = lib.mkIf (cfg.package != null) [
        (pkgs.symlinkJoin {
          name = "w3m-wrapped";
          paths = [ cfg.package ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/w3m \
            --set W3M_DIR "${w3mDir}" \
            --set W3M_IMG2SIXEL "${cfg.w3mImg2Sixel}" \
            --set WWW_HOME "${cfg.homePage}" \
            --suffix PATH : ${lib.makeBinPath cfg.extraPackages}
          '';
        })
      ];

      home.file = {
        # generates w3m's bookmark file. the format is:
        #   <h1>title</h1>
        #   <h2>category1</h2>
        #   <ul>
        #     <li>bookmark</li>
        #     ...
        #   </ul>
        #
        #   <h2>category2</h2>
        #   ...
        "${bookmarkFile}" = mkIf (cfg.bookmarks.marks != { }) {
          source =
            let
              mkBookmarks =
                with lib;
                set:
                concatStringsSep "\n" (
                  flatten (
                    mapAttrsToList (
                      k: v:
                      [ "<h2>${k}</h2>" ]
                      ++ [ "<ul>" ]
                      ++ (map (s: "<li><a href=\"${s.url}\">${s.name}</a></li>") v)
                      ++ [ "</ul" ]
                    ) set
                  )
                );
            in
            pkgs.writeText "bookmark.html" ''
              <!-- This file was generated by Home Manager and is read-only. -->
              <!DOCTYPE html>
              <html>
              <head>
              </head>
              <body>
              <h1>${cfg.bookmarks.title}</h1>
              ${mkBookmarks cfg.bookmarks.marks}
              </body>
              </html>
            '';
        };

        # generates w3m's keybinding file. the format is:
        #   keymap <key(s)> <action(s)>
        "${keymapFile}" = mkIf (cfg.bindings != { }) {
          source = pkgs.writeText "keymap" (warningHeader + (mkConfig { pre = "keymap "; } cfg.bindings));
        };

        # generates w3m's main config file. the format is:
        #   <option> <value>
        "${configFile}" = mkIf (cfg.settings != { }) {
          source = pkgs.writeText "config" (warningHeader + (mkConfig { } cfg.settings));
        };

        # generates w3m's siteconf file. the format is:
        #   url <pattern>
        #   <option> <argument>
        #   <option> <argument>
        #   ...
        #
        #
        #   url <pattern>
        #   ...
        "${siteconfFile}" = mkIf (cfg.siteconf != [ ]) {
          source =
            let
              mkSiteConf =
                with lib;
                set: concatStringsSep "\n" (flatten (map (s: [ "url ${s.url}" ] ++ s.preferences ++ [ "\n" ]) set));
            in
            pkgs.writeText "siteconf" (warningHeader + (mkSiteConf cfg.siteconf));
        };

        # generates w3m's urimethodmap file. the format is:
        #   <uri_scheme>: <script>
        "${urimethodmapFile}" = mkIf (cfg.urimethodmap != { }) {
          source = pkgs.writeText "urimethodmap" (
            warningHeader + (mkConfig { sep = ": "; } cfg.urimethodmap)
          );
        };
      }
      // cgiScripts;
    };
}
