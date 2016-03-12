Sequel.migration do
  change do
    create_table(:flags) do
      primary_key :id
      foreign_key :assessment_id, :assessments, :on_delete => :cascade, :index => true
      foreign_key :blob_id, :blobs, :on_delete => :cascade, :index => true
      String :caption
      String :description
      DateTime :updated_at
      DateTime :created_at
    end
  end
end
