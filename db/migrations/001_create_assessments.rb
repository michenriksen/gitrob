Sequel.migration do
  change do
    create_table(:assessments) do
      primary_key :id
      String :name
      String :endpoint
      String :site
      Boolean :verify_ssl
      Integer :owners_count, :default => 0
      Integer :repositories_count, :default => 0
      Integer :blobs_count, :default => 0
      Integer :findings_count, :default => 0
      Boolean :finished, :default => false, :index => true
      Boolean :deleted, :default => false, :index => true
      DateTime :updated_at
      DateTime :created_at, :index => true
    end
  end
end
