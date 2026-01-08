{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.distrobox;

  generateConfig = lib.generators.toKeyValue {
    mkKeyValue =
      name: value: if lib.isString value then ''${name}="${value}"'' else "${name}=${toString value}";
  };

  iniFormat = pkgs.formats.ini { listsAsDuplicateKeys = true; };
  iniAtomType = iniFormat.lib.types.atom;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.distrobox = {
    enable = mkEnableOption "distrobox";
    package = mkPackageOption pkgs "distrobox" { nullable = true; };
    enableSystemdUnit = mkOption {
      type = lib.types.bool;
      default = cfg.containers != { } && cfg.package != null;
      defaultText = "config.programs.distrobox.containers != { } && config.programs.distrobox.package != null";
      example = false;
      description = ''
        Whatever to enable a Systemd Unit that automatically rebuilds your
        containers when changes are detected.
      '';
    };
    settings = mkOption {
      type = lib.types.attrsOf iniAtomType;
      default = { };
      example = {
        container_always_pull = "1";
        container_generate_entry = 0;
        container_manager = "docker";
        container_image_default = "registry.opensuse.org/opensuse/toolbox:latest";
        container_name_default = "test-name-1";
        container_user_custom_home = "$HOME/.local/share/container-home-test";
        container_init_hook = "~/.local/distrobox/a_custom_default_init_hook.sh";
        container_pre_init_hook = "~/a_custom_default_pre_init_hook.sh";
        container_manager_additional_flags = "--env-file /path/to/file --custom-flag";
        container_additional_volumes = "/example:/example1 /example2:/example3:ro";
        non_interactive = "1";
        skip_workdir = "0";
      };
      description = ''
        Configuration settings for Distrobox. All the available options can be found here:
        <https://github.com/89luca89/distrobox?tab=readme-ov-file#configure-distrobox>
      '';
    };
    containers = mkOption {
      inherit (iniFormat) type;
      default = { };
      example = {
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
      };
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
      (lib.hm.assertions.assertPlatform "programs.distrobox" pkgs lib.platforms.linux)
      {
        assertion = cfg.enableSystemdUnit -> (cfg.containers != { });
        message = "Cannot set `programs.distrobox.enableSystemdUnit` if `programs.distrobox.containers` is unset.";
      }
      {
        assertion = cfg.enableSystemdUnit -> (cfg.package != null);
        message = "Cannot set `programs.distrobox.enableSystemdUnit` if `programs.distrobox.package` is set to null.";
      }
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "distrobox/containers.ini" = mkIf (cfg.containers != { }) {
        source = iniFormat.generate "distrobox-containers.ini" cfg.containers;
      };
      "distrobox/distrobox.conf" = mkIf (cfg.settings != { }) {
        text = generateConfig cfg.settings;
      };
    };

    systemd.user.services.distrobox-home-manager = mkIf (cfg.enableSystemdUnit && cfg.package != null) {
      Unit.Description = "Build the containers declared in ~/.config/distrobox/containers.ini";
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
