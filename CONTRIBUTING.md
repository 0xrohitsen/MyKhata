# Contributing to My Khata

First off, thank you for considering contributing to My Khata! 🎉

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples to demonstrate the steps**
- **Describe the behavior you observed after following the steps**
- **Explain which behavior you expected to see instead and why**
- **Include device information** (Android version, device model, app version)

### 💡 Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Use a clear and descriptive title**
- **Provide a step-by-step description of the suggested enhancement**
- **Provide specific examples to demonstrate the steps**
- **Describe the current behavior and explain which behavior you expected to see instead**
- **Explain why this enhancement would be useful**

### 🔧 Pull Requests

1. Fork the repository
2. Create a new branch from `main`: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Add or update tests if needed
5. Ensure the code follows the project's coding standards
6. Commit your changes: `git commit -m 'Add some amazing feature'`
7. Push to the branch: `git push origin feature/amazing-feature`
8. Submit a pull request

## Development Setup

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio or VS Code
- Git
- Firebase CLI (for backend setup)

### Local Setup

1. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR-USERNAME/MyKhata.git
   cd MyKhata
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase** (for testing)
   - Create a test Firebase project
   - Add your development SHA-1 key
   - Download `google-services.json` to `android/app/`

4. **Run the app**
   ```bash
   flutter run
   ```

## Coding Standards

### Dart Code Style

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter format` to format your code
- Run `flutter analyze` to check for issues

### Architecture Guidelines

This project follows Clean Architecture principles:

```
lib/
├── core/          # Shared utilities, constants, themes
├── features/      # Feature-based modules
│   ├── auth/
│   ├── customers/
│   └── transactions/
└── shared/        # Shared widgets and components
```

### State Management

- Use Riverpod for state management
- Follow the repository pattern
- Separate business logic from UI components

### Database

- Store monetary amounts as integers (in paise) to avoid floating-point precision issues
- Use Firestore transactions for atomic updates
- Follow the established schema structure

## Testing

- Write unit tests for business logic
- Add widget tests for UI components
- Test offline functionality
- Ensure Firebase Auth works in both debug and release builds

## Documentation

- Update README.md if you change installation steps or add new features
- Comment complex business logic
- Update API documentation for new endpoints

## Commit Message Guidelines

Use conventional commit format:

```
type(scope): description

Examples:
feat(auth): add Google Sign-In support
fix(transactions): resolve balance calculation bug
docs(readme): update installation instructions
style(ui): improve customer list design
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code changes that neither fix a bug nor add a feature
- `test`: Adding missing tests
- `chore`: Changes to build process or auxiliary tools

## Release Process

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Create a new tag: `git tag v1.x.x`
4. Build release: `flutter build appbundle --release`
5. Create GitHub release with APK/AAB

## Questions?

Feel free to ask questions by creating an issue labeled with `question`.

## Recognition

Contributors will be recognized in the README.md file and release notes.

Thank you for contributing to My Khata! 🚀