import 'error.dart';

/// Helper class for JSON Pointers.
/// See https://tools.ietf.org/html/rfc6901 for more information.
class JsonPointer {
  const JsonPointer.fromSegments(this.segments) : assert(segments != null);

  factory JsonPointer.fromString(String pointer) {
    if (!(pointer.isEmpty || pointer.startsWith('/'))) {
      throw JsonPatchError('Invalid JSON Pointer: "$pointer".');
    }

    return JsonPointer.fromSegments(pointer
        .split('/')
        .skip(1)
        .map((String segment) => segment
            .replaceAll(RegExp(r'~1'), '/')
            .replaceAll(RegExp(r'~0'), '~'))
        .toList());
  }

  factory JsonPointer.join(JsonPointer lhs, JsonPointer rhs) {
    return JsonPointer.fromSegments(
      List.from(lhs.segments)..addAll(rhs.segments),
    );
  }

  final List<String> segments;

  bool get isRoot => segments.isEmpty;
  bool get hasParent => !isRoot;
  JsonPointer get parent {
    assert(hasParent);
    return JsonPointer.fromSegments(List.from(segments)..removeLast());
  }

  /// Returns the value this pointer points to.
  /// [json] must be a JSON-like object.
  dynamic traverse(dynamic json) {
    dynamic current = json;
    for (final segment in segments) {
      if (current is Map<String, dynamic>) {
        if (!current.containsKey(segment)) {
          throw JsonPatchError(
              'Argument $json does not contain value at $this');
        }
        current = current[segment];
      } else if (current is List) {
        try {
          current = current[int.parse(segment)];
        } catch (e) {
          throw JsonPatchError(
              'Argument $json does not contain value at $this');
        }
      } else {
        throw JsonPatchError('Argument $json does not contain value at $this');
      }
    }
    return current;
  }

  @override
  String toString() {
    return segments
        .map((String segment) => segment
            .replaceAll(RegExp(r'~'), '~0')
            .replaceAll(RegExp(r'/'), '~1'))
        .map((String segment) => '/' + segment)
        .join();
  }
}
