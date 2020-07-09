setup:
	python3 -m venv ~/.udacity-devops

install:
	pip install --upgrade pip &&\
		pip install -r requirements.txt

test:
	#python -m pytest -vv --cov=myrepolib tests/*.py
	#python -m pytest --nbval notebook.ipynb
	python -m pytest -vv test_hello.py


lint:
	#hadolint Dockerfile 
	#pylint --disable=R,C,W1203 app.py
	pylint --disable=R,C hello.py

all: install lint test
