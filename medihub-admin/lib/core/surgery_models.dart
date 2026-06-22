class SurgeryTeamMemberDto {
  final String? id;
  final String staffId;
  final String staffName;
  final String role;
  final String note;

  const SurgeryTeamMemberDto({
    this.id,
    required this.staffId,
    required this.staffName,
    required this.role,
    required this.note,
  });

  factory SurgeryTeamMemberDto.fromJson(Map<String, dynamic> json) =>
      SurgeryTeamMemberDto(
        id: json['id']?.toString(),
        staffId: json['staffId']?.toString() ?? '',
        staffName: json['staffName']?.toString() ?? '',
        role: json['role']?.toString() ?? 'OTHER',
        note: json['note']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'staffId': staffId,
    'staffName': staffName,
    'role': role,
    'note': note,
  };
}

class SurgeryConsumableDto {
  final String? id;
  final String? itemId;
  final String itemType;
  final String itemName;
  final double quantity;
  final String unit;
  final int? unitPrice;
  final int? totalPrice;
  final String note;

  const SurgeryConsumableDto({
    this.id,
    this.itemId,
    required this.itemType,
    required this.itemName,
    required this.quantity,
    required this.unit,
    this.unitPrice,
    this.totalPrice,
    required this.note,
  });

  factory SurgeryConsumableDto.fromJson(Map<String, dynamic> json) =>
      SurgeryConsumableDto(
        id: json['id']?.toString(),
        itemId: json['itemId']?.toString(),
        itemType: json['itemType']?.toString() ?? 'OTHER',
        itemName: json['itemName']?.toString() ?? '',
        quantity: double.tryParse('${json['quantity'] ?? 1}') ?? 1,
        unit: json['unit']?.toString() ?? '',
        unitPrice: int.tryParse('${json['unitPrice'] ?? ''}'),
        totalPrice: int.tryParse('${json['totalPrice'] ?? ''}'),
        note: json['note']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'itemType': itemType,
    'itemName': itemName,
    'quantity': quantity,
    'unit': unit,
    'unitPrice': unitPrice,
    'note': note,
  };
}

class SurgeryCaseDto {
  final Map<String, dynamic> data;
  const SurgeryCaseDto(this.data);

  factory SurgeryCaseDto.fromJson(Map<String, dynamic> json) =>
      SurgeryCaseDto(json);

  String get id => data['id']?.toString() ?? '';
  String get surgeryCode => data['surgeryCode']?.toString() ?? '';
  String get patient => data['patient']?.toString() ?? '';
  String get title => data['title']?.toString() ?? '';
  String get status => data['status']?.toString() ?? '';
}

class SurgeryCaseDetailDto extends SurgeryCaseDto {
  const SurgeryCaseDetailDto(super.data);

  factory SurgeryCaseDetailDto.fromJson(Map<String, dynamic> json) =>
      SurgeryCaseDetailDto(json);

  List<SurgeryTeamMemberDto> get teamMembers =>
      (data['teamMembers'] as List? ?? const [])
          .map(
            (item) => SurgeryTeamMemberDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

  List<SurgeryConsumableDto> get consumables =>
      (data['consumables'] as List? ?? const [])
          .map(
            (item) => SurgeryConsumableDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
}
