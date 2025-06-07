{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    isString
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.nyxt;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.nyxt = {
    enable = mkEnableOption "Nyxt";
    package = mkPackageOption pkgs "nyxt" { nullable = true; };
    config = mkOption {
      type = with types; either lines path;
      default = "";
      example = ''
        (in-package #:nyxt-user)

        (defvar *my-search-engines*
          (list
           (make-instance 'search-engine
                          :name "Google"
                          :shortcut "goo"
                          #+nyxt-4 :control-url #+nyxt-3 :search-url
                          "https://duckduckgo.com/?q=~a")
           (make-instance 'search-engine
                          :name "MDN"
                          :shortcut "mdn"
                          #+nyxt-4 :control-url #+nyxt-3 :search-url
                          "https://developer.mozilla.org/en-US/search?q=~a")))

        (define-configuration browser
          ((restore-session-on-startup-p nil)
           (default-new-buffer-url (quri:uri "https://github.com/atlas-engineer/nyxt"))
           (external-editor-program (if (member :flatpak *features*)
                                        "flatpak-spawn --host emacsclient -r"
                                        "emacsclient -r"))
           #+nyxt-4
           (search-engine-suggestions-p nil)
           #+nyxt-4
           (search-engines (append %slot-default% *my-search-engines*))
           ;; Sets the font for the Nyxt UI (not for webpages).
           (theme (make-instance 'theme:theme
                                 :font-family "Iosevka"
                                 :monospace-font-family "Iosevka"))
           ;; Whether code sent to the socket gets executed.  You must understand the
           ;; risks before enabling this: a privileged user with access to your system
           ;; can then take control of the browser and execute arbitrary code under your
           ;; user profile.
           ;; (remote-execution-p t)
           ))
      '';
      description = ''
        Configuration file for Nyxt, written in the Common Lisp
        programming language.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."nyxt/config.lisp" = mkIf (cfg.config != "") {
      source =
        let
          configSource = if isString cfg.config then pkgs.writeText "nyxt-config" cfg.config else cfg.config;
        in
        configSource;
    };
  };
}
