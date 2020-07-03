{ config, lib, pkgs, ... }:

with lib;

let

  pinnedNixpkgs = builtins.fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/05f0934825c2a0750d4888c4735f9420c906b388.tar.gz";
    sha256 = "1g8c2w0661qn89ajp44znmwfmghbbiygvdzq0rzlvlpdiz28v6gy";
  };

  pinnedPkgs = import pinnedNixpkgs { };

in {
  config = {
    nmt.script = ''
      PATH="${with pinnedPkgs; lib.makeBinPath [ findutils nixfmt ]}:$PATH"
      cd ${../..}
      if ! ${pkgs.runtimeShell} format -c; then
        fail "${''
        Expected source code to be formatted with nixfmt but it was not.
        This error can be resolved by running the './format' in the project root directory.''}"
      fi
    '';
  };
}
