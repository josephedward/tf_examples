# Devops assessment
The supplied zip file (https://drive.google.com/file/d/1ckHBsEWSrF7sTZglkmNh6VlOT-HnmwCu/view?usp=sharing) contains an older version of the architecture for our development environment, configured in Terraform. The following questions will take you through several scenarios involving this application. They will test your ability to provide structure and best practices to high-level system requirements.

- **Review the architecture as laid out in Terraform. Provide a visual or written explanation of the current architecture as it relates to the health, auth, hacker, and linter services.**

```
aws s3api create-bucket --bucket test-bucket-hackedu
```


- **We want to move this architecture into EKS. Provide YAML config files for running the health, auth, hacker, and linter services in K8s.**


- **Other than moving to Kubernetes, what would you change in this configuration, given 1 week to work on it? What about 1 month? 6 months?**


- **For local development, we need the engineer to run Postgres locally. Show how you would provide an alternative K8s configuration for local development.**


- **Each of the APIs has a /health endpoint that simply returns 200. How would you suggest that these endpoints be modified in order to provide better availability reporting?**


- **The sales team has informed engineering that there are 5 large deals in progress that would roughly double the number of registered users in the system. The CEO doesn't want to simply double the processing power of the system right now, as it's too expensive. Provide a plan for monitoring system resources and providing more capacity when needed.**

 Prometheus Operator 
 Grafana 
 Argo CD
 Kuberhealthy? 