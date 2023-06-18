{ config, pkgs, ... }:

let

  boolToString = bool: if bool then "true" else "false";
  backups = config.programs.borgmatic.backups;

in {
  programs.borgmatic = {
    enable = true;
    backups = {
      main = {
        location = {
          sourceDirectories = [ "/my-stuff-to-backup" ];
          repositories = [ "/mnt/disk1" "/mnt/disk2" ];
          extraConfig = {
            one_file_system = true;
            exclude_patterns = [ "*.swp" ];
          };
        };

        storage = {
          encryptionPasscommand = "fetch-the-password.sh";
          extraConfig = { checkpoint_interval = 200; };
        };

        retention = {
          keepWithin = "14d";
          keepSecondly = 12;
          extraConfig = { prefix = "hostname"; };
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

          extraConfig = { prefix = "hostname"; };
        };

        output = { extraConfig = { color = false; }; };

        hooks = {
          extraConfig = { before_actions = [ "echo Starting actions." ]; };
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
      boolToString backups.main.location.extraConfig.one_file_system
    }"
    expectations[location.exclude_patterns[0]]="${
      builtins.elemAt backups.main.location.extraConfig.exclude_patterns 0
    }"

    expectations[storage.encryption_passcommand]="${backups.main.storage.encryptionPasscommand}"
    expectations[storage.checkpoint_interval]="${
      toString backups.main.storage.extraConfig.checkpoint_interval
    }"

    expectations[retention.keep_within]="${backups.main.retention.keepWithin}"
    expectations[retention.keep_secondly]="${
      toString backups.main.retention.keepSecondly
    }"
    expectations[retention.prefix]="${backups.main.retention.extraConfig.prefix}"

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
    expectations[consistency.prefix]="${backups.main.consistency.extraConfig.prefix}"
    expectations[output.color]="${
      boolToString backups.main.output.extraConfig.color
    }"
    expectations[hooks.before_actions[0]]="${
      builtins.elemAt backups.main.hooks.extraConfig.before_actions 0
    }"

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
}
