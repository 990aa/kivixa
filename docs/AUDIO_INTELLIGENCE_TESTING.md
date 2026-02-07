# Audio Intelligence Manual Testing Guide

This document provides comprehensive manual testing procedures for the Audio Intelligence module in Kivixa. Each feature should be tested thoroughly before release.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Neural Input Bar](#neural-input-bar)
3. [Voice Note Block](#voice-note-block)
4. [Voice Search](#voice-search)
5. [Walkie-Talkie Mode](#walkie-talkie-mode)
6. [Read Aloud / TTS](#read-aloud--tts)
7. [Audio Settings](#audio-settings)
8. [Quick Notes (Thought Catcher)](#quick-notes-thought-catcher)
9. [Waveform Visualization](#waveform-visualization)
10. [Edge Cases](#edge-cases)
11. [Performance Testing](#performance-testing)

---

## Prerequisites

### Environment Setup

- [ ] Microphone access enabled (system permissions)
- [ ] Speaker/headphone output working
- [ ] Device running Android 8+ / Windows 10+
- [ ] At least 500MB free storage for models
- [ ] Stable internet connection (for initial model download)

### Model Verification

Before testing, verify the Rust backend is properly initialized:

```dart
final engine = AudioNeuralEngine();
final success = await engine.initialize();
assert(success, 'AudioNeuralEngine failed to initialize');
```

---

## Neural Input Bar

### Component: `NeuralInputBar` / `NeuralDictationBar`

#### Test Case NIB-001: Basic Dictation

**Steps:**
1. Open a text field with `NeuralInputBar` attached
2. Tap the microphone button
3. Speak clearly: "Hello world, this is a test"
4. Observe real-time transcription appearing
5. Stop speaking and wait for finalization (2-3s silence)

**Expected:**
- [ ] Mic button shows recording state (pulsing animation)
- [ ] Waveform visualization appears and responds to voice
- [ ] Ghost text appears during transcription (semi-transparent)
- [ ] Text becomes solid when finalized
- [ ] Text is inserted at cursor position

#### Test Case NIB-002: Glassmorphism UI

**Steps:**
1. Open the `NeuralInputBar` widget
2. Observe the visual styling
3. Scroll content behind the bar (if applicable)

**Expected:**
- [ ] Bar has frosted glass effect (BackdropFilter blur)
- [ ] Content behind is visible but blurred
- [ ] Border is subtle and visible
- [ ] Colors adapt to theme (light/dark mode)

#### Test Case NIB-003: Ghost Text and Alternatives

**Steps:**
1. Start dictation
2. Observe interim transcription
3. Complete dictation
4. Look for alternative interpretations (if available)

**Expected:**
- [ ] Ghost text shows unconfirmed words in italics
- [ ] Alternatives sheet accessible (swipe up or button)
- [ ] Selecting alternative replaces current text

#### Test Case NIB-004: Bezier Waveform Animation

**Steps:**
1. Activate recording
2. Vary voice volume (whisper to loud)
3. Observe waveform behavior

**Expected:**
- [ ] Smooth Bezier curves (Siri-style)
- [ ] Amplitude responds to voice intensity
- [ ] Animation is fluid (no jank)
- [ ] Colors match theme accent

#### Test Case NIB-005: Command Mode Toggle

**Steps:**
1. Enable command mode in settings
2. Start dictation
3. Say "Open settings"
4. Observe response

**Expected:**
- [ ] Visual indicator shows command mode active
- [ ] Commands are processed, not inserted as text
- [ ] Toggle between command/dictation modes works

---

## Voice Note Block

### Component: `VoiceNoteBlock` / `VoiceNoteCard`

#### Test Case VNB-001: Recording Voice Note

**Steps:**
1. Tap "New Voice Note" or mic icon
2. Record for 15-30 seconds with varied speech
3. Stop recording
4. Observe saved note

**Expected:**
- [ ] Recording timer visible during capture
- [ ] Waveform shows during recording
- [ ] Note saved with correct duration
- [ ] Audio playback works

#### Test Case VNB-002: Playback Controls

**Steps:**
1. Open an existing voice note
2. Play the audio
3. Test: play, pause, seek (scrub)
4. Test playback speed options (if available)

**Expected:**
- [ ] Play/pause button toggles correctly
- [ ] Scrubbing updates position immediately
- [ ] Time display shows current/total duration
- [ ] Speed changes are audible

#### Test Case VNB-003: Speaker Diarization

**Steps:**
1. Record a voice note with multiple speakers (or simulate)
2. Wait for transcription processing
3. View the transcript

**Expected:**
- [ ] Different speakers are color-coded
- [ ] Speaker labels show (Speaker 1, Speaker 2, etc.)
- [ ] Waveform segments colored by speaker
- [ ] Transcript shows speaker attribution

#### Test Case VNB-004: Karaoke Mode Highlighting

**Steps:**
1. Open a transcribed voice note
2. Play the audio
3. Observe transcript highlighting

**Expected:**
- [ ] Current word/sentence highlighted in real-time
- [ ] Highlight syncs with audio playback
- [ ] Tapping a word seeks to that position
- [ ] Smooth transitions between words

#### Test Case VNB-005: Skip Silence Feature

**Steps:**
1. Record a voice note with deliberate pauses (3-5s)
2. Enable "Skip Silence" option
3. Play the recording

**Expected:**
- [ ] Long pauses are automatically skipped
- [ ] Total playback time reduced
- [ ] Speech sections seamlessly connected
- [ ] Toggle to disable works

---

## Voice Search

### Component: `VoiceSearch`

#### Test Case VS-001: Inline Mic Button

**Steps:**
1. Focus on a search field with voice search enabled
2. Tap the microphone icon in the search bar
3. Speak a search query

**Expected:**
- [ ] Mic icon visible and accessible
- [ ] Recording indicator appears when active
- [ ] Query populates search field
- [ ] Search executes on finalization

#### Test Case VS-002: Vector/Semantic Search

**Steps:**
1. Ensure semantic search is enabled
2. Perform a voice search with natural language
3. E.g., "Find notes about project deadlines"

**Expected:**
- [ ] Results show semantic matches, not just keyword
- [ ] Relevance scoring visible (if UI supports)
- [ ] Results include similar concepts

#### Test Case VS-003: Audio Snippet Preview

**Steps:**
1. Search for content that includes voice notes
2. View search results
3. Tap preview on a voice note result

**Expected:**
- [ ] Mini audio preview available
- [ ] Preview plays relevant section
- [ ] Full playback accessible from preview

---

## Walkie-Talkie Mode

### Component: `WalkieTalkieMode` / `WalkieTalkieScreen`

#### Test Case WTM-001: Activation and Exit

**Steps:**
1. Navigate to walkie-talkie mode (button or gesture)
2. Verify full-screen mode activates
3. Test exit button/gesture

**Expected:**
- [ ] Screen becomes full-screen immersive
- [ ] Animated background appears
- [ ] Close button/gesture works

#### Test Case WTM-002: Dual Animated Orbs

**Steps:**
1. Observe the UI in idle state
2. Start speaking (user orb activates)
3. Wait for AI response (AI orb activates)

**Expected:**
- [ ] User orb (bottom) pulses when speaking
- [ ] AI orb (center/top) animates when AI speaks
- [ ] Distinct visual states for each
- [ ] Smooth transitions between states

#### Test Case WTM-003: Voice Activity Detection

**Steps:**
1. In walkie-talkie mode, stay silent
2. Start speaking naturally
3. Pause for 2-3 seconds
4. Continue speaking

**Expected:**
- [ ] Idle → User Speaking transition automatic
- [ ] No button press required to start
- [ ] Silence detection ends turn appropriately
- [ ] Short pauses don't end turn prematurely

#### Test Case WTM-004: Instant Interruption

**Steps:**
1. Initiate a conversation to get AI response
2. While AI is speaking, tap anywhere or start talking
3. Observe behavior

**Expected:**
- [ ] AI speech stops immediately
- [ ] "Tap to interrupt" hint visible during AI speech
- [ ] System returns to listening state
- [ ] No audio overlap

#### Test Case WTM-005: Streaming TTS Response

**Steps:**
1. Ask a question requiring long response
2. Observe AI speaking

**Expected:**
- [ ] Speech starts before full response generated
- [ ] Natural pacing and prosody
- [ ] Latency from question end to speech start < 2s

#### Test Case WTM-006: Conversation History

**Steps:**
1. Have multi-turn conversation
2. Access history view (button/swipe)

**Expected:**
- [ ] All turns recorded
- [ ] User vs AI messages distinguished
- [ ] Timestamps accurate
- [ ] Scrollable history

---

## Read Aloud / TTS

### Component: `ReadAloud` / `ReadAloudPanel` / `ReadAloudMiniPlayer`

#### Test Case RA-001: Basic Text-to-Speech

**Steps:**
1. Select text in a document
2. Tap "Read Aloud" option
3. Listen to speech output

**Expected:**
- [ ] Speech starts within 1 second
- [ ] Natural voice quality (Kokoro TTS)
- [ ] Correct pronunciation
- [ ] Proper pacing and intonation

#### Test Case RA-002: Sentence-Level Highlighting

**Steps:**
1. Start read aloud on a multi-sentence text
2. Watch the text while listening

**Expected:**
- [ ] Current sentence highlighted
- [ ] Highlight moves with speech
- [ ] Previous sentence unhighlights
- [ ] Tapping sentence seeks to it

#### Test Case RA-003: Floating Mini-Player

**Steps:**
1. Start read aloud
2. Navigate away from page (if applicable)
3. Observe mini-player

**Expected:**
- [ ] Mini-player appears at bottom
- [ ] Shows current sentence snippet
- [ ] Play/pause controls work
- [ ] Skip forward/back (10s) works
- [ ] Close button stops playback

#### Test Case RA-004: Playback Speed Control

**Steps:**
1. Start read aloud
2. Open speed options
3. Test: 0.5x, 1.0x, 1.5x, 2.0x

**Expected:**
- [ ] Speed changes take effect immediately
- [ ] Speech remains intelligible at all speeds
- [ ] Highlighting still syncs correctly

#### Test Case RA-005: Auto-Scroll Following

**Steps:**
1. Start read aloud on long document
2. Let playback progress beyond viewport

**Expected:**
- [ ] View auto-scrolls to keep current sentence visible
- [ ] Scroll is smooth, not jarring
- [ ] Manual scroll temporarily pauses auto-scroll

---

## Audio Settings

### Component: `AudioSettingsPage`

#### Test Case AS-001: Model Tab Display

**Steps:**
1. Navigate to Audio Settings
2. Select "Models" tab

**Expected:**
- [ ] STT models listed with names and sizes
- [ ] TTS models listed separately
- [ ] Download status shown (Available/Downloaded/Active)
- [ ] Quality badges visible (TINY, BASE, SMALL, etc.)

#### Test Case AS-002: Model Download

**Steps:**
1. Find a model not yet downloaded
2. Tap download button
3. Wait for completion

**Expected:**
- [ ] Progress indicator appears
- [ ] Progress percentage accurate
- [ ] Download can be cancelled
- [ ] Model marked as ready after completion

#### Test Case AS-003: Model Selection

**Steps:**
1. With multiple models downloaded
2. Tap to select a different model
3. Verify change takes effect

**Expected:**
- [ ] Selection indicator moves
- [ ] Active model card highlighted
- [ ] Subsequent transcription uses new model

#### Test Case AS-004: Voice Selection

**Steps:**
1. Go to "Voices" tab
2. Browse available voices
3. Preview a voice
4. Select a different voice

**Expected:**
- [ ] Voice cards show name, language, gender
- [ ] Preview plays sample audio
- [ ] Selection persists
- [ ] TTS uses selected voice

#### Test Case AS-005: Settings Persistence

**Steps:**
1. Change multiple settings
2. Close app completely
3. Reopen and check settings

**Expected:**
- [ ] All settings preserved
- [ ] Selected model active
- [ ] Selected voice active
- [ ] VAD/sensitivity settings unchanged

---

## Quick Notes (Thought Catcher)

### Component: `ThoughtCatcher` / `QuickNotesList`

#### Test Case QN-001: Long-Press Activation

**Steps:**
1. Find the floating mic button
2. Long-press and hold
3. Speak a thought
4. Release

**Expected:**
- [ ] Button pulse animation on hold
- [ ] Recording indicator appears
- [ ] Live transcription shown
- [ ] Note saved on release

#### Test Case QN-002: Background Transcription

**Steps:**
1. Capture a thought
2. Note the processing time

**Expected:**
- [ ] Transcription starts immediately
- [ ] Minimal delay to saved state
- [ ] Toast notification confirms capture

#### Test Case QN-003: Notes List View

**Steps:**
1. Capture several thoughts
2. Open quick notes list

**Expected:**
- [ ] Notes sorted by recency
- [ ] Each note shows text preview
- [ ] Duration and time displayed
- [ ] Tags auto-extracted and shown

#### Test Case QN-004: Tag Extraction

**Steps:**
1. Say "Remember to finish the todo list"
2. Check the saved note

**Expected:**
- [ ] "todo" tag auto-applied
- [ ] "remember" tag auto-applied
- [ ] Tags visible on note card

#### Test Case QN-005: Edit and Delete

**Steps:**
1. Open a quick note
2. Edit the text
3. Delete another note

**Expected:**
- [ ] Edit opens editable view
- [ ] Changes save correctly
- [ ] Delete prompts confirmation
- [ ] Note removed after confirm

---

## Waveform Visualization

### Component: `AudioWaveform`

#### Test Case WV-001: Style Variations

**Steps:**
1. Test each WaveformStyle:
   - `bars` (vertical bars)
   - `line` (oscilloscope line)
   - `circular` (radial visualization)
   - `orb` (glowing sphere)

**Expected:**
- [ ] Each style renders correctly
- [ ] Style switch is smooth
- [ ] All styles responsive to audio

#### Test Case WV-002: Amplitude Response

**Steps:**
1. Display waveform during recording
2. Vary voice volume: whisper → normal → loud
3. Stay silent

**Expected:**
- [ ] Waveform amplitude matches voice level
- [ ] Sensitive to quiet sounds
- [ ] No clipping on loud sounds
- [ ] Quiet baseline when silent

#### Test Case WV-003: Color Customization

**Steps:**
1. Set custom colors via properties
2. Verify theme integration

**Expected:**
- [ ] Custom colors applied
- [ ] Gradient options work (if available)
- [ ] Theme colors used when not customized

---

## Edge Cases

#### Test Case EC-001: No Microphone Permission

**Steps:**
1. Deny microphone permission
2. Try to use voice features

**Expected:**
- [ ] Graceful error message
- [ ] Prompt to enable permission
- [ ] No crash

#### Test Case EC-002: Very Long Transcription

**Steps:**
1. Record and dictate for 5+ minutes continuously

**Expected:**
- [ ] Memory usage stays reasonable
- [ ] Transcription remains accurate
- [ ] No UI freezes

#### Test Case EC-003: Background Audio

**Steps:**
1. Play music in background
2. Record a voice note

**Expected:**
- [ ] Voice isolated from background
- [ ] Transcription focuses on speech
- [ ] Playback audio ducked or paused

#### Test Case EC-004: Rapid Start/Stop

**Steps:**
1. Repeatedly tap mic button quickly (10x)

**Expected:**
- [ ] No crashes
- [ ] State remains consistent
- [ ] UI recovers gracefully

#### Test Case EC-005: Offline Mode

**Steps:**
1. Enable airplane mode
2. Attempt to use voice features

**Expected:**
- [ ] On-device models still work (if downloaded)
- [ ] Clear error if cloud needed
- [ ] Graceful degradation

#### Test Case EC-006: Low Battery

**Steps:**
1. Test with < 15% battery (simulated or real)

**Expected:**
- [ ] Warning if heavy processing needed
- [ ] Features still functional
- [ ] Battery drain reasonable

---

## Performance Testing

#### Test Case PT-001: Transcription Latency

**Metric:** Time from end of speech to final transcription
**Target:** < 1.5 seconds for Whisper Tiny, < 3s for larger models

**Steps:**
1. Say a short phrase
2. Note time to finalization

**Expected:**
- [ ] Meets latency target
- [ ] Consistent across multiple tests

#### Test Case PT-002: TTS Latency

**Metric:** Time from request to first audio output
**Target:** < 500ms for short phrases

**Steps:**
1. Request TTS playback
2. Measure time to audio start

**Expected:**
- [ ] Streaming begins quickly
- [ ] No noticeable delay

#### Test Case PT-003: Memory Usage

**Metric:** RAM consumption during voice features
**Target:** < 200MB additional during active use

**Steps:**
1. Profile memory before activation
2. Use voice features for 5 minutes
3. Profile memory during and after

**Expected:**
- [ ] Memory stays within limits
- [ ] No memory leaks after stopping

#### Test Case PT-004: CPU Usage

**Metric:** CPU utilization during transcription
**Target:** < 80% on mid-range device

**Steps:**
1. Monitor CPU during transcription
2. Check for thermal throttling

**Expected:**
- [ ] CPU usage reasonable
- [ ] Device doesn't overheat

---

## Sign-Off Checklist

Before release, confirm all critical paths:

- [ ] NIB-001: Basic dictation works
- [ ] VNB-002: Voice note playback works
- [ ] WTM-002: Walkie-talkie orbs animate
- [ ] RA-001: Read aloud produces speech
- [ ] AS-002: Models can be downloaded
- [ ] QN-001: Quick notes capture works
- [ ] EC-001: Permission denial handled
- [ ] PT-001: Latency within targets

**Tested By:** _________________  
**Date:** _________________  
**Build Version:** _________________  
**Devices Tested:** _________________

---

## Appendix: Test Data

### Sample Transcription Texts

1. Short: "Hello world"
2. Medium: "The quick brown fox jumps over the lazy dog near the riverbank"
3. Long: "Artificial intelligence continues to transform how we interact with technology. Voice interfaces have become increasingly natural and responsive."
4. Technical: "The API endpoint returns a JSON object with fields: userId, timestamp, and payload."
5. Numbers: "My phone number is 555-123-4567 and my zip code is 90210."

### Sample TTS Texts

1. Greeting: "Good morning! How can I help you today?"
2. Information: "Your appointment is scheduled for Tuesday at 3:30 PM."
3. Long passage: "In the beginning, there was only darkness. Then came the light, spreading across the vast emptiness of space, bringing with it the possibility of life and consciousness."

---

*Last Updated: v0.2.1*
