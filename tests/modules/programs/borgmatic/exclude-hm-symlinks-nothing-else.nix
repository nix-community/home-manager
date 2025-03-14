{ realPkgs, ... }:

{
  programs.borgmatic = {
    enable = true;
    backups = {
      main = {
        location = {
          sourceDirectories = [ "/my-stuff-to-backup" ];
          repositories = [ "/mnt/disk1" ];
          excludeHomeManagerSymlinks = true;
        };
      };
    };
  };

  nmt.script = ''
    config_file=$TESTED/home-files/.config/borgmatic.d/main.yaml
    assertFileExists $config_file

    yq=${realPkgs.yq-go}/bin/yq

    hmExclusionsFile=$($yq '.exclude_from[0]' $config_file)
    expected_content='/home/hm-user/.config/borgmatic.d/main.yaml'

    grep --quiet "$expected_content" "$hmExclusionsFile"

    if [[ $? -ne 0 ]]; then
      echo "Expected to find $expected_content in file $hmExclusionsFile but didn't" >&2
      exit 1
    fi
  '';
}
