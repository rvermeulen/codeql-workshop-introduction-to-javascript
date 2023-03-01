all: nodejs-goof-db.zip

nodejs-goof-db.zip: nodejs-goof
	codeql database create --language=javascript --source-root=nodejs-goof nodejs-goof-db
	codeql database bundle -o nodejs-goof-db.zip nodejs-goof-db
	rm -r nodejs-goof-db
