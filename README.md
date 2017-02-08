# gitlab-ci-runner-marathon

A customized Docker image for running scalable GitLab CI runners on DC/OS or vanilla Mesos via Marathon.

## Configuration

The GitLab runner can be configured by environment variables. For a complete overview, have a look at the [docs/gitlab_runner_register_arguments.md](docs/gitlab_runner_register_arguments.md) file.

The most important ones are:

* `GITLAB_SERVICE_NAME`: The Mesos DNS service name, e.g. `gitlab.marathon.mesos`. This strongly depends on your setup, i.e. how you launched GitLab and how you configured Mesos DNS. **(mandatory)**
* `REGISTRATION_TOKEN`: The registration token tu use with the GitLab instance. See the [docs](https://docs.gitlab.com/ce/ci/runners/README.html) for details. **(mandatory)**
* `RUNNER_EXECUTOR`: The type of the executor to use, e.g. `shell` or `docker`. See the [executor docs](https://github.com/ayufan/gitlab-ci-multi-runner/blob/master/docs/executors/README.md) for more details. **(mandatory)**
* `RUNNER_CONCURRENT_BUILDS`: The number of concurrent builds this runner should be able to handel. Default is `1`.
* `RUNNER_TAG_LIST`: If you want to use tags in you `.gitlab-ci.yml`, then you need to specify the comma-separated list of tags. This is useful to distinguish the runner types.

## Run on DC/OS (or vanilla Mesos)

This project currently comes in two flavors, split in branches:

* `master`: The [master branch](https://github.com/Azulinho/gitlab-ci-runner-marathon) is not using Docker-in-Docker techniques for the CI runners
* `dind`: The [dind branch](https://github.com/Azulinho/gitlab-ci-runner-marathon/tree/dind) provides a Docker-in-Docker solution for the CI runners 

See [jpetazzo's article](http://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/) for the pros and cons regarding Docker-in-Docker.

When not using DinD, mounting the `docker.socket` and the `docker` binary in the GitLab CI runner container from the host is necessary. It's possible that you have to mount other files as well, depending on your environment. See below for an example.

In the following examples, we assume that you're running the GitLab Universe package as service `gitlab` on DC/OS internal Marathon instance, which is also available to the runners via the `external_url` of the GitLab configuration. This normally means that GitLab is exposed on a public agent node via marathon-lb. 

Have a look below for a GitLab CE sample configuration.

### Shell runner

An example for a shell runner on DC/OS 1.8, where you need to map the Docker binary and socket, as well as other libs to the GitLab runner container. This enables the build of Docker images.

```javascript
{
  "id": "gitlab-runner-shell",
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "Azulinho/gitlab-ci-runner-marathon:latest",
      "network": "HOST",
      "forcePullImage": true
    },
    "volumes": [
      {
        "containerPath": "/var/run/docker.sock",
        "hostPath": "/var/run/docker.sock",
        "mode": "RW"
      }
    ]
  },
  "instances": 1,
  "cpus": 1,
  "mem": 2048,
  "env": {
    "GITLAB_SERVICE_NAME": "gitlab.marathon.mesos",
    "REGISTRATION_TOKEN": "zzNWmRE--SBfeMfiKCMh",
    "RUNNER_EXECUTOR": "shell",
    "RUNNER_TAG_LIST": "shell,build-as-docker",
    "RUNNER_CONCURRENT_BUILDS": "4"
  }
}
``` 

### Docker runner

Here's an example for a Docker runner, which enables builds *inside* Docker containers:

```javascript
{
  "id": "gitlab-runner-docker",
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "Azulinho/gitlab-ci-runner-marathon:latest",
      "network": "HOST",
      "forcePullImage": true
    },
    "volumes": [
      {
        "containerPath": "/var/run/docker.sock",
        "hostPath": "/var/run/docker.sock",
        "mode": "RW"
      }
    ]
  },
  "instances": 1,
  "cpus": 1,
  "mem": 2048,
  "env": {
    "GITLAB_SERVICE_NAME": "gitlab.marathon.mesos",
    "REGISTRATION_TOKEN": "zzNWmRE--SBfeMfiKCMh",
    "RUNNER_EXECUTOR": "docker",
    "RUNNER_TAG_LIST": "docker,build-in-docker",
    "RUNNER_CONCURRENT_BUILDS": "4",
    "DOCKER_IMAGE": "node:6-wheezy"
  }
}
```

Make sure you choose a useful default Docker image via `DOCKER_IMAGE`, for example if you want to build Node.js projects, the `node:6-wheezy` image. This can be overwritten with the `image` property in the `.gitlab-ci.yml` file (see the [GitLab CI docs](https://docs.gitlab.com/ce/ci/yaml/README.html).

## Usage in GitLab CI

### Builds as Docker

An `.gitlab-ci.yml` example of using the `build-as-docker` tag to trigger a build on the runner(s) with shell executors:

```yaml
stages:
  - ci

build-job:
  stage: ci
  tags:
    - build-as-docker
  script:
    - docker build -t Azulinho/test .
```

This assumes your project has a `Dockerfile`, for example

```
FROM nginx
```

### Builds in Docker

An `.gitlab-ci.yml` example of using the `build-in-docker` tag to trigger a build on the runner(s) with Docker executors:

```yaml
image: node:6-wheezy

stages:
  - ci

test-job:
  stage: ci
  tags:
    - build-in-docker
  script:
    - node --version
```
