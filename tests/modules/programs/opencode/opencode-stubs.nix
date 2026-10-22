{
  imports = [ ./opencode-check-jsonschema.nix ];

  test.stubs.opencode = {
    extraAttrs.passthru.jsonschema = {
      config = ./config-schema.json;
      tui = ./tui-schema.json;
    };
  };
}
