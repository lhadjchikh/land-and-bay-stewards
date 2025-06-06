import os
import shutil
import subprocess
import sys
from collections.abc import Callable
from pathlib import Path


def print_section_header(title: str) -> None:
    """Print a formatted section header."""
    print(f"\n{'='*60}")
    print(f" {title}")
    print(f"{'='*60}")


def print_step(step: str) -> None:
    """Print a formatted step indicator."""
    print(f"\n🔧 {step}")
    print("-" * 50)


def run_command(cmd: list[str], cwd: str | Path | None = None) -> bool:
    """Run a command and print its output.

    Args:
        cmd: Command to run as a list of strings
        cwd: Directory to run the command in

    Returns:
        True if the command was successful, False otherwise
    """
    print(f"   └─ {' '.join(cmd)}")
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            check=True,
            text=True,
            capture_output=True,
        )
        if result.stdout:
            # Indent output for better readability
            indented_output = "\n".join(
                f"      {line}" for line in result.stdout.strip().split("\n")
            )
            print(indented_output)
        print("   ✅ Success")
        return True
    except subprocess.CalledProcessError as e:
        print(f"   ❌ Error: {e}")
        if e.stdout:
            indented_output = "\n".join(
                f"      {line}" for line in e.stdout.strip().split("\n")
            )
            print(indented_output)
        if e.stderr:
            indented_output = "\n".join(
                f"      {line}" for line in e.stderr.strip().split("\n")
            )
            print(indented_output)
        return False


def which(cmd: str) -> str | None:
    """Check if a command exists by using shutil.which."""
    # First try the standard approach
    result = shutil.which(cmd)
    if result:
        return result
    
    # For Go tools, also check common Go installation paths
    if cmd in ["golangci-lint", "staticcheck", "gosec", "ineffassign", "misspell"]:
        # Check common Go bin directories
        common_go_paths = [
            os.path.expanduser("~/go/bin"),
            "/usr/local/go/bin",
            "/opt/go/bin",
        ]
        
        # Also try to get GOPATH from go env if available
        try:
            if shutil.which("go"):
                gopath_result = subprocess.run(
                    ["go", "env", "GOPATH"], 
                    capture_output=True, 
                    text=True, 
                    timeout=5
                )
                if gopath_result.returncode == 0:
                    gopath = gopath_result.stdout.strip()
                    if gopath:
                        common_go_paths.insert(0, f"{gopath}/bin")
        except (subprocess.TimeoutExpired, subprocess.SubprocessError):
            pass
        
        # Check each potential path
        for go_bin_path in common_go_paths:
            tool_path = os.path.join(go_bin_path, cmd)
            if os.path.isfile(tool_path) and os.access(tool_path, os.X_OK):
                return tool_path
    
    return None


def run_python_linters(project_root: Path) -> tuple[bool, bool]:
    """Run Python linters with auto-fix.

    Args:
        project_root: Path to the project root directory

    Returns:
        Tuple of (success, was_run) - success indicates if linters passed, was_run indicates if they could run
    """
    print_section_header("PYTHON LINTING")
    success = True

    backend_dir = project_root / "backend"
    
    # Check if backend directory exists
    if not backend_dir.exists():
        print("⚠️  Backend directory not found. Skipping Python linting.")
        return True, False
    
    # Check if poetry is available
    if not which("poetry"):
        print("⚠️  Poetry is not installed. Skipping Python linting.")
        return True, False

    print_step("Running Black code formatter")
    success &= run_command(["poetry", "run", "black", "."], cwd=backend_dir)

    print_step("Running Ruff linter with auto-fix")
    # Run ruff with --fix to auto-fix issues
    success &= run_command(
        ["poetry", "run", "ruff", "check", "--fix", "."],
        cwd=backend_dir,
    )

    return success, True


def run_prettier(project_root: Path) -> tuple[bool, bool]:
    """Run prettier on all supported file types in the project directory.

    Args:
        project_root: Path to the project root directory

    Returns:
        Tuple of (success, was_run) - success indicates if formatters passed, was_run indicates if they could run
    """
    print_section_header("PRETTIER FORMATTING")
    success = True

    # Skip if the project_root doesn't exist
    if not project_root.exists():
        print("⚠️  Project root directory not found. Skipping Prettier formatting.")
        return True, False

    frontend_dir = project_root / "frontend"
    if not frontend_dir.exists():
        print("⚠️  Frontend directory not found. Skipping Prettier formatting.")
        return True, False

    # Check if package.json exists and verify npm scripts
    package_json = frontend_dir / "package.json"
    if not package_json.exists():
        print(
            "⚠️  No package.json found in frontend directory. "
            "Skipping Prettier formatting.",
        )
        return True, False
    
    # Check if npm is available
    if not which("npm"):
        print("⚠️  npm is not installed. Skipping Prettier formatting.")
        return True, False

    try:
        # First, try to run the format:all script which is defined in package.json
        print_step("Running comprehensive format:all script")
        format_result = run_command(
            ["npm", "--prefix", "frontend", "run", "format:all"],
            cwd=project_root,
        )

        if not format_result:
            print("⚠️  Format:all script failed, trying alternative approaches...")
            success = False

            # Try YAML formatting as a fallback
            print_step("Fallback: YAML formatting")
            yaml_result = run_command(
                ["npm", "--prefix", "frontend", "run", "yaml:format"],
                cwd=project_root,
            )

            # Try the basic format command for frontend files
            print_step("Fallback: Basic frontend formatting")
            basic_result = run_command(
                ["npm", "--prefix", "frontend", "run", "format"],
                cwd=project_root,
            )

            # If any of the fallback methods succeed, consider it a partial success
            if yaml_result or basic_result:
                print("⚠️  Some formatting completed, but format:all failed.")
                # Still mark as failure since format:all should work
                success = False
            else:
                print("❌ All formatting attempts failed.")
                success = False
    except Exception as e:
        print(f"❌ Error running Prettier: {e}")
        success = False

    return success, True


def run_terraform_linters(project_root: Path) -> tuple[bool, bool]:
    """Run Terraform linters if terraform is installed.

    Args:
        project_root: Path to the project root directory

    Returns:
        Tuple of (success, was_run) - success indicates if linters passed, was_run indicates if they could run
    """
    print_section_header("TERRAFORM LINTING")
    success = True

    terraform_dir = project_root / "terraform"

    # Skip if terraform directory doesn't exist
    if not terraform_dir.exists():
        print("⚠️  Terraform directory not found. Skipping terraform lint checks.")
        return True, False

    # Skip if terraform is not installed
    if not which("terraform"):
        print("⚠️  Terraform is not installed. Skipping terraform lint checks.")
        return True, False

    # Run terraform fmt with -write=true to auto-fix formatting
    print_step("Running Terraform formatting")
    success &= run_command(
        ["terraform", "fmt", "-write=true", "-recursive"],
        cwd=terraform_dir,
    )

    # Check for tflint binary
    if not which("tflint"):
        print("⚠️  TFLint is not installed. Skipping tflint checks.")
    else:
        try:
            # Check for GitHub token to avoid rate limiting
            if "GITHUB_TOKEN" not in os.environ:
                print_step(
                    "Initializing TFLint (without plugins due to missing GITHUB_TOKEN)",
                )
                print(
                    "      ⚠️  Warning: GITHUB_TOKEN not found in environment. "
                    "TFLint plugin initialization may fail due to GitHub API "
                    "rate limits.",
                )
                # Use --no-plugins if we don't have a token
                # to avoid API rate limit errors
                init_args = ["tflint", "--no-plugins"]
            else:
                print_step("Initializing TFLint with plugins")
                init_args = ["tflint", "--init"]

            # Try to initialize TFLint (with or without plugins)
            init_result = run_command(init_args, cwd=terraform_dir)

            # Run TFLint recursively if initialization succeeded
            if init_result:
                print_step("Running TFLint recursive check")
                success &= run_command(["tflint", "--recursive"], cwd=terraform_dir)
            else:
                print(
                    "❌ Skipping recursive TFLint check due to initialization failure",
                )
                success = False
        except Exception as e:
            print(f"❌ Error running TFLint: {e}")
            success = False

    return success, True


def run_shell_linters(project_root: Path) -> tuple[bool, bool]:
    """Run shell script linters if shellcheck is installed.

    Args:
        project_root: Path to the project root directory

    Returns:
        Tuple of (success, was_run) - success indicates if linters passed, was_run indicates if they could run
    """
    print_section_header("SHELL SCRIPT LINTING")
    success = True

    # Skip if shellcheck is not installed
    if not which("shellcheck"):
        print("⚠️  ShellCheck is not installed. Skipping shell script lint checks.")
        return True, False

    # Find all .sh files in the project
    shell_scripts = list(project_root.glob("**/*.sh"))
    if not shell_scripts:
        print("ℹ️  No shell scripts found in project.")
        return True, False

    ignored_dirs = [".git", "node_modules", ".terraform"]

    # Filter out ignored directories
    filtered_scripts = []
    for script in shell_scripts:
        if not any(ignore_dir in str(script) for ignore_dir in ignored_dirs):
            filtered_scripts.append(script)

    if not filtered_scripts:
        print("ℹ️  No shell scripts found outside of ignored directories.")
        return True, False

    print_step(f"Found {len(filtered_scripts)} shell script(s) to check")

    for script in filtered_scripts:
        print(f"\n   📄 Checking {script.relative_to(project_root)}")

        # Run shellcheck with -x to follow external sources
        script_success = run_command(
            ["shellcheck", "-x", str(script)],
            cwd=project_root,
        )
        success &= script_success

        # Auto-fix shell scripts if the shellcheck-fix command is available
        if which("shellcheck-fix"):
            print(f"   🔧 Auto-fixing {script.relative_to(project_root)}")
            run_command(["shellcheck-fix", str(script)], cwd=project_root)
        elif which("shfmt"):
            # As an alternative, format the shell scripts with shfmt
            print(f"   🎨 Formatting {script.relative_to(project_root)} with shfmt")
            run_command(
                ["shfmt", "-w", "-i", "2", "-ci", str(script)],
                cwd=project_root,
            )

    return success, True


def run_go_linters(project_root: Path) -> tuple[bool, bool]:
    """Run Go linters if Go is installed and Go projects exist.

    Args:
        project_root: Path to the project root directory

    Returns:
        Tuple of (success, was_run) - success indicates if linters passed, was_run indicates if they could run
    """
    print_section_header("GO LINTING")
    success = True

    # Skip if Go is not installed
    if not which("go"):
        print("⚠️  Go is not installed. Skipping Go lint checks.")
        return True, False

    # Find Go modules in the project
    go_modules = []
    for go_mod in project_root.glob("**/go.mod"):
        # Skip node_modules and other common directories to ignore
        ignored_dirs = [".git", "node_modules", ".terraform", "vendor"]
        if not any(ignore_dir in str(go_mod) for ignore_dir in ignored_dirs):
            go_modules.append(go_mod.parent)

    if not go_modules:
        print("ℹ️  No Go modules found in project.")
        return True, False

    print_step(f"Found {len(go_modules)} Go module(s) to check")

    for module_dir in go_modules:
        module_name = module_dir.relative_to(project_root)
        print(f"\n   📦 Processing module: {module_name}")

        # Check Go formatting
        print(f"   🎨 Checking Go formatting")
        format_result = run_command(["gofmt", "-l", "."], cwd=module_dir)
        if not format_result:
            success = False
        else:
            # If gofmt found unformatted files, try to fix them
            print(f"   🔧 Auto-formatting Go files")
            run_command(["gofmt", "-w", "."], cwd=module_dir)

        # Run go vet
        print(f"   🔍 Running go vet")
        vet_result = run_command(["go", "vet", "./..."], cwd=module_dir)
        success &= vet_result

        # Run go mod tidy
        print(f"   📦 Checking module tidiness")
        tidy_result = run_command(["go", "mod", "tidy"], cwd=module_dir)
        success &= tidy_result

        # Run staticcheck if available
        staticcheck_path = which("staticcheck")
        if staticcheck_path:
            print(f"   🧹 Running staticcheck")
            staticcheck_result = run_command([staticcheck_path, "./..."], cwd=module_dir)
            success &= staticcheck_result
        else:
            print(f"   ⚠️  staticcheck not found, installing...")
            install_result = run_command(
                ["go", "install", "honnef.co/go/tools/cmd/staticcheck@latest"],
                cwd=module_dir,
            )
            if install_result:
                # Try running staticcheck via go run if not in PATH
                print(f"   🧹 Running staticcheck via go run")
                staticcheck_result = run_command(
                    ["go", "run", "honnef.co/go/tools/cmd/staticcheck@latest", "./..."], 
                    cwd=module_dir
                )
                success &= staticcheck_result

        # Run golangci-lint if available
        golangci_lint_path = which("golangci-lint")
        if golangci_lint_path:
            print(f"   ⚡ Running golangci-lint")
            # Check if config exists, use it if available
            config_args = []
            if (module_dir / ".golangci.yml").exists():
                config_args = ["--config", ".golangci.yml"]
            elif (module_dir / ".golangci.yaml").exists():
                config_args = ["--config", ".golangci.yaml"]
            
            lint_cmd = [golangci_lint_path, "run"] + config_args + ["./..."]
            lint_result = run_command(lint_cmd, cwd=module_dir)
            success &= lint_result
        else:
            print(f"   ℹ️  golangci-lint not found. Run 'python scripts/setup_dev_env.py' to install it.")

        # Run ineffassign if available
        ineffassign_path = which("ineffassign")
        if ineffassign_path:
            print(f"   🎯 Checking ineffective assignments")
            ineffassign_result = run_command([ineffassign_path, "./..."], cwd=module_dir)
            success &= ineffassign_result
        else:
            print(f"   ℹ️  ineffassign not found. Run 'python scripts/setup_dev_env.py' to install it.")

        # Run misspell if available
        misspell_path = which("misspell")
        if misspell_path:
            print(f"   📝 Checking for misspellings")
            misspell_result = run_command([misspell_path, "-error", "."], cwd=module_dir)
            success &= misspell_result
        else:
            print(f"   ℹ️  misspell not found. Run 'python scripts/setup_dev_env.py' to install it.")

        # Security check with gosec if available
        gosec_path = which("gosec")
        if gosec_path:
            print(f"   🔒 Running security scan")
            # Don't fail on security findings, just report them
            gosec_result = run_command(
                [gosec_path, "-quiet", "./..."], 
                cwd=module_dir
            )
            # Note: We don't update success here as gosec findings are informational
            if not gosec_result:
                print(f"   ⚠️  Security findings detected - please review")
        else:
            print(f"   ℹ️  gosec not found. Run 'python scripts/setup_dev_env.py' to install it.")

    return success, True


def main() -> int:
    """Run all linters and formatters.

    Returns:
        0 if all linters succeeded, 1 otherwise
    """
    project_root = Path(__file__).parent.parent

    print_section_header("STARTING LINT & FORMAT PROCESS")
    print(f"📁 Project root: {project_root}")
    print(f"🕐 Started at: {Path(__file__).name}")

    # Define all linter functions to run
    linters: list[tuple[str, Callable[[Path], tuple[bool, bool]]]] = [
        ("Python", lambda root: run_python_linters(root)),
        ("Prettier", lambda root: run_prettier(root)),
        ("Terraform", lambda root: run_terraform_linters(root)),
        ("Shell Scripts", lambda root: run_shell_linters(root)),
        ("Go", lambda root: run_go_linters(root)),
    ]

    # Run all linters
    success = True
    results = []

    for name, linter in linters:
        linter_success, was_run = linter(project_root)
        # Only count failures if the linter actually ran
        if was_run:
            success &= linter_success
        results.append((name, linter_success, was_run))

    # Print summary
    print_section_header("SUMMARY")
    for name, linter_success, was_run in results:
        if not was_run:
            status = "⏭️  SKIPPED"
        elif linter_success:
            status = "✅ PASSED"
        else:
            status = "❌ FAILED"
        print(f"{status} - {name}")

    print(f"\n{'='*60}")
    if success:
        print("🎉 ALL LINTERS COMPLETED SUCCESSFULLY!")
        print("Your code is properly formatted and passes all checks.")
        return 0
    else:
        print("❌ ONE OR MORE LINTERS FAILED")
        print("Please review the output above and fix any issues manually.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
