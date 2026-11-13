{
  imports = [ ./opencode-check-jsonschema.nix ];

  test.stubs.opencode = {
    version = "2.1.1";
    extraAttrs.passthru.jsonschema = {
      cli = ./cli-schema.json;
      config = ./config-schema.json;
    };
  };
}
