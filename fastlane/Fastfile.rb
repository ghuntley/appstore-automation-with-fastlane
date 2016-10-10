require 'time'
require 'commander'
require 'pathname'

fastlane_version "1.105.0"

# Constants
APPLICAITON_IDENTIFIER = "com.ghuntley.fastlanelecture"
ITUNES_CONNECT_TEAM_ID = "J98S49XE45"
ITUNES_CONNECT_USERNAME = "ghuntley@ghuntley.com"
GOOGLE_PLAY_JSON_KEY = "~/Desktop/google-play-account-secret.json"

desc "Displays the commits between working tree and the last beta/release tag"
lane :changelog do |options|
  tag = options[:tag]

  puts_changelog(tag: last_release)
  puts_changelog(tag: last_beta)

end

desc "Fetches the distribution certificates and provisioning profiles to compile the app for development & distribution"
lane :certificates do

  match(type: "appstore", readonly: true, force: false, app_identifier: APPLICAITON_IDENTIFIER, team_id: ITUNES_CONNECT_TEAM_ID, username: ITUNES_CONNECT_USERNAME)
  match(type: "development", readonly: true, force: false, app_identifier: APPLICAITON_IDENTIFIER, team_id: ITUNES_CONNECT_TEAM_ID, username: ITUNES_CONNECT_USERNAME)

end

desc "Build production and debug build"
lane :build do
  
  changelog
  certificates

  sh("cd ..; ./build.sh")
end


desc "Submit a new version to iTunes Connect and Google Play"
desc ""
desc "If on master; it will do the following: "
desc "- Displays the commits between working tree and the last beta/release tag"
desc "- Fetches distribution certificates and provisioning profiles"
desc "- Upload screenshots + app metadata"
desc "- Build, sign and upload the app release"
desc "- Do a build version bump and push it"
desc "The application will *not* be submitted for review or automatically released"
desc ""
desc "If on develop; it will do the following: "
desc "- Displays the commits between working tree and the last beta/release tag"
desc "- Make sure the profiles are up to date and download the latest one"
desc "- Do a build version bump and push it"
desc "- Build, sign and upload the app for testing"
desc "The application will *not* be submitted for review or automatically released to external testers"
desc ""
lane :deploy do

  puts case git_branch
  when "master", "release"

    # slack(
    #   message: "App Store build incoming",
    #   channel: "#mobile",
    #   default_payloads: [:git_author]
    # )

    build

    tag_release

    deploy_itunesconnect
    deploy_googleplay

    metadata
    screenshots

  when "develop", "beta"
    
    build

    tag_beta

    devices

    deploy_itunesconnect
    deploy_googleplay

  else
    # failure
  end

end

private_lane :deploy_itunesconnect do

  ipa = "./artifacts/apple/release/FastlaneLecture.App.iOS.ipa"

  sigh(
    adhoc: true,
    force: true,
    filename: APPLICAITON_IDENTIFIER + ".mobileprovision",
    app_identifier: APPLICAITON_IDENTIFIER, 
    team_id: ITUNES_CONNECT_TEAM_ID, 
    username: ITUNES_CONNECT_USERNAME
  )

  resign(
    ipa: ipa,
    signing_identity: "iPhone Distribution: Geoffrey Huntley (J98S49XE45)",
  )

  puts case git_branch
  when "master", "release"

    deliver(
      metadata_path: "metadata/apple",
      force: true,
      ipa: ipa,
      skip_screenshots: true,
      skip_metadata: true,
      automatic_release: false,
      submit_for_review: false,
    )

  when "develop", "beta"
    
    pilot(
      ipa: ipa,
      app_identifier: APPLICAITON_IDENTIFIER,
      username: ITUNES_CONNECT_USERNAME,
      team_id: ITUNES_CONNECT_TEAM_ID,
      distribute_external: false,
      skip_waiting_for_build_processing: true
    )

  else
    # failure
  end

  # slack_message(message: "New version of the app successfully deployed to iTunes Connect! :tada: :tada:", success: true, payload: {})

end

lane :deploy_googleplay do

  apk = "artifacts/android/release/com.ghuntley.fastlanelecture-Signed.apk"
  
  supply(
    json_key: GOOGLE_PLAY_JSON_KEY,
    package_name: APPLICAITON_IDENTIFIER,
    apk: apk,
    track: "beta",
    metadata_path: "metadata/google-play",
    skip_upload_metadata: true,
    skip_upload_images: true,
    skip_upload_screenshots: true
  )

  # slack_message(message: "New version of the app successfully deployed to iTunes Connect! :tada: :tada:", success: true, payload: {})

end

desc "Registers developer devices with iTunes Connect"
lane :devices do

  register_devices(devices_file: "./Fastlane/iTunesConnectDevices", username: ITUNES_CONNECT_USERNAME , team_id: ITUNES_CONNECT_TEAM_ID)

end

desc "Upload application metadata to iTunes Connect and Google Play"
lane :metadata do

  supply(
    json_key: GOOGLE_PLAY_JSON_KEY,
    package_name: APPLICAITON_IDENTIFIER,
    metadata_path: "metadata/google-play",
    skip_upload_metadata: false,
    skip_upload_images: true,
    skip_upload_screenshots: true
  )

end

private_lane :metadata_itunesconnect do

  deliver(
    metadata_path: "metadata/apple",
    force: true,
    skip_binary_upload: true,
    skip_screenshots: true,
    skip_metadata: false,
    automatic_release: false,
    submit_for_review: false
  )

end

private_lane :metadata_googleplay do
end

desc "Upload application screenshots to iTunes Connect and Google Play"
lane :screenshots do

  screenshots_itunesconnect
  screenshots_googleplay

end

private_lane :screenshots_itunesconnect do

  deliver(
    metadata_path: "metadata/apple",
    force: true,
    skip_binary_upload: true,
    skip_screenshots: false,
    skip_metadata: true,
    automatic_release: false,
    submit_for_review: false
  )

end

private_lane :screenshots_googleplay do

  supply(
    json_key: GOOGLE_PLAY_JSON_KEY,
    package_name: APPLICAITON_IDENTIFIER,
    metadata_path: "metadata/google-play",
    skip_upload_metadata: true,
    skip_upload_images: false,
    skip_upload_screenshots: false
  )

end

private_lane :puts_changelog do |options|
  tag = options[:tag]

  puts compare_url(tag: tag)

  puts changelog_from_git_commits(
    between: [tag, "HEAD"], 
    pretty: "- (%ae) %s",
    match_lightweight_tag: false,
    include_merges: false 
  )

end

desc "Push the build to the beta branch and tag the build"
private_lane :tag_beta do |options|

  tag_name = "betas/#{build_version}"

  sh("git fetch")
  sh("git stash")
  sh("git checkout")
  sh("git pull origin develop")
  sh("git checkout beta")
  sh("git merge develop")
  sh("git stash apply")

  push_to_git_remote(
      local_branch: 'beta', 
      remote_branch: 'beta'
  )

  add_git_tag(tag: tag_name)
  sh("git push origin --tags")

end

desc "Push the build to the release branch and tag the build"
private_lane :tag_release do |options|
  tag_name = "releases/#{build_version}"

  sh("git fetch")
  sh("git stash")
  sh("git checkout")
  sh("git pull origin release")
  sh("git checkout master")
  sh("git merge release")
  sh("git stash apply")

  push_to_git_remote(
      local_branch: 'release',  
      remote_branch: 'release'
  )

  add_git_tag(tag: tag_name)
  sh("git push origin --tags")

end

private_lane :slack_message do |options|
  message = options[:message]
  success = options[:success]
  payload = options[:payload]

  slack(
    message: message,
    channel: "#mobile",
    success: success,
    payload: payload)
end

after_all do |lane|
  ship_it
  notify("Lane #{lane} completed successfully!")
end

error do |lane, exception|
  puts "\n(╯°□°）╯︵ ┻━┻\n".red
  notify("Lane #{lane} failed to complete")
end

# Helper functions
def build_version
  return sh("grep AssemblyInformationalVersion ../src/CommonAssemblyInfo.cs | awk -F '\"' '{print $2}'").strip
end

def last_beta
  return sh("git describe origin/develop --match=\"beta*\" --tags --abbrev=0").strip
end

def last_release
  return sh("git describe origin/master --match=\"release*\" --tags --abbrev=0").strip
end

def compare_url(options={})
  tag = options[:tag]
  head = last_git_commit[:abbreviated_commit_hash]
  
  return "https://github.com/ghuntley/appstore-automation-with-fastlane/compare/#{tag}...#{head}"
end

def ship_it
  rand = Random.rand(0..1)
  if rand == 0
    squirrel
  elsif rand == 1
    boat
  end
end

def squirrel
  puts "
    !!!!
  !!!!!!!!
!!!!!!!!!!!   O_O
!!!  !!!!!!! /@ @\\
      !!!!!! \\ x /
      !!!!!!/ m  !m
       !!!!/ __  |
       !!!!|/  \\__
        !!!\\______\\
  "
end

def boat
  puts "
     .  o ..
     o . o o.o
          ...oo
            __[]__
         __|_o_o_o\__
         \\\"\"\"\"\"\"\"\"\"\"/
          \\. ..  . /
     ^^^^^^^^^^^^^^^^^^^^
  "
end
