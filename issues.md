- current template code only sets namespace labels if also managing the namespace creation
  - can be refactored
- namespace labels not deep merged; instance will override role settings
  - https://github.com/argoproj/argo-cd/issues/12836
  - https://github.com/argoproj/argo-cd/issues/12837

