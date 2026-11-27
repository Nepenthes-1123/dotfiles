//! M0 section 6 (and 3.2): libghostty-vt from Rust.
//!
//! 1. Restore nvim's screen from the bytes a re-attach delivered and compare
//!    it with what hc itself reads from the terminal.
//! 2. Kitty keyboard: Shift+Enter vs Enter before and after the program asks.
//! 3. Character widths: libghostty-vt vs WezTerm's own width function
//!    (termwiz, with WezTerm's defaults: unicode_version 9, ambiguous narrow).
//!
//! usage: vt-probe CAPTURES_DIR

use ghostty_vt::Terminal;
use termwiz::cell::{UnicodeVersion, unicode_column_width};

const KEY_ENTER: i32 = 58;
const MOD_SHIFT: u16 = 1;

fn show(bytes: &[u8]) -> String {
    bytes
        .iter()
        .map(|&b| match b {
            0x1b => "ESC".to_string(),
            b'\r' => "\\r".to_string(),
            0x20..=0x7e => (b as char).to_string(),
            _ => format!("\\x{b:02x}"),
        })
        .collect()
}

/// Width ghostty gives `s`: print it at the home position, then ask where the cursor is.
fn ghostty_width(s: &str, grapheme_mode: bool) -> usize {
    let mut t = Terminal::new(80, 5, 0);
    if grapheme_mode {
        t.write(b"\x1b[?2027h");
    }
    t.write(b"\x1b[H\x1b[2J");
    t.write(s.as_bytes());
    t.write(b"\x1b[6n");
    let reply = String::from_utf8_lossy(&t.take_responses()).into_owned();
    // ESC [ row ; col R
    let col: usize = reply
        .rsplit(';')
        .next()
        .and_then(|c| c.trim_end_matches('R').parse().ok())
        .unwrap_or(0);
    col.saturating_sub(1)
}

fn main() {
    let dir = std::env::args().nth(1).unwrap_or_else(|| ".".into());

    println!("== 1. restore nvim's screen from the re-attach bytes");
    let paint = std::fs::read(format!("{dir}/nvim-reattach-first-paint.bin")).expect("capture");
    let read: serde_json::Value =
        serde_json::from_slice(&std::fs::read(format!("{dir}/nvim-terminal-read.json")).unwrap()).unwrap();
    let want: Vec<String> = read["text"].as_str().unwrap().lines().map(|l| l.trim_end().to_string()).collect();
    let mut t = Terminal::new(100, 30, 1 << 20);
    t.write(&paint);
    let got: Vec<String> = t.screen_rows().into_iter().map(|l| l.trim_end().to_string()).collect();
    std::fs::write(format!("{dir}/nvim-restored-by-libghostty-vt.txt"), got.join("\n") + "\n").unwrap();
    let same = got.iter().zip(want.iter()).filter(|(a, b)| a == b).count();
    println!(
        "  alt screen active: {}, rows identical to hc's own read: {same}/{} (restored rows {})",
        t.alt_screen(),
        want.len(),
        got.len()
    );
    for (i, (a, b)) in got.iter().zip(want.iter()).enumerate() {
        if a != b {
            println!("  row {i} differs:\n    restored: {a:?}\n    hc read : {b:?}");
        }
    }
    println!("  first rows:\n    {}\n    {}", got[0], got[1]);

    println!("== 2. Kitty keyboard protocol through the key encoder");
    let mut t = Terminal::new(80, 24, 0);
    let legacy = (t.encode_key(KEY_ENTER, 0, "\r", 0), t.encode_key(KEY_ENTER, MOD_SHIFT, "\r", 0));
    println!("  before the program asks: Enter {:?}  Shift+Enter {:?}", show(&legacy.0), show(&legacy.1));
    t.write(b"\x1b[>1u"); // what Claude Code / nvim send: push 'disambiguate'
    let kitty = (t.encode_key(KEY_ENTER, 0, "\r", 0), t.encode_key(KEY_ENTER, MOD_SHIFT, "\r", 0));
    println!("  after CSI > 1 u:         Enter {:?}  Shift+Enter {:?}", show(&kitty.0), show(&kitty.1));
    println!("  distinguished: {}", kitty.0 != kitty.1);
    t.write(b"\x1b[<u"); // pop
    let popped = t.encode_key(KEY_ENTER, MOD_SHIFT, "\r", 0);
    println!("  after CSI < u (pop):     Shift+Enter {:?}", show(&popped));

    println!("== 3. widths: libghostty-vt vs WezTerm defaults (termwiz, unicode 9, ambiguous narrow)");
    let wez9 = Some(UnicodeVersion { version: 9, ambiguous_are_wide: false });
    let wez14 = Some(UnicodeVersion { version: 14, ambiguous_are_wide: false });
    let samples: &[(&str, &str)] = &[
        ("日本語", "CJK"),
        ("ｱｲｳ", "halfwidth kana"),
        ("か\u{3099}", "kana + combining voiced mark"),
        ("🎉", "emoji"),
        ("👍🏽", "emoji + skin tone"),
        ("👨\u{200d}👩\u{200d}👧", "ZWJ family"),
        ("🇯🇵", "flag"),
        ("❤\u{fe0f}", "heart + VS16"),
        ("✔\u{fe0f}", "check + VS16"),
        ("✓", "U+2713 check"),
        ("◉", "U+25C9 (spec: blocked)"),
        ("●", "U+25CF (spec: working)"),
        ("○", "U+25CB (spec: idle)"),
        ("①", "circled digit (ambiguous)"),
        ("→…", "arrow, ellipsis (ambiguous)"),
        ("─│", "box drawing (ambiguous)"),
        ("\u{e0b0}", "Powerline PUA (ambiguous)"),
    ];
    println!("  {:<34} {:>7} {:>9} {:>9} {:>9}", "sample", "ghostty", "ghostty", "WezTerm", "WezTerm");
    println!("  {:<34} {:>7} {:>9} {:>9} {:>9}", "", "default", "+2027", "uni 9", "uni 14");
    let mut mismatches = 0;
    for (s, what) in samples {
        let g = ghostty_width(s, false);
        let g2 = ghostty_width(s, true);
        let w9 = unicode_column_width(s, wez9);
        let w14 = unicode_column_width(s, wez14);
        let mark = if g == w9 { "" } else { "  <- differs from WezTerm default" };
        if g != w9 {
            mismatches += 1;
        }
        println!("  {:<34} {g:>7} {g2:>9} {w9:>9} {w14:>9}{mark}", format!("{s} ({what})"));
    }
    println!("  samples where ghostty's default width differs from WezTerm's default: {mismatches}/{}", samples.len());
}
