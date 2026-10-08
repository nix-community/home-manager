{ config, lib, ... }:
{
  config = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        # Stable name for dag ordering, header carries the actual pattern.
        suffixed = lib.hm.dag.entryBefore [ "tmux" ] {
          header = "Host foo foo-tmux bar bar-tmux";
          ForwardAgent = true;
        };

        tmux = {
          header = "Host *-tmux";
          RemoteCommand = "tmux attach";
        };

        # Match condition referring to a store path; cannot be expressed
        # as the attribute name because Nix forbids string context there.
        local-exec = {
          header = ''Match exec "${builtins.toFile "predicate" ''
            #!/bin/sh
            true
          ''}"'';
          IdentityFile = "~/.ssh/id_ed25519_sk";
        };
      };
    };

    home.file.assertions.text = builtins.toJSON (
      map (a: a.message) (lib.filter (a: !a.assertion) config.assertions)
    );

    nmt.script = ''
      assertFileExists home-files/.ssh/config
      assertFileContent \
        home-files/.ssh/config \
        ${./settings-header-expected.conf}
      assertFileContent home-files/assertions ${./no-assertions.json}
    '';
  };
}
