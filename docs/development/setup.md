# Development Environment Setup

This guide helps developers set up their environment to pass all linting checks.

## 🚀 Quick Setup

### Option 1: Automated Setup (Recommended)

Run the automated setup script that handles most configuration:

```bash
# Auto-detect your OS and set up everything
python scripts/setup_dev_env.py

# Or specify your OS explicitly
python scripts/setup_dev_env.py --os macos    # macOS with Homebrew
python scripts/setup_dev_env.py --os linux    # Ubuntu/Debian with apt
python scripts/setup_dev_env.py --os windows  # Windows with winget
```

### Option 2: Manual Setup

If you prefer manual setup or the automated script has issues:

#### 1. Install Python 3.13

**macOS:**

```bash
brew install python@3.13
```

**Linux (Ubuntu/Debian):**

```bash
sudo apt update
sudo apt install python3.13 python3.13-venv python3.13-dev
```

**Windows:**

```bash
winget install Python.Python.3.13
# or
choco install python --version=3.13
```

#### 2. Configure Poetry

```bash
cd backend
poetry env use python3.13
poetry install
```

#### 3. Install Go

**macOS:**

```bash
brew install go
```

**Linux:**

```bash
sudo apt install golang-go
# or download from https://golang.org/
```

**Windows:**

```bash
winget install GoLang.Go
# or
choco install golang
```

#### 4. Install Go Tools

```bash
# Add Go tools to PATH first
export PATH=$PATH:$(go env GOPATH)/bin  # Linux/macOS
# On Windows, add %GOPATH%\bin to your PATH environment variable

# Install linting tools
go install honnef.co/go/tools/cmd/staticcheck@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install github.com/gordonklaus/ineffassign@latest
go install github.com/client9/misspell/cmd/misspell@latest
```

#### 5. Install Other Tools

**macOS:**

```bash
brew install terraform tflint shellcheck shfmt node
```

**Linux:**

```bash
sudo apt install shellcheck nodejs npm
# For terraform and tflint, see their respective installation guides
```

**Windows:**

```bash
winget install Hashicorp.Terraform terraform-linters.tflint koalaman.shellcheck OpenJS.NodeJS
```

## 🔧 Final Configuration

### Shell Profile Setup

Add Go tools to your PATH permanently:

**Linux/macOS (~/.bashrc, ~/.zshrc):**

```bash
export PATH=$PATH:$(go env GOPATH)/bin
```

**Windows:**
Add `%GOPATH%\bin` to your PATH environment variable through System Properties.

### Test Your Setup

```bash
# Run all linters
python scripts/lint.py
```

You should see:

- ✅ PASSED - Python
- ✅ PASSED - Prettier
- ✅ PASSED - Terraform
- ✅ PASSED - Shell Scripts
- ⚠️ Go (may have issues due to Terraform test code)

## 🐛 Known Issues

### Go Linting Failures

The Go linter may fail due to outdated code in `terraform/tests/` that uses deprecated Terratest API functions:

```
undefined: aws.GetSubnetById
undefined: aws.GetSecurityGroupById
vpc.State undefined
```

**Workaround:** These are non-critical test files. The main application code will still be linted correctly.

**Fix:** Update the Terratest code to use the current API (see Terratest documentation).

### gosec Installation Issues

The `gosec` security scanner may fail to install due to repository access issues. This is optional and doesn't affect core linting.

## 📚 Tool Documentation

- **Python Linting**: Uses Black (formatting) + Ruff (linting)
- **Go Linting**: Uses gofmt, go vet, staticcheck, golangci-lint
- **JavaScript/TypeScript**: Uses Prettier via npm
- **Terraform**: Uses terraform fmt + tflint
- **Shell Scripts**: Uses ShellCheck + shfmt

## 🆘 Troubleshooting

### Poetry Python Version Issues

```bash
# Check current Poetry environment
poetry env list

# Force Poetry to use Python 3.13
poetry env use python3.13
poetry install
```

### Go Tools Not Found

```bash
# Check if Go is installed
go version

# Check GOPATH
go env GOPATH

# Verify tools are installed
ls $(go env GOPATH)/bin/

# Add to PATH if missing
export PATH=$PATH:$(go env GOPATH)/bin
```

### npm/Node.js Issues

```bash
# Check Node.js version
node --version
npm --version

# Install frontend dependencies
cd frontend && npm install
```

## 💡 Tips

1. **Use the automated setup script first** - it handles most edge cases
2. **Restart your terminal** after installing tools
3. **Check your shell profile** to ensure PATH changes persist
4. **Run `python scripts/lint.py`** to test everything works
5. **Use VS Code extensions** for real-time linting feedback

## 🤝 Getting Help

If you encounter issues:

1. Run the setup script: `python scripts/setup_dev_env.py`
2. Check this troubleshooting guide
3. Verify your environment matches the requirements above
4. Open an issue with your specific error message and OS details
