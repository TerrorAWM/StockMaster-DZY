# StockMaster Config Repository

Spring Cloud Config reads these files by service name.

For Kubernetes, mount or publish this directory as a Git repository and set:

```text
CONFIG_GIT_URI=<your config repo url>
```

