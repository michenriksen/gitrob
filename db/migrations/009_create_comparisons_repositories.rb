Sequel.migration do
  change do
    create_table(:comparisons_repositories) do
      foreign_key :comparison_id, :comparisons, :on_delete => :cascade, :index => true
      foreign_key :repository_id, :repositories, :on_delete => :cascade, :index => true
    end
  end
end
