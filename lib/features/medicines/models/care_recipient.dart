import 'package:flutter/foundation.dart';

@immutable
class CareRecipient {
  const CareRecipient({
    this.id,
    required this.name,
    this.relationship,
    this.createdAtUtc,
  });

  final int? id;
  final String name;
  final String? relationship;
  final int? createdAtUtc;

  CareRecipient copyWith({String? name, String? relationship}) => CareRecipient(
    id: id,
    name: name ?? this.name,
    relationship: relationship ?? this.relationship,
    createdAtUtc: createdAtUtc,
  );
}
