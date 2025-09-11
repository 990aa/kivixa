sealed class DomainError {
  const DomainError();
}

class NotFoundError extends DomainError {
  final String message;
  const NotFoundError(this.message);
}

class DatabaseError extends DomainError {
  final String message;
  const DatabaseError(this.message);
}

class ValidationError extends DomainError {
  final String message;
  const ValidationError(this.message);
}

class PermissionError extends DomainError {
  final String message;
  const PermissionError(this.message);
}

// Add more error types as needed
