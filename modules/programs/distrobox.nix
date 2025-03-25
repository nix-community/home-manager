{ lib, pkgs, config, ... }:
let
  inherit (lib) generators types mkIf mkEnableOption mkPackageOption mkOption;

  cfg = config.programs.distrobox;

  formatter = pkgs.formats.ini { listsAsDuplicateKeys = true; };
in {
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.distrobox = {
    enable = mkEnableOption "distrobox";

    package = mkPackageOption pkgs "distrobox" { };

    containers = mkOption {
      type = formatter.type;
      default = { };
      example = ''
        {
          python-project = {
            image = "fedora:40";
            additional_packages = "python3 git";
            init_hooks = "pip3 install numpy pandas torch torchvision";
          };

          common-debian = {
            image = "debian:13";
            entry = true;
            additional_packages = "git";
            init_hooks = [
              "ln -sf /usr/bin/distrobox-host-exec /usr/local/bin/docker"
              "ln -sf /usr/bin/distrobox-host-exec /usr/local/bin/docker-compose"
            ];
          };

          office = {
            clone = "common-debian";
            additional_packages = "libreoffice onlyoffice";
            entry = true;
          };

          random-things = {
            clone = "common-debian";
            entry = false;
          };
        }
      '';
      description = ''
        A set of containers and all its respective configurations. Each option can be either a
        bool, string or a list of strings. If passed a list, the option will be repeated for each element.
        See common-debian in the example config. All the available options for the containers can be found
        in the distrobox-assemble documentation at <https://github.com/89luca89/distrobox/blob/main/docs/usage/distrobox-assemble.md>.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.distrobox" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."distrobox/containers.ini".source =
      (formatter.generate "containers.ini" cfg.containers);

    systemd.user.services.distrobox-home-manager = {
      Unit.Description =
        "Build the containers declared in ~/.config/distrobox/containers.ini";
      Install.WantedBy = [ "default.target" ];

      Service.ExecStart = "${pkgs.writeShellScript "distrobox-home-manager" ''
        PATH=/run/current-system/sw/bin:

        containers_file=${config.xdg.configHome}/distrobox/containers.ini
        prev_hash_file=${config.xdg.configHome}/distrobox/prev_hash
        new_hash=$(sha256sum $containers_file | cut -f 1 -d " ")

        if [[ -f $prev_hash_file ]]; then
          prev_hash=$(cat $prev_hash_file)
        else
          prev_hash=0
        fi

        if [[ $prev_hash != $new_hash ]]; then
          rm -rf /tmp/storage-run-1000/containers
          rm -rf /tmp/storage-run-1000/libpod/tmp
          ${cfg.package}/bin/distrobox-assemble create --file $containers_file
          echo $new_hash > $prev_hash_file
        fi
      ''}";
    };
  };
}
