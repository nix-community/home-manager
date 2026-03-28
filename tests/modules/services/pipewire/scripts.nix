{ pkgs, ... }:

let
  inherit (pkgs) writeText;

  expectedValue = ''
    print("Hello, world!")
  '';
in

{
  services.pipewire = {
    enable = true;
    wireplumber = {
      enable = true;
      scripts = {
        "foo/hello-world.lua" = expectedValue;
        "bar/hello-world.lua" = expectedValue;
      };
    };
  };

  nmt.script = ''
    local expected=${writeText "expected-wireplumber-script" expectedValue}

    local scripts=(
      'foo/hello-world.lua'
      'bar/hello-world.lua'
    )

    for script in $scripts; do
      local file="home-files/.local/share/wireplumber/scripts/$script"

      assertFileExists "$file"
      assertFileContent "$file" "$expected"
    done
  '';
}
