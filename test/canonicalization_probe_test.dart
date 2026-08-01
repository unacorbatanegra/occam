// ignore_for_file: public_member_api_docs, avoid_print, prefer_const_constructors
//
// Control group. This file tests the LANGUAGE/TOOLCHAIN, not occam.
//
// Why it exists: `state_identity_test.dart` was written assuming Dart
// canonicalizes const instances, so that two `const Probe()` expressions are
// one object — the premise the security report used to explain how
// `_stateFromRegistry`'s `identical(element.widget, widget)` confuses two
// mounted instances. Measured on Flutter 3.44.8 that premise did not hold:
//
//   kProbe          -> 374183397
//   const Probe() A -> 562513451
//   const Probe() B -> 908379881
//   inlineA === inlineB: false
//
// Two `const Probe()` in the same function came back as different objects.
//
// ANSWER (measured, Flutter 3.44.8): plain classes and `const Object()` DO
// canonicalize; every Widget subclass does NOT — SizedBox, a stock
// StatefulWidget and StateWidget all came back DIFFERENT. The cause is the
// `--track-widget-creation` transform, which `flutter test` and debug builds
// enable for the Widget Inspector: it appends a hidden `_location`
// (file/line/column) argument to every const Widget constructor, so two const
// expressions on different source lines have different arguments and are not
// the same instance.
//
// What follows from that, and it matters for how bad the bug is:
//
//   * The transform is OFF in release/profile. There, `const HomePage()` in two
//     different files IS one object, exactly as the report said — so the
//     state-resolution bug is WORSE in production than in debug, and a debug-
//     mode test run hides it. Use `flutter test --no-track-widget-creation` to
//     reproduce release behaviour.
//   * Even WITH the transform on, one const site evaluated more than once
//     yields the same object: a route builder called twice, a const page in a
//     loop, a const widget held in a field. See the `const ... via fn` rows.
//
// The detector suite deliberately shares a reference (`kProbe`) instead of
// writing `const Probe()` inline, so it reproduces the ambiguity in BOTH modes.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

void main() {
  test('canonicalization control table', () {
    const plainA = Plain();
    const plainB = Plain();
    const fieldA = Plain(1);
    const fieldB = Plain(1);
    const boxA = SizedBox();
    const boxB = SizedBox();
    const vanillaA = Vanilla();
    const vanillaB = Vanilla();
    const probeA = Probe();
    const probeB = Probe();

    void row(String label, Object a, Object b) {
      print('${label.padRight(28)} '
          '${identical(a, b) ? 'SAME    ' : 'DIFFERENT'} '
          '${identityHashCode(a)} / ${identityHashCode(b)}');
    }

    print('--- two separate const expressions, same class + same args ---');
    row('plain class, no fields', plainA, plainB);
    row('plain class, int field', fieldA, fieldB);
    row('const Object()', const Object(), const Object());
    row('flutter SizedBox', boxA, boxB);
    row('plain StatefulWidget', vanillaA, vanillaB);
    row('occam StateWidget', probeA, probeB);

    print('--- shared reference (what the detector suite relies on) ---');
    row('same const variable twice', plainA, plainA);
    row('same StateWidget variable', probeA, probeA);
    row('const via factory fn', constPlain(), constPlain());
    row('const StateWidget via fn', constProbe(), constProbe());

    print('--- distinct args must stay distinct ---');
    row('different int field', const Plain(1), const Plain(2));
    row('different Key', const Probe(), const Probe(key: Key('a')));

    // Non-Widget const canonicalization is untouched by the transform, so this
    // holds in every mode. If it ever fails, const evaluation itself is broken.
    expect(identical(plainA, plainB), isTrue, reason: 'plain class');
    expect(identical(fieldA, fieldB), isTrue, reason: 'plain class w/ field');
    expect(identical(const Object(), const Object()), isTrue);

    // Widgets: the answer depends on --track-widget-creation, so report the
    // mode instead of asserting one of them. Both Widget rows must agree —
    // whatever holds for SizedBox must hold for StateWidget, since the
    // transform applies to every Widget alike.
    final widgetsCanonicalize = identical(boxA, boxB);
    print(widgetsCanonicalize
        ? 'MODE: --no-track-widget-creation (release-like). Separate const '
            'Widget expressions ARE one object.'
        : 'MODE: track-widget-creation ON (default for flutter test / debug). '
            'Separate const Widget expressions are distinct; only a reused '
            'const site or a shared reference collides.');
    expect(
      identical(probeA, probeB),
      widgetsCanonicalize,
      reason: 'StateWidget must canonicalize exactly like any other Widget; if '
          'it diverges from SizedBox, something in StateWidget changed const '
          'identity and the state-resolution analysis needs revisiting',
    );
    expect(
      identical(vanillaA, vanillaB),
      widgetsCanonicalize,
      reason: 'StatefulWidget must behave like SizedBox',
    );

    // These must hold no matter what, and are what the detector suite relies on.
    expect(identical(plainA, plainA), isTrue);
    expect(identical(probeA, probeA), isTrue);
    expect(identical(constProbe(), constProbe()), isTrue,
        reason:
            'one const site evaluated twice must yield one object — this is '
            'what makes the bug reachable even in debug mode');
    expect(identical(const Plain(1), const Plain(2)), isFalse);
    expect(identical(const Probe(), const Probe(key: Key('a'))), isFalse);
  });
}

/// A const expression behind a function call — the route-builder shape.
Widget constProbe() => const Probe();
Object constPlain() => const Plain();

class Plain {
  final int? value;
  const Plain([this.value]);
}

/// A stock StatefulWidget, for comparison against [Probe].
class Vanilla extends StatefulWidget {
  const Vanilla({super.key});

  @override
  State<Vanilla> createState() => _VanillaState();
}

class _VanillaState extends State<Vanilla> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// The occam shape: a const, fieldless, unkeyed StateWidget.
class Probe extends StateWidget<ProbeController> {
  const Probe({super.key});

  @override
  ProbeController createState() => ProbeController();

  @override
  Widget build(BuildContext context, ProbeController state) => const SizedBox();
}

class ProbeController extends StateController {}
