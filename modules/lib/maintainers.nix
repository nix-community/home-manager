# Home Manager maintainers.
#
# This attribute set contains Home Manager module maintainers that do
# not have an entry in the Nixpkgs maintainer list [1]. Entries here
# are expected to be follow the same format as described in [1].
#
# [1] https://github.com/NixOS/nixpkgs/blob/fca0d6e093c82b31103dc0dacc48da2a9b06e24b/maintainers/maintainer-list.nix#LC1

{
  justinlovinger = {
    name = "Justin Lovinger";
    email = "git@justinlovinger.com";
    github = "JustinLovinger";
    githubId = 7183441;
  };
  owm111 = {
    email = "7798336+owm111@users.noreply.github.com";
    name = "Owen McGrath";
    github = "owm111";
    githubId = 7798336;
  };
  cwyc = {
    email = "cwyc@users.noreply.github.com";
    name = "cwyc";
    github = "cwyc";
    githubId = 16950437;
  };
  svmhdvn = {
    email = "me@svmhdvn.name";
    name = "Siva Mahadevan";
    github = "svmhdvn";
    githubId = 2187906;
    keys = [{
      longkeyid = "ed25519/0xF1299E0B6ED2B95B";
      fingerprint = "5F09 212B 063A E019 946D  D00F F129 9E0B 6ED2 B95B";
    }];
  };
}
