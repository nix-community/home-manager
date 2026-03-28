{ pkgs, ... }:

let
  jsonFormat = pkgs.formats.json { };

  expectedValue = {
    "foo.bar" = {
      "baz.qux" = true;
    };
    "baz.qux" = {
      "foo.bar" = false;
    };
  };
in

{
  services.pipewire = rec {
    enable = true;
    configs = {
      "10-test" = expectedValue;
      "11-test" = expectedValue;
    };

    clientConfigs = configs;
    jackConfigs = configs;
    pulseConfigs = configs;

    wireplumber = {
      enable = true;
      configs = configs;
    };
  };

  nmt.script = ''
    local expected=${jsonFormat.generate "expected-pipewire-config" expectedValue}

    local names=(
      '10-test.conf'
      '11-test.conf'
    )

    local subdirs=(
      'pipewire/pipewire.conf.d'
      'pipewire/client.conf.d'
      'pipewire/jack.conf.d'
      'pipewire/pipewire-pulse.conf.d'
      'wireplumber/wireplumber.conf.d'
    )

    for subdir in $subdirs; do
      for name in $names; do
        local file="home-files/.config/$subdir/$name"

        assertFileExists "$file"
        assertFileContent "$file" "$expected"
      done
    done
  '';
}
