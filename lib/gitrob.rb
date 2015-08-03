require 'json'
require 'cgi'
require 'time'

require 'methadone'
require 'highline/import'
require 'thread/pool'
require 'httparty'
require 'ruby-progressbar'
require 'paint'
require 'sinatra/base'
require 'data_mapper'
require 'tilt/erb'
require 'net/smtp'

require 'gitrob/version'
require 'gitrob/util'
require 'gitrob/progressbar'
require 'gitrob/github/http_client'
require 'gitrob/github/repository'
require 'gitrob/github/blob'
require 'gitrob/github/organization'
require 'gitrob/github/user'
require 'gitrob/observers/sensitive_files'
require 'gitrob/webapp'

require "#{File.dirname(__FILE__)}/../models/organization"
require "#{File.dirname(__FILE__)}/../models/repo"
require "#{File.dirname(__FILE__)}/../models/user"
require "#{File.dirname(__FILE__)}/../models/blob"
require "#{File.dirname(__FILE__)}/../models/finding"

module Gitrob

  def self.scan_org(orgname, threadnum, operation, org_id = nil)
    org_name    = orgname
    repo_count  = 0
    members     = Array.new
    http_client = Gitrob::Github::HttpClient.new({:access_tokens => Gitrob::configuration['github_access_tokens']})
    observers   = Gitrob::Observers.constants.collect { |c| Gitrob::Observers::const_get(c) }
    updated_repo_count = 0
    new_repo_count = 0
    total_update_findings = 0

    Gitrob::task("Loading file patterns...") do
      Gitrob::Observers::SensitiveFiles::load_patterns!
    end

    begin
      org = Gitrob::Github::Organization.new(org_name, http_client)

      Gitrob::task("Collecting organization repositories...") do
        repo_count = org.repositories(operation, org_id).count
      end
    rescue Gitrob::Github::HttpClient::ClientError => e
      if e.status == 404
        Gitrob::fatal("Cannot find GitHub organization with that name; exiting.")
      else
        raise e
      end
    end

    Gitrob::task("Collecting organization members...") do
      members = org.members(operation, org_id)
    end

    progress = Gitrob::ProgressBar.new("Collecting member repositories...",
      :total => members.count
    )

    thread_pool = Thread.pool(threadnum)

    members.each do |member|
      thread_pool.process do
        if member.repositories(operation, org_id).count > 0
          repo_count += member.repositories(operation, org_id).count
          progress.log("Collected #{Gitrob::Util::pluralize(member.repositories(operation, org_id).count, 'repository', 'repositories')} from #{Paint[member.username, :bright, :white]}")
        else
          progress.log("Skipped #{Paint[member.username, :bright, :white]}")
        end
        progress.increment
      end
    end

    thread_pool.shutdown

     if repo_count.zero?
      Gitrob::fatal("Organization has no repositories to check; exiting.")
    end

    progress = Gitrob::ProgressBar.new("Processing repositories...",
      :total => repo_count
    )

    if operation == 'update'
      db_org = Gitrob::Organization.get(org_id)
    else
      db_org = org.save_to_database!
    end

    thread_pool = Thread.pool(threadnum)

    org.repositories(operation, org_id).each do |repo|
      thread_pool.process do
        begin
          if repo.contents.count > 0

            if repo.exists
              db_repo = db_org.repos.first(:name => repo.name)
              updated_repo_count += 1
            else
              db_repo  = repo.save_to_database!(db_org)
              new_repo_count += 1
            end

            findings = 0
      
            repo.contents.each do |blob|
              db_blob = blob.to_model(db_org, db_repo)

              observers.each do |observer|
                observer.observe(db_blob)
              end

              db_blob.findings.each do |f|
                db_blob.findings_count += 1
                findings += 1
                f.organization = db_org
                f.repo         = db_repo
              end

              if repo.exists
                oldBlob = db_repo.blobs.first(:filename => blob.filename)
                if !oldBlob.nil?
                  oldBlob.destroy
                  db_blob.attributes = {:status => 'updated'}
                end
                db_repo.attributes = {:created_at => DateTime.now}
                db_repo.save
              end
              db_blob.save
            end
            total_update_findings += findings
            progress.log("Processed #{Gitrob::Util::pluralize(repo.contents.count, 'file', 'files')} from #{Paint[repo.full_name, :bright, :white]} with #{findings.zero? ? 'no findings' : Paint[Gitrob::Util.pluralize(findings, 'finding', 'findings'), :yellow]}")
          end
          progress.increment
        rescue Exception => e
          progress.log_error("Encountered error when processing #{Paint[repo.full_name, :bright, :white]} (#{e.class.name})")
          progress.increment
        end
      end
    end

    org.members(operation, org_id).each do |member|
      thread_pool.process do
        begin
          if member.exists
            db_user = db_org.users.first(:username => member.username)
          else
            db_user = member.save_to_database!(db_org)
          end

          member.repositories(operation, org_id).each do |repo|

            if repo.exists
              db_repo = db_user.repos.first(:name => repo.name)
              updated_repo_count += 1
            else
              db_repo  = repo.save_to_database!(db_org, db_user)
              new_repo_count += 1
            end

            if repo.contents.count > 0
              findings = 0

              repo.contents.each do |blob|
                db_blob = blob.to_model(db_org, db_repo)

                observers.each do |observer|
                  observer.observe(db_blob)
                end

                db_blob.findings.each do |f|
                  db_blob.findings_count += 1
                  findings += 1
                  f.organization = db_org
                  f.repo         = db_repo
                  f.user         = db_user
                end

                if repo.exists
                  oldBlob = db_repo.blobs.first(:filename => blob.filename)
                  if !oldBlob.nil?
                    oldBlob.destroy
                    db_blob.attributes = {:status => 'updated'}
                  end
                  db_repo.attributes = {:created_at => DateTime.now}
                  db_repo.save
                end
                db_blob.save
              end
              total_update_findings += findings
              progress.log("Processed #{Gitrob::Util::pluralize(repo.contents.count, 'file', 'files')} from #{Paint[repo.full_name, :bright, :white]} with #{findings.zero? ? 'no findings' : Paint[Gitrob::Util.pluralize(findings, 'finding', 'findings'), :yellow]}")
            end
            progress.increment
          end
        rescue Exception => e
          progress.log_error("Encountered error when processing #{Paint[member.username, :bright, :white]} (#{e.class.name})")
          progress.increment
        end
      end
    end

    thread_pool.shutdown
    if operation == 'update'
      Gitrob::status("Completed...\nNew Repositories: #{new_repo_count}\nUpdated Repositories: #{updated_repo_count}\nFindings from Update: #{total_update_findings}")

      if configuration['smtp_server']
        send_email_updates(new_repo_count, updated_repo_count, total_update_findings)
      end
    end
  end

  def self.send_email_updates(new_repo_count, updated_repo_count, total_update_findings)
    msgstr = "From: gitrob\nTo: gitrob.user\nSubject: Gitrob Update\n\n"+
             "New Repositories: #{new_repo_count}\n" +
             "Updated Repositories: #{updated_repo_count}\n" +
             "Findings from Update: #{total_update_findings}"

    if configuration['smtp_scheme'] == 'plain'
      Net::SMTP.start(configuration['smtp_server'], configuration['smtp_port'], configuration['smtp_domain'],
                      configuration['smtp_user_name'], configuration['smtp_password'], :plain) do |smtp|
        smtp.send_message msgstr, 'gitrob', configuration['update_emails']
      end
    elsif configuration['smtp_scheme'] == 'login'
      Net::SMTP.start(configuration['smtp_server'], configuration['smtp_port'], configuration['smtp_domain'],
                      configuration['smtp_user_name'], configuration['smtp_password'], :login) do |smtp|
        smtp.send_message msgstr, 'gitrob', configuration['update_emails']
      end
    elsif configuration['smtp_scheme'] == 'cram_md5'
      Net::SMTP.start(configuration['smtp_server'], configuration['smtp_port'], configuration['smtp_domain'],
                      configuration['smtp_user_name'], configuration['smtp_password'], :cram_md5) do |smtp|
        smtp.send_message msgstr, 'gitrob', configuration['update_emails']
      end
    else
      Net::SMTP.start(configuration['smtp_server'], configuration['smtp_port']) do |smtp|
        smtp.send_message msgstr, 'gitrob', configuration['update_emails']
      end
    end
  end

  def self.task(message)
    print " #{Paint['[*]', :bright, :blue]} #{Paint[message, :bright, :white]}"
    yield
    puts Paint[" done", :bright, :green]
  rescue => e
    puts Paint[" failed", :bright, :red]
    puts "#{Paint[' [!]', :bright, :red]} #{Paint[e.class, :bright, :white]}: #{e.message}"
    exit!
  end

  def self.status(message)
    puts " #{Paint['[*]', :bright, :blue]} #{Paint[message, :bright, :white]}"
  end

  def self.fatal(message)
    puts " #{Paint['[!]', :bright, :red]} #{Paint[message, :bright, :white]}"
    exit!
  end

  def self.prepare_database!
    DataMapper::Model.raise_on_save_failure = true
    DataMapper::Property.auto_validation(false)
    DataMapper.setup(:default, configuration['sql_connection_uri'])
    DataMapper.finalize
    DataMapper.auto_upgrade!
  end

  def self.delete_organization(org)
    orgs = Gitrob::Organization.all(:login => org)
    if orgs.count > 0
      task("Deleting existing #{org} organization...") do
        orgs.destroy
      end
    end
  end

  def self.agreement_accepted?
    File.exists?("#{File.dirname(__FILE__)}/../agreement")
  end

  def self.agreement
    "\n#{self.license}\n\n" +

    Paint["Gitrob is designed for security professionals. If you use any information\n" +
          "found through this tool for malicious purposes that are not authorized by\n" +
          "the organization, you are violating the terms of use and license of this\n" +
          "tool. By typing y/yes, you agree to the terms of use and that you will use\n" +
          "this tool for lawful purposes only.",
          :bright, :red]
  end

  def self.agreement_accepted
    File.open("#{File.dirname(__FILE__)}/../agreement", 'w') { |file| file.write("user accepted") }
  end

  def self.license
    File.read("#{File.dirname(__FILE__)}/../LICENSE.txt")
  end

  def self.configured?
    File.exists?("#{Dir.home}/.gitrobrc")
  end

  def self.configuration
    @config ||= load_configuration!
  end

  def self.load_configuration!
    YAML.load_file("#{Dir.home}/.gitrobrc")
  end

  def self.save_configuration!(config)
    @config = config
    File.open("#{Dir.home}/.gitrobrc", 'w') { |f| f.write YAML.dump(config) }
  end

  def self.banner
<<-BANNER
      _ _           _
  ___|_| |_ ___ ___| |_
 | . | |  _|  _| . | . |
 |_  |_|_| |_| |___|___|
 |___| #{Paint["By @michenriksen", :bright, :white]}
BANNER
  end
end
