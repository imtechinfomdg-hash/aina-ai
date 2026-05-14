class ChildModel {
  final int? id;
  final String firstName;
  final DateTime birthDate;
  final String gender;
  final double? weight;
  final double? height;

  ChildModel({
    this.id,
    required this.firstName,
    required this.birthDate,
    required this.gender,
    this.weight,
    this.height,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'weight': weight,
      'height': height,
    };
  }

  factory ChildModel.fromMap(Map<String, dynamic> map) {
    return ChildModel(
      id: map['id'],
      firstName: map['firstName'],
      birthDate: DateTime.parse(map['birthDate']),
      gender: map['gender'],
      weight: map['weight'],
      height: map['height'],
    );
  }
}
