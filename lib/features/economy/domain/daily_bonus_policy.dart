class DailyBonusPolicy {
  DailyBonusPolicy({this.lastClaimDate = ''});

  String lastClaimDate;

  bool isClaimedOn(String date) => lastClaimDate == date;

  void recordClaim(String date) => lastClaimDate = date;

  void reset() => lastClaimDate = '';
}
