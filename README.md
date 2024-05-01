# Dockerfile you need: ubuntu-jam-runner.Dockerfile

## ⚠️⚠️ Caution this requires privilege access to run ⚠️⚠️

## BUILD it RUN it


```
docker build -t docker-image:tag -f ubuntu-jam-runner.Dockerfile .

docker run --privileged -it -e GITHUB_PERSONAL_TOKEN="<github-personal-access-token>" -e GITHUB_OWNER="<organization-owner>" -e RUNNER_NAME="runner-name" docker-image:tag

```

## change `runs-on` in workflow

```yaml
runs-on: self-hosted 

# or

runs-on: runner-name 
```