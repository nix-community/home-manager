{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.fish;

  abbrsStr = concatStringsSep "\n" (
    mapAttrsToList (k: v: "abbr --add --global ${k} '${v}'") cfg.shellAbbrs
  );

  aliasesStr = concatStringsSep "\n" (
    mapAttrsToList (k: v: "alias ${k}='${v}'") cfg.shellAliases
  );

  fileType = textGen: types.submodule (
    { name, config, ... }: {
      options = {
        body = mkOption {
          default = null;
          type = types.nullOr types.lines;
          description = "Body of the file.";
        };

        source = mkOption {
          type = types.path;
          description = ''
            Path of the source file. The file name must not start
            with a period.
          '';
        };
      };

      config = {
        source = mkIf (config.body != null) (
          mkDefault (pkgs.writeTextFile {
            inherit name;
            text = textGen name config.body;
            executable = true;
          })
        );
      };
    }
  );
in

{
  options = {
    programs.fish = {
      enable = mkEnableOption "fish friendly interactive shell";

      package = mkOption {
        type = types.package;
        default = pkgs.fish;
        defaultText = literalExample "pkgs.fish";
        description = ''
          The fish package to install. May be used to change the version.
        '';
      };

      shellAliases = mkOption {
        type = types.attrs;
        default = {};
        example = { ".." = "cd .."; ll = "ls -l"; };
        description = ''
          An attribute set that maps aliases (the top level attribute names
          in this option) to command strings or directly to build outputs.
        '';
      };

      shellAbbrs = mkOption {
        type = types.attrs;
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
      type = types.listOf types.package;
      default = [];
      description = ''
        The plugins to add to fish.
        Built with <varname>buildFishPlugin</varname>.
        Overrides manually installed ones.
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

    programs.fish.completions = mkOption {
      type = types.attrsOf (fileType (name: body: body));
      default = {};
      description = ''
        Completions to add to fish.
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
      xdg.configFile = mapAttrs' (f_name: f_body: {
        name = "fish/functions/${f_name}.fish";
        value = {"text" = ''
          function ${f_name}
            ${f_body}
          end
        '';};
      }) cfg.functions;
    } (
    let
      wrappedPkgVersion = lib.getVersion pkgs.fish;
      wrappedPkgName = lib.removeSuffix "-${wrappedPkgVersion}" pkgs.fish.name;
      dependencies = concatMap (p: p.dependencies) cfg.plugins;
      combinedPluginDrv = pkgs.buildEnv {
        name = "${wrappedPkgName}-plugins-${wrappedPkgVersion}";
        paths = cfg.plugins;
        postBuild = ''
          touch $out/setup.fish

          if [ -d $out/functions ]; then
            echo "set fish_function_path \$fish_function_path[1] $out/functions \$fish_function_path[2..-1]" >> $out/setup.fish
          fi

          if [ -d $out/completions ]; then
            echo "set fish_complete_path \$fish_complete_path[1] $out/completions \$fish_complete_path[2..-1]" >> $out/setup.fish
          fi

          if [ -d $out/conf.d ]; then
            echo "source $out/conf.d/*.fish" >> $out/setup.fish
          fi
        '';
      };
    in mkIf (length cfg.plugins > 0) {
      xdg.configFile."fish/conf.d/99plugins.fish".source = "${combinedPluginDrv}/setup.fish";
      home.packages = dependencies;
  })]);
}
