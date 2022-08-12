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
	    # classic example of conflict
	    conflict1 = { source = ./foo.nix; target = "baz"; };
	    conflict2 = { source = ./bar.nix; target = "baz"; };
	  }
      or
	  home.file = {
	    # missing "recursive = true"
	    conflict1 = { source = ./some-directory; target = "baz"; recursive=true;};
	    conflict2 = { source = ./other-directory; target = "baz"; };  # error here
	  }
      or
	  home.file = {
	    # conflict with at least a file among the recursively-linked directories
	    conflict1 = { source = ./some-directory; target = "baz"; recursive=true;};
	    conflict2 = { source = ./a-file.nix; target = "baz"; recursive=true;};  # error here
	  }''];

};
}
