/// Simple keyword -> answer knowledge base for the free, offline, rule-based
/// HIFAZAT assistant. No external API/cost involved (Option A from our
/// earlier discussion). Expand this list anytime — no other file needs to
/// change.
class FaqEntry {
  final List<String> keywords;
  final String answer;
  const FaqEntry({required this.keywords, required this.answer});
}

class FaqData {
  FaqData._();

  static const List<FaqEntry> entries = [
    FaqEntry(
      keywords: ['turbidity', 'cloudy', 'murky'],
      answer:
          'Turbidity measures how cloudy your water is due to suspended particles. High turbidity can shield harmful bacteria from disinfection and often signals contamination from silt, sewage, or organic matter. Boiling and filtering can help, but persistent high turbidity should be reported to your local water authority.',
    ),
    FaqEntry(
      keywords: ['ph', 'acidic', 'alkaline'],
      answer:
          'A safe drinking water pH is generally between 6.5 and 8.5. Water outside this range can taste off, corrode pipes (low pH) or cause scaling and reduce disinfection effectiveness (high pH). It is usually not immediately dangerous but is worth monitoring over time.',
    ),
    FaqEntry(
      keywords: ['urea', 'adulteration', 'adulterated'],
      answer:
          'Urea is sometimes illegally added to milk to artificially boost its protein reading. Trace amounts can affect kidney function over time, especially in children. If detected, it is best to avoid that milk source and consider reporting the supplier.',
    ),
    FaqEntry(
      keywords: ['fat', 'diluted', 'watered'],
      answer:
          'Low fat content compared to expected values may indicate the milk has been diluted with water, reducing its nutritional value. This isn\'t usually toxic, but you are not getting what you are paying for.',
    ),
    FaqEntry(
      keywords: ['rancid', 'rancidity', 'smell', 'odor', 'sour'],
      answer:
          'A sour or off smell in milk is usually a sign of bacterial spoilage — the pH sensor will typically show a drop when this happens. Discard milk with a sour smell rather than consuming it, even after boiling.',
    ),
    FaqEntry(
      keywords: ['boil', 'boiling', 'safe to drink'],
      answer:
          'Boiling water for at least one minute kills most harmful bacteria and viruses, but it will not remove chemical contaminants or heavy metals. If your result flagged a chemical issue rather than a biological one, boiling alone may not make it fully safe.',
    ),
    FaqEntry(
      keywords: ['confidence', 'accurate', 'sure', 'retest', 're-test'],
      answer:
          'When our confidence is below 80%, we recommend re-testing rather than trusting the result outright. This usually happens with unusual sensor readings or a partially calibrated device — a clean re-test with a fresh sample often resolves it.',
    ),
    FaqEntry(
      keywords: ['tds', 'dissolved solids'],
      answer:
          'TDS (Total Dissolved Solids) measures minerals, salts, and metals dissolved in water. A very high TDS can indicate contamination, while a moderate level is often just mineral content and not necessarily unsafe on its own — we look at it together with other sensors.',
    ),
    FaqEntry(
      keywords: ['gas', 'ammonia', 'spoilage'],
      answer:
          'Our gas sensor detects volatile compounds that increase with microbial spoilage or chemical contamination. A high reading combined with other unusual sensor values is a stronger indicator of an unsafe sample than any single reading alone.',
    ),
  ];

  static const String fallback =
      'I don\'t have a specific answer for that yet, but you can ask me about turbidity, pH, urea, milk dilution, TDS, or gas readings — or whether boiling helps with your specific result.';
}
