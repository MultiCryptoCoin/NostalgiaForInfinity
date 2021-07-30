.PHONY: run
.ONESHELL:

-include .env
export

STRATEGIES = $(shell ls user_data/strategies | grep py | sed "s/.py//g" | grep -v "IndicatorforRL" | grep -v "TrainCatBoostStrategy" | grep -v "Ensemble" | tr "\n" " ")
TODAY = $(shell date +'%Y-%m-%d')
all: help

help: # show all commands
	@sed -n 's/:.*#/:/p' makefile | grep -v sed

build: # update and build local image
	docker-compose pull && docker-compose build --progress=plain

pairs: # pull pairs for $COIN
	docker-compose run --rm freqtrade \
		list-pairs --config user_data/data/pairlists.json --quot=$(COIN) --print-json

list-data: # list data
	docker-compose run --rm freqtrade \
		 list-data --config user_data/data/pairlists.json --config user_data/data/$(EXCHANGE)-usdt-static.json

list-strats: # list strategies
	@echo $(STRATEGIES)


test: # run backtest
	docker-compose run --rm freqtrade \
		backtesting --config user_data/data/pairlists.json --config user_data/data/$(EXCHANGE)-usdt-static.json --strategy-list $(STRATEGY) --timeframe $(B_TIMEFRAME) --timerange=$(TIMERANGE) \
		--export=trades
	osascript -e 'display notification "Done"'

test-all: # run backtest on all strats
	docker-compose run --rm freqtrade \
		backtesting --config user_data/data/pairlists.json --config user_data/data/$(EXCHANGE)-usdt-static.json --strategy-list $(STRATEGIES) --timerange=$(TIMERANGE) --timeframe $(B_TIMEFRAME) --export=trades
	osascript -e 'display notification "Done"'

hyperopt: data # run hyper opt
	docker-compose run --rm freqtrade \
		hyperopt --config user_data/data/pairlists.json --config user_data/data/$(EXCHANGE)-usdt-static.json --hyperopt-loss $(LOSS) --spaces $(SPACES) --strategy $(STRATEGY) -e $(EPOCHS) --timerange=$(TIMERANGE) --timeframe=$(TIMEFRAME) --random-state 42 -j 12
	osascript -e 'display notification "Done"'

stop: # stop containers
	docker-compose stop


shell: # run bash
	docker-compose run --rm freqtrade bash

dry: # run dry mode
	docker-compose run --rm freqtrade \
		freqtrade trade --config user_data/data/pairlists.json --config user_data/data/$(EXCHANGE)-usdt-static.json --verbose
