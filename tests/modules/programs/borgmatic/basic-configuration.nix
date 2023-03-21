{ config, pkgs, ... }:

let
  boolToString = bool: if bool then "true" else "false";
  backups = config.programs.borgmatic.backups;
in {
  config = {
    programs.borgmatic = {
      enable = true;
      backups = {
        main = {
          location = {
            sourceDirectories = [ "/my-stuff-to-backup" ];
            repositories = [ "/mnt/disk1" "/mnt/disk2" ];
          };

          storage = { encryptionPasscommand = "fetch-the-password.sh"; };

          retention = {
            keepWithin = "14d";
            keepSecondly = 12;
          };

          consistency = {
            checks = [
              {
                name = "repository";
                frequency = "2 weeks";
              }
              {
                name = "archives";
                frequency = "4 weeks";
              }
            ];
          };

          extraConfig = {
            location = {
              one_file_system = true;
              exclude_patterns = [ "*.swp" ];
            };
            storage = { checkpoint_interval = 200; };
            retention = { prefix = "hostname"; };
            consistency = { prefix = "hostname"; };
            hooks = { before_actions = [ "echo Starting actions." ]; };
          };
        };
      };
    };

    test.stubs.borgmatic = { };

    nmt.script = ''
      config_file=$TESTED/home-files/.config/borgmatic.d/main.yaml
      assertFileExists $config_file

      declare -A expectations

      expectations[location.source_directories[0]]="${
        builtins.elemAt backups.main.location.sourceDirectories 0
      }"
      expectations[location.repositories[0]]="${
        builtins.elemAt backups.main.location.repositories 0
      }"
      expectations[location.repositories[1]]="${
        builtins.elemAt backups.main.location.repositories 1
      }"
      expectations[location.one_file_system]="${
        boolToString backups.main.extraConfig.location.one_file_system
      }"
      expectations[location.exclude_patterns[0]]="${
        builtins.elemAt backups.main.extraConfig.location.exclude_patterns 0
      }"

      expectations[storage.encryption_passcommand]="${backups.main.storage.encryptionPasscommand}"
      expectations[storage.checkpoint_interval]="${
        toString backups.main.extraConfig.storage.checkpoint_interval
      }"

      expectations[retention.keep_within]="${backups.main.retention.keepWithin}"
      expectations[retention.keep_secondly]="${
        toString backups.main.retention.keepSecondly
      }"
      expectations[retention.prefix]="${backups.main.extraConfig.retention.prefix}"

      expectations[consistency.checks[0].name]="${
        (builtins.elemAt backups.main.consistency.checks 0).name
      }"
      expectations[consistency.checks[0].frequency]="${
        (builtins.elemAt backups.main.consistency.checks 0).frequency
      }"
      expectations[consistency.checks[1].name]="${
        (builtins.elemAt backups.main.consistency.checks 1).name
      }"
      expectations[consistency.checks[1].frequency]="${
        (builtins.elemAt backups.main.consistency.checks 1).frequency
      }"
      expectations[consistency.prefix]="${backups.main.extraConfig.consistency.prefix}"

      expectations[hooks.before_actions[0]]="echo Starting actions."

      yq=${pkgs.yq-go}/bin/yq

      for filter in "''${!expectations[@]}"; do
        expected_value="''${expectations[$filter]}"
        actual_value="$($yq ".$filter" $config_file)"

        if [[ "$actual_value" != "$expected_value" ]]; then
          fail "Expected '$filter' to be '$expected_value' but was '$actual_value'"
        fi
      done

      one_file_system=$($yq ".location.one_file_system" $config_file)
      if [[ $one_file_system != "true" ]]; then
         fail "Expected one_file_system to be true but it was $one_file_system"
      fi
    '';
  };
}
