
all: enrichment ccsne_yields

enrichment:
	$(MAKE) -C vice/core/

ccsne_yields:
	$(MAKE) -C vice/data/_ccsne_yields/

tests:
	$(MAKE) -C docs/ tests

tutorial: 
	$(MAKE) -C docs/ 
	$(MAKE) -C docs/ clean

clean:
	cd vice/core/ && make clean && cd - 
	cd vice/data/_ccsne_yields && make clean && cd -	
	rm -r build
	# cd docs && make clean && cd -