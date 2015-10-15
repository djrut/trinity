USER		:= "djrut"
REPO		:= "trinity"
BUILDDIR	:= "Docker"
VERSION		:= $(shell git describe --tags)
IMAGE		:= $(USER)/$(REPO):$(VERSION)

all:	prep dry-run build push commit clean

prep:
	$(info +++ Building Git archive... +++)
	@git archive -o $(BUILDDIR)/$(REPO).tar HEAD

dry-run:
	$(info +++ Performing dry-run build of Docker image... +++)
	@docker build -t $(IMAGE) --force-rm --rm $(BUILDDIR)
	@docker rmi $(IMAGE)

build:
	$(info +++ Performing final build of Docker image... +++)
	@Docker/build_dockerrun.sh > Dockerrun.aws.json
	@docker build -t $(IMAGE) --force-rm --rm $(BUILDDIR)

tag_latest:
	@docker tag $(IMAGE) $(USER)/$(REPO):latest

push:
	$(info +++ Pushing image to Dockerhub... +++)
	@docker push $(IMAGE)

commit:
	$(info +++ Committing updated Dockerrun.aws.json... +++)
	@git add Dockerrun.aws.json
	@git commit --amend --no-edit

clean:
	$(info +++ Clean-up... +++)
	@rm -v $(BUILDDIR)/$(REPO).tar
