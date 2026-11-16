{
  imports = [ ./opencode-check-jsonschema.nix ];

  test.stubs.opencode = {
    version = "1.18.31";
    extraAttrs.passthru.jsonschema = {
      config = ./config-schema.json;
      tui = ./tui-schema.json;
    };
  };
}
