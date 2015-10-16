USER		:= "djrut"
REPO		:= "trinity"
BUILDDIR	:= "Docker"
VERSION		:= $(shell git describe --tags)
IMAGE		:= $(USER)/$(REPO):$(VERSION)

.PHONY: all prep build push commit clean

all:	| prep build push commit clean

prep:
	@echo "+\n++\n+++ Building Git archive..."
	@git archive -o $(BUILDDIR)/$(REPO).tar HEAD

build:
	@echo "+\n++\n+++ Performing build of Docker image..."
	@docker build -t $(IMAGE) --force-rm --rm $(BUILDDIR)

push:
	@echo "+\n++\n+++ Pushing image to Dockerhub..."
	@docker push $(IMAGE)

commit:
	@echo "+\n++\n+++ Committing updated Dockerrun.aws.json..."
	@Docker/build_dockerrun.sh > Dockerrun.aws.json
	@git add Dockerrun.aws.json
	@git commit --amend --no-edit

clean:
	@echo "+\n++\n+++ Cleaning-up... "
	@rm -v $(BUILDDIR)/$(REPO).tar
