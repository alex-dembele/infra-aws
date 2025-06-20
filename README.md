🔥 Prochaines étapes critiques : 🔥

1.  Allez dans le dossier du projet :
    cd mon-infra-aws

2.  INITIALISEZ UN DÉPÔT GIT et poussez le code vers GitHub/GitLab :
    git init
    git add .
    git commit -m 'Initial infrastructure setup'
    git branch -M main
    git remote add origin https://github.com/VOTRE_USER/VOTRE_REPO.git
    git push -u origin main

3.  MODIFIEZ LES FICHIERS DE CONFIGURATION AVEC VOS VALEURS :
    - Remplissez tous les 'REMPLACER_PAR_...' dans TOUS les fichiers .tf et .yaml.
    - C'est une étape cruciale, utilisez la fonction de recherche de votre éditeur.

4.  Provisionnez l'infrastructure AWS avec Terraform :
    cd terraform
    terraform init
    terraform apply -var='rds_username=...' -var='rds_password=...'
    - Notez bien tous les outputs à la fin.

5.  Mettez à jour les fichiers YAML avec les outputs de Terraform :
    - Ex: Remplissez les ARN des rôles IAM, le nom du cluster, etc. dans les fichiers de 'kubernetes/1-core-services'.
    - Commitez et poussez ces changements dans votre dépôt Git.

6.  Installez ArgoCD sur votre cluster :
    - ╷
│ Warning: No outputs found
│ 
│ The state file either has no outputs defined, or all the defined outputs are empty. Please define an
│ output in your configuration with the `output` keyword and run `terraform refresh` for it to become
│ available. If you are using interpolation, please verify the interpolated value is not empty. You can
│ use the `terraform console` command to assist.
╵
    - kubectl create namespace argocd
    - kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

7.  Déployez le pattern 'App of Apps' :
    - Assurez-vous que 'kubernetes/app-of-apps.yaml' pointe vers VOTRE dépôt Git.
    - kubectl apply -f ../kubernetes/app-of-apps.yaml

8.  Connectez-vous à l'UI d'ArgoCD pour voir la magie opérer !
    - argo cd admin initial-password -n argocd
    - kubectl port-forward svc/argocd-server -n argocd 8080:443
    - Accédez à https://localhost:8080

