Sequel.migration do
  change do
    create_table(:owners) do
      primary_key :id
      Integer :github_id, :index => true
      foreign_key :assessment_id, :assessments, :on_delete => :cascade, :index => true
      String :login
      String :type, :size => 12, :index => true
      String :url
      String :html_url
      String :avatar_url
      String :name
      String :blog
      String :location
      String :email
      String :bio
      Integer :repositories_count, :index => true, :default => 0
      Integer :blobs_count, :index => true, :default => 0
      Integer :findings_count, :index => true, :default => 0
      DateTime :updated_at
      DateTime :created_at
    end
  end
end
