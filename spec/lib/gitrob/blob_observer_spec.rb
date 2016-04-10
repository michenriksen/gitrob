require "spec_helper"

describe Gitrob::BlobObserver do
  describe ".observe" do
    it "flags private RSA SSH keys" do
      %w(
        /ssh/id_rsa
        /.ssh/personal_rsa
        /config/server_rsa
        id_rsa
        .id_rsa
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Private SSH key")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags private DSA SSH keys" do
      %w(
        /ssh/id_dsa
        /.ssh/personal_dsa
        /config/server_dsa
        id_dsa
        .id_dsa
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Private SSH key")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags private ed25519 SSH keys" do
      %w(
        /ssh/id_ed25519
        /.ssh/personal_ed25519
        /config/server_ed25519
        id_ed25519
        .id_ed25519
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Private SSH key")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags private ECDSA SSH keys" do
      %w(
        /ssh/id_ecdsa
        /.ssh/personal_ecdsa
        /config/server_ecdsa
        id_ecdsa
        .id_ecdsa
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Private SSH key")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags blobs with .pem extension" do
      %w(
        /privatekey.pem
        .secret.pem
        /keys/privatekey.pem
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Potential cryptographic private key")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags blobs with .key(pair) extension" do
      %w(
        privatekey.key
        keys/privatekey.key
        .secret.key
        production.keypair
        keys/privatekey.keypair
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Potential cryptographic private key")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags blobs with .pkcs12 extension" do
      %w(
        privatekey.pkcs12
        keys/privatekey.pkcs12
        .secret.pkcs12
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Potential cryptographic key bundle")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags blobs with .pfx extension" do
      %w(
        privatekey.pfx
        keys/privatekey.pfx
        .secret.pfx
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Potential cryptographic key bundle")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags blobs with .p12 extension" do
      %w(
        privatekey.p12
        keys/privatekey.p12
        .secret.p12
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Potential cryptographic key bundle")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags blobs with .asc extension" do
      %w(
        privatekey.asc
        keys/privatekey.asc
        .secret.asc
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Potential cryptographic key bundle")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags Pidgin private OTR keys" do
      %w(
        otr.private_key
        .purple/otr.private_key
        pidgin/otr.private_key
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Pidgin OTR private key")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags shell command history blobs" do
      %w(
        .bash_history
        bash_history
        bash/bash_history
        .zsh_history
        zsh_history
        zsh/zsh_history
        .zhistory
        zhistory
        zsh/zhistory
        .history
        history
        shell/history
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Shell command history file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags MySQL client command history blobs" do
      %w(
        .mysql_history
        mysql_history
        history/.mysql_history
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("MySQL client command history file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags PostgreSQL client command history blobs" do
      %w(
        .psql_history
        psql_history
        history/.psql_history
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("PostgreSQL client command history file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags IRB console history blobs" do
      %w(
        .irb_history
        irb_history
        history/.irb_history
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Ruby IRB console history file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags Pidgin chat client account configuration blobs" do
      %w(
        .purple/accounts.xml
        purple/accounts.xml
        config/purple/accounts.xml
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Pidgin chat client account configuration file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags XChat client server list configuration blobs" do
      %w(
        .xchat2/servlist_.conf
        .xchat2/servlist.conf
        xchat2/servlist_.conf
        xchat2/servlist.conf
        xchat/servlist_.conf
        xchat/servlist.conf
        .xchat/servlist_.conf
        .xchat/servlist.conf
        config/.xchat/servlist.conf
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Hexchat/XChat IRC client server list configuration file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags Hexchat client server list configuration blobs" do
      %w(
        .hexchat/servlist.conf
        hexchat/servlist.conf
        config/.hexchat/servlist.conf
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Hexchat/XChat IRC client server list configuration file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags irrsi IRC client configuration blobs" do
      %w(
        .irssi/config
        irssi/config
        config/.irssi/config
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Irssi IRC client configuration file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags Recon-ng API key databases" do
      %w(
        .recon-ng/keys.db
        recon-ng/keys.db
        config/.recon-ng/keys.db
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Recon-ng web reconnaissance framework API key database")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags DBeaver configuration blobs" do
      %w(
        .dbeaver-data-sources.xml
        dbeaver-data-sources.xml
        config/.dbeaver-data-sources.xml
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("DBeaver SQL database manager configuration file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags Mutt configuration blobs" do
      %w(
        .muttrc
        muttrc
        config/.muttrc
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Mutt e-mail client configuration file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags S3cmd configuration blobs" do
      %w(
        .s3cfg
        s3cfg
        config/.s3cfg
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("S3cmd configuration file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags AWS CLI credential blobs" do
      %w(
        .aws/credentials
        aws/credentials
        homefolder/aws/credentials
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("AWS CLI credentials file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags T Twitter client configuration blobs" do
      %w(
        .trc
        trc
        config/.trc
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("T command-line Twitter client configuration file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags OpenVPN configuration blobs" do
      %w(
        vpn.ovpn
        .cryptostorm.ovpn
        config/work.ovpn
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("OpenVPN client configuration file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags Gitrob configuration blobs" do
      %w(
        .gitrobrc
        gitrobrc
        config/.gitrobrc
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Well, this is awkward... Gitrob configuration file")
        expect(blob.flags.first.description)
          .to eq(nil)
      end
    end

    it "flags shell configuration blobs" do
      %w(
        .bashrc
        bashrc
        bash/.bashrc
        .zshrc
        zshrc
        zsh/.zshrc
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Shell configuration file")
        expect(blob.flags.first.description)
          .to eq("Shell configuration files might contain information such " \
                 "as server hostnames, passwords and API keys.")
      end
    end

    it "flags shell profile blobs" do
      %w(
        .bash_profile
        bash_profile
        bash/.bash_profile
        .zsh_profile
        zsh_profile
        zsh/.zsh_profile
        .profile
        profile
        sh/.profile
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Shell profile configuration file")
        expect(blob.flags.first.description)
          .to eq("Shell configuration files might contain information such " \
                 "as server hostnames, passwords and API keys.")
      end
    end

    it "flags shell alias blobs" do
      %w(
        .bash_aliases
        bash_aliases
        bash/.bash_aliases
        .zsh_aliases
        zsh_aliases
        zsh/.zsh_aliases
        .aliases
        aliases
        sh/.aliases
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Shell command alias configuration file")
        expect(blob.flags.first.description)
          .to eq("Shell configuration files might contain information such " \
                 "as server hostnames, passwords and API keys.")
      end
    end

    it "flags Rails secret token configuration blobs" do
      %w(
        secret_token.rb
        config/initializers/secret_token.rb
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Ruby On Rails secret token configuration file")
        expect(blob.flags.first.description)
          .to eq("If the Rails secret token is known, " \
                 "it can allow for remote code execution." \
                 " (http://www.exploit-db.com/exploits/27527/)")
      end
    end

    it "flags Omniauth configuration blobs" do
      %w(
        omniauth.rb
        config/initializers/omniauth.rb
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("OmniAuth configuration file")
        expect(blob.flags.first.description)
          .to eq("The OmniAuth configuration file might contain " \
                 "client application secrets.")
      end
    end

    it "flags Carrierwave configuration blobs" do
      %w(
        carrierwave.rb
        config/initializers/carrierwave.rb
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Carrierwave configuration file")
        expect(blob.flags.first.description)
          .to eq("Can contain credentials for online storage " \
                 "systems such as Amazon S3 and Google Storage.")
      end
    end

    it "flags Rails database configuration blobs" do
      %w(
        database.yml
        config/database.yml
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Potential Ruby On Rails database configuration file")
        expect(blob.flags.first.description)
          .to eq("Might contain database credentials.")
      end
    end

    it "flags Django settings blobs" do
      %w(
        settings.py
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Django configuration file")
        expect(blob.flags.first.description)
          .to eq("Might contain database credentials, online " \
                 "storage system credentials, secret keys, etc.")
      end
    end

    it "flags PHP configuration blobs" do
      %w(
        config.php
        config/config.inc.php
        db_config.php
        secret_config.inc.php
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("PHP configuration file")
        expect(blob.flags.first.description)
          .to eq("Might contain credentials and keys.")
      end
    end

    it "flags KeePass database blobs" do
      %w(
        keepass.kdb
        secret/pwd.kdb
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("KeePass password manager database file")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags 1Password database blobs" do
      %w(
        passwords.agilekeychain
        secret/pwd.agilekeychain
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("1Password password manager database file")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags Apple keychain database blobs" do
      %w(
        passwords.keychain
        secret/pwd.keychain
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Apple Keychain database file")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags GNOME keyring database blobs" do
      %w(
        passwords.keystore
        passwords.keyring
        secret/pwd.keystore
        secret/pwd.keyring
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("GNOME Keyring database file")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags log blobs" do
      %w(
        log.log
        logs/production.log
        .secret.log
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Log file")
        expect(blob.flags.first.description)
          .to eq("Log files might contain information such as "\
                 "references to secret HTTP endpoints, session " \
                 "IDs, user information, passwords and API keys.")
      end
    end

    it "flags PCAP blobs" do
      %w(
        capture.pcap
        debug/production.pcap
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Network traffic capture file")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags SQL blobs" do
      %w(
        db.sql
        db.sqldump
        setup/database.sql
        backup/production.sqldump
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("SQL dump file")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags GnuCash database blobs" do
      %w(
        budget.gnucash
        .budget.gnucash
        finance/budget.gnucash
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("GnuCash database file")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags blobs containing word: backup" do
      %w(
        backup.tar.gz,
        backups/dbbackup.zip
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Contains word: backup")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags blobs containing word: dump" do
      %w(
        dump.bin
        debug/memdump.txt
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Contains word: dump")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags blobs containing word: password" do
      %w(
        passwords.xls
        private/password-reminders.txt
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Contains word: password")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags blobs containing words: private, key" do
      %w(
        privatekey.asc
        super_private_key.asc
        private/private_keys.tar.gz
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("Contains words: private, key")
        expect(blob.flags.last.description)
          .to be nil
      end
    end

    it "flags blobs containing word: secret" do
      %w(
        secrets.txt
        private/secret_key
        admin/secret.php
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Contains word: secret")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags blobs containing word: credential" do
      %w(
        credentials.txt
        private/user_credentials.tar.gz
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Contains word: credential")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags Jenkins publish over ssh plugin configuration blobs" do
      %w(
        jenkins.plugins.publish_over_ssh.BapSshPublisherPlugin.xml
        jenkins/jenkins.plugins.publish_over_ssh.BapSshPublisherPlugin.xml
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Jenkins publish over SSH plugin file")
        expect(blob.flags.last.description)
          .to be nil
      end
    end

    it "flags Jenkins credentials blobs" do
      %w(
        credentials.xml
        jenkins/credentials.xml
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("Potential Jenkins credentials file")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags Apache htpasswd blobs" do
      %w(
        .htpasswd
        htpasswd
        public/htpasswd
        admin/.htpasswd
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Apache htpasswd file")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags netrc blobs" do
      %w(
        .netrc
        netrc
        _netrc
        dotfiles/.netrc
        homefolder/netrc
        home/_netrc
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Configuration file for auto-login process")
        expect(blob.flags.first.description)
          .to eq("Might contain username and password.")
      end
    end

    it "flags KDE Wallet Manager blobs" do
      %w(
        wallet.kwallet
        .wallet.kwallet
        dotfiles/secret.kwallet
        homefolder/creds.kwallet
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("KDE Wallet Manager database file")
        expect(blob.flags.last.description)
          .to be nil
      end
    end

    it "flags MediaWiki configuration blobs" do
      %w(
        LocalSettings.php
        mediawiki/LocalSettings.php
        configs/LocalSettings.php
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Potential MediaWiki configuration file")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags Tunnelblick VPN configuration blobs" do
      %w(
        vpn.tblk
        secret/tunnel.tblk
        configs/.tunnelblick.tblk
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Tunnelblick VPN configuration file")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags Rubygems credentials blobs" do
      %w(
        .gem/credentials
        gem/credentials
        homefolder/gem/credentials
      ).each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("Rubygems credentials file")
        expect(blob.flags.last.description)
          .to eq("Might contain API key for a rubygems.org account.")
      end
    end

    it "flags Little Snitch configuration blobs" do
      [
        "Library/Application Support/Sequel Pro/Data/Favorites.plist",
        "Sequel/Favorites.plist",
        "Favorites.plist"
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Sequel Pro MySQL database manager bookmark file")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags Sequel Pro bookmark blobs" do
      [
        "Library/Application Support/Little Snitch/configuration.user.xpl",
        "littlesnitch/configuration.user.xpl",
        "configuration.user.xpl"
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Little Snitch firewall configuration file")
        expect(blob.flags.first.description)
          .to eq("Contains traffic rules for applications")
      end
    end

    it "flags Day One journal blobs" do
      [
        "journal.dayone",
        "documents/journal.dayone",
        "backup/.journal.dayone"
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Day One journal file")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags jrnl journal blobs" do
      [
        "journal.txt",
        "homefolder/journal.txt",
        "backup/journal.txt"
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Potential jrnl journal file")
        expect(blob.flags.first.description)
          .to be nil
      end
    end

    it "flags Chef knife.rg blobs" do
      [
        "knife.rb",
        ".chef/knife.rb",
        "home/chef/knife.rb"
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.first.caption)
          .to eq("Chef Knife configuration file")
        expect(blob.flags.first.description)
          .to eq("Might contain references to Chef servers")
      end
    end

    it "flags Chef private key blobs" do
      [
        "chef/user.pem",
        ".chef/key.pem",
        "home/chef/admin.pem"
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("Chef private key")
        expect(blob.flags.last.description)
          .to eq("Can be used to authenticate against Chef servers")
      end
    end

    it "flags Git configuration blobs" do
      [
        ".gitconfig",
        "home/gitconfig",
        "gitconfig"
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("Git configuration file")
        expect(blob.flags.last.description)
          .to be nil
      end
    end

    it "flags SSH configuration blobs" do
      [
        ".ssh/config",
        "ssh/config",
        "home/ssh/config"
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("SSH configuration file")
        expect(blob.flags.last.description)
          .to be nil
      end
    end

    it "flags PostgreSQL password blobs" do
      [
        ".pgpass",
        "pgpass",
        "home/.pgpass"
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("PostgreSQL password file")
        expect(blob.flags.last.description)
          .to be nil
      end
    end

    it "flags ProFTPd password blobs" do
      [
        "proftpdpasswd",
        "project/proftpdpasswd",
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("cPanel backup ProFTPd credentials file")
        expect(blob.flags.last.description)
          .to eq("Contains usernames and password hashes for FTP accounts")
      end
    end

    it "flags Robomongo configuration blobs" do
      [
        "robomongo.json",
        "project/robomongo.json",
        "home/robomongo.json",
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("Robomongo MongoDB manager configuration file")
        expect(blob.flags.last.description)
          .to eq("Might contain credentials for MongoDB databases")
      end
    end

    it "flags Filezilla configuration blobs" do
      [
        "filezilla.xml",
        "project/filezilla.xml",
        "home/filezilla.xml",
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("FileZilla FTP configuration file")
        expect(blob.flags.last.description)
          .to eq("Might contain credentials for FTP servers")
      end
    end

    it "flags Filezilla recent servers blobs" do
      [
        "recentservers.xml",
        "project/recentservers.xml",
        "home/recentservers.xml",
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("FileZilla FTP recent servers file")
        expect(blob.flags.last.description)
          .to eq("Might contain credentials for FTP servers")
      end
    end

    it "flags Ventrilo server configuration blobs" do
      [
        "ventrilo_srv.ini",
        "project/ventrilo_srv.ini",
        "home/ventrilo_srv.ini",
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("Ventrilo server configuration file")
        expect(blob.flags.last.description)
          .to eq("Might contain passwords")
      end
    end

    it "flags Docker configuration blobs" do
      [
        ".dockercfg",
        "project/dockercfg",
        "home/.dockercfg",
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("Docker configuration file")
        expect(blob.flags.last.description)
          .to eq("Might contain credentials for public or private Docker registries")
      end
    end

    it "flags NPM configuration blobs" do
      [
        ".npmrc",
        "project/npmrc",
        "home/.npmrc",
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("NPM configuration file")
        expect(blob.flags.last.description)
          .to eq("Might contain credentials for NPM registries")
      end
    end

    it "flags Terraform variable configuration blobs" do
      [
        "terraform.tfvars",
        "project/terraform.tfvars",
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("Terraform variable config file")
        expect(blob.flags.last.description)
          .to eq("Might contain credentials for terraform providers")
      end
    end

    it "flags environment configuration files" do
      [
        ".env",
        "env",
        "project/.env",
        "project/env",
      ].each do |path|
        blob = create(:blob, :path => path)
        described_class.observe(blob)
        expect(blob.flags.count).to be >= 1
        expect(blob.flags.last.caption)
          .to eq("Environment configuration file")
        expect(blob.flags.last.description)
          .to be nil
      end
    end
  end

  describe "Signature validation" do
    let(:signatures_file_path) do
      File.expand_path("../../../../signatures.json", __FILE__)
    end

    let(:custom_signatures_file_path) do
      File.join(Dir.home, ".gitrobsignatures")
    end

    context "when custom signatures file is present" do
      it "loads custom signatures" do
        described_class.unload_signatures
        allow(described_class).to receive(:custom_signatures?)
          .and_return(true)
        expect(File).to receive(:read)
          .with(custom_signatures_file_path)
          .and_return('
            [
               {
                 "part": "filename",
                 "type": "match",
                 "pattern": "test",
                 "caption": "Test signature",
                 "description": "This is a test signature"
               }
            ]
          ')
        described_class.load_custom_signatures!
        expect(described_class.signatures.count).to eq(1)
        signature = described_class.signatures.first
        expect(signature).to be_a(Gitrob::BlobObserver::Signature)
        expect(signature.part).to eq("filename")
        expect(signature.type).to eq("match")
        expect(signature.pattern).to eq("test")
        expect(signature.caption).to eq("Test signature")
        expect(signature.description).to eq("This is a test signature")
      end

      it "validates custom signatures" do
        described_class.unload_signatures
        allow(described_class).to receive(:custom_signatures?)
          .and_return(true)
        allow(File).to receive(:read)
          .with(custom_signatures_file_path)
          .and_return('
            [
               {
                 "part": "filename",
                 "type": "match",
                 "pattern": "test",
                 "caption": "Test signature",
                 "description": "This is a test signature"
               }
            ]
          ')
        expect(described_class).to receive(:validate_signatures!)
          .with([
            {
              "part" => "filename",
               "type" => "match",
               "pattern" => "test",
               "caption" => "Test signature",
               "description" => "This is a test signature"
            }
          ])
        described_class.load_custom_signatures!
      end
    end

    context "when Signature file is empty" do
      it "raises CorruptSignaturesError" do
        expect(File).to receive(:read)
          .with(signatures_file_path)
          .and_return("")
        expect do
          described_class.load_signatures!
        end
          .to raise_error(
            Gitrob::BlobObserver::CorruptSignaturesError,
            "Signature file contains no signatures"
          )
      end
    end

    context "when Signature file contains an empty array" do
      it "raises CorruptSignaturesError" do
        expect(File).to receive(:read)
          .with(signatures_file_path)
          .and_return("[]")
        expect do
          described_class.load_signatures!
        end
          .to raise_error(
            Gitrob::BlobObserver::CorruptSignaturesError,
            "Signature file contains no signatures"
          )
      end
    end

    context "when Signature file contains invalid JSON" do
      it "raises CorruptSignaturesError" do
        expect(File).to receive(:read)
          .with(signatures_file_path)
          .and_return("lol\nwhat?")
        expect do
          described_class.load_signatures!
        end
          .to raise_error(
            Gitrob::BlobObserver::CorruptSignaturesError,
            "Could not parse signature file"
          )
      end
    end

    context "when signature is missing part" do
      let(:signatures) do
        [{
          "type" => "match",
          "pattern" => "pattern",
          "caption" => "caption",
          "description" => "description"
        }]
      end

      it "raises CorruptSignaturesError" do
        expect(File).to receive(:read)
          .with(signatures_file_path)
          .and_return(JSON.dump(signatures))
        expect do
          described_class.load_signatures!
        end
          .to raise_error(
            Gitrob::BlobObserver::CorruptSignaturesError,
            "Validation failed for Signature #1: Missing required signature key: part"
          )
      end
    end

    context "when signature is missing type" do
      let(:signatures) do
        [{
          "part" => "filename",
          "pattern" => "pattern",
          "caption" => "caption",
          "description" => "description"
        }]
      end

      it "raises CorruptSignaturesError" do
        expect(File).to receive(:read)
          .with(signatures_file_path)
          .and_return(JSON.dump(signatures))
        expect do
          described_class.load_signatures!
        end
          .to raise_error(
            Gitrob::BlobObserver::CorruptSignaturesError,
            "Validation failed for Signature #1: Missing required signature key: type"
          )
      end
    end

    context "when signature is missing pattern" do
      let(:signatures) do
        [{
          "part" => "filename",
          "type" => "match",
          "caption" => "caption",
          "description" => "description"
        }]
      end

      it "raises CorruptSignaturesError" do
        expect(File).to receive(:read)
          .with(signatures_file_path)
          .and_return(JSON.dump(signatures))
        expect do
          described_class.load_signatures!
        end
          .to raise_error(
            Gitrob::BlobObserver::CorruptSignaturesError,
            "Validation failed for Signature #1: Missing required signature key: pattern"
          )
      end
    end

    context "when signature is missing caption" do
      let(:signatures) do
        [{
          "part" => "filename",
          "type" => "match",
          "pattern" => "pattern",
          "description" => "description"
        }]
      end

      it "raises CorruptSignaturesError" do
        expect(File).to receive(:read)
          .with(signatures_file_path)
          .and_return(JSON.dump(signatures))
        expect do
          described_class.load_signatures!
        end
          .to raise_error(
            Gitrob::BlobObserver::CorruptSignaturesError,
            "Validation failed for Signature #1: Missing required signature key: caption"
          )
      end
    end

    context "when signature is missing description" do
      let(:signatures) do
        [{
          "part" => "filename",
          "type" => "match",
          "pattern" => "pattern",
          "caption" => "caption"
        }]
      end

      it "raises CorruptSignaturesError" do
        expect(File).to receive(:read)
          .with(signatures_file_path)
          .and_return(JSON.dump(signatures))
        expect do
          described_class.load_signatures!
        end
          .to raise_error(
            Gitrob::BlobObserver::CorruptSignaturesError,
            "Validation failed for Signature #1: Missing required signature key: description"
          )
      end
    end

    context "when signature has invalid part" do
      let(:signatures) do
        [{
          "part" => "what",
          "type" => "match",
          "pattern" => "pattern",
          "caption" => "caption",
          "description" => "description"
        }]
      end

      it "raises CorruptSignaturesError" do
        expect(File).to receive(:read)
          .with(signatures_file_path)
          .and_return(JSON.dump(signatures))
        expect do
          described_class.load_signatures!
        end
          .to raise_error(
            Gitrob::BlobObserver::CorruptSignaturesError,
            "Validation failed for Signature #1: Invalid signature part: what"
          )
      end
    end

    context "when signature has invalid type" do
      let(:signatures) do
        [{
          "part" => "filename",
          "type" => "what",
          "pattern" => "pattern",
          "caption" => "caption",
          "description" => "description"
        }]
      end

      it "raises CorruptSignaturesError" do
        expect(File).to receive(:read)
          .with(signatures_file_path)
          .and_return(JSON.dump(signatures))
        expect do
          described_class.load_signatures!
        end
          .to raise_error(
            Gitrob::BlobObserver::CorruptSignaturesError,
            "Validation failed for Signature #1: Invalid signature type: what"
          )
      end
    end
  end
end
