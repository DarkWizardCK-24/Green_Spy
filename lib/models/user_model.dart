import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class UserModel {
  final String userId;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? job;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    this.job,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
  });

  // Calculate age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'job': job,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
    };
  }

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: data['userId'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'],
      gender: data['gender'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      job: data['job'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
    );
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? name,
    String? phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
    String? job,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      job: job ?? this.job,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  // Get initials for avatar
  String getInitials() {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty
        ? name.substring(0, min(2, name.length)).toUpperCase()
        : 'U';
  }

  // Get random avatar color based on user ID
  Color getAvatarColor() {
    final colors = [
      const Color(0xFF00FF88), // Primary Green
      const Color(0xFF3742FA), // Blue
      const Color(0xFFFFA502), // Orange
      const Color(0xFFFF6348), // Red
      const Color(0xFF5352ED), // Purple
      const Color(0xFF2ED573), // Light Green
      const Color(0xFF00D2FF), // Cyan
      const Color(0xFFFF4757), // Pink
    ];

    // Use userId hash to consistently generate same color for same user
    final hash = userId.hashCode.abs();
    return colors[hash % colors.length];
  }
}
