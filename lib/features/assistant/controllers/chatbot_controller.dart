import '../data/faq_data.dart';

/// Free, fully offline, rule-based chatbot logic. Matches the user's message
/// against keyword lists in FaqData — no API cost, no internet dependency,
/// and easily explainable in an FYP defense as "not a black box."
class ChatbotController {
  String getAnswer(String userMessage) {
    final lower = userMessage.toLowerCase();

    for (final entry in FaqData.entries) {
      for (final keyword in entry.keywords) {
        if (lower.contains(keyword)) {
          return entry.answer;
        }
      }
    }

    return FaqData.fallback;
  }

  /// Builds a friendly opening message when the chat is opened from a specific
  /// test result.
  ///
  /// The inconclusive branch comes first deliberately. If the model wasn't
  /// confident, the assistant must not start chatting about a contaminant it
  /// isn't sure is there — that would reintroduce, in conversational form, the
  /// exact false confidence the result screen suppresses.
  String buildContextGreeting({
    required String sampleType,
    String? contaminant,
    bool isInconclusive = false,
    double? purityPercent,
  }) {
    if (isInconclusive) {
      return 'Hi! Your $sampleType test came back inconclusive — the model wasn\'t '
          'confident enough to give a verdict, so I won\'t guess. Ask me how to '
          'get a cleaner reading, or about the Sensor Flush protocol.';
    }

    final purityNote = purityPercent != null
        ? ' It came out around ${purityPercent.toStringAsFixed(0)}% pure.'
        : '';

    if (contaminant == null || contaminant.toLowerCase() == 'none detected') {
      return 'Hi! Your $sampleType sample looked clean.$purityNote Ask me anything '
          'about water or milk safety.';
    }
    return 'Hi! I see your $sampleType test flagged "$contaminant".$purityNote Ask me '
        'what it means, whether it\'s dangerous, or what to do next.';
  }
}
