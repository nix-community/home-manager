{ config, ... }:

{
  config = {
    nix = {
      package = config.lib.test.mkStubPackage { };
      nixPath = [ "/a" "/b/c" ];
      keepOldNixPath = false;
    };

    nmt.script = ''
      assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
        'export NIX_PATH="/a:/b/c"'
    '';
  };
}
