@TestOn("browser")

library guinness2.test.test_backend_test;

import 'dart:html' as html;

import 'package:mockito/mockito.dart';
import 'package:guinness2/guinness2_html.dart' as guinness2;
import 'package:test/test.dart';

import '../test_utils.dart';

assertTrue(Function fn) => expect(fn, returnsNormally);
assertFalse(Function fn) => expect(fn, throws);

class TestClass {
  var prop;

  TestClass([this.prop]);
}

class TestClassWithPrivateField {
  var prop;
  var _private;

  TestClassWithPrivateField([this.prop, this._private]);
}

class MockTest extends Mock {
  noSuchMethod(i) => super.noSuchMethod(i);
}

void main() {
  group("[TestVisitor]", () {
    var visitor, dartTest;

    setUp(() {
      dartTest = new MockTest();
      visitor = new guinness2.TestVisitor(new Set(), dartTest: dartTest);
    });

    tearDown(() {
      verifyNoMoreInteractions(dartTest);
    });

    test('handles an empty suite', () {
      visitor.visitSuite(createSuite());
    });

    test('uses group for describe', () {
      final suite = createSuite()..add(createDescribe());

      visitor.visitSuite(suite);
      verify(dartTest.group(any, any));
    });

    test('skips excluded describes', () {
      final suite = createSuite()..add(createDescribe(excluded: true));

      visitor.visitSuite(suite);
    });

    test('uses test for it', () {
      final suite = createSuite()..add(createIt());

      visitor.visitSuite(suite);
      verify(dartTest.test(any, any));
    });

    test('only adds exclusive it', () {
      final suite = createSuite()..add(createIt(exclusive: true))
          ..add(createIt());

      visitor.visitSuite(suite);
      verify(dartTest.test(any, any)).called(1);
    });

    test('skips excluded its', () {
      final suite = createSuite()..add(createIt(excluded: true));

      visitor.visitSuite(suite);
    });

    test('runs only exlusive its', () {
      final suite = createSuite();
      var exclusiveDescribe = createDescribe(exclusive: true);
      var exclusiveIt = createIt(exclusive: true);
      var otherIt = createIt(parent: exclusiveDescribe);
      suite..add(exclusiveDescribe)..add(exclusiveIt);

      visitor.visitSuite(suite);
      verify(dartTest.group(any, any));
      verify(dartTest.test(any, any));
    });

    test("initializes specs only once", () {
      final suite = createSuite()
        ..add(createIt())
        ..add(createDescribe());

      visitor.visitSuite(suite);

      visitor.visitSuite(suite);
      verify(dartTest.test(any, any));
      verify(dartTest.group(any, any));
    });
  });

  group("[TestMatchers]", () {
    final matchers = new guinness2.TestMatchersWithHtml();

    test("toBe", () {
      var x = [1, 2];
      var y = [1, 2];
      assertFalse(() => matchers.toBe(x, y));
      assertTrue(() => matchers.toBe(x, x));
    });

    test("toBeLessThan", () {
      assertFalse(() => matchers.toBeLessThan(9, 9));
      assertTrue(() => matchers.toBeLessThan(-4, 9));
      assertFalse(() => matchers.toBeLessThan(9, -4));
    });

    test("toBeGreaterThan", () {
      assertFalse(() => matchers.toBeGreaterThan(9, 9));
      assertFalse(() => matchers.toBeGreaterThan(-4, 9));
      assertTrue(() => matchers.toBeGreaterThan(9, -4));
    });

    test("toBeCloseTo", () {
      assertTrue(() => matchers.toBeCloseTo(9, 9, 0));
      assertTrue(() => matchers.toBeCloseTo(9.123, 9.12, 2));
      assertFalse(() => matchers.toBeCloseTo(9.123, 9.12, 3));
    });

    test("toBeA", skipDart2Js(() {
      assertFalse(() => matchers.toBeA(2, String));
      assertTrue(() => matchers.toBeA(2, num));
    }));

    test("toBeAnInstanceOf", () {
      assertFalse(() => matchers.toBeAnInstanceOf("blah", TestClass));
      assertTrue(() => matchers.toBeAnInstanceOf(new TestClass(), TestClass));
    });

    test("toThrow", () {
      assertTrue(() => matchers.toThrow(() => throw "Wow!"));
      assertFalse(() => matchers.toThrow(() {}));
      assertTrue(() => matchers.toThrow(() => throw "Wow!", "Wow!"));
      assertFalse(() => matchers.toThrow(() => throw "Wow!", "Boom!"));
    });

    test("toThrowWith", () {
      assertTrue(() => matchers.toThrowWith(() => throw "Wow!"));
      assertFalse(() => matchers.toThrowWith(() {}));
      assertTrue(
          () => matchers.toThrowWith(() => throw "Wow!", message: "Wow!"));
      assertFalse(
          () => matchers.toThrowWith(() => throw "Wow!", message: "Boom!"));
      assertTrue(() => matchers.toThrowWith(
          () => throw new ArgumentError("123"),
          message: new RegExp(r"^.*[1-9]{3}$")));
      assertFalse(() => matchers.toThrowWith(
          () => throw new ArgumentError("123"),
          message: new RegExp(r"^.*[a-zA-Z]{3}$")));
      assertFalse(() => matchers.toThrowWith(
          () => throw new ArgumentError("123"),
          anInstanceOf: UnsupportedError));
      assertTrue(() => matchers.toThrowWith(
          () => throw new ArgumentError("123"), anInstanceOf: ArgumentError));
      assertTrue(() {
        matchers.toThrowWith(() => throw new ArgumentError("123"), where: (e) {
          expect(e.message, equals("123"));
        });
      });
      assertFalse(() {
        matchers.toThrowWith(() => throw new ArgumentError("123"), where: (e) {
          expect(e.message, equals("456"));
        });
      });
      assertTrue(() {
        matchers.toThrowWith(() => throw new ArgumentError("123"),
            where: (e) => e.message == "123");
      });
      assertFalse(() {
        matchers.toThrowWith(() => throw new ArgumentError("123"),
            where: (e) => e.message == "456");
      });

      skipDart2Js(() {
        assertTrue(() => matchers.toThrowWith(() => throw new ArgumentError(),
            type: ArgumentError));
        assertFalse(() => matchers.toThrowWith(() => throw new ArgumentError(),
            type: UnsupportedError));
      });
    });

    test("toBeFalsy", () {
      assertTrue(() => matchers.toBeFalsy(null));
      assertTrue(() => matchers.toBeFalsy(false));
      assertFalse(() => matchers.toBeFalsy("any object"));
      assertFalse(() => matchers.toBeFalsy(true));
    });

    test("toBeTruthy", () {
      assertFalse(() => matchers.toBeTruthy(null));
      assertFalse(() => matchers.toBeTruthy(false));
      assertTrue(() => matchers.toBeTruthy("any object"));
      assertTrue(() => matchers.toBeTruthy(true));
    });

    test("toBeFalse", () {
      assertTrue(() => matchers.toBeFalse(false));
      assertFalse(() => matchers.toBeFalse(true));
      assertFalse(() => matchers.toBeFalse(null));
      assertFalse(() => matchers.toBeFalse("any object"));
    });

    test("toBeTrue", () {
      assertTrue(() => matchers.toBeTrue(true));
      assertFalse(() => matchers.toBeTrue(null));
      assertFalse(() => matchers.toBeTrue(false));
      assertFalse(() => matchers.toBeTrue("any object"));
    });

    test("toHaveHtml", () {
      final div = new html.DivElement()..innerHtml = "<div>inner</div>";
      assertTrue(() => matchers.toHaveHtml(div, "<div>inner</div>"));
      assertFalse(() => matchers.toHaveHtml(div, "invalid"));
    });

    test("toHaveText", () {
      final div = new html.DivElement()..innerHtml = "expected";
      assertTrue(() => matchers.toHaveText(div, "expected"));
      assertFalse(() => matchers.toHaveText(div, "invalid"));
    });

    test("toContainText", () {
      final div = new html.DivElement()..innerHtml = "some expected text";
      assertTrue(() => matchers.toContainText(div, "expected"));
      assertFalse(() => matchers.toContainText(div, "invalid"));
    });

    test("toHaveClass", () {
      final div = new html.DivElement();
      div.classes.add("one");

      assertTrue(() => matchers.toHaveClass(div, "one"));
      assertFalse(() => matchers.toHaveClass(div, "two"));
    });

    test("toHaveAttribute", () {
      final div = new html.DivElement();
      div.attributes["one"] = "value";

      assertTrue(() => matchers.toHaveAttribute(div, "one"));
      assertTrue(() => matchers.toHaveAttribute(div, "one", "value"));
      assertFalse(() => matchers.toHaveAttribute(div, "two"));
      assertFalse(() => matchers.toHaveAttribute(div, "one", "invalid value"));
    });

    test("toEqualSelect", () {
      final select = new html.SelectElement();
      select.children.add(new html.OptionElement(value: "1"));
      select.children.add(new html.OptionElement(value: "2", selected: true));
      select.children.add(new html.OptionElement(value: "3"));

      assertTrue(() => matchers.toEqualSelect(select, ["1", ["2"], "3"]));
      assertFalse(() => matchers.toEqualSelect(select, ["1", "2", "3"]));
    });

    test("toHaveBeenCalled", () {
      final spy = new guinness2.SpyFunction("");

      assertFalse(() => matchers.toHaveBeenCalled(spy));

      spy();

      assertTrue(() => matchers.toHaveBeenCalled(spy));
    });

    test("toHaveBeenCalledOnce", () {
      final spy = new guinness2.SpyFunction("");

      assertFalse(() => matchers.toHaveBeenCalledOnce(spy));

      spy();

      assertTrue(() => matchers.toHaveBeenCalledOnce(spy));

      spy();

      assertFalse(() => matchers.toHaveBeenCalledOnce(spy));
    });

    test("toHaveBeenCalledWith", () {
      final spy = new guinness2.SpyFunction("");

      assertFalse(() => matchers.toHaveBeenCalledWith(spy, 1, 2));

      spy(1, 2);

      assertTrue(() => matchers.toHaveBeenCalledWith(spy, 1, 2));
      assertFalse(() => matchers.toHaveBeenCalledWith(spy, 3, 4));
    });

    test("toHaveBeenCalledOnceWith", () {
      final spy = new guinness2.SpyFunction("");

      assertFalse(() => matchers.toHaveBeenCalledOnceWith(spy, 1, 2));

      spy(1, 2);

      assertTrue(() => matchers.toHaveBeenCalledOnceWith(spy, 1, 2));

      spy(1, 2);

      assertFalse(() => matchers.toHaveBeenCalledOnceWith(spy, 1, 2));
    });

    test("notToEqual", () {
      assertTrue(() => matchers.notToEqual("one", "two"));
      assertFalse(() => matchers.notToEqual("one", "one"));
    });

    test("notToContain", () {
      assertTrue(() => matchers.notToContain("one", "z"));
      assertFalse(() => matchers.notToContain("one", "o"));
    });

    test("notToBe", () {
      var x = [1, 2];
      var y = [1, 2];
      assertTrue(() => matchers.notToBe(x, y));
      assertFalse(() => matchers.notToBe(x, x));
    });

    test("notToBeLessThan", () {
      assertTrue(() => matchers.notToBeLessThan(9, 9));
      assertFalse(() => matchers.notToBeLessThan(-4, 9));
      assertTrue(() => matchers.notToBeLessThan(9, -4));
    });

    test("notToBeGreaterThan", () {
      assertTrue(() => matchers.notToBeGreaterThan(9, 9));
      assertTrue(() => matchers.notToBeGreaterThan(-4, 9));
      assertFalse(() => matchers.notToBeGreaterThan(9, -4));
    });

    test("notToBeCloseTo", () {
      assertFalse(() => matchers.notToBeCloseTo(9, 9, 0));
      assertFalse(() => matchers.notToBeCloseTo(9.123, 9.12, 2));
      assertTrue(() => matchers.notToBeCloseTo(9.123, 9.12, 3));
    });

    test("notToBeA", skipDart2Js(() {
      assertTrue(() => matchers.notToBeA(2, String));
      assertFalse(() => matchers.notToBeA(2, num));
    }));

    test("notToBeAnInstanceOf", () {
      assertTrue(() => matchers.notToBeAnInstanceOf(2, TestClass));
      assertFalse(
          () => matchers.notToBeAnInstanceOf(new TestClass(), TestClass));
    });

    test("toReturnNormally", () {
      assertFalse(() => matchers.toReturnNormally(() => throw "Wow!"));
      assertTrue(() => matchers.toReturnNormally(() {}));
    });

    test("notToHaveHtml", () {
      final div = new html.DivElement()..innerHtml = "<div>inner</div>";
      assertFalse(() => matchers.notToHaveHtml(div, "<div>inner</div>"));
      assertTrue(() => matchers.notToHaveHtml(div, "invalid"));
    });

    test("notToHaveText", () {
      final div = new html.DivElement()..innerHtml = "expected";
      assertFalse(() => matchers.notToHaveText(div, "expected"));
      assertTrue(() => matchers.notToHaveText(div, "invalid"));
    });

    test("notToContainText", () {
      final div = new html.DivElement()..innerHtml = "some expected test";
      assertFalse(() => matchers.notToContainText(div, "expected"));
      assertTrue(() => matchers.notToContainText(div, "invalid"));
    });

    test("notToHaveClass", () {
      final div = new html.DivElement();
      div.classes.add("one");

      assertFalse(() => matchers.notToHaveClass(div, "one"));
      assertTrue(() => matchers.notToHaveClass(div, "two"));
    });

    test("notToHaveAttribute", () {
      final div = new html.DivElement();
      div.attributes["one"] = "value";

      assertFalse(() => matchers.notToHaveAttribute(div, "one"));
      assertTrue(() => matchers.notToHaveAttribute(div, "two"));
    });

    test("notToHaveBeenCalled", () {
      final spy = new guinness2.SpyFunction("");

      assertTrue(() => matchers.notToHaveBeenCalled(spy));

      spy();

      assertFalse(() => matchers.notToHaveBeenCalled(spy));
    });

    test("notToHaveBeenCalledWith", () {
      final spy = new guinness2.SpyFunction("");

      assertTrue(() => matchers.notToHaveBeenCalledWith(spy, 1, 2));

      spy(1, 2);

      assertFalse(() => matchers.notToHaveBeenCalledWith(spy, 1, 2));
      assertTrue(() => matchers.notToHaveBeenCalledWith(spy, 3, 4));
    });

    group("toHaveSameProps", () {
      test("should work for primitives", () {
        assertTrue(() => matchers.toHaveSameProps(1, 1));
        assertFalse(() => matchers.toHaveSameProps(1, 2));
      });

      test("should work for lists", () {
        assertTrue(() => matchers.toHaveSameProps([1, 2], [1, 2]));
        assertFalse(() => matchers.toHaveSameProps([1, 2], [1, 3]));
      });

      test("should work for maps", () {
        assertTrue(
            () => matchers.toHaveSameProps({1: 100, 2: 200}, {1: 100, 2: 200}));
        assertFalse(
            () => matchers.toHaveSameProps({1: 100, 2: 200}, {1: 100, 2: 300}));
      });

      test("should work for custom objects", () {
        final expected = new TestClass(new TestClass([1, 2]));
        final actual = new TestClass(new TestClass([1, 2]));
        assertTrue(() => matchers.toHaveSameProps(actual, expected));

        final falseActual = new TestClass(new TestClass([1, 2, 3]));
        assertFalse(() => matchers.toHaveSameProps(falseActual, expected));
      });

      test("should ignore private fields when comparing private objects", () {
        final expected =
            new TestClass(new TestClassWithPrivateField([1, 2], true));
        final actual =
            new TestClass(new TestClassWithPrivateField([1, 2], false));
        assertTrue(() => matchers.toHaveSameProps(actual, expected));
      });

      test("should skip recursive properties", () {
        final expected = new TestClass("");
        expected.prop = expected;
        assertTrue(() => matchers.toHaveSameProps(expected, expected));
      });
    });

    group("toHaveSameProps", () {
      test("should work", () {
        assertFalse(() => matchers.notToHaveSameProps(1, 1));
        assertTrue(() => matchers.notToHaveSameProps(1, 2));
      });
    });
  });
}

Function skipDart2Js(Function fn) => !identical(1, 1.0) ? fn : () {};
