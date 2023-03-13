{ home-manager, gettext, runCommand, ncurses }:

let

  hmBashLibInit = ''
    export TEXTDOMAIN=home-manager
    export TEXTDOMAINDIR=${home-manager}/share/locale
    source ${home-manager}/share/bash/home-manager.sh
  '';

in runCommand "home-manager-install" {
  propagatedBuildInputs = [ home-manager gettext ncurses ];
  preferLocalBuild = true;
  shellHookOnly = true;
  shellHook = ''
    ${hmBashLibInit}

    confFile="''${XDG_CONFIG_HOME:-$HOME/.config}/home-manager/home.nix"

    if [[ ! -e $confFile ]]; then
      echo
      _i "Creating initial Home Manager configuration..."

      nl=$'\n'
      xdgVars=""
      if [[ -v XDG_CACHE_HOME && $XDG_CACHE_HOME != "$HOME/.cache" ]]; then
        xdgVars="$xdgVars  xdg.cacheHome = \"$XDG_CACHE_HOME\";$nl"
      fi
      if [[ -v XDG_CONFIG_HOME && $XDG_CONFIG_HOME != "$HOME/.config" ]]; then
        xdgVars="$xdgVars  xdg.configHome = \"$XDG_CONFIG_HOME\";$nl"
      fi
      if [[ -v XDG_DATA_HOME && $XDG_DATA_HOME != "$HOME/.local/share" ]]; then
        xdgVars="$xdgVars  xdg.dataHome = \"$XDG_DATA_HOME\";$nl"
      fi
      if [[ -v XDG_STATE_HOME && $XDG_STATE_HOME != "$HOME/.local/state" ]]; then
        xdgVars="$xdgVars  xdg.stateHome = \"$XDG_STATE_HOME\";$nl"
      fi

      mkdir -p "$(dirname "$confFile")"
      cat > $confFile <<EOF
    { config, pkgs, ... }:

    {
      # Home Manager needs a bit of information about you and the
      # paths it should manage.
      home.username = "$USER";
      home.homeDirectory = "$HOME";
    $xdgVars
      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
      home.stateVersion = "22.11";

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;
    }
    EOF
    fi

    echo
    _i "Creating initial Home Manager generation..."
    echo

    if home-manager switch ; then
      # translators: The "%s" specifier will be replaced by a file path.
      _i $'All done! The home-manager tool should now be installed and you can edit\n\n    %s\n\nto configure Home Manager. Run \'man home-configuration.nix\' to\nsee all available options.' \
        "$confFile"
      exit 0
    else
      # translators: The "%s" specifier will be replaced by a URL.
      _i $'Uh oh, the installation failed! Please create an issue at\n\n    %s\n\nif the error seems to be the fault of Home Manager.' \
        "https://github.com/nix-community/home-manager/issues"
      exit 1
    fi
  '';
} ''
  ${hmBashLibInit}
  _iError 'This derivation is not buildable, please run it using nix-shell.'
  exit 1
''
