Sequel.migration do
  change do
    create_table(:github_access_tokens) do
      primary_key :id
      foreign_key :assessment_id, :assessments, :on_delete => :cascade, :index => true
      String :token, :size => 40, :fixed => true
      DateTime :updated_at
      DateTime :created_at
    end
  end
end
