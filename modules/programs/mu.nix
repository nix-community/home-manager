{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.mu;

  # Used to generate command line arguments that mu can operate with.
  genCmdMaildir = path: "--maildir=" + path;

  # Takes the list of accounts with mu.enable = true, and generates a
  # command-line flag for initializing the mu database.
  myAddresses = let
    # Set of email account sets where mu.enable = true.
    muAccounts =
      filter (a: a.mu.enable) (attrValues config.accounts.email.accounts);
    addrs = map (a: a.address) muAccounts;
    # Construct list of lists containing email aliases, and flatten
    aliases = flatten (map (a: a.aliases) muAccounts);
    # Prefix --my-address= to each account's address AND all defined aliases
    addMyAddress = map (addr: "--my-address=" + addr) (addrs ++ aliases);
  in concatStringsSep " " addMyAddress;

in {
  meta.maintainers = [ maintainers.KarlJoad ];

  options = {
    programs.mu = {
      enable = mkEnableOption "mu, a maildir indexer and searcher";

      package = mkPackageOption pkgs "mu" { };

      # No options/config file present for mu, and program author will not be
      # adding one soon. See https://github.com/djcb/mu/issues/882 for more
      # information about this.
    };

    accounts.email.accounts = mkOption {
      type = with types;
        attrsOf
        (submodule { options.mu.enable = mkEnableOption "mu indexing"; });
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.activation.runMuInit = let
      maildirOption = genCmdMaildir config.accounts.email.maildirBasePath;
      dbLocation = config.xdg.cacheHome + "/mu";
    in hm.dag.entryAfter [ "writeBoundary" ] ''
      # If the database directory exists, then `mu init` should NOT be run.
      # In theory, mu is the only thing that creates that directory, and it is
      # only created during the initial index.
      if [[ ! -d "${dbLocation}" ]]; then
        $DRY_RUN_CMD ${
          getExe cfg.package
        } init ${maildirOption} ${myAddresses} $VERBOSE_ARG;
      fi
    '';
  };
}
