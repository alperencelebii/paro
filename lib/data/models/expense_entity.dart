
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExpenseModel {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final IconData? icon;
  final Color? color;
  final String userId;

  const ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.icon,
    this.color,
    required this.userId,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: (json['date'] as Timestamp).toDate(),
      category: json['category'] as String,
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'userId': userId,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? category,
    IconData? icon,
    Color? color,
    String? userId,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      userId: userId ?? this.userId,
    );
  }
}
