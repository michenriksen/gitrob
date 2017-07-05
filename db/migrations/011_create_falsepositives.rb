Sequel.migration do
  change do
    create_table(:false_positives) do
      primary_key :id
      String :repository, :size => 100
      String :path, :size => 100 
      String :fingerprint, :size => 65, :fixed => true, :index => true
    end
  end
end
