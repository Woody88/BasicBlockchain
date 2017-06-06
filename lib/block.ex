defmodule Block do
   defstruct index: 0, previousHash: "0", timestamp: :os.system_time(:millisecond), data: :none, hash: "0", nonce: 0
   @nonce_limit 500000

   def create_blockchain do
     Agent.start_link(fn -> [generate_genesis_block()] end)
   end

   def generate_genesis_block do
      struct(%Block{}, %{data: "Genesis Block"})
      |> generate_block_hash([])
   end

   def get_blockchain(blockchain) do
     Agent.get(blockchain, fn state -> state end)
   end

   def get_previous_block(blockchain) do
     get_blockchain(blockchain)
     |> List.first
   end

   def update_block_from_chain(blockchain, block) do
      Agent.update(blockchain, fn state ->
        Enum.into(state, [], fn(x) -> if x.index == block.index, do: block, else: x  end)
      end)
   end

   def add_block_to_chain(blockchain, block) do
      previous_block = get_previous_block(blockchain)
      if is_valid_new_block(block, previous_block, blockchain), do: add_block(blockchain, block), else: is_valid_new_block(block, previous_block, blockchain)
   end

   defp add_block(blockchain, block) do
     Agent.update(blockchain, fn state -> [block] ++ state end)
   end

   def generate_next_block(blockdata, blockchain) do
        previous_block = get_previous_block(blockchain)
        next_timestamp = :os.system_time(:millisecond)
        next_index =  previous_block.index + 1

        struct(%Block{}, index: next_index, timestamp: next_timestamp, previousHash: previous_block.hash, data: blockdata )
        |> generate_block_hash(blockchain)
   end

   def generate_block_hash(block, blockchain) do
     %{ block | hash: calculate_hash(block, blockchain) }
   end

   def calculate_hash(block, blckchn) when is_map(block) do
     blockchain = if blckchn == [], do: blckchn, else: get_blockchain(blckchn)
     value = (blockchain |> :erlang.term_to_binary) <> (block.index |> Integer.to_string) <> block.previousHash <> (block.nonce |> Integer.to_string) <> (block.timestamp |> Integer.to_string) <> (block.data |> :erlang.term_to_binary)

     :crypto.hash_init(:sha256)
     |> :crypto.hash_update(value)
     |> :crypto.hash_final
     |> Base.encode16
     |> String.downcase
   end

   def is_valid_new_block(new_block, previous_block, blockchain) do
     cond do
        (previous_block.index + 1) != new_block.index ->
          { false, "Invalid index" }
        previous_block.hash != new_block.previousHash ->
          { false, "Invalid previous hash" }
        calculate_hash(new_block, blockchain) != new_block.hash ->
          { false, "Invalid hash: " <> calculate_hash(new_block, blockchain) <> " " <> new_block.hash }
        true -> true
     end
   end

   def mine(blockchain, block, nonce) do
      cond do
        block.nonce == @nonce_limit ->
          {:error, "could not mine block."}
        {:success, mined_block, _} =  mining(blockchain, block, nonce) ->
          :ok = update_block_from_chain(blockchain, mined_block)
      end
   end

   def mining(blockchain, block, nonce) do
     inc_nonce = nonce + 1
     mine_attempt = calculate_hash(block, blockchain)
     if mine_attempt |> String.starts_with?("0000"), do: {:success, %{block | hash: mine_attempt, nonce: inc_nonce}, "Mine completed!"}, else: mine(blockchain, %{block | nonce: inc_nonce}, inc_nonce)
   end


end

# {:ok, blockchain} = Block.create_blockchain
# genesis_block = Block.get_blockchain(blockchain)
# transaction_data = %{sender: "Ikumi", recepient: "Woodson", amount: 35, payment: "Debit" }
# ts_bl1 = Block.generate_next_block(transaction_data, blockchain)
#  Block.add_block_to_chain(blockchain, ts_bl1)
# transaction_data2 = %{sender: "Woodson", recepient: "Jawaad", amount: 10, payment: "Debit" }
# ts_bl1 = Block.generate_next_block(transaction_data2, blockchain)
#  Block.add_block_to_chain(blockchain, ts_bl2)
#  blocks = Block.get_blockchain(blockchain)
# %{index: 0, previousHash: "0", timestamp: :os.system_time(:millisecond), data: "my genesis!", hash: "U1iquFMbMopg1jG+Vqtn/h4jPQEE6hGnWgNoj0nRr5Ez1PlQ8XSpFDDeWmXChPN5"}
# h = Block.calculate_hash(b)
# block = Block.create(%{b | hash: h})
# transaction_data = %{sender: "Ikumi", recepient: "Woodson", amount: 35, payment: "Debit" }
# Block.generate_next_block(transaction_data, blockchain)
