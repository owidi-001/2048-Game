class Tile {
  final int id;
  final int value;
  final int row;
  final int col;
  final bool isNew;
  final bool isMerged;
  final bool isAbsorbed;

  const Tile({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
    this.isNew = false,
    this.isMerged = false,
    this.isAbsorbed = false,
  });

  Tile copyWith({
    int? value,
    int? row,
    int? col,
    bool? isNew,
    bool? isMerged,
    bool? isAbsorbed,
  }) {
    return Tile(
      id: id,
      value: value ?? this.value,
      row: row ?? this.row,
      col: col ?? this.col,
      isNew: isNew ?? this.isNew,
      isMerged: isMerged ?? this.isMerged,
      isAbsorbed: isAbsorbed ?? this.isAbsorbed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
        'row': row,
        'col': col,
      };

  factory Tile.fromJson(Map<String, dynamic> json) => Tile(
        id: json['id'] as int,
        value: json['value'] as int,
        row: json['row'] as int,
        col: json['col'] as int,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tile &&
          id == other.id &&
          value == other.value &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => Object.hash(id, value, row, col);
}
