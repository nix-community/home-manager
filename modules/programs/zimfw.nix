{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zsh;

  ## copied relToDotDir from ./zsh.nix. Probably should import it, but I don't
  ## know how.
  relToDotDir = file:
    (optionalString (cfg.dotDir != null) (cfg.dotDir + "/")) + file;

  ## zimfw doesn't exist in nixpkgs. I'm open to adding it there, but I'm not
  ## quite sure how to configure it without home-manager, so the following
  ## derivation may not be correct for a more generic case.
  zimPkg = pkgs.stdenv.mkDerivation rec {
    pname = "zimfw";
    version = "v1.11.0";
    src = pkgs.fetchFromGitHub {
      owner = "zimfw";
      repo = pname;
      rev = version;
      ## zim only needs this one file to be installed.
      sparseCheckout = [ "zimfw.zsh" ];
      sha256 = "sha256-BmzYAgP5Z77VqcpAB49cQLNuvQX1qcKmAh9BuXsy2pA=";
    };
    strictDeps = true;
    dontConfigure = true;
    dontBuild = true;
    dontPatch = true;

    installPhase = ''
      mkdir -p $out
      cp -r $src/zimfw.zsh $out/
    '';

    ## zim automates the downloading of any plugins you specify in the `.zimrc`
    ## file. To do that with Nix, you'll need $ZIM_HOME to be writable.
    ## `~/.cache/zim` is a good place for that. The problem is that zim also
    ## looks for `zimfw.zsh` there, so we're going to tell it here to look for
    ## the `zimfw.zsh` where we currently are.
    postFixup = ''
      echo "POSTINSTALL"
      substituteInPlace $out/zimfw.zsh \
        --replace "\''${ZIM_HOME}/zimfw.zsh" "$out/zimfw.zsh"
    '';

    meta = with lib; {
      description =
        "The Zsh configuration framework with blazing speed and modular extensions";
      homepage = "https://zimfw.sh";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };
in {
  meta.maintainers = [ maintainers.joedevivo ];

  options = {
    programs.zsh.zimfw = {
      enable = mkEnableOption "Zim - ${zimPkg.meta.description}";

      homeDir = mkOption {
        default = "$HOME/.zim";
        example = "$HOME/.cache/zim";
        type = types.str;
        description = ''
          Working directory for zim. It stores downloaded plugins here.
        '';
      };

      configFile = mkOption {
        default = if cfg.dotDir != null then
          "$HOME/${cfg.dotDir}/.zimrc"
        else
          "$HOME/.zimrc";
        type = types.str;
        description = ''
          Location of zimrc file
        '';
      };

      degit = mkOption {
        default = true;
        example = false;
        type = types.bool;
        description = ''
          Use zim's degit tool for faster module installation.
        '';
      };

      disableVersionCheck = mkOption {
        default = false;
        type = types.bool;
        description = ''
          disables 30 day version check
        '';
      };

      zmodules = mkOption {
        default = [ "environment" "git" "input" "termtitle" "utility" ];
        example = [
          "environment"
          "git"
          "input"
          "termtitle"
          "utility"
          "exa"
          "$PATH_TO_LOCAL_MODULE"
          "duration-info"
          "git-info"
        ];
        type = types.listOf types.str;
        description = ''
          List of zimfw modules. These are added to `.zimrc` verbatim,
          so ENV vars will work for paths to local modules.
        '';
      };
    };
  };

  config = mkIf cfg.zimfw.enable {
    home.packages = [ zimPkg ];
    programs.zsh.localVariables = {
      ZIM_HOME = cfg.zimfw.homeDir;
      ZIM_CONFIG_FILE = cfg.zimfw.configFile;
    };
    programs.zsh.initExtra = concatStringsSep "\n" ([
      (optionalString (cfg.zimfw.degit) ''
        zstyle ':zim:zmodule' use 'degit'
      '')
      (optionalString (cfg.zimfw.disableVersionCheck) ''
        zstyle ':zim' disable-version-check yes
      '')
      ''
        if [[ ! -e ${zimPkg}/zimfw.zsh ]]; then
          echo "Zim is missing, this is a nix issue."
        fi
        if [[ ! -e ''${ZIM_HOME} ]]; then
          mkdir -p ''${ZIM_HOME}
        fi
        # Install missing modules, and update ''${ZIM_HOME}/init.zsh
        # if missing or outdated.
        if [[ ! ''${ZIM_HOME}/init.zsh -nt ''${ZIM_CONFIG_FILE} ]]; then
          source ${zimPkg}/zimfw.zsh init -q
        fi
        source ''${ZIM_HOME}/init.zsh
      ''
    ]);
    home.file."${relToDotDir ".zimrc"}".text = concatStringsSep "\n"
      ((map (zmodule: "zmodule ${zmodule}") cfg.zimfw.zmodules));
    home.activation.zimfw = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      zsh -c "export ZIM_HOME="${cfg.zimfw.homeDir}" && source ${zimPkg}/zimfw.zsh init -q && zimfw install && zimfw compile"
    '';
  };
}
