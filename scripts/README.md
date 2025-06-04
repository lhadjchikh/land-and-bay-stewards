# Project Scripts

This directory contains project-wide scripts that operate across multiple components of the Land and Bay Stewards application.

## 📁 Available Scripts

### `lint.py`

Comprehensive linting and formatting script that processes the entire codebase.

**Languages/Tools Supported:**

- **Python**: Black formatting, Ruff linting
- **Go**: gofmt, go vet, golangci-lint, staticcheck, gosec
- **JavaScript/TypeScript**: Prettier formatting (via npm)
- **Terraform**: terraform fmt, tflint
- **Shell Scripts**: ShellCheck, shfmt

**Usage:**

```bash
# Run all linters
python scripts/lint.py

# Or with Python from backend directory
cd backend && poetry run python ../scripts/lint.py
```

**Features:**

- 🎨 **Auto-formatting**: Fixes formatting issues automatically
- 🔧 **Tool Installation**: Installs missing linting tools automatically
- 📊 **Progress Reporting**: Clear visual feedback with sections and status
- 🚀 **Performance**: Skips missing tools gracefully
- 🛡️ **Security**: Includes security scanning for Go and shell scripts

## 🏗️ Script Organization

### Root Scripts (`/scripts/`)

Project-wide operations that affect multiple components:

- **Linting & Formatting**: Code quality across all languages
- **Setup & Installation**: Project initialization scripts
- **Deployment**: Cross-component deployment automation
- **Testing**: Integration testing across components

### Component Scripts

Component-specific operations remain in their respective directories:

- **Backend Scripts** (`backend/scripts/`): Django-specific utilities
- **Frontend Scripts** (`frontend/scripts/`): React/Node.js utilities
- **Infrastructure Scripts** (`terraform/scripts/`): Infrastructure utilities

## 🚀 Usage Patterns

### Development Workflow

```bash
# Format and lint everything before commit
python scripts/lint.py

# Set up git hook (optional)
echo "python scripts/lint.py" > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### CI/CD Integration

```yaml
# GitHub Actions example
- name: Run project linting
  run: python scripts/lint.py
```

### IDE Integration

Many IDEs can be configured to run the lint script:

- **VS Code**: Configure as a task
- **PyCharm**: Configure as an external tool
- **Vim/Neovim**: Configure as a command

## 🔧 Adding New Scripts

When adding new project-wide scripts:

1. **Create the script** in this directory
2. **Add executable permissions** if it's a shell script
3. **Update this README** with usage instructions
4. **Consider dependencies** - document any required tools
5. **Follow naming conventions**:
   - Use descriptive names (`lint.py`, `setup.py`, `deploy.py`)
   - Use lowercase with underscores for Python scripts
   - Use kebab-case for shell scripts (`setup-env.sh`)

### Script Template

```python
#!/usr/bin/env python3
"""
Brief description of what this script does.

Usage:
    python scripts/script_name.py [options]
"""

from pathlib import Path
import sys

def main() -> int:
    """Main function that returns exit code."""
    project_root = Path(__file__).parent.parent

    # Script implementation here

    return 0

if __name__ == "__main__":
    sys.exit(main())
```

## 📦 Dependencies

### Required

- **Python 3.13+**: For running Python scripts
- **Node.js 18+**: For Prettier formatting (if frontend exists)

### Optional (auto-installed by lint.py)

- **Go tools**: gofmt, staticcheck, golangci-lint, gosec
- **Terraform tools**: terraform, tflint
- **Shell tools**: shellcheck, shfmt

## 🤝 Contributing

When modifying scripts:

1. **Test thoroughly** across different environments
2. **Update documentation** if behavior changes
3. **Maintain backward compatibility** when possible
4. **Follow the project's coding standards**
5. **Add error handling** for common failure cases

## 🔗 Related Documentation

- [Backend Scripts](../backend/scripts/README.md) - Django-specific utilities
- [Frontend Package Scripts](../frontend/package.json) - npm scripts for frontend
- [Terraform Testing](../terraform/tests/README.md) - Infrastructure testing
- [CI/CD Workflows](../.github/workflows/README.md) - Automated pipeline scripts
