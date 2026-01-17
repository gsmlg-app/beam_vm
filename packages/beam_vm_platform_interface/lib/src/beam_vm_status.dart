/// Status of the BEAM VM.
enum BeamVmStatus {
  /// VM has not been initialized.
  uninitialized,

  /// VM is currently initializing.
  initializing,

  /// VM is running and ready to accept commands.
  running,

  /// VM encountered an error.
  error,

  /// VM is shutting down.
  shuttingDown,
}
