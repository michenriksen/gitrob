module Gitrob
  module Jobs
    class Comparison
      include SuckerPunch::Job

      def perform(primary_assessment, secondary_assessment)
        @comparison = Gitrob::Models::Comparison.new
        @primary_assessment = primary_assessment
        @secondary_assessment = secondary_assessment
        @comparison.primary_assessment = primary_assessment
        @comparison.secondary_assessment = secondary_assessment
        @comparison.save
        compare_blobs
        compare_repositories
        compare_owners
        @comparison.finished = true
        @comparison.save
      end

      private

      def compare_blobs
        old_blob_shas = @secondary_assessment.blobs_dataset.select_map(:sha)
        @primary_assessment.blobs_dataset.eager(:flags).all.each do |blob|
          next if old_blob_shas.include?(blob.sha)
          @comparison.add_blob(blob)
          @comparison.blobs_count += 1
          @comparison.findings_count += 1 unless blob.flags_count.zero?
        end
      end

      def compare_repositories
        old_repository_github_ids = @secondary_assessment
                                     .repositories_dataset
                                     .select_map(:github_id)
        @primary_assessment.repositories.each do |repository|
          next if old_repository_github_ids.include?(repository.github_id)
          @comparison.add_repository(repository)
          @comparison.repositories_count += 1
        end
      end

      def compare_owners
        old_owner_github_ids = @secondary_assessment
                                     .owners_dataset
                                     .select_map(:github_id)
        @primary_assessment.owners.each do |owner|
          next if old_owner_github_ids.include?(owner.github_id)
          @comparison.add_owner(owner)
          @comparison.owners_count += 1
        end
      end
    end
  end
end
