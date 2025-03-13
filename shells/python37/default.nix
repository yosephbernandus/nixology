{ pkgs, python37 }:
pkgs.mkShell {
  buildInputs = [
    python37
  ];
  
  shellHook = ''
    echo "🐍 Python 3.7 Environment"
    echo "----------------------------------------"
    python --version
    echo "----------------------------------------"
    
    # Export PATH to ensure Python 3.7 is first
    export PATH=${python37}/bin:$PATH
    
    echo "Python 3.7 is ready!"
    echo "Run 'python' to start the interpreter"
  '';
}
