{
  lib,
  options,
  realPkgs,
  ...
}:
let
  executeAfter = [
    "before"
    "middle"
    "after"
  ];
  rules = [
    { name = "Before"; }
    { name = "Middle"; }
    { name = "After"; }
  ];
  oldConfig = builtins.toFile "old-grobi.conf" (
    builtins.toJSON {
      execute_after = executeAfter;
      inherit rules;
    }
  );
in
{
  imports = [
    {
      services.grobi = {
        executeAfter = lib.mkBefore [ "before" ];
        rules = lib.mkBefore [ { name = "Before"; } ];
      };
    }
    {
      services.grobi = {
        executeAfter = lib.mkAfter [ "after" ];
        rules = lib.mkAfter [ { name = "After"; } ];
      };
    }
  ];

  services.grobi = {
    enable = true;
    executeAfter = [ "middle" ];
    rules = [ { name = "Middle"; } ];
  };

  test.asserts.warnings.expected = [
    "The option `services.grobi.rules' defined in ${lib.showFiles options.services.grobi.rules.files} has been renamed to `services.grobi.settings.rules'."
    "The option `services.grobi.executeAfter' defined in ${lib.showFiles options.services.grobi.executeAfter.files} has been renamed to `services.grobi.settings.execute_after'."
  ];

  nmt.script = ''
    configFile=home-files/.config/grobi.conf
    assertFileContent "$configFile" ${./legacy-settings.json}

    ${realPkgs.jq}/bin/jq --sort-keys . ${oldConfig} > old-grobi.json
    ${realPkgs.jq}/bin/jq --sort-keys . "$TESTED/$configFile" > new-grobi.json
    diff -u old-grobi.json new-grobi.json

    ${realPkgs.grobi}/bin/grobi -C "$TESTED/$configFile" rules > actual-rules
    diff -u ${builtins.toFile "legacy-grobi-rules" ''
      Before
      Middle
      After
    ''} actual-rules
  '';
}
