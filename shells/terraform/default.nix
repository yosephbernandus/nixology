{ pkgs }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    terraform
    google-cloud-sdk
  ];

  shellHook = ''
    echo "🚀 Terraform Development Environment"
    echo "----------------------------------------"
    echo "Terraform $(terraform version | head -n1)"
    echo "Google Cloud SDK $(gcloud version | head -n1)"
    echo "----------------------------------------"

    export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"
    
    terraform_prompt() {
      if [ -d .terraform ]; then
        workspace=$(terraform workspace show 2>/dev/null)
        echo "(tf:$workspace) "
      fi
    }
    export PS1='$(terraform_prompt)'$PS1
  '';
}
