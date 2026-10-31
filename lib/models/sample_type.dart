enum SampleType { water, milk }

extension SampleTypeX on SampleType {
  String get label {
    switch (this) {
      case SampleType.water:
        return 'Water';
      case SampleType.milk:
        return 'Milk';
    }
  }
}
