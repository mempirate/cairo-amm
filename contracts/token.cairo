%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_nn_le

# Upper balance of a token in our AMM: unsigned 64 bit integer
const BALANCE_UPPER_BOUND = 2 ** 64

# Mapping between a tuple of account_id and token_type to the related balance.
# (account_id, token_type) -> balance
@storage_var
func account_balance(account_id : felt, token_type : felt) -> (balance : felt):
end

# Function to modify account balances. Amount can be negative.
# Implicit arguments are given because we need them for assert and syscalls (storage reads/writes)
@external
func modify_account_balance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        account_id : felt, token_type : felt, amount : felt):
    # Read the current balance from storage
    let (current_balance) = account_balance.read(account_id, token_type)
    # tempvars are available in the current scope, as long as the scope doesn't change.
    # When the scope changes, they get revoked.
    tempvar new_balance = current_balance + amount

    # Assert that the new balance is non-negative + less than or equal to BALANCE_UPPER_BOUND - 1
    assert_nn_le(new_balance, BALANCE_UPPER_BOUND - 1)

    # Update account balance
    account_balance.write(account_id=account_id, token_type=token_type, value=new_balance)
    return ()
end

@view
func get_account_token_balance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        account_id : felt, token_type : felt) -> (balance : felt):
    return account_balance.read(account_id, token_type)
end
