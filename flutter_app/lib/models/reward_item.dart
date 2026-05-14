class RewardItem {
  RewardItem({required this.name, required this.cost, this.isCustom = false});

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      name: (json['name'] ?? '').toString(),
      cost: (json['cost'] as num? ?? 0).toInt(),
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  String name;
  int cost;
  bool isCustom;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'name': name, 'cost': cost, 'isCustom': isCustom};
  }

  RewardItem copy() {
    return RewardItem(name: name, cost: cost, isCustom: isCustom);
  }

  @override
  String toString() => '$name - $cost POINTS';
}
