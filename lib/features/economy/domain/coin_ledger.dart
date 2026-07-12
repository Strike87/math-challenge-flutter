class CoinLedger {
  CoinLedger({this.balance = 0});

  int balance;

  void adjust(int amount) {
    balance += amount;
  }

  void reset() {
    balance = 0;
  }
}
