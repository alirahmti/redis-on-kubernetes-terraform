# 🚀 Deploying Redis Cluster on Kubernetes with Terraform

Welcome to the **Redis Cluster Deployment Guide**! This guide will walk you through deploying a Redis master-slave cluster on Kubernetes using Terraform. By the end of this tutorial, you'll have a fully functional Redis setup running in your Kubernetes cluster. 🎉

---

## 🛠️ Prerequisites

Before you begin, ensure you have the following tools installed and configured:

1. **Terraform** (v1.0 or later)
2. **kubectl** (configured to access your Kubernetes cluster)
3. A Kubernetes cluster (local or cloud-based)
4. Access to the `.kube/config` file for cluster authentication

---

## 📂 Project Structure

Here’s the structure of the Terraform configuration:

```
.
├── main.tf  # Contains the Terraform configuration for Redis deployment
```

---

## 📜 Configuration Details

### 1. **Provider Configuration**
The Kubernetes provider is configured to use the kubeconfig file located at `/root/.kube/config`:

```hcl
provider "kubernetes" {
  config_path = "/root/.kube/config"
}
```

### 2. **Namespace**
A dedicated namespace `redis` is created to isolate Redis resources:

```hcl
resource "kubernetes_namespace" "redis" {
  metadata {
    name = "redis"
  }
}
```

### 3. **Redis Master**
The Redis master deployment and service are defined as follows:

#### Deployment:
```hcl
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
```

#### Service:
```hcl
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
```

### 4. **Redis Slave**
The Redis slave deployment and service are defined as follows:

#### Deployment:
```hcl
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
```

#### Service:
```hcl
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
```

---

## 🚀 Deployment Steps

Follow these steps to deploy the Redis cluster:

1. **Initialize Terraform**:
   Run the following command to initialize Terraform and download the required provider plugins:
   ```bash
   terraform init
   ```

2. **Apply the Configuration**:
   Deploy the resources to your Kubernetes cluster:
   ```bash
   terraform apply
   ```
   Confirm the changes when prompted by typing `yes`.

3. **Verify the Deployment**:
   Use `kubectl` to check the status of the Redis master and slave pods:
   ```bash
   kubectl get pods -n redis
   ```

   You should see one `redis-master` pod and one `redis-slave` pod running.

4. **Access Redis**:
   - Use the `redis-master` service to connect to the master node.
   - Use the `redis-slave` service to connect to the slave node.

---

## 🎉 Congratulations!

You’ve successfully deployed a Redis master-slave cluster on Kubernetes using Terraform! 🚀

Feel free to customize the configuration to suit your needs, such as scaling the number of replicas or adding persistence to the storage volumes.

---

## 📝 Notes

- This setup uses `emptyDir` volumes for storage, which means data will not persist if the pods are restarted. For production use, consider using persistent volumes.
- The Redis image used is `redis:6.2.6`. You can update this to the latest version if needed.

---

Happy coding! 💻✨

## **Author** ✍️

Created by [Ali Rahmati](https://github.com/alirahmti). If you find this repository helpful, feel free to fork it or contribute!
