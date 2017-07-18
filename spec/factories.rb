FactoryGirl.define do
  to_create { |instance| instance.save(:raise_on_failure => true) }

  factory :assessment, :class => Gitrob::Models::Assessment do
    name "Assessment"
    endpoint "https://api.github.com"
    site "https://github.com"
    owners_count 0
    repositories_count 0
    blobs_count 0
    verify_ssl true
  end

  factory :github_access_token, :class => Gitrob::Models::GithubAccessToken do
    token "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
  end

  factory :organization, :class => Gitrob::Models::Owner do
    github_id { Faker::Number.number(7) }
    name { Faker::Company.name }
    login { Faker::Internet.slug(name) }
    type "Organization"
    url { "https://api.github.com/orgs/#{login}" }
    html_url { "https://github.com/#{login}" }
    avatar_url do
      "https://avatars3.githubusercontent.com/u/#{github_id}?v=3&s=200"
    end
    blog { "http://#{Faker::Internet.domain_name}" }
    location { "#{Faker::Address.city}, #{Faker::Address.country}" }
    email { Faker::Internet.safe_email(login) }
    bio { Faker::Company.catch_phrase }
  end

  factory :user, :class => Gitrob::Models::Owner do
    github_id { Faker::Number.number(7) }
    name { Faker::Name.name }
    login { Faker::Internet.user_name }
    type "User"
    url { "https://api.github.com/users/#{login}" }
    html_url { "https://github.com/#{login}" }
    avatar_url do
      "https://avatars3.githubusercontent.com/u/#{github_id}?v=3&s=200"
    end
    blog { "http://#{Faker::Internet.domain_name}" }
    location { "#{Faker::Address.city}, #{Faker::Address.country}" }
    email { Faker::Internet.safe_email(login) }
    bio { Faker::Lorem.sentence }
  end

  factory :repository, :class => Gitrob::Models::Repository do
    github_id { Faker::Number.number(7) }
    name { Faker::App.name }
    full_name { "#{Faker::Internet.user_name}/#{Faker::Internet.slug(name)}" }
    description { Faker::Lorem.sentence }
    private false
    url { "https://api.github.com/repos/#{full_name}" }
    html_url { "https://github.com/#{full_name}" }
    homepage { Faker::Internet.url }
    size { Faker::Number.number(4) }
    default_branch "master"
  end

  factory :blob, :class => Gitrob::Models::Blob do
    path do
      dir = Random.rand(7).times.collect do
        Faker::Internet.password(5, 15)
      end
      file = Faker::Internet.password(5, 15)
      ext = %w(sql rb py php go txt md).sample
      "#{dir.join('/')}/#{file}.#{ext}"
    end
    size { Faker::Number.number(3) }
    sha { Digest::SHA1.hexdigest(Random.rand.to_s) }
  end

  factory :flag, :class => Gitrob::Models::Flag do
    caption do
      "#{Faker::Hacker.adjective} #{Faker::Hacker.adjective} " \
      "#{Faker::Hacker.noun}"
    end
    description { Faker::Hacker.say_something_smart }
  end
end
