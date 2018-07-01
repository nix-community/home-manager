
# { config, lib, pkgs, ... }:

# with lib;
# # with import ../lib/dag.nix { inherit lib; };

# let

#   cfg = config.programs.mailaccounts;

# in

# {

#   options = {
#     programs.notmuch = {
#       enable = mkEnableOption "Notmuch";

#     };

#   };

#   config = mkIf cfg.enable {
#     home.packages = [ notmuch ];
#   };
# }


