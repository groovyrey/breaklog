/// A user-facing move type. Defaults ship with the app; the user can add more,
/// and every category shows up in the vocabulary filter.
class MoveCategory {
  const MoveCategory(this.name);

  final String name;

  static const defaults = [
    MoveCategory('Toprock'),
    MoveCategory('Footwork'),
    MoveCategory('Power'),
    MoveCategory('Freeze'),
    MoveCategory('Combo'),
  ];

  static MoveCategory fromJson(dynamic raw) {
    if (raw is Map) return MoveCategory((raw['name'] as String?) ?? '');
    return MoveCategory((raw as String?) ?? '');
  }

  Map<String, dynamic> toJson() => {'name': name};
}
