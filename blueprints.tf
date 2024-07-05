
module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.3"
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_aws_efs_csi_driver           = false
  enable_aws_load_balancer_controller = true
  enable_karpenter                    = true
  providers = {
    helm = helm.karpenter
  }
  karpenter_enable_spot_termination = true
  enable_metrics_server             = true
  enable_kube_prometheus_stack      = true
  kube_prometheus_stack = {
    name             = "kube-prometheus-stack"
    description      = "A Helm chart to install the Kube Prometheus Stack"
    namespace        = "kube-prometheus-stack"
    create_namespace = true
    chart            = "kube-prometheus-stack"
    repository       = "https://prometheus-community.github.io/helm-charts"
    values        = [
      <<-EOT
        grafana:
          enabled: true
          adminPassword: ${random_password.grafana_password.result}
          additionalDataSources:
            - name: CloudWatch
              type: cloudwatch
              jsonData:
                authType: default
                assumeRoleArn: ${aws_iam_role.grafana_role.arn}
                defaultRegion: ${data.aws_region.current.name}
          ingress:
            ingressClassName: "alb"
            enabled: true
            annotations:
              alb.ingress.kubernetes.io/scheme: internet-facing
              alb.ingress.kubernetes.io/certificate-arn: ${aws_acm_certificate.this.arn}
              alb.ingress.kubernetes.io/group.name: monitoring-albs-group
              alb.ingress.kubernetes.io/load-balancer-name: monitoring-stack-alb
              alb.ingress.kubernetes.io/target-type: ip
              alb.ingress.kubernetes.io/healthcheck-port: traffic-port
              alb.ingress.kubernetes.io/healthcheck-path: /login
              alb.ingress.kubernetes.io/backend-protocol: HTTP
              alb.ingress.kubernetes.io/ssl-redirect: '443'
              alb.ingress.kubernetes.io/listen-ports:  '[{"HTTP": 80}, {"HTTPS":443}]'
            hosts:
              - ${var.environament}-grafana.${var.cloudflare_zone_name}
            paths:
              - /*

        prometheus:
          prometheusSpec:
            retention: "15d"
          ingress:
            ingressClassName: "alb"
            enabled: true
            annotations:
              alb.ingress.kubernetes.io/scheme: internet-facing
              alb.ingress.kubernetes.io/load-balancer-name: monitoring-stack-alb
              alb.ingress.kubernetes.io/certificate-arn: ${aws_acm_certificate.this.arn}
              alb.ingress.kubernetes.io/group.name: monitoring-albs-group
              alb.ingress.kubernetes.io/target-type: ip
              alb.ingress.kubernetes.io/backend-protocol: HTTP
              alb.ingress.kubernetes.io/listen-ports:  '[{"HTTP": 80}, {"HTTPS":443}]'
              alb.ingress.kubernetes.io/ssl-redirect: '443'
              alb.ingress.kubernetes.io/healthcheck-port: traffic-port
            hosts:
              - ${var.environament}-prometheus.${var.cloudflare_zone_name}
            paths:
              - /*

        alertmanager:
          enable: true
          ingress:
            enabled: true
            ingressClassName: "alb"
            annotations:
              alb.ingress.kubernetes.io/scheme: internet-facing
              alb.ingress.kubernetes.io/load-balancer-name: monitoring-stack-alb
              alb.ingress.kubernetes.io/certificate-arn: ${aws_acm_certificate.this.arn}
              alb.ingress.kubernetes.io/group.name: monitoring-albs-group
              alb.ingress.kubernetes.io/target-type: ip
              alb.ingress.kubernetes.io/healthcheck-port: traffic-port
              alb.ingress.kubernetes.io/backend-protocol: HTTP
              alb.ingress.kubernetes.io/success-codes: '302'
              alb.ingress.kubernetes.io/listen-ports:  '[{"HTTP": 80}, {"HTTPS":443}]'
              alb.ingress.kubernetes.io/ssl-redirect: '443'
            hosts:
              - ${var.environament}-alertmanager.${var.cloudflare_zone_name}

            paths:
              - /*
          config:
            global:
              resolve_timeout: 5m
            inhibit_rules:
              - source_matchers:
                  - 'severity = critical'
                target_matchers:
                  - 'severity =~ warning|info'
                equal:
                  - 'namespace'
                  - 'alertname'
              - source_matchers:
                  - 'severity = warning'
                target_matchers:
                  - 'severity = info'
                equal:
                  - 'namespace'
                  - 'alertname'
              - source_matchers:
                  - 'alertname = InfoInhibitor'
                target_matchers:
                  - 'severity = info'
                equal:
                  - 'namespace'
              - target_matchers:
                  - 'alertname = InfoInhibitor'
            route:
              group_by: ['namespace']
              group_wait: 30s
              group_interval: 5m
              repeat_interval: 12h
              routes:
              - receiver: 'null'
                matchers:
                  - alertname = "Watchdog"
              - receiver: 'discord-default'
                matchers:
                  - namespace = "default"
              - receiver: 'discord-others'
                matchers:
                  - namespace != "default"

            receivers:
              - name: 'null'
              - name: 'discord-default'
                discord_configs:
                - webhook_url: ${jsondecode(data.aws_secretsmanager_secret_version.discord_alerts_secret_version.secret_string)["APPLICATION_ALERT_CHANNEL"]}
              - name: 'discord-others'
                discord_configs:
                - webhook_url: ${jsondecode(data.aws_secretsmanager_secret_version.discord_alerts_secret_version.secret_string)["CLUSTER_ALERT_CHANNEL"]}
      EOT
      ]
  }

  helm_releases = {
    karpenter-resources-default = {
      name        = "karpenter-resources-basic"
      description = "A Helm chart for karpenter CPU based resources basic teir"
      chart       = "${path.module}/helm-charts/karpenter"
      values = [
        <<-EOT
          clusterName: ${module.eks.cluster_name}
          subnetname: ${local.name}
          deviceName: "/dev/xvda"
          instanceName: backend-karpenter-node
          iamRoleName: ${module.eks_blueprints_addons.karpenter.node_iam_role_name}
          instanceFamilies: ["m5"]
          amiFamily: AL2023
          taints: []
          labels: []
        EOT
      ]
    }
    mongodb = {
      count       = var.create_mongodb_release ? 1 : 0
      name        = "mongodb"
      description = "A Helm chart for MongoDB with replicas and LoadBalancer"
      chart       = "bitnami/mongodb"
      version     = "15.6.5"
      create_namespace = true
      namespace = "mongodb"
      values = [
        <<-EOT
          architecture: standalone
          auth:
            rootPassword: "${random_password.mongodb_password.result}"
            rootUser: "root"
            usernames: ["admin"]
            passwords: ["${random_password.mongodb_password.result}"]
            databases: ["backend"]
        EOT
      ]
    }
  }
  tags = local.tags
}