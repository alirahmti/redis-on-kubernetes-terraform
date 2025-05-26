provider "kubernetes" {
  config_path = "/root/.kube/config"
}

resource "kubernetes_namespace" "redis" {
  metadata {
    name = "redis"
  }
}

resource "kubernetes_service" "redis-master" {
  metadata {
    name      = "redis-master"
    namespace = kubernetes_namespace.redis.metadata[0].name
  }

  spec {
    selector = {
      app = "redis"
      role = "master"
    }

    port {
      port        = 6379
      target_port = 6379
    }
  }
}

resource "kubernetes_deployment" "redis-master" {
  metadata {
    name      = "redis-master"
    namespace = kubernetes_namespace.redis.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app  = "redis"
        role = "master"
      }
    }

    template {
      metadata {
        labels = {
          app  = "redis"
          role = "master"
        }
      }

      spec {
        container {
          name  = "redis"
          image = "redis:6.2.6"

          port {
            container_port = 6379
          }

          volume_mount {
            name       = "redis-storage"
            mount_path = "/data"
          }
        }

        volume {
          name = "redis-storage"

          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "redis-slave" {
  metadata {
    name      = "redis-slave"
    namespace = kubernetes_namespace.redis.metadata[0].name
  }

  spec {
    selector = {
      app = "redis"
      role = "slave"
    }

    port {
      port        = 6379
      target_port = 6379
    }
  }
}

resource "kubernetes_deployment" "redis-slave" {
  metadata {
    name      = "redis-slave"
    namespace = kubernetes_namespace.redis.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app  = "redis"
        role = "slave"
      }
    }

    template {
      metadata {
        labels = {
          app  = "redis"
          role = "slave"
        }
      }

      spec {
        container {
          name  = "redis"
          image = "redis:6.2.6"

          port {
            container_port = 6379
          }

          env {
            name  = "REDIS_REPLICATION_MODE"
            value = "slave"
          }

          env {
            name  = "REDIS_MASTER_HOST"
            value = "redis-master"
          }

          volume_mount {
            name       = "redis-storage"
            mount_path = "/data"
          }
        }

        volume {
          name = "redis-storage"

          empty_dir {}
        }
      }
    }
  }
}

