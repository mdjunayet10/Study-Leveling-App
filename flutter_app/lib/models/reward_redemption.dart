class RewardRedemption {
  RewardRedemption({
    required this.rewardName,
    required this.cost,
    required this.redeemedAt,
  });

  factory RewardRedemption.fromJson(Map<String, dynamic> json) {
    final redeemedAtValue = json['redeemedAt'];

    return RewardRedemption(
      rewardName: (json['rewardName'] ?? '').toString(),
      cost: (json['cost'] as num? ?? 0).toInt(),
      redeemedAt: redeemedAtValue == null
          ? DateTime.now()
          : DateTime.tryParse(redeemedAtValue.toString()) ?? DateTime.now(),
    );
  }

  final String rewardName;
  final int cost;
  final DateTime redeemedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rewardName': rewardName,
      'cost': cost,
      'redeemedAt': redeemedAt.toIso8601String(),
    };
  }

  RewardRedemption copy() {
    return RewardRedemption(
      rewardName: rewardName,
      cost: cost,
      redeemedAt: DateTime.fromMillisecondsSinceEpoch(
        redeemedAt.millisecondsSinceEpoch,
      ),
    );
  }
}
