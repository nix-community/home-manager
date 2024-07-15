{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.nnn;

  renderSetting = key: value: "${key}:${value}";

  renderSettings = settings:
    concatStringsSep ";" (mapAttrsToList renderSetting settings);

  pluginModule = types.submodule ({ ... }: {
    options = {
      src = mkOption {
        type = with types; nullOr path;
        example = literalExpression ''
          (pkgs.fetchFromGitHub {
            owner = "jarun";
            repo = "nnn";
            rev = "v4.0";
            sha256 = "sha256-Hpc8YaJeAzJoEi7aJ6DntH2VLkoR6ToP6tPYn3llR7k=";
          }) + "/plugins";
        '';
        default = null;
        description = ''
          Path to the plugin folder.
        '';
      };

      mappings = mkOption {
        type = with types; attrsOf str;
        description = ''
          Key mappings to the plugins.
        '';
        default = { };
        example = literalExpression ''
          {
            c = "fzcd";
            f = "finder";
            v = "imgview";
          };
        '';
      };
    };
  });
in {
  meta.maintainers = with maintainers; [ thiagokokada ];

  options = {
    programs.nnn = {
      enable = mkEnableOption "nnn";

      package = mkOption {
        type = types.package;
        default = pkgs.nnn;
        defaultText = literalExpression "pkgs.nnn";
        example =
          literalExpression "pkgs.nnn.override ({ withNerdIcons = true; });";
        description = ''
          Package containing the {command}`nnn` program.
        '';
      };

      finalPackage = mkOption {
        type = types.package;
        readOnly = true;
        visible = false;
        description = ''
          Resulting nnn package.
        '';
      };

      bookmarks = mkOption {
        type = with types; attrsOf str;
        description = ''
          Directory bookmarks.
        '';
        example = literalExpression ''
          {
            d = "~/Documents";
            D = "~/Downloads";
            p = "~/Pictures";
            v = "~/Videos";
          };
        '';
        default = { };
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        example =
          literalExpression "with pkgs; [ ffmpegthumbnailer mediainfo sxiv ]";
        description = ''
          Extra packages available to nnn.
        '';
        default = [ ];
      };

      plugins = mkOption {
        type = pluginModule;
        description = ''
          Manage nnn plugins.
        '';
        default = { };
      };

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

      quitcd = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether to enable cd on quit.
        '';
      };
    };
  };

  config = let
    nnnPackage = cfg.package.overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ])
        ++ [ pkgs.makeWrapper ];
      postInstall = ''
        ${oldAttrs.postInstall or ""}

        wrapProgram $out/bin/nnn \
          --prefix PATH : "${makeBinPath cfg.extraPackages}" \
          --prefix NNN_BMS : "${renderSettings cfg.bookmarks}" \
          --prefix NNN_PLUG : "${renderSettings cfg.plugins.mappings}"
      '';
    });

    quitcd = {
      bash_sh_zsh = ''
        n ()
        {
            # Block nesting of nnn in subshells
            [ "''${NNNLVL:-0}" -eq 0 ] || {
                echo "nnn is already running"
                return
            }

            # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
            # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
            # see. To cd on quit only on ^G, remove the "export" and make sure not to
            # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
            #      NNN_TMPFILE="''${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
            export NNN_TMPFILE="''${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

            # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
            # stty start undef
            # stty stop undef
            # stty lwrap undef
            # stty lnext undef

            # The command builtin allows one to alias nnn to n, if desired, without
            # making an infinitely recursive alias
            command nnn "$@"

            [ ! -f "$NNN_TMPFILE" ] || {
                . "$NNN_TMPFILE"
                rm -f -- "$NNN_TMPFILE" > /dev/null
            }
        }
      '';
      fish = ''
        function n --wraps nnn --description 'support nnn quit and change directory'
            # Block nesting of nnn in subshells
            if test -n "$NNNLVL" -a "$NNNLVL" -ge 1
                echo "nnn is already running"
                return
            end

            # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
            # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
            # see. To cd on quit only on ^G, remove the "-x" from both lines below,
            # without changing the paths.
            if test -n "$XDG_CONFIG_HOME"
                set -x NNN_TMPFILE "$XDG_CONFIG_HOME/nnn/.lastd"
            else
                set -x NNN_TMPFILE "$HOME/.config/nnn/.lastd"
            end

            # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
            # stty start undef
            # stty stop undef
            # stty lwrap undef
            # stty lnext undef

            # The command function allows one to alias this function to `nnn` without
            # making an infinitely recursive alias
            command nnn $argv

            if test -e $NNN_TMPFILE
                source $NNN_TMPFILE
                rm -- $NNN_TMPFILE
            end
        end'';
      nu = ''
        # Run nnn with dynamic changing directory to the environment.
        #
        # $env.XDG_CONFIG_HOME sets the home folder for `nnn` folder and its $env.NNN_TMPFILE variable.
        # See manual NNN(1) for more information.
        #
        # Import module using `use quitcd.nu n` to have `n` command in your context.
        export def --env n [
        	...args : string # Extra flags to launch nnn with.
        	--selective = false # Change directory only when exiting via ^G.
        ] -> nothing {

        	# The behaviour is set to cd on quit (nnn checks if $env.NNN_TMPFILE is set).
        	# Hard-coded to its respective behaviour in `nnn` source-code.
        	let nnn_tmpfile = $env
        		| default '~/.config/' 'XDG_CONFIG_HOME'
        		| get 'XDG_CONFIG_HOME'
        		| path join 'nnn/.lastd'
        		| path expand

        	# Launch nnn. Add desired flags after `^nnn`, ex: `^nnn -eda ...$args`,
        	# or make an alias `alias n = n -eda`.
        	if $selective {
        		^nnn ...$args
        	} else {
        		NNN_TMPFILE=$nnn_tmpfile ^nnn ...$args
        	}

        	if ($nnn_tmpfile | path exists) {
        		# Remove <cd '> from the first part of the string and the last single quote <'>.
        		# Fix post-processing of nnn's given path that escapes its single quotes with POSIX syntax.
        		let path = open $nnn_tmpfile
        			| str replace --all --regex `^cd '|'$` ``
        			| str replace --all `'\''''` `'`

        		^rm -- $nnn_tmpfile

        		cd $path
        	}
        }'';
    };
  in mkIf cfg.enable {
    programs.nnn.finalPackage = nnnPackage;
    home.packages = [ nnnPackage ];
    xdg.configFile."nnn/plugins" =
      mkIf (cfg.plugins.src != null) { source = cfg.plugins.src; };

    programs.bash.initExtra =
      mkIf cfg.enableBashIntegration (mkAfter quitcd.bash_sh_zsh);
    programs.zsh.initExtra =
      mkIf cfg.enableZshIntegration (mkAfter quitcd.bash_sh_zsh);
    programs.fish.interactiveShellInit =
      mkIf cfg.enableFishIntegration (mkAfter quitcd.fish);
    programs.nushell.extraConfig =
      mkIf cfg.enableNushellIntegration (mkAfter quitcd.nu);
  };
}
