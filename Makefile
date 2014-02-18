PROJECT = boilerplate
PROJECT_DIR = $(shell pwd)

TESTTIMEOUT = 5000
REPORTER	= spec
TEST_UNIT_SPEC = $(shell find test -name \*-uspec.coffee -or -name \*-unit.coffee)
TEST_INT_SPEC  = $(shell find test -name \*-intspec.coffee -or -name \*-integration.coffee )

TMP_BUILD = tmp

BOWER_COMPONENTS = bower_components

SHARED_SRC = src/coffee/shared
SHARED_BUILD = lib/shared

APP_BUILD = lib/server
APP_VIEWS = src/views
APP_SRC = src/coffee/server

IMG_SRC = src/static/img
IMG_BUILD = $(APP_BUILD)/public

IMG_SRC = src/static/img
IMG_BUILD = $(APP_BUILD)/public

FONTS_SRC = src/static/fonts/
FONTS_BUILD = lib/server/public/css/

CSS_BOWER_SRC = $(BOWER_COMPONENTS)
CSS_BOWER_TARGETS = bootstrap/dist/css/bootstrap.css

CSS_SRC = src/static/css
CSS_BUILD = lib/server/public/css
CSS_FINAL = $(CSS_BUILD)/$(PROJECT).css
CSS_FINAL_MIN = $(CSS_BUILD)/$(PROJECT).min.css
CSS_TARGETS =	boilerplate.css

#any ajax code can be added as separate coffee files in here.
COFFEE_UI_SRC = src/coffee/browser

JS_UI_BUILD = lib/server/public/js

JS_UI_FINAL = $(JS_UI_BUILD)/$(PROJECT).build.js

JS_UI_LIB_SRC = $(BOWER_COMPONENTS)

UI_LIB_TARGETS = 	jquery/jquery.min.js \
									bootstrap/dist/js/bootstrap.js



COFFEE_UI_TARGETS =	 `find $(COFFEE_UI_SRC) -name \*.coffee | sort`
										
install:
	npm install

version:
	@echo $(VERSION)


build-ui: 
	@mkdir -p $(JS_UI_BUILD) && mkdir -p $(TMP_BUILD)
	@cp -r $(IMG_SRC) $(IMG_BUILD)
	
	@coffee -c -o $(TMP_BUILD) $(COFFEE_UI_TARGETS)
	@awk 'FNR==1{print ""}1' $(COFFEE_UI_TARGETS) > $(TMP_BUILD)/ui.build.coffee
	@coffee -c -o $(TMP_BUILD) $(TMP_BUILD)/ui.build.coffee

	@for file in $(UI_LIB_TARGETS) ; do \
		cat $(addprefix $(JS_UI_LIB_SRC)/, $$file) ; \
		echo ; \
	done > $(TMP_BUILD)/libs.js
	@cat $(TMP_BUILD)/libs.js $(TMP_BUILD)/ui.build.js  > $(JS_UI_FINAL)
	
	#BUILD BOWER AND OWN CSS INTO FINAL CSS and then remove the tmp folder
	@mkdir -p $(CSS_BUILD)
	
	@for file in $(CSS_BOWER_TARGETS) ; do \
		cat $(addprefix $(CSS_BOWER_SRC)/, $$file) | sed -e "s/\@@STATICDOMAIN/$(STATIC_DOMAIN)/" ; \
		echo ; \
	done > $(TMP_BUILD)/bower.css

	@for file in $(CSS_TARGETS) ; do \
		cat $(addprefix $(CSS_SRC)/, $$file) | sed -e "s/\@@STATICDOMAIN/$(STATIC_DOMAIN)/" ; \
		echo ; \
	done > $(TMP_BUILD)/temp.css
	
	@cat $(TMP_BUILD)/bower.css $(TMP_BUILD)/temp.css  > $(CSS_FINAL)
	#DONE WITH CSS
	
	@rm -rf $(TMP_BUILD)

	@cp -rf $(FONTS_SRC)* $(FONTS_BUILD)

build-app:
	@mkdir -p lib && coffee -c -o $(APP_BUILD) $(APP_SRC)
	@find $(APP_SRC) -name "*.coffee" -print0 | xargs -0 ./node_modules/coffeelint/bin/coffeelint -f ./coffeelint.json
	@cp -rf $(APP_VIEWS) $(APP_BUILD)


build-shared:
	@coffee -c -o $(SHARED_BUILD) $(SHARED_SRC)
	@find $(SHARED_SRC) -name "*.coffee" -print0 | xargs -0 ./node_modules/coffeelint/bin/coffeelint -f ./coffeelint.json

build-dev: build-ui build-app build-shared

build-prod: build-ui build-app build-shared min

watch: build-dev
	node ./node_modules/nodemon/bin/nodemon --watch src -x "make build-dev -f" Makefile

min-js:
	@./node_modules/uglify-js/bin/uglifyjs -nc -o $(JS_UI_FINAL) $(JS_UI_FINAL)

min-css:
	@./node_modules/uglifycss/uglifycss $(CSS_FINAL) > $(CSS_FINAL_MIN)

min: min-js min-css

clean:
	@find src/coffee -name \*.js | xargs rm
	@find test -name \*.js | xargs rm
	@rm -rf lib 

#all-dev: install build-dev test
all-dev: install build-dev

.PHONY: all 

