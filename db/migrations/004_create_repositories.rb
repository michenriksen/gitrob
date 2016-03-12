Sequel.migration do
  change do
    create_table(:repositories) do
      primary_key :id
      Integer :github_id, :index => true
      foreign_key :assessment_id, :assessments, :on_delete => :cascade, :index => true
      foreign_key :owner_id, :owners, :on_delete => :cascade, :index => true
      String :name
      String :full_name
      String :description
      Boolean :private
      String :url
      String :html_url
      String :homepage
      Integer :size
      String :default_branch
      Integer :blobs_count, :default => 0
      Integer :findings_count, :index => true, :default => 0
      DateTime :updated_at
      DateTime :created_at
    end
  end
end
