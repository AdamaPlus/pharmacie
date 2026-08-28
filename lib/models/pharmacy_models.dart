// ==========================================
// 1. PRODUCT & LOT MODELS
// ==========================================

class Product {
  final String id;
  final String name;
  final String description;
  final String barcode;
  final double purchasePrice;
  final double sellingPrice;
  final double vat; // TVA percentage (e.g. 18.0)
  final String category;
  final String supplierName;
  final String image;
  final int minStock;
  int totalQuantity;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.barcode,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.vat,
    required this.category,
    required this.supplierName,
    required this.image,
    required this.minStock,
    this.totalQuantity = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'barcode': barcode,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'vat': vat,
      'category': category,
      'supplierName': supplierName,
      'image': image,
      'minStock': minStock,
      'totalQuantity': totalQuantity,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      barcode: map['barcode'] ?? '',
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      vat: (map['vat'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      supplierName: map['supplierName'] ?? '',
      image: map['image'] ?? '',
      minStock: (map['minStock'] as num?)?.toInt() ?? 0,
      totalQuantity: (map['totalQuantity'] as num?)?.toInt() ?? 0,
    );
  }
}

class Lot {
  final String id;
  final String productId;
  final String productName;
  final String lotNumber;
  final DateTime expirationDate;
  int quantity;

  Lot({
    required this.id,
    required this.productId,
    required this.productName,
    required this.lotNumber,
    required this.expirationDate,
    required this.quantity,
  });

  bool get isExpired => expirationDate.isBefore(DateTime.now());
  bool get isNearExpiration =>
      expirationDate.isBefore(DateTime.now().add(const Duration(days: 90))) &&
      !isExpired;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'lotNumber': lotNumber,
      'expirationDate': expirationDate.toIso8601String(),
      'quantity': quantity,
    };
  }

  factory Lot.fromMap(Map<String, dynamic> map) {
    return Lot(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      lotNumber: map['lotNumber'] ?? '',
      expirationDate: DateTime.parse(
          map['expirationDate'] ?? DateTime.now().toIso8601String()),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

// ==========================================
// 2. STOCK MOVEMENTS
// ==========================================

class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final String type; // 'ENTREE', 'SORTIE', 'TRANSFERT', 'AJUSTEMENT'
  final int quantity;
  final DateTime date;
  final String reason;
  final String user;

  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.date,
    required this.reason,
    required this.user,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'type': type,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'reason': reason,
      'user': user,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      type: map['type'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      reason: map['reason'] ?? '',
      user: map['user'] ?? 'System',
    );
  }
}

// ==========================================
// 3. SALES & POS MODELS
// ==========================================

class SaleItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double vat; // TVA percentage
  final double total;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.vat,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'vat': vat,
      'total': total,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      vat: (map['vat'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Sale {
  final String id;
  final DateTime date;
  final List<SaleItem> items;
  final double totalAmount;
  final double discountAmount;
  final double netAmount;
  final String paymentMethod; // 'ESPECES', 'CARTE', 'CHEQUE'
  final double cashReceived;
  final double changeReturned;
  final String cashierName;
  final String? patientId;
  final String? patientName;

  Sale({
    required this.id,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.discountAmount,
    required this.netAmount,
    required this.paymentMethod,
    required this.cashReceived,
    required this.changeReturned,
    required this.cashierName,
    this.patientId,
    this.patientName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'netAmount': netAmount,
      'paymentMethod': paymentMethod,
      'cashReceived': cashReceived,
      'changeReturned': changeReturned,
      'cashierName': cashierName,
      'patientId': patientId,
      'patientName': patientName,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    var itemsList = map['items'] as List? ?? [];
    return Sale(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      items: itemsList.map((item) => SaleItem.fromMap(item)).toList(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      netAmount: (map['netAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'ESPECES',
      cashReceived: (map['cashReceived'] as num?)?.toDouble() ?? 0.0,
      changeReturned: (map['changeReturned'] as num?)?.toDouble() ?? 0.0,
      cashierName: map['cashierName'] ?? '',
      patientId: map['patientId'],
      patientName: map['patientName'],
    );
  }
}

// ==========================================
// 4. PRESCRIPTION MODELS
// ==========================================

class PrescriptionItem {
  final String medicineName;
  final String dosage;
  final String duration;
  final int quantityPrescribed;

  PrescriptionItem({
    required this.medicineName,
    required this.dosage,
    required this.duration,
    required this.quantityPrescribed,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'dosage': dosage,
      'duration': duration,
      'quantityPrescribed': quantityPrescribed,
    };
  }

  factory PrescriptionItem.fromMap(Map<String, dynamic> map) {
    return PrescriptionItem(
      medicineName: map['medicineName'] ?? '',
      dosage: map['dosage'] ?? '',
      duration: map['duration'] ?? '',
      quantityPrescribed: (map['quantityPrescribed'] as num?)?.toInt() ?? 0,
    );
  }
}

class Prescription {
  final String id;
  final DateTime date;
  final String doctorName;
  final String patientId;
  final String patientName;
  final List<PrescriptionItem> medicines;
  final String dosageInstructions;
  bool isDispensed;
  DateTime? dispensedDate;
  final String safetyAlerts; // Interaction/allergy checks, if any
  final String illnessType; // Type de maladie / Diagnostic

  Prescription({
    required this.id,
    required this.date,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.medicines,
    required this.dosageInstructions,
    this.isDispensed = false,
    this.dispensedDate,
    required this.safetyAlerts,
    this.illnessType = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'doctorName': doctorName,
      'patientId': patientId,
      'patientName': patientName,
      'medicines': medicines.map((item) => item.toMap()).toList(),
      'dosageInstructions': dosageInstructions,
      'isDispensed': isDispensed,
      'dispensedDate': dispensedDate?.toIso8601String(),
      'safetyAlerts': safetyAlerts,
      'illnessType': illnessType,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    var medicinesList = map['medicines'] as List? ?? [];
    return Prescription(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      doctorName: map['doctorName'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      medicines:
          medicinesList.map((item) => PrescriptionItem.fromMap(item)).toList(),
      dosageInstructions: map['dosageInstructions'] ?? '',
      isDispensed: map['isDispensed'] ?? false,
      dispensedDate: map['dispensedDate'] != null
          ? DateTime.parse(map['dispensedDate'])
          : null,
      safetyAlerts: map['safetyAlerts'] ?? '',
      illnessType: map['illnessType'] ?? '',
    );
  }
}

// ==========================================
// 5. CLIENT & PATIENT MODELS
// ==========================================

class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String prescribedMedication;
  final String phone;
  final String email;
  final List<String> allergies;
  final List<String> medicalHistory;
  int loyaltyPoints;
  final String quartier;
  final String maladie;

  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.prescribedMedication,
    required this.phone,
    required this.email,
    required this.allergies,
    required this.medicalHistory,
    this.loyaltyPoints = 0,
    this.quartier = '',
    this.maladie = '',
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'prescribedMedication': prescribedMedication,
      'phone': phone,
      'email': email,
      'allergies': allergies,
      'medicalHistory': medicalHistory,
      'loyaltyPoints': loyaltyPoints,
      'quartier': quartier,
      'maladie': maladie,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      prescribedMedication: map['prescribedMedication'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      allergies: List<String>.from(map['allergies'] ?? []),
      medicalHistory: List<String>.from(map['medicalHistory'] ?? []),
      loyaltyPoints: (map['loyaltyPoints'] as num?)?.toInt() ?? 0,
      quartier: map['quartier'] ?? '',
      maladie: map['maladie'] ?? '',
    );
  }
}

// ==========================================
// 6. STAFF & PERSONNEL MODELS
// ==========================================

class Shift {
  final String id;
  final String dayOfWeek; // 'Lundi', 'Mardi', etc. or exact date
  final String startTime; // '08:00'
  final String endTime; // '17:00'

  Shift({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
    );
  }
}

class LeaveRequest {
  final String id;
  final String startDate;
  final String endDate;
  final String type; // 'CONGE_ANNUEL', 'MALADIE', 'MATERNITE', 'SANS_SOLDE'
  final String reason;
  String status; // 'PENDING', 'APPROVED', 'REJECTED'

  LeaveRequest({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.reason,
    this.status = 'PENDING',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate,
      'endDate': endDate,
      'type': type,
      'reason': reason,
      'status': status,
    };
  }

  factory LeaveRequest.fromMap(Map<String, dynamic> map) {
    return LeaveRequest(
      id: map['id'] ?? '',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      type: map['type'] ?? 'CONGE_ANNUEL',
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'PENDING',
    );
  }
}

class Employee {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String position; // 'PHARMACIEN', 'PREPARATEUR', 'CAISSIER', 'ADMIN'
  final String hireDate;
  final String contractInfo;
  final double hourlyRate;
  double hoursWorkedThisMonth;
  final List<Shift> planning;
  final List<LeaveRequest> leaveRequests;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.position,
    required this.hireDate,
    required this.contractInfo,
    required this.hourlyRate,
    this.hoursWorkedThisMonth = 0.0,
    required this.planning,
    required this.leaveRequests,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'position': position,
      'hireDate': hireDate,
      'contractInfo': contractInfo,
      'hourlyRate': hourlyRate,
      'hoursWorkedThisMonth': hoursWorkedThisMonth,
      'planning': planning.map((s) => s.toMap()).toList(),
      'leaveRequests': leaveRequests.map((l) => l.toMap()).toList(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    var planningList = map['planning'] as List? ?? [];
    var leavesList = map['leaveRequests'] as List? ?? [];
    return Employee(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      position: map['position'] ?? 'CAISSIER',
      hireDate: map['hireDate'] ?? '',
      contractInfo: map['contractInfo'] ?? '',
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 10.0,
      hoursWorkedThisMonth:
          (map['hoursWorkedThisMonth'] as num?)?.toDouble() ?? 0.0,
      planning: planningList.map((s) => Shift.fromMap(s)).toList(),
      leaveRequests: leavesList.map((l) => LeaveRequest.fromMap(l)).toList(),
    );
  }
}

// ==========================================
// 7. SUPPLIER MODELS
// ==========================================

class OrderItem {
  final String productId;
  final String productName;
  final int quantityOrdered;
  final int quantityReceived;
  final double unitPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantityOrdered,
    this.quantityReceived = 0,
    required this.unitPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantityOrdered': quantityOrdered,
      'quantityReceived': quantityReceived,
      'unitPrice': unitPrice,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantityOrdered: (map['quantityOrdered'] as num?)?.toInt() ?? 0,
      quantityReceived: (map['quantityReceived'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SupplierOrder {
  final String id;
  final DateTime date;
  final List<OrderItem> items;
  final double totalAmount;
  String status; // 'COMMANDE', 'RECUE_PARTIEL', 'RECUE', 'ANNULEE'

  SupplierOrder({
    required this.id,
    required this.date,
    required this.items,
    required this.totalAmount,
    this.status = 'COMMANDE',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
    };
  }

  factory SupplierOrder.fromMap(Map<String, dynamic> map) {
    var itemsList = map['items'] as List? ?? [];
    return SupplierOrder(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      items: itemsList.map((i) => OrderItem.fromMap(i)).toList(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'COMMANDE',
    );
  }
}

class SupplierInvoice {
  final String id;
  final String invoiceNumber;
  final double amount;
  final DateTime date;
  bool isPaid;

  SupplierInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.amount,
    required this.date,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'amount': amount,
      'date': date.toIso8601String(),
      'isPaid': isPaid,
    };
  }

  factory SupplierInvoice.fromMap(Map<String, dynamic> map) {
    return SupplierInvoice(
      id: map['id'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      isPaid: map['isPaid'] ?? false,
    );
  }
}

class Expense {
  final String id;
  final String label;
  final String category;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String notes;

  const Expense({
    required this.id,
    required this.label,
    required this.category,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'paymentMethod': paymentMethod,
        'notes': notes,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] ?? '',
        label: map['label'] ?? '',
        category: map['category'] ?? 'Autres',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
        paymentMethod: map['paymentMethod'] ?? 'Espèces',
        notes: map['notes'] ?? '',
      );
}

class Supplier {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String paymentTerms; // '30_JOURS', 'A_LA_RECEPTION', etc.
  final List<SupplierOrder> orders;
  final List<SupplierInvoice> invoices;

  Supplier({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.paymentTerms,
    required this.orders,
    required this.invoices,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'paymentTerms': paymentTerms,
      'orders': orders.map((o) => o.toMap()).toList(),
      'invoices': invoices.map((i) => i.toMap()).toList(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    var ordersList = map['orders'] as List? ?? [];
    var invoicesList = map['invoices'] as List? ?? [];
    return Supplier(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      paymentTerms: map['paymentTerms'] ?? 'A_LA_RECEPTION',
      orders: ordersList.map((o) => SupplierOrder.fromMap(o)).toList(),
      invoices: invoicesList.map((i) => SupplierInvoice.fromMap(i)).toList(),
    );
  }
}

// ==========================================
// 8. SECURITY & AUDIT MODELS
// ==========================================

class UserAccount {
  final String username;
  final String passwordHash; // simple representation
  final String employeeId;
  final String
      role; // 'PHARMACIEN', 'PREPARATEUR', 'CAISSIER', 'ADMIN', 'VENDEUR'
  final String fullName;
  final String email;
  final String password;
  final String
      pinCode; // Code PIN propre à chaque utilisateur (attribué par l'admin pour les vendeurs)
  final List<String> permissions;
  final String? profileImageBase64;

  UserAccount({
    required this.username,
    String? passwordHash,
    String? employeeId,
    required this.role,
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.pinCode = '',
    List<String>? permissions,
    this.profileImageBase64,
  })  : this.passwordHash = passwordHash ?? password,
        this.employeeId = employeeId ?? 'E001',
        this.permissions = permissions ??
            (role == 'ADMIN'
                ? [
                    'dashboard',
                    'pos',
                    'add_product',
                    'new_medicines',
                    'reports',
                    'archives',
                    'loans',
                    'replenish',
                    'suppliers',
                    'history'
                  ]
                : ['dashboard', 'pos', 'archives']);

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'passwordHash': passwordHash,
      'employeeId': employeeId,
      'role': role,
      'fullName': fullName,
      'email': email,
      'password': password,
      'pinCode': pinCode,
      'permissions': permissions,
      'profileImageBase64': profileImageBase64,
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      username: map['username'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      employeeId: map['employeeId'] ?? '',
      role: map['role'] ?? 'CAISSIER',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? (map['passwordHash'] ?? ''),
      pinCode: map['pinCode'] ?? '',
      permissions: map['permissions'] != null
          ? List<String>.from(map['permissions'])
          : null,
      profileImageBase64: map['profileImageBase64'],
    );
  }
}

class AuditLog {
  final String id;
  final DateTime timestamp;
  final String username;
  final String action;
  final String details;

  AuditLog({
    required this.id,
    required this.timestamp,
    required this.username,
    required this.action,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'username': username,
      'action': action,
      'details': details,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] ?? '',
      timestamp:
          DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      username: map['username'] ?? 'System',
      action: map['action'] ?? '',
      details: map['details'] ?? '',
    );
  }
}

// ==========================================
// 10. DETTES & EMPRUNTS MODELS
// ==========================================

class LoanItem {
  final String productName;
  final int quantity;
  final double unitValue;

  LoanItem({
    required this.productName,
    required this.quantity,
    required this.unitValue,
  });

  double get totalValue => quantity * unitValue;

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'quantity': quantity,
      'unitValue': unitValue,
    };
  }

  factory LoanItem.fromMap(Map<String, dynamic> map) {
    return LoanItem(
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitValue: (map['unitValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MedicamentLoan {
  final String id;
  final List<LoanItem> items;
  final String lenderType; // 'personne' or 'pharmacie'
  final String lenderName;
  final String lenderContact;
  final String lenderAddress;
  final DateTime loanDate;
  bool isReturned;
  final String notes;
  final String? saleId;

  MedicamentLoan({
    required this.id,
    required this.items,
    required this.lenderType,
    required this.lenderName,
    required this.lenderContact,
    required this.lenderAddress,
    required this.loanDate,
    this.isReturned = false,
    this.notes = '',
    this.saleId,
  });

  double get totalValue =>
      items.fold(0.0, (sum, item) => sum + item.totalValue);

  String get medicamentName =>
      items.isNotEmpty ? items.map((i) => i.productName).join(', ') : 'Aucun';
  int get quantity => items.fold(0, (sum, item) => sum + item.quantity);
  double get unitValue => items.isNotEmpty ? items.first.unitValue : 0.0;
  String get borrowerName => lenderName;
  double get amount => totalValue;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) => item.toMap()).toList(),
      'lenderType': lenderType,
      'lenderName': lenderName,
      'lenderContact': lenderContact,
      'lenderAddress': lenderAddress,
      'loanDate': loanDate.toIso8601String(),
      'isReturned': isReturned,
      'notes': notes,
      'saleId': saleId,
    };
  }

  factory MedicamentLoan.fromMap(Map<String, dynamic> map) {
    var itemsList = map['items'] as List? ?? [];
    return MedicamentLoan(
      id: map['id'] ?? '',
      items: itemsList.map((i) => LoanItem.fromMap(i)).toList(),
      lenderType: map['lenderType'] ?? 'personne',
      lenderName: map['lenderName'] ?? '',
      lenderContact: map['lenderContact'] ?? '',
      lenderAddress: map['lenderAddress'] ?? '',
      loanDate:
          DateTime.parse(map['loanDate'] ?? DateTime.now().toIso8601String()),
      isReturned: map['isReturned'] ?? false,
      notes: map['notes'] ?? '',
      saleId: map['saleId'],
    );
  }
}
