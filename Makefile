doc:
	docker run --rm -it -v $(shell pwd):/kube-setup -w /kube-setup/policy --entrypoint /app/gh-md-toc evkalinin/gh-md-toc:0.8.0 --insert --no-backup --hide-footer gatekeeper.md
	docker run --rm -it -v $(shell pwd):/kube-setup -w /kube-setup/kubeadm --entrypoint /app/gh-md-toc evkalinin/gh-md-toc:0.8.0 --insert --no-backup --hide-footer README.md