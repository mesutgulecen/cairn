.PHONY: verify sanitize links help

help:
	@echo "verify    run every guard against its calibration fixtures"
	@echo "sanitize  scan the repository for leaked deployment identifiers"
	@echo "links     check that every relative markdown link resolves"

verify:
	@./scripts/verify.sh

sanitize:
	@./scripts/sanitize-check.sh

links:
	@./scripts/check-links.py
