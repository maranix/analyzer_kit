import 'dart:io';

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart'
    show CorrectionProducerContext;
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart'
    show
        ClassDeclaration,
        FieldDeclaration,
        FormalParameter,
        InstanceCreationExpression,
        TopLevelVariableDeclaration;
import 'package:analyzer/error/error.dart' show DiagnosticCode;
import 'package:analyzer_kit/src/constants.dart';
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/fixes/add_composite_methods.dart';
import 'package:analyzer_kit/src/fixes/add_deserialize_method.dart';
import 'package:analyzer_kit/src/fixes/add_serialize_method.dart';
import 'package:analyzer_kit/src/fixes/override_to_string_method.dart';
import 'package:analyzer_kit/src/rules/analyzer_kit_rule.dart';
import 'package:analyzer_kit/src/utils/utils.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late AnalysisContextCollection collection;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('analyzer_kit_resolved_');
    final pkgConfigDir = Directory('${tempDir.path}/.dart_tool')..createSync();
    final annotationLibUri = Directory(
      '${Directory.current.path}/../analyzer_kit_annotation',
    ).uri;

    File('${pkgConfigDir.path}/package_config.json').writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "analyzer_kit_annotation",
      "rootUri": "$annotationLibUri",
      "packageUri": "lib/",
      "languageVersion": "3.10"
    },
    {
      "name": "test_pkg",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "3.14"
    }
  ]
}
''');
    File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: test_pkg
environment:
  sdk: ^3.14.0
''');
    Directory('${tempDir.path}/lib').createSync();
  });

  tearDownAll(() async {
    await collection.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<ResolvedUnitResult> resolveCode(String fileName, String code) async {
    final filePath = '${tempDir.path}/lib/$fileName';
    File(filePath).writeAsStringSync(code);
    collection = AnalysisContextCollection(includedPaths: [tempDir.path]);
    final result = await collection
        .contextFor(filePath)
        .currentSession
        .getResolvedUnit(filePath);
    return result as ResolvedUnitResult;
  }

  test('extractAnnotationConfig caches annotationNodes and resolves CompositeAnnotation', () async {
    final unitResult = await resolveCode('composite.dart', '''
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

const dataClass = CompositeAnnotation([
  CopyWith(nullable: true),
  OverrideEquality(),
  OverrideToString(),
  Serialize(),
  Deserialize(),
]);

@dataClass
class User {
  final String name;
  final String? bio;
  const User({required this.name, this.bio});
}
''');

    final cls = unitResult.unit.declarations
        .whereType<ClassDeclaration>()
        .single;
    final config = extractAnnotationConfig(cls);

    expect(config.hasCompositeAnnotation, isTrue);
    expect(config.copyWith, isTrue);
    expect(config.copyWithNullable, isTrue);
    expect(config.overrideEquality, isTrue);
    expect(config.overrideToString, isTrue);
    expect(config.serialize, isTrue);
    expect(config.deserialize, isTrue);
    expect(
      config.annotationNodes[FeatureAnnotation.copyWith],
      same(cls.metadata.single),
    );
    expect(
      config.annotationNodes[FeatureAnnotation.serialize],
      same(cls.metadata.single),
    );
  });

  test('AddCompositeMethods generates nested class, enum, DateTime, and generic code on resolved AST', () async {
    final unitResult = await resolveCode('nested_and_generic.dart', '''
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

enum Role { admin, member }

const dataClass = CompositeAnnotation([
  CopyWith(nullable: true),
  OverrideEquality(),
  OverrideToString(),
  Serialize(),
  Deserialize(),
]);

@Serialize(name: .toJson)
@Deserialize(name: .fromJson)
class Address {
  final String city;
  const Address({required this.city});

  Map<String, dynamic> toJson() => {'city': city};
  factory Address.fromJson(Map<String, dynamic> map) =>
      Address(city: map['city'] as String);
}

@dataClass
class Account<T> {
  final T payload;
  final Role role;
  final DateTime createdAt;
  final Address address;
  final List<Address> history;
  final String? nickname;

  const Account({
    required this.payload,
    required this.role,
    required this.createdAt,
    required this.address,
    required this.history,
    this.nickname,
  });
}
''');

    final accountClass = unitResult.unit.declarations
        .whereType<ClassDeclaration>()
        .firstWhere((c) => c.namePart.typeName.lexeme == 'Account');

    final fields = extractGeneratableFields(accountClass);
    expect(fields.map((f) => f.name), [
      'payload',
      'role',
      'createdAt',
      'address',
      'history',
      'nickname',
    ]);
    expect(fields[1].isEnumType, isTrue);
    expect(fields[2].isDateTimeType, isTrue);
    expect(fields[3].serializeMethodName, 'toJson');
    expect(fields[3].deserializeMethodName, 'fromJson');
    expect(fields[4].isListType, isTrue);
    expect(fields[4].typeArguments.single.serializeMethodName, 'toJson');

    final context = CorrectionProducerContext.createResolved(
      libraryResult: unitResult.libraryElement.session == unitResult.session
          ? await unitResult.session.getResolvedLibraryByElement(
              unitResult.libraryElement,
            ) as ResolvedLibraryResult
          : throw StateError('Unexpected session'),
      unitResult: unitResult,
      selectionOffset: accountClass.offset,
    );

    final builder = ChangeBuilder(session: unitResult.session);
    await AddCompositeMethods(context: context).compute(builder);

    final edits = builder.sourceChange.edits.single.edits;
    expect(edits, isNotEmpty);
    final inserted = edits.map((e) => e.replacement).join('\n');

    expect(inserted, contains('Account<T> copyWith('));
    expect(inserted, contains('String? Function()? nickname'));
    expect(inserted, contains('other is Account<T>'));
    expect(inserted, contains("'role': role.name"));
    expect(inserted, contains("'createdAt': createdAt.toIso8601String()"));
    expect(inserted, contains("'address': address.toJson()"));
    expect(inserted, contains('e.toJson()'));
    expect(inserted, contains('Address.fromJson'));
    expect(inserted, contains('Role.values.byName'));
    expect(inserted, contains('DateTime.parse'));
  });

  test('sync checks detect removed fields, nullable drift, and generic type argument drift', () async {
    final unitResult = await resolveCode('sync_drift.dart', '''
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@CopyWith(nullable: true)
@OverrideEquality()
@Deserialize()
class Box<T> {
  final T value;
  final String? label;

  const Box({required this.value, this.label});

  Box<T> copyWith({T? value, String? label}) =>
      Box<T>(value: value ?? this.value, label: label ?? this.label);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Box && other.value == value && other.label == label && other.removed == removed);

  @override
  int get hashCode => Object.hash(value, label);

  factory Box.fromMap(Map<String, dynamic> map) => Box<T>(
    value: map['value'] as T,
    label: map['label'] as String?,
    stale: map['stale'] as int,
  );
}
''');

    final cls = unitResult.unit.declarations
        .whereType<ClassDeclaration>()
        .single;
    final fields = extractGeneratableFields(cls);

    final copyWithMethod = findMethodDeclaration(cls, 'copyWith')!;
    final copySync = checkCopyWithSync(copyWithMethod, fields, nullable: true);
    expect(copySync.isInSync, isFalse);
    expect(copySync.summary, contains('nullable signature mismatch: label'));

    final equalsMethod = findMethodDeclaration(cls, '==')!;
    final hashMethod = findMethodDeclaration(cls, 'hashCode')!;
    final eqSync = checkEqualitySync(
      equalsMethod,
      hashMethod,
      fields,
      className: 'Box',
      typeArguments: '<T>',
    );
    expect(eqSync.isInSync, isFalse);
    expect(eqSync.extraFields, contains('removed'));
    expect(eqSync.driftReasons, contains('missing type arguments: <T>'));

    final fromMap = findDeserializeMember(cls, 'fromMap')!;
    final deserSync = checkDeserializeSync(fromMap, fields);
    expect(deserSync.isInSync, isFalse);
    expect(deserSync.extraFields, contains('stale'));
  });

  test('extracts inherited fields, non-primary positional params, Uri/Duration/BigInt, and auto-imports deep equality', () async {
    await resolveCode('base_model.dart', '''
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

const myBundle = CompositeAnnotation([
  CopyWith(),
  OverrideEquality(),
  Serialize(),
  Deserialize(),
]);

class BaseEntity {
  final int id;
  const BaseEntity(this.id);
}
''');

    final unitResult = await resolveCode('derived_model.dart', '''
import 'base_model.dart';

@myBundle
class DerivedEntity extends BaseEntity {
  final Uri link;
  final Duration ttl;
  final BigInt big;
  final List<String> tags;
  final String computed = 'v1';

  const DerivedEntity(
    super.id, {
    required this.link,
    required this.ttl,
    required this.big,
    required this.tags,
  });
}
''');

    final cls = unitResult.unit.declarations
        .whereType<ClassDeclaration>()
        .single;
    final fields = extractGeneratableFields(cls);

    final idField = fields.firstWhere((f) => f.name == 'id');
    expect(idField.isPositional, isTrue);
    expect(idField.isConstructorParam, isTrue);

    final computedField = fields.firstWhere((f) => f.name == 'computed');
    expect(computedField.isConstructorParam, isFalse);

    expect(fields.firstWhere((f) => f.name == 'link').isUriType, isTrue);
    expect(fields.firstWhere((f) => f.name == 'ttl').isDurationType, isTrue);
    expect(fields.firstWhere((f) => f.name == 'big').isBigIntType, isTrue);

    final context = CorrectionProducerContext.createResolved(
      libraryResult: await unitResult.session.getResolvedLibraryByElement(
        unitResult.libraryElement,
      ) as ResolvedLibraryResult,
      unitResult: unitResult,
      selectionOffset: cls.offset,
    );

    final builder = ChangeBuilder(session: unitResult.session);
    await AddCompositeMethods(context: context).compute(builder);

    final allEdits = builder.sourceChange.edits.single.edits
        .map((e) => e.replacement)
        .join('\n');

    // Auto-imported analyzer_kit_annotation for deepHash/deepEquals
    expect(
      allEdits,
      contains(
        "import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';",
      ),
    );
    // Positional super.id in copyWith & fromMap, and computed omitted from them
    expect(allEdits, contains('id ?? this.id,'));
    expect(allEdits, contains("map['id'] as int,"));
    expect(allEdits, contains('link.toString()'));
    expect(allEdits, contains('ttl.inMicroseconds'));
    expect(allEdits, contains('big.toString()'));
    expect(allEdits, isNot(contains('String? computed')));
  });

  test(
    'supports prefixed annotation imports and skips abstract classes',
    () async {
      final unitResult = await resolveCode('prefixed.dart', '''
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart' as ak;

@ak.CopyWith(nullable: true)
class PrefixedModel {
  final String? title;
  const PrefixedModel({this.title});
}

@ak.CopyWith()
abstract class AbstractBase {
  String get id;
}
''');

      final classes = unitResult.unit.declarations
          .whereType<ClassDeclaration>()
          .toList();
      final prefixed = classes[0];
      final abstractCls = classes[1];

      final config = extractAnnotationConfig(prefixed);
      expect(config.copyWith, isTrue);
      expect(config.copyWithNullable, isTrue);
      expect(
        config.annotationNodes[FeatureAnnotation.copyWith],
        same(prefixed.metadata.single),
      );
      expect(
        annotationEnablesFeature(
          prefixed.metadata.single,
          FeatureAnnotation.copyWith,
        ),
        isTrue,
      );

      expect(extractGeneratableFields(abstractCls), isEmpty);
    },
  );

  test('supports field-level @ignore, @Ignore(), and @Ignore({...}) across all features', () async {
    final unitResult = await resolveCode('ignore_fields.dart', '''
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

const dataClass = CompositeAnnotation([
  CopyWith(),
  OverrideEquality(),
  OverrideToString(),
  Serialize(),
  Deserialize(),
]);

@dataClass
class Account({
  required final String id,
  @Ignore({.overrideToString, .serialize}) final String? token,
}) {
  @ignore
  final String? cachedLabel;

  @Ignore({.copyWith, .overrideEquality, .overrideToString, .serialize})
  final String? legacyNote;
}
''');

    final cls = unitResult.unit.declarations
        .whereType<ClassDeclaration>()
        .single;
    final fields = extractGeneratableFields(cls);

    final idField = fields.firstWhere((f) => f.name == 'id');
    expect(idField.ignoredFor, isEmpty);

    final tokenField = fields.firstWhere((f) => f.name == 'token');
    expect(tokenField.ignoredFor, {
      FeatureAnnotation.overrideToString,
      FeatureAnnotation.serialize,
    });

    final cachedField = fields.firstWhere((f) => f.name == 'cachedLabel');
    expect(cachedField.ignoredFor, FeatureAnnotation.values.toSet());

    final legacyField = fields.firstWhere((f) => f.name == 'legacyNote');
    expect(legacyField.ignoredFor, {
      FeatureAnnotation.copyWith,
      FeatureAnnotation.overrideEquality,
      FeatureAnnotation.overrideToString,
      FeatureAnnotation.serialize,
    });

    expect(
      fieldsForFeature(fields, FeatureAnnotation.copyWith).map((f) => f.name),
      ['id', 'token'],
    );
    expect(
      fieldsForFeature(
        fields,
        FeatureAnnotation.overrideToString,
      ).map((f) => f.name),
      ['id'],
    );
    expect(
      fieldsForFeature(fields, FeatureAnnotation.serialize).map((f) => f.name),
      ['id'],
    );
    expect(
      fieldsForFeature(
        fields,
        FeatureAnnotation.deserialize,
      ).map((f) => f.name),
      ['id', 'token', 'legacyNote'],
    );

    final libraryResult = await unitResult.session.getResolvedLibraryByElement(
      unitResult.libraryElement,
    ) as ResolvedLibraryResult;
    final context = CorrectionProducerContext.createResolved(
      libraryResult: libraryResult,
      unitResult: unitResult,
      selectionOffset: cls.offset,
    );

    final builder = ChangeBuilder(session: unitResult.session);
    await AddCompositeMethods(context: context).compute(builder);

    final generated = builder.sourceChange.edits.single.edits
        .map((e) => e.replacement)
        .join('\n');

    // cachedLabel is ignored everywhere
    expect(generated, isNot(contains('cachedLabel')));
    // token is in copyWith & equality & fromMap, but not in toString or toMap
    expect(generated, contains('String? token'));
    expect(generated, contains('other.token == token'));
    expect(generated, contains("toString() => 'Account(id: \$id)'"));
    expect(generated, contains("toMap() => {'id': id}"));
  });

  test('supports field-level @redact and @Redact across primary params, body fields, and inherited fields', () async {
    await resolveCode('redact_base.dart', '''
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

class BaseCredentials {
  @Redact({.overrideToString, .serialize})
  final String masterKey;

  const BaseCredentials({required this.masterKey});
}
''');

    final unitResult = await resolveCode('redact_fields.dart', '''
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';
import 'redact_base.dart';

const dataClass = CompositeAnnotation([
  CopyWith(),
  OverrideEquality(),
  OverrideToString(),
  Serialize(),
  Deserialize(),
]);

@dataClass
class PrimaryAccount({
  required final String id,
  @redact final String password,
});

@dataClass
class ServiceAccount extends BaseCredentials {
  @Redact({.overrideToString, .serialize}, '***')
  final String apiToken;

  const ServiceAccount({
    required this.apiToken,
    required super.masterKey,
  });
}
''');

    final classes = unitResult.unit.declarations
        .whereType<ClassDeclaration>()
        .toList();
    final primaryCls = classes.firstWhere(
      (c) => c.namePart.typeName.lexeme == 'PrimaryAccount',
    );
    final serviceCls = classes.firstWhere(
      (c) => c.namePart.typeName.lexeme == 'ServiceAccount',
    );

    final primaryFields = extractGeneratableFields(primaryCls);
    final idField = primaryFields.firstWhere((f) => f.name == 'id');
    expect(idField.redactedFor, isEmpty);

    final passwordField = primaryFields.firstWhere((f) => f.name == 'password');
    expect(passwordField.redactedFor, {FeatureAnnotation.overrideToString});
    expect(passwordField.redactPlaceholder, '[REDACTED]');

    final serviceFields = extractGeneratableFields(serviceCls);
    final apiTokenField = serviceFields.firstWhere((f) => f.name == 'apiToken');
    expect(apiTokenField.redactedFor, {
      FeatureAnnotation.overrideToString,
      FeatureAnnotation.serialize,
    });
    expect(apiTokenField.redactPlaceholder, '***');

    final masterKeyField = serviceFields.firstWhere(
      (f) => f.name == 'masterKey',
    );
    expect(masterKeyField.redactedFor, {
      FeatureAnnotation.overrideToString,
      FeatureAnnotation.serialize,
    });
    expect(masterKeyField.redactPlaceholder, '[REDACTED]');

    final libraryResult = await unitResult.session.getResolvedLibraryByElement(
      unitResult.libraryElement,
    ) as ResolvedLibraryResult;

    final primaryContext = CorrectionProducerContext.createResolved(
      libraryResult: libraryResult,
      unitResult: unitResult,
      selectionOffset: primaryCls.offset,
    );
    final primaryBuilder = ChangeBuilder(session: unitResult.session);
    await AddCompositeMethods(context: primaryContext).compute(primaryBuilder);
    final primaryGenerated = primaryBuilder.sourceChange.edits.single.edits
        .map((e) => e.replacement)
        .join('\n');

    expect(primaryGenerated, contains('String? password'));
    expect(primaryGenerated, contains('other.password == password'));
    expect(
      primaryGenerated,
      contains(
        "toString() => 'PrimaryAccount(id: \$id, password: [REDACTED])'",
      ),
    );
    expect(primaryGenerated, contains("'password': password"));

    final context = CorrectionProducerContext.createResolved(
      libraryResult: libraryResult,
      unitResult: unitResult,
      selectionOffset: serviceCls.offset,
    );

    final compositeBuilder = ChangeBuilder(session: unitResult.session);
    await AddCompositeMethods(context: context).compute(compositeBuilder);
    final generated = compositeBuilder.sourceChange.edits.single.edits
        .map((e) => e.replacement)
        .join('\n');

    // All fields remain in copyWith, ==, hashCode, and fromMap
    expect(generated, contains('String? apiToken'));
    expect(generated, contains('String? masterKey'));
    expect(generated, contains('other.apiToken == apiToken'));
    expect(generated, contains("map['apiToken'] as String"));
    expect(generated, contains("map['masterKey'] as String"));

    // toString and toMap render placeholders for apiToken and masterKey
    expect(
      generated,
      contains(
        "toString() => 'ServiceAccount(apiToken: ***, masterKey: [REDACTED])'",
      ),
    );
    expect(generated, contains("'apiToken': '***'"));
    expect(generated, contains("'masterKey': '[REDACTED]'"));

    // Single-feature quick fixes also respect @Redact
    final toStringBuilder = ChangeBuilder(session: unitResult.session);
    await OverrideToStringMethod(context: context).compute(toStringBuilder);
    final toStringEdit = toStringBuilder.sourceChange.edits.single.edits
        .map((e) => e.replacement)
        .join('\n');
    expect(
      toStringEdit,
      contains('ServiceAccount(apiToken: ***, masterKey: [REDACTED])'),
    );

    final serializeBuilder = ChangeBuilder(session: unitResult.session);
    await AddSerializeMethod(context: context).compute(serializeBuilder);
    final serializeEdit = serializeBuilder.sourceChange.edits.single.edits
        .map((e) => e.replacement)
        .join('\n');
    expect(serializeEdit, contains("'apiToken': '***'"));
    expect(serializeEdit, contains("'masterKey': '[REDACTED]'"));
  });

  test('AddCompositeMethods replaces unredacted toString and toMap when @Redact is present', () async {
    final unitResult = await resolveCode('redact_sync_fix.dart', '''
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

const dataClass = CompositeAnnotation([
  OverrideToString(),
  Serialize(),
]);

@dataClass
class Credentials {
  final String user;
  @Redact({.overrideToString, .serialize})
  final String secret;

  const Credentials({required this.user, required this.secret});

  @override
  String toString() => 'Credentials(user: \$user, secret: \$secret)';

  Map<String, dynamic> toMap() => {'user': user, 'secret': secret};
}
''');

    final cls = unitResult.unit.declarations
        .whereType<ClassDeclaration>()
        .single;
    final fields = extractGeneratableFields(cls);
    final toStringMethod = findMethodDeclaration(cls, 'toString')!;
    final toMapMethod = findMethodDeclaration(cls, 'toMap')!;

    expect(
      checkBodySync(
        toStringMethod.body,
        fields,
        feature: FeatureAnnotation.overrideToString,
      ).isInSync,
      isFalse,
    );
    expect(checkSerializeSync(toMapMethod.body, fields).isInSync, isFalse);

    final libraryResult = await unitResult.session.getResolvedLibraryByElement(
      unitResult.libraryElement,
    ) as ResolvedLibraryResult;
    final context = CorrectionProducerContext.createResolved(
      libraryResult: libraryResult,
      unitResult: unitResult,
      selectionOffset: cls.offset,
    );

    final builder = ChangeBuilder(session: unitResult.session);
    await AddCompositeMethods(context: context).compute(builder);
    final updated = builder.sourceChange.edits.single.edits
        .map((e) => e.replacement)
        .join('\n');

    expect(
      updated,
      contains("toString() => 'Credentials(user: \$user, secret: [REDACTED])'"),
    );
    expect(updated, contains("'secret': '[REDACTED]'"));
  });

  test('validates CompositeAnnotation entries and annotation targets on resolved AST', () async {
    final unitResult = await resolveCode('annotation_validation.dart', '''
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

const nestedBundle = CompositeAnnotation([CopyWith()]);

const validBundle = CompositeAnnotation([
  nestedBundle,
  copyWith,
  overrideEquality,
  OverrideToString(),
  Serialize(),
  Deserialize(),
]);

const invalidBundle = CompositeAnnotation([
  CopyWith(),
  Ignore(),
  redact,
  'not_an_annotation',
]);

@ignore
@Redact()
class MisplacedOnClass {
  @copyWith
  @validBundle
  final String name;

  const MisplacedOnClass({@Serialize() required this.name});
}

class PrimaryParamTest({@OverrideToString() required final String id});
''');

    final reported = <(DiagnosticCode, List<Object>)>[];
    void capture(node, DiagnosticCode code, List<Object> args) {
      reported.add((code, args));
    }

    // Check CompositeAnnotation entries
    final topVars = unitResult.unit.declarations
        .whereType<TopLevelVariableDeclaration>()
        .toList();
    for (final decl in topVars) {
      final init = decl.variables.variables.single.initializer;
      if (init is InstanceCreationExpression) {
        validateCompositeAnnotationArgs(init.argumentList, capture);
      }
    }

    expect(
      reported
          .where((r) => r.$1 == LintCodes.invalidCompositeAnnotationEntry)
          .map((r) => r.$2.single)
          .toList(),
      ['Ignore', 'Redact', 'String'],
    );

    reported.clear();

    // Check class, field, and parameter metadata
    final classes = unitResult.unit.declarations
        .whereType<ClassDeclaration>()
        .toList();
    for (final cls in classes) {
      validateClassMetadata(cls.metadata, capture);
      for (final member in cls.body.members) {
        if (member is FieldDeclaration) {
          validateFieldOrParamMetadata(member.metadata, capture);
        }
      }
    }
    // Also check formal parameters across all declarations
    final params = <FormalParameter>[];
    void collectParams(node) {
      for (final child in node.childEntities) {
        if (child is FormalParameter) params.add(child);
        if (child is ClassDeclaration ||
            child.runtimeType.toString().contains('Body') ||
            child.runtimeType.toString().contains('Constructor') ||
            child.runtimeType.toString().contains('FormalParameterList')) {
          collectParams(child);
        }
      }
    }

    for (final cls in classes) {
      collectParams(cls);
    }
    for (final param in params) {
      validateFieldOrParamMetadata(param.metadata, capture);
    }

    expect(
      reported
          .where((r) => r.$1 == LintCodes.misplacedFieldAnnotation)
          .map((r) => r.$2.single)
          .toList(),
      ['ignore', 'Redact'],
    );
    expect(
      reported
          .where((r) => r.$1 == LintCodes.misplacedClassAnnotation)
          .map((r) => r.$2.single)
          .toList(),
      ['copyWith', 'validBundle', 'Serialize', 'OverrideToString'],
    );
  });

  test(
    'supports fieldRename on @Serialize, @Deserialize, and CompositeAnnotation',
    () async {
      final unitResult = await resolveCode('field_rename.dart', '''
import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

const snakeJson = CompositeAnnotation([
  Serialize(name: .toJson(), fieldRename: .snake),
  Deserialize(name: .fromJson(), fieldRename: .snake),
]);

@snakeJson
class ApiUser {
  final String firstName;
  final DateTime createdAt;

  const ApiUser({required this.firstName, required this.createdAt});
}

@Serialize(fieldRename: .screamingSnake)
@Deserialize(fieldRename: .screamingSnake)
class EnvConfig {
  final String apiBaseUrl;

  const EnvConfig({required this.apiBaseUrl});
}
''');

      final classes = unitResult.unit.declarations
          .whereType<ClassDeclaration>()
          .toList();
      final apiUser = classes.firstWhere(
        (c) => c.namePart.typeName.lexeme == 'ApiUser',
      );
      final envConfig = classes.firstWhere(
        (c) => c.namePart.typeName.lexeme == 'EnvConfig',
      );

      final apiConfig = extractAnnotationConfig(apiUser);
      expect(apiConfig.serializeFieldRename, FieldRename.snake);
      expect(apiConfig.deserializeFieldRename, FieldRename.snake);

      final envConfigParsed = extractAnnotationConfig(envConfig);
      expect(envConfigParsed.serializeFieldRename, FieldRename.screamingSnake);
      expect(
        envConfigParsed.deserializeFieldRename,
        FieldRename.screamingSnake,
      );

      final libraryResult =
          await unitResult.session.getResolvedLibraryByElement(
            unitResult.libraryElement,
          ) as ResolvedLibraryResult;

      final apiContext = CorrectionProducerContext.createResolved(
        libraryResult: libraryResult,
        unitResult: unitResult,
        selectionOffset: apiUser.offset,
      );
      final apiBuilder = ChangeBuilder(session: unitResult.session);
      await AddCompositeMethods(context: apiContext).compute(apiBuilder);
      final apiGenerated = apiBuilder.sourceChange.edits.single.edits
          .map((e) => e.replacement)
          .join('\n');

      expect(apiGenerated, contains("'first_name': firstName"));
      expect(
        apiGenerated,
        contains("'created_at': createdAt.toIso8601String()"),
      );
      expect(apiGenerated, contains("firstName: map['first_name'] as String"));
      expect(
        apiGenerated,
        contains("createdAt: DateTime.parse(map['created_at'] as String)"),
      );

      final envContext = CorrectionProducerContext.createResolved(
        libraryResult: libraryResult,
        unitResult: unitResult,
        selectionOffset: envConfig.offset,
      );
      final serBuilder = ChangeBuilder(session: unitResult.session);
      await AddSerializeMethod(context: envContext).compute(serBuilder);
      expect(
        serBuilder.sourceChange.edits.single.edits.single.replacement,
        contains("'API_BASE_URL': apiBaseUrl"),
      );

      final deserBuilder = ChangeBuilder(session: unitResult.session);
      await AddDeserializeMethod(context: envContext).compute(deserBuilder);
      expect(
        deserBuilder.sourceChange.edits.single.edits.single.replacement,
        contains("apiBaseUrl: map['API_BASE_URL'] as String"),
      );
    },
  );
}
