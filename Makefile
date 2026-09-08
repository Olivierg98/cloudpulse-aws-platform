.PHONY: test run validate fmt smoke destroy
test:
	pytest -q
run:
	docker compose up --build
validate:
	terraform -chdir=infra/environments/dev init -backend=false
	terraform -chdir=infra/environments/dev validate
fmt:
	terraform fmt -recursive infra
smoke:
	./scripts/smoke-test.sh
destroy:
	terraform -chdir=infra/environments/dev destroy
