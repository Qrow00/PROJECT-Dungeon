"""Generate class-specific dungeon-crawler voice-overs via ElevenLabs (eleven_v3).
Gets raw PCM audio from ElevenLabs, saves as OGG Vorbis.
Files saved to voice/{class_id}/{category}_{n}.ogg
"""

import os
import time

import requests
import soundfile as sf

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
VOICE_DIR = os.path.join(PROJECT_ROOT, "Audio", "Narration", "voice")
API_KEY = "sk_90a1b82840f965ee61f1529e46b17ff0fa073cf3439e59a9"
SAMPLE_RATE = 24000
EXT = ".ogg"

CLASSES = {
    "warrior": {
        "voice_id": "SOYHLrjzK2X1ezoPC6cr",
        "voice_name": "Harry (Fierce Warrior)",
        "settings": {"stability": 0.15, "similarity_boost": 0.8, "style_exaggeration": 0.7},
        "combat_action": ["Hyah!", "Die!", "Rrragh!", "Enough!"],
        "combat_hit": ["Ngh!", "Tch...", "Ghk!", "Still standing..."],
        "flee": ["Damn! Back!", "Not here!", "Live to fight another day.", "Run!"],
        "level_up": ["Heh... good.", "More.", "Yes...", "I'm not done yet."],
        "death": ["So... dark...", "Not... like this...", "The void... takes me...", "I... failed..."],
    },
    "rogue": {
        "voice_id": "N2lVS1w4EtoT3dr4eOWO",
        "voice_name": "Callum (Husky Trickster)",
        "settings": {"stability": 0.2, "similarity_boost": 0.75, "style_exaggeration": 0.6},
        "combat_action": ["Heh... gotcha.", "Quick and deadly.", "From the shadows!", "Too slow."],
        "combat_hit": ["Tsk... lucky.", "Agh... fine.", "Slippery... not bad.", "You'll pay for that."],
        "flee": ["I'll vanish.", "Not worth my time.", "Another day.", "Disappear..."],
        "level_up": ["Heh... I'm getting good.", "Smooth...", "The shadows grow deeper.", "Perfect."],
        "death": ["The dark... takes me...", "Slipped... one last time...", "Into... the void...", "My... final trick..."],
    },
    "mage": {
        "voice_id": "pqHfZKP75CvOlQylNhV4",
        "voice_name": "Bill (Wise, Mature)",
        "settings": {"stability": 0.08, "similarity_boost": 0.7, "style_exaggeration": 0.8},
        "combat_action": ["You dare challenge centuries of knowledge?", "I've destroyed empires... you're nothing.", "The void answers to ME.", "Fool... you've sealed your fate."],
        "combat_hit": ["Impudent... whelp...", "You think that hurts me?", "I've endured far worse...", "Enough of your insolence!"],
        "flee": ["This body fails me... retreat.", "I'll live to study another day.", "You may have won... this time.", "Withdraw... before I change my mind."],
        "level_up": ["The ancient knowledge... flows through me.", "Yes... I remember now...", "Centuries of wisdom... unlocked.", "The arcane secrets... revealed at last."],
        "death": ["So much... yet to learn...", "The void... welcomes me home...", "My long journey... finally ends...", "I see... the light beyond..."],
    },
    "paladin": {
        "voice_id": "onwK4e9ZLuTAKqWW03F9",
        "voice_name": "Daniel (Steady Broadcaster)",
        "settings": {"stability": 0.2, "similarity_boost": 0.75, "style_exaggeration": 0.5},
        "combat_action": ["By the light!", "Smite!", "I will prevail!", "For the light!"],
        "combat_hit": ["My faith... holds.", "I endure.", "The light... protects.", "I will not fall."],
        "flee": ["A tactical retreat.", "The light guides me away.", "I must survive.", "Another path."],
        "level_up": ["Blessed be.", "The light... strengthens me.", "I grow in faith.", "Righteous power."],
        "death": ["Into... the light...", "My watch... ends...", "The light... calls me...", "I go... to rest..."],
    },
}

CATEGORIES = ["combat_action", "combat_hit", "flee", "level_up", "death"]


def generate_line(text: str, voice_id: str, settings: dict, output_path: str) -> str:
    resp = requests.post(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format=pcm_{SAMPLE_RATE}",
        headers={"xi-api-key": API_KEY, "Content-Type": "application/json"},
        json={"text": text, "model_id": "eleven_v3", "voice_settings": settings},
        timeout=60,
    )
    resp.raise_for_status()
    pcm_data = resp.content
    import numpy as np
    samples = np.frombuffer(pcm_data, dtype=np.int16).astype(np.float32) / 32768.0
    sf.write(output_path, samples, SAMPLE_RATE, format="OGG", subtype="VORBIS")
    return output_path


def generate_all():
    total = sum(len(klass[cat]) for klass in CLASSES.values() for cat in CATEGORIES)
    total_chars = sum(len(l) for klass in CLASSES.values() for cat in CATEGORIES for l in klass[cat])
    print(f"Generating {total} voice lines ({total_chars} chars) via ElevenLabs eleven_v3 (PCM to WAV)")
    print()

    idx = 0
    for class_id, klass in CLASSES.items():
        class_dir = os.path.join(VOICE_DIR, class_id)
        os.makedirs(class_dir, exist_ok=True)
        voice_id = klass["voice_id"]
        settings = klass["settings"]
        for cat in CATEGORIES:
            for i, text in enumerate(klass[cat], 1):
                idx += 1
                filename = f"{cat}_{i}{EXT}"
                path = os.path.join(class_dir, filename)
                print(f"  [{idx}/{total}] {class_id}/{filename}: \"{text}\"", end=" ")
                t0 = time.time()
                try:
                    generate_line(text, voice_id, settings, path)
                    elapsed = time.time() - t0
                    size = os.path.getsize(path)
                    print(f"({size} bytes, {elapsed:.1f}s)")
                except Exception as e:
                    print(f"FAILED: {e}")

    print(f"\nDone! {total} files in {VOICE_DIR}/{{class}}/")


if __name__ == "__main__":
    generate_all()
