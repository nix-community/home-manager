# { lib, pkgs, ... }:
# let
#   mkVSCodeFork = import ./mkVSCodeFork.nix;
# in
# {
#   meta.maintainers = [ lib.maintainers.emaiax ];

#   imports = [
#     (mkVSCodeFork {
#       modulePath = [
#         "programs"
#         "vscode-fork"
#       ];

#       name = "VSCode";
#       package = pkgs.vscode;
#       # configDirectory = ".vscode";
#       userDirectory = "Code";
#     })
#   ];
# }
