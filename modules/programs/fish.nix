{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.fish;

  pluginModule = types.submodule ({ config, ... }: {
    options = {
      src = mkOption {
        type = types.path;
        description = ''
          Path to the plugin folder.

          Relevant pieces will be added to the fish function path and
          the completion path. The {file}`init.fish` and
          {file}`key_binding.fish` files are sourced if
          they exist.
        '';
      };

      name = mkOption {
        type = types.str;
        description = ''
          The name of the plugin.
        '';
      };
    };
  });

  functionModule = types.submodule {
    options = {
      body = mkOption {
        type = types.lines;
        description = ''
          The function body.
        '';
      };

      argumentNames = mkOption {
        type = with types; nullOr (either str (listOf str));
        default = null;
        description = ''
          Assigns the value of successive command line arguments to the names
          given.
        '';
      };

      description = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          A description of what the function does, suitable as a completion
          description.
        '';
      };

      wraps = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          Causes the function to inherit completions from the given wrapped
          command.
        '';
      };

      onEvent = mkOption {
        type = with types; nullOr (either str (listOf str));
        default = null;
        description = ''
          Tells fish to run this function when the specified named event is
          emitted. Fish internally generates named events e.g. when showing the
          prompt.
        '';
      };

      onVariable = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          Tells fish to run this function when the specified variable changes
          value.
        '';
      };

      onJobExit = mkOption {
        type = with types; nullOr (either str int);
        default = null;
        description = ''
          Tells fish to run this function when the job with the specified group
          ID exits. Instead of a PID, the stringer `caller` can
          be specified. This is only legal when in a command substitution, and
          will result in the handler being triggered by the exit of the job
          which created this command substitution.
        '';
      };

      onProcessExit = mkOption {
        type = with types; nullOr (either str int);
        default = null;
        example = "$fish_pid";
        description = ''
          Tells fish to run this function when the fish child process with the
          specified process ID exits. Instead of a PID, for backwards
          compatibility, `%self` can be specified as an alias
          for `$fish_pid`, and the function will be run when
          the current fish instance exits.
        '';
      };

      onSignal = mkOption {
        type = with types; nullOr (either str int);
        default = null;
        example = [ "SIGHUP" "HUP" 1 ];
        description = ''
          Tells fish to run this function when the specified signal is
          delievered. The signal can be a signal number or signal name.
        '';
      };

      noScopeShadowing = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Allows the function to access the variables of calling functions.
        '';
      };

      inheritVariable = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          Snapshots the value of the specified variable and defines a local
          variable with that same name and value when the function is defined.
        '';
      };
    };
  };

  abbrModule = types.submodule {
    options = {
      expansion = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          The command expanded by an abbreviation.
        '';
      };

      position = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "anywhere";
        description = ''
          If the position is "command", the abbreviation expands only if
          the position is a command. If it is "anywhere", the abbreviation
          expands anywhere.
        '';
      };

      regex = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          The regular expression pattern matched instead of the literal name.
        '';
      };

      command = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          Specifies the command(s) for which the abbreviation should expand. If
          set, the abbreviation will only expand when used as an argument to
          the given command(s).
        '';
      };

      setCursor = mkOption {
        type = with types; (either bool str);
        default = false;
        description = ''
          The marker indicates the position of the cursor when the abbreviation
          is expanded. When setCursor is true, the marker is set with a default
          value of "%".
        '';
      };

      function = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          The fish function expanded instead of a literal string.
        '';
      };
    };
  };

  abbrsStr = concatStringsSep "\n" (mapAttrsToList (name: def:
    let
      mods = with def;
        cli.toGNUCommandLineShell {
          mkOption = k: v:
            if v == null then
              [ ]
            else if k == "set-cursor" then
              [ "--${k}=${lib.generators.mkValueStringDefault { } v}" ]
            else [
              "--${k}"
              (lib.generators.mkValueStringDefault { } v)
            ];
        } {
          inherit position regex command function;
          set-cursor = setCursor;
        };
      modifiers = if isAttrs def then mods else "";
      expansion = if isAttrs def then def.expansion else def;
    in "abbr --add ${modifiers} -- ${name}"
    + optionalString (expansion != null) " ${escapeShellArg expansion}")
    cfg.shellAbbrs);

  aliasesStr = concatStringsSep "\n"
    (mapAttrsToList (k: v: "alias ${k} ${escapeShellArg v}") cfg.shellAliases);

  fishIndent = name: text:
    pkgs.runCommand name {
      nativeBuildInputs = [ cfg.package ];
      inherit text;
      passAsFile = [ "text" ];
    } "env HOME=$(mktemp -d) fish_indent < $textPath > $out";

  translatedSessionVariables =
    pkgs.runCommandLocal "hm-session-vars.fish" { } ''
      (echo "function setup_hm_session_vars;"
      ${pkgs.buildPackages.babelfish}/bin/babelfish \
      <${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh
      echo "end"
      echo "setup_hm_session_vars") > $out
    '';

in {
  imports = [
    (mkRemovedOptionModule [ "programs" "fish" "promptInit" ] ''
      Prompt is now configured through the

        programs.fish.interactiveShellInit

      option. Please change to use that instead.
    '')
  ];

  options = {
    programs.fish = {
      enable = mkEnableOption "fish, the friendly interactive shell";

      package = mkOption {
        type = types.package;
        default = pkgs.fish;
        defaultText = literalExpression "pkgs.fish";
        description = ''
          The fish package to install. May be used to change the version.
        '';
      };

      generateCompletions = mkEnableOption
        "the automatic generation of completions based upon installed man pages"
        // {
          default = true;
        };

      shellAliases = mkOption {
        type = with types; attrsOf str;
        default = { };
        example = literalExpression ''
          {
            g = "git";
            "..." = "cd ../..";
          }
        '';
        description = ''
          An attribute set that maps aliases (the top level attribute names
          in this option) to command strings or directly to build outputs.
        '';
      };

      shellAbbrs = mkOption {
        type = with types; attrsOf (either str abbrModule);
        default = { };
        example = literalExpression ''
          {
            l = "less";
            gco = "git checkout";
            "-C" = {
              position = "anywhere";
              expansion = "--color";
            };
          }
        '';
        description = ''
          An attribute set that maps aliases (the top level attribute names
          in this option) to abbreviations. Abbreviations are expanded with
          the longer phrase after they are entered.
        '';
      };

      preferAbbrs = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          If enabled, abbreviations will be preferred over aliases when
          other modules define aliases for fish.
        '';
      };

      shellInit = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Shell script code called during fish shell
          initialisation.
        '';
      };

      loginShellInit = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Shell script code called during fish login shell
          initialisation.
        '';
      };

      interactiveShellInit = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Shell script code called during interactive fish shell
          initialisation.
        '';
      };

      shellInitLast = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Shell script code called during interactive fish shell
          initialisation, this will be the last thing executed in fish startup.
        '';
      };
    };

    programs.fish.plugins = mkOption {
      type = types.listOf pluginModule;
      default = [ ];
      example = literalExpression ''
        [
          {
            name = "z";
            src = pkgs.fetchFromGitHub {
              owner = "jethrokuan";
              repo = "z";
              rev = "ddeb28a7b6a1f0ec6dae40c636e5ca4908ad160a";
              sha256 = "0c5i7sdrsp0q3vbziqzdyqn4fmp235ax4mn4zslrswvn8g3fvdyh";
            };
          }

          # oh-my-fish plugins are stored in their own repositories, which
          # makes them simple to import into home-manager.
          {
            name = "fasd";
            src = pkgs.fetchFromGitHub {
              owner = "oh-my-fish";
              repo = "plugin-fasd";
              rev = "38a5b6b6011106092009549e52249c6d6f501fba";
              sha256 = "06v37hqy5yrv5a6ssd1p3cjd9y3hnp19d3ab7dag56fs1qmgyhbs";
            };
          }
        ]
      '';
      description = ''
        The plugins to source in
        {file}`conf.d/99plugins.fish`.
      '';
    };

    programs.fish.functions = mkOption {
      type = with types; attrsOf (either lines functionModule);
      default = { };
      example = literalExpression ''
        {
          __fish_command_not_found_handler = {
            body = "__fish_default_command_not_found_handler $argv[1]";
            onEvent = "fish_command_not_found";
          };

          gitignore = "curl -sL https://www.gitignore.io/api/$argv";
        }
      '';
      description = ''
        Basic functions to add to fish. For more information see
        <https://fishshell.com/docs/current/cmds/function.html>.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    { home.packages = [ cfg.package ]; }

    (mkIf cfg.generateCompletions {
      # Support completion for `man` by building a cache for `apropos`.
      programs.man.generateCaches = mkDefault true;

      xdg.dataFile."fish/home-manager_generated_completions".source = let
        # paths later in the list will overwrite those already linked
        destructiveSymlinkJoin = args_@{ name, paths, preferLocalBuild ? true
          , allowSubstitutes ? false, postBuild ? "", ... }:
          let
            args = removeAttrs args_ [ "name" "postBuild" ] // {
              # pass the defaults
              inherit preferLocalBuild allowSubstitutes;
            };
          in pkgs.runCommand name args ''
            mkdir -p $out
            for i in $paths; do
              if [ -z "$(find $i -prune -empty)" ]; then
                cp -srf $i/* $out
              fi
            done
            ${postBuild}
          '';

        generateCompletions = let
          getName = attrs:
            attrs.name or "${attrs.pname or "«pname-missing»"}-${
              attrs.version or "«version-missing»"
            }";
        in package:
        pkgs.runCommand "${getName package}-fish-completions" {
          srcs = [ package ] ++ filter (p: p != null)
            (builtins.map (outName: package.${outName} or null)
              config.home.extraOutputsToInstall);
          nativeBuildInputs = [ pkgs.python3 ];
          buildInputs = [ cfg.package ];
          preferLocalBuild = true;
        } ''
          mkdir -p $out
          for src in $srcs; do
            if [ -d $src/share/man ]; then
              find -L $src/share/man -type f \
                -exec python ${cfg.package}/share/fish/tools/create_manpage_completions.py --directory $out {} + \
                > /dev/null
            fi
          done
        '';
      in destructiveSymlinkJoin {
        name = "${config.home.username}-fish-completions";
        paths =
          let cmp = (a: b: (a.meta.priority or 0) > (b.meta.priority or 0));
          in map generateCompletions (sort cmp config.home.packages);
      };

      programs.fish.interactiveShellInit = ''
        # add completions generated by Home Manager to $fish_complete_path
        begin
          set -l joined (string join " " $fish_complete_path)
          set -l prev_joined (string replace --regex "[^\s]*generated_completions.*" "" $joined)
          set -l post_joined (string replace $prev_joined "" $joined)
          set -l prev (string split " " (string trim $prev_joined))
          set -l post (string split " " (string trim $post_joined))
          set fish_complete_path $prev "${config.xdg.dataHome}/fish/home-manager_generated_completions" $post
        end
      '';
    })

    {
      xdg.configFile."fish/config.fish".source = fishIndent "config.fish" ''
        # ~/.config/fish/config.fish: DO NOT EDIT -- this file has been generated
        # automatically by home-manager.

        # Only execute this file once per shell.
        set -q __fish_home_manager_config_sourced; and exit
        set -g __fish_home_manager_config_sourced 1

        source ${translatedSessionVariables}

        ${cfg.shellInit}

        status is-login; and begin

          # Login shell initialisation
          ${cfg.loginShellInit}

        end

        status is-interactive; and begin

          # Abbreviations
          ${abbrsStr}

          # Aliases
          ${aliasesStr}

          # Interactive shell initialisation
          ${cfg.interactiveShellInit}

        end

        ${cfg.shellInitLast}
      '';
    }
    {
      xdg.configFile = mapAttrs' (name: def: {
        name = "fish/functions/${name}.fish";
        value = {
          source = let
            modifierStr = n: v: optional (v != null) ''--${n}="${toString v}"'';
            modifierStrs = n: v: optional (v != null) "--${n}=${toString v}";
            modifierBool = n: v: optional (v != null && v) "--${n}";

            mods = with def;
              modifierStr "description" description ++ modifierStr "wraps" wraps
              ++ lib.concatMap (modifierStr "on-event") (lib.toList onEvent)
              ++ modifierStr "on-variable" onVariable
              ++ modifierStr "on-job-exit" onJobExit
              ++ modifierStr "on-process-exit" onProcessExit
              ++ modifierStr "on-signal" onSignal
              ++ modifierBool "no-scope-shadowing" noScopeShadowing
              ++ modifierStr "inherit-variable" inheritVariable
              ++ modifierStrs "argument-names" argumentNames;

            modifiers = if isAttrs def then " ${toString mods}" else "";
            body = if isAttrs def then def.body else def;
          in fishIndent "${name}.fish" ''
            function ${name}${modifiers}
              ${lib.strings.removeSuffix "\n" body}
            end
          '';
        };
      }) cfg.functions;
    }

    # Each plugin gets a corresponding conf.d/plugin-NAME.fish file to load
    # in the paths and any initialization scripts.
    (mkIf (length cfg.plugins > 0) {
      xdg.configFile = mkMerge ((map (plugin: {
        "fish/conf.d/plugin-${plugin.name}.fish".source =
          fishIndent "${plugin.name}.fish" ''
            # Plugin ${plugin.name}
            set -l plugin_dir ${plugin.src}

            # Set paths to import plugin components
            if test -d $plugin_dir/functions
              set fish_function_path $fish_function_path[1] $plugin_dir/functions $fish_function_path[2..-1]
            end

            if test -d $plugin_dir/completions
              set fish_complete_path $fish_complete_path[1] $plugin_dir/completions $fish_complete_path[2..-1]
            end

            # Source initialization code if it exists.
            if test -d $plugin_dir/conf.d
              for f in $plugin_dir/conf.d/*.fish
                source $f
              end
            end

            if test -f $plugin_dir/key_bindings.fish
              source $plugin_dir/key_bindings.fish
            end

            if test -f $plugin_dir/init.fish
              source $plugin_dir/init.fish
            end
          '';
      }) cfg.plugins));
    })
  ]);
}
