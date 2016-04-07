.PHONY: deploy

deploy: 
	butler push . leafo/x-moon:src -a http://localhost.com:8080


