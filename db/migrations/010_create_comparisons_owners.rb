Sequel.migration do
  change do
    create_table(:comparisons_owners) do
      foreign_key :comparison_id, :comparisons, :on_delete => :cascade, :index => true
      foreign_key :owner_id, :owners, :on_delete => :cascade, :index => true
    end
  end
end
