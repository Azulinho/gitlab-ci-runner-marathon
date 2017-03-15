# vim:filetype=make shiftwidth=4 tabstop=4 noexpandtab

clean:
	docker rmi mokus-gitlab-ci-runner-marathon:$$CI_BUILD_REF || echo

build:
	docker build -t $$DOCKER_REGISTRY_ENDPOINT/mokus-gitlab-ci-runner-marathon:$$CI_BUILD_REF .

publish:
	docker login --username=$$DOCKER_REGISTRY_USERNAME --password=$$DOCKER_REGISTRY_PASSWORD  $$DOCKER_REGISTRY_ENDPOINT
	docker push $$DOCKER_REGISTRY_ENDPOINT/mokus-gitlab-ci-runner-marathon:$$CI_BUILD_REF