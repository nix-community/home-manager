{ config, pkgs, ... }:

let
  backups = config.programs.borgmatic.backups;
  excludeFile = pkgs.writeText "excludeFile.txt" "/foo/bar";
in {
  config = {
    programs.borgmatic = {
      enable = true;
      backups = {
        main = {
          location = {
            sourceDirectories = [ "/my-stuff-to-backup" ];
            repositories = [ "/mnt/disk1" ];
            excludeHomeManagerSymlinks = true;
            extraConfig = { exclude_from = [ (toString excludeFile) ]; };
          };
        };
      };
    };

    test.stubs.borgmatic = { };

    nmt.script = ''
      config_file=$TESTED/home-files/.config/borgmatic.d/main.yaml
      assertFileExists $config_file

      declare -A expectations

      expectations[location.exclude_from[0]]="${excludeFile}"

      yq=${pkgs.yq-go}/bin/yq

      for filter in "''${!expectations[@]}"; do
        expected_value="''${expectations[$filter]}"
        actual_value="$($yq ".$filter" $config_file)"

        if [[ "$actual_value" != "$expected_value" ]]; then
          fail "Expected '$filter' to be '$expected_value' but was '$actual_value'"
        fi
      done

      hmExclusionsFile=$($yq '.location.exclude_from[1]' $config_file)
      expected_content='/home/hm-user/.config/borgmatic.d/main.yaml'

      grep --quiet "$expected_content" "$hmExclusionsFile"

      if [[ $? -ne 0 ]]; then
        echo "Expected to find $expected_content in file $hmExclusionsFile but didn't" >&2
        exit 1
      fi
    '';
  };
}
