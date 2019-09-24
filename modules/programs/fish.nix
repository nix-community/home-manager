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
          </para><para>
          Relevant pieces will be added to the fish function path and
          the completion path. The <filename>init.fish</filename> and
          <filename>key_binding.fish</filename> files are sourced if
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

  abbrsStr = concatStringsSep "\n" (
    mapAttrsToList (k: v: "abbr --add --global ${k} '${v}'") cfg.shellAbbrs
  );

  aliasesStr = concatStringsSep "\n" (
    mapAttrsToList (k: v: "alias ${k}='${v}'") cfg.shellAliases
  );

in

{
  options = {
    programs.fish = {
      enable = mkEnableOption "fish, the friendly interactive shell";

      package = mkOption {
        type = types.package;
        default = pkgs.fish;
        defaultText = literalExample "pkgs.fish";
        description = ''
          The fish package to install. May be used to change the version.
        '';
      };

      shellAliases = mkOption {
        type = with types; attrsOf str;
        default = {};
        example = { ".." = "cd .."; ll = "ls -l"; };
        description = ''
          An attribute set that maps aliases (the top level attribute names
          in this option) to command strings or directly to build outputs.
        '';
      };

      shellAbbrs = mkOption {
        type = with types; attrsOf str;
        default = {};
        example = { l = "less"; gco = "git checkout"; };
        description = ''
          An attribute set that maps aliases (the top level attribute names
          in this option) to abbreviations. Abbreviations are expanded with
          the longer phrase after they are entered.
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

      promptInit = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Shell script code used to initialise fish prompt.
        '';
      };
    };

    programs.fish.plugins = mkOption {
      type = types.listOf pluginModule;
      default = [];
      example = literalExample ''
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
        <filename>conf.d/99plugins.fish</filename>.
      '';
    };

    programs.fish.functions = mkOption {
      type = types.attrsOf types.lines;
      default = {};
      example = { gitignore = "curl -sL https://www.gitignore.io/api/$argv"; };
      description = ''
        Basic functions to add to fish. For more information see
        <link xlink:href="https://fishshell.com/docs/current/commands.html#function"/>.
      '';
    };

  };

  config = mkIf cfg.enable (mkMerge [{

    home.packages = [ cfg.package ];

    xdg.dataFile."fish/home-manager_generated_completions".source =
      let
        # paths later in the list will overwrite those already linked
        destructiveSymlinkJoin =
          args_@{ name
              , paths
              , preferLocalBuild ? true
              , allowSubstitutes ? false
              , postBuild ? ""
              , ...
              }:
          let
            args = removeAttrs args_ [ "name" "postBuild" ]
              // { inherit preferLocalBuild allowSubstitutes; }; # pass the defaults
          in pkgs.runCommand name args
            ''
              mkdir -p $out
              for i in $paths; do
                if [ -z "$(find $i -prune -empty)" ]; then
                  cp -srf $i/* $out
                fi
              done
              ${postBuild}
            '';
        generateCompletions = package: pkgs.runCommand
          "${package.name}-fish-completions"
          {
            src = package;
            nativeBuildInputs = [ pkgs.python2 ];
            buildInputs = [ cfg.package ];
            preferLocalBuild = true;
            allowSubstitutes = false;
          }
          ''
            mkdir -p $out
            if [ -d $src/share/man ]; then
              find $src/share/man -type f \
                | xargs python ${cfg.package}/share/fish/tools/create_manpage_completions.py --directory $out \
                > /dev/null
            fi
          '';
      in
        destructiveSymlinkJoin {
          name = "${config.home.username}-fish-completions";
          paths =
            let
              cmp = (a: b: (a.meta.priority or 0) > (b.meta.priority or 0));
            in
              map generateCompletions (sort cmp config.home.packages);
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

    xdg.configFile."fish/config.fish".text = ''
      # ~/.config/fish/config.fish: DO NOT EDIT -- this file has been generated
      # automatically by home-manager.

      # if we haven't sourced the general config, do it
      if not set -q __fish_general_config_sourced

        set fish_function_path ${pkgs.fish-foreign-env}/share/fish-foreign-env/functions $fish_function_path
        fenv source ${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh > /dev/null
        set -e fish_function_path[1]

        ${cfg.shellInit}
        # and leave a note so we don't source this config section again from
        # this very shell (children will source the general config anew)
        set -g __fish_general_config_sourced 1

      end

      # if we haven't sourced the login config, do it
      status --is-login; and not set -q __fish_login_config_sourced
      and begin

        # Login shell initialisation
        ${cfg.loginShellInit}

        # and leave a note so we don't source this config section again from
        # this very shell (children will source the general config anew)
        set -g __fish_login_config_sourced 1

      end

      # if we haven't sourced the interactive config, do it
      status --is-interactive; and not set -q __fish_interactive_config_sourced
      and begin

        # Abbreviations
        ${abbrsStr}

        # Aliases
        ${aliasesStr}

        # Prompt initialisation
        ${cfg.promptInit}

        # Interactive shell intialisation
        ${cfg.interactiveShellInit}

        # and leave a note so we don't source this config section again from
        # this very shell (children will source the general config anew,
        # allowing configuration changes in, e.g, aliases, to propagate)
        set -g __fish_interactive_config_sourced 1

      end
    '';

  } {

      xdg.configFile = mapAttrs' (fName: fBody: {
        name = "fish/functions/${fName}.fish";
        value = {"text" = ''
          function ${fName}
            ${fBody}
          end
        '';};
      }) cfg.functions;

  }

    # Plugins are all sources together in a conf.d file as this allows
    # the original source to be undisturbed.
    (mkIf (length cfg.plugins > 0) {
      xdg.configFile."fish/conf.d/99plugins.fish".text = concatStrings
        (map (plugin: ''
          # Plugin ${plugin.name}
          if test -d ${plugin.src}/functions
            set fish_function_path $fish_function_path[1] ${plugin.src}/functions $fish_function_path[2..-1]
          end

          if test -d ${plugin.src}/completions
            set fish_complete_path $fish_function_path[1] ${plugin.src}/completions $fish_complete_path[2..-1]
          end

          if test -d ${plugin.src}/conf.d
            source ${plugin.src}/conf.d/*.fish
          end

          if test -f ${plugin.src}/key_bindings.fish
            source ${plugin.src}/key_bindings.fish
          end

          if test -f ${plugin.src}/init.fish
            source ${plugin.src}/init.fish
          end

        ''
        ) cfg.plugins);
    })
  ]);
}
