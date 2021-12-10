python_testcases := $(wildcard t/*.py)

test:
	@echo $(python_testcases) | xargs -P 8 -n 1 bash ./runtest.sh
