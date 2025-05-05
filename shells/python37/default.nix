{ pkgs, python37 }:
pkgs.mkShell {
  buildInputs = [
    python37
    pkgs.glibcLocales # Add this for locale support
  ];
  
  shellHook = ''
    echo "🐍 Python 3.7 Environment"
    echo "----------------------------------------"
    python --version
    echo "----------------------------------------"
    
    # Export PATH to ensure Python 3.7 is first
    export PATH=${python37}/bin:$PATH
    
    # Fix locale issues
    export LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    
    echo "Python 3.7 is ready!"
    echo "Run 'python' to start the interpreter"
  '';
}
