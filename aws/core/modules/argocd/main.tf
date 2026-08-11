resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
    helm = {
      source  = "hashicorp/helm"
    }
  }
}


resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.7.0"

  create_namespace = false

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP" 
        }
      }
      configs = {
        params = {
          "server.insecure" = true
        }
      }
    })
  ]
}

resource "helm_release" "monitoring" {
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "56.21.0"

  timeout          = 600
  create_namespace = false

  values = [
    yamlencode({
      grafana = {
        service = {
          type = "ClusterIP"
        }
      }

      prometheus = {
        service = {
          type = "ClusterIP"
        }
      }

      alertmanager = {
        service = {
          type = "ClusterIP"
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.monitoring
  ]
}

resource "kubernetes_secret" "demo-repo" {
  metadata {
    name      = "demo-repo"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  data = {
    username = "git"
    password = var.github_token
    type     = "git"
    url      = "https://github.com/${var.cd_project_repo}"
  }
  type = "Opaque"

  depends_on = [helm_release.argocd]
}

resource "kubernetes_namespace_v1" "boutique" {
  metadata {
    name = "boutique"
  }
}

resource "helm_release" "argocd-apps" {
  name       = "argocd-apps"
  chart      = "argocd-apps"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  version    = "1.6.1"
  repository = "https://argoproj.github.io/argo-helm"
  timeout    = 300

  set {
    name  = "applications[0].source.repoURL"
    value = "https://github.com/${var.cd_project_repo}"
    type  = "string"
  }

  values = [
    "${file("${path.module}/argo-cd-apps-values.yaml")}"
  ]

  depends_on = [helm_release.argocd, kubernetes_secret.demo-repo]
}
