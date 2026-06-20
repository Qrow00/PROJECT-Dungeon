"""Generate essential room narration WAV files via OmniVoice HTTP API.

Usage:
    1. Start omnivoice-server:   omnivoice-server --port 8880 --num-step 16 --timeout 300
    2. Run:                       python tools/generate_omnivoice_audio.py
    3. Files saved to Audio/Narration/hash/
"""

import hashlib
import os
import time

import requests
import torch

torch.set_num_threads(12)

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
HASH_DIR = os.path.join(PROJECT_ROOT, "Audio", "Narration", "hash")
SERVER_URL = "http://localhost:8880/v1/audio/speech"
VOICE = "onyx"
EXT = ".wav"

ROOM_NARRATIONS = {
    "MONSTER": [
        "You hear guttural growls ahead. Something hungry waits in the dark.",
        "The stench of blood and fur fills the air. Lair ahead.",
        "Shadows shift and move. You are not alone in this chamber.",
        "Eyes gleam from the darkness. Teeth drip with anticipation.",
        "The floor is strewn with bones. The inhabitants are near.",
    ],
    "TREASURE": [
        "A glittering pile catches the torchlight. Riches beyond measure.",
        "Gold coins spill from ancient chests. A dragon's hoard, long forgotten.",
        "The room glows with a warm golden hue. Treasure awaits.",
        "Jewels and gemstones crunch underfoot. This place is a vault.",
        "Ancient coins bear the marks of a long-dead kingdom.",
    ],
    "REST": [
        "A crackling fire casts dancing shadows. The air is safe and warm.",
        "Ancient runes on the walls pulse with a gentle light. Peace at last.",
        "Stone benches surround a dying ember. A moment to catch your breath.",
        "The quiet is almost unsettling after the horrors above.",
        "Fresh water trickles down the wall. A small mercy in this dark place.",
    ],
    "EVENT": [
        "The air hums with arcane energy. Strange symbols cover every surface.",
        "A pedestal stands in the center, pulsing with an inner light.",
        "The walls are covered in murals depicting a great battle.",
        "You feel a presence watching from beyond the veil.",
        "Ghostly whispers echo through the chamber, speaking in forgotten tongues.",
    ],
    "SHOP": [
        "A hooded figure tends a stall of oddities in the middle of nowhere.",
        "The merchant's eyes gleam with knowing. \"Looking for something special?\"",
        "Strange bottles and weapons line the shelves. A traveling merchant's cart.",
        "\"Not many make it this far, friend. Take a look.\"",
        "The merchant's wares glow with an unnatural light. Curiosity pulls you closer.",
    ],
    "BOSS": [
        "The air grows heavy and cold. A malevolent presence stirs ahead.",
        "This is the lair of something ancient and terrible. You feel it watching.",
        "The walls pulse with a dark heartbeat. The boss awaits its challenger.",
        "Pressure builds in your chest. The very dungeon groans in anticipation.",
        "Deep, rhythmic breathing echoes through the chamber. You have arrived.",
    ],
    "MINIBOSS": [
        "A powerful aura radiates from beyond the door. An elite guardian stands ready.",
        "The floor trembles slightly. Something big patrols these halls.",
        "Challenger marks are scratched into the stone. A warrior's room.",
        "You hear the sharpening of steel. A deadly foe prepares.",
    ],
    "SECRET": [
        "The wall sounds hollow. Your fingers find a hidden catch.",
        "A draft whispers through a hairline crack. There's more here than meets the eye.",
        "You notice the mortar is newer here. Something was sealed away.",
        "Your torch flickers as a hidden passage is revealed behind the tapestry.",
    ],
}

ROOM_DESCRIPTIONS = [
    "You hear growling ahead. Something lurks in the shadows...",
    "Glittering light reflects off piles of gold and trinkets.",
    "A warm glow emanates from an ancient brazier. The air is calm.",
    "Strange symbols cover the walls. The air hums with energy.",
    "A hooded figure tends a stall of curious wares.",
    "The air grows heavy. A massive presence awaits...",
    "The wall seems... wrong. You feel a hidden space beyond.",
]


def text_hash(text: str) -> str:
    return hashlib.md5(text.strip().encode("utf-8")).hexdigest()


def generate_tts(text: str, output_path: str):
    payload = {
        "model": "omnivoice",
        "input": text,
        "voice": VOICE,
        "response_format": "wav",
        "num_step": 16,
        "request_timeout_s": 300,
    }
    for attempt in range(5):
        try:
            resp = requests.post(SERVER_URL, json=payload, timeout=360)
            resp.raise_for_status()
            with open(output_path, "wb") as f:
                f.write(resp.content)
            return
        except requests.exceptions.RequestException as e:
            print(f"    -> Attempt {attempt+1}/5 failed: {e}")
            if attempt < 4:
                wait = 15 * (attempt + 1)
                print(f"    -> Retrying in {wait}s...")
                time.sleep(wait)
    raise RuntimeError(f"Failed after 5 attempts: {text[:60]}")


def generate_all():
    os.makedirs(HASH_DIR, exist_ok=True)

    all_texts = list(ROOM_DESCRIPTIONS)
    for lines in ROOM_NARRATIONS.values():
        all_texts.extend(lines)

    total = len(all_texts)
    print(f"Generating {total} narration files ({VOICE} voice, {VOICE} voice)")
    print(f"Torch threads: {torch.get_num_threads()}")
    print(f"Output: {HASH_DIR}")
    print()

    for i, text in enumerate(all_texts, 1):
        h = text_hash(text)
        path = os.path.join(HASH_DIR, f"{h}{EXT}")
        if os.path.exists(path):
            print(f"  [{i}/{total}] EXISTS — {text[:60]}...")
            continue
        print(f"  [{i}/{total}] Generating: {text[:60]}...", end=" ")
        t0 = time.time()
        generate_tts(text, path)
        elapsed = time.time() - t0
        size = os.path.getsize(path)
        print(f"({size} bytes, {elapsed:.1f}s)")

    print(f"\nDone! {total} files in {HASH_DIR}")
    existing = sum(1 for text in all_texts if os.path.exists(os.path.join(HASH_DIR, f"{text_hash(text)}{EXT}")))
    print(f"Generated: {existing}/{total}")


if __name__ == "__main__":
    generate_all()
