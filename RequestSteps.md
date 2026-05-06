# دليل خطوات إنشاء API Request جديد

هذا الدليل يحتوي على خطوات واضحة لإنشاء API Request جديد في المشروع. فقط قم بإعطاء AI المعلومات التالية واتبع الخطوات.

## المعلومات المطلوبة منك:

1. **اسم الـ Entity** (مثال: `Address`, `Order`, `Product`)
2. **نوع الطلب** (`GET`, `POST`, `PUT`, `DELETE`, `PATCH`)
3. **Endpoint** (مثال: `v1/account/addresses`)
4. **هل يوجد Pagination؟** (`نعم` أو `لا`)
5. **هيكل الاستجابة (Response Structure)** - JSON structure
6. **المعاملات (Parameters)** المطلوبة (query parameters, body parameters)

---

## الخطوات:

### الخطوة 1: إنشاء Entity

**الموقع:** `lib/features/[feature_name]/domain/entities/[entity_name].dart`

**القواعد:**
- يجب أن يرث من `Equatable`
- جميع الحقول `final`
- يجب أن يحتوي على `props` override

**مثال:**
```dart
import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final int id;
  final String title;
  final String street;
  final String building;
  final String floor;
  final String apartment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Address({
    required this.id,
    required this.title,
    required this.street,
    required this.building,
    required this.floor,
    required this.apartment,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    street,
    building,
    floor,
    apartment,
    createdAt,
    updatedAt,
  ];
}
```

---

### الخطوة 2: إضافة الدالة في Repository Interface

**الموقع:** `lib/features/[feature_name]/domain/repositories/[feature_name]_repository.dart`

**القواعد:**
- إذا كان مع pagination: `Future<Either<Failure, Paginator<Entity>>>`
- إذا كان بدون pagination: `Future<Either<Failure, Entity>>` أو `Future<Either<Failure, List<Entity>>>`

**مثال مع Pagination:**
```dart
Future<Either<Failure, Paginator<Address>>> getAddresses({
  int page = 1,
  int limit = 10,
});
```

**مثال بدون Pagination:**
```dart
Future<Either<Failure, Address>> getAddressById(int id);
// أو
Future<Either<Failure, List<Address>>> getAllAddresses();
```

---

### الخطوة 3: إنشاء UseCase مع Params

**الموقع:** `lib/features/[feature_name]/domain/usecases/[use_case_name]_use_case.dart`

**القواعد:**
- يجب أن يطبق `UseCase<ReturnType, ParamsClass>`
- يجب إنشاء `Params` class يرث من `Equatable`
- استخدم `NoParams` إذا لم تكن هناك parameters

**مثال مع Pagination:**
```dart
import 'package:basta_app/core/errors/failures.dart';
import 'package:basta_app/core/services/paginator/paginator.dart';
import 'package:basta_app/core/usecases/usecase.dart';
import 'package:basta_app/features/main/domain/entities/address.dart';
import 'package:basta_app/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetAddressesUseCase
    implements UseCase<Paginator<Address>, GetAddressesParams> {
  final MainRepository mainRepository;

  GetAddressesUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, Paginator<Address>>> call(
    GetAddressesParams params,
  ) async {
    return mainRepository.getAddresses(
      page: params.page,
      limit: params.limit,
    );
  }
}

class GetAddressesParams extends Equatable {
  final int page;
  final int limit;

  const GetAddressesParams({required this.page, required this.limit});

  @override
  List<Object?> get props => [page, limit];
}
```

**مثال بدون Pagination:**
```dart
class GetAddressByIdUseCase implements UseCase<Address, GetAddressByIdParams> {
  final MainRepository mainRepository;

  GetAddressByIdUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, Address>> call(
    GetAddressByIdParams params,
  ) async {
    return mainRepository.getAddressById(params.id);
  }
}

class GetAddressByIdParams extends Equatable {
  final int id;

  const GetAddressByIdParams({required this.id});

  @override
  List<Object?> get props => [id];
}
```

---

### الخطوة 4: إنشاء Model

**الموقع:** `lib/features/[feature_name]/data/models/[entity_name]_model.dart`

**القواعد:**
- يجب أن يرث من الـ Entity
- يجب أن يحتوي على `factory fromJson` و `toJson`

**مثال:**
```dart
import 'package:basta_app/features/main/domain/entities/address.dart';

class AddressModel extends Address {
  const AddressModel({
    required super.id,
    required super.title,
    required super.street,
    required super.building,
    required super.floor,
    required super.apartment,
    required super.createdAt,
    required super.updatedAt,
  }) : super();

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
    id: json['id'] as int,
    title: json['title'] as String,
    street: json['street'] as String,
    building: json['building'] as String,
    floor: json['floor'] as String,
    apartment: json['apartment'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'street': street,
    'building': building,
    'floor': floor,
    'apartment': apartment,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
```

**ملاحظات مهمة:**
- عند تحويل `DateTime`: استخدم `DateTime.parse(json['created_at'] as String)`
- عند تحويل `bool`: تأكد من التعامل مع `1/0` أو `true/false` حسب API
- عند تحويل `double`: استخدم `(json['field'] as num).toDouble()`

---

### الخطوة 5: إضافة الدالة في Remote Data Source

**الموقع:** `lib/features/[feature_name]/data/datasources/[feature_name]_remote_data_source.dart`

**القواعد:**
- أضف الدالة في الـ abstract interface
- نفذها في الـ implementation class
- إذا كان مع pagination: استخدم `PaginatorModel<EntityModel>.fromJson`
- إذا كان بدون pagination: استخدم `EntityModel.fromJson` مباشرة

**مثال مع Pagination (GET):**
```dart
// في الـ interface
Future<PaginatorModel<AddressModel>> getAddresses({
  int page = 1,
  int limit = 10,
});

// في الـ implementation
@override
Future<PaginatorModel<AddressModel>> getAddresses({
  int page = 1,
  int limit = 10,
}) async {
  final response = await apiConsumer.get(
    'v1/account/addresses',
    queryParameters: {'page': page, 'limit': limit},
  );
  return PaginatorModel<AddressModel>.fromJson(
    response as Map<String, dynamic>,
    (m) => AddressModel.fromJson(m),
  );
}
```

**مثال بدون Pagination (GET):**
```dart
// في الـ interface
Future<AddressModel> getAddressById(int id);

// في الـ implementation
@override
Future<AddressModel> getAddressById(int id) async {
  final response = await apiConsumer.get('v1/account/addresses/$id');
  return AddressModel.fromJson(response['data'] as Map<String, dynamic>);
}
```

**مثال POST/PUT/PATCH:**
```dart
// في الـ interface
Future<AddressModel> createAddress({
  required String title,
  required String street,
  required String building,
  String? floor,
  String? apartment,
});

// في الـ implementation
@override
Future<AddressModel> createAddress({
  required String title,
  required String street,
  required String building,
  String? floor,
  String? apartment,
}) async {
  final response = await apiConsumer.post(
    'v1/account/addresses',
    body: {
      'title': title,
      'street': street,
      'building': building,
      if (floor != null) 'floor': floor,
      if (apartment != null) 'apartment': apartment,
    },
  );
  return AddressModel.fromJson(response['data'] as Map<String, dynamic>);
}
```

**ملاحظات:**
- للـ POST/PUT/PATCH مع ملفات: استخدم `isFormData: true`
- استخدم `queryParameters` للـ query params في GET
- استخدم `body` للـ body parameters في POST/PUT/PATCH

---

### الخطوة 6: تنفيذ Repository Implementation

**الموقع:** `lib/features/[feature_name]/data/repositories/[feature_name]_repository_impl.dart`

**القواعد:**
- استخدم `_handleRemoteCall` للتعامل مع الأخطاء
- حول `EntityModel` إلى `Entity` (يحدث تلقائياً لأن Model يرث من Entity)

**مثال:**
```dart
@override
Future<Either<Failure, Paginator<Address>>> getAddresses({
  int page = 1,
  int limit = 10,
}) async {
  return _handleRemoteCall(
    () => mainRemoteDataSource.getAddresses(page: page, limit: limit),
  );
}
```

---

### الخطوة 7: إضافة UseCase إلى Injector Container

**الموقع:** `lib/core/config/injector_container.dart`

**القواعد:**
- أضف الـ UseCase في الـ Feature Injector المناسب
- استخدم `Get.lazyPut` مع `fenix: true`

**مثال:**
```dart
class MainFeatureInjector {
  static void init() {
    // ... existing code ...

    // UseCases
    Get.lazyPut(
      () => GetProductsUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetAddressesUseCase(mainRepository: Get.find()),
      fenix: true,
    );
  }
}
```

---

## أمثلة كاملة:

### مثال 1: GET مع Pagination

**المعلومات:**
- Entity: `Address`
- Type: `GET`
- Endpoint: `v1/account/addresses`
- Pagination: `نعم`
- Response: 
```json
{
  "data": {
    "data": [
      {
        "id": 1,
        "title": "Home",
        "street": "Main Street",
        "building": "Building 1",
        "floor": "3",
        "apartment": "101",
        "created_at": "2024-01-01T00:00:00",
        "updated_at": "2024-01-01T00:00:00"
      }
    ],
    "current_page": 1,
    "last_page": 5,
    "per_page": 10,
    "total": 50
  }
}
```

**الخطوات:**
1. ✅ إنشاء `Address` entity
2. ✅ إضافة `getAddresses` في `MainRepository` interface
3. ✅ إنشاء `GetAddressesUseCase` مع `GetAddressesParams`
4. ✅ إنشاء `AddressModel`
5. ✅ إضافة `getAddresses` في `MainRemoteDataSource`
6. ✅ تنفيذ `getAddresses` في `MainRepositoryImpl`
7. ✅ إضافة `GetAddressesUseCase` في `MainFeatureInjector`

---

### مثال 2: GET بدون Pagination

**المعلومات:**
- Entity: `Address`
- Type: `GET`
- Endpoint: `v1/account/addresses/1`
- Pagination: `لا`
- Response:
```json
{
  "data": {
    "id": 1,
    "title": "Home",
    "street": "Main Street",
    "building": "Building 1",
    "floor": "3",
    "apartment": "101",
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
}
```

**الخطوات:**
1. ✅ إنشاء `Address` entity (إذا لم يكن موجوداً)
2. ✅ إضافة `getAddressById(int id)` في `MainRepository` interface
3. ✅ إنشاء `GetAddressByIdUseCase` مع `GetAddressByIdParams`
4. ✅ إنشاء `AddressModel` (إذا لم يكن موجوداً)
5. ✅ إضافة `getAddressById(int id)` في `MainRemoteDataSource`
6. ✅ تنفيذ `getAddressById` في `MainRepositoryImpl`
7. ✅ إضافة `GetAddressByIdUseCase` في `MainFeatureInjector`

---

### مثال 3: POST بدون Pagination

**المعلومات:**
- Entity: `Address`
- Type: `POST`
- Endpoint: `v1/account/addresses`
- Pagination: `لا`
- Body Parameters: `title`, `street`, `building`, `floor?`, `apartment?`
- Response:
```json
{
  "data": {
    "id": 1,
    "title": "Home",
    "street": "Main Street",
    "building": "Building 1",
    "floor": "3",
    "apartment": "101",
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
}
```

**الخطوات:**
1. ✅ إنشاء `Address` entity (إذا لم يكن موجوداً)
2. ✅ إضافة `createAddress(...)` في `MainRepository` interface
3. ✅ إنشاء `CreateAddressUseCase` مع `CreateAddressParams`
4. ✅ إنشاء `AddressModel` (إذا لم يكن موجوداً)
5. ✅ إضافة `createAddress(...)` في `MainRemoteDataSource`
6. ✅ تنفيذ `createAddress` في `MainRepositoryImpl`
7. ✅ إضافة `CreateAddressUseCase` في `MainFeatureInjector`

---

## ملاحظات مهمة:

1. **Pagination Structure**: إذا كان الـ API يستخدم pagination، تأكد من أن هيكل JSON يحتوي على:
   - `data.data` للقائمة
   - `data.current_page`, `data.last_page`, `data.per_page`, `data.total` للـ meta

2. **Non-Pagination Structure**: إذا لم يكن هناك pagination، تأكد من أن الـ response يحتوي على `data` مباشرة

3. **Feature Name**: تأكد من استخدام اسم الـ feature الصحيح (مثل `main`, `auth`, `global`)

4. **File Naming**: استخدم أسماء واضحة:
   - Entity: `[entity_name].dart`
   - Model: `[entity_name]_model.dart`
   - UseCase: `[action]_[entity_name]_use_case.dart` (مثال: `get_addresses_use_case.dart`)

5. **Import Paths**: تأكد من استخدام المسارات الصحيحة:
   - Domain entities: `basta_app/features/[feature]/domain/entities/...`
   - Data models: `basta_app/features/[feature]/data/models/...`
   - UseCases: `basta_app/features/[feature]/domain/usecases/...`

---

## قالب جاهز للاستخدام:

عند إعطاء المعلومات للـ AI، استخدم هذا القالب:

```
أريد إنشاء API Request جديد:

1. Entity Name: [اسم الـ Entity]
2. Request Type: [GET/POST/PUT/DELETE/PATCH]
3. Endpoint: [endpoint path]
4. Pagination: [نعم/لا]
5. Response Structure:
[JSON structure هنا]
6. Parameters:
- Query Parameters (إذا موجودة): [list]
- Body Parameters (إذا موجودة): [list]

الرجاء اتباع RequestSteps.md
```

---

## Checklist قبل الانتهاء:

- [ ] Entity تم إنشاؤه ويرث من Equatable
- [ ] Repository interface يحتوي على الدالة
- [ ] UseCase تم إنشاؤه مع Params class
- [ ] Model تم إنشاؤه مع fromJson و toJson
- [ ] Remote Data Source يحتوي على الدالة (interface + implementation)
- [ ] Repository Implementation ينفذ الدالة
- [ ] UseCase تم إضافته في Injector Container
- [ ] جميع الـ imports صحيحة
- [ ] تم اختبار الـ types والـ conversions

