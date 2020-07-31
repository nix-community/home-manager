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
  olmokramer = {
    name = "Olmo Kramer";
    email = "olmokramer@users.noreply.github.com";
    github = "olmokramer";
    githubId = 3612514;
  };
  matrss = {
    name = "Matthias Riße";
    email = "matrss@users.noreply.github.com";
    github = "matrss";
    githubId = 9308656;
  };
  seylerius = {
    email = "sable@seyleri.us";
    name = "Sable Seyler";
    github = "seylerius";
    githubId = 1145981;
    keys = [{
      logkeyid = "rsa4096/0x68BF2EAE6D91CAFF";
      fingerprint = "F0E0 0311 126A CD72 4392  25E6 68BF 2EAE 6D91 CAFF";
    }];
  };
}
