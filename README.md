**Infrastructure AWS avec EKS, RDS et GitOps (ArgoCD)**

Ce projet déploie une infrastructure complète, sécurisée et hautement disponible sur Amazon Web Services (AWS) en utilisant Terraform pour l'Infrastructure as Code (IaC) et ArgoCD pour une gestion GitOps des applications et addons Kubernetes.

L'objectif est de fournir une base solide et prête pour la production pour des applications conteneurisées, en mettant l'accent sur la sécurité, l'automatisation, la performance économique et la haute disponibilité.
Architecture

L'infrastructure déployée est structurée comme suit :
- VPC (Virtual Private Cloud) : Un réseau isolé sur 2 zones de disponibilité (AZ) avec : 
    - Des sous-réseaux publics pour les ressources exposées à Internet (Load Balancers, Bastion).
    - Des sous-réseaux privés pour les ressources critiques (Nœuds EKS, Base de données RDS) afin de les protéger de tout accès direct.
    - Un NAT Gateway pour permettre aux ressources privées d'accéder à Internet pour les mises à jour, sans être accessibles depuis l'extérieur.

- EKS (Elastic Kubernetes Service) :
    - Un cluster Kubernetes managé, avec son control plane réparti sur plusieurs AZ.
    - Un groupe de nœuds initial pour les services système.
    - Karpenter pour l'auto-scaling intelligent et économique des nœuds applicatifs, capable de provisionner des instances Spot et Graviton (ARM64) pour réduire les coûts.

- RDS (Relational Database Service) :
    - Une base de données PostgreSQL configurée en mode Multi-AZ avec une instance principale (écriture) et un réplica en lecture dans une autre AZ pour la haute disponibilité et la répartition de charge.
    - La base de données est uniquement accessible depuis les nœuds du cluster EKS via des groupes de sécurité stricts.

- Sécurité & Accès :
    - Un Bastion Host (instance EC2) dans un sous-réseau public sert de point d'entrée SSH sécurisé pour les administrateurs.
    - IRSA (IAM Roles for Service Accounts) est utilisé systématiquement pour donner aux pods des permissions AWS granulaires et sécurisées sans jamais stocker de clés d'accès.

- Automatisation (GitOps) :
    - ArgoCD est le cœur du déploiement continu. Il surveille un dépôt Git et s'assure que l'état du cluster Kubernetes correspond à l'état défini dans le dépôt.
    - Tous les addons (monitoring, certificats, etc.) sont gérés comme des applications ArgoCD.

**Composants & Addons**
Le cluster est pré-configuré avec les addons essentiels suivants, tous déployés via ArgoCD :

- ArgoCD : Pour le déploiement GitOps.
- AWS Load Balancer Controller : Provisionne des Application Load Balancers (ALB) pour les Ingress Kubernetes.
- Karpenter : Auto-scaling des nœuds avancé.
- ExternalDNS : Synchronise les noms de domaine des services/ingress avec AWS Route 53.
- Cert-Manager : Génère et renouvelle automatiquement les certificats TLS/SSL via Let's Encrypt.
- Kube-Prometheus-Stack : Déploie une suite complète de monitoring avec Prometheus et Grafana.

**Prérequis**

Avant de commencer, assurez-vous d'avoir installé les outils suivants sur votre machine locale :

- AWS CLI (configuré avec aws configure)
- Terraform (v1.2.x ou plus)
- kubectl
- Git

**🚀 Guide de Déploiement**
Suivez ces étapes dans l'ordre pour déployer l'infrastructure.

**Étape 1 : Configuration du Projet**

C'est l'étape manuelle la plus importante. Vous devez remplacer toutes les valeurs placeholders dans les fichiers de configuration.

1. Clônez votre dépôt Git si ce n'est pas déjà fait.
2. Ouvrez le projet dans votre éditeur de code.
3. Faites une recherche globale sur le terme REMPLACER_ et remplacez chaque occurrence par la valeur appropriée.

Voici une liste des fichiers et variables clés à modifier :

**Fichier	Variable(s) à modifier et Description**

- terraform/variables.tf	my_ip, bastion_ssh_key_name, domain_name	Votre IP, le nom de votre clé SSH existante sur AWS, et votre nom de domaine.
- terraform/main.tf	Bloc backend "s3"	Décommentez et configurez ce bloc si vous utilisez un backend S3 pour l'état Terraform (recommandé).
- kubernetes/app-of-apps.yaml	repoURL	Crucial : L'URL de VOTRE dépôt Git où ce code est stocké.
- kubernetes/1-core-services/*.yaml	REMPLACER_PAR_NOM_DU_CLUSTER, REMPLACER_PAR_OUTPUT_*_ROLE_ARN, etc.	Ces valeurs seront remplacées par les outputs de Terraform à l'étape 5.
- kubernetes/1-core-services/cluster-issuer.yaml	email	Votre adresse email pour les notifications de Let's Encrypt.
- kubernetes/0-config/secret.yaml	DB_PASSWORD, DB_USER, etc.	Encodez vos secrets en Base64 (`echo -n 'valeur' \

**Étape 2 : Initialisation du Dépôt Git**

Le workflow GitOps repose sur un dépôt Git.
```
git init
git add .
git commit -m "Initial infrastructure setup"
git branch -M main
git remote add origin https://github.com/VOTRE_USER/VOTRE_REPO.git # Remplacez par votre URL
git push -u origin main
```

**Étape 3 : Déploiement de l'Infrastructure AWS avec Terraform**

Cette étape provisionne toutes les ressources sur AWS (VPC, EKS, RDS...).

1. Naviguez dans le dossier Terraform :
```
cd terraform
```

2. Initialisez Terraform :
```
terraform init
```

3. Appliquez la configuration :
Terraform vous demandera de fournir les variables marquées comme sensitive.
```
# Planifiez pour voir ce qui va être créé
terraform plan -var="rds_username=votre_user" -var="rds_password=votre_mot_de_passe_secret"

# Appliquez pour créer les ressources
terraform apply -var="rds_username=votre_user" -var="rds_password=votre_mot_de_passe_secret"
```

4. Sauvegardez les outputs : À la fin de l'exécution, Terraform affichera une liste d'outputs. Copiez-les dans un endroit sûr, vous en aurez besoin à l'étape suivante.

**Étape 4 : Mise à Jour des Fichiers Kubernetes**

Maintenant que l'infrastructure existe, nous devons utiliser ses informations (comme les ARNs des rôles IAM) pour configurer les addons Kubernetes.

    Retournez à la racine du projet.

    Ouvrez les fichiers dans kubernetes/1-core-services/ et remplacez les placeholders avec les outputs de Terraform correspondants.
        REMPLACER_PAR_NOM_DU_CLUSTER -> eks_cluster_name
        REMPLACER_PAR_OUTPUT_LBC_ROLE_ARN -> aws_lbc_iam_role_arn
        REMPLACER_PAR_OUTPUT_KARPENTER_ROLE_ARN -> karpenter_iam_role_arn
        ... et ainsi de suite pour tous les autres.

    Faites de même pour kubernetes/0-config/ (endpoints RDS, etc.).

    Commitez et poussez ces changements : C'est essentiel pour qu'ArgoCD puisse les lire.
    Bash

    git add .
    git commit -m "Configure addons with Terraform outputs"
    git push

Étape 5 : Bootstrap d'ArgoCD

Cette étape unique installe ArgoCD sur votre cluster.

    Configurez kubectl pour qu'il pointe vers votre nouveau cluster EKS :
    Bash

# Utilisez l'output 'configure_kubectl' de Terraform
aws eks --region eu-west-3 update-kubeconfig --name my-prod-app # Adaptez si nécessaire

Installez ArgoCD :
Bash

    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Étape 6 : Déploiement de l' "App of Apps"

C'est ici que la magie opère. Vous allez dire à ArgoCD de surveiller votre dépôt Git.
Bash

# Appliquez le fichier qui déploie tous les autres
kubectl apply -f kubernetes/app-of-apps.yaml

ArgoCD va maintenant détecter cette application, clôner votre dépôt, et commencer à déployer tous les addons définis dans le dossier kubernetes/1-core-services.
Utilisation et Vérification
Accéder à l'UI d'ArgoCD

    Obtenez le mot de passe initial :
    Bash

argocd admin initial-password -n argocd

Accédez à l'interface via port-forward :
Bash

    kubectl port-forward svc/argocd-server -n argocd 8080:443

    Ouvrez votre navigateur et allez sur https://localhost:8080. Connectez-vous avec l'utilisateur admin et le mot de passe obtenu.

Vérifier le statut

Depuis l'UI ou la ligne de commande, vous pouvez voir le statut de synchronisation de vos applications.
Bash

# Devrait montrer tous les addons avec un statut Synced et Healthy
kubectl get applications -n argocd

Déployer une application

Pour déployer votre propre application (ex: api-app), créez les fichiers deployment.yaml, service.yaml, et ingress.yaml dans le dossier kubernetes/2-applications/api-app. Ensuite, créez une nouvelle Application ArgoCD qui pointe vers ce dossier.
Détruire l'Infrastructure

Pour détruire toutes les ressources et éviter les coûts, suivez ces étapes :

    Supprimez l'application "App of Apps" :
    Bash

kubectl delete -f kubernetes/app-of-apps.yaml

(Ceci, grâce aux finalizers, demandera à ArgoCD de supprimer tous les addons et leurs ressources associées, comme les Load Balancers).

Détruisez les ressources AWS :
Bash

cd terraform
terraform destroy -var="rds_username=votre_user" -var="rds_password=votre_mot_de_passe_secret"

Nettoyage manuel (si nécessaire) :

    Supprimez le bucket S3 et la table DynamoDB utilisés pour le backend Terraform si vous les aviez créés.