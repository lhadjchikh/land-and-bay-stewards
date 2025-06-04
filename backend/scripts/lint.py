import os
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

    backend_dir = project_root / "backend"

    print("Running black...")
    success &= run_command(["poetry", "run", "black", "."], cwd=backend_dir)

    print("Running ruff...")
    # Run ruff with --fix to auto-fix issues
    success &= run_command(
        ["poetry", "run", "ruff", "check", "--fix", "."],
        cwd=backend_dir,
    )

    return success


def run_prettier(project_root: Path) -> bool:
    """Run prettier on all supported file types in the project directory.

    Args:
        project_root: Path to the project root directory

    Returns:
        True if all formatters succeeded or were skipped, False otherwise
    """
    success = True

    # Skip if the project_root doesn't exist
    if not project_root.exists():
        return success

    frontend_dir = project_root / "frontend"
    if not frontend_dir.exists():
        print("Frontend directory not found. Skipping frontend formatting.")
        return success

    # Check if package.json exists and verify npm scripts
    package_json = frontend_dir / "package.json"
    if not package_json.exists():
        print(
            "No package.json found in frontend directory. "
            "Skipping frontend formatting.",
        )
        return success

    print("Running Prettier formatting...")

    try:
        # First, try to run the format:all script which is defined in package.json
        print("Running format:all script...")
        format_result = run_command(
            ["npm", "--prefix", "frontend", "run", "format:all"],
            cwd=project_root,
        )

        if not format_result:
            print("Format:all script failed, trying alternative approaches...")
            success = False

            # Try YAML formatting as a fallback
            print("Trying YAML formatting...")
            yaml_result = run_command(
                ["npm", "--prefix", "frontend", "run", "yaml:format"],
                cwd=project_root,
            )

            # Try the basic format command for frontend files
            print("Trying basic format command...")
            basic_result = run_command(
                ["npm", "--prefix", "frontend", "run", "format"],
                cwd=project_root,
            )

            # If any of the fallback methods succeed, consider it a partial success
            if yaml_result or basic_result:
                print("Some formatting completed, but format:all failed.")
                # Still mark as failure since format:all should work
                success = False
            else:
                print("All formatting attempts failed.")
                success = False
        else:
            print("Format:all script completed successfully.")
    except Exception as e:
        print(f"Error running Prettier: {e}")
        success = False

    return success


def run_terraform_linters(project_root: Path) -> bool:
    """Run Terraform linters if terraform is installed.

    Args:
        project_root: Path to the project root directory

    Returns:
        True if all linters succeeded or were skipped, False otherwise
    """
    success = True

    terraform_dir = project_root / "terraform"

    # Skip if terraform is not installed
    if not which("terraform"):
        print("Terraform is not installed. Skipping terraform lint checks.")
        return success

    # Run terraform fmt with -write=true to auto-fix formatting
    print("Running terraform fmt...")
    success &= run_command(
        ["terraform", "fmt", "-write=true", "-recursive"],
        cwd=terraform_dir,
    )

    # Check for tflint binary
    if not which("tflint"):
        print("TFLint is not installed. Skipping tflint checks.")
    else:
        print("Running tflint...")
        try:
            # Check for GitHub token to avoid rate limiting
            if "GITHUB_TOKEN" not in os.environ:
                print(
                    "Warning: GITHUB_TOKEN not found in environment. "
                    "TFLint plugin initialization may fail due to GitHub API "
                    "rate limits.",
                )
                # Use --no-plugins if we don't have a token
                # to avoid API rate limit errors
                init_args = ["tflint", "--no-plugins"]
            else:
                init_args = ["tflint", "--init"]

            # Try to initialize TFLint (with or without plugins)
            init_result = run_command(init_args, cwd=terraform_dir)

            # Run TFLint recursively if initialization succeeded
            if init_result:
                success &= run_command(["tflint", "--recursive"], cwd=terraform_dir)
            else:
                print("Skipping recursive TFLint check due to initialization failure")
                success = False
        except Exception as e:
            print(f"Error running TFLint: {e}")
            success = False

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
    project_root = Path(__file__).parent.parent.parent

    # Define all linter functions to run
    linters: list[Callable[[Path], bool]] = [
        lambda root: run_python_linters(root),
        lambda root: run_prettier(root),
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
