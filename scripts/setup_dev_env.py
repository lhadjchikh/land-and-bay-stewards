#!/usr/bin/env python3
"""
Development Environment Setup Script

This script helps developers set up their environment to pass all linting checks.
It addresses common issues with Python versions, Go installation, and tool dependencies
across different operating systems.

Usage:
    python scripts/setup_dev_env.py [--os {macos,linux,windows}]
    
If --os is not specified, the script will attempt to auto-detect the OS.
"""

import argparse
import platform
import shutil
import subprocess
import sys
from pathlib import Path


def print_section(title: str) -> None:
    """Print a formatted section header."""
    print(f"\n{'='*60}")
    print(f" {title}")
    print(f"{'='*60}")


def print_step(step: str) -> None:
    """Print a formatted step indicator."""
    print(f"\n🔧 {step}")
    print("-" * 50)


def run_command(cmd: list[str], cwd: str | Path | None = None, check: bool = True) -> bool:
    """Run a command and return success status."""
    print(f"   └─ {' '.join(cmd)}")
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            check=check,
            text=True,
            capture_output=True,
        )
        if result.stdout:
            print(f"      {result.stdout.strip()}")
        print("   ✅ Success")
        return True
    except subprocess.CalledProcessError as e:
        print(f"   ❌ Error: {e}")
        if e.stdout:
            print(f"      {e.stdout.strip()}")
        if e.stderr:
            print(f"      {e.stderr.strip()}")
        return False


def check_tool(tool: str) -> bool:
    """Check if a tool is available."""
    return shutil.which(tool) is not None


def detect_os() -> str:
    """Auto-detect the operating system."""
    system = platform.system().lower()
    if system == "darwin":
        return "macos"
    elif system == "linux":
        return "linux"
    elif system == "windows":
        return "windows"
    else:
        print(f"⚠️  Unknown OS: {system}. Defaulting to linux.")
        return "linux"


def get_install_instructions(os_type: str) -> dict:
    """Get installation instructions for different operating systems."""
    instructions = {
        "macos": {
            "python3.13": "brew install python@3.13",
            "go": "brew install go",
            "terraform": "brew install terraform",
            "tflint": "brew install tflint",
            "shellcheck": "brew install shellcheck",
            "shfmt": "brew install shfmt",
            "npm": "brew install node",
            "package_manager": "brew",
            "package_manager_install": "Install Homebrew from https://brew.sh/",
        },
        "linux": {
            "python3.13": "sudo apt update && sudo apt install python3.13 python3.13-venv python3.13-dev",
            "go": "sudo apt install golang-go  # or download from https://golang.org/",
            "terraform": "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && sudo apt install terraform",
            "tflint": "curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash",
            "shellcheck": "sudo apt install shellcheck",
            "shfmt": "sudo apt install shfmt  # or go install mvdan.cc/sh/v3/cmd/shfmt@latest",
            "npm": "sudo apt install nodejs npm",
            "package_manager": "apt",
            "package_manager_install": "apt should be available by default on Ubuntu/Debian",
        },
        "windows": {
            "python3.13": "winget install Python.Python.3.13  # or choco install python",
            "go": "winget install GoLang.Go  # or choco install golang",
            "terraform": "winget install Hashicorp.Terraform  # or choco install terraform",
            "tflint": "winget install terraform-linters.tflint  # or choco install tflint",
            "shellcheck": "winget install koalaman.shellcheck  # or choco install shellcheck",
            "shfmt": "go install mvdan.cc/sh/v3/cmd/shfmt@latest",
            "npm": "winget install OpenJS.NodeJS  # or choco install nodejs",
            "package_manager": "winget",
            "package_manager_install": "winget should be available on Windows 10+ by default",
        }
    }
    return instructions.get(os_type, instructions["linux"])


def setup_python(os_type: str, instructions: dict) -> bool:
    """Set up Python 3.13."""
    print_section("PYTHON SETUP")
    success = True
    
    # Check for Python 3.13
    python_cmd = "python3.13" if os_type != "windows" else "python"
    
    if not check_tool(python_cmd):
        print_step(f"Installing Python 3.13 for {os_type}")
        print(f"   Please run: {instructions['python3.13']}")
        if os_type == "windows":
            print("   Note: On Windows, you may also need to add Python to your PATH")
        success = False
    else:
        print("✅ Python 3.13 is already installed")
    
    # Configure Poetry if available
    if check_tool("poetry"):
        print_step("Configuring Poetry to use Python 3.13")
        project_root = Path(__file__).parent.parent
        backend_dir = project_root / "backend"
        
        # Try different Python commands based on OS
        python_versions = ["python3.13", "python3", "python"] if os_type != "windows" else ["python"]
        
        for py_cmd in python_versions:
            if check_tool(py_cmd):
                success &= run_command(["poetry", "env", "use", py_cmd], cwd=backend_dir)
                success &= run_command(["poetry", "install"], cwd=backend_dir)
                break
    else:
        print("⚠️  Poetry not found. Please install Poetry first: https://python-poetry.org/docs/#installation")
        success = False
    
    return success


def setup_go(os_type: str, instructions: dict) -> bool:
    """Set up Go and Go tools."""
    print_section("GO SETUP")
    success = True
    
    if not check_tool("go"):
        print_step(f"Installing Go for {os_type}")
        print(f"   Please run: {instructions['go']}")
        success = False
    else:
        print("✅ Go is already installed")
        result = subprocess.run(["go", "version"], capture_output=True, text=True)
        print(f"   Current version: {result.stdout.strip()}")
    
    # Set up Go PATH and tools
    if check_tool("go"):
        print_step("Setting up Go PATH")
        try:
            go_path = subprocess.run(["go", "env", "GOPATH"], capture_output=True, text=True).stdout.strip()
            go_bin = f"{go_path}/bin"
            print(f"   Go tools will be installed to: {go_bin}")
            
            # Check if Go bin is already in PATH
            current_path = subprocess.run(["go", "env", "PATH"], capture_output=True, text=True).stdout.strip()
            if go_bin not in current_path:
                print(f"   ⚠️  {go_bin} is not in your PATH")
                if os_type == "windows":
                    print(f"   Add this to your PATH environment variable: {go_bin}")
                    print("   Instructions: https://www.java.com/en/download/help/path.html")
                else:
                    print(f"   Add this to your shell profile: export PATH=$PATH:{go_bin}")
                    print("   Or run temporarily: export PATH=$PATH:$(go env GOPATH)/bin")
            else:
                print(f"   ✅ {go_bin} is already in PATH")
        except Exception as e:
            print(f"   ⚠️  Could not get GOPATH: {e}")
        
        # Install Go linting tools
        print_step("Installing Go linting tools")
        essential_tools = [
            "honnef.co/go/tools/cmd/staticcheck@latest",
            "github.com/golangci/golangci-lint/cmd/golangci-lint@latest", 
            "github.com/gordonklaus/ineffassign@latest",
            "github.com/client9/misspell/cmd/misspell@latest",
        ]
        
        optional_tools = [
            ("github.com/securecodewarrior/gosec/v2/cmd/gosec@latest", "gosec", "Security scanner for Go code"),
        ]
        
        # Install essential tools first
        for tool in essential_tools:
            tool_name = tool.split("/")[-1].split("@")[0]
            print(f"   📦 Installing {tool_name}")
            install_success = run_command(["go", "install", tool])
            success &= install_success
            
            # Verify installation by checking if tool is accessible
            if install_success:
                # Check if tool is in PATH or Go bin directory
                if check_tool(tool_name):
                    print(f"   ✅ {tool_name} is accessible via PATH")
                else:
                    try:
                        go_path = subprocess.run(["go", "env", "GOPATH"], capture_output=True, text=True).stdout.strip()
                        tool_path = Path(go_path) / "bin" / tool_name
                        if tool_path.exists():
                            print(f"   ⚠️  {tool_name} installed but not in PATH: {tool_path}")
                        else:
                            print(f"   ❌ {tool_name} installation may have failed")
                    except Exception:
                        print(f"   ⚠️  Cannot verify {tool_name} installation")
        
        # Install optional tools (don't fail setup if these fail)
        for tool, tool_name, description in optional_tools:
            print(f"   📦 Installing {tool_name} (optional) - {description}")
            install_success = run_command(["go", "install", tool], check=False)
            
            if install_success:
                # Verify installation by checking if tool is accessible
                if check_tool(tool_name):
                    print(f"   ✅ {tool_name} is accessible via PATH")
                else:
                    try:
                        go_path = subprocess.run(["go", "env", "GOPATH"], capture_output=True, text=True).stdout.strip()
                        tool_path = Path(go_path) / "bin" / tool_name
                        if tool_path.exists():
                            print(f"   ⚠️  {tool_name} installed but not in PATH: {tool_path}")
                        else:
                            print(f"   ❌ {tool_name} installation may have failed")
                    except Exception:
                        print(f"   ⚠️  Cannot verify {tool_name} installation")
            else:
                print(f"   ⚠️  {tool_name} installation failed - this is optional and won't affect linting")
                print(f"      You can install {tool_name} manually later if needed")
    
    return success


def setup_other_tools(os_type: str, instructions: dict) -> bool:
    """Set up other required tools."""
    print_section("OTHER TOOLS")
    success = True
    
    tools_to_check = [
        ("terraform", instructions["terraform"]),
        ("tflint", instructions["tflint"]),
        ("shellcheck", instructions["shellcheck"]),
        ("shfmt", instructions["shfmt"]),
        ("npm", instructions["npm"]),
    ]
    
    for tool, install_cmd in tools_to_check:
        if not check_tool(tool):
            print(f"⚠️  {tool} not found. Install with: {install_cmd}")
            success = False
        else:
            print(f"✅ {tool} is available")
    
    return success


def test_setup() -> bool:
    """Test the setup by running the lint script."""
    print_section("TESTING SETUP")
    print_step("Running lint script to test setup")
    
    project_root = Path(__file__).parent.parent
    
    # Try different Python commands
    python_commands = ["python3.13", "python3", "python"]
    
    for py_cmd in python_commands:
        if check_tool(py_cmd):
            lint_result = run_command([py_cmd, "scripts/lint.py"], cwd=project_root, check=False)
            return lint_result
    
    print("   ❌ No suitable Python command found")
    return False


def main() -> int:
    """Set up development environment."""
    parser = argparse.ArgumentParser(description="Set up development environment for linting")
    parser.add_argument(
        "--os",
        choices=["macos", "linux", "windows"],
        help="Target operating system (auto-detected if not specified)"
    )
    
    args = parser.parse_args()
    
    # Determine OS
    if args.os:
        os_type = args.os
        print(f"🖥️  Using specified OS: {os_type}")
    else:
        os_type = detect_os()
        print(f"🖥️  Auto-detected OS: {os_type}")
    
    instructions = get_install_instructions(os_type)
    
    print_section("DEVELOPMENT ENVIRONMENT SETUP")
    print(f"📁 Project root: {Path(__file__).parent.parent}")
    print(f"🖥️  Target OS: {os_type}")
    
    # Check package manager
    if not check_tool(instructions["package_manager"]):
        print(f"\n⚠️  Package manager '{instructions['package_manager']}' not found.")
        print(f"   {instructions['package_manager_install']}")
        print("   Please install the package manager first, then re-run this script.")
        return 1
    
    # Set up components
    python_success = setup_python(os_type, instructions)
    go_success = setup_go(os_type, instructions)
    tools_success = setup_other_tools(os_type, instructions)
    
    # Test setup
    test_success = test_setup()
    
    # Print final instructions
    print_section("FINAL STEPS")
    
    if os_type == "windows":
        print("On Windows, make sure to:")
        print("1. Add Python to your PATH")
        print("2. Add Go tools to your PATH")
        print("3. Restart your terminal/IDE")
    else:
        try:
            go_path = subprocess.run(["go", "env", "GOPATH"], capture_output=True, text=True).stdout.strip()
            go_bin = f"{go_path}/bin"
            
            # Check if PATH update is needed
            current_path = subprocess.run(["go", "env", "PATH"], capture_output=True, text=True).stdout.strip()
            if go_bin not in current_path:
                print("⚠️  Go tools directory is not in your PATH!")
                print("Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):")
                print(f"   export PATH=$PATH:{go_bin}")
                print("\nThen reload your shell or run:")
                print("   source ~/.zshrc  # or ~/.bashrc")
                print("\nAlternatively, run this temporarily for the current session:")
                print(f"   export PATH=$PATH:$(go env GOPATH)/bin")
                
                # Check if specific tools are accessible
                essential_tools_check = ["golangci-lint", "staticcheck", "ineffassign", "misspell"]
                optional_tools_check = ["gosec"]
                
                missing_essential = [tool for tool in essential_tools_check if not check_tool(tool)]
                missing_optional = [tool for tool in optional_tools_check if not check_tool(tool)]
                
                if missing_essential:
                    print(f"\n🔍 Essential tools missing from PATH: {', '.join(missing_essential)}")
                    print("   These tools were installed but can't be found via 'which'")
                    print("   Make sure to update your PATH as shown above")
                
                if missing_optional:
                    print(f"\n🔍 Optional tools not available: {', '.join(missing_optional)}")
                    print("   These tools are optional for security scanning")
                    print("   The linting will work fine without them")
            else:
                print("✅ Go tools directory is already in your PATH")
        except:
            print("Please ensure Go tools are in your PATH")
    
    print("\nTo run all linters:")
    print("   python scripts/lint.py")
    print("\nTo verify golangci-lint is working:")
    print("   golangci-lint version")
    print("   # If this fails, check your PATH configuration above")
    
    overall_success = python_success and go_success and tools_success and test_success
    
    if overall_success:
        print("\n🎉 SETUP COMPLETED SUCCESSFULLY!")
        print("All linting tools should now work correctly.")
        return 0
    else:
        print("\n⚠️  SETUP COMPLETED WITH ISSUES")
        print("Some tools may need manual installation. Follow the instructions above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())