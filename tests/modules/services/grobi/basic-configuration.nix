{
  config,
  lib,
  realPkgs,
  ...
}:
{
  imports = [
    {
      services.grobi.settings = {
        execute_after = lib.mkBefore [ "before" ];
        rules = lib.mkBefore [
          {
            name = "Before";
            configure_single = "eDP-1";
          }
        ];
      };
    }
    {
      services.grobi.settings = {
        execute_after = lib.mkAfter [ "after" ];
        rules = lib.mkAfter [
          {
            name = "After";
            configure_single = "HDMI-1";
          }
        ];
      };
    }
  ];

  services.grobi = {
    enable = true;
    settings = {
      arbitrary = {
        enabled = true;
        nested = [
          1
          "two"
          null
        ];
      };
      execute_after = [ "middle" ];
      on_failure = [ "notify-send 'Grobi failed'" ];
      rules = [
        {
          name = "Middle";
          configure_single = "DP-1";
          arbitrary_rule.nested = true;
        }
      ];
    };
  };

  assertions =
    let
      expected = builtins.fromJSON (builtins.readFile ./basic-configuration.json);
    in
    [
      {
        assertion = config.services.grobi.executeAfter == expected.execute_after;
        message = "The executeAfter alias must read canonical ordered commands.";
      }
      {
        assertion = config.services.grobi.rules == expected.rules;
        message = "The rules alias must read canonical ordered rules.";
      }
    ];

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    configFile=home-files/.config/grobi.conf
    assertFileContent "$configFile" ${./basic-configuration.json}

    ${realPkgs.grobi}/bin/grobi -C "$TESTED/$configFile" rules > actual-rules
    diff -u ${builtins.toFile "grobi-rules" ''
      Before
      Middle
      After
    ''} actual-rules
  '';
}
