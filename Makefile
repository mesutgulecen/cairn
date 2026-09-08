.PHONY: verify sanitize help

help:
	@echo "verify    run every guard against its calibration fixtures"
	@echo "sanitize  scan the repository for leaked deployment identifiers"

verify:
	@./scripts/verify.sh

sanitize:
	@./scripts/sanitize-check.sh
