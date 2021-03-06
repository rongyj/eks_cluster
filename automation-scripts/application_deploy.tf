## Node JS Application

## Deployment Resource for App Pods

resource "kubernetes_deployment" "app_deployment" {
        depends_on = [
                aws_eks_node_group.eks_node_group,
                aws_eks_node_group.eks_node_group_2,
                kubernetes_persistent_volume_claim.app_pvc,
                kubernetes_secret.mongo_secret,
                kubernetes_service.monogo_service,
        ]
        metadata {
                name = "app-deploy"
                labels = {
                        app = "nodejs"
                }
        }
        spec{
                selector {
                        match_labels = {
                                app = "nodejs"
                                tier = "frontend"
                        }
                }
                strategy {
                        type = "Recreate"
                }
                template {
                        metadata {
                                name = "app-pod"
                                labels = {
                                        app = "nodejs"
                                        tier = "frontend"
                                }
                        }
                        spec {
                                container {
                                        name = "app-container"
                                        image = var.app_image_name
                                        port {
                                                name= "app-port"
                                                container_port = var.app_container_port
                                        }
                                        env {
                                                name  = "DATABASE_USER"
                                                value_from {
                                                        secret_key_ref {
                                                                name = kubernetes_secret.mongo_secret.metadata[0].name
                                                                key = "username"
                                                        }
                                                }
                                        }
                                       env {
                                               name  = "DATABASE_PASSWORD"
                                               value_from {
                                                        secret_key_ref {
                                                                name = kubernetes_secret.mongo_secret.metadata[0].name
                                                                key = "password"

                                                        }
                                                }
                                        }
                                       env {
                                                name  = "DATABASE"
                                                value_from {
                                                        secret_key_ref {
                                                                name = kubernetes_secret.mongo_secret.metadata[0].name
                                                                key  = "database"

                                                        }
                                                }
                                        }
                                        env {
                                                name  = "DATABASE_SERVER"
                                                value =  kubernetes_service.monogo_service.metadata[0].name
                                        }
                                        env {
                                                name  = "DATABASE_PORT"
                                                value = var.mongo_db_port
                                        }
                                }
                       }
                }
        }
}



## Kubernetes Service resource for Application server

resource "kubernetes_service" "app_service" {
        metadata {
                name = "app-svc"
                annotations = {
                        #"service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
                        "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
                        "service.beta.kubernetes.io/aws-load-balancer-connection-draining-enabled" = "true"
                        "service.beta.kubernetes.io/aws-load-balancer-connection-draining-timeout" = "60"
                }
        }
        spec{
                selector = {
                        app = kubernetes_deployment.app_deployment.spec[0].template[0].metadata[0].labels.app
                        tier = kubernetes_deployment.app_deployment.spec[0].template[0].metadata[0].labels.tier
                }
                port {
                        port        = var.app_port
                        target_port = var.app_container_port
                }
                type = "LoadBalancer"
        }
}


