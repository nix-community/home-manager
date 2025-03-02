{ lib, pkgs, config, ... }:

let
  inherit (lib)
    types isBool boolToString concatStringsSep mapAttrsToList mkIf
    mkEnableOption mkPackageOption mkOption literalExpression;

  cfg = config.programs.distrobox;

  attrToString = name: value:
    let newvalue = if (isBool value) then (boolToString value) else value;
    in "${name}=${newvalue}";

  getFlags = set: concatStringsSep "\n" (mapAttrsToList attrToString set);

  setToContainer = name: set:
    ''
      [${name}]
    '' + (getFlags set);

  getContainersConfig = set:
    (concatStringsSep "\n\n" (mapAttrsToList setToContainer set)) + "\n";

  containersFile = "${config.xdg.configHome}/distrobox/containers.ini";
  prevHashFile = "${config.xdg.configHome}/distrobox/prev-hash";

  # Notice that running 'distrobox-assemble' at build time will fail,
  # since there's no backend available at that moment. So,
  # we should add some mechanism that automatically checks for changes
  # in ~/distrobox/containers.ini, and asks for building the containers.

  bashInitExtra = ''
    alias distrobox-nixos-build="distrobox-assemble create --file ${containersFile}"

    containers_file=${containersFile}
    prev_hash_file=${prevHashFile}
    new_hash=$(sha256sum $containers_file | cut -f 1 -d " ")

    if [[ -f  $prev_hash_file ]]; then
      prev_hash=$(cat $prev_hash_file)
    else
      prev_hash=0
    fi

    if [[ ! $new_hash == $prev_hash ]]; then
      echo "Distrobox's containers list have changed. Do you want to build them now? [y/N/i]:"
      read answer

      if [[ $answer == "y" ]] || [[ $answer == "Y" ]]; then
        distrobox-nixos-build
        echo $new_hash > $prev_hash_file
      elif [[ $answer == "i" ]] || [[ $answer == "I" ]]; then
        echo "Changes ignored. Distrobox won't warn you before more changes are detected."
        echo "To manually build the containers run \'distrobox-nixos-build\'."
        echo $new_hash > $prev_hash_file
      fi
    fi

    unset containers_file
    unset prev_hash_file
    unset new_hash
    unset prev_hash
    unset answer
  '';

  zshInitExtra = bashInitExtra;

  fishInitExtra = ''
    function distrobox-nixos-build
      distrobox-assemble create --file ${containersFile}
    end

    set containers_file ${containersFile}
    set prev_hash_file ${prevHashFile}
    set new_hash (sha256sum $containers_file | cut -f 1 -d " ")

    if test -f $prev_hash_file
      set prev_hash (cat $prev_hash_file)
    else
      set prev_hash 0
    end

    if not test $new_hash = $prev_hash
      echo "Distrobox's containers list have changed. Do you want to build them now? [y/N/i]: "
      read answer

      if test $answer = "y" -o $answer = "Y"
        distrobox-nixos-build
        echo $new_hash > $prev_hash_file
      else if test $answer = "i" -o $answer = "I"
        echo "Changes ignored. Distrobox won't warn you before more changes are detected."
        echo "To manually build the containers run 'distrobox-nixos-build'."
        echo $new_hash > $prev_hash_file
      end
    end

    set -e containers_file
    set -e prev_hash_file
    set -e new_hash
    set -e prev_hash
    set -e answer
  '';

  nushellInitExtra = ''
    def distrobox-nixos-build [] {
      distrobox-assemble create --file ${containersFile}
    }

    let containers_file = "${containersFile}"
    let prev_hash_file = "${prevHashFile}"
    let new_hash = (sha256sum $containers_file | str trim | split row " " | get 0)

    let prev_hash = if ($prev_hash_file | path exists) {
      open $prev_hash_file | str trim
    } else {
      "0"
    }

    if $new_hash != $prev_hash {
      let answer = (input "Distrobox's containers list ave changed. Do you want to build them now? [y/N/i]: ") | str downcase

      if $answer == "y" {
        distrobox-nixos-build
        $new_hash | save $prev_hash_file
      } else if $answer == "i" {
        print "Changes ignored. Distrobox won't warn you before more changes are detected."
        print "To manually build the containers run 'distrobox-nixos-build'"
        $new_hash | save $prev_hash_file
      }
    }

    let containers_file = null
    let prev_hash_file = null
    let new_hash = null
    let prev_hash = null
    let answer = null
  '';

in {
  meta.maintainers = [ lib.hm.maintainers.aguirre-matteo ];

  options.programs.distrobox = {
    enable = mkEnableOption "Distrobox";

    package = mkPackageOption pkgs "distrobox" { };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration =
      lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    containers = mkOption {
      type = with types; attrsOf (attrsOf (either bool str));
      default = { };
      example = literalExpression ''
        {
          debian = {
            image = "debian:latest":
            nvidia = true;
            root = true;
          };

          fedora = {
            image = "fedora:40;
            pull - true;
            entry = true;
            additional_packages = "python3 git fastfetch";
          };
        }
      '';
      description = ''
        A set of containers to be created.
        The name of the container will be equal to the name of the set.
        To see available options see <https://github.com/89luca89/distrobox/blob/main/docs/usage/distrobox-assemble.md>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."distrobox/containers.ini".source =
      pkgs.writeText "containers.ini" (getContainersConfig cfg.containers);

    programs.bash.initExtra = mkIf cfg.enableBashIntegration bashInitExtra;
    programs.zsh.initExtra = mkIf cfg.enableZshIntegration zshInitExtra;
    programs.fish.interactiveShellInit =
      mkIf cfg.enableFishIntegration fishInitExtra;
    programs.nushell.extraConfig =
      mkIf cfg.enableNushellIntegration nushellInitExtra;
  };
}
