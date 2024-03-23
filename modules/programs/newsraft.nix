{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.newsraft;

  nrSection = types.submodule {
    options = {
      name = mkOption { type = types.nonEmptyStr; };

      urls = mkOption { type = with types; listOf nonEmptyStr; };
    };
  };

  feedsFile = let
    AttrToListNr = attr:
      mapAttrsToList
      (_: value: if (isString value) then "@ ${value}" else value) attr;
    convertAttrs = attrs:
      mapAttrs
      (name: value: if (name == "wrong") then map AttrToListNr value else value)
      attrs;
  in concatStringsSep "\n" (flatten (mapAttrsToList (_: value: value)
    (convertAttrs (lib.partition (field: !isAttrs field) cfg.feeds))));

  settingsFile = let
    # because toString turns true into "1" and false into ""
    anyToStr = val:
      if (isBool val) then (if val then "true" else "false") else toString val;
    renderSettings = attr:
      mapAttrsToList (name: value: "set ${name} ${anyToStr value}") attr;
    renderBindings = attr:
      mapAttrsToList (key: value: "bind ${key} ${value}") attr;
  in concatStringsSep "\n" ((renderSettings cfg.settings)
    ++ (renderBindings cfg.bindings) ++ [ cfg.extraConfig ]);
in {
  meta.maintainers = [ maintainers.arthsmn ];

  options.programs.newsraft = {
    enable = mkEnableOption "Newsraft feed reader";

    feeds = mkOption {
      type = with types; listOf (oneOf [ nonEmptyStr nrSection ]);
      default = { };
      example = ''
        [
          "https://nixos.org/blog/announcements-rss.xml"

          {
            name = "Tech";
            urls = ["https://news.ycombinator.com/rss" "https://www.phoronix.com/rss.php"];
          }
        ]
      '';
      description =
        "The feed list for newsraft. It can be either a list of links (strings) or attributes for sections (with a name field and a list of feeds). If an auto update timer needs to be set, you should set either in the end of the link, or in the name of the section.";
    };

    settings = mkOption {
      type = with types; attrsOf (oneOf [ ints.unsigned str bool ]);
      default = { };
      example = {
        scrolloff = 12;
        copy-to-clipboard-command = "wl-copy";
        section-menu-paramount-explore = true;

        color-status-good-fg = "default";
        color-status-good-bg = "bold green";
      };
      description =
        "The settings for newsraft. For colors, set both the color and the optional format attribute together.";
    };

    bindings = mkOption {
      type = with types; attrsOf nonEmptyStr;
      default = { };
      example = {
        f = "exec feh %l";
        "^P" = "mark-unread-all";
      };
      description = ''
        The bindings for newsraft. If the binding isn't a simple string (eg. ^P), you have to wrap it with parenthesis (eg. "^P").'';
    };

    extraConfig = mkOption {
      type = types.nonEmptyStr;
      default = "";
      example = ''
        unbind r
      '';
      description =
        "Extra raw configuration lines to be added to newsraft config.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.enable -> cfg.feeds != [ ];
      message = "You have to specify at least one feed.";
    }];

    home.packages = [ pkgs.newsraft ];

    xdg.configFile."newsraft/feeds".text = feedsFile + "\n";
    xdg.configFile."newsraft/config".text =
      mkIf (cfg.settings != { } || cfg.bindings != { } || cfg.extraConfig != "")
      (settingsFile + "\n");
  };
}
