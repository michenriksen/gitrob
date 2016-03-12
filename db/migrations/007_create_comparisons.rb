Sequel.migration do
  change do
    create_table(:comparisons) do
      primary_key :id
      foreign_key :primary_assessment_id, :assessments, :on_delete => :cascade, :index => true
      foreign_key :secondary_assessment_id, :assessments, :on_delete => :cascade, :index => true
      Integer :blobs_count, :default => 0
      Integer :repositories_count, :default => 0
      Integer :owners_count, :default => 0
      Integer :findings_count, :default => 0
      Boolean :finished, :default => false, :index => true
      Boolean :deleted, :default => false, :index => true
      DateTime :updated_at
      DateTime :created_at
    end
  end
end
