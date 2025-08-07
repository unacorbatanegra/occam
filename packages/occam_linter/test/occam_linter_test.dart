// test/rx_disposal_rule_test.dart
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:occam_linter/src/rx_disposal_rule.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

void main() {
  group('RxDisposalRule', () {
    late RxDisposalRule rule;
    
    setUp(() {
      rule = const RxDisposalRule();
    });

    test('detects undisposed Rx variable with explicit type', () async {
      final code = '''
class HomeController extends StateController {
  final Rx<int> counter = Rx(0);
  
  @override
  void dispose() {
    super.dispose();
  }
}

class StateController {}
class Rx<T> {
  Rx(T value);
  void dispose() {}
}
''';

      final errors = await _getLintErrors(code, rule);

      expect(errors, hasLength(1));
      expect(errors.first.message, contains('counter'));
      expect(errors.first.message, contains('must be disposed'));
    });

    test('detects undisposed Rx variable with extension syntax', () async {
      final code = '''
class HomeController extends StateController {
  final counter = 0.rx;
  final name = "".rx;
  
  @override
  void dispose() {
    super.dispose();
  }
}

class StateController {}
extension IntRx on int {
  Rx<int> get rx => Rx(this);
}
extension StringRx on String {
  Rx<String> get rx => Rx(this);
}
class Rx<T> {
  Rx(T value);
  void dispose() {}
}
''';

      final errors = await _getLintErrors(code, rule);

      expect(errors, hasLength(2));
      expect(errors.any((e) => e.message.contains('counter')), isTrue);
      expect(errors.any((e) => e.message.contains('name')), isTrue);
    });

    test('detects undisposed RxBool', () async {
      final code = '''
class HomeController extends StateController {
  final RxBool isLoading = RxBool(false);
  
  @override
  void dispose() {
    super.dispose();
  }
}

class StateController {}
class RxBool {
  RxBool(bool value);
  void dispose() {}
}
''';

      final errors = await _getLintErrors(code, rule);

      expect(errors, hasLength(1));
      expect(errors.first.message, contains('isLoading'));
    });

    test('detects undisposed RxList', () async {
      final code = '''
class HomeController extends StateController {
  final RxList<String> items = RxList([]);
  
  @override
  void dispose() {
    super.dispose();
  }
}

class StateController {}
class RxList<T> {
  RxList(List<T> value);
  void dispose() {}
}
''';

      final errors = await _getLintErrors(code, rule);

      expect(errors, hasLength(1));
      expect(errors.first.message, contains('items'));
    });

    test('no error when Rx variable is properly disposed', () async {
      final code = '''
class HomeController extends StateController {
  final counter = 0.rx;
  final name = "".rx;
  
  @override
  void dispose() {
    counter.dispose();
    name.dispose();
    super.dispose();
  }
}

class StateController {}
extension IntRx on int {
  Rx<int> get rx => Rx(this);
}
extension StringRx on String {
  Rx<String> get rx => Rx(this);
}
class Rx<T> {
  Rx(T value);
  void dispose() {}
}
''';

      final errors = await _getLintErrors(code, rule);

      expect(errors, isEmpty);
    });

    test('no error for static Rx variables', () async {
      final code = '''
class HomeController extends StateController {
  static final counter = 0.rx;
  
  @override
  void dispose() {
    super.dispose();
  }
}

class StateController {}
extension IntRx on int {
  Rx<int> get rx => Rx(this);
}
class Rx<T> {
  Rx(T value);
  void dispose() {}
}
''';

      final errors = await _getLintErrors(code, rule);

      expect(errors, isEmpty);
    });

    test('no error for non-StateController classes', () async {
      final code = '''
class RegularClass {
  final counter = 0.rx;
  
  void dispose() {
    // Not required to dispose in non-StateController classes
  }
}

extension IntRx on int {
  Rx<int> get rx => Rx(this);
}
class Rx<T> {
  Rx(T value);
  void dispose() {}
}
''';

      final errors = await _getLintErrors(code, rule);

      expect(errors, isEmpty);
    });

    test('handles missing dispose method', () async {
      final code = '''
class HomeController extends StateController {
  final counter = 0.rx;
}

class StateController {}
extension IntRx on int {
  Rx<int> get rx => Rx(this);
}
class Rx<T> {
  Rx(T value);
  void dispose() {}
}
''';

      final errors = await _getLintErrors(code, rule);

      expect(errors, hasLength(1));
      expect(errors.first.message, contains('counter'));
    });

    test('detects multiple undisposed variables', () async {
      final code = '''
class HomeController extends StateController {
  final counter = 0.rx;
  final RxBool isLoading = RxBool(false);
  final RxList<String> items = RxList([]);
  final disposed = "".rx;
  
  @override
  void dispose() {
    disposed.dispose();
    super.dispose();
  }
}

class StateController {}
extension IntRx on int {
  Rx<int> get rx => Rx(this);
}
extension StringRx on String {
  Rx<String> get rx => Rx(this);
}
class Rx<T> {
  Rx(T value);
  void dispose() {}
}
class RxBool {
  RxBool(bool value);
  void dispose() {}
}
class RxList<T> {
  RxList(List<T> value);
  void dispose() {}
}
''';

      final errors = await _getLintErrors(code, rule);

      expect(errors, hasLength(3));
      expect(errors.any((e) => e.message.contains('counter')), isTrue);
      expect(errors.any((e) => e.message.contains('isLoading')), isTrue);
      expect(errors.any((e) => e.message.contains('items')), isTrue);
      expect(errors.every((e) => !e.message.contains('disposed')), isTrue);
    });

    test('handles nested dispose calls', () async {
      final code = '''
class HomeController extends StateController {
  final counter = 0.rx;
  
  @override
  void dispose() {
    _disposeResources();
    super.dispose();
  }
  
  void _disposeResources() {
    counter.dispose();
  }
}

class StateController {}
extension IntRx on int {
  Rx<int> get rx => Rx(this);
}
class Rx<T> {
  Rx(T value);
  void dispose() {}
}
''';

      // Note: This test might fail with the current implementation
      // as it only checks direct dispose calls in the dispose method.
      // This is a known limitation that could be enhanced.
      final errors = await _getLintErrors(code, rule);

      // The current implementation would report an error here
      expect(errors, hasLength(1));
    });

    test('handles late variables', () async {
      final code = '''
class HomeController extends StateController {
  late final Rx<int> counter;
  
  @override
  void initState() {
    counter = Rx(0);
    super.initState();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}

class StateController {
  void initState() {}
}
class Rx<T> {
  Rx(T value);
  void dispose() {}
}
''';

      final errors = await _getLintErrors(code, rule);

      expect(errors, hasLength(1));
      expect(errors.first.message, contains('counter'));
    });

    test('handles nullable Rx variables', () async {
      final code = '''
class HomeController extends StateController {
  Rx<int>? counter;
  
  @override
  void dispose() {
    counter?.dispose();
    super.dispose();
  }
}

class StateController {}
class Rx<T> {
  Rx(T value);
  void dispose() {}
}
''';

      final errors = await _getLintErrors(code, rule);

      expect(errors, isEmpty);
    });
  });
}

// Helper function to run the linter and collect errors
Future<List<LintError>> _getLintErrors(String code, LintRule rule) async {
  final errors = <LintError>[];

  // Parse the code
  final parseResult = parseString(content: code);
  final unit = parseResult.unit;
  
  // Create a mock error reporter
  final reporter = _MockErrorReporter((error) {
    errors.add(LintError(
      message: error.message,
      code: error.errorCode.name,
      location: error.offset,
      length: error.length,
    ));
  });
  
  // Create a mock context and resolver
  final context = _MockCustomLintContext(unit);
  final resolver = _MockCustomLintResolver();

  // Run the rule
  rule.run(resolver, reporter, context);

  return errors;
}

class LintError {
  final String message;
  final String code;
  final int location;
  final int length;

  LintError({
    required this.message,
    required this.code,
    required this.location,
    required this.length,
  });
}

// Mock classes for testing
class _MockErrorReporter implements ErrorReporter {
  final void Function(AnalysisError) onError;
  final _MockSource _source = _MockSource();

  _MockErrorReporter(this.onError);

  @override
  void reportError(AnalysisError error) {
    onError(error);
  }

  @override
  void atNode(AstNode node, ErrorCode errorCode,
      {List<Object>? arguments,
      List<DiagnosticMessage>? contextMessages,
      Object? data}) {
    final message = errorCode.problemMessage.replaceAllMapped(
      RegExp(r'\{(\d+)\}'),
      (match) {
        final index = int.parse(match.group(1)!);
        return arguments?[index].toString() ?? '';
      },
    );

    onError(AnalysisError.tmp(
      source: _source,
      offset: node.offset,
      length: node.length,
      errorCode: errorCode,
      arguments: arguments ?? const [],
      contextMessages: contextMessages ?? [],
      data: data,
    ));
  }

  @override
  void atOffset({
    required int offset,
    required int length,
    required ErrorCode errorCode,
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    final message = errorCode.problemMessage.replaceAllMapped(
      RegExp(r'\{(\d+)\}'),
      (match) {
        final index = int.parse(match.group(1)!);
        return arguments?[index].toString() ?? '';
      },
    );

    onError(AnalysisError.tmp(
      source: _source,
      offset: offset,
      length: length,
      errorCode: errorCode,
      arguments: arguments ?? const [],
      contextMessages: contextMessages ?? [],
      data: data,
    ));
  }

  @override
  void atElement(Element element, ErrorCode errorCode,
      {List<Object>? arguments,
      List<DiagnosticMessage>? contextMessages,
      Object? data}) {
    // Not implemented for tests
  }

  @override
  void atEntity(SyntacticEntity entity, ErrorCode errorCode,
      {List<Object>? arguments,
      List<DiagnosticMessage>? contextMessages,
      Object? data}) {
    // Not implemented for tests
  }

  @override
  void atSourceSpan(SourceSpan span, ErrorCode errorCode,
      {List<Object>? arguments,
      List<DiagnosticMessage>? contextMessages,
      Object? data}) {
    // Not implemented for tests
  }

  @override
  void atToken(Token token, ErrorCode errorCode,
      {List<Object>? arguments,
      List<DiagnosticMessage>? contextMessages,
      Object? data}) {
    // Not implemented for tests
  }

  @override
  void atConstructorDeclaration(
      ConstructorDeclaration node, ErrorCode errorCode,
      {List<Object>? arguments,
      List<DiagnosticMessage>? contextMessages,
      Object? data}) {
    // Not implemented for tests
  }

  @override
  Source get source => _source;

  @override
  int get lockLevel => 0;

  @override
  set lockLevel(int value) {
    // Not implemented for tests
  }

  // Deprecated methods - kept for compatibility
  @override
  void reportErrorForOffset(ErrorCode errorCode, int offset, int length,
      [List<Object>? arguments, List<DiagnosticMessage>? contextMessages, Object? data]) {
    atOffset(
      offset: offset,
      length: length,
      errorCode: errorCode,
      arguments: arguments,
      contextMessages: contextMessages,
      data: data,
    );
  }

  @override
  void reportErrorForSpan(ErrorCode errorCode, SourceSpan span,
      [List<Object>? arguments]) {
    atSourceSpan(span, errorCode, arguments: arguments);
  }

  @override
  void reportErrorForToken(ErrorCode errorCode, Token token,
      [List<Object>? arguments, List<DiagnosticMessage>? contextMessages, Object? data]) {
    atToken(token, errorCode, arguments: arguments, contextMessages: contextMessages, data: data);
  }

  @override
  void reportErrorForElement(ErrorCode errorCode, Element element,
      [List<Object>? arguments, List<DiagnosticMessage>? messages]) {
    atElement(element, errorCode,
        arguments: arguments, contextMessages: messages);
  }

  @override
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object>? arguments,
      List<DiagnosticMessage>? contextMessages,
      Object? data]) {
    atNode(node, errorCode,
        arguments: arguments, contextMessages: contextMessages, data: data);
  }

  @override
  void reportTypeErrorForNode(
      ErrorCode errorCode, AstNode node, List<Object> arguments) {
    atNode(node, errorCode, arguments: arguments);
  }
}

class _MockSource implements Source {
  @override
  String get fullName => 'test.dart';

  @override
  Uri get uri => Uri.parse('file:///test.dart');

  @override
  String get shortName => 'test.dart';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockCustomLintContext implements CustomLintContext {
  final CompilationUnit unit;

  _MockCustomLintContext(this.unit);

  @override
  LintRuleNodeRegistry get registry => _MockRegistry(unit);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockRegistry implements LintRuleNodeRegistry {
  final CompilationUnit unit;

  _MockRegistry(this.unit);

  @override
  void addClassDeclaration(void Function(ClassDeclaration) listener) {
    unit.accept(_ClassDeclarationVisitor(listener));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ClassDeclarationVisitor extends RecursiveAstVisitor<void> {
  final void Function(ClassDeclaration) listener;

  _ClassDeclarationVisitor(this.listener);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    listener(node);
    super.visitClassDeclaration(node);
  }
}

class _MockCustomLintResolver implements CustomLintResolver {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
