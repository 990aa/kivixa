# Contributing to Kivixa

First off, thank you for considering contributing to Kivixa! It's people like you that make Kivixa such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title** for the issue to identify the problem.
* **Describe the exact steps which reproduce the problem** in as many details as possible.
* **Provide specific examples to demonstrate the steps**.
* **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior.
* **Explain which behavior you expected to see instead and why.**
* **Include screenshots and animated GIFs** if possible.
* **Include your Flutter version, Dart version, and OS**.

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title** for the issue to identify the suggestion.
* **Provide a step-by-step description of the suggested enhancement** in as many details as possible.
* **Provide specific examples to demonstrate the steps**.
* **Describe the current behavior** and **explain which behavior you expected to see instead** and why.
* **Explain why this enhancement would be useful** to most Kivixa users.

### Pull Requests

* Fill in the required template
* Do not include issue numbers in the PR title
* Follow the Dart style guide
* Include thoughtfully-worded, well-structured tests
* Document new code based on the Documentation Styleguide
* End all files with a newline

## Development Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/YOUR-USERNAME/kivixa.git
   cd kivixa
   ```

2. **Install Flutter**
   - Make sure you have Flutter SDK installed (^3.9.0)
   - Run `flutter doctor` to verify your installation

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
kivixa/
├── lib/
│   ├── main.dart              # Application entry point
│   ├── config/                # Configuration files
│   ├── controllers/           # State management
│   ├── database/              # SQLite database repositories
│   ├── models/                # Data models
│   ├── painters/              # Custom painters
│   ├── screens/               # UI screens
│   ├── services/              # Business logic services
│   ├── utils/                 # Utility functions
│   └── widgets/               # Reusable widgets
├── docs/                      # Documentation
├── test/                      # Unit and widget tests
└── android/ios/web/windows/   # Platform-specific code
```

## Coding Guidelines

### Dart Style Guide

* Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
* Use `flutter analyze` to check for issues
* Use `dart format .` to format your code
* Maximum line length: 80 characters (flexible for readability)

### Code Quality

* Write clear, self-documenting code
* Add comments for complex logic
* Use meaningful variable and function names
* Keep functions small and focused on a single task
* Avoid deeply nested code

### Testing

* Write tests for new features
* Ensure all tests pass before submitting a PR
* Aim for high test coverage
* Include both unit tests and widget tests

```bash
flutter test
```

### Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line

Examples:
```
Add PDF annotation feature

Implement PDF viewer with annotation capabilities including:
- Pen tool for freehand drawing
- Text highlighting
- Shape drawing (rectangles, circles)

Fixes #123
```

## Architecture Guidelines

### Database Layer
* Use repository pattern for database operations
* Keep all SQL queries in repository classes
* Use transactions for multi-step operations

### UI Layer
* Keep widgets focused and composable
* Extract reusable components into separate widget files
* Use StatefulWidget only when necessary
* Prefer immutable data structures

### Service Layer
* Business logic should be in service classes
* Services should be independent of UI
* Use dependency injection where appropriate

### State Management
* Document state management approach for your feature
* Keep state as local as possible
* Use appropriate state management solutions

## Documentation

* Update README.md if you change functionality
* Add doc comments to public APIs
* Update relevant documentation in the `docs/` folder
* Include examples for complex features

## Performance

* Profile your code for performance bottlenecks
* Use `const` constructors where possible
* Avoid unnecessary rebuilds
* Optimize images and assets
* Test on real devices, not just emulators

## Accessibility

* Ensure UI is accessible to all users
* Add semantic labels to interactive elements
* Support screen readers
* Test with accessibility tools

## Release Process

1. All changes must be reviewed by at least one maintainer
2. All tests must pass
3. Documentation must be updated
4. Version numbers follow [Semantic Versioning](https://semver.org/)

## Getting Help

* Check the [documentation](docs/)
* Ask questions in GitHub Discussions
* Join our community chat (if available)

## Recognition

Contributors will be recognized in:
* The project README
* Release notes
* The contributors list

Thank you for contributing to Kivixa! 🎨
