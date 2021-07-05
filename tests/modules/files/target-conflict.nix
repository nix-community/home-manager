{ ... }:

{
  config = {
    home.file = {
      conflict1 = {
        text = "";
        target = "baz";
      };
      conflict2 = {
        source = ./target-conflict.nix;
        target = "baz";
      };
    };

    test.asserts.assertions.expected = [''
      Conflicting managed target files: baz

      This may happen, for example, if you have a configuration similar to

          home.file = {
            conflict1 = { source = ./foo.nix; target = "baz"; };
            conflict2 = { source = ./bar.nix; target = "baz"; };
          }''];
  };
}
