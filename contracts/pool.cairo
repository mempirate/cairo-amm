# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_le, assert_nn_le, unsigned_div_rem
# from starkware.starknet.common.syscalls import storage_read, storage_write

from contracts.token import account_balance, modify_account_balance, get_account_token_balance

# Upper balance of a token in our AMM: unsigned 64 bit integer
const BALANCE_UPPER_BOUND = 2 ** 64
const POOL_UPPER_BOUND = 2 ** 30

const TOKEN_TYPE_A = 1
const TOKEN_TYPE_B = 2

# We initialize both reserves with the constructor.
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_a : felt, token_b : felt):
    assert_nn_le(token_a, POOL_UPPER_BOUND - 1)
    assert_nn_le(token_b, POOL_UPPER_BOUND - 1)

    set_pool_token_balance(token_type=TOKEN_TYPE_A, balance=token_a)
    set_pool_token_balance(token_type=TOKEN_TYPE_B, balance=token_b)
    return ()
end

# Mapping between the token type and the balance in the pool for that
# token type. This is kept in persistent storage (see the storage_var decorator)
# token_type -> balance
@storage_var
func pool_balance(token_type : felt) -> (balance : felt):
end

# Internal function to set pool balances.
func set_pool_token_balance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_type : felt, balance : felt):
    assert_nn_le(balance, BALANCE_UPPER_BOUND - 1)
    pool_balance.write(token_type, balance)
    return ()
end

# Gets the pool balance for a specific token.
@view
func get_pool_token_balance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_type : felt) -> (balance : felt):
    return pool_balance.read(token_type)
end

# Returns the opposite token.
func get_opposite_token(token_type : felt) -> (t : felt):
    if token_type == TOKEN_TYPE_A:
        return (TOKEN_TYPE_B)
    else:
        return (TOKEN_TYPE_A)
    end
end

# External function that prepares the swap and does all the checks.
# We want to trade amount_from tokens of token_from type to the other token
# in the pool.
@external
func swap{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        account_id : felt, token_from : felt, amount_from : felt) -> (amount_to : felt):
    # Verify that token_from is either TOKEN_TYPE_A or TOKEN_TYPE_B (0 or 1).
    assert (token_from - TOKEN_TYPE_A) * (token_from - TOKEN_TYPE_B) = 0

    # Check requested amount_from is valid.
    assert_nn_le(amount_from, BALANCE_UPPER_BOUND - 1)

    # Check if the user has enough funds.
    let (account_from_balance) = get_account_token_balance(
        account_id=account_id, token_type=token_from)
    assert_le(amount_from, account_from_balance)

    # Execute the actual swap.
    let (token_to) = get_opposite_token(token_type=token_from)
    let (amount_to) = do_swap(
        account_id=account_id, token_from=token_from, token_to=token_to, amount_from=amount_from)

    return (amount_to=amount_to)
end

# Internal function that does the actual swap according to the xy=k invariant.
func do_swap{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        account_id : felt, token_from : felt, token_to : felt, amount_from : felt) -> (
        amount_to : felt):
    # Allocates space for local variables to use.
    alloc_locals

    # Get pool balance. local variables persist across scope changes (function calls).
    let (local amm_from_balance) = get_pool_token_balance(token_type=token_from)
    let (local amm_to_balance) = get_pool_token_balance(token_type=token_to)

    # Calculate swap amount. unsigned_div_rem returns the value and the remainder of an
    # unsigned integer division.
    let (local amount_to, _) = unsigned_div_rem(
        amm_to_balance * amount_from, amm_from_balance + amount_from)

    # Update token_from balances.
    modify_account_balance(account_id=account_id, token_type=token_from, amount=-amount_from)
    set_pool_token_balance(token_type=token_from, balance=amm_from_balance + amount_from)

    # Update token_to balances.
    modify_account_balance(account_id=account_id, token_type=token_to, amount=amount_to)
    set_pool_token_balance(token_type=token_to, balance=amm_to_balance - amount_to)
    return (amount_to=amount_to)
end
