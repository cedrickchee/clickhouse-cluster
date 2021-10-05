# Based on this post: https://earthly.dev/blog/python-makefile/

VENV = venv
PYTHON = $(VENV)/bin/python3
PIP = $(VENV)/bin/pip
ACTIVATE = $(VENV)/bin/activate

all: install run

# Just create virtualenv
venv:
	: # Create venv if it doesn't exist
	test -d $(VENV) || python3 -m venv $(VENV)

# Make virtual environment and execute other commands
# Reference: https://stackoverflow.com/questions/33839018/activate-virtualenv-in-makefile
install: venv requirements.txt
	: # Activate venv and install something inside
	. $(ACTIVATE) && pip install -r requirements.txt

# Old make virtual env and install dependencies
$(VENV)/bin/activate: venv requirements.txt
	# python3 -m venv $(VENV)
	$(PIP) install -r requirements.txt

# Old install deps and run
oldrun: $(VENV)/bin/activate
	$(PYTHON) app.py

# Execute your app inside venv
run:
	: # determine if we are in venv
	. $(ACTIVATE) && pip -V
	: # run app
	. $(ACTIVATE) && python app.py

# Remove venv and python binaries
clean:
	rm -rf __pycache__
	rm -rf $(VENV)

# setup: requirements.txt
# 	pip install -r requirements.txt

.PHONY: run oldrun clean