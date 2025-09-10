import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class RxDisposalRule extends DartLintRule {
  const RxDisposalRule() : super(code: _code);

  static const _code = LintCode(
    name: 'dispose_rx_variables',
    problemMessage: 'Rx variable {0} must be disposed in the dispose() method.',
    correctionMessage: 'Add {0}.dispose() to the dispose() method.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      _RxDisposalChecker(reporter).check(node);
    });
  }
}

class _RxDisposalChecker {
  final ErrorReporter reporter;

  _RxDisposalChecker(this.reporter);

  void check(ClassDeclaration classNode) {
    // Only check classes that extend StateController
    if (!_extendsStateController(classNode)) return;

    final rxFields = _findRxFields(classNode);
    final disposedFields = _findDisposedFields(classNode);

    // Report undisposed fields
    for (final field in rxFields) {
      if (!disposedFields.contains(field.name)) {
        
        reporter.atNode(
          field.node,
          RxDisposalRule._code,
          arguments: [field.name],
        );
      }
    }
  }

  bool _extendsStateController(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause == null) return false;

    final superclassName = extendsClause.superclass.name2.lexeme;
    return superclassName == 'StateController';
  }

  List<_FieldInfo> _findRxFields(ClassDeclaration node) {
    final fields = <_FieldInfo>[];

    for (final member in node.members) {
      if (member is FieldDeclaration && !member.isStatic) {
        for (final variable in member.fields.variables) {
          if (_isRxField(member.fields.type, variable.initializer)) {
            fields.add(_FieldInfo(
              name: variable.name.lexeme,
              node: variable.root,
            ));
          }
        }
      }
    }

    return fields;
  }

  bool _isRxField(TypeAnnotation? type, Expression? initializer) {
    // Check explicit Rx types
    if (type is NamedType) {
      final typeName = type.name2.lexeme;
      if (const ['Rx', 'RxBool', 'RxList', 'RxInt', 'RxDouble', 'RxString']
          .contains(typeName)) {
        return true;
      }
    }

    // Check .rx extension usage
    if (initializer != null) {
      if (initializer is PropertyAccess &&
          initializer.propertyName.name == 'rx') {
        return true;
      }
      if (initializer is PrefixedIdentifier &&
          initializer.identifier.name == 'rx') {
        return true;
      }
    }

    return false;
  }

  Set<String> _findDisposedFields(ClassDeclaration node) {
    final disposed = <String>{};

    // Find dispose method
    final disposeMethods = node.members.whereType<MethodDeclaration>().where(
          (method) => method.name.lexeme == 'dispose',
        );

    // If no dispose method found, return empty set
    if (disposeMethods.isEmpty) {
      return disposed;
    }

    // Visit dispose method to find disposed fields
    disposeMethods.first.accept(_DisposeCallVisitor(disposed));

    return disposed;
  }
}

class _FieldInfo {
  final String name;
  final AstNode node;

  _FieldInfo({required this.name, required this.node});
}

class _DisposeCallVisitor extends RecursiveAstVisitor<void> {
  final Set<String> disposedFields;

  _DisposeCallVisitor(this.disposedFields);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'dispose') {
      final target = node.target;
      if (target is SimpleIdentifier) {
        disposedFields.add(target.name);
      }
    }
    super.visitMethodInvocation(node);
  }
}
