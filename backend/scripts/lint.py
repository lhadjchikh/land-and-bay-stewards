import shutil
import subprocess
import sys
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


def main() -> int:
    """Run all linters and formatters.

    Returns:
        0 if all linters succeeded, 1 otherwise
    """
    # Get the project root directory
    backend_dir = Path(__file__).parent.parent
    project_root = backend_dir.parent

    success = True

    # Run Python linters with auto-fix
    print("Running black...")
    success &= run_command(["poetry", "run", "black", "."], cwd=backend_dir)

    print("Running ruff...")
    # Run ruff with --fix to auto-fix issues
    success &= run_command(
        ["poetry", "run", "ruff", "check", "--fix", "."],
        cwd=backend_dir,
    )

    # Format YAML files using Prettier
    print("Running YAML formatting...")
    if project_root.joinpath("frontend").exists():
        print("Auto-formatting YAML files using Prettier...")
        run_command(
            ["npm", "--prefix", "frontend", "run", "yaml:format"],
            cwd=project_root,
        )

    # Format Markdown files using Prettier
    print("Running Markdown formatting...")
    if project_root.joinpath("frontend").exists():
        print("Formatting Markdown files using Prettier...")
        run_command(
            ["npm", "--prefix", "frontend", "run", "format:all"],
            cwd=project_root,
        )

    # Check for terraform binary using shutil.which
    if not which("terraform"):
        print("Terraform is not installed. Skipping terraform lint checks.")
    else:
        # Run Terraform linters
        terraform_dir = project_root / "terraform"
        if terraform_dir.exists():
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
                success &= run_command(["tflint", "--init"], cwd=terraform_dir)
                success &= run_command(["tflint", "--recursive"], cwd=terraform_dir)

    if success:
        print("All linters completed successfully!")
        return 0
    else:
        print("One or more linters failed. Please fix the issues manually.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
