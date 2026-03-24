enum AgeGroup {
  preschool,    // 4-6
  earlyPrimary, // 6-8
  latePrimary,  // 8-10
}

extension AgeGroupConfig on AgeGroup {
  double get buttonScale => switch (this) {
    AgeGroup.preschool => 1.4,
    AgeGroup.earlyPrimary => 1.2,
    AgeGroup.latePrimary => 1.0,
  };

  double get highlightOpacity => switch (this) {
    AgeGroup.preschool => 0.85,
    AgeGroup.earlyPrimary => 0.6,
    AgeGroup.latePrimary => 0.35,
  };

  double get dimOpacity => switch (this) {
    AgeGroup.preschool => 0.8,
    AgeGroup.earlyPrimary => 0.5,
    AgeGroup.latePrimary => 0.25,
  };

  bool get autoTtsDefault => switch (this) {
    AgeGroup.preschool => true,
    AgeGroup.earlyPrimary => true,
    AgeGroup.latePrimary => false,
  };
}
