#!/bin/env fish
##################################################

# « home-manager » command-line fish completion
#
# © 2021 "Ariel AxionL" <i at axionl dot me>
#
# MIT License
#

##################################################

### Functions
function __home_manager_generations --description "Get all generations"
    for i in (home-manager generations)
        set -l split (string split " " $i)
        set -l gen_id $split[5]
        set -l gen_datetime $split[1..2]
        set -l gen_hash (string match -r '\w{32}' $i)
        echo $gen_id\t$gen_datetime $gen_hash
    end
end


### SubCommands
complete -c home-manager -n "__fish_use_subcommand" -f -a "help" -d "Print home-manager help"
complete -c home-manager -n "__fish_use_subcommand" -f -a "edit" -d "Open the home configuration in $EDITOR"
complete -c home-manager -n "__fish_use_subcommand" -f -a "option" -d "Inspect configuration option"
complete -c home-manager -n "__fish_use_subcommand" -f -a "build" -d "Build configuration into result directory"
complete -c home-manager -n "__fish_use_subcommand" -f -a "instantiate" -d "Instantiate the configuration and print the resulting derivation"
complete -c home-manager -n "__fish_use_subcommand" -f -a "switch" -d "Build and activate configuration"
complete -c home-manager -n "__fish_use_subcommand" -f -a "generations" -d "List all home environment generations"
complete -c home-manager -n "__fish_use_subcommand" -f -a "packages" -d "List all packages installed in home-manager-path"
complete -c home-manager -n "__fish_use_subcommand" -f -a "news" -d "Show news entries in a pager"
complete -c home-manager -n "__fish_use_subcommand" -f -a "uninstall" -d "Remove Home Manager"

complete -c home-manager -n "__fish_use_subcommand" -x -a "remove-generations" -d "Remove indicated generations"
complete -c home-manager -n "__fish_seen_subcommand_from remove-generations" -f -ka '(__home_manager_generations)'

complete -c home-manager -n "__fish_use_subcommand" -x -a "expire-generations" -d "Remove generations older than TIMESTAMP"

### Options
complete -c home-manager -F -s f -l "file" -d "The home configuration file"
complete -c home-manager -x -s A -d "Select an expression in the configuration file"
complete -c home-manager -F -s I -d "Add a path to the Nix expression search path"
complete -c home-manager -F -l "flake" -d "Use home-manager configuration at specified flake-uri"
complete -c home-manager -F -s b -d "Move existing files to new path rather than fail"
complete -c home-manager -f -s v -l "verbose" -d "Verbose output"
complete -c home-manager -f -s n -l "dry-run" -d "Do a dry run, only prints what actions would be taken"
complete -c home-manager -f -s h -l "help" -d "Print this help"

complete -c home-manager -x -l "arg" -d "Override inputs passed to home-manager.nix"
complete -c home-manager -x -l "argstr" -d "Like --arg but the value is a string"
complete -c home-manager -x -l "cores" -d "Threads per job (e.g. -j argument to make)"
complete -c home-manager -x -l "debug"
complete -c home-manager -x -l "impure"
complete -c home-manager -f -l "keep-failed" -d "Keep temporary directory used by failed builds"
complete -c home-manager -f -l "keep-going" -d "Keep going in case of failed builds"
complete -c home-manager -x -s j -l "max-jobs" -d "Max number of build jobs in parallel"
complete -c home-manager -x -l "option" -d "Set Nix configuration option"
complete -c home-manager -x -l "builders" -d "Remote builders"
complete -c home-manager -f -l "show-trace" -d "Print stack trace of evaluation errors"
complete -c home-manager -f -l "substitute"
complete -c home-manager -f -l "no-substitute"
complete -c home-manager -f -l "no-out-link"
