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
          patterns = [
            "R /home/user"
            "+ home/user/stuff-to-backup"
            "+ home/user/junk/important-file"
            "- home/user/junk"
          ];
          repositories = [ "/mnt/backup-drive" ];
        };
      };
    };
  };

  test.stubs.borgmatic = { };

  nmt.script = ''
    config_file=$TESTED/home-files/.config/borgmatic.d/main.yaml
    assertFileExists $config_file

    declare -A expectations

    expectations[patterns[0]]="${
      builtins.elemAt backups.main.location.patterns 0
    }"
    expectations[patterns[1]]="${
      builtins.elemAt backups.main.location.patterns 1
    }"
    expectations[patterns[2]]="${
      builtins.elemAt backups.main.location.patterns 2
    }"
    expectations[patterns[3]]="${
      builtins.elemAt backups.main.location.patterns 3
    }"

    yq=${pkgs.yq-go}/bin/yq

    for filter in "''${!expectations[@]}"; do
      expected_value="''${expectations[$filter]}"
      actual_value="$($yq ".$filter" $config_file)"

      if [[ "$actual_value" != "$expected_value" ]]; then
        fail "Expected '$filter' to be '$expected_value' but was '$actual_value'"
      fi
    done
  '';
}
