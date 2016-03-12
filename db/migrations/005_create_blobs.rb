Sequel.migration do
  change do
    create_table(:blobs) do
      primary_key :id
      foreign_key :assessment_id, :assessments, :on_delete => :cascade, :index => true
      foreign_key :owner_id, :owners, :on_delete => :cascade, :index => true
      foreign_key :repository_id, :repositories, :on_delete => :cascade, :index => true
      String :path
      Integer :size, :index => true
      String :sha, :size => 40, :fixed => true, :index => true
      Integer :flags_count, :index => true, :default => 0
      DateTime :updated_at
      DateTime :created_at
    end
  end
end
