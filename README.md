# Jarvis Flutter Starter (Android)

**At your service, Boss.** Ye ek minimal Flutter project template hai for a Jarvis-style assistant — ready to upload to GitHub and build on Codemagic.

## What's included
- `lib/main.dart` — simple chat UI + placeholders for OpenAI API, speech-to-text, and TTS.
- `pubspec.yaml` — dependencies (http, flutter_tts, speech_to_text).
- `.gitignore`

## How to use
1. Extract this folder and `git init` / create a GitHub repo, push all files.
2. On Codemagic, connect your GitHub repo and set up a Flutter build workflow (target: Android APK or AAB).
3. **Add your OpenAI API key securely**:
   - On Codemagic: In Project settings -> Environment variables, add `OPENAI_API_KEY` (secure, not exposed).
   - Locally for testing: create a file `assets/.env` **(don't commit)** and add `OPENAI_API_KEY=sk-...` and load it in code if you want local testing.
4. Configure Android signing in Codemagic (if you want a release-signed APK).

## Notes & Limitations
- This is a starter template — you'll need to refine prompts, error handling, add streaming, and follow OpenAI usage policies.
- Speech-to-text and TTS use common Flutter plugins — on some devices you'll need to grant microphone permissions.
- Replace the placeholder `callOpenAI` implementation with your own preferred OpenAI endpoint and model.

## Files of interest
- `lib/main.dart` — main app
- `pubspec.yaml` — dependencies
- `README.md` — you're reading it

## Licence
Use freely. Attribution appreciated but not required.
