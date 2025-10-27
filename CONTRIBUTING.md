# Contributing to gacs_pack

First off, thank you for considering contributing to gacs_pack! It's people like you that make gacs_pack such a great tool.

## Code of Conduct

This project adheres to the [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Describe the behavior you observed and what you expected**
- **Include Ruby version, Rails version, and gem version**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested enhancement**
- **Explain why this enhancement would be useful**
- **List any alternatives you've considered**

### Pull Requests

1. **Fork the repo** and create your branch from `main`
2. **Follow the coding style** (RuboCop will help)
3. **Add tests** for any new functionality
4. **Update documentation** if you change behavior
5. **Ensure the test suite passes** (`bundle exec rspec`)
6. **Ensure RuboCop passes** (`bundle exec rubocop`)
7. **Ensure Steep passes** (if you modified type signatures)

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/gacs_pack.git
cd gacs_pack

# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Run type checker
bundle exec steep check
```

## Coding Standards

### Ruby Style

- Follow the [Ruby Style Guide](https://rubystyle.guide/)
- Run `bundle exec rubocop` to check compliance
- We use double quotes for strings
- Target Ruby 3.1+

### Testing

- Write RSpec tests for all new features
- Maintain or improve test coverage
- Use descriptive test names
- Test both success and failure cases

### Type Signatures

- Add RBS type signatures for new classes/methods
- Update signatures when changing method signatures
- Run `bundle exec steep check` to validate

### Documentation

- Document public APIs with YARD comments
- Update README if adding user-facing features
- Add examples for complex features
- Update relevant docs in `docs/` directory

## Project Structure

```
gacs_pack/
├── lib/
│   ├── gacs_pack/
│   │   ├── ports/         # Port interfaces
│   │   ├── config.rb
│   │   ├── context_engine.rb
│   │   ├── snapshot.rb
│   │   ├── token_budgeter.rb
│   │   └── ...
│   └── gacs_pack.rb       # Main entry point
├── sig/                   # RBS type signatures
├── spec/                  # RSpec tests
├── docs/                  # Documentation
└── README.md
```

## Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters
- Reference issues and pull requests when relevant

Examples:
```
Add TokenBudgeter class with weight-based prioritization

Fixes #123

- Implements sorting by section weight
- Delegates truncation to tokenizer adapter
- Adds comprehensive unit tests
```

## Release Process

(For maintainers)

1. Update version in `lib/gacs_pack/version.rb`
2. Update `CHANGELOG.md`
3. Run full test suite
4. Create git tag: `git tag v0.x.0`
5. Push tag: `git push --tags`
6. Build gem: `gem build gacs_pack.gemspec`
7. Push to RubyGems: `gem push gacs_pack-0.x.0.gem`

## Questions?

Feel free to open an issue with the question label or reach out to the maintainers.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
