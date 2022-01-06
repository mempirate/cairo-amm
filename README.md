# Starknet AMM with Nile

A simple AMM written in Cairo for StarkNet, using the Nile development framework.

## Getting started
Create and activate a new virtual env:
```
python3 -m venv env
source env/bin/activate
```
Install Nile and dependencies:
```
pip install cairo-nile
nile init
```
Compile the `pool.cairo` contract:
```
nile compile contracts/pool.cairo
```
Run the tests with pytest:
```
pytest -s 
```
