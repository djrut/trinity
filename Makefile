USER		:= "djrut"
REPO		:= "trinity"
BUILDDIR	:= "Docker"
VERSION		:= "$(shell git rev-parse --abbrev-ref HEAD)"
IMAGE		:= "$(USER)/$(REPO):$(VERSION)"

.PHONY: all prep build push commit clean

all:	| prep build push commit clean

prep:
	@echo "+\n++ Building Git archive of HEAD at $(BUILDDIR)/$(REPO).tar...\n+"
	@git archive -o $(BUILDDIR)/$(REPO).tar HEAD

build:
	@echo "+\n++ Performing build of Docker image $(IMAGE)...\n+"
	@docker build -t $(IMAGE) --force-rm --rm $(BUILDDIR)

push:
	@echo "+\n++ Pushing image $(IMAGE) to Dockerhub...\n+"
	@docker push $(IMAGE)

commit:
	@echo "+\n++ Building and Committing Dockerrun.aws.json...\n+"
	@Docker/build_dockerrun.sh > Dockerrun.aws.json
	@git add Dockerrun.aws.json
	@git commit --amend --no-edit

clean:
	@echo "+\n++ Cleaning-up...\n+"
	@rm -v $(BUILDDIR)/$(REPO).tar
