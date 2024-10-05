{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.broot;

  tomlFormat = pkgs.formats.toml { };

  settingsModule = {
    freeformType = tomlFormat.type;

    options = {
      modal = mkEnableOption "modal (vim) mode";

      verbs = mkOption {
        type = with types; listOf (attrsOf (oneOf [ bool str (listOf str) ]));
        default = [ ];
        example = literalExpression ''
          [
            { invocation = "p"; execution = ":parent"; }
            { invocation = "edit"; shortcut = "e"; execution = "$EDITOR {file}" ; }
            { invocation = "create {subpath}"; execution = "$EDITOR {directory}/{subpath}"; }
            { invocation = "view"; execution = "less {file}"; }
            {
              invocation = "blop {name}\\.{type}";
              execution = "mkdir {parent}/{type} && ''${pkgs.neovim}/bin/nvim {parent}/{type}/{name}.{type}";
              from_shell = true;
            }
          ]
        '';
        description = ''
          Define new verbs. For more information, see
          [Verb Definition Attributes](https://dystroy.org/broot/documentation/configuration/#verb-definition-attributes)
          in the broot documentation.

          The possible attributes are:

          `invocation` (optional)
          : how the verb is called by the user, with placeholders for arguments

          `execution` (mandatory)
          : how the verb is executed

          `key` (optional)
          : a keyboard key triggering execution

          `keys` (optional)
          : multiple keyboard keys each triggering execution

          `shortcut` (optional)
          : an alternate way to call the verb (without
            the arguments part)

          `leave_broot` (optional)
          : whether to quit broot on execution
            (default: `true`)

          `from_shell` (optional)</term>
          : whether the verb must be executed from the
            parent shell (default: `false`)
        '';
      };

      skin = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = literalExpression ''
          {
            status_normal_fg = "grayscale(18)";
            status_normal_bg = "grayscale(3)";
            status_error_fg = "red";
            status_error_bg = "yellow";
            tree_fg = "red";
            selected_line_bg = "grayscale(7)";
            permissions_fg = "grayscale(12)";
            size_bar_full_bg = "red";
            size_bar_void_bg = "black";
            directory_fg = "lightyellow";
            input_fg = "cyan";
            flag_value_fg = "lightyellow";
            table_border_fg = "red";
            code_fg = "lightyellow";
          }
        '';
        description = ''
          Color configuration.

          Complete list of keys (expected to change before the v1 of broot):

          * `char_match`
          * `code`
          * `directory`
          * `exe`
          * `file`
          * `file_error`
          * `flag_label`
          * `flag_value`
          * `input`
          * `link`
          * `permissions`
          * `selected_line`
          * `size_bar_full`
          * `size_bar_void`
          * `size_text`
          * `spinner`
          * `status_error`
          * `status_normal`
          * `table_border`
          * `tree`
          * `unlisted`

          Add `_fg` for a foreground color and
          `_bg` for a background color.
        '';
      };
    };
  };

  shellInit = shell:
    # Using mkAfter to make it more likely to appear after other
    # manipulations of the prompt.
    mkAfter ''
      source ${
        pkgs.runCommand "br.${shell}" { nativeBuildInputs = [ cfg.package ]; }
        "broot --print-shell-function ${shell} > $out"
      }
    '';
in {
  meta.maintainers = [ hm.maintainers.aheaume maintainers.dermetfan ];

  imports = [
    (mkRenamedOptionModule [ "programs" "broot" "modal" ] [
      "programs"
      "broot"
      "settings"
      "modal"
    ])
    (mkRenamedOptionModule [ "programs" "broot" "verbs" ] [
      "programs"
      "broot"
      "settings"
      "verbs"
    ])
    (mkRenamedOptionModule [ "programs" "broot" "skin" ] [
      "programs"
      "broot"
      "settings"
      "skin"
    ])
  ];

  options.programs.broot = {
    enable = mkEnableOption "Broot, a better way to navigate directories";

    enableBashIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Bash integration.
      '';
    };

    enableZshIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Zsh integration.
      '';
    };

    enableFishIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Fish integration.
      '';
    };

    enableNushellIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Nushell integration.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.broot;
      defaultText = literalExpression "pkgs.broot";
      description = "Package providing broot";
    };

    settings = mkOption {
      type = types.submodule settingsModule;
      default = { };
      description = "Verbatim config entries";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."broot" = {
      recursive = true;
      source = pkgs.symlinkJoin {
        name = "xdg.configFile.broot";
        paths = [
          # Copy all files under /resources/default-conf
          "${cfg.package.src}/resources/default-conf"

          # Dummy file to prevent broot from trying to reinstall itself
          (pkgs.writeTextDir "launcher/installed-v1" "")
        ];

        postBuild = ''
          ln -s ${
            tomlFormat.generate "broot-config" cfg.settings
          } $out/conf.toml

          # Remove conf.hjson, whose content has been merged into programs.broot.settings
          rm $out/conf.hjson
        '';
      };
    };

    programs.broot.settings = builtins.fromJSON (builtins.readFile
      (pkgs.runCommand "default-conf.json" {
        nativeBuildInputs = [ pkgs.hjson ];
      }
        "hjson -c ${cfg.package.src}/resources/default-conf/conf.hjson > $out"));

    programs.bash.initExtra = mkIf cfg.enableBashIntegration (shellInit "bash");

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration (shellInit "zsh");

    programs.fish.shellInit = mkIf cfg.enableFishIntegration (shellInit "fish");

    programs.nushell.extraConfig =
      mkIf cfg.enableNushellIntegration (shellInit "nushell");
  };
}
