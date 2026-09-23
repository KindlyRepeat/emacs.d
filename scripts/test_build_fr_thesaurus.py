"""Run with: python3 -m unittest discover -s scripts -p 'test_*.py'."""

import importlib.util
import io
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).with_name("build-fr-thesaurus.py")
spec = importlib.util.spec_from_file_location("build_fr_thesaurus", SCRIPT)
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ConversionTests(unittest.TestCase):
    def test_utf8_words_multiple_senses_and_labels(self):
        src = io.StringIO(
            "UTF-8\nélève|2\n(Nom)|étudiant|écolier\n(Verbe)|hausse|monte\n"
            "chat|1\n(Nom)|félin\n"
        )
        result = io.StringIO()
        self.assertEqual(module.convert(src, result), 2)
        text = result.getvalue()
        self.assertIn(":élève:\n  1. (Nom)\n     étudiant, écolier\n"
                      "  2. (Verbe)\n     hausse, monte\n", text)
        self.assertIn(":chat:\n  1. (Nom)\n     félin\n", text)

    def test_invalid_and_truncated_input(self):
        for input_text in ("Latin-1\nchat|1\n(Nom)|félin\n",
                           "UTF-8\nchat|2\n(Nom)|félin\n",
                           "UTF-8\nchat|1\n(Nom)\n",
                           "UTF-8\n"):
            with self.subTest(input_text=input_text), self.assertRaises(ValueError):
                module.convert(io.StringIO(input_text), io.StringIO())

    def test_cli_invokes_dictfmt_and_dictzip(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / "thes_fr.dat"
            source.write_text("UTF-8\nété|1\n(Nom)|saison\n", encoding="utf-8")
            output_dir = root / "output"
            calls = []

            def fake_run(command, **kwargs):
                calls.append(command)
                if command[0] == "dictfmt":
                    self.assertIn(":été:\n", kwargs["stdin"].read().decode("utf-8"))
                    (output_dir / "fr-thesaurus.dict").write_text("database")
                    (output_dir / "fr-thesaurus.index").write_text("index")
                else:
                    (output_dir / "fr-thesaurus.dict").rename(
                        output_dir / "fr-thesaurus.dict.dz"
                    )

            with patch.object(sys, "argv", [str(SCRIPT), str(source), str(output_dir)]), \
                 patch.object(module.shutil, "which", return_value="/fake/binary"), \
                 patch.object(module.subprocess, "run", side_effect=fake_run), \
                 redirect_stdout(io.StringIO()):
                module.main()
            self.assertEqual(calls[0][:3], ["dictfmt", "-j", "--utf8"])
            self.assertEqual(calls[1], ["dictzip", str(output_dir / "fr-thesaurus.dict")])
            self.assertTrue((output_dir / "fr-thesaurus.dict.dz").exists())
            self.assertTrue((output_dir / "fr-thesaurus.index").exists())
            self.assertIn(":été:", (output_dir / "fr-thesaurus.txt").read_text())

    def test_full_libreoffice_file_when_available(self):
        data = Path("/tmp/emacs-thes_fr.dat")
        if not data.exists():
            self.skipTest("optional upstream data not downloaded")
        with tempfile.TemporaryFile(mode="w+", encoding="utf-8") as output:
            with data.open(encoding="utf-8") as source:
                count = module.convert(source, output)
            self.assertGreater(count, 36000)
            output.seek(0)
            text = output.read()
            self.assertIn(":à:\n  1. (Preposition)\n     chez, dans, parmi\n", text)
            self.assertIn(":abattement:\n  1. (Nom)\n", text)
            self.assertIn("  2. (nom)\n", text)


if __name__ == "__main__":
    unittest.main()
