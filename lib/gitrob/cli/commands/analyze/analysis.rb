module Gitrob
  class CLI
    module Commands
      class Analyze < Gitrob::CLI::Command
        module Analysis
          def analyze_repositories
            loadFalsePositive
            repo_progress_bar do |progress|
              github_data_manager.owners.each do |owner|
                @db_owner = @db_assessment.save_owner(owner)
                thread_pool do |pool|
                  repositories_for_owner(owner).each do |repo|
                    pool.process do
                      db_repo = @db_assessment.save_repository(repo, @db_owner)
                      blobs   = blobs_for_repository(repo)
                      analyze_blobs(blobs, db_repo, @db_owner, progress)
                    end
                  end
                end
              end
            end
          end

          def analyze_blobs(blobs, db_repo, db_owner, progress)
            findings = 0
            blobs.each do |blob|
              db_blob = @db_assessment.save_blob(blob, db_repo, db_owner)

              #Do a fingerprint comparison before observing blob
              if !@falsePositiveFingerprints.include? db_blob.sha256
                Gitrob::BlobObserver.observe(db_blob)
              end
              
              if db_blob.flags.count > 0
                findings += 1
                @db_assessment.findings_count += 1
                db_owner.findings_count += 1
                db_repo.findings_count += 1
              end
            end
            db_owner.save
            db_repo.save
            progress.increment
            report_findings(findings, db_repo, progress)
          rescue => e
            progress.error("#{e.class}: #{e.message}")
          end

          #Loading false positives from database
          def loadFalsePositive
            @falsePositiveFingerprints =[]
            @loadDatabase = Gitrob::Models::FalsePositive.dataset.all
            @loadDatabase.each do |e|
              @falsePositiveFingerprints << e.fingerprint
            end
          end

          def report_findings(finding_count, repo, progress)
            return if finding_count.zero?
            files = finding_count == 1 ? "1 file" : "#{finding_count} files"
            progress.info(
              "Flagged #{files.to_s.light_yellow} " \
              "in #{repo.full_name.bold}")
          end
        end

        def repo_progress_bar
          progress_bar(
            "Analyzing repositories...",
            :total => repository_count) do |progress|
            yield progress
          end
          sleep 0.1
        end

        def repositories_for_owner(owner)
          github_data_manager.repositories_for_owner(owner)
        end

        def blobs_for_repository(repo)
          github_data_manager.blobs_for_repository(repo)
        end

        def repository_count
          @github_data_manager.repositories.count
        end
      end
    end
  end
end
