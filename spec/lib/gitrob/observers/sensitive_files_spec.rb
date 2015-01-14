require 'spec_helper'

RSpec.describe Gitrob::Observers::SensitiveFiles do
  let(:patterns) { File.read("#{File.dirname(__FILE__)}/../../../../patterns.json") }

  describe '.load_patterns!' do
    it 'reads pattern file' do
      expect(File).to receive(:read).with(/gitrob\/lib\/gitrob\/observers\/\.\.\/\.\.\/\.\.\/patterns.json\z/)
      .and_return(patterns)

      described_class.load_patterns!
    end

    it 'parses JSON document' do
      expect(JSON).to receive(:parse).with(patterns).and_return(JSON.parse(patterns))

      described_class.load_patterns!
    end

    context 'when JSON document is invalid' do
      before do
        allow(File).to receive(:read).and_return('oops!')
      end

      it 'raises InvalidPatternFileError exception' do
        expect do
          described_class.load_patterns!
        end.to raise_error(Gitrob::Observers::SensitiveFiles::InvalidPatternFileError)
      end
    end
  end

  describe '.observe' do
    before do
      allow(described_class).to receive(:patterns).and_return(JSON.parse(patterns))
      stub_request(:get, "https://api.github.com/orgs/org").
        to_return(:status => 200, :body => JSON.dump({
          "login"      => "org",
          "name"       => "Org",
          "website"    => "http://www.org.com",
          "location"   => "The Internet",
          "email"      => "contact@org.com",
          "avatar_url" => "https://github.com/avatar.png",
          "html_url"   => "https://github.com/org"
      }))
      stub_request(:get, "https://api.github.com/repos/user/repo").
        to_return(:status => 200, :body => JSON.dump({
          "html_url"    => "https://github.com/user/repo",
          "description" => "My Dotfiles",
          "homepage"    => "http://localhost"
      }))
    end

    let(:http_client) { Gitrob::Github::HttpClient.new(:access_tokens => ['deadbeefdeadbeefdeadbeefdeadbeef']) }
    let(:owner) { Gitrob::Github::User.new('user', http_client) }
    let(:repo) { Gitrob::Github::Repository.new(owner.username, 'repo', http_client) }
    let(:org) { Gitrob::Github::Organization.new('org', http_client).to_model }

    it 'detects private keys' do
      ['id_rsa',
       '.ssh/id_rsa',
       'ssh/id_rsa',
       'privatekeys/id_rsa',
       'id_ed25519',
       '.ssh/id_ed25519',
       'privatekeys/id_ed25519',
       '.ssh/id_ecdsa',
       'id_ecdsa',
       'ssh/id_ecdsa',
       'privatekeys/id_ecdsa'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Private SSH key")
      end
    end

    it 'detects files with .pem extension' do
      ['privatekey.pem',
       'keys/privatekey.pem',
       '.secret.pem',
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Potential cryptographic private key")
      end
    end

    it 'detects files with .key extension' do
      ['privatekey.key',
       'keys/privatekey.key',
       '.secret.key',
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Potential cryptographic private key")
      end
    end

    it 'detects files with .pkcs12 extension' do
      ['privatekey.pkcs12',
       'keys/privatekey.pkcs12',
       '.secret.pkcs12',
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Potential cryptographic key bundle")
      end
    end

    it 'detects files with .pfx extension' do
      ['privatekey.pfx',
       'keys/privatekey.pfx',
       '.secret.pfx',
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Potential cryptographic key bundle")
      end
    end

    it 'detects files with .p12 extension' do
      ['privatekey.p12',
       'keys/privatekey.p12',
       '.secret.p12',
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Potential cryptographic key bundle")
      end
    end

    it 'detects files with .asc extension' do
      ['privatekey.asc',
       'keys/privatekey.asc',
       '.secret.asc',
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Potential cryptographic key bundle")
      end
    end

    it 'detects Pidgin private OTR keys' do
      ['otr.private_key',
       '.purple/otr.private_key',
       'pidgin/otr.private_key',
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Pidgin OTR private key")
      end
    end

    it 'detects shell command history files' do
      ['.bash_history',
       'bash_history',
       'bash/bash_history',
       '.zsh_history',
       'zsh_history',
       'zsh/zsh_history',
       '.zhistory',
       'zhistory',
       'zsh/zhistory',
       '.history',
       'history',
       'shell/history'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Shell command history file")
      end
    end

    it 'detects MySQL client command history files' do
      ['.mysql_history',
       'mysql_history',
       'history/.mysql_history',
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("MySQL client command history file")
      end
    end

    it 'detects PostgreSQL client command history files' do
      ['.psql_history',
       'psql_history',
       'history/.psql_history',
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("PostgreSQL client command history file")
      end
    end

    it 'detects IRB console history files' do
      ['.irb_history',
       'irb_history',
       'history/.irb_history',
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Ruby IRB console history file")
      end
    end

    it 'detects Pidgin chat client account configuration files' do
      ['.purple/accounts.xml',
       'purple/accounts.xml',
       'config/purple/accounts.xml',
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Pidgin chat client account configuration file")
      end
    end

    it 'detects XChat client server list configuration files' do
      ['.xchat2/servlist_.conf',
       '.xchat2/servlist.conf',
       'xchat2/servlist_.conf',
       'xchat2/servlist.conf',
       'xchat/servlist_.conf',
       'xchat/servlist.conf',
       '.xchat/servlist_.conf',
       '.xchat/servlist.conf',
       'config/.xchat/servlist.conf'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Hexchat/XChat IRC client server list configuration file")
      end
    end

    it 'detects Hexchat client server list configuration files' do
      ['.hexchat/servlist.conf',
       'hexchat/servlist.conf',
       'config/.hexchat/servlist.conf'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Hexchat/XChat IRC client server list configuration file")
      end
    end

    it 'detects irrsi IRC client configuration files' do
      ['.irssi/config',
       'irssi/config',
       'config/.irssi/config'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Irssi IRC client configuration file")
      end
    end

    it 'detects Recon-ng API key databases' do
      ['.recon-ng/keys.db',
       'recon-ng/keys.db',
       'config/.recon-ng/keys.db'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Recon-ng web reconnaissance framework API key database")
      end
    end

    it 'detects DBeaver configuration files' do
      ['.dbeaver-data-sources.xml',
       'dbeaver-data-sources.xml',
       'config/.dbeaver-data-sources.xml'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("DBeaver SQL database manager configuration file")
      end
    end

    it 'detects Mutt configuration files' do
      ['.muttrc',
       'muttrc',
       'config/.muttrc'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Mutt e-mail client configuration file")
      end
    end

    it 'detects S3cmd configuration files' do
      ['.s3cfg',
       's3cfg',
       'config/.s3cfg'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("S3cmd configuration file")
      end
    end

    it 'detects T Twitter client configuration files' do
      ['.trc',
       'trc',
       'config/.trc'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("T command-line Twitter client configuration file")
      end
    end

    it 'detects OpenVPN configuration files' do
      ['vpn.ovpn',
       '.cryptostorm.ovpn',
       'config/work.ovpn'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("OpenVPN client configuration file")
      end
    end

    it 'detects Gitrob configuration files' do
      ['.gitrobrc',
       'gitrobrc',
       'config/.gitrobrc'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Well, this is awkward... Gitrob configuration file")
      end
    end

    it 'detects shell configuration files' do
      ['.bashrc',
       'bashrc',
       'bash/.bashrc',
       '.zshrc',
       'zshrc',
       'zsh/.zshrc'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Shell configuration file")
        expect(blob.findings.first.description).to eq("Shell configuration files might contain information such as server hostnames, passwords and API keys.")
      end
    end

    it 'detects shell profile files' do
      ['.bash_profile',
       'bash_profile',
       'bash/.bash_profile',
       '.zsh_profile',
       'zsh_profile',
       'zsh/.zsh_profile',
       '.profile',
       'profile',
       'sh/.profile'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Shell profile configuration file")
        expect(blob.findings.first.description).to eq("Shell configuration files might contain information such as server hostnames, passwords and API keys.")
      end
    end

    it 'detects shell alias files' do
      ['.bash_aliases',
       'bash_aliases',
       'bash/.bash_aliases',
       '.zsh_aliases',
       'zsh_aliases',
       'zsh/.zsh_aliases',
       '.aliases',
       'aliases',
       'sh/.aliases'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Shell command alias configuration file")
        expect(blob.findings.first.description).to eq("Shell configuration files might contain information such as server hostnames, passwords and API keys.")
      end
    end

    it 'detects Rails secret token configuration files' do
      ['secret_token.rb',
       'config/initializers/secret_token.rb'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Ruby On Rails secret token configuration file")
        expect(blob.findings.first.description).to eq("If the Rails secret token is known, it can allow for remote code execution. (http://www.exploit-db.com/exploits/27527/)")
      end
    end

    it 'detects Omniauth configuration files' do
      ['omniauth.rb',
       'config/initializers/omniauth.rb'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("OmniAuth configuration file")
        expect(blob.findings.first.description).to eq("The OmniAuth configuration file might contain client application secrets.")
      end
    end

    it 'detects Carrierwave configuration files' do
      ['carrierwave.rb',
       'config/initializers/carrierwave.rb'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Carrierwave configuration file")
        expect(blob.findings.first.description).to eq("Can contain credentials for online storage systems such as Amazon S3 and Google Storage.")
      end
    end

    it 'detects Rails schema files' do
      ['schema.rb',
       'db/schema.rb'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Ruby On Rails database schema file")
        expect(blob.findings.first.description).to eq("Contains information on the database schema of a Ruby On Rails application.")
      end
    end

    it 'detects Rails database configuration files' do
      ['database.yml',
       'config/database.yml'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Potential Ruby On Rails database configuration file")
        expect(blob.findings.first.description).to eq("Might contain database credentials.")
      end
    end

    it 'detects KeePass database files' do
      ['keepass.kdb',
       'secret/pwd.kdb'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("KeePass password manager database file")
      end
    end

    it 'detects 1Password database files' do
      ['passwords.agilekeychain',
       'secret/pwd.agilekeychain'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("1Password password manager database file")
      end
    end

    it 'detects Apple keychain database files' do
      ['passwords.keychain',
       'secret/pwd.keychain'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Apple Keychain database file")
      end
    end

    it 'detects GNOME keyring database files' do
      ['passwords.keystore',
       'passwords.keyring',
       'secret/pwd.keystore',
       'secret/pwd.keyring'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("GNOME Keyring database file")
      end
    end

    it 'detects log files' do
      ['log.log',
       'logs/production.log',
       '.secret.log'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Log file")
        expect(blob.findings.first.description).to eq("Log files might contain information such as references to secret HTTP endpoints, session IDs, user information, passwords and API keys.")
      end
    end

    it 'detects PCAP files' do
      ['capture.pcap',
       'debug/production.pcap'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Network traffic capture file")
      end
    end

    it 'detects SQL files' do
      ['db.sql',
       'db.sqldump',
       'setup/database.sql',
       'backup/production.sqldump'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("SQL dump file")
      end
    end

    it 'detects GnuCash database files' do
      ['budget.gnucash',
       '.budget.gnucash',
       'finance/budget.gnucash'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("GnuCash database file")
      end
    end

    it 'detects files containing word: backup' do
      ['backup.tar.gz',
       'backups/dbbackup.zip'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Contains word: backup")
      end
    end

    it 'detects files containing word: dump' do
      ['dump.bin',
       'debug/memdump.txt'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Contains word: dump")
      end
    end

    it 'detects files containing word: password' do
      ['passwords.xls',
       'private/password-reminders.txt'
      ].each do |path|
        blob = Gitrob::Github::Blob.new(path, 1, repo).to_model(org, repo.to_model(org))
        described_class.observe(blob)
        expect(blob.findings.first.caption).to eq("Contains word: password")
      end
    end
  end
end
