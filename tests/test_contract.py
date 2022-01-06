"""pool.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "pool.cairo")

# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.


@pytest.mark.asyncio
async def test_swap():
    """Test increase_balance method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
        constructor_calldata=[3000, 4000]
    )

    execution_info = await contract.get_pool_token_balance(token_type=1).call()
    assert execution_info.result == (3000,)
    execution_info = await contract.get_pool_token_balance(token_type=2).call()
    assert execution_info.result == (4000,)

    await contract.modify_account_balance(account_id=1, token_type=1, amount=500).invoke()
    info = await contract.get_account_token_balance(account_id=1, token_type=1).call()
    assert info.result == (500,)

    await contract.swap(account_id=1, token_from=1, amount_from=100).invoke()

    execution_info = await contract.get_pool_token_balance(token_type=1).call()
    print(execution_info.result)
    execution_info = await contract.get_pool_token_balance(token_type=2).call()
    print(execution_info.result)

    info = await contract.get_account_token_balance(account_id=1, token_type=1).call()
    print(info.result)
    assert info.result == (400,)
    info = await contract.get_account_token_balance(account_id=1, token_type=2).call()
    print(info.result)
    assert info.result == (129,)
