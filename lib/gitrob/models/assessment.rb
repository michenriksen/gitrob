module Gitrob
  module Models
    class Assessment < Sequel::Model
      set_allowed_columns :name, :endpoint, :site, :verify_ssl, :finished

      one_to_many :github_access_tokens
      one_to_many :owners
      one_to_many :repositories
      one_to_many :blobs
      one_to_many :flags
      one_to_many :primary_comparisons,
                  :class => :"Gitrob::Models::Comparison",
                  :key   => :primary_assessment_id
      one_to_many :secondary_comparisons,
                  :class => :"Gitrob::Models::Comparison",
                  :key   => :secondary_assessment_id

      def validate
        super
        validates_presence [:endpoint, :site, :verify_ssl]
      end

      def name
        values[:name] || fallback_name
      end

      def save_owner(owner)
        owner = Gitrob::Utils.symbolize_hash_keys(owner.to_hash)
        allowed_columns = Gitrob::Models::Owner.allowed_columns
        owner[:github_id] = owner.delete(:id)
        data = owner.select { |k, _v| allowed_columns.include?(k.to_sym) }
        owner = Gitrob::Models::Owner.new(data)
        self.owners_count += 1
        add_owner(owner)
      end

      def save_repository(repository, owner)
        repository = Gitrob::Utils.symbolize_hash_keys(repository.to_hash)
        allowed_columns = Gitrob::Models::Repository.allowed_columns
        repository[:github_id] = repository.delete(:id)
        data = repository.select { |k, _v| allowed_columns.include?(k.to_sym) }
        repository = Gitrob::Models::Repository.new(data)
        repository.owner = owner
        self.repositories_count += 1
        repository.owner.repositories_count += 1
        repository.owner.save
        add_repository(repository)
      end

      def save_blob(blob, repository, owner)
        allowed_columns = Gitrob::Models::Blob.allowed_columns
        data = blob.select { |k, _v| allowed_columns.include?(k.to_sym) }
        blob = Gitrob::Models::Blob.new(data)
        blob.repository = repository
        blob.owner = owner
        self.blobs_count += 1
        blob.owner.blobs_count += 1
        blob.owner.save
        blob.repository.blobs_count += 1
        blob.repository.save
        add_blob(blob)
      end

      def save_github_access_token(token)
        add_github_access_token(
          Gitrob::Models::GithubAccessToken.new(:token => token)
        )
      end

      def comparable_assessments
        owner_ids      = owners.map(&:github_id)
        comparison_ids = primary_comparisons_dataset
                          .select_map(:secondary_assessment_id) +
                         secondary_comparisons_dataset
                          .select_map(:primary_assessment_id)
        self.class
          .where("id NOT IN ?", [id] + comparison_ids)
          .where(:finished => true, :deleted => false)
          .order(:created_at)
          .eager(:owners).reverse.all.select  do |a|
            !(a.owners.map(&:github_id) & owner_ids).empty?
          end
      end

      def comparable_assessment?(assessment)
        comparable_assessments.map(&:id).include?(assessment.id)
      end

      private

      def fallback_name
        reload.values[:created_at].strftime("%A, %d %b %Y %H:%M")
      end
    end
  end
end
