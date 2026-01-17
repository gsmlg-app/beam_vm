/// Exception thrown when BEAM VM operations fail.
class BeamVmException implements Exception {
  /// The error message describing what went wrong.
  final String message;

  /// Optional error code from the platform.
  final String? code;

  /// Optional additional details about the error.
  final dynamic details;

  /// Creates a new [BeamVmException].
  BeamVmException(this.message, {this.code, this.details});

  @override
  String toString() =>
      'BeamVmException: $message${code != null ? ' ($code)' : ''}';
}
