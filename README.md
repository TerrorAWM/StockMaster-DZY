# StockMaster

StockMaster is a cloud-native warehouse inventory system for the course lab.

Architecture:

- Vue 3 admin console served by Nginx
- Spring Cloud Gateway as the API entry
- Eureka service registry
- Spring Cloud Config backed by a Git config repository
- User, product, order, and stock microservices
- MySQL deployed in Kubernetes
- Kubernetes manifests for VM-based deployment

Default admin account:

- Username: `admin`
- Password: `admin123`

