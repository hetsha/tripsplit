class TransactionSplit {
  final int userId;
  final String name;
  final double amount;

  TransactionSplit({
    required this.userId,
    required this.name,
    required this.amount,
  });

  factory TransactionSplit.fromJson(Map<String, dynamic> json) {
    return TransactionSplit(
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      name: json['name'] ?? 'Member',
      amount: double.parse(json['amount'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'amount': amount,
    };
  }
}

class Transaction {
  final int id;
  final String type; // 'expense', 'income', 'settlement'
  final double amount;
  final String description;
  final String paymentMethod;
  final String paymentMethodLabel;
  final String paymentMethodIcon;
  final String date;
  final String formattedAmount;
  final String formattedDate;
  final String? notes;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final int? categoryId;
  final int? payerId;
  final String? payerName;
  final String? payerColor;
  final int? receiverId;
  final String? receiverName;
  final List<TransactionSplit> splits;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.paymentMethod,
    required this.paymentMethodLabel,
    required this.paymentMethodIcon,
    required this.date,
    required this.formattedAmount,
    required this.formattedDate,
    this.notes,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.categoryId,
    this.payerId,
    this.payerName,
    this.payerColor,
    this.receiverId,
    this.receiverName,
    required this.splits,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    var rawSplits = json['splits'] as List?;
    List<TransactionSplit> parsedSplits = rawSplits != null
        ? rawSplits.map((s) => TransactionSplit.fromJson(s)).toList()
        : [];

    return Transaction(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      type: json['type'] ?? 'expense',
      amount: double.parse(json['amount'].toString()),
      description: json['description'] ?? '',
      paymentMethod: json['payment_method'] ?? 'cash',
      paymentMethodLabel: json['payment_method_label'] ?? 'Cash',
      paymentMethodIcon: json['payment_method_icon'] ?? '💵',
      date: json['transaction_date'] ?? '',
      formattedAmount: json['formatted_amount'] ?? '',
      formattedDate: json['formatted_date'] ?? '',
      notes: json['notes'],
      categoryName: json['category_name'],
      categoryIcon: json['category_icon'],
      categoryColor: json['category_color'],
      categoryId: json['category_id'] != null
          ? (json['category_id'] is int ? json['category_id'] : int.parse(json['category_id'].toString()))
          : null,
      payerId: json['payer_id'] != null
          ? (json['payer_id'] is int ? json['payer_id'] : int.parse(json['payer_id'].toString()))
          : null,
      payerName: json['payer_name'],
      payerColor: json['payer_color'],
      receiverId: json['receiver_id'] != null
          ? (json['receiver_id'] is int ? json['receiver_id'] : int.parse(json['receiver_id'].toString()))
          : null,
      receiverName: json['receiver_name'],
      splits: parsedSplits,
    );
  }
}
