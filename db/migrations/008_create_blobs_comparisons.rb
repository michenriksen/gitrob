Sequel.migration do
  change do
    create_table(:blobs_comparisons) do
      foreign_key :comparison_id, :comparisons, :on_delete => :cascade, :index => true
      foreign_key :blob_id, :blobs, :on_delete => :cascade, :index => true
    end
  end
end
