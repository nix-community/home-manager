{ lib, realPkgs, ... }:
{
  programs.borgmatic = {
    enable = true;
    backups.databaseOnly.settings = {
      repositories = [ { path = "/mnt/disk1"; } ];
      postgresql_databases = [ { name = "app"; } ];
    };
    backups.native.settings = lib.mkDefault (
      lib.mkMerge [
        {
          source_directories = [ "/native" ];
          repositories = [ { path = "/native-repository"; } ];
          encryption_passcommand = "pass native";
          checks = [ { name = "repository"; } ];
          keep_daily = 7;
          constants.first = "one";
        }
        { constants.second = "two"; }
      ]
    );
    backups.hm = {
      settings = {
        source_directories = [ "/hm" ];
        repositories = [ { path = "/hm-repository"; } ];
        exclude_from = [ "/native-exclude" ];
      };
      location.excludeHomeManagerSymlinks = true;
    };
    backups.hmForced = {
      settings = {
        repositories = [ { path = "/hm-repository"; } ];
        exclude_from = lib.mkForce [ ];
      };
      location.excludeHomeManagerSymlinks = true;
    };
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    config_file=$TESTED/home-files/.config/borgmatic.d/databaseOnly.yaml
    assertFileExists "$config_file"
    ${realPkgs.jq}/bin/jq --exit-status '
      (has("source_directories") | not) and
      (has("patterns") | not) and
      .postgresql_databases == [{"name": "app"}] and
      .repositories == [{"path": "/mnt/disk1"}]
    ' "$config_file"

    native=$TESTED/home-files/.config/borgmatic.d/native.yaml
    jq=${realPkgs.jq}/bin/jq

    assertFileExists $native
    $jq --exit-status '
      .source_directories == ["/native"] and
      .repositories == [{"path": "/native-repository"}] and
      .encryption_passcommand == "pass native" and
      .checks == [{"name": "repository"}] and
      .keep_daily == 7 and
      .constants == {"first": "one", "second": "two"}
    ' $native
    hm=$TESTED/home-files/.config/borgmatic.d/hm.yaml
    assertFileExists $hm
    $jq --exit-status '
      (.exclude_from | length) == 2 and .exclude_from[0] == "/native-exclude"
    ' $hm
    grep --quiet '/home/hm-user/.config/borgmatic.d/hm.yaml' "$($jq --raw-output '.exclude_from[1]' $hm)"

    hm_forced=$TESTED/home-files/.config/borgmatic.d/hmForced.yaml
    assertFileExists $hm_forced
    $jq --exit-status '.exclude_from == []' $hm_forced
  '';
}
