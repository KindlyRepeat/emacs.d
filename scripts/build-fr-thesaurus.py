#!/usr/bin/env python3
"""Convert LibreOffice's French MyThes file into a compressed DICT database.

Usage: python3 scripts/build-fr-thesaurus.py /path/to/thes_fr.dat OUTPUT_DIR
Requires dictfmt and dictzip on PATH. The source data is LGPL-2.1-or-later;
see README_thes_fr.txt distributed alongside thes_fr.dat.
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

SOURCE_URL = "https://github.com/LibreOffice/dictionaries/tree/master/fr_FR/dictionaries"
BASENAME = "fr-thesaurus"


def convert(source, destination):
    """Write dictfmt's Jargon input, preserving every MyThes sense and label."""
    encoding = source.readline().strip("\ufeff\r\n")
    if encoding.upper() != "UTF-8":
        raise ValueError(f"expected UTF-8 MyThes header, got {encoding!r}")

    destination.write("Thésaurus français (Dicollecte/Grammalecte v2.3).\n")
    destination.write("Source: " + SOURCE_URL + "\n")
    destination.write("Licence des données: LGPL-2.1-or-later.\n\n")
    entries = 0
    while header := source.readline():
        header = header.rstrip("\r\n")
        try:
            word, count = header.rsplit("|", 1)
            senses = int(count)
        except ValueError as exc:
            raise ValueError(f"invalid MyThes entry header: {header!r}") from exc
        if word.startswith(":") or senses < 1:
            raise ValueError(f"invalid MyThes entry header: {header!r}")
        # Upstream v2.3 includes one empty headword ("|1"). Consume its
        # sense, but do not create an unqueryable DICT record for it.
        if word:
            destination.write(f":{word}:\n")
        else:
            print("warning: skipping empty MyThes headword", file=sys.stderr)
        for number in range(1, senses + 1):
            raw = source.readline()
            if not raw:
                raise ValueError(f"truncated senses for {word!r}: expected {senses}")
            parts = raw.rstrip("\r\n").split("|")
            if len(parts) < 2 or not parts[0] or not any(parts[1:]):
                raise ValueError(f"invalid sense {number} for {word!r}: {raw!r}")
            # Indentation prevents dictfmt -j from interpreting body lines as
            # headwords or its special '*'/'='/'-' control lines.
            if word:
                destination.write(f"  {number}. {parts[0]}\n")
                destination.write("     " + ", ".join(filter(None, parts[1:])) + "\n")
        if word:
            destination.write("\n")
            entries += 1
    if not entries:
        raise ValueError("MyThes file contains no entries")
    return entries


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="LibreOffice thes_fr.dat")
    parser.add_argument("output_dir", type=Path, help="directory for DICT files")
    args = parser.parse_args()
    for program in ("dictfmt", "dictzip"):
        if shutil.which(program) is None:
            parser.error(f"{program} not found on PATH")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    base = args.output_dir / BASENAME
    # Keep the intermediate text for inspection or manual dictfmt reruns.
    input_file = base.with_suffix(".txt")
    try:
        with args.source.open("r", encoding="utf-8", newline="") as src, input_file.open(
            "w", encoding="utf-8", newline="\n"
        ) as dst:
            count = convert(src, dst)
        with input_file.open("rb") as src:
            subprocess.run(
                ["dictfmt", "-j", "--utf8", "-u", SOURCE_URL,
                 "-s", "Thésaurus français (Dicollecte/Grammalecte v2.3)", str(base)],
                stdin=src, check=True,
            )
        subprocess.run(["dictzip", str(base.with_suffix(".dict"))], check=True)
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        parser.exit(1, f"error: {exc}\n")
    print(f"Converted {count} entries: {base}.index and {base}.dict.dz")
    print(f"Intermediate DICT source: {input_file}")


if __name__ == "__main__":
    main()
