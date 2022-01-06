# Starknet AMM with Nile

A simple AMM written in Cairo for StarkNet, using the Nile development framework.

## Getting started
Create and activate venv
```
python3 -m venv env
source env/bin/activate
```
Install dependencies
```
nile init
```
Compile contract
```
nile compile contracts/pool.cairo
```
Run the tests with
```
pytest -s 
```
