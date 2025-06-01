import shutil
import subprocess
import sys
from collections.abc import Callable
from pathlib import Path


def run_command(cmd: list[str], cwd: str | Path | None = None) -> bool:
    """Run a command and print its output.

    Args:
        cmd: Command to run as a list of strings
        cwd: Directory to run the command in

    Returns:
        True if the command was successful, False otherwise
    """
    print(f"Running: {' '.join(cmd)}")
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            check=True,
            text=True,
            capture_output=True,
        )
        if result.stdout:
            print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {e}")
        if e.stdout:
            print(e.stdout)
        if e.stderr:
            print(e.stderr)
        return False


def which(cmd: str) -> str | None:
    """Check if a command exists by using shutil.which."""
    return shutil.which(cmd)


def run_python_linters(project_root: Path) -> bool:
    """Run Python linters with auto-fix.

    Args:
        project_root: Path to the project root directory

    Returns:
        True if all linters succeeded, False otherwise
    """
    success = True

    print("Running black...")
    success &= run_command(["poetry", "run", "black", "."], cwd=project_root)

    print("Running ruff...")
    # Run ruff with --fix to auto-fix issues
    success &= run_command(
        ["poetry", "run", "ruff", "check", "--fix", "."],
        cwd=project_root,
    )

    return success


def run_frontend_formatters(project_root: Path) -> bool:
    """Run frontend formatters if the frontend directory exists.

    Args:
        project_root: Path to the project root directory

    Returns:
        True if all formatters succeeded or were skipped, False otherwise
    """
    success = True

    # Skip if the project_root doesn't exist
    if not project_root.exists():
        return success

    # Format YAML files using Prettier
    print("Running YAML formatting...")
    print("Auto-formatting YAML files using Prettier...")
    success &= run_command(
        ["npm", "--prefix", "frontend", "run", "yaml:format"],
        cwd=project_root,
    )

    # Format Markdown files using Prettier
    print("Running Markdown formatting...")
    print("Formatting Markdown files using Prettier...")
    success &= run_command(
        ["npm", "--prefix", "frontend", "run", "format:all"],
        cwd=project_root,
    )

    return success


def run_terraform_linters(project_root: Path) -> bool:
    """Run Terraform linters if terraform is installed.

    Args:
        project_root: Path to the project root directory

    Returns:
        True if all linters succeeded or were skipped, False otherwise
    """
    success = True

    # Skip if terraform is not installed
    if not which("terraform"):
        print("Terraform is not installed. Skipping terraform lint checks.")
        return success

    # Run terraform fmt with -write=true to auto-fix formatting
    print("Running terraform fmt...")
    success &= run_command(
        ["terraform", "fmt", "-write=true", "-recursive"],
        cwd=project_root,
    )

    # Check for tflint binary
    if not which("tflint"):
        print("TFLint is not installed. Skipping tflint checks.")
    else:
        print("Running tflint...")
        success &= run_command(["tflint", "--init"], cwd=project_root)
        success &= run_command(["tflint", "--recursive"], cwd=project_root)

    return success


def run_shell_linters(project_root: Path) -> bool:
    """Run shell script linters if shellcheck is installed.

    Args:
        project_root: Path to the project root directory

    Returns:
        True if all linters succeeded or were skipped, False otherwise
    """
    success = True

    # Skip if shellcheck is not installed
    if not which("shellcheck"):
        print("ShellCheck is not installed. Skipping shell script lint checks.")
        return success

    print("Running ShellCheck on shell scripts...")
    # Find all .sh files in the project
    shell_scripts = list(project_root.glob("**/*.sh"))
    if not shell_scripts:
        return success

    ignored_dirs = [".git", "node_modules", ".terraform"]

    for script in shell_scripts:
        # Skip files in ignored directories
        if any(ignore_dir in str(script) for ignore_dir in ignored_dirs):
            continue

        print(f"Checking {script.relative_to(project_root)}...")
        # Run shellcheck with -x to follow external sources
        success &= run_command(["shellcheck", "-x", str(script)], cwd=project_root)

        # Auto-fix shell scripts if the shellcheck-fix command is available
        if which("shellcheck-fix"):
            print(f"Auto-fixing {script.relative_to(project_root)}...")
            run_command(["shellcheck-fix", str(script)], cwd=project_root)
        elif which("shfmt"):
            # As an alternative, format the shell scripts with shfmt
            print(f"Formatting {script.relative_to(project_root)} with shfmt...")
            run_command(
                ["shfmt", "-w", "-i", "2", "-ci", str(script)],
                cwd=project_root,
            )

    return success


def main() -> int:
    """Run all linters and formatters.

    Returns:
        0 if all linters succeeded, 1 otherwise
    """
    # Get the project root directory
    backend_dir = Path(__file__).parent.parent
    project_root = backend_dir.parent

    # Define all linter functions to run
    linters: list[Callable[[Path], bool]] = [
        lambda _: run_python_linters(backend_dir),
        lambda root: run_frontend_formatters(root),
        lambda root: run_terraform_linters(root),
        lambda root: run_shell_linters(root),
    ]

    # Run all linters
    success = True
    for linter in linters:
        success &= linter(project_root)

    if success:
        print("All linters completed successfully!")
        return 0
    else:
        print("One or more linters failed. Please fix the issues manually.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
