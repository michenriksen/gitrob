Sequel.migration do
  change do
    create_table(:gitrob_users) do
      primary_key :id
      String :username, :size => 100
      String :password_digest, :size => 100
    end
  end
end
