{ ... }:

{
  config = {
    home.file = {
      conflict1 = {
        source = ../home-environment;
        target = "baz";
	recursive = true;
      };
      conflict2 = {
        source = ./.;
        target = "baz";
	recursive = true;
      };
    };

    nmt.script = ''
      assertFileExists home-files/baz/target-conflict-avoided.nix;
      assertFileExists home-files/baz/session-variables.nix;
      '';
  };
}
