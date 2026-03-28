//! Text Phonemizer Module
//!
//! Converts text to phonetic representations for TTS synthesis.
//! Supports English phonemization using a rule-based approach with
//! a pronunciation dictionary fallback.

use anyhow::Result;
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use unicode_normalization::UnicodeNormalization;

/// Phoneme set for English (simplified ARPAbet-like)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum Phoneme {
    // Vowels
    AA, // odd
    AE, // at
    AH, // hut
    AO, // ought
    AW, // cow
    AY, // hide
    EH, // Ed
    ER, // hurt
    EY, // ate
    IH, // it
    IY, // eat
    OW, // oat
    OY, // toy
    UH, // hood
    UW, // two

    // Consonants
    B,  // be
    CH, // cheese
    D,  // dee
    DH, // thee
    F,  // fee
    G,  // green
    HH, // he
    JH, // gee
    K,  // key
    L,  // lee
    M,  // me
    N,  // knee
    NG, // ping
    P,  // pee
    R,  // read
    S,  // sea
    SH, // she
    T,  // tea
    TH, // theta
    V,  // vee
    W,  // we
    Y,  // yield
    Z,  // zee
    ZH, // seizure

    // Special
    SIL,   // silence/pause
    SP,    // short pause
    SPACE, // word boundary
}

impl Phoneme {
    /// Convert phoneme to its string representation
    pub fn to_str(&self) -> &'static str {
        match self {
            Phoneme::AA => "AA",
            Phoneme::AE => "AE",
            Phoneme::AH => "AH",
            Phoneme::AO => "AO",
            Phoneme::AW => "AW",
            Phoneme::AY => "AY",
            Phoneme::EH => "EH",
            Phoneme::ER => "ER",
            Phoneme::EY => "EY",
            Phoneme::IH => "IH",
            Phoneme::IY => "IY",
            Phoneme::OW => "OW",
            Phoneme::OY => "OY",
            Phoneme::UH => "UH",
            Phoneme::UW => "UW",
            Phoneme::B => "B",
            Phoneme::CH => "CH",
            Phoneme::D => "D",
            Phoneme::DH => "DH",
            Phoneme::F => "F",
            Phoneme::G => "G",
            Phoneme::HH => "HH",
            Phoneme::JH => "JH",
            Phoneme::K => "K",
            Phoneme::L => "L",
            Phoneme::M => "M",
            Phoneme::N => "N",
            Phoneme::NG => "NG",
            Phoneme::P => "P",
            Phoneme::R => "R",
            Phoneme::S => "S",
            Phoneme::SH => "SH",
            Phoneme::T => "T",
            Phoneme::TH => "TH",
            Phoneme::V => "V",
            Phoneme::W => "W",
            Phoneme::Y => "Y",
            Phoneme::Z => "Z",
            Phoneme::ZH => "ZH",
            Phoneme::SIL => "SIL",
            Phoneme::SP => "SP",
            Phoneme::SPACE => " ",
        }
    }

    /// Check if this is a vowel
    pub fn is_vowel(&self) -> bool {
        matches!(
            self,
            Phoneme::AA
                | Phoneme::AE
                | Phoneme::AH
                | Phoneme::AO
                | Phoneme::AW
                | Phoneme::AY
                | Phoneme::EH
                | Phoneme::ER
                | Phoneme::EY
                | Phoneme::IH
                | Phoneme::IY
                | Phoneme::OW
                | Phoneme::OY
                | Phoneme::UH
                | Phoneme::UW
        )
    }

    /// Check if this is a consonant
    pub fn is_consonant(&self) -> bool {
        !self.is_vowel() && !matches!(self, Phoneme::SIL | Phoneme::SP | Phoneme::SPACE)
    }
}

/// A phonemized word with timing hints
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PhonemeSequence {
    /// Original text
    pub text: String,
    /// Phoneme sequence
    pub phonemes: Vec<Phoneme>,
    /// Stress markers (0 = no stress, 1 = primary, 2 = secondary)
    pub stress: Vec<u8>,
}

impl PhonemeSequence {
    /// Create a new phoneme sequence
    pub fn new(text: String, phonemes: Vec<Phoneme>) -> Self {
        let stress = vec![0; phonemes.len()];
        Self {
            text,
            phonemes,
            stress,
        }
    }

    /// Create with stress markers
    pub fn with_stress(text: String, phonemes: Vec<Phoneme>, stress: Vec<u8>) -> Self {
        Self {
            text,
            phonemes,
            stress,
        }
    }

    /// Convert to string representation
    pub fn to_string_repr(&self) -> String {
        self.phonemes
            .iter()
            .map(|p| p.to_str())
            .collect::<Vec<_>>()
            .join(" ")
    }

    /// Get number of syllables (approximated by counting vowels)
    pub fn syllable_count(&self) -> usize {
        self.phonemes.iter().filter(|p| p.is_vowel()).count().max(1)
    }
}

/// Text phonemizer configuration
#[derive(Debug, Clone)]
pub struct PhonemizerConfig {
    /// Whether to preserve punctuation as pauses
    pub preserve_punctuation: bool,
    /// Whether to expand numbers
    pub expand_numbers: bool,
    /// Whether to expand abbreviations
    pub expand_abbreviations: bool,
}

impl Default for PhonemizerConfig {
    fn default() -> Self {
        Self {
            preserve_punctuation: true,
            expand_numbers: true,
            expand_abbreviations: true,
        }
    }
}

/// Text-to-Phoneme converter
///
/// Converts English text to phoneme sequences for TTS synthesis.
/// Uses a combination of:
/// - Built-in pronunciation dictionary for common words
/// - Grapheme-to-phoneme rules for unknown words
#[derive(Debug)]
pub struct Phonemizer {
    config: PhonemizerConfig,
    /// Pronunciation dictionary
    dictionary: HashMap<String, Vec<Phoneme>>,
    /// Abbreviation expansions
    abbreviations: HashMap<String, String>,
}

impl Phonemizer {
    /// Create a new phonemizer with default configuration
    pub fn new() -> Self {
        Self::with_config(PhonemizerConfig::default())
    }

    /// Create a phonemizer with custom configuration
    pub fn with_config(config: PhonemizerConfig) -> Self {
        let mut phonemizer = Self {
            config,
            dictionary: HashMap::new(),
            abbreviations: HashMap::new(),
        };
        phonemizer.initialize_dictionary();
        phonemizer.initialize_abbreviations();
        phonemizer
    }

    /// Initialize the built-in pronunciation dictionary
    fn initialize_dictionary(&mut self) {
        // Common words with their phoneme sequences
        let entries: Vec<(&str, Vec<Phoneme>)> = vec![
            (
                "hello",
                vec![Phoneme::HH, Phoneme::AH, Phoneme::L, Phoneme::OW],
            ),
            (
                "world",
                vec![Phoneme::W, Phoneme::ER, Phoneme::L, Phoneme::D],
            ),
            ("the", vec![Phoneme::DH, Phoneme::AH]),
            ("a", vec![Phoneme::AH]),
            ("an", vec![Phoneme::AE, Phoneme::N]),
            ("is", vec![Phoneme::IH, Phoneme::Z]),
            ("are", vec![Phoneme::AA, Phoneme::R]),
            ("was", vec![Phoneme::W, Phoneme::AA, Phoneme::Z]),
            ("were", vec![Phoneme::W, Phoneme::ER]),
            ("be", vec![Phoneme::B, Phoneme::IY]),
            ("been", vec![Phoneme::B, Phoneme::IH, Phoneme::N]),
            (
                "being",
                vec![Phoneme::B, Phoneme::IY, Phoneme::IH, Phoneme::NG],
            ),
            ("have", vec![Phoneme::HH, Phoneme::AE, Phoneme::V]),
            ("has", vec![Phoneme::HH, Phoneme::AE, Phoneme::Z]),
            ("had", vec![Phoneme::HH, Phoneme::AE, Phoneme::D]),
            ("do", vec![Phoneme::D, Phoneme::UW]),
            ("does", vec![Phoneme::D, Phoneme::AH, Phoneme::Z]),
            ("did", vec![Phoneme::D, Phoneme::IH, Phoneme::D]),
            ("will", vec![Phoneme::W, Phoneme::IH, Phoneme::L]),
            ("would", vec![Phoneme::W, Phoneme::UH, Phoneme::D]),
            ("can", vec![Phoneme::K, Phoneme::AE, Phoneme::N]),
            ("could", vec![Phoneme::K, Phoneme::UH, Phoneme::D]),
            ("should", vec![Phoneme::SH, Phoneme::UH, Phoneme::D]),
            ("may", vec![Phoneme::M, Phoneme::EY]),
            ("might", vec![Phoneme::M, Phoneme::AY, Phoneme::T]),
            (
                "must",
                vec![Phoneme::M, Phoneme::AH, Phoneme::S, Phoneme::T],
            ),
            ("i", vec![Phoneme::AY]),
            ("you", vec![Phoneme::Y, Phoneme::UW]),
            ("he", vec![Phoneme::HH, Phoneme::IY]),
            ("she", vec![Phoneme::SH, Phoneme::IY]),
            ("it", vec![Phoneme::IH, Phoneme::T]),
            ("we", vec![Phoneme::W, Phoneme::IY]),
            ("they", vec![Phoneme::DH, Phoneme::EY]),
            ("this", vec![Phoneme::DH, Phoneme::IH, Phoneme::S]),
            ("that", vec![Phoneme::DH, Phoneme::AE, Phoneme::T]),
            ("these", vec![Phoneme::DH, Phoneme::IY, Phoneme::Z]),
            ("those", vec![Phoneme::DH, Phoneme::OW, Phoneme::Z]),
            ("what", vec![Phoneme::W, Phoneme::AH, Phoneme::T]),
            ("who", vec![Phoneme::HH, Phoneme::UW]),
            ("where", vec![Phoneme::W, Phoneme::EH, Phoneme::R]),
            ("when", vec![Phoneme::W, Phoneme::EH, Phoneme::N]),
            ("why", vec![Phoneme::W, Phoneme::AY]),
            ("how", vec![Phoneme::HH, Phoneme::AW]),
            ("and", vec![Phoneme::AE, Phoneme::N, Phoneme::D]),
            ("or", vec![Phoneme::AO, Phoneme::R]),
            ("but", vec![Phoneme::B, Phoneme::AH, Phoneme::T]),
            ("not", vec![Phoneme::N, Phoneme::AA, Phoneme::T]),
            ("yes", vec![Phoneme::Y, Phoneme::EH, Phoneme::S]),
            ("no", vec![Phoneme::N, Phoneme::OW]),
            ("one", vec![Phoneme::W, Phoneme::AH, Phoneme::N]),
            ("two", vec![Phoneme::T, Phoneme::UW]),
            ("three", vec![Phoneme::TH, Phoneme::R, Phoneme::IY]),
            ("four", vec![Phoneme::F, Phoneme::AO, Phoneme::R]),
            ("five", vec![Phoneme::F, Phoneme::AY, Phoneme::V]),
            ("six", vec![Phoneme::S, Phoneme::IH, Phoneme::K, Phoneme::S]),
            (
                "seven",
                vec![Phoneme::S, Phoneme::EH, Phoneme::V, Phoneme::AH, Phoneme::N],
            ),
            ("eight", vec![Phoneme::EY, Phoneme::T]),
            ("nine", vec![Phoneme::N, Phoneme::AY, Phoneme::N]),
            ("ten", vec![Phoneme::T, Phoneme::EH, Phoneme::N]),
            (
                "kivixa",
                vec![
                    Phoneme::K,
                    Phoneme::IH,
                    Phoneme::V,
                    Phoneme::IH,
                    Phoneme::K,
                    Phoneme::S,
                    Phoneme::AH,
                ],
            ),
        ];

        for (word, phonemes) in entries {
            self.dictionary.insert(word.to_string(), phonemes);
        }
    }

    /// Initialize abbreviation expansions
    fn initialize_abbreviations(&mut self) {
        let abbrevs: Vec<(&str, &str)> = vec![
            ("mr", "mister"),
            ("mrs", "missus"),
            ("ms", "miss"),
            ("dr", "doctor"),
            ("prof", "professor"),
            ("st", "street"),
            ("ave", "avenue"),
            ("blvd", "boulevard"),
            ("etc", "et cetera"),
            ("vs", "versus"),
            ("ie", "that is"),
            ("eg", "for example"),
            ("usa", "u s a"),
            ("uk", "u k"),
            ("ai", "a i"),
            ("ui", "u i"),
            ("api", "a p i"),
            ("cpu", "c p u"),
            ("gpu", "g p u"),
            ("ram", "ram"),
            ("ssd", "s s d"),
            ("hdd", "h d d"),
            ("pdf", "p d f"),
            ("html", "h t m l"),
            ("css", "c s s"),
        ];

        for (abbrev, expansion) in abbrevs {
            self.abbreviations
                .insert(abbrev.to_string(), expansion.to_string());
        }
    }

    /// Phonemize a text string
    ///
    /// # Arguments
    /// * `text` - The text to phonemize
    ///
    /// # Returns
    /// A vector of phoneme sequences, one per word/token
    pub fn phonemize(&self, text: &str) -> Result<Vec<PhonemeSequence>> {
        let normalized = self.normalize_text(text);
        let tokens = self.tokenize(&normalized);

        let mut result = Vec::new();
        for token in tokens {
            let sequence = self.phonemize_token(&token)?;
            result.push(sequence);
        }

        Ok(result)
    }

    /// Phonemize to a flat phoneme string
    pub fn phonemize_to_string(&self, text: &str) -> Result<String> {
        let sequences = self.phonemize(text)?;
        Ok(sequences
            .iter()
            .map(|s| s.to_string_repr())
            .collect::<Vec<_>>()
            .join(" "))
    }

    /// Normalize text for phonemization
    fn normalize_text(&self, text: &str) -> String {
        let mut normalized = text.nfc().collect::<String>();

        // Convert to lowercase
        normalized = normalized.to_lowercase();

        // Expand abbreviations if enabled
        if self.config.expand_abbreviations {
            for (abbrev, expansion) in &self.abbreviations {
                let pattern = format!(r"\b{}\b", regex::escape(abbrev));
                if let Ok(re) = Regex::new(&pattern) {
                    normalized = re.replace_all(&normalized, expansion.as_str()).to_string();
                }
            }
        }

        // Expand numbers if enabled
        if self.config.expand_numbers {
            normalized = self.expand_numbers(&normalized);
        }

        normalized
    }

    /// Expand numbers to words
    fn expand_numbers(&self, text: &str) -> String {
        let mut result = text.to_string();

        // Simple number expansion for common cases
        let numbers: Vec<(&str, &str)> = vec![
            ("0", "zero"),
            ("1", "one"),
            ("2", "two"),
            ("3", "three"),
            ("4", "four"),
            ("5", "five"),
            ("6", "six"),
            ("7", "seven"),
            ("8", "eight"),
            ("9", "nine"),
            ("10", "ten"),
            ("11", "eleven"),
            ("12", "twelve"),
            ("13", "thirteen"),
            ("14", "fourteen"),
            ("15", "fifteen"),
            ("16", "sixteen"),
            ("17", "seventeen"),
            ("18", "eighteen"),
            ("19", "nineteen"),
            ("20", "twenty"),
            ("30", "thirty"),
            ("40", "forty"),
            ("50", "fifty"),
            ("60", "sixty"),
            ("70", "seventy"),
            ("80", "eighty"),
            ("90", "ninety"),
            ("100", "one hundred"),
            ("1000", "one thousand"),
        ];

        for (num, word) in numbers {
            let pattern = format!(r"\b{}\b", num);
            if let Ok(re) = Regex::new(&pattern) {
                result = re.replace_all(&result, word).to_string();
            }
        }

        result
    }

    /// Tokenize text into words and punctuation
    fn tokenize(&self, text: &str) -> Vec<String> {
        let mut tokens = Vec::new();
        let mut current_word = String::new();

        for c in text.chars() {
            if c.is_alphabetic() || c == '\'' {
                current_word.push(c);
            } else {
                if !current_word.is_empty() {
                    tokens.push(current_word.clone());
                    current_word.clear();
                }
                if self.config.preserve_punctuation
                    && (c == '.' || c == ',' || c == '!' || c == '?' || c == ':' || c == ';')
                {
                    tokens.push(c.to_string());
                } else if c.is_whitespace() && !tokens.is_empty() {
                    // Add space marker between words
                    if tokens.last().map(|t| t != " ").unwrap_or(false) {
                        tokens.push(" ".to_string());
                    }
                }
            }
        }

        if !current_word.is_empty() {
            tokens.push(current_word);
        }

        tokens
    }

    /// Phonemize a single token
    fn phonemize_token(&self, token: &str) -> Result<PhonemeSequence> {
        // Handle punctuation
        if token.len() == 1 {
            match token.chars().next() {
                Some('.') | Some('!') | Some('?') => {
                    return Ok(PhonemeSequence::new(token.to_string(), vec![Phoneme::SIL]));
                }
                Some(',') | Some(':') | Some(';') => {
                    return Ok(PhonemeSequence::new(token.to_string(), vec![Phoneme::SP]));
                }
                Some(' ') => {
                    return Ok(PhonemeSequence::new(
                        token.to_string(),
                        vec![Phoneme::SPACE],
                    ));
                }
                _ => {}
            }
        }

        // Look up in dictionary
        let word = token.to_lowercase();
        if let Some(phonemes) = self.dictionary.get(&word) {
            return Ok(PhonemeSequence::new(token.to_string(), phonemes.clone()));
        }

        // Fall back to grapheme-to-phoneme rules
        let phonemes = self.g2p(&word);
        Ok(PhonemeSequence::new(token.to_string(), phonemes))
    }

    /// Grapheme-to-phoneme conversion for unknown words
    fn g2p(&self, word: &str) -> Vec<Phoneme> {
        let mut phonemes = Vec::new();
        let chars: Vec<char> = word.chars().collect();
        let mut i = 0;

        while i < chars.len() {
            let remaining = &chars[i..];
            let (phoneme, advance) = self.match_grapheme(remaining);
            if let Some(p) = phoneme {
                phonemes.push(p);
            }
            i += advance;
        }

        if phonemes.is_empty() {
            phonemes.push(Phoneme::AH); // Fallback
        }

        phonemes
    }

    /// Match graphemes to phonemes using rules
    fn match_grapheme(&self, chars: &[char]) -> (Option<Phoneme>, usize) {
        if chars.is_empty() {
            return (None, 1);
        }

        let c = chars[0];
        let next = chars.get(1).copied();
        let next2 = chars.get(2).copied();

        // Multi-character patterns
        match (c, next, next2) {
            ('t', Some('h'), _) => return (Some(Phoneme::TH), 2),
            ('s', Some('h'), _) => return (Some(Phoneme::SH), 2),
            ('c', Some('h'), _) => return (Some(Phoneme::CH), 2),
            ('n', Some('g'), _) => return (Some(Phoneme::NG), 2),
            ('w', Some('h'), _) => return (Some(Phoneme::W), 2),
            ('p', Some('h'), _) => return (Some(Phoneme::F), 2),
            ('g', Some('h'), _) => return (None, 2), // Silent gh
            ('k', Some('n'), _) => return (Some(Phoneme::N), 2), // Silent k in kn
            ('w', Some('r'), _) => return (Some(Phoneme::R), 2), // Silent w in wr
            ('e', Some('a'), _) => return (Some(Phoneme::IY), 2),
            ('o', Some('o'), _) => return (Some(Phoneme::UW), 2),
            ('e', Some('e'), _) => return (Some(Phoneme::IY), 2),
            ('o', Some('u'), _) => return (Some(Phoneme::AW), 2),
            ('a', Some('i'), _) => return (Some(Phoneme::EY), 2),
            ('a', Some('y'), _) => return (Some(Phoneme::EY), 2),
            ('o', Some('i'), _) => return (Some(Phoneme::OY), 2),
            ('o', Some('y'), _) => return (Some(Phoneme::OY), 2),
            ('i', Some('g'), Some('h')) => return (Some(Phoneme::AY), 3),
            _ => {}
        }

        // Single character patterns
        let phoneme = match c {
            'a' => Phoneme::AE,
            'b' => Phoneme::B,
            'c' => {
                if next == Some('e') || next == Some('i') || next == Some('y') {
                    Phoneme::S
                } else {
                    Phoneme::K
                }
            }
            'd' => Phoneme::D,
            'e' => Phoneme::EH,
            'f' => Phoneme::F,
            'g' => {
                if next == Some('e') || next == Some('i') || next == Some('y') {
                    Phoneme::JH
                } else {
                    Phoneme::G
                }
            }
            'h' => Phoneme::HH,
            'i' => Phoneme::IH,
            'j' => Phoneme::JH,
            'k' => Phoneme::K,
            'l' => Phoneme::L,
            'm' => Phoneme::M,
            'n' => Phoneme::N,
            'o' => Phoneme::AA,
            'p' => Phoneme::P,
            'q' => Phoneme::K,
            'r' => Phoneme::R,
            's' => Phoneme::S,
            't' => Phoneme::T,
            'u' => Phoneme::AH,
            'v' => Phoneme::V,
            'w' => Phoneme::W,
            'x' => Phoneme::K, // Simplified
            'y' => {
                if next.is_none() || next.map(|c| c.is_alphabetic()).unwrap_or(false) {
                    Phoneme::IY
                } else {
                    Phoneme::Y
                }
            }
            'z' => Phoneme::Z,
            '\'' => return (None, 1), // Skip apostrophes
            _ => return (None, 1),
        };

        (Some(phoneme), 1)
    }
}

impl Default for Phonemizer {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_phoneme_properties() {
        assert!(Phoneme::AA.is_vowel());
        assert!(Phoneme::IY.is_vowel());
        assert!(!Phoneme::B.is_vowel());
        assert!(Phoneme::B.is_consonant());
        assert!(!Phoneme::SIL.is_consonant());
    }

    #[test]
    fn test_phonemizer_dictionary_lookup() {
        let phonemizer = Phonemizer::new();
        let result = phonemizer.phonemize("hello").unwrap();

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].text, "hello");
        assert!(!result[0].phonemes.is_empty());
    }

    #[test]
    fn test_phonemizer_multiple_words() {
        let phonemizer = Phonemizer::new();
        let result = phonemizer.phonemize("hello world").unwrap();

        // Should have hello, space, world
        assert!(result.len() >= 2);
    }

    #[test]
    fn test_phonemizer_punctuation() {
        let phonemizer = Phonemizer::new();
        let result = phonemizer.phonemize("hello.").unwrap();

        // Should end with a silence phoneme
        let last = result.last().unwrap();
        assert!(last.phonemes.contains(&Phoneme::SIL));
    }

    #[test]
    fn test_g2p_unknown_word() {
        let phonemizer = Phonemizer::new();
        let result = phonemizer.phonemize("xyz").unwrap();

        assert!(!result.is_empty());
        assert!(!result[0].phonemes.is_empty());
    }

    #[test]
    fn test_phoneme_sequence_syllables() {
        let seq = PhonemeSequence::new(
            "hello".to_string(),
            vec![Phoneme::HH, Phoneme::AH, Phoneme::L, Phoneme::OW],
        );
        assert_eq!(seq.syllable_count(), 2); // Two vowels
    }

    #[test]
    fn test_abbreviation_expansion() {
        let phonemizer = Phonemizer::new();
        let result = phonemizer.phonemize("dr smith").unwrap();

        // "dr" should be expanded to "doctor"
        assert!(result.iter().any(|s| s.text == "doctor"));
    }

    #[test]
    fn test_number_expansion() {
        let phonemizer = Phonemizer::new();
        let result = phonemizer.phonemize("i have 3 apples").unwrap();

        // "3" should be expanded to "three"
        assert!(result.iter().any(|s| s.text == "three"));
    }

    #[test]
    fn test_normalize_text() {
        let phonemizer = Phonemizer::new();
        let normalized = phonemizer.normalize_text("Hello World!");
        assert_eq!(normalized, "hello world!");
    }

    #[test]
    fn test_phonemize_to_string() {
        let phonemizer = Phonemizer::new();
        let result = phonemizer.phonemize_to_string("hello").unwrap();

        assert!(!result.is_empty());
        assert!(result.contains("HH"));
    }

    #[test]
    fn test_kivixa_pronunciation() {
        let phonemizer = Phonemizer::new();
        let result = phonemizer.phonemize("kivixa").unwrap();

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].text, "kivixa");
    }
}
