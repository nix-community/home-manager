{
  borgmatic-program-basic-configuration = ./basic-configuration.nix;
  borgmatic-program-patterns-configuration = ./patterns-configuration.nix;
  borgmatic-program-both-sourcedirectories-and-patterns =
    ./both-sourcedirectories-and-patterns.nix;
  borgmatic-program-neither-sourcedirectories-nor-patterns =
    ./neither-sourcedirectories-nor-patterns.nix;
  borgmatic-program-include-hm-symlinks = ./include-hm-symlinks.nix;
  borgmatic-program-exclude-hm-symlinks = ./exclude-hm-symlinks.nix;
  borgmatic-program-exclude-hm-symlinks-nothing-else =
    ./exclude-hm-symlinks-nothing-else.nix;
}
