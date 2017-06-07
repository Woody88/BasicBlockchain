defmodule BasicBlockchainTest do
  use ExUnit.Case
  doctest BasicBlockchain

  setup do
    {:ok, blockchain} = BasicBlockchain.create_blockchain
    {:ok, [blockchain: blockchain]}
  end

  test "Genenis block create", context do
    chain = BasicBlockchain.get_blockchain(context[:blockchain])

    assert length(chain) == 1
    assert List.first(chain) |> Map.get(:data) |> Kernel.==("Genesis Block")
  end

  test "Create a block", context do
    ts_bl1 = %{sender: "Ikumi", recepient: "Woodson", amount: 35, payment: "Debit" }
             |> BasicBlockchain.generate_next_block(context[:blockchain])
    assert :ok = BasicBlockchain.add_block_to_chain(context[:blockchain], ts_bl1)
  end

  test "Nonce generated always unique on blocks", context do
    nonce_list = Enum.map(1..10, fn x ->  generate_block(x, context) |> Map.get(:nonce) end)
    uniq_nonce_list = Enum.uniq(nonce_list)
    assert nonce_list == uniq_nonce_list
  end

  test "Mining function return block with a new nonce and ok status", context do
     Enum.map(1..3, fn x ->  block = generate_block(x, context)
        assert :ok = BasicBlockchain.add_block_to_chain(context[:blockchain], block)
     end)
     [update_block | _] = BasicBlockchain.get_blockchain(context[:blockchain])
     updated_block = Map.from_struct(update_block) |>  Kernel.put_in([:data,:amount], 100)
     {:success, mined_block, _} = BasicBlockchain.mine(context[:blockchain], updated_block)
     assert :ok = BasicBlockchain.update_block_from_chain(context[:blockchain], mined_block)
  end

  def generate_block(n, context) do
    n_to_s = to_string(n)
    %{sender: "Ikumi"<> n_to_s, recepient: "Woodson" <> n_to_s, amount: 35 + n, payment: "Debit" }
    |> BasicBlockchain.generate_next_block(context[:blockchain])
  end
end
