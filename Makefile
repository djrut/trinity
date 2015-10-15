USER		:= "djrut"
REPO		:= "trinity"
BUILDDIR	:= "Docker"
VERSION		:= $(shell git describe --tags)
IMAGE		:= $(USER)/$(REPO):$(VERSION)

.PHONY: all prep build push commit clean

all:	| prep build push commit clean

prep:
	$(info +++ Building Git archive... +++)
	@git archive -o $(BUILDDIR)/$(REPO).tar HEAD

build:
	$(info +++ Performing build of Docker image... +++)
	@docker build -t $(IMAGE) --force-rm --rm $(BUILDDIR)

push:
	$(info +++ Pushing image to Dockerhub... +++)
	@docker push $(IMAGE)

commit:
	$(info +++ Committing updated Dockerrun.aws.json... +++)
	@Docker/build_dockerrun.sh > Dockerrun.aws.json
	@git add Dockerrun.aws.json
	@git commit --amend --no-edit

clean:
	$(info +++ Clean-up... +++)
	@rm -v $(BUILDDIR)/$(REPO).tar
