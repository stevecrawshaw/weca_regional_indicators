"""Convert a Teams VTT transcript to plain text with speaker labels.

Strips timestamps and cue IDs, merges consecutive cues into per-speaker
paragraphs, and orders paragraphs by cue start time (so overlapping
speech / interjections split the surrounding speaker's paragraph where
Teams recorded them).

Usage:
    uv run python scripts/vtt_to_text.py <input.vtt> [output.txt]

If output.txt is omitted, writes alongside the input with a .txt suffix.
"""

import argparse
import re
from dataclasses import dataclass
from pathlib import Path

TIMESTAMP_RE = re.compile(
    r"(\d{2}:\d{2}:\d{2}\.\d{3})\s*-->\s*(\d{2}:\d{2}:\d{2}\.\d{3})"
)
VOICE_OPEN_RE = re.compile(r"<v\s+([^>]+)>")
VOICE_CLOSE_RE = re.compile(r"</v>")


@dataclass
class Cue:
    start_seconds: float
    speaker: str
    text: str


def timestamp_to_seconds(timestamp: str) -> float:
    hours, minutes, seconds = timestamp.split(":")
    return int(hours) * 3600 + int(minutes) * 60 + float(seconds)


def parse_vtt(content: str) -> list[Cue]:
    blocks = re.split(r"\n\s*\n", content.strip())
    cues: list[Cue] = []

    for block in blocks:
        lines = block.splitlines()
        timestamp_line = next((line for line in lines if "-->" in line), None)
        if timestamp_line is None:
            continue

        match = TIMESTAMP_RE.search(timestamp_line)
        if match is None:
            continue
        start_seconds = timestamp_to_seconds(match.group(1))

        text_lines = lines[lines.index(timestamp_line) + 1 :]
        raw_text = " ".join(text_lines)

        speaker_match = VOICE_OPEN_RE.search(raw_text)
        if speaker_match is None:
            continue
        speaker = speaker_match.group(1).strip()

        text = VOICE_OPEN_RE.sub("", raw_text)
        text = VOICE_CLOSE_RE.sub("", text)
        text = " ".join(text.split())
        if not text:
            continue

        cues.append(Cue(start_seconds=start_seconds, speaker=speaker, text=text))

    cues.sort(key=lambda cue: cue.start_seconds)
    return cues


def cues_to_paragraphs(cues: list[Cue]) -> str:
    paragraphs: list[str] = []
    current_speaker: str | None = None
    current_words: list[str] = []

    for cue in cues:
        if cue.speaker != current_speaker:
            if current_speaker is not None:
                paragraphs.append(f"{current_speaker}: {' '.join(current_words)}")
            current_speaker = cue.speaker
            current_words = []
        current_words.append(cue.text)

    if current_speaker is not None:
        paragraphs.append(f"{current_speaker}: {' '.join(current_words)}")

    return "\n\n".join(paragraphs)


def convert(input_path: Path, output_path: Path) -> None:
    content = input_path.read_text(encoding="utf-8")
    cues = parse_vtt(content)
    text = cues_to_paragraphs(cues)
    output_path.write_text(text, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="Path to the .vtt transcript")
    parser.add_argument(
        "output",
        type=Path,
        nargs="?",
        help="Path for the plain-text output (default: input with .txt suffix)",
    )
    args = parser.parse_args()

    output_path = args.output or args.input.with_suffix(".txt")
    convert(args.input, output_path)
    print(f"Wrote {output_path}")


if __name__ == "__main__":
    main()
