#!/usr/bin/env python3.11
import argparse
import json
import logging
import re
import shlex
import subprocess
import sys
from argparse import ArgumentParser

from dataclasses import asdict, dataclass, field, fields
from functools import reduce
from operator import concat
from typing import Dict, Generic, Iterable, List, Optional, TypeVar

DEFAULT_MACHINE = "podman-machine-default"
T = TypeVar("T")
logger = logging.getLogger("podman-launchd")
logger_commander = logger.getChild("commander")

CAMEL_REGEX = re.compile(r"([A-Z]+)")
UNDERSCORE_REGEX = re.compile(r"^_")


@dataclass(frozen=True)
class Machine:
    # Resource config for CLI
    cpus: int
    disk_size: int
    memory: int

    # Metadata about the machine
    name: str
    active: bool = field(compare=False, default=False)
    qemu_binary: Optional[str] = None
    """A path to a custom QEMU command to be used when starting the machine with a specific arch"""

    # Optional CLI parameters
    image_path: Optional[str] = None
    """A local path to a custom QEMU image"""

    @classmethod
    def from_dict(cls, a_dict: dict) -> "Machine":
        return Machine(
            **{
                snake_key: value
                for key, value in a_dict.items()
                if (snake_key := camel2snake(key).lower()) in MACHINE_FIELDS
            }
        )


MACHINE_FIELDS = [field.name for field in fields(Machine)]


@dataclass
class Diff(Generic[T]):
    new: List[T] = field(default_factory=list)
    modified: List[T] = field(default_factory=list)
    same: List[T] = field(default_factory=list)
    removed: List[T] = field(default_factory=list)


class PodmanMachineCommander:
    MACHINE_CLI_ARGS = ("cpus", "disk_size", "memory")

    def __init__(self, command: str = None):
        self.command = command or "podman"

    def _call(self, *args: str, **kwargs) -> str:
        """Call podman machine"""

        args_ = [self.command, "machine"] + list(args)
        logger_commander.debug("Executing %s", shlex.join(args_))

        # no subprocess.run here as streaming is necessary
        stdout_lines = []
        with subprocess.Popen(
            args_,
            # Capture both streams in stdout
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            **kwargs,
        ) as process:
            # Collect stdout+stderr and steam if requested
            for line in process.stdout:
                line_str = line.decode().rstrip()
                stdout_lines.append(line_str)
                logger_commander.debug(line_str)

        stdout = "\n".join(stdout_lines)
        # Check if the command failed
        if (return_code := process.returncode) != 0:
            print(stdout, file=sys.stderr)
            raise subprocess.CalledProcessError(return_code, args_, stdout)

        return stdout

    def _call_json(self, *args: str, **kwargs) -> dict:
        """Call podman requesting JSON output and interpret it as such"""
        return json.loads(self._call(*args, "--format", "json", **kwargs))

    @classmethod
    def make_cli_args(
        cls, machine: Machine, selected_args: Iterable[str] = MACHINE_CLI_ARGS
    ):
        """
        Converts dict from list of key-value pair
        to list of ["--key1", value1, "--key2", value2, ... ]
        """
        machine_dict = asdict(machine)
        return reduce(
            concat,
            [
                [("--" + key.replace("_", "-")), str(value)]
                for key in selected_args
                if (value := machine_dict.get(key))
            ],
            [],
        )

    def get_active_machine_name(self) -> str:
        """Name of the machine that is currently running"""
        output_json = self._call_json("info")
        return output_json.get("Host", {}).get("CurrentMachine")

    def list(self) -> Dict[str, Machine]:
        """Get all machines known to podman"""
        machine_jsons = self._call_json("list")
        if not isinstance(machine_jsons, list):
            raise ValueError("Unexpected output from command", machine_jsons)

        # `podman machine list` has different units for disk_size, memory, etc.
        # `podman machine inspect` has the information we need
        inspected_jsons = self.inspect(
            *[listed_machine["Name"] for listed_machine in machine_jsons]
        )
        return {
            machine.name: machine
            for inspected_json in inspected_jsons
            if (
                machine := Machine.from_dict(
                    {"name": inspected_json["Name"], **inspected_json["Resources"]}
                )
            )
        }

    def inspect(self, *machine_names: str):
        """Get information about a machine from podman"""
        # The podman machine interface is really confusing
        # inspect only returns JSON and other commands require --format json
        return json.loads(self._call("inspect", *machine_names))

    def add(self, machine: Machine):
        """
        Let podman create a machine's config and initialize it
        Also downloads the image of the machine
        """
        self._call(
            "init",
            *self.make_cli_args(machine, self.MACHINE_CLI_ARGS + ("image_path",)),
            machine.name,
        )

    def update(self, machine: Machine):
        """Update a machine's configuration and write it to disk"""
        self._call("set", *self.make_cli_args(machine), machine.name)

        # Set the custom QEMU path in the machine's config
        # This is necessary for running machines with a specific architecture
        if machine.qemu_binary:
            inspection = self.inspect(machine.name)[0]
            config_path = inspection.get("ConfigPath", {}).get("Path", {})

            with open(config_path) as config_file:
                config = json.load(config_file)

            if not (cmd_line := config.get("CmdLine")):
                logger.error(
                    "Cannot find CmdLine in config of %s at", machine.name, config_path
                )
            cmd_line[0] = machine.qemu_binary

            with open(config_path, mode="w") as config_file:
                json.dump(config, config_file)

    def remove(self, machine: Machine):
        """Kills and removes the machine"""
        self._call("rm", "--force", machine.name)

    def start(self, machine_name: str):
        """Start up a machine"""
        self._call("start", machine_name)

    def stop(self, machine_name: str):
        """Stop a running machine"""
        self._call("stop", machine_name)


def main(
    requested_machines: Dict[str, Machine],
    podman_command: str,
):
    """
    :param requested_machines: Which machines should exist on the host
    :param podman_command: The path to or the podman command itself
    """
    podman_command = podman_command or "podman"
    commander = PodmanMachineCommander(podman_command)
    active_machines = [
        name for name, machine in requested_machines.items() if machine.active
    ]
    if len(active_machines) != 1:
        raise ValueError("Exactly one machine in the configuration should be active")
    requested_active = active_machines[0]

    old_machines = commander.list()
    # Find machines to add, update, delete
    diffs = diff_machines(requested_machines, old_machines)

    # Init new machines
    for new_machine in diffs.new:
        logger.info("Adding machine: %s. This may take some time...", new_machine.name)
        commander.add(new_machine)
    # Init the default machine if it's not

    # Delete old ones
    for removed_machine in diffs.removed:
        logger.info("Removing machine: %s", removed_machine.name)
        commander.remove(removed_machine)

    # Update configuration of qemuBinary if necessary
    for mod_machine in diffs.modified:
        logger.info("Updating machine: %s", mod_machine.name)
        commander.update(mod_machine)

    # Start the requested machine if it isn't already running
    active_machine = commander.get_active_machine_name()
    if active_machine != requested_active:
        if active_machine:
            logger.info("Stopping machine: %s", active_machine)
            commander.stop(active_machine)
        logger.info("Starting: %s", requested_active)
        commander.start(requested_active)

    logger.info("%s is active and podman is ready to be used")


def camel2snake(camel: str) -> str:
    """
    Converts camelCase to snake_case
    """
    snake = CAMEL_REGEX.sub(r"_\1", camel).lower()
    # if snake starts with _ remove it
    return UNDERSCORE_REGEX.sub("", snake)


def diff_machines(
    requested_machines: Dict[str, Machine], old_machines: Dict[str, Machine]
) -> Diff[Machine]:
    diff: Diff[Machine] = Diff()
    requested_names = requested_machines.keys()
    old_names = old_machines.keys()
    requested_items = requested_machines.items()
    old_items = old_machines.items()
    diff.new = [requested_machines[name] for name in (requested_names - old_names)]
    diff.removed = [old_machines[name] for name in (old_names - requested_names)]
    diff.same = list(dict(old_items & requested_items).values())

    # Find modified machines = same key, different Machine
    diff.modified = [
        requested_machines[key]
        for key in (requested_names & old_names)
        if requested_machines[key] != old_machines[key]
    ]

    return diff


def MachineDict(json_path: str) -> dict:
    try:
        with open(json_path) as json_file:
            loaded_json = json.load(json_file)
        return {
            name: Machine.from_dict({"name": name, **machine})
            for name, machine in loaded_json.items()
        }
    except json.JSONDecodeError as decode_error:
        raise argparse.ArgumentTypeError() from decode_error
    except Exception as exc:
        raise argparse.ArgumentTypeError() from exc


if __name__ == "__main__":
    parser = ArgumentParser(
        "podman-launchd", description="CRUDs pod machines and starts one"
    )

    parser.add_argument(
        "machines",
        help="Path to JSON configuration of machines that should be on this host",
        type=MachineDict,
    )
    parser.add_argument(
        "-p", "--podman", help="Name or path of the podman command to use"
    )
    parser.add_argument(
        "--verbose", help="Activate verbose logging", action="store_true"
    )
    cmd_args = parser.parse_args()
    logging.basicConfig(level=logging.DEBUG if cmd_args.verbose else logging.INFO)

    try:
        main(cmd_args.machines, cmd_args.podman)
    except:
        logger.exception("Couldn't complete command")
        exit(1)
