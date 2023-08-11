import argparse
import json
import tempfile
import unittest

from podmactl import (
    Machine,
    MachineDict,
    diff_machines,
    PodmanMachineCommander,
)


class MachineTestCase(unittest.TestCase):
    def test_from_list_dict(self):
        """Ensure that dicts from `podman machine list` can create a machine object"""
        self.assertEqual(
            Machine(
                cpus=2, disk_size=100, memory=2048, name="indie-machine", active=True
            ),
            Machine.from_dict(
                dict(
                    CPUs=2,
                    DiskSize=100,
                    Memory=2048,
                    Name="indie-machine",
                )
            ),
        )

    def test_from_extra_dict(self):
        self.assertEqual(
            Machine(
                cpus=2, disk_size=100, memory=2048, name="indie-machine", active=True
            ),
            Machine.from_dict(
                dict(
                    cpus=2,
                    disk_size=100,
                    memory=2048,
                    name="indie-machine",
                    active=True,
                    new=True,
                    dont_exist="something",
                    something_else="ladidah",
                )
            ),
        )

    def test_from_bad_dict(self):
        """Will pass the wrong number of args to the __init__"""
        self.assertRaises(
            TypeError,
            Machine.from_dict,
            dict(
                cpus=2,
            ),
        )

    def test_make_cli_args(self):
        args = PodmanMachineCommander.make_cli_args(
            Machine(cpus=2, disk_size=50, memory=4096, name="manjaro", active=False)
        )
        self.assertEqual(
            args,
            [
                "--cpus",
                "2",
                "--disk-size",
                "50",
                "--memory",
                "4096",
            ],
        )

    def test_make_optional_cli_args(self):
        machine = Machine(
            cpus=2,
            disk_size=50,
            memory=4096,
            name="manjaro",
            active=False,
            image_path="somewhere.qcow2.xz",
        )
        self.assertEqual(
            PodmanMachineCommander.make_cli_args(machine),
            [
                "--cpus",
                "2",
                "--disk-size",
                "50",
                "--memory",
                "4096",
            ],
        )
        self.assertEqual(
            PodmanMachineCommander.make_cli_args(
                machine, PodmanMachineCommander.MACHINE_CLI_ARGS + ("image_path",)
            ),
            [
                "--cpus",
                "2",
                "--disk-size",
                "50",
                "--memory",
                "4096",
                "--image-path",
                "somewhere.qcow2.xz",
            ],
        )


class MachineDictTestCase(unittest.TestCase):
    def test_load(self):
        machine_json = {
            "cpus": 2,
            "disk_size": 100,
            "memory": 2048,
            "active": False,
        }
        machines_json = {"default": machine_json}
        with tempfile.NamedTemporaryFile(mode="w") as fp:
            json.dump(machines_json, fp)
            fp.seek(0)
            machines = MachineDict(fp.name)
            self.assertDictEqual(
                machines,
                {
                    "default": Machine(
                        cpus=2,
                        disk_size=100,
                        memory=2048,
                        name="default",
                        active=False,
                    )
                },
            )

    def test_bad_machine_load(self):
        with self.assertRaises(argparse.ArgumentTypeError):
            with tempfile.NamedTemporaryFile(mode="w") as fp:
                json.dump({"default": {}}, fp)
                fp.seek(0)
                MachineDict(fp.name)

    def test_bad_json_load(self):
        with self.assertRaises(argparse.ArgumentTypeError):
            with tempfile.NamedTemporaryFile(mode="w") as fp:
                fp.write("this is definitely not a json")
                fp.seek(0)
                MachineDict(fp.name)


class DiffTestCase(unittest.TestCase):
    def test_new_machines(self):
        diff = diff_machines(
            {
                "new": Machine(
                    cpus=1, disk_size=100, memory=1024, name="new", active=True
                ),
                "old": Machine(
                    cpus=1, disk_size=100, memory=1024, name="old", active=False
                ),
            },
            {
                "old": Machine(
                    cpus=1, disk_size=100, memory=1024, name="old", active=False
                ),
            },
        )
        self.assertListEqual(
            diff.new,
            [Machine(cpus=1, disk_size=100, memory=1024, name="new", active=False)],
        )
        self.assertListEqual(
            diff.same,
            [Machine(cpus=1, disk_size=100, memory=1024, name="old", active=False)],
        )
        self.assertListEqual(diff.removed, [])
        self.assertListEqual(diff.modified, [])

    def test_update_machine(self):
        diff = diff_machines(
            {
                "changed": Machine(
                    cpus=1, disk_size=100, memory=1024, name="changed", active=True
                ),
            },
            {
                "changed": Machine(
                    cpus=2, disk_size=100, memory=2048, name="changed", active=False
                ),
            },
        )
        self.assertListEqual(diff.new, [])
        self.assertListEqual(diff.same, [])
        self.assertListEqual(diff.removed, [])
        self.assertListEqual(
            diff.modified,
            [Machine(cpus=1, disk_size=100, memory=1024, name="changed", active=False)],
        )

    def test_remove_machine(self):
        diff = diff_machines(
            {
                "same": Machine(
                    cpus=1, disk_size=100, memory=1024, name="same", active=True
                ),
            },
            {
                "same": Machine(
                    cpus=1, disk_size=100, memory=1024, name="same", active=False
                ),
                "removed": Machine(
                    cpus=1, disk_size=100, memory=1024, name="removed", active=True
                ),
            },
        )
        self.assertListEqual(diff.new, [])
        self.assertListEqual(
            diff.same,
            [Machine(cpus=1, disk_size=100, memory=1024, name="same", active=False)],
        )
        self.assertListEqual(
            diff.removed,
            [Machine(cpus=1, disk_size=100, memory=1024, name="removed", active=False)],
        )
        self.assertListEqual(diff.modified, [])


if __name__ == "__main__":
    unittest.main()
